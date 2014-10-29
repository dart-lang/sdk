// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.correction.util;

import 'dart:math';

import 'package:analysis_server/src/protocol.dart' show SourceChange,
    SourceEdit;
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * @return <code>true</code> if given [List]s are identical at given position.
 */
bool allListsIdentical(List<List> lists, int position) {
  Object element = lists[0][position];
  for (List list in lists) {
    if (list[position] != element) {
      return false;
    }
  }
  return true;
}


/**
 * Climbs up [PrefixedIdentifier] and [ProperyAccess] nodes that include [node].
 */
Expression climbPropertyAccess(AstNode node) {
  while (true) {
    AstNode parent = node.parent;
    if (parent is PrefixedIdentifier && parent.identifier == node) {
      node = parent;
      continue;
    }
    if (parent is PropertyAccess && parent.propertyName == node) {
      node = parent;
      continue;
    }
    return node;
  }
}


/**
 * TODO(scheglov) replace with nodes once there will be [CompilationUnit#getComments].
 *
 * Returns [SourceRange]s of all comments in [unit].
 */
List<SourceRange> getCommentRanges(CompilationUnit unit) {
  List<SourceRange> ranges = <SourceRange>[];
  Token token = unit.beginToken;
  while (token != null && token.type != TokenType.EOF) {
    Token commentToken = token.precedingComments;
    while (commentToken != null) {
      ranges.add(rangeToken(commentToken));
      commentToken = commentToken.next;
    }
    token = token.next;
  }
  return ranges;
}


String getDefaultValueCode(DartType type) {
  if (type != null) {
    String typeName = type.displayName;
    if (typeName == "bool") {
      return "false";
    }
    if (typeName == "int") {
      return "0";
    }
    if (typeName == "double") {
      return "0.0";
    }
    if (typeName == "String") {
      return "''";
    }
  }
  // no better guess
  return "null";
}



/**
 * Return the name of the [Element] kind.
 */
String getElementKindName(Element element) {
  return element.kind.displayName;
}

/**
 * Returns the name to display in the UI for the given [Element].
 */
String getElementQualifiedName(Element element) {
  ElementKind kind = element.kind;
  if (kind == ElementKind.FIELD || kind == ElementKind.METHOD) {
    return '${element.enclosingElement.displayName}.${element.displayName}';
  } else {
    return element.displayName;
  }
}


/**
 * If the given [AstNode] is in a [ClassDeclaration], returns the
 * [ClassElement]. Otherwise returns `null`.
 */
ClassElement getEnclosingClassElement(AstNode node) {
  ClassDeclaration enclosingClassNode =
      node.getAncestor((node) => node is ClassDeclaration);
  if (enclosingClassNode != null) {
    return enclosingClassNode.element;
  }
  return null;
}


/**
 * Returns a class or an unit member enclosing the given [node].
 */
AstNode getEnclosingClassOrUnitMember(AstNode node) {
  AstNode member = node;
  while (node != null) {
    if (node is ClassDeclaration) {
      return member;
    }
    if (node is CompilationUnit) {
      return member;
    }
    member = node;
    node = node.parent;
  }
  return null;
}


/**
 * @return the [ExecutableElement] of the enclosing executable [AstNode].
 */
ExecutableElement getEnclosingExecutableElement(AstNode node) {
  while (node != null) {
    if (node is FunctionDeclaration) {
      return node.element;
    }
    if (node is ConstructorDeclaration) {
      return node.element;
    }
    if (node is MethodDeclaration) {
      return node.element;
    }
    node = node.parent;
  }
  return null;
}


/**
 * @return the enclosing executable [AstNode].
 */
AstNode getEnclosingExecutableNode(AstNode node) {
  while (node != null) {
    if (node is FunctionDeclaration) {
      return node;
    }
    if (node is ConstructorDeclaration) {
      return node;
    }
    if (node is MethodDeclaration) {
      return node;
    }
    node = node.parent;
  }
  return null;
}


/**
 * Returns [getExpressionPrecedence] for the parent of [node],
 * or `0` if the parent node is [ParenthesizedExpression].
 *
 * The reason is that `(expr)` is always executed after `expr`.
 */
int getExpressionParentPrecedence(AstNode node) {
  AstNode parent = node.parent;
  if (parent is ParenthesizedExpression) {
    return 0;
  }
  return getExpressionPrecedence(parent);
}


/**
 * Returns the precedence of [node] it is an [Expression], negative otherwise.
 */
int getExpressionPrecedence(AstNode node) {
  if (node is Expression) {
    return node.precedence;
  }
  return -1000;
}


/**
 * Returns the namespace of the given [ImportElement].
 */
