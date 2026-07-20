package syntax;

import com.intellij.psi.tree.IElementType;

public interface ForthTokenTypes {
    IElementType KEYWORD = new ForthTokenType("KEYWORD");
    IElementType OPERATOR = new ForthTokenType("OPERATOR");
    IElementType NUMBER = new ForthTokenType("NUMBER");
    IElementType STRING = new ForthTokenType("STRING");
    IElementType IDENTIFIER = new ForthTokenType("IDENTIFIER");
    IElementType PUNCTUATION = new ForthTokenType("PUNCTUATION");
}
