plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.amarnamovil"
    compileSdk = 36 // Required by modern plugins (camera, sqflite, etc)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.amarnamovil"
        minSdk = flutter.minSdkVersion
        targetSdk = 34 // targetSdk puede ser 34, pero compileSdk debe ser 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    aaptOptions {
        ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*~:!._*"
    }
}

flutter {
    source = "../.."
}

dependencies {
    // No añadas dependencias aquí, se gestionan desde pubspec.yaml
}
