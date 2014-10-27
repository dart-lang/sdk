// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'ast.dart';
import 'element.dart';
import 'engine.dart' show AnalysisEngine, AngularHtmlUnitResolver, ExpressionVisitor;

/**
 * The abstract class `AbstractScanner` implements a scanner for HTML code. Subclasses are
 * required to implement the interface used to access the characters being scanned.
 */
abstract class AbstractScanner {
  static List<String> _NO_PASS_THROUGH_ELEMENTS = <String> [];

  /**
   * The source being scanned.
   */
  final Source source;

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
  AbstractScanner(this.source) {
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
    _scan();
    _appendEofToken();
    return _firstToken();
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

  void _appendEofToken() {
    Token eofToken = new Token.con1(TokenType.EOF, offset);
    // The EOF token points to itself so that there is always infinite look-ahead.
    eofToken.setNext(eofToken);
    _tail = _tail.setNext(eofToken);
  }

  Token _emit(Token token) {
    _tail.setNext(token);
    _tail = token;
    return token;
  }

  Token _emitWithOffset(TokenType type, int start) => _emit(new Token.con1(type, start));

  Token _emitWithOffsetAndLength(TokenType type, int start, int count) => _emit(new Token.con2(type, start, getString(start, count)));

  Token _firstToken() => _tokens.next;

  int _recordStartOfLineAndAdvance(int c) {
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

  void _scan() {
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
            // handle a comment
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
              c = _recordStartOfLineAndAdvance(c);
            }
            _emitWithOffsetAndLength(TokenType.COMMENT, start, -1);
            // Capture <!--> and <!---> as tokens but report an error
            if (_tail.length < 7) {
              // TODO (danrubel): Report invalid HTML comment
            }
          } else {
            // handle a declaration
            while (c >= 0) {
              if (c == 0x3E) {
                c = advance();
                break;
              }
              c = _recordStartOfLineAndAdvance(c);
            }
            _emitWithOffsetAndLength(TokenType.DECLARATION, start, -1);
            if (!StringUtilities.endsWithChar(_tail.lexeme, 0x3E)) {
              // TODO (danrubel): Report missing '>' in directive
            }
          }
        } else if (c == 0x3F) {
          // handle a directive
          while (c >= 0) {
            if (c == 0x3F) {
              c = advance();
              if (c == 0x3E) {
                c = advance();
                break;
              }
            } else {
              c = _recordStartOfLineAndAdvance(c);
            }
          }
          _emitWithOffsetAndLength(TokenType.DIRECTIVE, start, -1);
          if (_tail.length < 4) {
            // TODO (danrubel): Report invalid directive
          }
        } else if (c == 0x2F) {
          _emitWithOffset(TokenType.LT_SLASH, start);
          inBrackets = true;
          c = advance();
        } else {
          inBrackets = true;
          _emitWithOffset(TokenType.LT, start);
          // ignore whitespace in braces
          while (Character.isWhitespace(c)) {
            c = _recordStartOfLineAndAdvance(c);
          }
          // get tag
          if (Character.isLetterOrDigit(c)) {
            int tagStart = offset;
            c = advance();
            while (Character.isLetterOrDigit(c) || c == 0x2D || c == 0x5F) {
              c = advance();
            }
            _emitWithOffsetAndLength(TokenType.TAG, tagStart, -1);
            // check tag against passThrough elements
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
        _emitWithOffset(TokenType.GT, start);
        inBrackets = false;
        c = advance();
        // if passThrough != null, read until we match it
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
            c = _recordStartOfLineAndAdvance(c);
          }
          if (start + 1 < offset) {
            if (endFound) {
              _emitWithOffsetAndLength(TokenType.TEXT, start + 1, -len);
              _emitWithOffset(TokenType.LT_SLASH, offset - len + 1);
              _emitWithOffsetAndLength(TokenType.TAG, offset - len + 3, -1);
            } else {
              _emitWithOffsetAndLength(TokenType.TEXT, start + 1, -1);
            }
          }
          endPassThrough = null;
        }
      } else if (c == 0x2F && peek() == 0x3E) {
        advance();
        _emitWithOffset(TokenType.SLASH_GT, start);
        inBrackets = false;
        c = advance();
      } else if (!inBrackets) {
        c = _recordStartOfLineAndAdvance(c);
        while (c != 0x3C && c >= 0) {
          c = _recordStartOfLineAndAdvance(c);
        }
        _emitWithOffsetAndLength(TokenType.TEXT, start, -1);
      } else if (c == 0x22 || c == 0x27) {
        // read a string
        int endQuote = c;
        c = advance();
        while (c >= 0) {
          if (c == endQuote) {
            c = advance();
            break;
          }
          c = _recordStartOfLineAndAdvance(c);
        }
        _emitWithOffsetAndLength(TokenType.STRING, start, -1);
      } else if (c == 0x3D) {
        // a non-char token
        _emitWithOffset(TokenType.EQ, start);
        c = advance();
      } else if (Character.isWhitespace(c)) {
        // ignore whitespace in braces
        do {
          c = _recordStartOfLineAndAdvance(c);
        } while (Character.isWhitespace(c));
      } else if (Character.isLetterOrDigit(c)) {
        c = advance();
        while (Character.isLetterOrDigit(c) || c == 0x2D || c == 0x5F) {
          c = advance();
        }
        _emitWithOffsetAndLength(TokenType.TAG, start, -1);
      } else {
        // a non-char token
        _emitWithOffsetAndLength(TokenType.TEXT, start, 0);
        c = advance();
      }
    }
  }
}

