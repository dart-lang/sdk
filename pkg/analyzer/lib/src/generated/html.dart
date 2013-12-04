// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.html;

import 'dart:collection';
import 'java_core.dart';
import 'java_engine.dart';
import 'source.dart';
import 'error.dart' show AnalysisErrorListener;
import 'scanner.dart' as sc show Scanner, SubSequenceReader, Token;
import 'parser.dart' show Parser;
import 'ast.dart' show ASTVisitor, CompilationUnit, Expression;
import 'element.dart' show HtmlElementImpl, HtmlScriptElement;
import 'engine.dart' show AnalysisEngine;

/**
 * Instances of the class `Token` represent a token that was scanned from the input. Each
 * token knows which token follows it, acting as the head of a linked list of tokens.
 *
 * @coverage dart.engine.html
 */
class Token {
  /**
   * The offset from the beginning of the file to the first character in the token.
   */
  int offset = 0;

  /**
   * The previous token in the token stream.
   */
  Token previous;

  /**
   * The next token in the token stream.
   */
  Token next;

  /**
   * The type of the token.
   */
  TokenType type;

  /**
   * The lexeme represented by this token.
   */
  String lexeme;

  /**
   * Initialize a newly created token.
   *
   * @param type the token type (not `null`)
   * @param offset the offset from the beginning of the file to the first character in the token
   */
  Token.con1(TokenType type, int offset) : this.con2(type, offset, type.lexeme);

  /**
   * Initialize a newly created token.
   *
   * @param type the token type (not `null`)
   * @param offset the offset from the beginning of the file to the first character in the token
   * @param value the lexeme represented by this token (not `null`)
   */
  Token.con2(TokenType type, int offset, String value) {
    this.type = type;
    this.lexeme = StringUtilities.intern(value);
    this.offset = offset;
  }

  /**
   * Return the offset from the beginning of the file to the character after last character of the
   * token.
   *
   * @return the offset from the beginning of the file to the first character after last character
   *         of the token
   */
  int get end => offset + length;

  /**
   * Return the number of characters in the node's source range.
   *
   * @return the number of characters in the node's source range
   */
  int get length => lexeme.length;

  /**
   * Return `true` if this token is a synthetic token. A synthetic token is a token that was
   * introduced by the parser in order to recover from an error in the code. Synthetic tokens always
   * have a length of zero (`0`).
   *
   * @return `true` if this token is a synthetic token
   */
  bool get isSynthetic => length == 0;

  /**
   * Set the next token in the token stream to the given token. This has the side-effect of setting
   * this token to be the previous token for the given token.
   *
   * @param token the next token in the token stream
   * @return the token that was passed in
   */
  Token setNext(Token token) {
    next = token;
    token.previous = this;
    return token;
  }

  String toString() => lexeme;
}

/**
 * Instances of the class `EmbeddedExpression` represent an expression enclosed between
 * <code>{{</code> and <code>}}</code> delimiters.
 */
class EmbeddedExpression {
  /**
   * The offset of the first character of the opening delimiter.
   */
  int openingOffset = 0;

  /**
   * The expression that is enclosed between the delimiters.
   */
  Expression expression;

  /**
   * The offset of the first character of the closing delimiter.
   */
  int closingOffset = 0;

  /**
   * An empty array of embedded expressions.
   */
  static List<EmbeddedExpression> EMPTY_ARRAY = new List<EmbeddedExpression>(0);

  /**
   * Initialize a newly created embedded expression to represent the given expression.
   *
   * @param openingOffset the offset of the first character of the opening delimiter
   * @param expression the expression that is enclosed between the delimiters
   * @param closingOffset the offset of the first character of the closing delimiter
   */
  EmbeddedExpression(int openingOffset, Expression expression, int closingOffset) {
    this.openingOffset = openingOffset;
    this.expression = expression;
    this.closingOffset = closingOffset;
  }
}

/**
 * Instances of `HtmlParseResult` hold the result of parsing an HTML file.
 *
 * @coverage dart.engine.html
 */
class HtmlParseResult extends HtmlScanResult {
  /**
   * The unit containing the parsed information (not `null`).
   */
  HtmlUnit htmlUnit;

  HtmlParseResult(int modificationTime, Token token, List<int> lineStarts, HtmlUnit unit) : super(modificationTime, token, lineStarts) {
    this.htmlUnit = unit;
  }
}

/**
 * Instances of the class `TagWithEmbeddedExpressions` represent a tag whose text content
 * contains one or more embedded expressions.
 */
class TagWithEmbeddedExpressions extends XmlTagNode {
  /**
   * The expressions that are embedded in the tag's content.
   */
  List<EmbeddedExpression> _expressions;

  /**
   * Initialize a newly created tag whose text content contains one or more embedded expressions.
   *
   * @param nodeStart the token marking the beginning of the tag
   * @param tag the name of the tag
   * @param attributes the attributes in the tag
   * @param attributeEnd the token terminating the region where attributes can be
   * @param tagNodes the children of the tag
   * @param contentEnd the token that starts the closing tag
   * @param closingTag the name of the tag that occurs in the closing tag
   * @param nodeEnd the last token in the tag
   * @param expressions the expressions that are embedded in the value
   */
  TagWithEmbeddedExpressions(Token nodeStart, Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd, List<EmbeddedExpression> expressions) : super(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd) {
    this._expressions = expressions;
  }

  List<EmbeddedExpression> get expressions => _expressions;
}

/**
 * Instances of the class `RecursiveXmlVisitor` implement an XML visitor that will recursively
 * visit all of the nodes in an XML structure. For example, using an instance of this class to visit
 * a [XmlTagNode] will also cause all of the contained [XmlAttributeNode]s and
 * [XmlTagNode]s to be visited.
 *
 * Subclasses that override a visit method must either invoke the overridden visit method or must
 * explicitly ask the visited node to visit its children. Failure to do so will cause the children
 * of the visited node to not be visited.
 *
 * @coverage dart.engine.html
 */
class RecursiveXmlVisitor<R> implements XmlVisitor<R> {
  R visitHtmlScriptTagNode(HtmlScriptTagNode node) {
    node.visitChildren(this);
    return null;
  }

  R visitHtmlUnit(HtmlUnit node) {
    node.visitChildren(this);
    return null;
  }

  R visitXmlAttributeNode(XmlAttributeNode node) {
    node.visitChildren(this);
    return null;
  }

  R visitXmlTagNode(XmlTagNode node) {
    node.visitChildren(this);
    return null;
  }
}

/**
 * Instances of the class `HtmlScriptTagNode` represent a script tag within an HTML file that
 * references a Dart script.
 */
class HtmlScriptTagNode extends XmlTagNode {
  /**
   * The AST structure representing the Dart code within this tag.
   */
  CompilationUnit _script;

  /**
   * The element representing this script.
   */
  HtmlScriptElement scriptElement;

  /**
   * Initialize a newly created node to represent a script tag within an HTML file that references a
   * Dart script.
   *
   * @param nodeStart the token marking the beginning of the tag
   * @param tag the name of the tag
   * @param attributes the attributes in the tag
   * @param attributeEnd the token terminating the region where attributes can be
   * @param tagNodes the children of the tag
   * @param contentEnd the token that starts the closing tag
   * @param closingTag the name of the tag that occurs in the closing tag
   * @param nodeEnd the last token in the tag
   */
  HtmlScriptTagNode(Token nodeStart, Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd) : super(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);