Map<String, Element> getImportNamespace(ImportElement imp) {
  NamespaceBuilder builder = new NamespaceBuilder();
  Namespace namespace = builder.createImportNamespaceForDirective(imp);
  return namespace.definedNames;
}

/**
 * Returns the line prefix from the given source, i.e. basically just a
 * whitespace prefix of the given [String].
 */
String getLinePrefix(String line) {
  int index = 0;
  while (index < line.length) {
    int c = line.codeUnitAt(index);
    if (!isWhitespace(c)) {
      break;
    }
    index++;
  }
  return line.substring(0, index);
}

/**
 * @return the [LocalVariableElement] or [ParameterElement] if given
 *         [SimpleIdentifier] is the reference to local variable or parameter, or
 *         <code>null</code> in the other case.
 */
VariableElement getLocalOrParameterVariableElement(SimpleIdentifier node) {
  Element element = node.staticElement;
  if (element is LocalVariableElement) {
    return element;
  }
  if (element is ParameterElement) {
    return element;
  }
  return null;
}


/**
 * @return the [LocalVariableElement] if given [SimpleIdentifier] is the reference to
 *         local variable, or <code>null</code> in the other case.
 */
LocalVariableElement getLocalVariableElement(SimpleIdentifier node) {
  Element element = node.staticElement;
  if (element is LocalVariableElement) {
    return element;
  }
  return null;
}


/**
 * @return the nearest common ancestor [AstNode] of the given [AstNode]s.
 */
AstNode getNearestCommonAncestor(List<AstNode> nodes) {
  // may be no nodes
  if (nodes.isEmpty) {
    return null;
  }
  // prepare parents
  List<List<AstNode>> parents = [];
  for (AstNode node in nodes) {
    parents.add(getParents(node));
  }
  // find min length
  int minLength = 1 << 20;
  for (List<AstNode> parentList in parents) {
    minLength = min(minLength, parentList.length);
  }
  // find deepest parent
  int i = 0;
  for ( ; i < minLength; i++) {
    if (!allListsIdentical(parents, i)) {
      break;
    }
  }
  return parents[0][i - 1];
}


/**
 * Returns the [Expression] qualifier if given node is the name part of a
 * [PropertyAccess] or a [PrefixedIdentifier]. Maybe `null`.
 */
Expression getNodeQualifier(SimpleIdentifier node) {
  AstNode parent = node.parent;
  if (parent is PropertyAccess) {
    PropertyAccess propertyAccess = parent;
    if (identical(propertyAccess.propertyName, node)) {
      return propertyAccess.target;
    }
  }
  if (parent is PrefixedIdentifier) {
    PrefixedIdentifier prefixed = parent;
    if (identical(prefixed.identifier, node)) {
      return prefixed.prefix;
    }
  }
  return null;
}


/**
 * Returns the [ParameterElement] if the given [SimpleIdentifier] is a reference
 * to a parameter, or `null` in the other case.
 */
ParameterElement getParameterElement(SimpleIdentifier node) {
  Element element = node.staticElement;
  if (element is ParameterElement) {
    return element;
  }
  return null;
}


/**
 * @return parent [AstNode]s from [CompilationUnit] (at index "0") to the given one.
 */
List<AstNode> getParents(AstNode node) {
  // prepare number of parents
  int numParents = 0;
  {
    AstNode current = node.parent;
    while (current != null) {
      numParents++;
      current = current.parent;
    }
  }
  // fill array of parents
  List<AstNode> parents = new List<AstNode>(numParents);
  AstNode current = node.parent;
  int index = numParents;
  while (current != null) {
    parents[--index] = current;
    current = current.parent;
  }
  return parents;
}


/**
 * Returns a [PropertyAccessorElement] if the given [SimpleIdentifier] is a
 * reference to a property, or `null` in the other case.
 */
PropertyAccessorElement getPropertyAccessorElement(SimpleIdentifier node) {
  Element element = node.staticElement;
  if (element is PropertyAccessorElement) {
    return element;
  }
  return null;
}


/**
 * If given [AstNode] is name of qualified property extraction, returns target from which
 * this property is extracted. Otherwise `null`.
 */
Expression getQualifiedPropertyTarget(AstNode node) {
  AstNode parent = node.parent;
  if (parent is PrefixedIdentifier) {
    PrefixedIdentifier prefixed = parent;
    if (prefixed.identifier == node) {
      return parent.prefix;
    }
  }
  if (parent is PropertyAccess) {
    PropertyAccess access = parent;
    if (access.propertyName == node) {
      return access.realTarget;
    }
  }
  return null;
}


/**
 * Returns the given [Statement] if not a [Block], or the first child
 * [Statement] if a [Block], or `null` if more than one child.
 */
