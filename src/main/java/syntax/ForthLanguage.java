package syntax;

import com.intellij.lang.Language;

public class ForthLanguage extends Language {
    public static ForthLanguage INSTANCE = new ForthLanguage();

    private ForthLanguage() {
        super("forth");
    }
}