  accept(XmlVisitor visitor) => visitor.visitHtmlScriptTagNode(this);

  /**
   * Return the AST structure representing the Dart code within this tag, or `null` if this
   * tag references an external script.
   *
   * @return the AST structure representing the Dart code within this tag
   */
  CompilationUnit get script => _script;

  /**
   * Set the AST structure representing the Dart code within this tag to the given compilation unit.
   *
   * @param unit the AST structure representing the Dart code within this tag
   */
  void set script(CompilationUnit unit) {
    _script = unit;
  }
}

/**
 * The abstract class `XmlNode` defines behavior common to all XML/HTML nodes.
 *
 * @coverage dart.engine.html
 */
abstract class XmlNode {
  /**
   * The parent of the node, or `null` if the node is the root of an AST structure.
   */
  XmlNode _parent;

  /**
   * Use the given visitor to visit this node.
   *
   * @param visitor the visitor that will visit this node
   * @return the value returned by the visitor as a result of visiting this node
   */
  accept(XmlVisitor visitor);

  /**
   * Return the first token included in this node's source range.
   *
   * @return the first token or `null` if none
   */
  Token get beginToken;

  /**
   * Return the offset of the character immediately following the last character of this node's
   * source range. This is equivalent to `node.getOffset() + node.getLength()`. For an html
   * unit this will be equal to the length of the unit's source.
   *
   * @return the offset of the character just past the node's source range
   */
  int get end => offset + length;

  /**
   * Return the last token included in this node's source range.
   *
   * @return the last token or `null` if none
   */
  Token get endToken;

  /**
   * Return the number of characters in the node's source range.
   *
   * @return the number of characters in the node's source range
   */
  int get length {
    Token beginToken = this.beginToken;
    Token endToken = this.endToken;
    if (beginToken == null || endToken == null) {
      return -1;
    }
    return endToken.offset + endToken.length - beginToken.offset;
  }

  /**
   * Return the offset from the beginning of the file to the first character in the node's source
   * range.
   *
   * @return the offset from the beginning of the file to the first character in the node's source
   *         range
   */
  int get offset {
    Token beginToken = this.beginToken;
    if (beginToken == null) {
      return -1;
    }
    return this.beginToken.offset;
  }

  /**
   * Return this node's parent node, or `null` if this node is the root of an AST structure.
   *
   * Note that the relationship between an AST node and its parent node may change over the lifetime
   * of a node.
   *
   * @return the parent of this node, or `null` if none
   */
  XmlNode get parent => _parent;

  String toString() {
    PrintStringWriter writer = new PrintStringWriter();
    accept(new ToSourceVisitor(writer));
    return writer.toString();
  }

  /**
   * Use the given visitor to visit all of the children of this node. The children will be visited
   * in source order.
   *
   * @param visitor the visitor that will be used to visit the children of this node
   */
  void visitChildren(XmlVisitor visitor);

  /**
   * Make this node the parent of the given child nodes.
   *
   * @param children the nodes that will become the children of this node
   * @return the nodes that were made children of this node
   */
  List becomeParentOf(List children) {
    if (children != null) {
      for (JavaIterator iter = new JavaIterator(children); iter.hasNext;) {
        XmlNode node = iter.next();
        node.parent = this;
      }
      return new List.from(children);
    }
    return children;
  }

  /**
   * Make this node the parent of the given child node.
   *
   * @param child the node that will become a child of this node
   * @return the node that was made a child of this node
   */
  XmlNode becomeParentOf2(XmlNode child) {
    if (child != null) {
      XmlNode node = child;
      node.parent = this;
    }
    return child;
  }

  /**
   * This method exists for debugging purposes only.
   */
  void appendIdentifier(JavaStringBuilder builder, XmlNode node) {
    if (node is XmlTagNode) {
      builder.append((node as XmlTagNode).tag.lexeme);
    } else if (node is XmlAttributeNode) {
      builder.append((node as XmlAttributeNode).name.lexeme);
    } else {
      builder.append("htmlUnit");
    }
  }

  /**
   * This method exists for debugging purposes only.
   */
  String buildRecursiveStructureMessage(XmlNode newParent) {
    JavaStringBuilder builder = new JavaStringBuilder();
    builder.append("Attempt to create recursive structure: ");
    XmlNode current = newParent;
    while (current != null) {
      if (current != newParent) {
        builder.append(" -> ");
      }
      if (identical(current, this)) {
        builder.appendChar(0x2A);
        appendIdentifier(builder, current);
        builder.appendChar(0x2A);
      } else {
        appendIdentifier(builder, current);
      }
      current = current.parent;
    }
    return builder.toString();
  }

  /**
   * Set the parent of this node to the given node.
   *
   * @param newParent the node that is to be made the parent of this node
   */
  void set parent(XmlNode newParent) {
    XmlNode current = newParent;
    while (current != null) {
      if (identical(current, this)) {
        AnalysisEngine.instance.logger.logError3(new IllegalArgumentException(buildRecursiveStructureMessage(newParent)));
        return;
      }
      current = current.parent;
    }
    _parent = newParent;
  }
}

/**
 * Instances of the class `AttributeWithEmbeddedExpressions` represent an attribute whose
 * value contains one or more embedded expressions.
 */
class AttributeWithEmbeddedExpressions extends XmlAttributeNode {
  /**
   * The expressions that are embedded in the attribute's value.
   */
  List<EmbeddedExpression> _expressions;

  /**
   * Initialize a newly created attribute whose value contains one or more embedded expressions.
   *
   * @param name the name of the attribute
   * @param equals the equals sign separating the name from the value
   * @param value the value of the attribute
   * @param expressions the expressions that are embedded in the value
   */
  AttributeWithEmbeddedExpressions(Token name, Token equals, Token value, List<EmbeddedExpression> expressions) : super(name, equals, value) {
    this._expressions = expressions;
  }

  List<EmbeddedExpression> get expressions => _expressions;
}

/**
 * Instances of the class `SimpleXmlVisitor` implement an AST visitor that will do nothing
 * when visiting an AST node. It is intended to be a superclass for classes that use the visitor
 * pattern primarily as a dispatch mechanism (and hence don't need to recursively visit a whole
 * structure) and that only need to visit a small number of node types.
 */
class SimpleXmlVisitor<R> implements XmlVisitor<R> {
  R visitHtmlScriptTagNode(HtmlScriptTagNode node) => null;

  R visitHtmlUnit(HtmlUnit htmlUnit) => null;

  R visitXmlAttributeNode(XmlAttributeNode xmlAttributeNode) => null;

  R visitXmlTagNode(XmlTagNode xmlTagNode) => null;
}

/**
 * The abstract class `AbstractScanner` implements a scanner for HTML code. Subclasses are
 * required to implement the interface used to access the characters being scanned.
 *
 * @coverage dart.engine.html
 */
abstract class AbstractScanner {
  static List<String> _NO_PASS_THROUGH_ELEMENTS = <String> [];

  /**
   * The source being scanned.
   */
  Source source;

  /**
   * The token pointing to the head of the linked list of tokens.
   */
  Token _tokens;

  /**
   * The last token that was scanned.
   */
  Token _tail;

