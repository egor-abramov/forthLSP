import org.gradle.api.tasks.JavaExec

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
        val isCI = System.getenv("CI").toBoolean()

        if (isCI) {
            intellijIdea("2026.1.4")
        } else {
            local(file("C:/Program Files/JetBrains/IntelliJ IDEA 2026.1.4"))
        }
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

tasks.register<Exec>("buildServer") {
    group = "build"
    description = "Builds the LSP server"
    workingDir = file("server")
    commandLine("cabal", "build")
}

tasks.named<JavaExec>("runIde") {
    dependsOn("buildServer")

    val exePath = file("dist-newstyle/build/x86_64-windows/ghc-9.6.7/server-0.1.0.0/x/server/build/server/server.exe").absolutePath //[cite: 3]
    systemProperty("forthLsp.serverPath", exePath)
}
