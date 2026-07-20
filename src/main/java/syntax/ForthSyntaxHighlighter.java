package syntax;

import com.intellij.lexer.Lexer;
import com.intellij.openapi.editor.DefaultLanguageHighlighterColors;
import com.intellij.openapi.editor.colors.TextAttributesKey;
import com.intellij.openapi.fileTypes.SyntaxHighlighterBase;
import com.intellij.psi.tree.IElementType;
import org.jetbrains.annotations.NotNull;
import org.jspecify.annotations.NonNull;

import static com.intellij.openapi.editor.colors.TextAttributesKey.createTextAttributesKey;

public class ForthSyntaxHighlighter extends SyntaxHighlighterBase {
    public static final TextAttributesKey KEYWORD =
            createTextAttributesKey("FORTH_KEYWORD", DefaultLanguageHighlighterColors.KEYWORD);
    public static final TextAttributesKey NUMBER =
            createTextAttributesKey("FORTH_NUMBER", DefaultLanguageHighlighterColors.NUMBER);
    public static final TextAttributesKey STRING =
            createTextAttributesKey("FORTH_STRING", DefaultLanguageHighlighterColors.STRING);
    public static final TextAttributesKey OPERATOR =
            createTextAttributesKey("FORTH_OPERATOR", DefaultLanguageHighlighterColors.OPERATION_SIGN);
    public static final TextAttributesKey IDENTIFIER =
            createTextAttributesKey("FORTH_IDENTIFIER", DefaultLanguageHighlighterColors.IDENTIFIER);

    @NotNull
    @Override
    public Lexer getHighlightingLexer() {
        return new ForthLexer();
    }

    @NotNull
    @Override
    public TextAttributesKey @NonNull [] getTokenHighlights(IElementType tokenType) {
        if (tokenType.equals(ForthTokenTypes.KEYWORD)) return new TextAttributesKey[]{KEYWORD};
        if (tokenType.equals(ForthTokenTypes.NUMBER)) return new TextAttributesKey[]{NUMBER};
        if (tokenType.equals(ForthTokenTypes.STRING)) return new TextAttributesKey[]{STRING};
        if (tokenType.equals(ForthTokenTypes.OPERATOR)) return new TextAttributesKey[]{OPERATOR};
        if (tokenType.equals(ForthTokenTypes.IDENTIFIER)) return new TextAttributesKey[]{IDENTIFIER};

        return new TextAttributesKey[0];
    }
}