  /**
   * A list containing the offsets of the first character of each line in the source code.
   */
  List<int> _lineStarts = new List<int>();

  /**
   * An array of element tags for which the content between tags should be consider a single token.
   */
  List<String> _passThroughElements = _NO_PASS_THROUGH_ELEMENTS;

  /**
   * Initialize a newly created scanner.
   *
   * @param source the source being scanned
   */
  AbstractScanner(Source source) {
    this.source = source;
    _tokens = new Token.con1(TokenType.EOF, -1);
    _tokens.setNext(_tokens);
    _tail = _tokens;
    recordStartOfLine();
  }

  /**
   * Return an array containing the offsets of the first character of each line in the source code.
   *
   * @return an array containing the offsets of the first character of each line in the source code
   */
  List<int> get lineStarts => _lineStarts;

  /**
   * Return the current offset relative to the beginning of the file. Return the initial offset if
   * the scanner has not yet scanned the source code, and one (1) past the end of the source code if
   * the source code has been scanned.
   *
   * @return the current offset of the scanner in the source
   */
  int get offset;

  /**
   * Set array of element tags for which the content between tags should be consider a single token.
   */
  void set passThroughElements(List<String> passThroughElements) {
    this._passThroughElements = passThroughElements != null ? passThroughElements : _NO_PASS_THROUGH_ELEMENTS;
  }

  /**
   * Scan the source code to produce a list of tokens representing the source.
   *
   * @return the first token in the list of tokens that were produced
   */
  Token tokenize() {
    scan();
    appendEofToken();
    return firstToken();
  }

  /**
   * Advance the current position and return the character at the new current position.
   *
   * @return the character at the new current position
   */
  int advance();

  /**
   * Return the substring of the source code between the start offset and the modified current
   * position. The current position is modified by adding the end delta.
   *
   * @param start the offset to the beginning of the string, relative to the start of the file
   * @param endDelta the number of character after the current location to be included in the
   *          string, or the number of characters before the current location to be excluded if the
   *          offset is negative
   * @return the specified substring of the source code
   */
  String getString(int start, int endDelta);

  /**
   * Return the character at the current position without changing the current position.
   *
   * @return the character at the current position
   */
  int peek();

  /**
   * Record the fact that we are at the beginning of a new line in the source.
   */
  void recordStartOfLine() {
    _lineStarts.add(offset);
  }

  void appendEofToken() {
    Token eofToken = new Token.con1(TokenType.EOF, offset);
    eofToken.setNext(eofToken);
    _tail = _tail.setNext(eofToken);
  }

  Token emit(Token token) {
    _tail.setNext(token);
    _tail = token;
    return token;
  }

  Token emit2(TokenType type, int start) => emit(new Token.con1(type, start));

  Token emit3(TokenType type, int start, int count) => emit(new Token.con2(type, start, getString(start, count)));

  Token firstToken() => _tokens.next;

  int recordStartOfLineAndAdvance(int c) {
    if (c == 0xD) {
      c = advance();
      if (c == 0xA) {
        c = advance();
      }
      recordStartOfLine();
    } else if (c == 0xA) {
      c = advance();
      recordStartOfLine();
    } else {
      c = advance();
    }
    return c;
  }

  void scan() {
    bool inBrackets = false;
    String endPassThrough = null;
    int c = advance();
    while (c >= 0) {
      int start = offset;
      if (c == 0x3C) {
        c = advance();
        if (c == 0x21) {
          c = advance();
          if (c == 0x2D && peek() == 0x2D) {
            c = advance();
            int dashCount = 1;
            while (c >= 0) {
              if (c == 0x2D) {
                dashCount++;
              } else if (c == 0x3E && dashCount >= 2) {
                c = advance();
                break;
              } else {
                dashCount = 0;
              }
              c = recordStartOfLineAndAdvance(c);
            }
            emit3(TokenType.COMMENT, start, -1);
            if (_tail.length < 7) {
            }
          } else {
            while (c >= 0) {
              if (c == 0x3E) {
                c = advance();
                break;
              }
              c = recordStartOfLineAndAdvance(c);
            }
            emit3(TokenType.DECLARATION, start, -1);
            if (!_tail.lexeme.endsWith(">")) {
            }
          }
        } else if (c == 0x3F) {
          while (c >= 0) {
            if (c == 0x3F) {
              c = advance();
              if (c == 0x3E) {
                c = advance();
                break;
              }
            } else {
              c = recordStartOfLineAndAdvance(c);
            }
          }
          emit3(TokenType.DIRECTIVE, start, -1);
          if (_tail.length < 4) {
          }
        } else if (c == 0x2F) {
          emit2(TokenType.LT_SLASH, start);
          inBrackets = true;
          c = advance();
        } else {
          inBrackets = true;
          emit2(TokenType.LT, start);
          while (Character.isWhitespace(c)) {
            c = recordStartOfLineAndAdvance(c);
          }
          if (Character.isLetterOrDigit(c)) {
            int tagStart = offset;
            c = advance();
            while (Character.isLetterOrDigit(c) || c == 0x2D || c == 0x5F) {
              c = advance();
            }
            emit3(TokenType.TAG, tagStart, -1);
            String tag = _tail.lexeme;
            for (String str in _passThroughElements) {
              if (str == tag) {
                endPassThrough = "</${str}>";
                break;
              }
            }
          }
        }
      } else if (c == 0x3E) {
        emit2(TokenType.GT, start);
        inBrackets = false;
        c = advance();
        if (endPassThrough != null) {
          bool endFound = false;
          int len = endPassThrough.length;
          int firstC = endPassThrough.codeUnitAt(0);
          int index = 0;
          int nextC = firstC;
          while (c >= 0) {
            if (c == nextC) {
              index++;
              if (index == len) {
                endFound = true;
                break;
              }
              nextC = endPassThrough.codeUnitAt(index);
            } else if (c == firstC) {
              index = 1;
              nextC = endPassThrough.codeUnitAt(1);
            } else {
              index = 0;
              nextC = firstC;
            }
            c = recordStartOfLineAndAdvance(c);
          }
          if (start + 1 < offset) {
            if (endFound) {
              emit3(TokenType.TEXT, start + 1, -len);
              emit2(TokenType.LT_SLASH, offset - len + 1);
              emit3(TokenType.TAG, offset - len + 3, -1);
            } else {
              emit3(TokenType.TEXT, start + 1, -1);
            }
          }
          endPassThrough = null;
        }
      } else if (c == 0x2F && peek() == 0x3E) {
        advance();
        emit2(TokenType.SLASH_GT, start);
        inBrackets = false;
        c = advance();
      } else if (!inBrackets) {
        c = recordStartOfLineAndAdvance(c);
        while (c != 0x3C && c >= 0) {
          c = recordStartOfLineAndAdvance(c);
        }
        emit3(TokenType.TEXT, start, -1);
      } else if (c == 0x22 || c == 0x27) {
        int endQuote = c;
        c = advance();
        while (c >= 0) {
          if (c == endQuote) {
            c = advance();
            break;
          }
          c = recordStartOfLineAndAdvance(c);
        }
        emit3(TokenType.STRING, start, -1);
      } else if (c == 0x3D) {
        emit2(TokenType.EQ, start);
        c = advance();
      } else if (Character.isWhitespace(c)) {
        do {
          c = recordStartOfLineAndAdvance(c);
        } while (Character.isWhitespace(c));
      } else if (Character.isLetterOrDigit(c)) {
        c = advance();
        while (Character.isLetterOrDigit(c) || c == 0x2D || c == 0x5F) {
          c = advance();
        }
        emit3(TokenType.TAG, start, -1);
      } else {
        emit3(TokenType.TEXT, start, 0);
        c = advance();
      }
    }
  }
}