Statement getSingleStatement(Statement statement) {
  if (statement is Block) {
    List<Statement> blockStatements = statement.statements;
    if (blockStatements.length != 1) {
      return null;
    }
    return blockStatements[0];
  }
  return statement;
}

/**
 * Returns the [String] content of the given [Source].
 */
String getSourceContent(AnalysisContext context, Source source) {
  return context.getContents(source).data;
}


/**
 * Returns the given [Statement] if not a [Block], or all the children
 * [Statement]s if a [Block].
 */
List<Statement> getStatements(Statement statement) {
  if (statement is Block) {
    return statement.statements;
  }
  return [statement];
}


/**
 * Checks if the given [Element]'s display name equals to the given name.
 */
bool hasDisplayName(Element element, String name) {
  if (element == null) {
    return false;
  }
  return element.displayName == name;
}


/**
 * Checks if the given [PropertyAccessorElement] is an accessor of a
 * [FieldElement].
 */
bool isFieldAccessorElement(PropertyAccessorElement accessor) {
  return accessor != null && accessor.variable is FieldElement;
}


/**
 * Checks if given [DartNode] is the left hand side of an assignment, or a
 * declaration of a variable.
 */
bool isLeftHandOfAssignment(SimpleIdentifier node) {
  if (node.inSetterContext()) {
    return true;
  }
  return node.parent is VariableDeclaration &&
      (node.parent as VariableDeclaration).name == node;
}


/**
 * @return `true` if the given [SimpleIdentifier] is the name of the
 *         [NamedExpression].
 */
bool isNamedExpressionName(SimpleIdentifier node) {
  AstNode parent = node.parent;
  if (parent is Label) {
    Label label = parent;
    if (identical(label.label, node)) {
      AstNode parent2 = label.parent;
      if (parent2 is NamedExpression) {
        return identical(parent2.name, label);
      }
    }
  }
  return false;
}


/**
 * If the given [expression] is the `expression` property of a [NamedExpression]
 * then returns this [NamedExpression]. Otherwise returns [expression].
 */
Expression stepUpNamedExpression(Expression expression) {
  if (expression != null) {
    AstNode parent = expression.parent;
    if (parent is NamedExpression && parent.expression == expression) {
      return parent;
    }
  }
  return expression;
}


class CorrectionUtils {
  final CompilationUnit unit;

  LibraryElement _library;
  String _buffer;
  String _endOfLine;

  CorrectionUtils(this.unit) {
    CompilationUnitElement unitElement = unit.element;
    this._library = unitElement.library;
    this._buffer = unitElement.context.getContents(unitElement.source).data;
  }

  /**
   * Returns the EOL to use for this [CompilationUnit].
   */
  String get endOfLine {
    if (_endOfLine == null) {
      if (_buffer.contains("\r\n")) {
        _endOfLine = "\r\n";
      } else {
        _endOfLine = "\n";
      }
    }
    return _endOfLine;
  }

  /**
   * Returns an [Edit] that changes indentation of the source of the given
   * [SourceRange] from [oldIndent] to [newIndent], keeping indentation of lines
   * relative to each other.
   */
  SourceEdit createIndentEdit(SourceRange range, String oldIndent,
      String newIndent) {
    String newSource = replaceSourceRangeIndent(range, oldIndent, newIndent);
    return new SourceEdit(range.offset, range.length, newSource);
  }

  /**
   * Returns the [AstNode] that encloses the given offset.
   */
  AstNode findNode(int offset) =>
      new NodeLocator.con1(offset).searchWithin(unit);

  /**
   * Returns the actual type source of the given [Expression], may be `null`
   * if can not be resolved, should be treated as the `dynamic` type.
   */
  String getExpressionTypeSource(Expression expression) {
    if (expression == null) {
      return null;
    }
    DartType type = expression.bestType;
    if (type.isDynamic) {
      return null;
    }
    return getTypeSource(type);
  }

  /**
   * Returns the indentation with the given level.
   */
  String getIndent(int level) => repeat('  ', level);

  /**
   * Returns a [InsertDesc] describing where to insert a new library-related
   * directive.
   */
  CorrectionUtils_InsertDesc getInsertDescImport() {
    // analyze directives
    Directive prevDirective = null;
    for (Directive directive in unit.directives) {
      if (directive is LibraryDirective ||
          directive is ImportDirective ||
          directive is ExportDirective) {
        prevDirective = directive;
      }
    }
    // insert after last library-related directive
    if (prevDirective != null) {
      CorrectionUtils_InsertDesc result = new CorrectionUtils_InsertDesc();
      result.offset = prevDirective.end;
      String eol = endOfLine;
      if (prevDirective is LibraryDirective) {
        result.prefix = "${eol}${eol}";
      } else {
        result.prefix = eol;
      }
      return result;
    }
    // no directives, use "top" location
    return getInsertDescTop();
  }

