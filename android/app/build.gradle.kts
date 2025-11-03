import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Add Firebase plugin
    id("com.google.gms.google-services")
}

// Load keystore properties if available
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.fortumars_hrm_app"
    compileSdk = 36  // Required by plugins (camera_android, geolocator_android, etc.)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Application ID - Update this to your own unique identifier before publishing
        // Format: com.yourcompany.yourapp
        applicationId = "com.example.fortumars_hrm_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    
    // Fix for plugins with old AndroidManifest package attributes
    packaging {
        jniLibs {
            useLegacyPackaging = true
        }
    }

    // Signing configurations
    signingConfigs {
        // Release signing (if key.properties exists)
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Use release signing if available, otherwise fall back to debug
            // For production: Create key.properties file with your release keystore
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug") // Fallback for testing
            }
            
            // Enable code shrinking and obfuscation for production
            isMinifyEnabled = false // Set to true if you want to enable ProGuard
            isShrinkResources = false // Set to true if you want to enable resource shrinking
            
            // ProGuard rules (even if minify is disabled, some rules help)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/DEPENDENCIES"
            excludes += "/META-INF/LICENSE"
            excludes += "/META-INF/LICENSE.txt"
            excludes += "/META-INF/license.txt"
            excludes += "/META-INF/NOTICE"
            excludes += "/META-INF/NOTICE.txt"
            excludes += "/META-INF/notice.txt"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add Firebase BoM (Bill of Materials) to manage Firebase dependency versions
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    
    // Firebase dependencies (versions managed by BoM above)
    // Note: firebase-core is deprecated and not needed
    // Exclude firebase-iid to resolve duplicate class conflict
    implementation("com.google.firebase:firebase-messaging") {
        exclude(group = "com.google.firebase", module = "firebase-iid")
    }
}