class ExpressionVisitor_HtmlUnitUtils_getExpression extends ExpressionVisitor {
  int offset = 0;

  List<Expression> result;

  ExpressionVisitor_HtmlUnitUtils_getExpression(this.offset, this.result) : super();

  @override
  void visitExpression(Expression expression) {
    Expression at = HtmlUnitUtils._getExpressionAt(expression, offset);
    if (at != null) {
      result[0] = at;
      throw new HtmlUnitUtils_FoundExpressionError();
    }
  }
}

/**
 * Instances of the class `HtmlParser` are used to parse tokens into a AST structure comprised
 * of [XmlNode]s.
 */
class HtmlParser extends XmlParser {
  /**
   * The line information associated with the source being parsed.
   */
  LineInfo _lineInfo;

  /**
   * The error listener to which errors will be reported.
   */
  final AnalysisErrorListener _errorListener;

  static String _APPLICATION_DART_IN_DOUBLE_QUOTES = "\"application/dart\"";

  static String _APPLICATION_DART_IN_SINGLE_QUOTES = "'application/dart'";

  static String _SCRIPT = "script";

  static String _TYPE = "type";

  /**
   * A set containing the names of tags that do not have a closing tag.
   */
  static Set<String> SELF_CLOSING = new HashSet<String>.from(JavaArrays.asList(<String> [
      "area",
      "base",
      "basefont",
      "br",
      "col",
      "frame",
      "hr",
      "img",
      "input",
      "link",
      "meta",
      "param",
      "!"]));

  /**
   * Given the contents of an embedded expression that occurs at the given offset, parse it as a
   * Dart expression. The contents should not include the expression's delimiters.
   *
   * @param source the source that contains that given token
   * @param token the token to start parsing from
   * @return the Dart expression that was parsed
   */
  static Expression parseEmbeddedExpression(Source source, sc.Token token, AnalysisErrorListener errorListener) {
    Parser parser = new Parser(source, errorListener);
    return parser.parseExpression(token);
  }

  /**
   * Given the contents of an embedded expression that occurs at the given offset, scans it as a
   * Dart code.
   *
   * @param source the source of that contains the given contents
   * @param contents the contents to scan
   * @param contentOffset the offset of the contents in the larger file
   * @return the first Dart token
   */
  static sc.Token scanDartSource(Source source, LineInfo lineInfo, String contents, int contentOffset, AnalysisErrorListener errorListener) {
    LineInfo_Location location = lineInfo.getLocation(contentOffset);
    sc.Scanner scanner = new sc.Scanner(source, new sc.SubSequenceReader(contents, contentOffset), errorListener);
    scanner.setSourceStart(location.lineNumber, location.columnNumber);
    return scanner.tokenize();
  }

  /**
   * Construct a parser for the specified source.
   *
   * @param source the source being parsed
   * @param errorListener the error listener to which errors will be reported
   */
  HtmlParser(Source source, this._errorListener) : super(source);

  /**
   * Parse the given tokens.
   *
   * @param token the first token in the stream of tokens to be parsed
   * @param lineInfo the line information created by the scanner
   * @return the parse result (not `null`)
   */
  HtmlUnit parse(Token token, LineInfo lineInfo) {
    this._lineInfo = lineInfo;
    List<XmlTagNode> tagNodes = parseTopTagNodes(token);
    return new HtmlUnit(token, tagNodes, currentToken);
  }

  @override
  XmlAttributeNode createAttributeNode(Token name, Token equals, Token value) => new XmlAttributeNode(name, equals, value);

  @override
  XmlTagNode createTagNode(Token nodeStart, Token tag, List<XmlAttributeNode> attributes, Token attributeEnd, List<XmlTagNode> tagNodes, Token contentEnd, Token closingTag, Token nodeEnd) {
    if (_isScriptNode(tag, attributes, tagNodes)) {
      HtmlScriptTagNode tagNode = new HtmlScriptTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
      String contents = tagNode.content;
      int contentOffset = attributeEnd.end;
      LineInfo_Location location = _lineInfo.getLocation(contentOffset);
      sc.Scanner scanner = new sc.Scanner(source, new sc.SubSequenceReader(contents, contentOffset), _errorListener);
      scanner.setSourceStart(location.lineNumber, location.columnNumber);
      sc.Token firstToken = scanner.tokenize();
      Parser parser = new Parser(source, _errorListener);
      CompilationUnit unit = parser.parseCompilationUnit(firstToken);
      unit.lineInfo = _lineInfo;
      tagNode.script = unit;
      return tagNode;
    }
    return new XmlTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
  }

  @override
  bool isSelfClosing(Token tag) => SELF_CLOSING.contains(tag.lexeme);