/**
 * Instances of `HtmlScanResult` hold the result of scanning an HTML file.
 *
 * @coverage dart.engine.html
 */
class HtmlScanResult {
  /**
   * The time at which the contents of the source were last set.
   */
  int modificationTime = 0;

  /**
   * The first token in the token stream (not `null`).
   */
  Token token;

  /**
   * The line start information that was produced.
   */
  List<int> lineStarts;

  HtmlScanResult(int modificationTime, Token token, List<int> lineStarts) {
    this.modificationTime = modificationTime;
    this.token = token;
    this.lineStarts = lineStarts;
  }
}

/**
 * Instances of the class `StringScanner` implement a scanner that reads from a string. The
 * scanning logic is in the superclass.
 *
 * @coverage dart.engine.html
 */
class StringScanner extends AbstractScanner {
  /**
   * The string from which characters will be read.
   */
  String _string;

  /**
   * The number of characters in the string.
   */
  int _stringLength = 0;

  /**
   * The index, relative to the string, of the last character that was read.
   */
  int _charOffset = 0;

  /**
   * Initialize a newly created scanner to scan the characters in the given string.
   *
   * @param source the source being scanned
   * @param string the string from which characters will be read
   */
  StringScanner(Source source, String string) : super(source) {
    this._string = string;
    this._stringLength = string.length;
    this._charOffset = -1;
  }

  int get offset => _charOffset;

  void set offset(int offset) {
    _charOffset = offset;
  }

  int advance() {
    if (++_charOffset < _stringLength) {
      return _string.codeUnitAt(_charOffset);
    }
    _charOffset = _stringLength;
    return -1;
  }

  String getString(int start, int endDelta) => _string.substring(start, _charOffset + 1 + endDelta);

  int peek() {
    if (_charOffset + 1 < _stringLength) {
      return _string.codeUnitAt(_charOffset + 1);
    }
    return -1;
  }
}

/**
 * Instances of the class `CharBufferScanner` implement a scanner that reads from a character
 * buffer. The scanning logic is in the superclass.
 *
 * @coverage dart.engine.html
 */
class CharBufferScanner extends AbstractScanner {
  /**
   * The buffer from which characters will be read.
   */
  CharSequence _buffer;

  /**
   * The number of characters in the buffer.
   */
  int _bufferLength = 0;

  /**
   * The index of the last character that was read.
   */
  int _charOffset = 0;

  /**
   * Initialize a newly created scanner to scan the characters in the given character buffer.
   *
   * @param source the source being scanned
   * @param buffer the buffer from which characters will be read
   */
  CharBufferScanner(Source source, CharSequence buffer) : super(source) {
    this._buffer = buffer;
    this._bufferLength = buffer.length();
    this._charOffset = -1;
  }

  int get offset => _charOffset;

  int advance() {
    if (++_charOffset < _bufferLength) {
      return _buffer.charAt(_charOffset);
    }
    _charOffset = _bufferLength;
    return -1;
  }

  String getString(int start, int endDelta) => _buffer.subSequence(start, _charOffset + 1 + endDelta).toString();

  int peek() {
    if (_charOffset + 1 < _bufferLength) {
      return _buffer.charAt(_charOffset + 1);
    }
    return -1;
  }
}

/**
 * Instances of the class `ToSourceVisitor` write a source representation of a visited XML
 * node (and all of it's children) to a writer.
 *
 * @coverage dart.engine.html
 */
class ToSourceVisitor implements XmlVisitor<Object> {
  /**
   * The writer to which the source is to be written.
   */
  PrintWriter _writer;

  /**
   * Initialize a newly created visitor to write source code representing the visited nodes to the
   * given writer.
   *
   * @param writer the writer to which the source is to be written
   */
  ToSourceVisitor(PrintWriter writer) {
    this._writer = writer;
  }

  Object visitHtmlScriptTagNode(HtmlScriptTagNode node) => visitXmlTagNode(node);

  Object visitHtmlUnit(HtmlUnit node) {
    for (XmlTagNode child in node.tagNodes) {
      visit(child);
    }
    return null;
  }

  Object visitXmlAttributeNode(XmlAttributeNode node) {
    String name = node.name.lexeme;
    Token value = node.value;
    if (name.length == 0) {
      _writer.print("__");
    } else {
      _writer.print(name);
    }
    _writer.print("=");
    if (value == null) {
      _writer.print("__");
    } else {
      _writer.print(value.lexeme);
    }
    return null;
  }

  Object visitXmlTagNode(XmlTagNode node) {
    _writer.print("<");
    String tagName = node.tag.lexeme;
    _writer.print(tagName);
    for (XmlAttributeNode attribute in node.attributes) {
      _writer.print(" ");
      visit(attribute);
    }
    _writer.print(node.attributeEnd.lexeme);
    if (node.closingTag != null) {
      for (XmlTagNode child in node.tagNodes) {
        visit(child);
      }
      _writer.print("</");
      _writer.print(tagName);
      _writer.print(">");
    }
    return null;
  }

  /**
   * Safely visit the given node.
   *
   * @param node the node to be visited
   */
  void visit(XmlNode node) {
    if (node != null) {
      node.accept(this);
    }
  }
}

/**
 * The enumeration `TokenType` defines the types of tokens that can be returned by the
 * scanner.
 *
 * @coverage dart.engine.html
 */
class TokenType extends Enum<TokenType> {
  /**
   * The type of the token that marks the end of the input.
   */
  static final TokenType EOF = new TokenType_EOF('EOF', 0, "");

  static final TokenType EQ = new TokenType('EQ', 1, "=");

  static final TokenType GT = new TokenType('GT', 2, ">");

  static final TokenType LT_SLASH = new TokenType('LT_SLASH', 3, "</");

  static final TokenType LT = new TokenType('LT', 4, "<");

  static final TokenType SLASH_GT = new TokenType('SLASH_GT', 5, "/>");

  static final TokenType COMMENT = new TokenType('COMMENT', 6, null);

  static final TokenType DECLARATION = new TokenType('DECLARATION', 7, null);

  static final TokenType DIRECTIVE = new TokenType('DIRECTIVE', 8, null);

  static final TokenType STRING = new TokenType('STRING', 9, null);

  static final TokenType TAG = new TokenType('TAG', 10, null);

  static final TokenType TEXT = new TokenType('TEXT', 11, null);

  static final List<TokenType> values = [
      EOF,
      EQ,
      GT,
      LT_SLASH,
      LT,
      SLASH_GT,
      COMMENT,
      DECLARATION,
      DIRECTIVE,
      STRING,
      TAG,
      TEXT];

  /**
   * The lexeme that defines this type of token, or `null` if there is more than one possible
   * lexeme for this type of token.
   */
  String lexeme;

  TokenType(String name, int ordinal, String lexeme) : super(name, ordinal) {
    this.lexeme = lexeme;
  }
}

