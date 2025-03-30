plugins {
    id("com.android.application")
    id("com.google.gms.google-services") // ✅ Firebase Google Services
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.jewelry_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.jewelry_app"
        minSdk = 23  // ✅ Ensure compatibility with Firebase Auth
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Change to release signingConfig for production
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("com.google.firebase:firebase-bom:32.7.2") // ✅ Firebase BOM (latest version)
    implementation("com.google.firebase:firebase-auth-ktx") // ✅ Firebase Authentication
    implementation("com.google.firebase:firebase-firestore-ktx") // ✅ Firestore (optional)
    implementation("com.google.firebase:firebase-storage-ktx") // ✅ Firebase Storage (optional)
}