  /**
   * Determine if the specified node is a Dart script.
   *
   * @param node the node to be tested (not `null`)
   * @return `true` if the node is a Dart script
   */
  bool _isScriptNode(Token tag, List<XmlAttributeNode> attributes, List<XmlTagNode> tagNodes) {
    if (tagNodes.length != 0 || tag.lexeme != _SCRIPT) {
      return false;
    }
    for (XmlAttributeNode attribute in attributes) {
      if (attribute.name == _TYPE) {
        Token valueToken = attribute.valueToken;
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

  @override
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
 * Instances of the class `HtmlUnit` represent the contents of an HTML file.
 */
class HtmlUnit extends XmlNode {
  /**
   * The first token in the token stream that was parsed to form this HTML unit.
   */
  final Token beginToken;

  /**
   * The last token in the token stream that was parsed to form this compilation unit. This token
   * should always have a type of [TokenType.EOF].
   */
  final Token endToken;

  /**
   * The tag nodes contained in the receiver (not `null`, contains no `null`s).
   */
  List<XmlTagNode> _tagNodes;

  /**
   * Construct a new instance representing the content of an HTML file.
   *
   * @param beginToken the first token in the file (not `null`)
   * @param tagNodes child tag nodes of the receiver (not `null`, contains no `null`s)
   * @param endToken the last token in the token stream which should be of type
   *          [TokenType.EOF]
   */
  HtmlUnit(this.beginToken, List<XmlTagNode> tagNodes, this.endToken) {
    this._tagNodes = becomeParentOfAll(tagNodes);
  }

  @override
  accept(XmlVisitor visitor) => visitor.visitHtmlUnit(this);

  /**
   * Return the element associated with this HTML unit.
   *
   * @return the element or `null` if the receiver is not resolved
   */
  @override
  HtmlElement get element => super.element as HtmlElement;

  /**
   * Answer the tag nodes contained in the receiver. Callers should not manipulate the returned list
   * to edit the AST structure.
   *
   * @return the children (not `null`, contains no `null`s)
   */
  List<XmlTagNode> get tagNodes => _tagNodes;

  @override
  void set element(Element element) {
    if (element != null && element is! HtmlElement) {
      throw new IllegalArgumentException("HtmlElement expected, but ${element.runtimeType} given");
    }
    super.element = element;
  }

  @override
  void visitChildren(XmlVisitor visitor) {
    for (XmlTagNode node in _tagNodes) {
      node.accept(visitor);
    }
  }
}

/**
 * Utilities locating [Expression]s and [Element]s in [HtmlUnit].
 */
class HtmlUnitUtils {
  /**
   * Returns the [XmlAttributeNode] that is part of the given [HtmlUnit] and encloses
   * the given offset.
   */
  static XmlAttributeNode getAttributeNode(HtmlUnit htmlUnit, int offset) {
    if (htmlUnit == null) {
      return null;
    }
    List<XmlAttributeNode> result = [null];
    try {
      htmlUnit.accept(new RecursiveXmlVisitor_HtmlUnitUtils_getAttributeNode(offset, result));
    } on HtmlUnitUtils_FoundAttributeNodeError catch (e) {
      return result[0];
    }
    return null;
  }

  /**
   * Returns the best [Element] of the given [Expression].
   */
  static Element getElement(Expression expression) {
    if (expression == null) {
      return null;
    }
    return ElementLocator.locate(expression);
  }

  /**
   * Returns the [Element] of the [Expression] in the given [HtmlUnit], enclosing
   * the given offset.
   */
  static Element getElementAtOffset(HtmlUnit htmlUnit, int offset) {
    Expression expression = getExpression(htmlUnit, offset);
    return getElement(expression);
  }

  /**
   * Returns the [Element] to open when requested at the given [Expression].
   */
  static Element getElementToOpen(HtmlUnit htmlUnit, Expression expression) {
    Element element = getElement(expression);
    {
      AngularElement angularElement = AngularHtmlUnitResolver.getAngularElement(element);
      if (angularElement != null) {
        return angularElement;
      }
    }
    return element;
  }

  /**
   * Returns the [XmlTagNode] that is part of the given [HtmlUnit] and encloses the
   * given offset.
   */
  static XmlTagNode getEnclosingTagNode(HtmlUnit htmlUnit, int offset) {
    if (htmlUnit == null) {
      return null;
    }
    List<XmlTagNode> result = [null];
    try {
      htmlUnit.accept(new RecursiveXmlVisitor_HtmlUnitUtils_getEnclosingTagNode(offset, result));
    } on HtmlUnitUtils_FoundTagNodeError catch (e) {
      return result[0];
    }
    return null;
  }

  /**
   * Returns the [Expression] that is part of the given [HtmlUnit] and encloses the
   * given offset.
   */
  static Expression getExpression(HtmlUnit htmlUnit, int offset) {
    if (htmlUnit == null) {
      return null;
    }
    List<Expression> result = [null];
    try {
      // TODO(scheglov) this code is very Angular specific
      htmlUnit.accept(new ExpressionVisitor_HtmlUnitUtils_getExpression(offset, result));
    } on HtmlUnitUtils_FoundExpressionError catch (e) {
      return result[0];
    }
    return null;
  }

  /**
   * Returns the [XmlTagNode] that is part of the given [HtmlUnit] and its open or
   * closing tag name encloses the given offset.
   */
  static XmlTagNode getTagNode(HtmlUnit htmlUnit, int offset) {
    XmlTagNode node = getEnclosingTagNode(htmlUnit, offset);
    // do we have an enclosing tag at all?
    if (node == null) {
      return null;
    }
    // is "offset" in the open tag?
    Token openTag = node.tagToken;
    if (openTag.offset <= offset && offset <= openTag.end) {
      return node;
    }
    // is "offset" in the open tag?
    Token closeTag = node.closingTag;
    if (closeTag != null && closeTag.offset <= offset && offset <= closeTag.end) {
      return node;
    }
    // not on a tag name
    return null;
  }

  /**
   * Returns the [Expression] that is part of the given root [AstNode] and encloses the
   * given offset.
   */
  static Expression _getExpressionAt(AstNode root, int offset) {
    if (root.offset <= offset && offset <= root.end) {
      AstNode dartNode = new NodeLocator.con1(offset).searchWithin(root);
      if (dartNode is Expression) {
        return dartNode;
      }
    }
    return null;
  }
}

class HtmlUnitUtils_FoundAttributeNodeError extends Error {
}

class HtmlUnitUtils_FoundExpressionError extends Error {
}

class HtmlUnitUtils_FoundTagNodeError extends Error {
}

/**
 * Implementation of [XmlExpression] for an [Expression] embedded without any wrapping
 * characters.
 */
class RawXmlExpression extends XmlExpression {
  final Expression expression;

  RawXmlExpression(this.expression);

  @override
  int get end => expression.end;

  @override
  int get length => expression.length;

  @override
  int get offset => expression.offset;

  @override
  XmlExpression_Reference getReference(int offset) {
    AstNode node = new NodeLocator.con1(offset).searchWithin(expression);
    if (node != null) {
      Element element = ElementLocator.locate(node);
      return new XmlExpression_Reference(element, node.offset, node.length);
    }
    return null;
  }
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
 */
class RecursiveXmlVisitor<R> implements XmlVisitor<R> {
  @override
  R visitHtmlScriptTagNode(HtmlScriptTagNode node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitHtmlUnit(HtmlUnit node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitXmlAttributeNode(XmlAttributeNode node) {
    node.visitChildren(this);
    return null;
  }

  @override
  R visitXmlTagNode(XmlTagNode node) {
    node.visitChildren(this);
    return null;
  }
}

class RecursiveXmlVisitor_HtmlUnitUtils_getAttributeNode extends RecursiveXmlVisitor<Object> {
  int offset = 0;

  List<XmlAttributeNode> result;

  RecursiveXmlVisitor_HtmlUnitUtils_getAttributeNode(this.offset, this.result) : super();

  @override
  Object visitXmlAttributeNode(XmlAttributeNode node) {
    Token nameToken = node.nameToken;
    if (nameToken.offset <= offset && offset <= nameToken.end) {
      result[0] = node;
      throw new HtmlUnitUtils_FoundAttributeNodeError();
    }
    return super.visitXmlAttributeNode(node);
  }
}

class RecursiveXmlVisitor_HtmlUnitUtils_getEnclosingTagNode extends RecursiveXmlVisitor<Object> {
  int offset = 0;

  List<XmlTagNode> result;

  RecursiveXmlVisitor_HtmlUnitUtils_getEnclosingTagNode(this.offset, this.result) : super();

  @override
  Object visitXmlTagNode(XmlTagNode node) {
    if (node.offset <= offset && offset < node.end) {
      result[0] = node;
      super.visitXmlTagNode(node);
      throw new HtmlUnitUtils_FoundTagNodeError();
    }
    return null;
  }
}

/**
 * Instances of the class `SimpleXmlVisitor` implement an AST visitor that will do nothing
 * when visiting an AST node. It is intended to be a superclass for classes that use the visitor
 * pattern primarily as a dispatch mechanism (and hence don't need to recursively visit a whole
 * structure) and that only need to visit a small number of node types.
 */
class SimpleXmlVisitor<R> implements XmlVisitor<R> {
  @override
  R visitHtmlScriptTagNode(HtmlScriptTagNode node) => null;

  @override
  R visitHtmlUnit(HtmlUnit htmlUnit) => null;

  @override
  R visitXmlAttributeNode(XmlAttributeNode xmlAttributeNode) => null;

  @override
  R visitXmlTagNode(XmlTagNode xmlTagNode) => null;
}

/**
 * Instances of the class `StringScanner` implement a scanner that reads from a string. The
 * scanning logic is in the superclass.
 */
class StringScanner extends AbstractScanner {
  /**
   * The string from which characters will be read.
   */
  final String _string;

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
  StringScanner(Source source, this._string) : super(source) {
    this._stringLength = _string.length;
    this._charOffset = -1;
  }

  @override
  int get offset => _charOffset;

  void set offset(int offset) {
    _charOffset = offset;
  }

  @override
  int advance() {
    if (++_charOffset < _stringLength) {
      return _string.codeUnitAt(_charOffset);
    }
    _charOffset = _stringLength;
    return -1;
  }

  @override
  String getString(int start, int endDelta) => _string.substring(start, _charOffset + 1 + endDelta).toString();

  @override
  int peek() {
    if (_charOffset + 1 < _stringLength) {
      return _string.codeUnitAt(_charOffset + 1);
    }
    return -1;
  }
}

/**
 * Instances of the class `ToSourceVisitor` write a source representation of a visited XML
 * node (and all of it's children) to a writer.
 */
class ToSourceVisitor implements XmlVisitor<Object> {
  /**
   * The writer to which the source is to be written.
   */
  final PrintWriter _writer;

  /**
   * Initialize a newly created visitor to write source code representing the visited nodes to the
   * given writer.
   *
   * @param writer the writer to which the source is to be written
   */
  ToSourceVisitor(this._writer);

  @override
  Object visitHtmlScriptTagNode(HtmlScriptTagNode node) => visitXmlTagNode(node);

  @override
  Object visitHtmlUnit(HtmlUnit node) {
    for (XmlTagNode child in node.tagNodes) {
      _visit(child);
    }
    return null;
  }

  @override
  Object visitXmlAttributeNode(XmlAttributeNode node) {
    String name = node.name;
    Token value = node.valueToken;
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

  @override
  Object visitXmlTagNode(XmlTagNode node) {
    _writer.print("<");
    String tagName = node.tag;
    _writer.print(tagName);
    for (XmlAttributeNode attribute in node.attributes) {
      _writer.print(" ");
      _visit(attribute);
    }
    _writer.print(node.attributeEnd.lexeme);
    if (node.closingTag != null) {
      for (XmlTagNode child in node.tagNodes) {
        _visit(child);
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
  void _visit(XmlNode node) {
    if (node != null) {
      node.accept(this);
    }
  }
}

/**
 * Instances of the class `Token` represent a token that was scanned from the input. Each
 * token knows which token follows it, acting as the head of a linked list of tokens.
 */
class Token {
  /**
   * The offset from the beginning of the file to the first character in the token.
   */
  final int offset;

  /**
   * The previous token in the token stream.
   */
  Token previous;

  /**
   * The next token in the token stream.
   */
  Token _next;

  /**
   * The type of the token.
   */
  final TokenType type;

  /**
   * The lexeme represented by this token.
   */
  String _value;

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
  Token.con2(this.type, this.offset, String value) {
    this._value = StringUtilities.intern(value);
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
   * Return the lexeme that represents this token.
   *
   * @return the lexeme (not `null`)
   */
  String get lexeme => _value;

  /**
   * Return the next token in the token stream.
   *
   * @return the next token in the token stream
   */
  Token get next => _next;

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
    _next = token;
    token.previous = this;
    return token;
  }

  @override
  String toString() => lexeme;
}

/**
 * The enumeration `TokenType` defines the types of tokens that can be returned by the
 * scanner.
 */
class TokenType extends Enum<TokenType> {
  /**
   * The type of the token that marks the end of the input.
   */
  static const TokenType EOF = const TokenType_EOF('EOF', 0, "");

  static const TokenType EQ = const TokenType('EQ', 1, "=");

  static const TokenType GT = const TokenType('GT', 2, ">");

  static const TokenType LT_SLASH = const TokenType('LT_SLASH', 3, "</");

  static const TokenType LT = const TokenType('LT', 4, "<");

  static const TokenType SLASH_GT = const TokenType('SLASH_GT', 5, "/>");

  static const TokenType COMMENT = const TokenType('COMMENT', 6, null);

  static const TokenType DECLARATION = const TokenType('DECLARATION', 7, null);

  static const TokenType DIRECTIVE = const TokenType('DIRECTIVE', 8, null);

  static const TokenType STRING = const TokenType('STRING', 9, null);

  static const TokenType TAG = const TokenType('TAG', 10, null);

  static const TokenType TEXT = const TokenType('TEXT', 11, null);

  static const List<TokenType> values = const [
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
  final String lexeme;

  const TokenType(String name, int ordinal, this.lexeme) : super(name, ordinal);
}

class TokenType_EOF extends TokenType {
  const TokenType_EOF(String name, int ordinal, String arg0) : super(name, ordinal, arg0);

  @override
  String toString() => "-eof-";
}

/**
 * Instances of `XmlAttributeNode` represent name/value pairs owned by an [XmlTagNode].
 */
class XmlAttributeNode extends XmlNode {
  final Token _name;

  final Token equals;

  final Token _value;

  List<XmlExpression> expressions = XmlExpression.EMPTY_ARRAY;

  /**
   * Construct a new instance representing an XML attribute.
   *
   * @param name the name token (not `null`). This may be a zero length token if the attribute
   *          is badly formed.
   * @param equals the equals sign or `null` if none
   * @param value the value token (not `null`)
   */
  XmlAttributeNode(this._name, this.equals, this._value);

  @override
  accept(XmlVisitor visitor) => visitor.visitXmlAttributeNode(this);

  @override
  Token get beginToken => _name;

  @override
  Token get endToken => _value;

  /**
   * Answer the attribute name. This may be a zero length string if the attribute is badly formed.
   *
   * @return the name (not `null`)
   */
  String get name => _name.lexeme;

  /**
   * Answer the attribute name token. This may be a zero length token if the attribute is badly
   * formed.
   *
   * @return the name token (not `null`)
   */
  Token get nameToken => _name;

  /**
   * Answer the lexeme for the value token without the leading and trailing quotes.
   *
   * @return the text or `null` if the value is not specified
   */
  String get text {
    if (_value == null) {
      return null;
    }
    //TODO (danrubel): replace HTML character encodings with the actual characters
    String text = _value.lexeme;
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

  /**
   * Answer the offset of the value after the leading quote.
   *
   * @return the offset of the value, or `-1` if the value is not specified
   */
  int get textOffset {
    if (_value == null) {
      return -1;
    }
    String text = _value.lexeme;
    if (StringUtilities.startsWithChar(text, 0x22) || StringUtilities.startsWithChar(text, 0x27)) {
      return _value.offset + 1;
    }
    return _value.offset;
  }

  /**
   * Answer the attribute value token. A properly formed value will start and end with matching
   * quote characters, but the value returned may not be properly formed.
   *
   * @return the value token or `null` if this represents a badly formed attribute
   */
  Token get valueToken => _value;

  @override
  void visitChildren(XmlVisitor visitor) {
    // no children to visit
  }
}

/**
 * Instances of the class `XmlExpression` represent an abstract expression embedded into
 * [XmlNode].
 */
abstract class XmlExpression {
  /**
   * An empty array of expressions.
   */
  static List<XmlExpression> EMPTY_ARRAY = new List<XmlExpression>(0);

  /**
   * Check if the given offset belongs to the expression's source range.
   */
  bool contains(int offset) => this.offset <= offset && offset < end;

  /**
   * Return the offset of the character immediately following the last character of this
   * expression's source range. This is equivalent to `getOffset() + getLength()`.
   *
   * @return the offset of the character just past the expression's source range
   */
  int get end;

  /**
   * Return the number of characters in the expression's source range.
   */
  int get length;

  /**
   * Return the offset of the first character in the expression's source range.
   */
  int get offset;

  /**
   * Return the [Reference] at the given offset.
   *
   * @param offset the offset from the beginning of the file
   * @return the [Reference] at the given offset, maybe `null`
   */
  XmlExpression_Reference getReference(int offset);
}

/**
 * The reference to the [Element].
 */
class XmlExpression_Reference {
  Element element;

  int offset = 0;

  int length = 0;

  XmlExpression_Reference(Element element, int offset, int length) {
    this.element = element;
    this.offset = offset;
    this.length = length;
  }
}

/**
 * The abstract class `XmlNode` defines behavior common to all XML/HTML nodes.
 */
abstract class XmlNode {
  /**
   * The parent of the node, or `null` if the node is the root of an AST structure.
   */
  XmlNode _parent;

  /**
   * The element associated with this node or `null` if the receiver is not resolved.
   */
  Element _element;

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
   * Return the element associated with this node.
   *
   * @return the element or `null` if the receiver is not resolved
   */
  Element get element => _element;

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

  /**
   * Set the element associated with this node.
   *
   * @param element the element
   */
  void set element(Element element) {
    this._element = element;
  }

  @override
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
   * Make this node the parent of the given child node.
   *
   * @param child the node that will become a child of this node
   * @return the node that was made a child of this node
   */
  XmlNode becomeParentOf(XmlNode child) {
    if (child != null) {
      XmlNode node = child;
      node.parent = this;
    }
    return child;
  }

  /**
   * Make this node the parent of the given child nodes.
   *
   * @param children the nodes that will become the children of this node
   * @param ifEmpty the (empty) nodes to return if "children" is empty
   * @return the nodes that were made children of this node
   */
  List becomeParentOfAll(List children, {List ifEmpty}) {
    if (children == null || children.isEmpty) {
      if (ifEmpty != null) {
        return ifEmpty;
      }
    }
    if (children != null) {
      children.forEach((XmlNode node) {
        node.parent = this;
      });
    }
    return children;
  }

  /**
   * This method exists for debugging purposes only.
   */
  void _appendIdentifier(StringBuffer buffer, XmlNode node) {
    if (node is XmlTagNode) {
      buffer.write(node.tag);
    } else if (node is XmlAttributeNode) {
      buffer.write(node.name);
    } else {
      buffer.write("htmlUnit");
    }
  }

  /**
   * This method exists for debugging purposes only.
   */
  String _buildRecursiveStructureMessage(XmlNode newParent) {
    StringBuffer buffer = new StringBuffer();
    buffer.write("Attempt to create recursive structure: ");
    XmlNode current = newParent;
    while (current != null) {
      if (!identical(current, newParent)) {
        buffer.write(" -> ");
      }
      if (identical(current, this)) {
        buffer.writeCharCode(0x2A);
        _appendIdentifier(buffer, current);
        buffer.writeCharCode(0x2A);
      } else {
        _appendIdentifier(buffer, current);
      }
      current = current.parent;
    }
    return buffer.toString();
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
        AnalysisEngine.instance.logger.logError2("Circular structure while setting an XML node's parent", new IllegalArgumentException(_buildRecursiveStructureMessage(newParent)));
        return;
      }
      current = current.parent;
    }
    _parent = newParent;
  }
}

/**
 * Instances of the class `XmlParser` are used to parse tokens into a AST structure comprised
 * of [XmlNode]s.
 */
class XmlParser {
  /**
   * The source being parsed.
   */
  final Source source;

  /**
   * The next token to be parsed.
   */
  Token _currentToken;

  /**
   * Construct a parser for the specified source.
   *
   * @param source the source being parsed
   */
  XmlParser(this.source);

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
    _currentToken = firstToken;
    List<XmlTagNode> tagNodes = new List<XmlTagNode>();
    TokenType type = _currentToken.type;
    while (type != TokenType.EOF) {
      if (type == TokenType.LT) {
        tagNodes.add(_parseTagNode());
      } else if (type == TokenType.DECLARATION || type == TokenType.DIRECTIVE || type == TokenType.COMMENT) {
        // ignored tokens
        _currentToken = _currentToken.next;
      } else {
        _reportUnexpectedToken();
        _currentToken = _currentToken.next;
      }
      type = _currentToken.type;
    }
    return tagNodes;
  }

  /**
   * Answer the current token.
   *
   * @return the current token
   */
  Token get currentToken => _currentToken;

  /**
   * Insert a synthetic token of the specified type before the current token
   *
   * @param type the type of token to be inserted (not `null`)
   * @return the synthetic token that was inserted (not `null`)
   */
  Token _insertSyntheticToken(TokenType type) {
    Token token = new Token.con2(type, _currentToken.offset, "");
    _currentToken.previous.setNext(token);
    token.setNext(_currentToken);
    return token;
  }

  /**
   * Parse the token stream for an attribute. This method advances the current token over the
   * attribute, but should not be called if the [currentToken] is not [TokenType#TAG].
   *
   * @return the attribute (not `null`)
   */
  XmlAttributeNode _parseAttribute() {
    // Assume the current token is a tag
    Token name = _currentToken;
    _currentToken = _currentToken.next;
    // Equals sign
    Token equals;
    if (_currentToken.type == TokenType.EQ) {
      equals = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      _reportUnexpectedToken();
      equals = _insertSyntheticToken(TokenType.EQ);
    }
    // String value
    Token value;
    if (_currentToken.type == TokenType.STRING) {
      value = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      _reportUnexpectedToken();
      value = _insertSyntheticToken(TokenType.STRING);
    }
    return createAttributeNode(name, equals, value);
  }

  /**
   * Parse the stream for a sequence of attributes. This method advances the current token to the
   * next [TokenType#GT], [TokenType#SLASH_GT], or [TokenType#EOF].
   *
   * @return a collection of zero or more attributes (not `null`, contains no `null`s)
   */
  List<XmlAttributeNode> _parseAttributes() {
    TokenType type = _currentToken.type;
    if (type == TokenType.GT || type == TokenType.SLASH_GT || type == TokenType.EOF) {
      return XmlTagNode.NO_ATTRIBUTES;
    }
    List<XmlAttributeNode> attributes = new List<XmlAttributeNode>();
    while (type != TokenType.GT && type != TokenType.SLASH_GT && type != TokenType.EOF) {
      if (type == TokenType.TAG) {
        attributes.add(_parseAttribute());
      } else {
        _reportUnexpectedToken();
        _currentToken = _currentToken.next;
      }
      type = _currentToken.type;
    }
    return attributes;
  }

  /**
   * Parse the stream for a sequence of tag nodes existing within a parent tag node. This method
   * advances the current token to the next [TokenType#LT_SLASH] or [TokenType#EOF].
   *
   * @return a list of nodes (not `null`, contains no `null`s)
   */
  List<XmlTagNode> _parseChildTagNodes() {
    TokenType type = _currentToken.type;
    if (type == TokenType.LT_SLASH || type == TokenType.EOF) {
      return XmlTagNode.NO_TAG_NODES;
    }
    List<XmlTagNode> nodes = new List<XmlTagNode>();
    while (type != TokenType.LT_SLASH && type != TokenType.EOF) {
      if (type == TokenType.LT) {
        nodes.add(_parseTagNode());
      } else if (type == TokenType.COMMENT) {
        // ignored token
        _currentToken = _currentToken.next;
      } else {
        _reportUnexpectedToken();
        _currentToken = _currentToken.next;
      }
      type = _currentToken.type;
    }
    return nodes;
  }

  /**
   * Parse the token stream for the next tag node. This method advances current token over the
   * parsed tag node, but should only be called if the current token is [TokenType#LT]
   *
   * @return the tag node or `null` if none found
   */
  XmlTagNode _parseTagNode() {
    // Assume that the current node is a tag node start TokenType#LT
    Token nodeStart = _currentToken;
    _currentToken = _currentToken.next;
    // Get the tag or create a synthetic tag and report an error
    Token tag;
    if (_currentToken.type == TokenType.TAG) {
      tag = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      _reportUnexpectedToken();
      tag = _insertSyntheticToken(TokenType.TAG);
    }
    // Parse the attributes
    List<XmlAttributeNode> attributes = _parseAttributes();
    // Token ending attribute list
    Token attributeEnd;
    if (_currentToken.type == TokenType.GT || _currentToken.type == TokenType.SLASH_GT) {
      attributeEnd = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      _reportUnexpectedToken();
      attributeEnd = _insertSyntheticToken(TokenType.SLASH_GT);
    }
    // If the node has no children, then return the node
    if (attributeEnd.type == TokenType.SLASH_GT || isSelfClosing(tag)) {
      return createTagNode(nodeStart, tag, attributes, attributeEnd, XmlTagNode.NO_TAG_NODES, _currentToken, null, attributeEnd);
    }
    // Parse the child tag nodes
    List<XmlTagNode> tagNodes = _parseChildTagNodes();
    // Token ending child tag nodes
    Token contentEnd;
    if (_currentToken.type == TokenType.LT_SLASH) {
      contentEnd = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      // TODO (danrubel): handle self closing HTML elements by inserting synthetic tokens
      // but not reporting an error
      _reportUnexpectedToken();
      contentEnd = _insertSyntheticToken(TokenType.LT_SLASH);
    }
    // Closing tag
    Token closingTag;
    if (_currentToken.type == TokenType.TAG) {
      closingTag = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      _reportUnexpectedToken();
      closingTag = _insertSyntheticToken(TokenType.TAG);
    }
    // Token ending node
    Token nodeEnd;
    if (_currentToken.type == TokenType.GT) {
      nodeEnd = _currentToken;
      _currentToken = _currentToken.next;
    } else {
      _reportUnexpectedToken();
      nodeEnd = _insertSyntheticToken(TokenType.GT);
    }
    return createTagNode(nodeStart, tag, attributes, attributeEnd, tagNodes, contentEnd, closingTag, nodeEnd);
  }

  /**
   * Report the current token as unexpected
   */
  void _reportUnexpectedToken() {
    // TODO (danrubel): report unexpected token
  }
}

/**
 * Instances of `XmlTagNode` represent XML or HTML elements such as `` and
 * `<body foo="bar"> ... </body>`.
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
  final Token nodeStart;

  /**
   * The [TokenType#TAG] token after the starting '&lt;' (not `null`).
   */
  final Token _tag;

  /**
   * The attributes contained by the receiver (not `null`, contains no `null`s).
   */
  List<XmlAttributeNode> _attributes;

  /**
   * The [TokenType#GT] or [TokenType#SLASH_GT] token after the attributes (not
   * `null`). The token may be the same token as [nodeEnd] if there are no child
   * [tagNodes].
   */
  final Token attributeEnd;

  /**
   * The tag nodes contained in the receiver (not `null`, contains no `null`s).
   */
  List<XmlTagNode> _tagNodes;

  /**
   * The token (not `null`) after the content, which may be
   * * (1) [TokenType#LT_SLASH] for nodes with open and close tags, or
   * * (2) the [TokenType#LT] nodeStart of the next sibling node if this node is self
   * closing or the attributeEnd is [TokenType#SLASH_GT], or
   * * (3) [TokenType#EOF] if the node does not have a closing tag and is the last node in
   * the stream [TokenType#LT_SLASH] token after the content, or `null` if there is no
   * content and the attributes ended with [TokenType#SLASH_GT].
   */
  final Token contentEnd;

  /**
   * The closing [TokenType#TAG] after the child elements or `null` if there is no
   * content and the attributes ended with [TokenType#SLASH_GT]
   */
  final Token closingTag;

  /**
   * The ending [TokenType#GT] or [TokenType#SLASH_GT] token (not `null`).
   */
  final Token nodeEnd;

  /**
   * The expressions that are embedded in the tag's content.
   */
  List<XmlExpression> expressions = XmlExpression.EMPTY_ARRAY;

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
   *          * (1) [TokenType#LT_SLASH] for nodes with open and close tags, or
   *          * (2) the [TokenType#LT] nodeStart of the next sibling node if this node is
   *          self closing or the attributeEnd is [TokenType#SLASH_GT], or
   *          * (3) [TokenType#EOF] if the node does not have a closing tag and is the last
   *          node in the stream [TokenType#LT_SLASH] token after the content, or `null`
   *          if there is no content and the attributes ended with [TokenType#SLASH_GT].
   * @param closingTag the closing [TokenType#TAG] after the child elements or `null` if
   *          there is no content and the attributes ended with [TokenType#SLASH_GT]
   * @param nodeEnd the ending [TokenType#GT] or [TokenType#SLASH_GT] token (not
   *          `null`)
   */
  XmlTagNode(this.nodeStart, this._tag, List<XmlAttributeNode> attributes, this.attributeEnd, List<XmlTagNode> tagNodes, this.contentEnd, this.closingTag, this.nodeEnd) {
    this._attributes = becomeParentOfAll(attributes, ifEmpty: NO_ATTRIBUTES);
    this._tagNodes = becomeParentOfAll(tagNodes, ifEmpty: NO_TAG_NODES);
  }

  @override
  accept(XmlVisitor visitor) => visitor.visitXmlTagNode(this);

  /**
   * Answer the attribute with the specified name.
   *
   * @param name the attribute name
   * @return the attribute or `null` if no matching attribute is found
   */
  XmlAttributeNode getAttribute(String name) {
    for (XmlAttributeNode attribute in _attributes) {
      if (attribute.name == name) {
        return attribute;
      }
    }
    return null;
  }

  /**
   * Answer the receiver's attributes. Callers should not manipulate the returned list to edit the
   * AST structure.
   *
   * @return the attributes (not `null`, contains no `null`s)
   */
  List<XmlAttributeNode> get attributes => _attributes;

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

  @override
  Token get beginToken => nodeStart;

  /**
   * Return a string representing the content contained in the receiver. This
   * includes the textual representation of any child tag nodes ([getTagNodes]).
   * Whitespace between '&lt;', '&lt;/', and '>', '/>' is discarded, but all
   * other whitespace is preserved.
   */
  String get content {
    Token token = attributeEnd.next;
    if (identical(token, contentEnd)) {
      return "";
    }
    // TODO(danrubel) Handle CDATA and replace HTML character encodings with
    // the actual characters.
    String content = token.lexeme;
    token = token.next;
    if (identical(token, contentEnd)) {
      return content;
    }
    StringBuffer buffer = new StringBuffer();
    buffer.write(content);
    while (!identical(token, contentEnd)) {
      buffer.write(token.lexeme);
      token = token.next;
    }
    return buffer.toString();
  }

  @override
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
    if (!_tagNodes.isEmpty) {
      return _tagNodes[_tagNodes.length - 1].endToken;
    }
    if (attributeEnd != null) {
      return attributeEnd;
    }
    if (!_attributes.isEmpty) {
      return _attributes[_attributes.length - 1].endToken;
    }
    return _tag;
  }

  /**
   * Answer the tag name after the starting '&lt;'.
   *
   * @return the tag name (not `null`)
   */
  String get tag => _tag.lexeme;

  /**
   * Answer the tag nodes contained in the receiver. Callers should not manipulate the returned list
   * to edit the AST structure.
   *
   * @return the children (not `null`, contains no `null`s)
   */
  List<XmlTagNode> get tagNodes => _tagNodes;

  /**
   * Answer the [TokenType#TAG] token after the starting '&lt;'.
   *
   * @return the token (not `null`)
   */
  Token get tagToken => _tag;

  @override
  void visitChildren(XmlVisitor visitor) {
    for (XmlAttributeNode node in _attributes) {
      node.accept(visitor);
    }
    for (XmlTagNode node in _tagNodes) {
      node.accept(visitor);
    }
  }
}

/**
 * The interface `XmlVisitor` defines the behavior of objects that can be used to visit an
 * [XmlNode] structure.
 */
abstract class XmlVisitor<R> {
  R visitHtmlScriptTagNode(HtmlScriptTagNode node);

  R visitHtmlUnit(HtmlUnit htmlUnit);

  R visitXmlAttributeNode(XmlAttributeNode xmlAttributeNode);

  R visitXmlTagNode(XmlTagNode xmlTagNode);
}