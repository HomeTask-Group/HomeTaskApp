import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../core/utils/ui_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';

Future<String?> showTaskFormModal(BuildContext context, {TaskModel? taskToEdit}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => TaskFormModal(taskToEdit: taskToEdit),
  );
}

class TaskFormModal extends StatefulWidget {
  final TaskModel? taskToEdit;
  const TaskFormModal({super.key, this.taskToEdit});

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  DateTime _dueDate = DateTime.now();
  TaskPriority _priority = TaskPriority.media;
  String? _assignedToId;

  bool get _isEditing => widget.taskToEdit != null;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final t = widget.taskToEdit;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate ?? DateTime.now();
    _priority = t?.priority ?? TaskPriority.media;
    _assignedToId = t?.assignedToId;

    final auth = context.read<AuthProvider>();
    if (!auth.currentUser!.role.isGuardian) {
      _assignedToId = auth.currentUser!.id;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    FocusScope.of(context).unfocus();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _pickAssignee() async {
    FocusScope.of(context).unfocus();
    
    // Pequeño retraso para que el teclado baje suavemente antes de abrir el modal
    await Future.delayed(const Duration(milliseconds: 150));
    
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final members = auth.familyMembers;

    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Asignar tarea a',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ...members.map(
                (m) => ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(m.name),
                  onTap: () => Navigator.of(ctx).pop(m.id),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selectedId != null) {
      setState(() {
        _assignedToId = selectedId;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    final auth = context.read<AuthProvider>();
    final taskProvider = context.read<TaskProvider>();
    final currentUser = auth.currentUser!;
    final assignedId = _assignedToId ?? currentUser.id;

    try {
      if (_isEditing) {
        final updated = widget.taskToEdit!.copyWith(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          dueDate: _dueDate,
          priority: _priority,
          assignedToId: assignedId,
        );
        await taskProvider.updateTask(updated, currentUser.id);
        if (mounted) Navigator.of(context).pop('Tarea "${_titleCtrl.text}" actualizada con éxito.');
      } else {
        await taskProvider.createTask(
          title: _titleCtrl.text,
          description: _descCtrl.text,
          dueDate: _dueDate,
          priority: _priority,
          assignedToId: assignedId,
          currentUserId: currentUser.id,
        );
        if (mounted) Navigator.of(context).pop('Tarea "${_titleCtrl.text}" creada con éxito.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        UiUtils.showErrorModal(context, 'Error al guardar', taskProvider.errorMessage ?? 'No se pudo guardar la tarea.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final members = auth.familyMembers;
    final isTitleValid = _titleCtrl.text.trim().isNotEmpty;
    final isGuardian = auth.currentUser!.role.isGuardian;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Form(
          key: _formKey,
          onChanged: () => setState(() {}),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black12,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isEditing ? 'Editar tarea' : 'Nueva tarea',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Título *'),
                  validator: (v) => Validators.required(v, field: 'El título'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(14),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Fecha y hora límite',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    child: Text(
                      DateFormat('dd MMM yyyy, HH:mm', 'es').format(_dueDate),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Prioridad',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: TaskPriority.values.map((p) {
                    final selected = _priority == p;
                    final label = {
                      TaskPriority.baja: 'Baja',
                      TaskPriority.media: 'Media',
                      TaskPriority.alta: 'Alta',
                    }[p]!;
                    final color = {
                      TaskPriority.baja: AppColors.priorityLow,
                      TaskPriority.media: AppColors.priorityMedium,
                      TaskPriority.alta: AppColors.priorityHigh,
                    }[p]!;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? color : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color, width: 1.4),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? Colors.white : color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                if (isGuardian && members.isNotEmpty) ...[
                  Text(
                    'Asignar a',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickAssignee,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_pin_circle_outlined),
                      ),
                      child: Text(
                        members
                            .firstWhere(
                              (m) => m.id == (_assignedToId ?? auth.currentUser?.id),
                              orElse: () => members.first,
                            )
                            .name,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: (isTitleValid && !_isLoading) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isTitleValid
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).disabledColor,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Guardar cambios' : 'Crear tarea'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
