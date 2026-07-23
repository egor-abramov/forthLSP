package lsp;

import com.intellij.execution.configurations.GeneralCommandLine;
import com.intellij.ide.plugins.PluginManagerCore;
import com.intellij.openapi.extensions.PluginId;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.util.SystemInfo;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.platform.lsp.api.LspClientDescriptor;
import org.jetbrains.annotations.NotNull;

import java.io.File;
import java.nio.file.Path;

public class ForthClientDescriptor extends LspClientDescriptor {

    public ForthClientDescriptor(@NotNull Project project) {
        super(project, "Forth");
    }

    @Override
    public boolean isSupportedFile(@NotNull VirtualFile file) {
        return "fth".equals(file.getExtension());
    }

    @NotNull
    @Override
    public GeneralCommandLine createCommandLine() {
        String serverPath = getServerExecutablePath();

        File serverFile = new File(serverPath);
        if (serverFile.exists() && !serverFile.canExecute()) {
            serverFile.setExecutable(true);
        }
        return new GeneralCommandLine(serverPath, "--stdio");
    }

    private String getServerExecutablePath() {
        String devPath = System.getProperty("forthLsp.serverPath");
        if (devPath != null && !devPath.isEmpty()) {
            return devPath;
        }

        PluginId pluginId = PluginId.getId("forth.lsp.plugin");
        var plugin = PluginManagerCore.getPlugin(pluginId);
        if (plugin == null) {
            throw new RuntimeException("Forth LSP Plugin not found");
        }

        String executableName;
        if (SystemInfo.isWindows) {
            executableName = "server-windows.exe";
        } else if (SystemInfo.isMac) {
            executableName = "server-macos";
        } else {
            executableName = "server-linux";
        }

        Path binDir = plugin.getPluginPath().resolve("bin");
        return binDir.resolve(executableName).toAbsolutePath().toString();
    }
}