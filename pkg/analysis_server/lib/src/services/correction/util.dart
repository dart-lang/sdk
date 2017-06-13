// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:analysis_server/src/protocol_server.dart'
    show doSourceChange_addElementEdit;
import 'package:analysis_server/src/services/correction/strings.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceChange, SourceEdit;
import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';
import 'package:path/path.dart';

/**
 * Adds edits to the given [change] that ensure that all the [libraries] are
 * imported into the given [targetLibrary].
 */
void addLibraryImports(
    SourceChange change, LibraryElement targetLibrary, Set<Source> libraries) {
  CorrectionUtils libUtils;
  try {
    CompilationUnitElement unitElement = targetLibrary.definingCompilationUnit;
    CompilationUnit unitAst = getParsedUnit(unitElement);
    libUtils = new CorrectionUtils(unitAst);
  } catch (e) {
    throw new CancelCorrectionException(exception: e);
  }
  String eol = libUtils.endOfLine;
  // Prepare information about existing imports.
  LibraryDirective libraryDirective;
  List<_ImportDirectiveInfo> importDirectives = <_ImportDirectiveInfo>[];
  for (Directive directive in libUtils.unit.directives) {
    if (directive is LibraryDirective) {
      libraryDirective = directive;
    } else if (directive is ImportDirective) {
      importDirectives.add(new _ImportDirectiveInfo(
          directive.uriContent, directive.offset, directive.end));
    }
  }

  // Prepare all URIs to import.
  List<String> uriList = libraries
      .map((library) => getLibrarySourceUri(targetLibrary, library))
      .toList();
  uriList.sort((a, b) => a.compareTo(b));

  // Insert imports: between existing imports.
  if (importDirectives.isNotEmpty) {
    bool isFirstPackage = true;
    for (String importUri in uriList) {
      bool inserted = false;
      bool isPackage = importUri.startsWith('package:');
      bool isAfterDart = false;
      for (_ImportDirectiveInfo existingImport in importDirectives) {
        if (existingImport.uri.startsWith('dart:')) {
          isAfterDart = true;
        }
        if (existingImport.uri.startsWith('package:')) {
          isFirstPackage = false;
        }
        if (importUri.compareTo(existingImport.uri) < 0) {
          String importCode = "import '$importUri';$eol";
          doSourceChange_addElementEdit(change, targetLibrary,
              new SourceEdit(existingImport.offset, 0, importCode));
          inserted = true;
          break;
        }
      }
      if (!inserted) {
        String importCode = "${eol}import '$importUri';";
        if (isPackage && isFirstPackage && isAfterDart) {
          importCode = eol + importCode;
        }
        doSourceChange_addElementEdit(change, targetLibrary,
            new SourceEdit(importDirectives.last.end, 0, importCode));
      }
      if (isPackage) {
        isFirstPackage = false;
      }
    }
    return;
  }

  // Insert imports: after the library directive.
  if (libraryDirective != null) {
    String prefix = eol + eol;
    for (String importUri in uriList) {
      String importCode = "${prefix}import '$importUri';";
      prefix = eol;
      doSourceChange_addElementEdit(change, targetLibrary,
          new SourceEdit(libraryDirective.end, 0, importCode));
    }
    return;
  }

  // If still at the beginning of the file, skip shebang and line comments.
  {
    CorrectionUtils_InsertDesc desc = libUtils.getInsertDescTop();
    int offset = desc.offset;
    for (int i = 0; i < uriList.length; i++) {
      String importUri = uriList[i];
      String importCode = "import '$importUri';$eol";
      if (i == 0) {
        importCode = desc.prefix + importCode;
      }
      if (i == uriList.length - 1) {
        importCode = importCode + desc.suffix;
      }
      doSourceChange_addElementEdit(
          change, targetLibrary, new SourceEdit(offset, 0, importCode));
    }
  }
}

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
 * Climbs up [PrefixedIdentifier] and [PropertyAccess] nodes that include [node].
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
 * Returns the EOL to use for the given [code].
 */
