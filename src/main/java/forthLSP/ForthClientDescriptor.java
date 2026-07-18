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
        return new GeneralCommandLine("C:/Users/HONOR/Documents/haskell/haskellProject/dist-newstyle/build/x86_64-windows/ghc-9.6.7/haskellProject-0.1.0.0/x/haskellProject/build/haskellProject/haskellProject.exe", "--stdio");
    }
}