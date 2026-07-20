package syntax;

import com.intellij.psi.tree.IElementType;
import org.jspecify.annotations.NonNull;

public class ForthTokenType extends IElementType {

    public ForthTokenType(@NonNull String name) {
        super(name, ForthLanguage.INSTANCE);
    }
}
