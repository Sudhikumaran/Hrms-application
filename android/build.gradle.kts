allprojects {
    repositories {
        google()
        mavenCentral()
    }
    
    configurations.all {
        // Exclude firebase-iid from all dependencies to resolve duplicate class conflict
        exclude(group = "com.google.firebase", module = "firebase-iid")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