  /**
   * Returns a [InsertDesc] describing where to insert a new 'part' directive.
   */
  CorrectionUtils_InsertDesc getInsertDescPart() {
    // analyze directives
    Directive prevDirective = null;
    for (Directive directive in unit.directives) {
      prevDirective = directive;
    }
    // insert after last directive
    if (prevDirective != null) {
      CorrectionUtils_InsertDesc result = new CorrectionUtils_InsertDesc();
      result.offset = prevDirective.end;
      String eol = endOfLine;
      if (prevDirective is PartDirective) {
        result.prefix = eol;
      } else {
        result.prefix = "${eol}${eol}";
      }
      return result;
    }
    // no directives, use "top" location
    return getInsertDescTop();
  }

  /**
   * Returns a [InsertDesc] describing where to insert a new directive or a
   * top-level declaration at the top of the file.
   */
  CorrectionUtils_InsertDesc getInsertDescTop() {
    // skip leading line comments
    int offset = 0;
    bool insertEmptyLineBefore = false;
    bool insertEmptyLineAfter = false;
    String source = _buffer;
    // skip hash-bang
    if (offset < source.length - 2) {
      String linePrefix = getText(offset, 2);
      if (linePrefix == "#!") {
        insertEmptyLineBefore = true;
        offset = getLineNext(offset);
        // skip empty lines to first line comment
        int emptyOffset = offset;
        while (emptyOffset < source.length - 2) {
          int nextLineOffset = getLineNext(emptyOffset);
          String line = source.substring(emptyOffset, nextLineOffset);
          if (line.trim().isEmpty) {
            emptyOffset = nextLineOffset;
            continue;
          } else if (line.startsWith("//")) {
            offset = emptyOffset;
            break;
          } else {
            break;
          }
        }
      }
    }
    // skip line comments
    while (offset < source.length - 2) {
      String linePrefix = getText(offset, 2);
      if (linePrefix == "//") {
        insertEmptyLineBefore = true;
        offset = getLineNext(offset);
      } else {
        break;
      }
    }
    // determine if empty line is required after
    int nextLineOffset = getLineNext(offset);
    String insertLine = source.substring(offset, nextLineOffset);
    if (!insertLine.trim().isEmpty) {
      insertEmptyLineAfter = true;
    }
    // fill InsertDesc
    CorrectionUtils_InsertDesc desc = new CorrectionUtils_InsertDesc();
    desc.offset = offset;
    if (insertEmptyLineBefore) {
      desc.prefix = endOfLine;
    }
    if (insertEmptyLineAfter) {
      desc.suffix = endOfLine;
    }
    return desc;
  }

  /**
   * Skips whitespace characters and single EOL on the right from [index].
   *
   * If [index] the end of a statement or method, then in the most cases it is
   * a start of the next line.
   */
  int getLineContentEnd(int index) {
    int length = _buffer.length;
    // skip whitespace characters
    while (index < length) {
      int c = _buffer.codeUnitAt(index);
      if (!isWhitespace(c) || c == 0x0D || c == 0x0A) {
        break;
      }
      index++;
    }
    // skip single \r
    if (index < length && _buffer.codeUnitAt(index) == 0x0D) {
      index++;
    }
    // skip single \n
    if (index < length && _buffer.codeUnitAt(index) == 0x0A) {
      index++;
    }
    // done
    return index;
  }

  /**
   * Skips spaces and tabs on the left from [index].
   *
   * If [index] is the start or a statement, then in the most cases it is a
   * start on its line.
   */
  int getLineContentStart(int index) {
    while (index > 0) {
      int c = _buffer.codeUnitAt(index - 1);
      if (!isSpace(c)) {
        break;
      }
      index--;
    }
    return index;
  }

  /**
   * Returns a start index of the next line after the line which contains the
   * given index.
   */
  int getLineNext(int index) {
    int length = _buffer.length;
    // skip to the end of the line
    while (index < length) {
      int c = _buffer.codeUnitAt(index);
      if (c == 0xD || c == 0xA) {
        break;
      }
      index++;
    }
    // skip single \r
    if (index < length && _buffer.codeUnitAt(index) == 0xD) {
      index++;
    }
    // skip single \n
    if (index < length && _buffer.codeUnitAt(index) == 0xA) {
      index++;
    }
    // done
    return index;
  }

