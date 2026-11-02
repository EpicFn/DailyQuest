import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeyFile = rootProject.file("key.properties")
val releaseKeyProperties = Properties().apply {
    if (releaseKeyFile.isFile) {
        releaseKeyFile.reader(Charsets.UTF_8).use { load(it) }
    }
}

val checkReleaseSigning = tasks.register("checkReleaseSigning") {
    doLast {
        val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missing = required.filter { releaseKeyProperties.getProperty(it).isNullOrBlank() }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "Fill android/key.properties before building a release APK. Missing: ${missing.joinToString()}. " +
                    "Release builds never fall back to the debug key."
            )
        }
        if (!file(releaseKeyProperties.getProperty("storeFile")).isFile) {
            throw GradleException("The release keystore does not exist. Check storeFile in android/key.properties.")
        }
    }
}

tasks.matching { it.name == "preReleaseBuild" || it.name == "validateSigningRelease" }.configureEach {
    dependsOn(checkReleaseSigning)
}

android {
    namespace = "com.example.daily_quest"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.daily_quest"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = releaseKeyProperties.getProperty("storeFile")
                ?.takeIf { it.isNotBlank() }?.let { file(it) }
            storePassword = releaseKeyProperties.getProperty("storePassword")?.takeIf { it.isNotBlank() }
            keyAlias = releaseKeyProperties.getProperty("keyAlias")?.takeIf { it.isNotBlank() }
            keyPassword = releaseKeyProperties.getProperty("keyPassword")?.takeIf { it.isNotBlank() }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
