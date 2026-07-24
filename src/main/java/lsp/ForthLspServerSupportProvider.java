package lsp;

import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.platform.lsp.api.LspServerSupportProvider;
import org.jetbrains.annotations.NotNull;

public class ForthLspServerSupportProvider implements LspServerSupportProvider {

    @Override
    public void fileOpened(@NotNull Project project, @NotNull VirtualFile file, @NotNull LspServerStarter serverStarter) {
        if ("fth".equals(file.getExtension())) {
            serverStarter.ensureServerStarted(new ForthClientDescriptor(project));
        }
    }
}