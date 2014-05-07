// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library services.util;

import 'dart:collection';
import 'package:analyzer/src/generated/java_core.dart' hide StringUtils;
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'change.dart';
import 'proposal.dart';
import 'status.dart';
import 'stubs.dart';

/**
 * Context for which assistance should be provided.
 */
class AssistContext {
  final SearchEngine searchEngine;

  final AnalysisContext analysisContext;

  final String analysisContextId;

  final Source source;

  final CompilationUnit compilationUnit;

  final int selectionOffset;

  final int selectionLength;

  AstNode _coveredNode;

  AstNode _coveringNode;

  Element _coveredElement;

  bool _coveredElementFound = false;

  AssistContext.con1(this.searchEngine, this.analysisContext, this.analysisContextId, this.source, this.compilationUnit, this.selectionOffset, this.selectionLength);

  AssistContext.con2(SearchEngine searchEngine, AnalysisContext analysisContext, String analysisContextId, Source source, CompilationUnit compilationUnit, SourceRange selectionRange) : this.con1(searchEngine, analysisContext, analysisContextId, source, compilationUnit, selectionRange.offset, selectionRange.length);

  /**
   * @return the resolved [CompilationUnitElement] of the [Source].
   */
  CompilationUnitElement get compilationUnitElement => compilationUnit.element;

  /**
   * @return the [Element] of the [coveredNode], may be <code>null</code>.
   */
  Element get coveredElement {
    if (!_coveredElementFound) {
      _coveredElementFound = true;
      AstNode coveredNode = this.coveredNode;
      if (coveredNode == null) {
        return null;
      }
      _coveredElement = ElementLocator.locateWithOffset(coveredNode, selectionOffset);
    }
    return _coveredElement;
  }

  /**
   * @return the [AstNode] that is covered by the selection.
   */
  AstNode get coveredNode {
    if (_coveredNode == null) {
      NodeLocator locator = new NodeLocator.con2(selectionOffset, selectionOffset);
      _coveredNode = locator.searchWithin(compilationUnit);
    }
    return _coveredNode;
  }

  /**
   * @return the ASTNode that covers the selection.
   */
  AstNode get coveringNode {
    if (_coveringNode == null) {
      NodeLocator locator = new NodeLocator.con2(selectionOffset, selectionOffset + selectionLength);
      _coveringNode = locator.searchWithin(compilationUnit);
    }
    return _coveringNode;
  }

  /**
   * @return the errors associated with the [Source].
   */
  List<AnalysisError> get errors {
    Source source = this.source;
    if (analysisContext == null || source == null) {
      return AnalysisError.NO_ERRORS;
    }
    return analysisContext.getErrors(source).errors;
  }

  /**
   * @return the [SourceRange] of the selection.
   */
  SourceRange get selectionRange => new SourceRange(selectionOffset, selectionLength);
}

/**
 * Utilities for analyzing [CompilationUnit], its parts and source.
 */
class CorrectionUtils {
  /**
   * If `true` then [addEdit] validates that
   * [Edit] replaces correct part of the [Source].
   */
  static bool _DEBUG_VALIDATE_EDITS = true;

  static List<String> _KNOWN_METHOD_NAME_PREFIXES = ["get", "is", "to"];

  /**
   * Validates that the [Edit] replaces the expected part of the [Source] and adds this
   * [Edit] to the [SourceChange].
   */
  static void addEdit(AnalysisContext context, SourceChange change, String description, String expected, Edit edit) {
    if (_DEBUG_VALIDATE_EDITS) {
      Source source = change.source;
      String sourceContent = getSourceContent(context, source);
      // prepare range
      int beginIndex = edit.offset;
      int endIndex = beginIndex + edit.length;
      int sourceLength = sourceContent.length;
      if (beginIndex >= sourceLength || endIndex >= sourceLength) {
        throw new IllegalStateException("${source} has ${sourceLength} characters but ${beginIndex} to ${endIndex} requested.\n\nTry to use Tools | Reanalyze Sources.");
      }
      // check that range has expected content
      String rangeContent = sourceContent.substring(beginIndex, endIndex);
      if (rangeContent != expected) {
        throw new IllegalStateException("${source} expected |${expected}| at ${beginIndex} to ${endIndex} but |${rangeContent}| found.\n\nTry to use Tools | Reanalyze Sources.");
      }
    }
    // do add the Edit
    change.addEdit(edit, description);
  }

  /**
   * @return <code>true</code> if given [List]s are equals at given position.
   */
  static bool allListsEqual(List<List> lists, int position) {
    Object element = lists[0][position];
    for (List list in lists) {
      if (!identical(list[position], element)) {
        return false;
      }
    }
    return true;
  }

  /**
   * @return the updated [String] with applied [Edit]s.
   */
  static String applyReplaceEdits(String s, List<Edit> edits) {
    // sort edits
    edits = [];
    edits.sort((Edit o1, Edit o2) => o1.offset - o2.offset);
    // apply edits
    int delta = 0;
    for (Edit edit in edits) {
      int editOffset = edit.offset + delta;
      String beforeEdit = s.substring(0, editOffset);
      String afterEdit = s.substring(editOffset + edit.length);
      s = "${beforeEdit}${edit.replacement}${afterEdit}";
      delta += getDeltaOffset(edit);
    }
    // done
    return s;
  }

  /**
   * @return <code>true</code> if given [SourceRange] covers given [AstNode].
   */
  static bool covers(SourceRange r, AstNode node) {
    SourceRange nodeRange = SourceRangeFactory.rangeNode(node);
    return r.covers(nodeRange);
  }

  /**
   * @return all direct children of the given [Element].
   */
  static List<Element> getChildren(Element parent) => getChildren2(parent, null);

  /**
   * @param name the required name of children; may be <code>null</code> to get children with any
   *          name.
   * @return all direct children of the given [Element], with given name.
   */
  static List<Element> getChildren2(Element parent, String name) {
    List<Element> children = [];
    parent.accept(new GeneralizingElementVisitor_CorrectionUtils_getChildren(parent, name, children));
    return children;
  }

