allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    afterEvaluate {
        val p = this
        if (p.hasProperty("android")) {
            val extension = p.extensions.findByName("android")
            if (extension != null) {
                try {
                    val getCompileSdkVersion = extension.javaClass.getMethod("getCompileSdkVersion")
                    val currentCompileSdk = getCompileSdkVersion.invoke(extension)
                    if (currentCompileSdk == null) {
                        val setCompileSdkVersion = extension.javaClass.getMethod("setCompileSdkVersion", Any::class.java)
                        setCompileSdkVersion.invoke(extension, 35)
                    }
                } catch (e: Exception) {
                    // ignore
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