  /**
   * Returns the whitespace prefix of the line which contains given offset.
   */
  String getLinePrefix(int index) {
    int lineStart = getLineThis(index);
    int length = _buffer.length;
    int lineNonWhitespace = lineStart;
    while (lineNonWhitespace < length) {
      int c = _buffer.codeUnitAt(lineNonWhitespace);
      if (c == 0xD || c == 0xA) {
        break;
      }
      if (!isWhitespace(c)) {
        break;
      }
      lineNonWhitespace++;
    }
    return getText(lineStart, lineNonWhitespace - lineStart);
  }

  /**
   * Returns a [SourceRange] that covers [range] and extends (if possible) to
   * cover whole lines.
   */
  SourceRange getLinesRange(SourceRange range) {
    // start
    int startOffset = range.offset;
    int startLineOffset = getLineContentStart(startOffset);
    // end
    int endOffset = range.end;
    int afterEndLineOffset = getLineContentEnd(endOffset);
    // range
    return rangeStartEnd(startLineOffset, afterEndLineOffset);
  }

  /**
   * Returns a [SourceRange] that covers all the given [Statement]s.
   */
  SourceRange getLinesRangeStatements(List<Statement> statements) {
    SourceRange range = rangeNodes(statements);
    return getLinesRange(range);
  }

  /**
   * Returns the start index of the line which contains given index.
   */
  int getLineThis(int index) {
    while (index > 0) {
      int c = _buffer.codeUnitAt(index - 1);
      if (c == 0xD || c == 0xA) {
        break;
      }
      index--;
    }
    return index;
  }

  /**
   * Returns the line prefix consisting of spaces and tabs on the left from the given
   *         [AstNode].
   */
  String getNodePrefix(AstNode node) {
    int offset = node.offset;
    // function literal is special, it uses offset of enclosing line
    if (node is FunctionExpression) {
      return getLinePrefix(offset);
    }
    // use just prefix directly before node
    return getPrefix(offset);
  }

  /**
   * Returns the text of the given [AstNode] in the unit.
   */
  String getNodeText(AstNode node) {
    return getText(node.offset, node.length);
  }

  /**
   * @return the source for the parameter with the given type and name.
   */
  String getParameterSource(DartType type, String name) {
    // no type
    if (type == null || type.isDynamic) {
      return name;
    }
    // function type
    if (type is FunctionType) {
      FunctionType functionType = type;
      StringBuffer sb = new StringBuffer();
      // return type
      DartType returnType = functionType.returnType;
      if (returnType != null && !returnType.isDynamic) {
        sb.write(getTypeSource(returnType));
        sb.write(' ');
      }
      // parameter name
      sb.write(name);
      // parameters
      sb.write('(');
      List<ParameterElement> fParameters = functionType.parameters;
      for (int i = 0; i < fParameters.length; i++) {
        ParameterElement fParameter = fParameters[i];
        if (i != 0) {
          sb.write(", ");
        }
        sb.write(getParameterSource(fParameter.type, fParameter.name));
      }
      sb.write(')');
      // done
      return sb.toString();
    }
    // simple type
    return "${getTypeSource(type)} ${name}";
  }

  /**
   * Returns the line prefix consisting of spaces and tabs on the left from the
   * given offset.
   */
  String getPrefix(int endIndex) {
    int startIndex = getLineContentStart(endIndex);
    return _buffer.substring(startIndex, endIndex);
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String getRangeText(SourceRange range) {
    return getText(range.offset, range.length);
  }

  /**
   * Returns the text of the given range in the unit.
   */
  String getText(int offset, int length) {
    return _buffer.substring(offset, offset + length);
  }

  /**
   * Returns the source to reference [type] in this [CompilationUnit].
   */
  String getTypeSource(DartType type) {
    StringBuffer sb = new StringBuffer();
    // just a Function, not FunctionTypeAliasElement
    if (type is FunctionType && type.element is! FunctionTypeAliasElement) {
      return "Function";
    }
    // prepare element
    Element element = type.element;
    if (element == null) {
      String source = type.toString();
      source = source.replaceAll('<dynamic>', '');
      source = source.replaceAll('<dynamic, dynamic>', '');
      return source;
    }
    // append prefix
    {
      ImportElement imp = _getImportElement(element);
      if (imp != null && imp.prefix != null) {
        sb.write(imp.prefix.displayName);
        sb.write(".");
      }
    }
    // append simple name
    String name = element.displayName;
    sb.write(name);
    // may be type arguments
    if (type is ParameterizedType) {
      List<DartType> arguments = type.typeArguments;
      // check if has arguments
      bool hasArguments = false;
      for (DartType argument in arguments) {
        if (!argument.isDynamic) {
          hasArguments = true;
          break;
        }
      }
      // append type arguments
      if (hasArguments) {
        sb.write("<");
        for (int i = 0; i < arguments.length; i++) {
          DartType argument = arguments[i];
          if (i != 0) {
            sb.write(", ");
          }
          sb.write(getTypeSource(argument));
        }
        sb.write(">");
      }
    }
    // done
    return sb.toString();
  }

  /**
   * Indents given source left or right.
   */
  String indentSourceLeftRight(String source, bool right) {
    StringBuffer sb = new StringBuffer();
    String indent = getIndent(1);
    String eol = endOfLine;
    List<String> lines = source.split(eol);
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      // last line, stop if empty
      if (i == lines.length - 1 && isEmpty(line)) {
        break;
      }
      // update line
      if (right) {
        line = "${indent}${line}";
      } else {
        line = removeStart(line, indent);
      }
      // append line
      sb.write(line);
      sb.write(eol);
    }
    return sb.toString();
  }

