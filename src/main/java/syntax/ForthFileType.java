package syntax;

import com.intellij.openapi.fileTypes.LanguageFileType;
import com.intellij.openapi.util.IconLoader;
import com.intellij.openapi.util.NlsContexts;
import com.intellij.openapi.util.NlsSafe;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import javax.swing.Icon;

public class ForthFileType extends LanguageFileType {
    public static ForthFileType INSTANCE = new ForthFileType();

    private ForthFileType() {
        super(ForthLanguage.INSTANCE);
    }

    @Override
    public @NonNls @NotNull String getName() {
        return "Forth file";
    }

    @Override
    public @NlsContexts.Label @NotNull String getDescription() {
        return "Forth language file";
    }

    @Override
    public @NlsSafe @NotNull String getDefaultExtension() {
        return "fth";
    }

    @Override
    public @Nullable Icon getIcon() {
        return ForthIcon.FILE;
    }
}