class TokenType_EOF extends TokenType {
  TokenType_EOF(String name, int ordinal, String arg0) : super(name, ordinal, arg0);

  String toString() => "-eof-";
}

/**
 * Instances of `XmlAttributeNode` represent name/value pairs owned by an [XmlTagNode].
 *
 * @coverage dart.engine.html
 */
class XmlAttributeNode extends XmlNode {
  Token name;

  Token equals;

  Token value;

  /**
   * Construct a new instance representing an XML attribute.
   *
   * @param name the name token (not `null`). This may be a zero length token if the attribute
   *          is badly formed.
   * @param equals the equals sign or `null` if none
   * @param value the value token (not `null`)
   */
  XmlAttributeNode(Token name, Token equals, Token value) {
    this.name = name;
    this.equals = equals;
    this.value = value;
  }

  accept(XmlVisitor visitor) => visitor.visitXmlAttributeNode(this);

  Token get beginToken => name;

  Token get endToken => value;

  /**
   * Return the expressions that are embedded in the attribute's value.
   *
   * @return the expressions that are embedded in the attribute's value
   */
  List<EmbeddedExpression> get expressions => EmbeddedExpression.EMPTY_ARRAY;

  /**
   * Answer the lexeme for the value token without the leading and trailing quotes.
   *
   * @return the text or `null` if the value is not specified
   */
  String get text {
    if (value == null) {
      return null;
    }
    String text = value.lexeme;
    int len = text.length;
    if (len > 0) {
      if (text.codeUnitAt(0) == 0x22) {
        if (len > 1 && text.codeUnitAt(len - 1) == 0x22) {
          return text.substring(1, len - 1);
        } else {
          return text.substring(1);
        }
      } else if (text.codeUnitAt(0) == 0x27) {
        if (len > 1 && text.codeUnitAt(len - 1) == 0x27) {
          return text.substring(1, len - 1);
        } else {
          return text.substring(1);
        }
      }
    }
    return text;
  }

  void visitChildren(XmlVisitor visitor) {
  }
}

/**
 * Instances of the class `EmbeddedDartVisitor` implement a recursive visitor for HTML files
 * that will invoke another visitor on all embedded dart scripts and expressions.
 */
class EmbeddedDartVisitor<R> implements XmlVisitor<R> {
  /**
   * The visitor used to visit embedded Dart code.
   */
  ASTVisitor<R> _dartVisitor;

  /**
   * Initialize a newly created visitor to visit all of the nodes in an HTML structure and to use
   * the given visitor to visit all of the nodes representing any embedded scripts or expressions.
   *
   * @param dartVisitor the visitor used to visit embedded Dart code
   */
  EmbeddedDartVisitor(ASTVisitor<R> dartVisitor) {
    this._dartVisitor = dartVisitor;
  }

  R visitHtmlScriptTagNode(HtmlScriptTagNode node) {
    node.visitChildren(this);
    CompilationUnit script = node.script;
    if (script != null) {
      script.accept(_dartVisitor);
    }
    return null;
  }

  R visitHtmlUnit(HtmlUnit node) {
    node.visitChildren(this);
    return null;
  }

  R visitXmlAttributeNode(XmlAttributeNode node) {
    node.visitChildren(this);
    for (EmbeddedExpression expression in node.expressions) {
      expression.expression.accept(_dartVisitor);
    }
    return null;
  }

  R visitXmlTagNode(XmlTagNode node) {
    node.visitChildren(this);
    for (EmbeddedExpression expression in node.expressions) {
      expression.expression.accept(_dartVisitor);
    }
    return null;
  }
}

/**
 * The interface `XmlVisitor` defines the behavior of objects that can be used to visit an
 * [XmlNode] structure.
 *
 * @coverage dart.engine.html
 */
abstract class XmlVisitor<R> {
  R visitHtmlScriptTagNode(HtmlScriptTagNode node);

  R visitHtmlUnit(HtmlUnit htmlUnit);

  R visitXmlAttributeNode(XmlAttributeNode xmlAttributeNode);

  R visitXmlTagNode(XmlTagNode xmlTagNode);
}

/**
 * Instances of `HtmlScanner` receive and scan HTML content from a [Source].<br/>
 * For example, the following code scans HTML source and returns the result:
 *
 * <pre>
 *   HtmlScanner scanner = new HtmlScanner(source);
 *   source.getContents(scanner);
 *   return scanner.getResult();
 * </pre>
 *
 * @coverage dart.engine.html
 */
class HtmlScanner implements Source_ContentReceiver {
  List<String> _SCRIPT_TAG = <String> ["script"];

  /**
   * The source being scanned (not `null`)
   */
  Source _source;

  /**
   * The time at which the contents of the source were last set.
   */
  int _modificationTime = 0;

  /**
   * The scanner used to scan the source
   */
  AbstractScanner _scanner;

  /**
   * The first token in the token stream.
   */
  Token _token;

  /**
   * Construct a new instance to scan the specified source.
   *
   * @param source the source to be scanned (not `null`)
   */
  HtmlScanner(Source source) {
    this._source = source;
  }

  void accept(CharBuffer contents, int modificationTime) {
    this._modificationTime = modificationTime;
    _scanner = new CharBufferScanner(_source, contents);
    _scanner.passThroughElements = _SCRIPT_TAG;
    _token = _scanner.tokenize();
  }

  void accept2(String contents, int modificationTime) {
    this._modificationTime = modificationTime;
    _scanner = new StringScanner(_source, contents);
    _scanner.passThroughElements = _SCRIPT_TAG;
    _token = _scanner.tokenize();
  }

  /**
   * Answer the result of scanning the source
   *
   * @return the result (not `null`)
   */
  HtmlScanResult get result => new HtmlScanResult(_modificationTime, _token, _scanner.lineStarts);
}

/**
 * Instances of the class `XmlParser` are used to parse tokens into a AST structure comprised
 * of [XmlNode]s.
 *
 * @coverage dart.engine.html
 */
class XmlParser {
  /**
   * The source being parsed.
   */
  Source source;

  /**
   * The next token to be parsed.
   */
  Token currentToken;

  /**
   * Construct a parser for the specified source.
   *
   * @param source the source being parsed
   */
  XmlParser(Source source) {
    this.source = source;
  }

  /**
   * Create a node representing an attribute.
   *
   * @param name the name of the attribute
   * @param equals the equals sign, or `null` if there is no value
   * @param value the value of the attribute
   * @return the node that was created
   */
  XmlAttributeNode createAttributeNode(Token name, Token equals, Token value) => new XmlAttributeNode(name, equals, value);