  /**
   * @return the source of the inverted condition for the given logical expression.
   */
  String invertCondition(Expression expression) =>
      _invertCondition0(expression)._source;

  /**
   * @return <code>true</code> if selection range contains only whitespace or comments
   */
  bool isJustWhitespaceOrComment(SourceRange range) {
    String trimmedText = getRangeText(range).trim();
    // may be whitespace
    if (trimmedText.isEmpty) {
      return true;
    }
    // may be comment
    return TokenUtils.getTokens(trimmedText).isEmpty;
  }

  /**
   * Returns the source with indentation changed from [oldIndent] to
   * [newIndent], keeping indentation of lines relative to each other.
   */
  String replaceSourceIndent(String source, String oldIndent,
      String newIndent) {
    // prepare STRING token ranges
    List<SourceRange> lineRanges = [];
    {
      List<Token> tokens = TokenUtils.getTokens(source);
      for (Token token in tokens) {
        if (token.type == TokenType.STRING) {
          lineRanges.add(rangeToken(token));
        }
        token = token.next;
      }
    }
    // re-indent lines
    StringBuffer sb = new StringBuffer();
    String eol = endOfLine;
    List<String> lines = source.split(eol);
    int lineOffset = 0;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      // last line, stop if empty
      if (i == lines.length - 1 && isEmpty(line)) {
        break;
      }
      // check if "offset" is in one of the String ranges
      bool inString = false;
      for (SourceRange lineRange in lineRanges) {
        if (lineOffset > lineRange.offset && lineOffset < lineRange.end) {
          inString = true;
        }
        if (lineOffset > lineRange.end) {
          break;
        }
      }
      lineOffset += line.length + eol.length;
      // update line indent
      if (!inString) {
        line = "${newIndent}${removeStart(line, oldIndent)}";
      }
      // append line
      sb.write(line);
      sb.write(eol);
    }
    return sb.toString();
  }

  /**
   * Returns the source of the given [SourceRange] with indentation changed
   * from [oldIndent] to [newIndent], keeping indentation of lines relative
   * to each other.
   */
  String replaceSourceRangeIndent(SourceRange range, String oldIndent,
      String newIndent) {
    String oldSource = getRangeText(range);
    return replaceSourceIndent(oldSource, oldIndent, newIndent);
  }

  /**
   * @return <code>true</code> if "selection" covers "node" and there are any non-whitespace tokens
   *         between "selection" and "node" start/end.
   */
  bool selectionIncludesNonWhitespaceOutsideNode(SourceRange selection,
      AstNode node) {
    return _selectionIncludesNonWhitespaceOutsideRange(
        selection,
        rangeNode(node));
  }

  /**
   * @return <code>true</code> if given range of [BinaryExpression] can be extracted.
   */
  bool validateBinaryExpressionRange(BinaryExpression binaryExpression,
      SourceRange range) {
    // only parts of associative expression are safe to extract
    if (!binaryExpression.operator.type.isAssociativeOperator) {
      return false;
    }
    // prepare selected operands
    List<Expression> operands = _getOperandsInOrderFor(binaryExpression);
    List<Expression> subOperands = _getOperandsForSourceRange(operands, range);
    // if empty, then something wrong with selection
    if (subOperands.isEmpty) {
      return false;
    }
    // may be some punctuation included into selection - operators, braces, etc
    if (_selectionIncludesNonWhitespaceOutsideOperands(range, subOperands)) {
      return false;
    }
    // OK
    return true;
  }

  /**
   * @return the [ImportElement] used to import given [Element] into [library].
   *         May be `null` if was not imported, i.e. declared in the same library.
   */
  ImportElement _getImportElement(Element element) {
    for (ImportElement imp in _library.imports) {
      Map<String, Element> definedNames = getImportNamespace(imp);
      if (definedNames.containsValue(element)) {
        return imp;
      }
    }
    return null;
  }

  /**
   * @return the [InvertedCondition] for the given logical expression.
   */
  _InvertedCondition _invertCondition0(Expression expression) {
    if (expression is BooleanLiteral) {
      BooleanLiteral literal = expression;
      if (literal.value) {
        return _InvertedCondition._simple("false");
      } else {
        return _InvertedCondition._simple("true");
      }
    }
    if (expression is BinaryExpression) {
      BinaryExpression binary = expression;
      TokenType operator = binary.operator.type;
      Expression le = binary.leftOperand;
      Expression re = binary.rightOperand;
      _InvertedCondition ls = _invertCondition0(le);
      _InvertedCondition rs = _invertCondition0(re);
      if (operator == TokenType.LT) {
        return _InvertedCondition._binary2(ls, " >= ", rs);
      }
      if (operator == TokenType.GT) {
        return _InvertedCondition._binary2(ls, " <= ", rs);
      }
      if (operator == TokenType.LT_EQ) {
        return _InvertedCondition._binary2(ls, " > ", rs);
      }
      if (operator == TokenType.GT_EQ) {
        return _InvertedCondition._binary2(ls, " < ", rs);
      }
      if (operator == TokenType.EQ_EQ) {
        return _InvertedCondition._binary2(ls, " != ", rs);
      }
      if (operator == TokenType.BANG_EQ) {
        return _InvertedCondition._binary2(ls, " == ", rs);
      }
      if (operator == TokenType.AMPERSAND_AMPERSAND) {
        return _InvertedCondition._binary(
            TokenType.BAR_BAR.precedence,
            ls,
            " || ",
            rs);
      }
      if (operator == TokenType.BAR_BAR) {
        return _InvertedCondition._binary(
            TokenType.AMPERSAND_AMPERSAND.precedence,
            ls,
            " && ",
            rs);
      }
    }
    if (expression is IsExpression) {
      IsExpression isExpression = expression;
      String expressionSource = getNodeText(isExpression.expression);
      String typeSource = getNodeText(isExpression.type);
      if (isExpression.notOperator == null) {
        return _InvertedCondition._simple(
            "${expressionSource} is! ${typeSource}");
      } else {
        return _InvertedCondition._simple(
            "${expressionSource} is ${typeSource}");
      }
    }
    if (expression is PrefixExpression) {
      PrefixExpression prefixExpression = expression;
      TokenType operator = prefixExpression.operator.type;
      if (operator == TokenType.BANG) {
        Expression operand = prefixExpression.operand;
        while (operand is ParenthesizedExpression) {
          ParenthesizedExpression pe = operand as ParenthesizedExpression;
          operand = pe.expression;
        }
        return _InvertedCondition._simple(getNodeText(operand));
      }
    }
    if (expression is ParenthesizedExpression) {
      ParenthesizedExpression pe = expression;
      Expression innerExpresion = pe.expression;
      while (innerExpresion is ParenthesizedExpression) {
        innerExpresion = (innerExpresion as ParenthesizedExpression).expression;
      }
      return _invertCondition0(innerExpresion);
    }
    DartType type = expression.bestType;
    if (type.displayName == "bool") {
      return _InvertedCondition._simple("!${getNodeText(expression)}");
    }
    return _InvertedCondition._simple(getNodeText(expression));
  }

  bool _selectionIncludesNonWhitespaceOutsideOperands(SourceRange selection,
      List<Expression> operands) {
    return _selectionIncludesNonWhitespaceOutsideRange(
        selection,
        rangeNodes(operands));
  }

  /**
   * @return <code>true</code> if "selection" covers "range" and there are any non-whitespace tokens
   *         between "selection" and "range" start/end.
   */
  bool _selectionIncludesNonWhitespaceOutsideRange(SourceRange selection,
      SourceRange range) {
    // selection should cover range
    if (!selection.covers(range)) {
      return false;
    }
    // non-whitespace between selection start and range start
    if (!isJustWhitespaceOrComment(rangeStartStart(selection, range))) {
      return true;
    }
    // non-whitespace after range
    if (!isJustWhitespaceOrComment(rangeEndEnd(range, selection))) {
      return true;
    }
    // only whitespace in selection around range
    return false;
  }

  /**
   * @return [Expression]s from <code>operands</code> which are completely covered by given
   *         [SourceRange]. Range should start and end between given [Expression]s.
   */
  static List<Expression> _getOperandsForSourceRange(List<Expression> operands,
      SourceRange range) {
    assert(!operands.isEmpty);
    List<Expression> subOperands = [];
    // track range enter/exit
    bool entered = false;
    bool exited = false;
    // may be range starts before or on first operand
    if (range.offset <= operands[0].offset) {
      entered = true;
    }
    // iterate over gaps between operands
    for (int i = 0; i < operands.length - 1; i++) {
      Expression operand = operands[i];
      Expression nextOperand = operands[i + 1];
      SourceRange inclusiveGap =
          rangeEndStart(operand, nextOperand).getMoveEnd(1);
      // add operand, if already entered range
      if (entered) {
        subOperands.add(operand);
        // may be last operand in range
        if (range.endsIn(inclusiveGap)) {
          exited = true;
        }
      } else {
        // may be first operand in range
        if (range.startsIn(inclusiveGap)) {
          entered = true;
        }
      }
    }
    // check if last operand is in range
    Expression lastGroupMember = operands[operands.length - 1];
    if (range.end == lastGroupMember.end) {
      subOperands.add(lastGroupMember);
      exited = true;
    }
    // we expect that range covers only given operands
    if (!exited) {
      return [];
    }
    // done
    return subOperands;
  }

  /**
   * @return all operands of the given [BinaryExpression] and its children with the same
   *         operator.
   */
  static List<Expression> _getOperandsInOrderFor(BinaryExpression groupRoot) {
    List<Expression> operands = [];
    TokenType groupOperatorType = groupRoot.operator.type;
    groupRoot.accept(new _OrderedOperandsVisitor(groupOperatorType, operands));
    return operands;
  }
}


