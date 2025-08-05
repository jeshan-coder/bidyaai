plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
//--------------------------------------------------------------------

//-----------------------------------------------------------

android {
    namespace = "com.example.anticipatorygpt"
    compileSdk = flutter.compileSdkVersion
//    ndkVersion = flutter.ndkVersion
    ndkVersion="27.0.12077973" //chaged

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.bindu.bidyaai"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        //minSdk = flutter.minSdkVersion
        minSdk=24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works
            // .
            signingConfig = signingConfigs.getByName("debug")

            // --- CHANGES START HERE ---

            // 1. Enable R8 for code shrinking and obfuscation
            isMinifyEnabled = true

            // 2. Enable resource shrinking (often used with R8)
            isShrinkResources = true

            // 3. Specify the ProGuard/R8 rules file
            //    This tells R8 to use both the default optimized rules AND your custom rules
            //    from 'proguard-rules.pro' (where you'll paste content from missing_rules.txt)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro" // This file MUST exist in android/app/
            )
//            signingConfig = signingConfigs.getByName("debug")
        }
    }

//    this is added
    aaptOptions {
        noCompress("tflite","bin","onnx","dat","model","task")
    }

}

flutter {
    source = "../.."
}
