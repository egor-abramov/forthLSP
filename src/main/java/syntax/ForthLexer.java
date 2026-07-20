package syntax;

import com.intellij.lexer.LexerBase;
import com.intellij.psi.TokenType;
import com.intellij.psi.tree.IElementType;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.util.Set;

public class ForthLexer extends LexerBase {
    private CharSequence buffer;
    private int endOffset;
    private int position;
    private int tokenStart;
    private int tokenEnd;
    private IElementType tokenType;

    private static final Set<String> KEYWORDS = Set.of(
            "var", "string", "array", "import", "if", "else", "then", "loop", "endloop", "execute"
    );
    private static final Set<String> OPERATORS = Set.of(
            "+", "-", "*", "/", "%", "cells", "and", "not", "dup", "drop", "swap", "!", "@", "read", ".", "emit", "=0", ">0", "<0"
    );
    private static final Set<String> PUNCTUATION = Set.of(
            ":", ";", "(", ")", "->", "'"
    );

    @Override
    public void start(@NotNull CharSequence buffer, int startOffset, int endOffset, int initialState) {
        this.buffer = buffer;
        this.endOffset = endOffset;
        this.position = startOffset;
        advance();
    }

    @Override
    public void advance() {
        if (position >= endOffset) {
            tokenType = null;
            return;
        }

        tokenStart = position;
        char c = buffer.charAt(position);

        if (Character.isWhitespace(c)) {
            while (position < endOffset && Character.isWhitespace(buffer.charAt(position))) {
                position++;
            }
            tokenType = TokenType.WHITE_SPACE;
            tokenEnd = position;
            return;
        }

        if (c == '"') {
            do {
                position++;
            } while (position < endOffset && buffer.charAt(position) != '"');
            if (position < endOffset) {
                position++;
            }
            tokenType = ForthTokenTypes.STRING;
            tokenEnd = position;
            return;
        }

        while (position < endOffset && !Character.isWhitespace(buffer.charAt(position)) && buffer.charAt(position) != '"') {
            position++;
        }

        String tokenText = buffer.subSequence(tokenStart, position).toString();

        if (KEYWORDS.contains(tokenText)) {
            tokenType = ForthTokenTypes.KEYWORD;
        } else if (OPERATORS.contains(tokenText)) {
            tokenType = ForthTokenTypes.OPERATOR;
        } else if (PUNCTUATION.contains(tokenText)) {
            tokenType = ForthTokenTypes.PUNCTUATION;
        } else if (tokenText.matches("-?\\d+")) {
            tokenType = ForthTokenTypes.NUMBER;
        } else {
            tokenType = ForthTokenTypes.IDENTIFIER;
        }

        tokenEnd = position;
    }

    @Override
    public int getState() {
        return 0;
    }

    @Nullable
    @Override
    public IElementType getTokenType() {
        return tokenType;
    }

    @Override
    public int getTokenStart() {
        return tokenStart;
    }

    @Override
    public int getTokenEnd() {
        return tokenEnd;
    }

    @NotNull
    @Override
    public CharSequence getBufferSequence() {
        return buffer;
    }

    @Override
    public int getBufferEnd() {
        return endOffset;
    }
}