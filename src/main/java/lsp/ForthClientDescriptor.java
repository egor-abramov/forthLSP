package forthLSP;

import com.intellij.execution.configurations.GeneralCommandLine;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.platform.lsp.api.LspClientDescriptor;
import org.jetbrains.annotations.NotNull;

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
        String serverPath = System.getProperty("forthLsp.serverPath");
        return new GeneralCommandLine(serverPath, "--stdio");
    }
}