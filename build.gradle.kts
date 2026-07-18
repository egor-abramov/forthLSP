plugins {
    id("java")
    id("org.jetbrains.intellij.platform") version "2.18.1"
}

group = "forth"
version = "1.0"

repositories {
    mavenCentral()
    intellijPlatform {
        defaultRepositories()
    }
}

dependencies {
    intellijPlatform {
//        intellijIdeaUltimate("2026.1")
        local(file("C:/Program Files/JetBrains/IntelliJ IDEA 2026.1.4"))
    }
}

tasks.named("instrumentCode") {
    enabled = false
}

intellijPlatform {
    pluginConfiguration {
        id = "forth.lsp.plugin"
        version = project.version.toString()

        ideaVersion {
            sinceBuild = "261"
            untilBuild = provider { null }
        }
    }
}

java {
    toolchain {
        languageVersion = JavaLanguageVersion.of(21)
    }
}