  /**
   * Create a node representing a tag.
   *
   * @param nodeStart the token marking the beginning of the tag
   * @param tag the name of the tag
   * @param attributes the attributes in the tag
   * @param attributeEnd the token terminating the region where attributes can be
   * @param tagNodes the children of the tag
   * @param contentEnd the token that starts the closing tag
   * @param closingTag the name of the tag that occurs in the closing tag
   * @param nodeEnd the last token in the tag
   * @return the node that was created
   */
  XmlTagNode createTagNode(Token nodeStart, Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd) => new XmlTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);

  /**
   * Answer `true` if the specified tag is self closing and thus should never have content or
   * child tag nodes.
   *
   * @param tag the tag (not `null`)
   * @return `true` if self closing
   */
  bool isSelfClosing(Token tag) => false;

  /**
   * Parse the entire token stream and in the process, advance the current token to the end of the
   * token stream.
   *
   * @return the list of tag nodes found (not `null`, contains no `null`)
   */
  List<XmlTagNode> parseTopTagNodes(Token firstToken) {
    currentToken = firstToken;
    List<XmlTagNode> tagNodes = new List<XmlTagNode>();
    while (true) {
      while (true) {
        if (currentToken.type == TokenType.LT) {
          tagNodes.add(parseTagNode());
        } else if (currentToken.type == TokenType.DECLARATION || currentToken.type == TokenType.DIRECTIVE || currentToken.type == TokenType.COMMENT) {
          currentToken = currentToken.next;
        } else if (currentToken.type == TokenType.EOF) {
          return tagNodes;
        } else {
          reportUnexpectedToken();
          currentToken = currentToken.next;
        }
        break;
      }
    }
  }

  /**
   * Insert a synthetic token of the specified type before the current token
   *
   * @param type the type of token to be inserted (not `null`)
   * @return the synthetic token that was inserted (not `null`)
   */
  Token insertSyntheticToken(TokenType type) {
    Token token = new Token.con2(type, currentToken.offset, "");
    currentToken.previous.setNext(token);
    token.setNext(currentToken);
    return token;
  }

  /**
   * Parse the token stream for an attribute. This method advances the current token over the
   * attribute, but should not be called if the [currentToken] is not [TokenType#TAG].
   *
   * @return the attribute (not `null`)
   */
  XmlAttributeNode parseAttribute() {
    Token name = currentToken;
    currentToken = currentToken.next;
    Token equals;
    if (identical(currentToken.type, TokenType.EQ)) {
      equals = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      equals = insertSyntheticToken(TokenType.EQ);
    }
    Token value;
    if (identical(currentToken.type, TokenType.STRING)) {
      value = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      value = insertSyntheticToken(TokenType.STRING);
    }
    return createAttributeNode(name, equals, value);
  }

  /**
   * Parse the stream for a sequence of attributes. This method advances the current token to the
   * next [TokenType#GT], [TokenType#SLASH_GT], or [TokenType#EOF].
   *
   * @return a collection of zero or more attributes (not `null`, contains no `null`s)
   */
  List<XmlAttributeNode> parseAttributes() {
    TokenType type = currentToken.type;
    if (identical(type, TokenType.GT) || identical(type, TokenType.SLASH_GT) || identical(type, TokenType.EOF)) {
      return XmlTagNode.NO_ATTRIBUTES;
    }
    List<XmlAttributeNode> attributes = new List<XmlAttributeNode>();
    while (true) {
      while (true) {
        if (currentToken.type == TokenType.GT || currentToken.type == TokenType.SLASH_GT || currentToken.type == TokenType.EOF) {
          return attributes;
        } else if (currentToken.type == TokenType.TAG) {
          attributes.add(parseAttribute());
        } else {
          reportUnexpectedToken();
          currentToken = currentToken.next;
        }
        break;
      }
    }
  }

  /**
   * Parse the stream for a sequence of tag nodes existing within a parent tag node. This method
   * advances the current token to the next [TokenType#LT_SLASH] or [TokenType#EOF].
   *
   * @return a list of nodes (not `null`, contains no `null`s)
   */
  List<XmlTagNode> parseChildTagNodes() {
    TokenType type = currentToken.type;
    if (identical(type, TokenType.LT_SLASH) || identical(type, TokenType.EOF)) {
      return XmlTagNode.NO_TAG_NODES;
    }
    List<XmlTagNode> nodes = new List<XmlTagNode>();
    while (true) {
      while (true) {
        if (currentToken.type == TokenType.LT) {
          nodes.add(parseTagNode());
        } else if (currentToken.type == TokenType.LT_SLASH || currentToken.type == TokenType.EOF) {
          return nodes;
        } else if (currentToken.type == TokenType.COMMENT) {
          currentToken = currentToken.next;
        } else {
          reportUnexpectedToken();
          currentToken = currentToken.next;
        }
        break;
      }
    }
  }

  /**
   * Parse the token stream for the next tag node. This method advances current token over the
   * parsed tag node, but should only be called if the current token is [TokenType#LT]
   *
   * @return the tag node or `null` if none found
   */
  XmlTagNode parseTagNode() {
    Token nodeStart = currentToken;
    currentToken = currentToken.next;
    Token tag;
    if (identical(currentToken.type, TokenType.TAG)) {
      tag = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      tag = insertSyntheticToken(TokenType.TAG);
    }
    List<XmlAttributeNode> attributes = parseAttributes();
    Token attributeEnd;
    if (identical(currentToken.type, TokenType.GT) || identical(currentToken.type, TokenType.SLASH_GT)) {
      attributeEnd = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      attributeEnd = insertSyntheticToken(TokenType.SLASH_GT);
    }
    if (identical(attributeEnd.type, TokenType.SLASH_GT) || isSelfClosing(tag)) {
      return createTagNode(nodeStart, tag, attributes, attributeEnd, XmlTagNode.NO_TAG_NODES, currentToken, null, attributeEnd);
    }
    List<XmlTagNode> tagNodes = parseChildTagNodes();
    Token contentEnd;
    if (identical(currentToken.type, TokenType.LT_SLASH)) {
      contentEnd = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      contentEnd = insertSyntheticToken(TokenType.LT_SLASH);
    }
    Token closingTag;
    if (identical(currentToken.type, TokenType.TAG)) {
      closingTag = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      closingTag = insertSyntheticToken(TokenType.TAG);
    }
    Token nodeEnd;
    if (identical(currentToken.type, TokenType.GT)) {
      nodeEnd = currentToken;
      currentToken = currentToken.next;
    } else {
      reportUnexpectedToken();
      nodeEnd = insertSyntheticToken(TokenType.GT);
    }
    return createTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
  }

  /**
   * Report the current token as unexpected
   */
  void reportUnexpectedToken() {
  }
}

/**
 * Instances of `XmlTagNode` represent XML or HTML elements such as `` and
 * `<body foo="bar"> ... </body>`.
 *
 * @coverage dart.engine.html
 */
class XmlTagNode extends XmlNode {
  /**
   * Constant representing empty list of attributes.
   */
  static List<XmlAttributeNode> NO_ATTRIBUTES = new UnmodifiableListView(new List<XmlAttributeNode>());

  /**
   * Constant representing empty list of tag nodes.
   */
  static List<XmlTagNode> NO_TAG_NODES = new UnmodifiableListView(new List<XmlTagNode>());

  /**
   * The starting [TokenType#LT] token (not `null`).
   */
  Token nodeStart;

  /**
   * The [TokenType#TAG] token after the starting '&lt;' (not `null`).
   */
  Token tag;

  /**
   * The attributes contained by the receiver (not `null`, contains no `null`s).
   */
  List<XmlAttributeNode> attributes;

  /**
   * The [TokenType#GT] or [TokenType#SLASH_GT] token after the attributes (not
   * `null`). The token may be the same token as [nodeEnd] if there are no child
   * [tagNodes].
   */
  Token attributeEnd;