  static String getDefaultValueCode(DartType type) {
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
   * @return the number of characters this [Edit] will move offsets after its range.
   */
  static int getDeltaOffset(Edit edit) => edit.replacement.length - edit.length;

  /**
   * @return the name of the [Element] kind.
   */
  static String getElementKindName(Element element) {
    ElementKind kind = element.kind;
    return getElementKindName2(kind);
  }

  /**
   * @return the display name of the [ElementKind].
   */
  static String getElementKindName2(ElementKind kind) => kind.displayName;

  /**
   * @return the human name of the [Element].
   */
  static String getElementQualifiedName(Element element) {
    ElementKind kind = element.kind;
    while (true) {
      if (kind == ElementKind.FIELD || kind == ElementKind.METHOD) {
        return "${element.enclosingElement.displayName}.${element.displayName}";
      } else {
        return element.displayName;
      }
      break;
    }
  }

  /**
   * @return the [ExecutableElement] of the enclosing executable [AstNode].
   */
  static ExecutableElement getEnclosingExecutableElement(AstNode node) {
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
  static AstNode getEnclosingExecutableNode(AstNode node) {
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
   * @return [Element] exported from the given [LibraryElement].
   */
  static Element getExportedElement(LibraryElement library, String name) {
    if (library == null) {
      return null;
    }
    return getExportNamespace2(library)[name];
  }

  /**
   * TODO(scheglov) may be replace with some API for this
   *
   * @return the namespace of the given [ExportElement].
   */
  static Map<String, Element> getExportNamespace(ExportElement exp) {
    Namespace namespace = new NamespaceBuilder().createExportNamespaceForDirective(exp);
    return namespace.definedNames;
  }

  /**
   * TODO(scheglov) may be replace with some API for this
   *
   * @return the export namespace of the given [LibraryElement].
   */
  static Map<String, Element> getExportNamespace2(LibraryElement library) {
    Namespace namespace = new NamespaceBuilder().createExportNamespaceForLibrary(library);
    return namespace.definedNames;
  }

  /**
   * @return [getExpressionPrecedence] for parent node, or `0` if parent node
   *         is [ParenthesizedExpression]. The reason is that `(expr)` is always
   *         executed after `expr`.
   */
  static int getExpressionParentPrecedence(AstNode node) {
    AstNode parent = node.parent;
    if (parent is ParenthesizedExpression) {
      return 0;
    }
    return getExpressionPrecedence(parent);
  }

  /**
   * @return the precedence of the given node - result of [Expression#getPrecedence] if an
   *         [Expression], negative otherwise.
   */
  static int getExpressionPrecedence(AstNode node) {
    if (node is Expression) {
      return node.precedence;
    }
    return -1000;
  }

  /**
   * TODO(scheglov) may be replace with some API for this
   *
   * @return the namespace of the given [ImportElement].
   */
  static Map<String, Element> getImportNamespace(ImportElement imp) {
    Namespace namespace = new NamespaceBuilder().createImportNamespaceForDirective(imp);
    return namespace.definedNames;
  }

  /**
   * @return all [CompilationUnitElement] the given [LibraryElement] consists of.
   */
  static List<CompilationUnitElement> getLibraryUnits(LibraryElement library) {
    List<CompilationUnitElement> units = [];
    units.add(library.definingCompilationUnit);
    units.addAll(library.parts);
    return units;
  }

  /**
   * @return the line prefix from the given source, i.e. basically just whitespace prefix of the
   *         given [String].
   */
  static String getLinesPrefix(String lines) {
    int index = 0;
    while (index < lines.length) {
      int c = lines.codeUnitAt(index);
      if (!Character.isWhitespace(c)) {
        break;
      }
      index++;
    }
    return lines.substring(0, index);
  }

  /**
   * @return the [LocalVariableElement] or [ParameterElement] if given
   *         [SimpleIdentifier] is the reference to local variable or parameter, or
   *         <code>null</code> in the other case.
   */
  static VariableElement getLocalOrParameterVariableElement(SimpleIdentifier node) {
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
  static LocalVariableElement getLocalVariableElement(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is LocalVariableElement) {
      return element;
    }
    return null;
  }

  /**
   * @return the nearest common ancestor [AstNode] of the given [AstNode]s.
   */
  static AstNode getNearestCommonAncestor(List<AstNode> nodes) {
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
    int minLength = 2147483647;
    for (List<AstNode> parentList in parents) {
      minLength = Math.min(minLength, parentList.length);
    }
    // find deepest parent
    int i = 0;
    for (; i < minLength; i++) {
      if (!allListsEqual(parents, i)) {
        break;
      }
    }
    return parents[0][i - 1];
  }

  /**
   * @return the [Expression] qualified if given node is name part of a [PropertyAccess]
   *         or [PrefixedIdentifier]. May be <code>null</code>.
   */
  static Expression getNodeQualifier(SimpleIdentifier node) {
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
   * @return the [ParameterElement] if given [SimpleIdentifier] is the reference to
   *         parameter, or <code>null</code> in the other case.
   */
  static ParameterElement getParameterElement(SimpleIdentifier node) {
    Element element = node.staticElement;
    if (element is ParameterElement) {
      return element;
    }
    return null;
  }

  /**
   * @return the precedence of the given [Expression] parent. May be `-1` no operator.
   * @see #getPrecedence(Expression)
   */
  static int getParentPrecedence(Expression expression) {
    AstNode parent = expression.parent;
    if (parent is Expression) {
      return getPrecedence(parent);
    }
    return -1;
  }

  /**
   * @return parent [AstNode]s from [CompilationUnit] (at index "0") to the given one.
   */
  static List<AstNode> getParents(AstNode node) {
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
    return JavaArrays.asList(parents);
  }

  /**
   * @return the precedence of the given [Expression] operator. May be
   *         `Integer#MAX_VALUE` if not an operator.
   */
  static int getPrecedence(Expression expression) {
    if (expression is BinaryExpression) {
      BinaryExpression binaryExpression = expression;
      return binaryExpression.operator.type.precedence;
    }
    if (expression is PrefixExpression) {
      PrefixExpression prefixExpression = expression;
      return prefixExpression.operator.type.precedence;
    }
    if (expression is PostfixExpression) {
      PostfixExpression postfixExpression = expression;
      return postfixExpression.operator.type.precedence;
    }
    return 2147483647;
  }

  /**
   * @return the [PropertyAccessorElement] if given [SimpleIdentifier] is the reference
   *         to property, or <code>null</code> in the other case.
   */
  static PropertyAccessorElement getPropertyAccessorElement(SimpleIdentifier node) {
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
  static Expression getQualifiedPropertyTarget(AstNode node) {
    AstNode parent = node.parent;
    if (parent is PrefixedIdentifier) {
      PrefixedIdentifier prefixed = parent;
      if (identical(prefixed.identifier, node)) {
        return parent.prefix;
      }
    }
    if (parent is PropertyAccess) {
      PropertyAccess access = parent;
      if (identical(access.propertyName, node)) {
        return access.realTarget;
      }
    }
    return null;
  }

  /**
   * Returns the name of the file which corresponds to the name of the class according to the style
   * guide. However class does not have to be in this file.
   */
  static String getRecommentedFileNameForClass(String className) {
    int len = className.length;
    JavaStringBuilder sb = new JavaStringBuilder();
    bool prevWasUpper = false;
    for (int i = 0; i < len; i++) {
      int c = className.codeUnitAt(i);
      if (Character.isUpperCase(c)) {
        bool nextIsUpper = i < len - 1 && Character.isUpperCase(className.codeUnitAt(i + 1));
        if (i == 0) {
        } else if (prevWasUpper) {
          // HTTPServer
          //     ^
          if (!nextIsUpper) {
            sb.appendChar(0x5F);
          }
        } else {
          // HttpServer
          //     ^
          sb.appendChar(0x5F);
        }
        prevWasUpper = true;
        c = Character.toLowerCase(c);
      } else {
        prevWasUpper = false;
      }
      sb.appendChar(c);
    }
    sb.append(".dart");
    String fileName = sb.toString();
    return fileName;
  }

  /**
   * @return given [Statement] if not [Block], first child [Statement] if
   *         [Block], or <code>null</code> if more than one child.
   */
  static Statement getSingleStatement(Statement statement) {
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
   * @return the [String] content of the given [Source].
   */
  static String getSourceContent(AnalysisContext context, Source source) => context.getContents(source).data.toString();

  /**
   * @return given [Statement] if not [Block], all children [Statement]s if
   *         [Block].
   */
  static List<Statement> getStatements(Statement statement) {
    if (statement is Block) {
      return statement.statements;
    }
    return [];
  }

  /**
   * @return all top-level elements declared in the given [LibraryElement].
   */
  static List<Element> getTopLevelElements(LibraryElement library) {
    List<Element> elements = [];
    List<CompilationUnitElement> units = getLibraryUnits(library);
    for (CompilationUnitElement unit in units) {
      elements.addAll(unit.functions);
      elements.addAll(unit.functionTypeAliases);
      elements.addAll(unit.types);
      elements.addAll(unit.topLevelVariables);
    }
    return elements;
  }

  /**
   * @return the possible names for variable with initializer of the given [StringLiteral].
   */
  static List<String> getVariableNameSuggestions(String text, Set<String> excluded) {
    // filter out everything except of letters and white spaces
    {
      JavaStringBuilder sb = new JavaStringBuilder();
      for (int i = 0; i < text.length; i++) {
        int c = text.codeUnitAt(i);
        if (Character.isLetter(c) || Character.isWhitespace(c)) {
          sb.appendChar(c);
        }
      }
      text = sb.toString();
    }
    // make single camel-case text
    {
      List<String> words = StringUtils.split(text);
      JavaStringBuilder sb = new JavaStringBuilder();
      for (int i = 0; i < words.length; i++) {
        String word = words[i];
        if (i > 0) {
          word = StringUtils.capitalize(word);
        }
        sb.append(word);
      }
      text = sb.toString();
    }
    // split camel-case into separate suggested names
    Set<String> res = new LinkedHashSet();
    _addAll(excluded, res, _getVariableNameSuggestions(text));
    return new List.from(res);
  }

  /**
   * @return the possible names for variable with given expected type and expression.
   */
  static List<String> getVariableNameSuggestions2(DartType expectedType, Expression assignedExpression, Set<String> excluded) {
    Set<String> res = new LinkedHashSet();
    // use expression
    if (assignedExpression != null) {
      String nameFromExpression = _getBaseNameFromExpression(assignedExpression);
      if (nameFromExpression != null) {
        nameFromExpression = StringUtils.removeStart(nameFromExpression, "_");
        _addAll(excluded, res, _getVariableNameSuggestions(nameFromExpression));
      }
      String nameFromParent = _getBaseNameFromLocationInParent(assignedExpression);
      if (nameFromParent != null) {
        _addAll(excluded, res, _getVariableNameSuggestions(nameFromParent));
      }
    }
    // use type
    if (expectedType != null && !expectedType.isDynamic) {
      String typeName = expectedType.name;
      if ("int" == typeName) {
        _addSingleCharacterName(excluded, res, 0x69);
      } else if ("double" == typeName) {
        _addSingleCharacterName(excluded, res, 0x64);
      } else if ("String" == typeName) {
        _addSingleCharacterName(excluded, res, 0x73);
      } else {
        _addAll(excluded, res, _getVariableNameSuggestions(typeName));
      }
      res.remove(typeName);
    }
    // done
    return new List.from(res);
  }

  /**
   * @return `true` if the given [Element#getDisplayName] equals to the given name.
   */
  static bool hasDisplayName(Element element, String name) {
    if (element == null) {
      return false;
    }
    String elementDisplayName = element.displayName;
    return StringUtils.equals(elementDisplayName, name);
  }

  /**
   * @return `true` if the given [Element#getName] equals to the given name.
   */
  static bool hasName(Element element, String name) {
    if (element == null) {
      return false;
    }
    String elementName = element.name;
    return StringUtils.equals(elementName, name);
  }

  /**
   * @return `true` if the given [SimpleIdentifier] is the name of the
   *         [NamedExpression].
   */
  static bool isNamedExpressionName(SimpleIdentifier node) {
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
   * Adds "toAdd" items which are not excluded.
   */
  static void _addAll(Set<String> excluded, Set<String> result, Iterable<String> toAdd) {
    for (String item in toAdd) {
      // add name based on "item", but not "excluded"
      for (int suffix = 1;; suffix++) {
        // prepare name, just "item" or "item2", "item3", etc
        String name = item;
        if (suffix > 1) {
          name += suffix.toString();
        }
        // add once found not excluded
        if (!excluded.contains(name)) {
          result.add(name);
          break;
        }
      }
    }
  }

  /**
   * Add to "result" then given "c" or the first ASCII character after it.
   */
  static void _addSingleCharacterName(Set<String> excluded, Set<String> result, int c) {
    while (c < 0x7A) {
      String name = new String.fromCharCode(c);
      // may be done
      if (!excluded.contains(name)) {
        result.add(name);
        break;
      }
      // next character
      c = (c + 1);
    }
  }

  static String _getBaseNameFromExpression(Expression expression) {
    String name = null;
    // e as Type
    if (expression is AsExpression) {
      AsExpression asExpression = expression as AsExpression;
      expression = asExpression.expression;
    }
    // analyze expressions
    if (expression is SimpleIdentifier) {
      SimpleIdentifier node = expression;
      return node.name;
    } else if (expression is PrefixedIdentifier) {
      PrefixedIdentifier node = expression;
      return node.identifier.name;
    } else if (expression is MethodInvocation) {
      name = expression.methodName.name;
    } else if (expression is InstanceCreationExpression) {
      InstanceCreationExpression creation = expression;
      ConstructorName constructorName = creation.constructorName;
      TypeName typeName = constructorName.type;
      if (typeName != null) {
        Identifier typeNameIdentifier = typeName.name;
        // new ClassName()
        if (typeNameIdentifier is SimpleIdentifier) {
          return typeNameIdentifier.name;
        }
        // new prefix.name();
        if (typeNameIdentifier is PrefixedIdentifier) {
          PrefixedIdentifier prefixed = typeNameIdentifier;
          // new prefix.ClassName()
          if (prefixed.prefix.staticElement is PrefixElement) {
            return prefixed.identifier.name;
          }
          // new ClassName.constructorName()
          return prefixed.prefix.name;
        }
      }
    }
    // strip known prefixes
    if (name != null) {
      for (int i = 0; i < _KNOWN_METHOD_NAME_PREFIXES.length; i++) {
        String curr = _KNOWN_METHOD_NAME_PREFIXES[i];
        if (name.startsWith(curr)) {
          if (name == curr) {
            return null;
          } else if (Character.isUpperCase(name.codeUnitAt(curr.length))) {
            return name.substring(curr.length);
          }
        }
      }
    }
    // done
    return name;
  }

  static String _getBaseNameFromLocationInParent(Expression expression) {
    // value in named expression
    if (expression.parent is NamedExpression) {
      NamedExpression namedExpression = expression.parent as NamedExpression;
      if (identical(namedExpression.expression, expression)) {
        return namedExpression.name.label.name;
      }
    }
    // positional argument
    {
      ParameterElement parameter = expression.propagatedParameterElement;
      if (parameter == null) {
        parameter = expression.staticParameterElement;
      }
      if (parameter != null) {
        return parameter.displayName;
      }
    }
    // unknown
    return null;
  }

  /**
   * @return [Expression]s from <code>operands</code> which are completely covered by given
   *         [SourceRange]. Range should start and end between given [Expression]s.
   */
  static List<Expression> _getOperandsForSourceRange(List<Expression> operands, SourceRange range) {
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
      SourceRange inclusiveGap = SourceRangeFactory.rangeEndStart(operand, nextOperand).getMoveEnd(1);
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
    groupRoot.accept(new GeneralizingAstVisitor_CorrectionUtils_getOperandsInOrderFor(groupOperatorType, operands));
    return operands;
  }

  /**
   * @return all variants of names by removing leading words by one.
   */
  static List<String> _getVariableNameSuggestions(String name) {
    List<String> result = [];
    List<String> parts = name.split("(?<!(^|[A-Z]))(?=[A-Z])|(?<!^)(?=[A-Z][a-z])");
    for (int i = 0; i < parts.length; i++) {
      String suggestion = "${parts[i].toLowerCase()}${StringUtils.join(parts, "", i + 1, parts.length)}";
      result.add(suggestion);
    }
    return result;
  }

  /**
   * Adds enclosing parenthesis if the precedence of the [InvertedCondition] if less than the
   * precedence of the expression we are going it to use in.
   */
  static String _parenthesizeIfRequired(CorrectionUtils_InvertedCondition expr, int newOperatorPrecedence) {
    if (expr._precedence < newOperatorPrecedence) {
      return "(${expr._source})";
    }
    return expr._source;
  }

  final CompilationUnit unit;

  LibraryElement _library;

  String _buffer;

  String _endOfLine;

  CorrectionUtils(this.unit) {
    CompilationUnitElement element = unit.element;
    this._library = element.library;
    this._buffer = getSourceContent(element.context, element.source);
  }

  /**
   * @return the source of the given [SourceRange] with indentation changed from "oldIndent"
   *         to "newIndent", keeping indentation of the lines relative to each other.
   */
  Edit createIndentEdit(SourceRange range, String oldIndent, String newIndent) {
    String newSource = getIndentSource(range, oldIndent, newIndent);
    return new Edit(range.offset, range.length, newSource);
  }

  /**
   * @return the [AstNode] that encloses the given offset.
   */
  AstNode findNode(int offset) => new NodeLocator.con1(offset).searchWithin(unit);

  /**
   * TODO(scheglov) replace with nodes once there will be [CompilationUnit#getComments].
   *
   * @return the [SourceRange]s of all comments in [CompilationUnit].
   */
  List<SourceRange> get commentRanges {
    List<SourceRange> ranges = [];
    Token token = unit.beginToken;
    while (token != null && token.type != TokenType.EOF) {
      Token commentToken = token.precedingComments;
      while (commentToken != null) {
        ranges.add(SourceRangeFactory.rangeToken(commentToken));
        commentToken = commentToken.next;
      }
      token = token.next;
    }
    return ranges;
  }

  /**
   * @return the EOL to use for this [CompilationUnit].
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
   * @return the default indentation with given level.
   */
  String getIndent(int level) => StringUtils.repeat("  ", level);

  /**
   * @return the source of the given [SourceRange] with indentation changed from "oldIndent"
   *         to "newIndent", keeping indentation of the lines relative to each other.
   */
  String getIndentSource(SourceRange range, String oldIndent, String newIndent) {
    String oldSource = getText3(range);
    return getIndentSource3(oldSource, oldIndent, newIndent);
  }

  /**
   * Indents given source left or right.
   *
   * @return the source with changed indentation.
   */
  String getIndentSource2(String source, bool right) {
    JavaStringBuilder sb = new JavaStringBuilder();
    String indent = getIndent(1);
    String eol = endOfLine;
    List<String> lines = StringUtils.splitByWholeSeparatorPreserveAllTokens(source, eol);
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      // last line, stop if empty
      if (i == lines.length - 1 && StringUtils.isEmpty(line)) {
        break;
      }
      // update line
      if (right) {
        line = "${indent}${line}";
      } else {
        line = StringUtils.removeStart(line, indent);
      }
      // append line
      sb.append(line);
      sb.append(eol);
    }
    return sb.toString();
  }

  /**
   * @return the source with indentation changed from "oldIndent" to "newIndent", keeping
   *         indentation of the lines relative to each other.
   */
  String getIndentSource3(String source, String oldIndent, String newIndent) {
    // prepare STRING token ranges
    List<SourceRange> lineRanges = [];
    for (Token token in TokenUtils.getTokens(source)) {
      if (token.type == TokenType.STRING) {
        lineRanges.add(SourceRangeFactory.rangeToken(token));
      }
    }
    // re-indent lines
    JavaStringBuilder sb = new JavaStringBuilder();
    String eol = endOfLine;
    List<String> lines = StringUtils.splitByWholeSeparatorPreserveAllTokens(source, eol);
    int lineOffset = 0;
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      // last line, stop if empty
      if (i == lines.length - 1 && StringUtils.isEmpty(line)) {
        break;
      }
      // check if "offset" is in one of the String ranges
      bool inString = false;
      for (SourceRange lineRange in lineRanges) {
        inString = javaBooleanOr(inString, lineOffset > lineRange.offset && lineOffset < lineRange.end);
        if (lineOffset > lineRange.end) {
          break;
        }
      }
      lineOffset += line.length + eol.length;
      // update line indent
      if (!inString) {
        line = "${newIndent}${StringUtils.removeStart(line, oldIndent)}";
      }
      // append line
      sb.append(line);
      sb.append(eol);
    }
    return sb.toString();
  }

  /**
   * @return [InsertDesc], description where to insert new library-related directive.
   */
  CorrectionUtils_InsertDesc get insertDescImport {
    // analyze directives
    Directive prevDirective = null;
    for (Directive directive in unit.directives) {
      if (directive is LibraryDirective || directive is ImportDirective || directive is ExportDirective) {
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
    return insertDescTop;
  }

  /**
   * @return [InsertDesc], description where to insert new 'part 'directive.
   */
  CorrectionUtils_InsertDesc get insertDescPart {
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
    return insertDescTop;
  }

  /**
   * @return [InsertDesc], description where to insert new directive or top-level declaration
   *         at the top of file.
   */
  CorrectionUtils_InsertDesc get insertDescTop {
    // skip leading line comments
    int offset = 0;
    bool insertEmptyLineBefore = false;
    bool insertEmptyLineAfter = false;
    String source = text;
    // skip hash-bang
    if (offset < source.length - 2) {
      String linePrefix = getText2(offset, 2);
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
      String linePrefix = getText2(offset, 2);
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
   * Skips whitespace characters and single EOL on the right from the given position. If from
   * statement or method end, then this is in the most cases start of the next line.
   */
  int getLineContentEnd(int index) {
    int length = _buffer.length;
    // skip whitespace characters
    while (index < length) {
      int c = _buffer.codeUnitAt(index);
      if (!Character.isWhitespace(c) || c == 0xD || c == 0xA) {
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
   * @return the index of the last space or tab on the left from the given one, if from statement or
   *         method start, then this is in most cases start of the line.
   */
  int getLineContentStart(int index) {
    while (index > 0) {
      int c = _buffer.codeUnitAt(index - 1);
      if (c != 0x20 && c != 0x9) {
        break;
      }
      index--;
    }
    return index;
  }

  /**
   * @return the start index of the next line after the line which contains given index.
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
   * @return the whitespace prefix of the line which contains given offset.
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
      if (!Character.isWhitespace(c)) {
        break;
      }
      lineNonWhitespace++;
    }
    return getText2(lineStart, lineNonWhitespace - lineStart);
  }

  /**
   * @return the [getLinesRange] for given [Statement]s.
   */
  SourceRange getLinesRange(List<Statement> statements) {
    SourceRange range = SourceRangeFactory.rangeNodes(statements);
    return getLinesRange2(range);
  }

  /**
   * @return the [SourceRange] which starts at the start of the line of "offset" and ends at
   *         the start of the next line after "end" of the given [SourceRange], i.e. basically
   *         complete lines of the source for given [SourceRange].
   */
  SourceRange getLinesRange2(SourceRange range) {
    // start
    int startOffset = range.offset;
    int startLineOffset = getLineContentStart(startOffset);
    // end
    int endOffset = range.end;
    int afterEndLineOffset = getLineContentEnd(endOffset);
    // range
    return SourceRangeFactory.rangeStartEnd(startLineOffset, afterEndLineOffset);
  }

  /**
   * @return the [getLinesRange] for given [Statement]s.
   */
  SourceRange getLinesRange3(List<Statement> statements) => getLinesRange([]);

  /**
   * @return the start index of the line which contains given index.
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
   * @return the line prefix consisting of spaces and tabs on the left from the given
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
   * @return the index of the first non-whitespace character after given index.
   */
  int getNonWhitespaceForward(int index) {
    int length = _buffer.length;
    // skip whitespace characters
    while (index < length) {
      int c = _buffer.codeUnitAt(index);
      if (!Character.isWhitespace(c)) {
        break;
      }
      index++;
    }
    // done
    return index;
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
      JavaStringBuilder sb = new JavaStringBuilder();
      // return type
      DartType returnType = functionType.returnType;
      if (returnType != null && !returnType.isDynamic) {
        sb.append(getTypeSource2(returnType));
        sb.appendChar(0x20);
      }
      // parameter name
      sb.append(name);
      // parameters
      sb.appendChar(0x28);
      List<ParameterElement> fParameters = functionType.parameters;
      for (int i = 0; i < fParameters.length; i++) {
        ParameterElement fParameter = fParameters[i];
        if (i != 0) {
          sb.append(", ");
        }
        sb.append(getParameterSource(fParameter.type, fParameter.name));
      }
      sb.appendChar(0x29);
      // done
      return sb.toString();
    }
    // simple type
    return "${getTypeSource2(type)} ${name}";
  }

  /**
   * @return the line prefix consisting of spaces and tabs on the left from the given offset.
   */
  String getPrefix(int endIndex) {
    int startIndex = getLineContentStart(endIndex);
    return _buffer.substring(startIndex, endIndex);
  }

  /**
   * @return the full text of unit.
   */
  String get text => _buffer;

  /**
   * @return the given range of text from unit.
   */
  String getText(AstNode node) => getText2(node.offset, node.length);

  /**
   * @return the given range of text from unit.
   */
  String getText2(int offset, int length) => _buffer.substring(offset, offset + length);

  /**
   * @return the given range of text from unit.
   */
  String getText3(SourceRange range) => getText2(range.offset, range.length);

  /**
   * @return the actual type source of the given [Expression], may be `null` if can not
   *         be resolved, should be treated as <code>Dynamic</code>.
   */
  String getTypeSource(Expression expression) {
    if (expression == null) {
      return null;
    }
    DartType type = expression.bestType;
    String typeSource = getTypeSource2(type);
    if ("dynamic" == typeSource) {
      return null;
    }
    return typeSource;
  }

  /**
   * @return the source to reference the given [Type] in this [CompilationUnit].
   */
  String getTypeSource2(DartType type) {
    JavaStringBuilder sb = new JavaStringBuilder();
    // prepare element
    Element element = type.element;
    if (element == null) {
      String source = type.toString();
      source = StringUtils.remove(source, "<dynamic>");
      source = StringUtils.remove(source, "<dynamic, dynamic>");
      return source;
    }
    // append prefix
    {
      ImportElement imp = _getImportElement(element);
      if (imp != null && imp.prefix != null) {
        sb.append(imp.prefix.displayName);
        sb.append(".");
      }
    }
    // append simple name
    String name = element.displayName;
    sb.append(name);
    // may be type arguments
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      List<DartType> arguments = interfaceType.typeArguments;
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
        sb.append("<");
        for (int i = 0; i < arguments.length; i++) {
          DartType argument = arguments[i];
          if (i != 0) {
            sb.append(", ");
          }
          sb.append(getTypeSource2(argument));
        }
        sb.append(">");
      }
    }
    // done
    return sb.toString();
  }

  /**
   * @return the source of the inverted condition for the given logical expression.
   */
  String invertCondition(Expression expression) => _invertCondition0(expression)._source;

  /**
   * @return <code>true</code> if selection range contains only whitespace.
   */
  bool isJustWhitespace(SourceRange range) => getText3(range).trim().length == 0;

  /**
   * @return <code>true</code> if selection range contains only whitespace or comments
   */
  bool isJustWhitespaceOrComment(SourceRange range) {
    String trimmedText = getText3(range).trim();
    // may be whitespace
    if (trimmedText.isEmpty) {
      return true;
    }
    // may be comment
    return TokenUtils.getTokens(trimmedText).isEmpty;
  }

  /**
   * @return <code>true</code> if "selection" covers "node" and there are any non-whitespace tokens
   *         between "selection" and "node" start/end.
   */
  bool selectionIncludesNonWhitespaceOutsideNode(SourceRange selection, AstNode node) => _selectionIncludesNonWhitespaceOutsideRange(selection, SourceRangeFactory.rangeNode(node));

  /**
   * @return <code>true</code> if given range of [BinaryExpression] can be extracted.
   */
  bool validateBinaryExpressionRange(BinaryExpression binaryExpression, SourceRange range) {
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
  CorrectionUtils_InvertedCondition _invertCondition0(Expression expression) {
    if (expression is BooleanLiteral) {
      BooleanLiteral literal = expression;
      if (literal.value) {
        return CorrectionUtils_InvertedCondition._simple("false");
      } else {
        return CorrectionUtils_InvertedCondition._simple("true");
      }
    }
    if (expression is BinaryExpression) {
      BinaryExpression binary = expression;
      TokenType operator = binary.operator.type;
      Expression le = binary.leftOperand;
      Expression re = binary.rightOperand;
      CorrectionUtils_InvertedCondition ls = _invertCondition0(le);
      CorrectionUtils_InvertedCondition rs = _invertCondition0(re);
      if (operator == TokenType.LT) {
        return CorrectionUtils_InvertedCondition._binary2(ls, " >= ", rs);
      }
      if (operator == TokenType.GT) {
        return CorrectionUtils_InvertedCondition._binary2(ls, " <= ", rs);
      }
      if (operator == TokenType.LT_EQ) {
        return CorrectionUtils_InvertedCondition._binary2(ls, " > ", rs);
      }
      if (operator == TokenType.GT_EQ) {
        return CorrectionUtils_InvertedCondition._binary2(ls, " < ", rs);
      }
      if (operator == TokenType.EQ_EQ) {
        return CorrectionUtils_InvertedCondition._binary2(ls, " != ", rs);
      }
      if (operator == TokenType.BANG_EQ) {
        return CorrectionUtils_InvertedCondition._binary2(ls, " == ", rs);
      }
      if (operator == TokenType.AMPERSAND_AMPERSAND) {
        int newPrecedence = TokenType.BAR_BAR.precedence;
        return CorrectionUtils_InvertedCondition._binary(newPrecedence, ls, " || ", rs);
      }
      if (operator == TokenType.BAR_BAR) {
        int newPrecedence = TokenType.AMPERSAND_AMPERSAND.precedence;
        return CorrectionUtils_InvertedCondition._binary(newPrecedence, ls, " && ", rs);
      }
    }
    if (expression is IsExpression) {
      IsExpression isExpression = expression;
      String expressionSource = getText(isExpression.expression);
      String typeSource = getText(isExpression.type);
      if (isExpression.notOperator == null) {
        return CorrectionUtils_InvertedCondition._simple("${expressionSource} is! ${typeSource}");
      } else {
        return CorrectionUtils_InvertedCondition._simple("${expressionSource} is ${typeSource}");
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
        return CorrectionUtils_InvertedCondition._simple(getText(operand));
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
      return CorrectionUtils_InvertedCondition._simple("!${getText(expression)}");
    }
    return CorrectionUtils_InvertedCondition._simple(getText(expression));
  }

  bool _selectionIncludesNonWhitespaceOutsideOperands(SourceRange selection, List<Expression> operands) => _selectionIncludesNonWhitespaceOutsideRange(selection, SourceRangeFactory.rangeNodes(operands));

  /**
   * @return <code>true</code> if "selection" covers "range" and there are any non-whitespace tokens
   *         between "selection" and "range" start/end.
   */
  bool _selectionIncludesNonWhitespaceOutsideRange(SourceRange selection, SourceRange range) {
    // selection should cover range
    if (!selection.covers(range)) {
      return false;
    }
    // non-whitespace between selection start and range start
    if (!isJustWhitespaceOrComment(SourceRangeFactory.rangeStartStart(selection, range))) {
      return true;
    }
    // non-whitespace after range
    if (!isJustWhitespaceOrComment(SourceRangeFactory.rangeEndEnd(range, selection))) {
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
 * This class is used to hold the source and also its precedence during inverting logical
 * expressions.
 */
class CorrectionUtils_InvertedCondition {
  static CorrectionUtils_InvertedCondition _binary(int precedence, CorrectionUtils_InvertedCondition left, String operation, CorrectionUtils_InvertedCondition right) => new CorrectionUtils_InvertedCondition(precedence, "${CorrectionUtils._parenthesizeIfRequired(left, precedence)}${operation}${CorrectionUtils._parenthesizeIfRequired(right, precedence)}");

  static CorrectionUtils_InvertedCondition _binary2(CorrectionUtils_InvertedCondition left, String operation, CorrectionUtils_InvertedCondition right) => new CorrectionUtils_InvertedCondition(2147483647, "${left._source}${operation}${right._source}");

  static CorrectionUtils_InvertedCondition _simple(String source) => new CorrectionUtils_InvertedCondition(2147483647, source);

  final int _precedence;

  final String _source;

  CorrectionUtils_InvertedCondition(this._precedence, this._source);
}

class GeneralizingAstVisitor_CorrectionUtils_getOperandsInOrderFor extends GeneralizingAstVisitor<Object> {
  TokenType groupOperatorType;

  List<Expression> operands;

  GeneralizingAstVisitor_CorrectionUtils_getOperandsInOrderFor(this.groupOperatorType, this.operands) : super();

  @override
  Object visitExpression(Expression node) {
    if (node is BinaryExpression && node.operator.type == groupOperatorType) {
      return super.visitNode(node);
    }
    operands.add(node);
    return null;
  }
}

class GeneralizingElementVisitor_CorrectionUtils_getChildren extends GeneralizingElementVisitor<Object> {
  Element parent;

  String name;

  List<Element> children;

  GeneralizingElementVisitor_CorrectionUtils_getChildren(this.parent, this.name, this.children) : super();

  @override
  Object visitElement(Element element) {
    if (identical(element, parent)) {
      super.visitElement(element);
    } else if (name == null || CorrectionUtils.hasDisplayName(element, name)) {
      children.add(element);
    }
    return null;
  }
}

class GeneralizingElementVisitor_HierarchyUtils_getDirectMembers extends GeneralizingElementVisitor<Object> {
  ClassElement clazz;

  bool includeSynthetic = false;

  List<Element> members;

  GeneralizingElementVisitor_HierarchyUtils_getDirectMembers(this.clazz, this.includeSynthetic, this.members) : super();

  @override
  Object visitElement(Element element) {
    if (identical(element, clazz)) {
      return super.visitElement(element);
    }
    if (!includeSynthetic && element.isSynthetic) {
      return null;
    }
    if (element is ConstructorElement) {
      return null;
    }
    if (element is ExecutableElement) {
      members.add(element);
    }
    if (element is FieldElement) {
      members.add(element);
    }
    return null;
  }
}

class NameOccurrencesFinder extends RecursiveAstVisitor<Object> {
  static Iterable<AstNode> findIn(SimpleIdentifier ident, AstNode root) {
    if (ident == null || ident.bestElement == null) {
      return new Set<AstNode>();
    }
    NameOccurrencesFinder finder = new NameOccurrencesFinder(ident.bestElement);
    root.accept(finder);
    return finder.matches;
  }

  Element _target;

  Element _target2;

  Element _target3;

  Element _target4;

  Set<AstNode> _matches;

  NameOccurrencesFinder(Element source) {
    this._target = source;
    while (true) {
      if (source.kind == ElementKind.GETTER || source.kind == ElementKind.SETTER) {
        PropertyAccessorElement accessorElem = source as PropertyAccessorElement;
        this._target2 = accessorElem.variable;
        if (source is Member) {
          Member member = source;
          this._target4 = member.baseElement;
        }
        if (this._target2 is Member) {
          Member member = source as Member;
          this._target3 = member.baseElement;
        }
      } else if (source.kind == ElementKind.FIELD || source.kind == ElementKind.TOP_LEVEL_VARIABLE) {
        PropertyInducingElement propertyElem = source as PropertyInducingElement;
        this._target2 = propertyElem.getter;
        this._target3 = propertyElem.setter;
      } else if (source.kind == ElementKind.METHOD) {
        if (source is Member) {
          Member member = source;
          this._target4 = member.baseElement;
        }
      } else if (source.kind == ElementKind.PARAMETER) {
        ParameterElement param = source as ParameterElement;
        if (param.isInitializingFormal) {
          FieldFormalParameterElement fieldInit = param as FieldFormalParameterElement;
          this._target2 = fieldInit.field;
        }
      } else {
      }
      break;
    }
    if (_target2 == null) {
      _target2 = _target;
    }
    if (_target3 == null) {
      _target3 = _target;
    }
    if (_target4 == null) {
      _target4 = _target;
    }
    this._matches = new Set<AstNode>();
  }

  Iterable<AstNode> get matches => _matches;

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.bestElement;
    if (element == null) {
      return null;
    }
    _match(element, node);
    if (element is Member) {
      Member member = element;
      _match(member.baseElement, node);
    }
    while (true) {
      if (element.kind == ElementKind.GETTER || element.kind == ElementKind.SETTER) {
        PropertyAccessorElement accessorElem = element as PropertyAccessorElement;
        _match(accessorElem.variable, node);
      } else if (element.kind == ElementKind.FIELD || element.kind == ElementKind.TOP_LEVEL_VARIABLE) {
        PropertyInducingElement propertyElem = element as PropertyInducingElement;
        _match(propertyElem.getter, node);
        _match(propertyElem.setter, node);
      } else if (element.kind == ElementKind.PARAMETER) {
        ParameterElement param = element as ParameterElement;
        if (param.isInitializingFormal) {
          FieldFormalParameterElement fieldInit = param as FieldFormalParameterElement;
          _match(fieldInit.field, node);
        }
      } else {
      }
      break;
    }
    return null;
  }

  void _match(Element element, AstNode node) {
    if (identical(_target, element) || identical(_target2, element) || identical(_target3, element) || identical(_target4, element)) {
      _matches.add(node);
    }
  }
}

/**
 * Abstract visitor for visiting [AstNode]s covered by the selection [SourceRange].
 */
class SelectionAnalyzer extends GeneralizingAstVisitor<Object> {
  SourceRange selection;

  AstNode _coveringNode;

  List<AstNode> _selectedNodes;

  SelectionAnalyzer(SourceRange selection) {
    assert(selection != null);
    this.selection = selection;
  }

  /**
   * @return the [AstNode] with the shortest length which completely covers the specified
   *         selection.
   */
  AstNode get coveringNode => _coveringNode;

  /**
   * @return the first selected [AstNode], may be <code>null</code>.
   */
  AstNode get firstSelectedNode {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return null;
    }
    return _selectedNodes[0];
  }

  /**
   * @return the last selected [AstNode], may be <code>null</code>.
   */
  AstNode get lastSelectedNode {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return null;
    }
    return _selectedNodes[_selectedNodes.length - 1];
  }

  /**
   * @return the [SourceRange] which covers selected [AstNode]s, may be
   *         <code>null</code> if no [AstNode]s under selection.
   */
  SourceRange get selectedNodeRange {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return null;
    }
    AstNode firstNode = _selectedNodes[0];
    AstNode lastNode = _selectedNodes[_selectedNodes.length - 1];
    return SourceRangeFactory.rangeStartEnd(firstNode, lastNode);
  }

  /**
   * @return the [AstNode]s fully covered by the selection [SourceRange].
   */
  List<AstNode> get selectedNodes {
    if (_selectedNodes == null || _selectedNodes.isEmpty) {
      return [];
    }
    return _selectedNodes;
  }

  /**
   * @return <code>true</code> if there are [AstNode] fully covered by the selection
   *         [SourceRange].
   */
  bool get hasSelectedNodes => _selectedNodes != null && !_selectedNodes.isEmpty;

  @override
  Object visitNode(AstNode node) {
    SourceRange nodeRange = SourceRangeFactory.rangeNode(node);
    if (selection.covers(nodeRange)) {
      if (isFirstNode) {
        handleFirstSelectedNode(node);
      } else {
        handleNextSelectedNode(node);
      }
      return null;
    } else if (selection.coveredBy(nodeRange)) {
      _coveringNode = node;
      node.visitChildren(this);
      return null;
    } else if (selection.startsIn(nodeRange)) {
      handleSelectionStartsIn(node);
      node.visitChildren(this);
      return null;
    } else if (selection.endsIn(nodeRange)) {
      handleSelectionEndsIn(node);
      node.visitChildren(this);
      return null;
    }
    // no intersection
    return null;
  }

  /**
   * Adds first selected [AstNode].
   */
  void handleFirstSelectedNode(AstNode node) {
    _selectedNodes = [];
    _selectedNodes.add(node);
  }

  /**
   * Adds second or more selected [AstNode].
   */
  void handleNextSelectedNode(AstNode node) {
    if (identical(firstSelectedNode.parent, node.parent)) {
      _selectedNodes.add(node);
    }
  }

  /**
   * Notifies that selection ends in given [AstNode].
   */
  void handleSelectionEndsIn(AstNode node) {
  }

  /**
   * Notifies that selection starts in given [AstNode].
   */
  void handleSelectionStartsIn(AstNode node) {
  }

  /**
   * Resets selected nodes.
   */
  void reset() {
    _selectedNodes = null;
  }

  /**
   * @return <code>true</code> if there was no selected nodes yet.
   */
  bool get isFirstNode => _selectedNodes == null;
}

/**
 * Helper for building Dart source with tracked positions.
 */
class SourceBuilder {
  final int offset;

  JavaStringBuilder _buffer = new JavaStringBuilder();

  Map<String, List<SourceRange>> _linkedPositions = {};

  final Map<String, List<LinkedPositionProposal>> linkedProposals = {};

  String _currentPositionGroupId;

  int _currentPositionStart = 0;

  int _endPosition = -1;

  SourceBuilder.con1(this.offset);

  SourceBuilder.con2(SourceRange offsetRange) : this.con1(offsetRange.offset);

  /**
   * Adds proposal for the current position, may be called after [startPosition].
   */
  void addProposal(CorrectionImage icon, String text) {
    List<LinkedPositionProposal> proposals = linkedProposals[_currentPositionGroupId];
    if (proposals == null) {
      proposals = [];
      linkedProposals[_currentPositionGroupId] = proposals;
    }
    proposals.add(new LinkedPositionProposal(icon, text));
  }

  /**
   * Appends source to the buffer.
   */
  SourceBuilder append(String s) {
    _buffer.append(s);
    return this;
  }

  /**
   * Ends position started using [startPosition].
   */
  void endPosition() {
    assert(_currentPositionGroupId != null);
    _addPosition();
    _currentPositionGroupId = null;
  }

  /**
   * @return the "end position" for the [CorrectionProposal], may be <code>-1</code> if not
   *         set in this [SourceBuilder].
   */
  int get endPosition2 {
    if (_endPosition == -1) {
      return -1;
    }
    return offset + _endPosition;
  }

  /**
   * @return the [Map] or position IDs to their locations.
   */
  Map<String, List<SourceRange>> get linkedPositions => _linkedPositions;

  /**
   * @return the length of the built source.
   */
  int length() => _buffer.length;

  /**
   * Marks current position as "end position" of the [CorrectionProposal].
   */
  void setEndPosition() {
    _endPosition = _buffer.length;
  }

  /**
   * Sets text-only proposals for the current position.
   */
  void set proposals(List<String> proposals) {
    List<LinkedPositionProposal> proposalList = [];
    for (String proposalText in proposals) {
      proposalList.add(new LinkedPositionProposal(null, proposalText));
    }
    linkedProposals[_currentPositionGroupId] = proposalList;
  }

  /**
   * Starts linked position with given ID.
   */
  void startPosition(String groupId) {
    assert(_currentPositionGroupId == null);
    _currentPositionGroupId = groupId;
    _currentPositionStart = _buffer.length;
  }

  @override
  String toString() => _buffer.toString();

  /**
   * Adds position location [SourceRange] using current fields.
   */
  void _addPosition() {
    List<SourceRange> locations = _linkedPositions[_currentPositionGroupId];
    if (locations == null) {
      locations = [];
      _linkedPositions[_currentPositionGroupId] = locations;
    }
    int start = offset + _currentPositionStart;
    int end = offset + _buffer.length;
    locations.add(SourceRangeFactory.rangeStartEnd(start, end));
  }
}

/**
 * Analyzer to check if a selection covers a valid set of statements of AST.
 */
class StatementAnalyzer extends SelectionAnalyzer {
  /**
   * @return <code>true</code> if "nodes" contains "node".
   */
  static bool _contains(List<AstNode> nodes, AstNode node) => nodes.contains(node);

  /**
   * @return <code>true</code> if "nodes" contains one of the "otherNodes".
   */
  static bool _contains2(List<AstNode> nodes, List<AstNode> otherNodes) {
    for (AstNode otherNode in otherNodes) {
      if (nodes.contains(otherNode)) {
        return true;
      }
    }
    return false;
  }

  CorrectionUtils utils;

  RefactoringStatus _status = new RefactoringStatus();

  StatementAnalyzer.con1(CompilationUnit cunit, SourceRange selection) : this.con2(new CorrectionUtils(cunit), selection);

  StatementAnalyzer.con2(CorrectionUtils utils, SourceRange selection) : super(selection) {
    this.utils = utils;
  }

  /**
   * @return the [RefactoringStatus] result of checking selection.
   */
  RefactoringStatus get status => _status;

  @override
  Object visitCompilationUnit(CompilationUnit node) {
    super.visitCompilationUnit(node);
    if (!hasSelectedNodes) {
      return null;
    }
    // check that selection does not begin/end in comment
    {
      int selectionStart = selection.offset;
      int selectionEnd = selection.end;
      List<SourceRange> commentRanges = utils.commentRanges;
      for (SourceRange commentRange in commentRanges) {
        if (commentRange.contains(selectionStart)) {
          invalidSelection("Selection begins inside a comment.");
        }
        if (commentRange.containsExclusive(selectionEnd)) {
          invalidSelection("Selection ends inside a comment.");
        }
      }
    }
    // more checks
    if (!_status.hasFatalError) {
      _checkSelectedNodes(node);
    }
    return null;
  }

  @override
  Object visitDoStatement(DoStatement node) {
    super.visitDoStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    if (_contains(selectedNodes, node.body)) {
      invalidSelection("Operation not applicable to a 'do' statement's body and expression.");
    }
    return null;
  }

  @override
  Object visitForStatement(ForStatement node) {
    super.visitForStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    bool containsInit = _contains(selectedNodes, node.initialization) || _contains(selectedNodes, node.variables);
    bool containsCondition = _contains(selectedNodes, node.condition);
    bool containsUpdaters = _contains2(selectedNodes, node.updaters);
    bool containsBody = _contains(selectedNodes, node.body);
    if (containsInit && containsCondition) {
      invalidSelection("Operation not applicable to a 'for' statement's initializer and condition.");
    } else if (containsCondition && containsUpdaters) {
      invalidSelection("Operation not applicable to a 'for' statement's condition and updaters.");
    } else if (containsUpdaters && containsBody) {
      invalidSelection("Operation not applicable to a 'for' statement's updaters and body.");
    }
    return null;
  }

  @override
  Object visitSwitchStatement(SwitchStatement node) {
    super.visitSwitchStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    List<SwitchMember> switchMembers = node.members;
    for (AstNode selectedNode in selectedNodes) {
      if (switchMembers.contains(selectedNode)) {
        invalidSelection("Selection must either cover whole switch statement or parts of a single case block.");
        break;
      }
    }
    return null;
  }

  @override
  Object visitTryStatement(TryStatement node) {
    super.visitTryStatement(node);
    AstNode firstSelectedNode = this.firstSelectedNode;
    if (firstSelectedNode != null) {
      if (identical(firstSelectedNode, node.body) || identical(firstSelectedNode, node.finallyBlock)) {
        invalidSelection("Selection must either cover whole try statement or parts of try, catch, or finally block.");
      } else {
        List<CatchClause> catchClauses = node.catchClauses;
        for (CatchClause catchClause in catchClauses) {
          if (identical(firstSelectedNode, catchClause) || identical(firstSelectedNode, catchClause.body) || identical(firstSelectedNode, catchClause.exceptionParameter)) {
            invalidSelection("Selection must either cover whole try statement or parts of try, catch, or finally block.");
          }
        }
      }
    }
    return null;
  }

  @override
  Object visitWhileStatement(WhileStatement node) {
    super.visitWhileStatement(node);
    List<AstNode> selectedNodes = this.selectedNodes;
    if (_contains(selectedNodes, node.condition) && _contains(selectedNodes, node.body)) {
      invalidSelection("Operation not applicable to a while statement's expression and body.");
    }
    return null;
  }

  /**
   * Records fatal error with given message.
   */
  void invalidSelection(String message) {
    invalidSelection2(message, null);
  }

  /**
   * Records fatal error with given message and [RefactoringStatusContext].
   */
  void invalidSelection2(String message, RefactoringStatusContext context) {
    _status.addFatalError(message, context);
    reset();
  }

  /**
   * Checks final selected [AstNode]s after processing [CompilationUnit].
   */
  void _checkSelectedNodes(CompilationUnit unit) {
    List<AstNode> nodes = selectedNodes;
    // some tokens before first selected node
    {
      AstNode firstNode = nodes[0];
      SourceRange rangeBeforeFirstNode = SourceRangeFactory.rangeStartStart(selection, firstNode);
      if (_hasTokens(rangeBeforeFirstNode)) {
        invalidSelection2("The beginning of the selection contains characters that do not belong to a statement.", new RefactoringStatusContext.forUnit(unit, rangeBeforeFirstNode));
      }
    }
    // some tokens after last selected node
    {
      AstNode lastNode = nodes.last;
      SourceRange rangeAfterLastNode = SourceRangeFactory.rangeEndEnd(lastNode, selection);
      if (_hasTokens(rangeAfterLastNode)) {
        invalidSelection2("The end of the selection contains characters that do not belong to a statement.", new RefactoringStatusContext.forUnit(unit, rangeAfterLastNode));
      }
    }
  }

  /**
   * @return the [Token]s in given [SourceRange].
   */
  List<Token> _getTokens(SourceRange range) {
    try {
      String text = utils.getText3(range);
      return TokenUtils.getTokens(text);
    } catch (e) {
      return [];
    }
  }

  /**
   * @return <code>true</code> if there are [Token]s in the given [SourceRange].
   */
  bool _hasTokens(SourceRange range) => !_getTokens(range).isEmpty;
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
  static bool hasOnly(List<Token> tokens, TokenType type) => tokens.length == 1 && tokens[0].type == type;
}

class URIUtils {
  /**
   * Computes relative relative path to reference "target" from "base". Uses ".." if needed, in
   * contrast to [URI#relativize].
   */
  static String computeRelativePath(String base, String target) {
    // convert to URI separator
    base = base.replaceAll("\\\\", "/");
    target = target.replaceAll("\\\\", "/");
    if (base.startsWith("/") && target.startsWith("/")) {
      base = base.substring(1);
      target = target.substring(1);
    }
    // equal paths - no relative
    if (base == target) {
      return null;
    }
    // split paths
    List<String> baseParts = base.split("/");
    List<String> targetParts = target.split("/");
    // prepare maximum possible common root length
    int length = baseParts.length < targetParts.length ? baseParts.length : targetParts.length;
    // find common root
    int lastCommonRoot = -1;
    for (int i = 0; i < length; i++) {
      if (baseParts[i] == targetParts[i]) {
        lastCommonRoot = i;
      } else {
        break;
      }
    }
    // append ..
    JavaStringBuilder relativePath = new JavaStringBuilder();
    for (int i = lastCommonRoot + 1; i < baseParts.length; i++) {
      if (baseParts[i].length > 0) {
        relativePath.append("../");
      }
    }
    // append target folder names
    for (int i = lastCommonRoot + 1; i < targetParts.length - 1; i++) {
      String p = targetParts[i];
      relativePath.append(p);
      relativePath.append("/");
    }
    // append target file name
    relativePath.append(targetParts[targetParts.length - 1]);
    // done
    return relativePath.toString();
  }
}