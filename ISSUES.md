# Plan de Issues y Tareas para el Repositorio

Guía y especificación detallada de los issues para la carga, desarrollo y seguimiento modular del proyecto **Organizador de Tareas (Frontend Flutter)**.

---

## Issue 1: Configuración inicial, arquitectura base y capa Core
* **Título:** `chore: Inicialización del proyecto, capa Core y utilidades base`
* **Rama sugerida:** `chore/setup-and-core`
* **Descripción:**
  Configurar la estructura base del proyecto Flutter, definir las dependencias necesarias en `pubspec.yaml`, el cliente HTTP (`Dio`), manejo seguro de almacenamiento local (`flutter_secure_storage`), temas de la aplicación y utilidades de validación/UI.
* **Criterios de Aceptación:**
  - [ ] Configuración de dependencias y assets del proyecto.
  - [ ] Implementación de `ApiClient` con interceptores y `ApiException`.
  - [ ] Servicio seguro de almacenamiento de tokens (`SecureStorageService`).
  - [ ] Definición de colores y estilos globales de la app.
* **Archivos involucrados:**
  - `pubspec.yaml`
  - `analysis_options.yaml`
  - `.gitignore`
  - `lib/core/network/api_client.dart`
  - `lib/core/network/api_exception.dart`
  - `lib/core/storage/secure_storage_service.dart`
  - `lib/core/theme/app_theme.dart`
  - `lib/core/theme/app_colors.dart`
  - `lib/core/theme/app_accent.dart`
  - `lib/core/utils/ui_utils.dart`
  - `lib/core/utils/validators.dart`

---

## Issue 2: Módulo de Autenticación y Control de Sesión
* **Título:** `feat: Autenticación de usuarios, login, registro y control de sesión`
* **Rama sugerida:** `feature/auth-module`
* **Descripción:**
  Implementar el flujo completo de autenticación: registro de nuevos usuarios, inicio de sesión, persistencia de tokens de sesión y compuerta de autenticación (`AuthGate`) para proteger las rutas privadas.
* **Criterios de Aceptación:**
  - [ ] Modelado de usuario en `UserModel`.
  - [ ] Repositorio y provider de autenticación con manejo de estados.
  - [ ] Pantallas de Login y Registro con validaciones de campos.
  - [ ] Redirección automática según el estado de la sesión vía `AuthGate`.
* **Archivos involucrados:**
  - `lib/data/models/user_model.dart`
  - `lib/data/repositories/auth_repository.dart`
  - `lib/providers/auth_provider.dart`
  - `lib/screens/auth/auth_gate.dart`
  - `lib/screens/auth/login_screen.dart`
  - `lib/screens/auth/register_screen.dart`

---

## Issue 3: Navegación Shell, Tema Dinámico y Entrypoint
* **Título:** `feat: Shell de navegación principal y soporte de temas dinámicos`
* **Rama sugerida:** `feature/main-shell-and-theme`
* **Descripción:**
  Configurar el entrypoint principal `main.dart` con `MultiProvider`, la barra de navegación inferior (`BottomNavBar`), el contenedor principal `MainShell` y el gestor dinámico de tema claro/oscuro/acentos (`ThemeProvider`).
* **Criterios de Aceptación:**
  - [ ] Inyección de dependencias en `main.dart`.
  - [ ] Navegación entre pestañas de la aplicación mediante `MainShell`.
  - [ ] Cambio reactivo de tema visual mediante `ThemeProvider`.
* **Archivos involucrados:**
  - `lib/main.dart`
  - `lib/providers/theme_provider.dart`
  - `lib/screens/home/main_shell.dart`
  - `lib/widgets/bottom_nav_bar.dart`
  - `lib/widgets/user_avatar_action.dart`

---

## Issue 4: Módulo de Gestión de Tareas (Core Feature)
* **Título:** `feat: Dashboard de tareas, CRUD y tarjetas de resumen`
* **Rama sugerida:** `feature/task-management`
* **Descripción:**
  Construir el módulo central de tareas: listado, creación, edición, actualización de estado y eliminación de tareas, incluyendo tarjetas de resumen y modal de formulario.