  /**
   * The tag nodes contained in the receiver (not `null`, contains no `null`s).
   */
  List<XmlTagNode> tagNodes;

  /**
   * The token (not `null`) after the content, which may be
   *
   * * (1) [TokenType#LT_SLASH] for nodes with open and close tags, or
   * * (2) the [TokenType#LT] nodeStart of the next sibling node if this node is self
   * closing or the attributeEnd is [TokenType#SLASH_GT], or
   * * (3) [TokenType#EOF] if the node does not have a closing tag and is the last node in
   * the stream [TokenType#LT_SLASH] token after the content, or `null` if there is no
   * content and the attributes ended with [TokenType#SLASH_GT].
   *
   */
  Token contentEnd;

  /**
   * The closing [TokenType#TAG] after the child elements or `null` if there is no
   * content and the attributes ended with [TokenType#SLASH_GT]
   */
  Token closingTag;

  /**
   * The ending [TokenType#GT] or [TokenType#SLASH_GT] token (not `null`).
   */
  Token nodeEnd;

  /**
   * Construct a new instance representing an XML or HTML element
   *
   * @param nodeStart the starting [TokenType#LT] token (not `null`)
   * @param tag the [TokenType#TAG] token after the starting '&lt;' (not `null`).
   * @param attributes the attributes associated with this element or [NO_ATTRIBUTES] (not
   *          `null`, contains no `null`s)
   * @param attributeEnd The [TokenType#GT] or [TokenType#SLASH_GT] token after the
   *          attributes (not `null`). The token may be the same token as [nodeEnd] if
   *          there are no child [tagNodes].
   * @param tagNodes child tag nodes of the receiver or [NO_TAG_NODES] (not `null`,
   *          contains no `null`s)
   * @param contentEnd the token (not `null`) after the content, which may be
   *
   *          * (1) [TokenType#LT_SLASH] for nodes with open and close tags, or
   *          * (2) the [TokenType#LT] nodeStart of the next sibling node if this node is
   *          self closing or the attributeEnd is [TokenType#SLASH_GT], or
   *          * (3) [TokenType#EOF] if the node does not have a closing tag and is the last
   *          node in the stream [TokenType#LT_SLASH] token after the content, or `null`
   *          if there is no content and the attributes ended with [TokenType#SLASH_GT].
   *
   * @param closingTag the closing [TokenType#TAG] after the child elements or `null` if
   *          there is no content and the attributes ended with [TokenType#SLASH_GT]
   * @param nodeEnd the ending [TokenType#GT] or [TokenType#SLASH_GT] token (not
   *          `null`)
   */
  XmlTagNode(Token nodeStart, Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd) {
    this.nodeStart = nodeStart;
    this.tag = tag;
    this.attributes = becomeParentOfEmpty(attributes, NO_ATTRIBUTES);
    this.attributeEnd = attributeEnd;
    this.tagNodes = becomeParentOfEmpty(tagNodes, NO_TAG_NODES);
    this.contentEnd = contentEnd;
    this.closingTag = closingTag;
    this.nodeEnd = nodeEnd;
  }

  accept(XmlVisitor visitor) => visitor.visitXmlTagNode(this);

  /**
   * Answer the attribute with the specified name.
   *
   * @param name the attribute name
   * @return the attribute or `null` if no matching attribute is found
   */
  XmlAttributeNode getAttribute(String name) {
    for (XmlAttributeNode attribute in attributes) {
      if (attribute.name.lexeme == name) {
        return attribute;
      }
    }
    return null;
  }

  /**
   * Find the attribute with the given name (see [getAttribute] and answer the lexeme
   * for the attribute's value token without the leading and trailing quotes (see
   * [XmlAttributeNode#getText]).
   *
   * @param name the attribute name
   * @return the attribute text or `null` if no matching attribute is found
   */
  String getAttributeText(String name) {
    XmlAttributeNode attribute = getAttribute(name);
    return attribute != null ? attribute.text : null;
  }

  Token get beginToken => nodeStart;

  /**
   * Answer a string representing the content contained in the receiver. This includes the textual
   * representation of any child tag nodes ([getTagNodes]). Whitespace between '&lt;',
   * '&lt;/', and '>', '/>' is discarded, but all other whitespace is preserved.
   *
   * @return the content (not `null`)
   */
  String get content {
    Token token = attributeEnd.next;
    if (identical(token, contentEnd)) {
      return "";
    }
    String content = token.lexeme;
    token = token.next;
    if (identical(token, contentEnd)) {
      return content;
    }
    JavaStringBuilder buffer = new JavaStringBuilder();
    while (token != contentEnd) {
      buffer.append(token.lexeme);
      token = token.next;
    }
    return buffer.toString();
  }

  Token get endToken {
    if (nodeEnd != null) {
      return nodeEnd;
    }
    if (closingTag != null) {
      return closingTag;
    }
    if (contentEnd != null) {
      return contentEnd;
    }
    if (!tagNodes.isEmpty) {
      return tagNodes[tagNodes.length - 1].endToken;
    }
    if (attributeEnd != null) {
      return attributeEnd;
    }
    if (!attributes.isEmpty) {
      return attributes[attributes.length - 1].endToken;
    }
    return tag;
  }

  /**
   * Return the expressions that are embedded in the tag's content.
   *
   * @return the expressions that are embedded in the tag's content
   */
  List<EmbeddedExpression> get expressions => EmbeddedExpression.EMPTY_ARRAY;

  void visitChildren(XmlVisitor visitor) {
    for (XmlAttributeNode node in attributes) {
      node.accept(visitor);
    }
    for (XmlTagNode node in tagNodes) {
      node.accept(visitor);
    }
  }

  /**
   * Same as [becomeParentOf], but returns given "ifEmpty" if "children" is empty
   */
  List becomeParentOfEmpty(List children, List ifEmpty) {
    if (children != null && children.isEmpty) {
      return ifEmpty;
    }
    return becomeParentOf(children);
  }
}

/**
 * Instances of the class `HtmlParser` are used to parse tokens into a AST structure comprised
 * of [XmlNode]s.
 *
 * @coverage dart.engine.html
 */
class HtmlParser extends XmlParser {
  /**
   * The line information associated with the source being parsed.
   */
  LineInfo _lineInfo;

  /**
   * The error listener to which errors will be reported.
   */
  AnalysisErrorListener _errorListener;

  static String _APPLICATION_DART_IN_DOUBLE_QUOTES = "\"application/dart\"";

  static String _APPLICATION_DART_IN_SINGLE_QUOTES = "'application/dart'";

  static String _OPENING_DELIMITER = "{{";

  static String _CLOSING_DELIMITER = "}}";

  static String _SCRIPT = "script";

  static String _TYPE = "type";

  /**
   * A set containing the names of tags that do not have a closing tag.
   */
  static Set<String> SELF_CLOSING = new Set<String>();

  /**
   * Construct a parser for the specified source.
   *
   * @param source the source being parsed
   * @param errorListener the error listener to which errors will be reported
   */
  HtmlParser(Source source, AnalysisErrorListener errorListener) : super(source) {
    this._errorListener = errorListener;
  }

