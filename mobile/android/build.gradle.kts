allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.projectDirectory
        .dir("../build")
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    if (project.name != "app") {
        afterEvaluate {
            if (project.plugins.hasPlugin("com.android.library")) {
                project.extensions.configure<com.android.build.gradle.LibraryExtension> {
                    compileSdk = 36
                }
            }
        }
    }
    
    // Gradle 9 / AGP validation fix for subproject AAR metadata directory
    tasks.matching { it.name.startsWith("bundle") && it.name.endsWith("Aar") }.configureEach {
        doFirst {
            val debugDir = layout.buildDirectory.dir("intermediates/aar_metadata_check/debug/checkDebugAarMetadata").get().asFile
            if (!debugDir.exists()) {
                debugDir.mkdirs()
            }
            val releaseDir = layout.buildDirectory.dir("intermediates/aar_metadata_check/release/checkReleaseAarMetadata").get().asFile
            if (!releaseDir.exists()) {
                releaseDir.mkdirs()
            }
        }
    }
}




tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