* **Criterios de Aceptación:**
  - [ ] Modelo `TaskModel` y operaciones API en `TaskRepository`.
  - [ ] Gestión reactiva del estado de las tareas en `TaskProvider`.
  - [ ] Pantalla principal `HomeScreen` con métricas (`SummaryCard`).
  - [ ] Modal para alta y modificación de tareas (`TaskFormModal`).
  - [ ] Componente de visualización individual de tarea (`TaskCard`).
* **Archivos involucrados:**
  - `lib/data/models/task_model.dart`
  - `lib/data/repositories/task_repository.dart`
  - `lib/providers/task_provider.dart`
  - `lib/screens/home/home_screen.dart`
  - `lib/screens/home/task_form_modal.dart`
  - `lib/widgets/task_card.dart`
  - `lib/widgets/summary_card.dart`

---

## Issue 5: Módulo de Notificaciones
* **Título:** `feat: Centro de notificaciones y alertas de usuario`
* **Rama sugerida:** `feature/notifications-module`
* **Descripción:**
  Implementar el centro de notificaciones para listar alertas de vencimiento de tareas, cambios de estado o asignaciones.
* **Criterios de Aceptación:**
  - [ ] Modelo `NotificationModel` y repositorio asociado.
  - [ ] Control de notificaciones leídas/no leídas mediante `NotificationProvider`.
  - [ ] Pantalla de visualización `NotificationsScreen`.
* **Archivos involucrados:**
  - `lib/data/models/notification_model.dart`
  - `lib/data/repositories/notification_repository.dart`
  - `lib/providers/notification_provider.dart`
  - `lib/screens/home/notifications_screen.dart`

---

## Issue 6: Módulo de Perfil de Usuario y Ajustes
* **Título:** `feat: Visualización y edición del perfil de usuario`
* **Rama sugerida:** `feature/profile-management`
* **Descripción:**
  Crear las vistas de consulta del perfil de usuario y edición de datos personales (nombre, avatar/foto, preferencias o contraseña).
* **Criterios de Aceptación:**
  - [ ] Visualización de la información del perfil del usuario logueado en `ProfileScreen`.
  - [ ] Formulario de edición y actualización con llamada al backend en `EditProfileScreen`.
* **Archivos involucrados:**
  - `lib/screens/profile/profile_screen.dart`
  - `lib/screens/profile/edit_profile_screen.dart`

---

## Issue 7: Módulo de Grupo Familiar / Tareas Compartidas
* **Título:** `feat: Gestión de miembros del grupo familiar y asignación de tareas`
* **Rama sugerida:** `feature/family-group`
* **Descripción:**
  Incorporar la pantalla del grupo familiar para ver y organizar a los miembros con los que se comparten las tareas colaborativas.
* **Criterios de Aceptación:**
  - [ ] Pantalla `FamilyScreen` que liste a los miembros o dependientes del grupo.
  - [ ] Integración con el flujo de navegación principal de la app.
* **Archivos involucrados:**
  - `lib/screens/family/family_screen.dart`

---

## Issue 8: Pruebas, Documentación y Configuración Multiplataforma
* **Título:** `docs: Documentación del repositorio (README) y pruebas de interfaz/widgets`
* **Rama sugerida:** `chore/docs-and-tests`
* **Descripción:**
  Añadir la documentación del proyecto (`README.md`) con instrucciones de instalación, variables de entorno necesarias y ejecución. Mantener y actualizar las pruebas de widgets.
* **Criterios de Aceptación:**
  - [ ] Archivo `README.md` con descripción, stack tecnológico y guía de inicio rápido (`flutter run`, `flutter test`).
  - [ ] Pruebas iniciales de widgets operativas en `widget_test.dart`.
* **Archivos involucrados:**
  - `README.md`
  - `test/widget_test.dart`

---

## Flujo de Trabajo Recomendado (Git / GitHub / GitLab)
1. **Creación del Issue:** Crear el issue en la plataforma con el título y la descripción correspondientes.
2. **Crear Rama:**
   ```bash
   git checkout -b feature/nombre-del-issue
   ```
3. **Desarrollar y Commits Convencionales:**
   ```bash
   git commit -m "feat: implementar api client (#1)"
   ```
4. **Pull Request:** Abrir el Pull Request hacia la rama principal con la referencia `Closes #1`.