  Token getEndToken(Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd) {
    if (nodeEnd != null) {
      return nodeEnd;
    }
    if (closingTag != null) {
      return closingTag;
    }
    if (contentEnd != null) {
      return contentEnd;
    }
    if (!tagNodes.isEmpty) {
      return tagNodes[tagNodes.length - 1].endToken;
    }
    if (attributeEnd != null) {
      return attributeEnd;
    }
    if (!attributes.isEmpty) {
      return attributes[attributes.length - 1].endToken;
    }
    return tag;
  }

  /**
   * Parse the tokens specified by the given scan result.
   *
   * @param scanResult the result of scanning an HTML source (not `null`)
   * @return the parse result (not `null`)
   */
  HtmlParseResult parse(HtmlScanResult scanResult) {
    List<int> lineStarts = scanResult.lineStarts;
    _lineInfo = new LineInfo(lineStarts);
    Token firstToken = scanResult.token;
    List<XmlTagNode> tagNodes = parseTopTagNodes(firstToken);
    HtmlUnit unit = new HtmlUnit(firstToken, tagNodes, currentToken);
    return new HtmlParseResult(scanResult.modificationTime, firstToken, scanResult.lineStarts, unit);
  }

  /**
   * Scan then parse the specified source.
   *
   * @param source the source to be scanned and parsed (not `null`)
   * @return the parse result (not `null`)
   */
  HtmlParseResult parse2(Source source) {
    HtmlScanner scanner = new HtmlScanner(source);
    source.getContents(scanner);
    return parse(scanner.result);
  }

  XmlAttributeNode createAttributeNode(Token name, Token equals, Token value) {
    List<EmbeddedExpression> expressions = new List<EmbeddedExpression>();
    addEmbeddedExpressions(expressions, value);
    if (expressions.isEmpty) {
      return new XmlAttributeNode(name, equals, value);
    }
    return new AttributeWithEmbeddedExpressions(name, equals, value, new List.from(expressions));
  }

  XmlTagNode createTagNode(Token nodeStart, Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd) {
    if (isScriptNode(tag, attributes, tagNodes)) {
      HtmlScriptTagNode tagNode = new HtmlScriptTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
      String contents = tagNode.content;
      int contentOffset = attributeEnd.end;
      LineInfo_Location location = _lineInfo.getLocation(contentOffset);
      sc.Scanner scanner = new sc.Scanner(source, new sc.SubSequenceReader(new CharSequence(contents), contentOffset), _errorListener);
      scanner.setSourceStart(location.lineNumber, location.columnNumber);
      sc.Token firstToken = scanner.tokenize();
      Parser parser = new Parser(source, _errorListener);
      CompilationUnit unit = parser.parseCompilationUnit(firstToken);
      unit.lineInfo = _lineInfo;
      tagNode.script = unit;
      return tagNode;
    }
    Token token = nodeStart;
    Token endToken = getEndToken(tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
    List<EmbeddedExpression> expressions = new List<EmbeddedExpression>();
    while (token != endToken) {
      if (identical(token.type, TokenType.TEXT)) {
        addEmbeddedExpressions(expressions, token);
      }
      token = token.next;
    }
    if (expressions.isEmpty) {
      return super.createTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
    }
    return new TagWithEmbeddedExpressions(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd, new List.from(expressions));
  }

  bool isSelfClosing(Token tag) => SELF_CLOSING.contains(tag.lexeme);

  /**
   * Parse the value of the given token for embedded expressions, and add any embedded expressions
   * that are found to the given list of expressions.
   *
   * @param expressions the list to which embedded expressions are to be added
   * @param token the token whose value is to be parsed
   */
  void addEmbeddedExpressions(List<EmbeddedExpression> expressions, Token token) {
    String lexeme = token.lexeme;
    int startIndex = lexeme.indexOf(_OPENING_DELIMITER);
    while (startIndex >= 0) {
      int endIndex = JavaString.indexOf(lexeme, _CLOSING_DELIMITER, startIndex + 2);
      if (endIndex < 0) {
        return;
      } else if (startIndex + 2 < endIndex) {
        int offset = token.offset;
        expressions.add(new EmbeddedExpression(startIndex, parseEmbeddedExpression(lexeme.substring(startIndex + 2, endIndex), offset + startIndex), endIndex));
      }
      startIndex = JavaString.indexOf(lexeme, _OPENING_DELIMITER, endIndex + 2);
    }
  }

  /**
   * Determine if the specified node is a Dart script.
   *
   * @param node the node to be tested (not `null`)
   * @return `true` if the node is a Dart script
   */
  bool isScriptNode(Token tag, List<XmlAttributeNode> attributes, List<XmlTagNode> tagNodes) {
    if (tagNodes.length != 0 || tag.lexeme != _SCRIPT) {
      return false;
    }
    for (XmlAttributeNode attribute in attributes) {
      if (attribute.name.lexeme == _TYPE) {
        Token valueToken = attribute.value;
        if (valueToken != null) {
          String value = valueToken.lexeme;
          if (value == _APPLICATION_DART_IN_DOUBLE_QUOTES || value == _APPLICATION_DART_IN_SINGLE_QUOTES) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /**
   * Given the contents of an embedded expression that occurs at the given offset, parse it as a
   * Dart expression. The contents should not include the expression's delimiters.
   *
   * @param contents the contents of the expression
   * @param contentOffset the offset of the expression in the larger file
   * @return the Dart expression that was parsed
   */
  Expression parseEmbeddedExpression(String contents, int contentOffset) {
    LineInfo_Location location = _lineInfo.getLocation(contentOffset);
    sc.Scanner scanner = new sc.Scanner(source, new sc.SubSequenceReader(new CharSequence(contents), contentOffset), _errorListener);
    scanner.setSourceStart(location.lineNumber, location.columnNumber);
    sc.Token firstToken = scanner.tokenize();
    Parser parser = new Parser(source, _errorListener);
    return parser.parseExpression(firstToken);
  }
}

/**
 * Instances of the class `HtmlUnit` represent the contents of an HTML file.
 *
 * @coverage dart.engine.html
 */
class HtmlUnit extends XmlNode {
  /**
   * The first token in the token stream that was parsed to form this HTML unit.
   */
  Token _beginToken;

  /**
   * The last token in the token stream that was parsed to form this compilation unit. This token
   * should always have a type of [TokenType.EOF].
   */
  Token _endToken;

  /**
   * The tag nodes contained in the receiver (not `null`, contains no `null`s).
   */
  List<XmlTagNode> tagNodes;

  /**
   * The element associated with this HTML unit or `null` if the receiver is not resolved.
   */
  HtmlElementImpl element;

  /**
   * Construct a new instance representing the content of an HTML file.
   *
   * @param beginToken the first token in the file (not `null`)
   * @param tagNodes child tag nodes of the receiver (not `null`, contains no `null`s)
   * @param endToken the last token in the token stream which should be of type
   *          [TokenType.EOF]
   */
  HtmlUnit(Token beginToken, List<XmlTagNode> tagNodes, Token endToken) {
    this._beginToken = beginToken;
    this.tagNodes = becomeParentOf(tagNodes);
    this._endToken = endToken;
  }

  accept(XmlVisitor visitor) => visitor.visitHtmlUnit(this);

  Token get beginToken => _beginToken;

  Token get endToken => _endToken;

  void visitChildren(XmlVisitor visitor) {
    for (XmlTagNode node in tagNodes) {
      node.accept(visitor);
    }
  }
}