String getCodeEndOfLine(String code) {
  if (code.contains('\r\n')) {
    return '\r\n';
  }
  return '\n';
}

/**
 * TODO(scheglov) replace with nodes once there will be [CompilationUnit.getComments].
 *
 * Returns [SourceRange]s of all comments in [unit].
 */
List<SourceRange> getCommentRanges(CompilationUnit unit) {
  List<SourceRange> ranges = <SourceRange>[];
  Token token = unit.beginToken;
  while (token != null && token.type != TokenType.EOF) {
    Token commentToken = token.precedingComments;
    while (commentToken != null) {
      ranges.add(range.token(commentToken));
      commentToken = commentToken.next;
    }
    token = token.next;
  }
  return ranges;
}

/**
 * Return the given [element] if it is a [CompilationUnitElement].
 * Return the enclosing [CompilationUnitElement] of the given [element],
 * maybe `null`.
 */
CompilationUnitElement getCompilationUnitElement(Element element) {
  if (element is CompilationUnitElement) {
    return element;
  }
  return element.getAncestor((e) => e is CompilationUnitElement);
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
  if (kind == ElementKind.CONSTRUCTOR ||
      kind == ElementKind.FIELD ||
      kind == ElementKind.METHOD) {
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
  if (parent is IndexExpression && parent.index == node) {
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
 * Computes the best URI to import [what] into [from].
 */
String getLibrarySourceUri(LibraryElement from, Source what) {
  String whatPath = what.fullName;
  // check if an absolute URI (such as 'dart:' or 'package:')
  Uri whatUri = what.uri;
  String whatUriScheme = whatUri.scheme;
  if (whatUriScheme != '' && whatUriScheme != 'file') {
    return whatUri.toString();
  }
  // compute a relative URI
  String fromFolder = dirname(from.source.fullName);
  String relativeFile = relative(whatPath, from: fromFolder);
  return split(relativeFile).join('/');
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
  for (; i < minLength; i++) {
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
  if (parent is MethodInvocation && identical(parent.methodName, node)) {
    return parent.target;
  }
  if (parent is PropertyAccess && identical(parent.propertyName, node)) {
    return parent.target;
  }
  if (parent is PrefixedIdentifier && identical(parent.identifier, node)) {
    return parent.prefix;
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
 * Returns a parsed [AstNode] for the given [classElement].
 *
 * The resulting AST structure may or may not be resolved.
 */
AstNode getParsedClassElementNode(ClassElement classElement) {
  CompilationUnitElement unitElement = getCompilationUnitElement(classElement);
  CompilationUnit unit = getParsedUnit(unitElement);
  int offset = classElement.nameOffset;
  AstNode classNameNode = new NodeLocator(offset).searchWithin(unit);
  if (classElement.isEnum) {
    return classNameNode.getAncestor((node) => node is EnumDeclaration);
  } else {
    return classNameNode.getAncestor(
        (node) => node is ClassDeclaration || node is ClassTypeAlias);
  }
}

/**
 * Returns a parsed [CompilationUnit] for the given [unitElement].
 *
 * The resulting AST structure may or may not be resolved.
 * If it is not resolved, then at least the given [unitElement] will be set.
 */
CompilationUnit getParsedUnit(CompilationUnitElement unitElement) {
  AnalysisContext context = unitElement.context;
  Source source = unitElement.source;
  CompilationUnit unit = context.parseCompilationUnit(source);
  if (unit.element == null) {
    unit.element = unitElement;
  }
  return unit;
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

/**
 * This exception is thrown to cancel the current correction operation,
 * such as quick assist or quick fix because an inconsistency was detected.
 * These inconsistencies may happen as a part of normal workflow, e.g. because
 * a resource was deleted, or an analysis result was invalidated.
 */
class CancelCorrectionException {
  final Object exception;
  CancelCorrectionException({this.exception});
}

/**
 * Describes the location for a newly created [ClassMember].
 */
class ClassMemberLocation {
  final String prefix;
  final int offset;
  final String suffix;

  ClassMemberLocation(this.prefix, this.offset, this.suffix);
}

class CorrectionUtils {
  final CompilationUnit unit;

  /**
   * The [ClassElement] the generated code is inserted to, so we can decide if
   * a type parameter may or may not be used.
   */
  ClassElement targetClassElement;

  ExecutableElement targetExecutableElement;

  LibraryElement _library;
  String _buffer;
  String _endOfLine;

  CorrectionUtils(this.unit) {
    CompilationUnitElement unitElement = unit.element;
    AnalysisContext context = unitElement.context;
    if (context == null) {
      throw new CancelCorrectionException();
    }
    this._library = unitElement.library;
    this._buffer = context.getContents(unitElement.source).data;
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
  SourceEdit createIndentEdit(
      SourceRange range, String oldIndent, String newIndent) {
    String newSource = replaceSourceRangeIndent(range, oldIndent, newIndent);
    return new SourceEdit(range.offset, range.length, newSource);
  }

  /**
   * Returns the [AstNode] that encloses the given offset.
   */
  AstNode findNode(int offset) => new NodeLocator(offset).searchWithin(unit);

  /**
   * Returns names of elements that might conflict with a new local variable
   * declared at [offset].
   */
  Set<String> findPossibleLocalVariableConflicts(int offset) {
    Set<String> conflicts = new Set<String>();
    AstNode enclosingNode = findNode(offset);
    Block enclosingBlock = enclosingNode.getAncestor((node) => node is Block);
    if (enclosingBlock != null) {
      _CollectReferencedUnprefixedNames visitor =
          new _CollectReferencedUnprefixedNames();
      enclosingBlock.accept(visitor);
      return visitor.names;
    }
    return conflicts;
  }

  /**
   * Returns the actual type source of the given [Expression], may be `null`
   * if can not be resolved, should be treated as the `dynamic` type.
   */
  String getExpressionTypeSource(
      Expression expression, Set<Source> librariesToImport) {
    if (expression == null) {
      return null;
    }
    DartType type = expression.bestType;
    if (type.isDynamic) {
      return null;
    }
    return getTypeSource(type, librariesToImport);
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
        result.prefix = "$eol$eol";
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
        result.prefix = "$eol$eol";
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
   * Returns a [SourceRange] that covers [sourceRange] and extends (if possible)
   * to cover whole lines.
   */
  SourceRange getLinesRange(SourceRange sourceRange,
      {bool skipLeadingEmptyLines: false}) {
    // start
    int startOffset = sourceRange.offset;
    int startLineOffset = getLineContentStart(startOffset);
    if (skipLeadingEmptyLines) {
      startLineOffset = skipEmptyLinesLeft(startLineOffset);
    }
    // end
    int endOffset = sourceRange.end;
    int afterEndLineOffset = getLineContentEnd(endOffset);
    // range
    return range.startOffsetEndOffset(startLineOffset, afterEndLineOffset);
  }

  /**
   * Returns a [SourceRange] that covers all the given [Statement]s.
   */
  SourceRange getLinesRangeStatements(List<Statement> statements) {
    return getLinesRange(range.nodes(statements));
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
  String getParameterSource(
      DartType type, String name, Set<Source> librariesToImport) {
    // no type
    if (type == null || type.isDynamic) {
      return name;
    }
    // function type
    if (type is FunctionType && type.element.isSynthetic) {
      FunctionType functionType = type;
      StringBuffer sb = new StringBuffer();
      // return type
      DartType returnType = functionType.returnType;
      if (returnType != null && !returnType.isDynamic) {
        String returnTypeSource = getTypeSource(returnType, librariesToImport);
        sb.write(returnTypeSource);
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
        sb.write(getParameterSource(
            fParameter.type, fParameter.name, librariesToImport));
      }
      sb.write(')');
      // done
      return sb.toString();
    }
    // simple type
    String typeSource = getTypeSource(type, librariesToImport);
    return '$typeSource $name';
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
   *
   * Fills [librariesToImport] with [LibraryElement]s whose elements are
   * used by the generated source, but not imported.
   */
  String getTypeSource(DartType type, Set<Source> librariesToImport,
      {StringBuffer parametersBuffer}) {
    StringBuffer sb = new StringBuffer();
    // type parameter
    if (!_isTypeVisible(type)) {
      return 'dynamic';
    }
    // just a Function, not FunctionTypeAliasElement
    if (type is FunctionType && type.element is! FunctionTypeAliasElement) {
      if (parametersBuffer == null) {
        return "Function";
      }
      parametersBuffer.write('(');
      for (ParameterElement parameter in type.parameters) {
        String parameterType = getTypeSource(parameter.type, librariesToImport);
        if (parametersBuffer.length != 1) {
          parametersBuffer.write(', ');
        }
        parametersBuffer.write(parameterType);
        parametersBuffer.write(' ');
        parametersBuffer.write(parameter.name);
      }
      parametersBuffer.write(')');
      return getTypeSource(type.returnType, librariesToImport);
    }
    // <Bottom>, Null
    if (type.isBottom || type.isDartCoreNull) {
      return 'dynamic';
    }
    // prepare element
    Element element = type.element;
    if (element == null) {
      String source = type.toString();
      source = source.replaceAll('<dynamic>', '');
      source = source.replaceAll('<dynamic, dynamic>', '');
      return source;
    }
    // check if imported
    LibraryElement library = element.library;
    if (library != null && library != _library) {
      // no source, if private
      if (element.isPrivate) {
        return null;
      }
      // ensure import
      ImportElement importElement = _getImportElement(element);
      if (importElement != null) {
        if (importElement.prefix != null) {
          sb.write(importElement.prefix.displayName);
          sb.write(".");
        }
      } else {
        librariesToImport.add(library.source);
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
      bool allArgumentsVisible = true;
      for (DartType argument in arguments) {
        hasArguments = hasArguments || !argument.isDynamic;
        allArgumentsVisible = allArgumentsVisible && _isTypeVisible(argument);
      }
      // append type arguments
      if (hasArguments && allArgumentsVisible) {
        sb.write("<");
        for (int i = 0; i < arguments.length; i++) {
          DartType argument = arguments[i];
          if (i != 0) {
            sb.write(", ");
          }
          String argumentSrc = getTypeSource(argument, librariesToImport);
          if (argumentSrc != null) {
            sb.write(argumentSrc);
          } else {
            return null;
          }
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
        line = "$indent$line";
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
   * Return `true` if the given [classDeclaration] has open '{' and close '}'
   * at the same line, e.g. `class X {}`.
   */
  bool isClassWithEmptyBody(ClassDeclaration classDeclaration) {
    return getLineThis(classDeclaration.leftBracket.offset) ==
        getLineThis(classDeclaration.rightBracket.offset);
  }

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

  ClassMemberLocation prepareNewClassMemberLocation(
      ClassDeclaration classDeclaration,
      bool shouldSkip(ClassMember existingMember)) {
    String indent = getIndent(1);
    // Find the last target member.
    ClassMember targetMember = null;
    List<ClassMember> members = classDeclaration.members;
    for (ClassMember member in members) {
      if (shouldSkip(member)) {
        targetMember = member;
      } else {
        break;
      }
    }
    // After the last target member.
    if (targetMember != null) {
      return new ClassMemberLocation(
          endOfLine + endOfLine + indent, targetMember.end, '');
    }
    // At the beginning of the class.
    String suffix = members.isNotEmpty || isClassWithEmptyBody(classDeclaration)
        ? endOfLine
        : '';
    return new ClassMemberLocation(
        endOfLine + indent, classDeclaration.leftBracket.end, suffix);
  }

  ClassMemberLocation prepareNewConstructorLocation(
      ClassDeclaration classDeclaration) {
    return prepareNewClassMemberLocation(
        classDeclaration,
        (member) =>
            member is FieldDeclaration || member is ConstructorDeclaration);
  }

  ClassMemberLocation prepareNewFieldLocation(
      ClassDeclaration classDeclaration) {
    return prepareNewClassMemberLocation(
        classDeclaration, (member) => member is FieldDeclaration);
  }

  ClassMemberLocation prepareNewGetterLocation(
      ClassDeclaration classDeclaration) {
    return prepareNewClassMemberLocation(
        classDeclaration,
        (member) =>
            member is FieldDeclaration ||
            member is ConstructorDeclaration ||
            member is MethodDeclaration && member.isGetter);
  }

  ClassMemberLocation prepareNewMethodLocation(
      ClassDeclaration classDeclaration) {
    return prepareNewClassMemberLocation(
        classDeclaration,
        (member) =>
            member is FieldDeclaration ||
            member is ConstructorDeclaration ||
            member is MethodDeclaration);
  }

  /**
   * Returns the source with indentation changed from [oldIndent] to
   * [newIndent], keeping indentation of lines relative to each other.
   */
  String replaceSourceIndent(
      String source, String oldIndent, String newIndent) {
    // prepare STRING token ranges
    List<SourceRange> lineRanges = [];
    {
      List<Token> tokens = TokenUtils.getTokens(source);
      for (Token token in tokens) {
        if (token.type == TokenType.STRING) {
          lineRanges.add(range.token(token));
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
        line = "$newIndent${removeStart(line, oldIndent)}";
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
  String replaceSourceRangeIndent(
      SourceRange range, String oldIndent, String newIndent) {
    String oldSource = getRangeText(range);
    return replaceSourceIndent(oldSource, oldIndent, newIndent);
  }

  /**
   * @return <code>true</code> if "selection" covers "node" and there are any non-whitespace tokens
   *         between "selection" and "node" start/end.
   */
  bool selectionIncludesNonWhitespaceOutsideNode(
      SourceRange selection, AstNode node) {
    return _selectionIncludesNonWhitespaceOutsideRange(
        selection, range.node(node));
  }

  /**
   * Skip spaces, tabs and EOLs on the left from [index].
   *
   * If [index] is the start of a method, then in the most cases return the end
   * of the previous not-whitespace line.
   */
  int skipEmptyLinesLeft(int index) {
    int lastLine = index;
    while (index > 0) {
      int c = _buffer.codeUnitAt(index - 1);
      if (!isWhitespace(c)) {
        return lastLine;
      }
      if (isEOL(c)) {
        lastLine = index;
      }
      index--;
    }
    return 0;
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
      if (expression.value) {
        return _InvertedCondition._simple("false");
      } else {
        return _InvertedCondition._simple("true");
      }
    } else if (expression is BinaryExpression) {
      TokenType operator = expression.operator.type;
      Expression le = expression.leftOperand;
      Expression re = expression.rightOperand;
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
            TokenType.BAR_BAR.precedence, ls, " || ", rs);
      }
      if (operator == TokenType.BAR_BAR) {
        return _InvertedCondition._binary(
            TokenType.AMPERSAND_AMPERSAND.precedence, ls, " && ", rs);
      }
    } else if (expression is IsExpression) {
      String expressionSource = getNodeText(expression.expression);
      String typeSource = getNodeText(expression.type);
      if (expression.notOperator == null) {
        return _InvertedCondition._simple("$expressionSource is! $typeSource");
      } else {
        return _InvertedCondition._simple("$expressionSource is $typeSource");
      }
    } else if (expression is PrefixExpression) {
      TokenType operator = expression.operator.type;
      if (operator == TokenType.BANG) {
        Expression operand = expression.operand.unParenthesized;
        return _InvertedCondition._simple(getNodeText(operand));
      }
    } else if (expression is ParenthesizedExpression) {
      return _invertCondition0(expression.unParenthesized);
    }
    DartType type = expression.bestType;
    if (type.displayName == "bool") {
      return _InvertedCondition._simple("!${getNodeText(expression)}");
    }
    return _InvertedCondition._simple(getNodeText(expression));
  }

  /**
   * Checks if [type] is visible in [targetExecutableElement] or
   * [targetClassElement].
   */
  bool _isTypeVisible(DartType type) {
    if (type is TypeParameterType) {
      TypeParameterElement parameterElement = type.element;
      Element parameterClassElement = parameterElement.enclosingElement;
      return identical(parameterClassElement, targetExecutableElement) ||
          identical(parameterClassElement, targetClassElement);
    }
    return true;
  }

  /**
   * @return <code>true</code> if "selection" covers "range" and there are any non-whitespace tokens
   *         between "selection" and "range" start/end.
   */
  bool _selectionIncludesNonWhitespaceOutsideRange(
      SourceRange selection, SourceRange sourceRange) {
    // selection should cover range
    if (!selection.covers(sourceRange)) {
      return false;
    }
    // non-whitespace between selection start and range start
    if (!isJustWhitespaceOrComment(
        range.startOffsetEndOffset(selection.offset, sourceRange.offset))) {
      return true;
    }
    // non-whitespace after range
    if (!isJustWhitespaceOrComment(
        range.startOffsetEndOffset(sourceRange.end, selection.end))) {
      return true;
    }
    // only whitespace in selection around range
    return false;
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
   * Return the first token in the list of [tokens] representing the given
   * [keyword], or `null` if there is no such token.
   */
  static Token findKeywordToken(List<Token> tokens, Keyword keyword) {
    for (Token token in tokens) {
      if (token.keyword == keyword) {
        return token;
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

class _CollectReferencedUnprefixedNames extends RecursiveAstVisitor {
  final Set<String> names = new Set<String>();

  void visitSimpleIdentifier(SimpleIdentifier node) {
    if (!_isPrefixed(node)) {
      names.add(node.name);
    }
  }

  static bool _isPrefixed(SimpleIdentifier node) {
    AstNode parent = node.parent;
    return parent is ConstructorName && parent.name == node ||
        parent is MethodInvocation &&
            parent.methodName == node &&
            parent.realTarget != null ||
        parent is PrefixedIdentifier && parent.identifier == node ||
        parent is PropertyAccess && parent.target == node;
  }
}

class _ImportDirectiveInfo {
  final String uri;
  final int offset;
  final int end;

  _ImportDirectiveInfo(this.uri, this.offset, this.end);
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
    String src = _parenthesizeIfRequired(left, precedence) +
        operation +
        _parenthesizeIfRequired(right, precedence);
    return new _InvertedCondition(precedence, src);
  }

  static _InvertedCondition _binary2(
      _InvertedCondition left, String operation, _InvertedCondition right) {
    // TODO(scheglov) consider merging with "_binary()" after testing
    return new _InvertedCondition(
        1 << 20, "${left._source}$operation${right._source}");
  }

  /**
   * Adds enclosing parenthesis if the precedence of the [_InvertedCondition] if less than the
   * precedence of the expression we are going it to use in.
   */
  static String _parenthesizeIfRequired(
      _InvertedCondition expr, int newOperatorPrecedence) {
    if (expr._precedence < newOperatorPrecedence) {
      return "(${expr._source})";
    }
    return expr._source;
  }

  static _InvertedCondition _simple(String source) =>
      new _InvertedCondition(2147483647, source);
}
