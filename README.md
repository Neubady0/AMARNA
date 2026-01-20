# AMARNA App

Amarna es una aplicación móvil desarrollada en Flutter para ayudar a los alumnos de Monlau a mejorar su desempeño en entrevistas de trabajo. La aplicación permite a los usuarios (candidatos) buscar ofertas, gestionar su perfil y realizar simulaciones, mientras que los profesores pueden administrar ofertas y ver el progreso de los alumnos.

## Características

- **Roles de Usuario:**
  - **Candidato:** Registro, Login, Gestión de perfil (CV, datos), Búsqueda de ofertas, Solicitudes.
  - **Profesor/Admin:** Gestión de ofertas de empleo, Visualización de resultados de alumnos.
- **Tecnologías:** Flutter (Dart), SQLite (sqflite) para base de datos local.
- **Diseño:** Interfaz moderna con temas oscuros/claros (actualmente enfocado en tema oscuro premium) y animaciones fluidas (flutter_animate).

## Requisitos Previos

Antes de comenzar, asegúrate de tener instalado lo siguiente en tu sistema:

1.  **Flutter SDK:** [Guía de instalación](https://docs.flutter.dev/get-started/install)
2.  **Android Studio** (con Android SDK y Command-line Tools) o **VS Code** (con extensiones de Flutter/Dart).
3.  **Git** instalado.

## Instalación y Configuración

Sigue estos pasos para descargar y ejecutar el proyecto:

1.  **Clonar el repositorio:**

    ```bash
    git clone https://github.com/Neubady0/AMARNA.git
    cd AMARNA/app/AmarnaCarpeta/AmarnaCarpeta
    ```

    _(Nota: Ajusta la ruta `cd` según dónde hayas clonado la estructura si es diferente)._

2.  **Instalar dependencias:**

    Ejecuta el siguiente comando en la raíz del proyecto (donde está el archivo `pubspec.yaml`) para descargar las librerías necesarias:

    ```bash
    flutter pub get
    ```

3.  **Diagnóstico (Opcional pero recomendado):**

    Verifica que tu entorno de Flutter esté correcto:

    ```bash
    flutter doctor
    ```

    Si hay errores, sigue las instrucciones que aparecen en la terminal.

## Ejecución

Para correr la aplicación en un emulador Android o dispositivo físico conectado:

```bash
flutter run
```

Si deseas ejecutarlo específicamente en un dispositivo (por ejemplo, si tienes varios conectados):

1.  Lista los dispositivos:
    ```bash
    flutter devices
    ```
2.  Corre la app indicando el ID del dispositivo:
    ```bash
    flutter run -d <device_id>
    ```

## Estructura del Proyecto

- `lib/`: Código fuente Dart.
  - `core/`: Configuraciones, tema (AppTheme).
  - `data/`: Acceso a datos (DatabaseHelper para SQLite).
  - `features/`: Módulos principales (auth, candidate, teacher/admin).
  - `main.dart`: Punto de entrada de la aplicación.

## Notas Adicionales

- **Base de Datos:** La app utiliza SQLite localmente. Al iniciar por primera vez, se insertan datos de prueba (ofertas de empleo) automáticamente si la base de datos está vacía.
- **Credenciales:** Puedes registrarte como nuevo usuario desde la pantalla de Login seleccionando el rol "Usuario" o "Profesor".
