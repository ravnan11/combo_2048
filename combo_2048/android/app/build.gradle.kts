import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // O plugin do Flutter deve vir depois dos plugins Android e Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.afonsosolucoes.combo2048combo_2048"
    compileSdk = maxOf(34, flutter.compileSdkVersion)
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Alinhar com AGP 8.7/Kotlin 2.1
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    // -------- Carrega key.properties (keystore) --------
    val keystoreProperties = Properties()
    val keystorePropertiesFile = rootProject.file("key.properties")
    if (keystorePropertiesFile.exists()) {
        FileInputStream(keystorePropertiesFile).use { fis ->
            keystoreProperties.load(fis)
        }
    } else {
        println("⚠️  key.properties não encontrado na raiz. O build de release usará a config padrão (debug).")
    }

    defaultConfig {
        applicationId = "com.afonsosolucoes.combo2048combo_2048"
        minSdk = maxOf(23, 21)
        targetSdk = maxOf(34, flutter.targetSdkVersion)
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // App ID de TESTE por padrão (debug/fallback)
        manifestPlaceholders["ADMOB_APP_ID"] = "ca-app-pub-3940256099942544~3347511713"
    }

    // -------- Assinaturas --------
    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                val storePath = keystoreProperties["storeFile"] as String
                storeFile = file(storePath)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        debug {
            // Debug mantém App ID de teste
            manifestPlaceholders["ADMOB_APP_ID"] = "ca-app-pub-3940256099942544~3347511713"
            // applicationIdSuffix = ".debug"
            // versionNameSuffix = "-debug"
        }
        release {
            // ✅ Troque pelo App ID REAL do AdMob antes de publicar
            manifestPlaceholders["ADMOB_APP_ID"] = "SUA_APP_ID_AQUI"

            // Assinatura de release se existir keystore; senão cai no debug
            if (signingConfigs.findByName("release") != null) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                signingConfig = signingConfigs.getByName("debug")
            }

            isMinifyEnabled = false
            isShrinkResources = false
            // Para reduzir tamanho no futuro, ative e teste:
            // isMinifyEnabled = true
            // isShrinkResources = true
            // proguardFiles(
            //     getDefaultProguardFile("proguard-android-optimize.txt"),
            //     "proguard-rules.pro"
            // )
        }
    }
}

flutter {
    source = "../.."
}