/**
 * Describes where to insert new directive or top-level declaration.
 */
class CorrectionUtils_InsertDesc {
  int offset = 0;
  String prefix = "";
  String suffix = "";
}


/**
 * Utilities to work with [Token]s.
 */
class TokenUtils {
  /**
   * @return the first [KeywordToken] with given [Keyword], may be <code>null</code> if
   *         not found.
   */
  static KeywordToken findKeywordToken(List<Token> tokens, Keyword keyword) {
    for (Token token in tokens) {
      if (token is KeywordToken) {
        KeywordToken keywordToken = token;
        if (keywordToken.keyword == keyword) {
          return keywordToken;
        }
      }
    }
    return null;
  }

  /**
   * @return the first [Token] with given [TokenType], may be <code>null</code> if not
   *         found.
   */
  static Token findToken(List<Token> tokens, TokenType type) {
    for (Token token in tokens) {
      if (token.type == type) {
        return token;
      }
    }
    return null;
  }

  /**
   * @return [Token]s of the given Dart source, not <code>null</code>, may be empty if no
   *         tokens or some exception happens.
   */
  static List<Token> getTokens(String s) {
    try {
      List<Token> tokens = [];
      Scanner scanner = new Scanner(null, new CharSequenceReader(s), null);
      Token token = scanner.tokenize();
      while (token.type != TokenType.EOF) {
        tokens.add(token);
        token = token.next;
      }
      return tokens;
    } catch (e) {
      return [];
    }
  }

