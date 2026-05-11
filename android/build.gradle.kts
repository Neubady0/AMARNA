import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir = File(rootProject.projectDir, "../build").absoluteFile
rootProject.buildDir = newBuildDir

subprojects {
    project.buildDir = File(newBuildDir, project.name)
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.application") || project.plugins.hasPlugin("com.android.library")) {
            val androidExtensions = project.extensions.getByName("android")
            if (androidExtensions is com.android.build.gradle.BaseExtension) {
                androidExtensions.aaptOptions.ignoreAssetsPattern = "!.svn:!.git:!.ds_store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*~:!._*"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
