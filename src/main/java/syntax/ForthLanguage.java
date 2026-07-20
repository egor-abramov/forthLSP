package forthLSP;

import com.intellij.lang.Language;
import org.jetbrains.annotations.NonNls;
import org.jetbrains.annotations.NotNull;

public class ForthLanguage extends Language {
    public static ForthLanguage INSTANCE = new ForthLanguage("forth");

    protected ForthLanguage(@NonNls @NotNull String ID) {
        super(ID);
    }
}