  /**
   * @return <code>true</code> if given [Token]s contain only single [Token] with given
   *         [TokenType].
   */
  static bool hasOnly(List<Token> tokens, TokenType type) =>
      tokens.length == 1 && tokens[0].type == type;
}


/**
 * A container with a source and its precedence.
 */
class _InvertedCondition {
  final int _precedence;

  final String _source;

  _InvertedCondition(this._precedence, this._source);

  static _InvertedCondition _binary(int precedence, _InvertedCondition left,
      String operation, _InvertedCondition right) {
    String src =
        _parenthesizeIfRequired(left, precedence) +
        operation +
        _parenthesizeIfRequired(right, precedence);
    return new _InvertedCondition(precedence, src);
  }

  static _InvertedCondition _binary2(_InvertedCondition left, String operation,
      _InvertedCondition right) {
    // TODO(scheglov) conside merging with "_binary()" after testing
    return new _InvertedCondition(
        1 << 20,
        "${left._source}${operation}${right._source}");
  }

  /**
   * Adds enclosing parenthesis if the precedence of the [_InvertedCondition] if less than the
   * precedence of the expression we are going it to use in.
   */
  static String _parenthesizeIfRequired(_InvertedCondition expr,
      int newOperatorPrecedence) {
    if (expr._precedence < newOperatorPrecedence) {
      return "(${expr._source})";
    }
    return expr._source;
  }

  static _InvertedCondition _simple(String source) =>
      new _InvertedCondition(2147483647, source);
}


class _OrderedOperandsVisitor extends GeneralizingAstVisitor {
  final TokenType groupOperatorType;
  final List<Expression> operands;

  _OrderedOperandsVisitor(this.groupOperatorType, this.operands);

  @override
  Object visitExpression(Expression node) {
    if (node is BinaryExpression && node.operator.type == groupOperatorType) {
      return super.visitNode(node);
    }
    operands.add(node);
    return null;
  }
}
