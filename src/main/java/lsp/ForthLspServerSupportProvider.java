package lsp;

import com.intellij.openapi.project.Project;
import com.intellij.openapi.vfs.VirtualFile;
import com.intellij.platform.lsp.api.LspIntegrationProvider;
import org.jetbrains.annotations.NotNull;

public class ForthLspServerSupportProvider implements LspIntegrationProvider {

    @Override
    public void fileOpened(
            @NotNull Project project,
            @NotNull VirtualFile file,
            @NotNull LspClientStarter serverStarter) {

        if ("fth".equals(file.getExtension())) {
            serverStarter.ensureClientStarted(new ForthClientDescriptor(project));
        }
    }
}