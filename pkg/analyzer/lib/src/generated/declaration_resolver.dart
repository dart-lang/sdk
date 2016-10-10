// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.src.generated.declaration_resolver;

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/exception/exception.dart';
import 'package:analyzer/src/dart/element/element.dart';

/**
 * A visitor that resolves declarations in an AST structure to already built
 * elements.
 *
 * The resulting AST must have everything resolved that would have been resolved
 * by a [CompilationUnitBuilder] (that is, must be a valid [RESOLVED_UNIT1]).
 * This class must not assume that the [CompilationUnitElement] passed to it is
 * any more complete than a [COMPILATION_UNIT_ELEMENT].
 */
class DeclarationResolver extends RecursiveAstVisitor<Object>
    with _ExistingElementResolver {
  /**
   * The elements that are reachable from the compilation unit element. When a
   * compilation unit has been resolved, this set should be empty.
   */
  Set<Element> _expectedElements;

  /**
   * The function type alias containing the AST nodes being visited, or `null`
   * if we are not in the scope of a function type alias.
   */
  FunctionTypeAliasElement _enclosingAlias;

  /**
   * The class containing the AST nodes being visited, or `null` if we are not
   * in the scope of a class.
   */
  ClassElement _enclosingClass;

  /**
   * The method or function containing the AST nodes being visited, or `null` if
   * we are not in the scope of a method or function.
   */
  ExecutableElement _enclosingExecutable;

  /**
   * The parameter containing the AST nodes being visited, or `null` if we are
   * not in the scope of a parameter.
   */
  ParameterElement _enclosingParameter;

  /**
   * Resolve the declarations within the given compilation [unit] to the
   * elements rooted at the given [element]. Throw an [ElementMismatchException]
   * if the element model and compilation unit do not match each other.
   */
  void resolve(CompilationUnit unit, CompilationUnitElement element) {
    _ElementGatherer gatherer = new _ElementGatherer();
    element.accept(gatherer);
    _expectedElements = gatherer.elements;
    _enclosingUnit = element;
    _expectedElements.remove(element);
    unit.element = element;
    unit.accept(this);
    _validateResolution();
  }

  @override
  Object visitCatchClause(CatchClause node) {
    SimpleIdentifier exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      List<LocalVariableElement> localVariables =
          _enclosingExecutable.localVariables;
      _findIdentifier(localVariables, exceptionParameter);
      SimpleIdentifier stackTraceParameter = node.stackTraceParameter;
      if (stackTraceParameter != null) {
        _findIdentifier(localVariables, stackTraceParameter);
      }
    }
    return super.visitCatchClause(node);
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = _findIdentifier(_enclosingUnit.types, className);
      super.visitClassDeclaration(node);
      _resolveMetadata(node, node.metadata, _enclosingClass);
      return null;
    } finally {
      _enclosingClass = outerClass;
    }
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    ClassElement outerClass = _enclosingClass;
    try {
      SimpleIdentifier className = node.name;
      _enclosingClass = _findIdentifier(_enclosingUnit.types, className);
      super.visitClassTypeAlias(node);
      _resolveMetadata(node, node.metadata, _enclosingClass);
      return null;
    } finally {
      _enclosingClass = outerClass;
    }
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier constructorName = node.name;
      if (constructorName == null) {
        _enclosingExecutable = _enclosingClass.unnamedConstructor;
        if (_enclosingExecutable == null) {
          _mismatch('Could not find default constructor', node);
        }
      } else {
        _enclosingExecutable =
            _enclosingClass.getNamedConstructor(constructorName.name);
        if (_enclosingExecutable == null) {
          _mismatch(
              'Could not find constructor element with name "${constructorName.name}',
              node);
        }
        constructorName.staticElement = _enclosingExecutable;
      }
      _expectedElements.remove(_enclosingExecutable);
      node.element = _enclosingExecutable as ConstructorElement;
      super.visitConstructorDeclaration(node);
      _resolveMetadata(node, node.metadata, _enclosingExecutable);
      return null;
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    SimpleIdentifier variableName = node.identifier;
    Element element =
        _findIdentifier(_enclosingExecutable.localVariables, variableName);
    super.visitDeclaredIdentifier(node);
    _resolveMetadata(node, node.metadata, element);
    return null;
  }

  @override
  Object visitDefaultFormalParameter(DefaultFormalParameter node) {
    SimpleIdentifier parameterName = node.parameter.identifier;
    ParameterElement element = _getElementForParameter(node, parameterName);
    Expression defaultValue = node.defaultValue;
    if (defaultValue != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        _enclosingExecutable = element.initializer;
        defaultValue.accept(this);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    ParameterElement outerParameter = _enclosingParameter;
    try {
      _enclosingParameter = element;
      super.visitDefaultFormalParameter(node);
      _resolveMetadata(node, node.metadata, element);
      return null;
    } finally {
      _enclosingParameter = outerParameter;
    }
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    ClassElement enclosingEnum =
        _findIdentifier(_enclosingUnit.enums, node.name);
    List<FieldElement> constants = enclosingEnum.fields;
    for (EnumConstantDeclaration constant in node.constants) {
      _findIdentifier(constants, constant.name);
    }
    super.visitEnumDeclaration(node);
    _resolveMetadata(node, node.metadata, enclosingEnum);
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    super.visitExportDirective(node);
    _resolveAnnotations(
        node, node.metadata, _enclosingUnit.getAnnotations(node.offset));
    return null;
  }

  @override
  Object visitFieldDeclaration(FieldDeclaration node) {
    super.visitFieldDeclaration(node);
    _resolveMetadata(node, node.metadata, node.fields.variables[0].element);
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = _getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        super.visitFieldFormalParameter(node);
        _resolveMetadata(node, node.metadata, element);
        return null;
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFieldFormalParameter(node);
    }
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      SimpleIdentifier functionName = node.name;
      Token property = node.propertyKeyword;
      if (property == null) {
        if (_enclosingExecutable != null) {
          _enclosingExecutable =
              _findIdentifier(_enclosingExecutable.functions, functionName);
        } else {
          _enclosingExecutable =
              _findIdentifier(_enclosingUnit.functions, functionName);
        }
      } else {
        if (_enclosingExecutable != null) {
          _enclosingExecutable =
              _findIdentifier(_enclosingExecutable.functions, functionName);
        } else {
          List<PropertyAccessorElement> accessors;
          if (_enclosingClass != null) {
            accessors = _enclosingClass.accessors;
          } else {
            accessors = _enclosingUnit.accessors;
          }
          PropertyAccessorElement accessor;
          if (property.keyword == Keyword.GET) {
            accessor = _findIdentifier(accessors, functionName);
          } else if (property.keyword == Keyword.SET) {
            accessor = _findWithNameAndOffset(accessors, functionName,
                functionName.name + '=', functionName.offset);
            _expectedElements.remove(accessor);
            functionName.staticElement = accessor;
          }
          _enclosingExecutable = accessor;
        }
      }
      node.functionExpression.element = _enclosingExecutable;
      super.visitFunctionDeclaration(node);
      _resolveMetadata(node, node.metadata, _enclosingExecutable);
      return null;
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is! FunctionDeclaration) {
      FunctionElement element = _findAtOffset(
          _enclosingExecutable.functions, node, node.beginToken.offset);
      _expectedElements.remove(element);
      node.element = element;
    }
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      _enclosingExecutable = node.element;
      return super.visitFunctionExpression(node);
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    FunctionTypeAliasElement outerAlias = _enclosingAlias;
    try {
      SimpleIdentifier aliasName = node.name;
      _enclosingAlias =
          _findIdentifier(_enclosingUnit.functionTypeAliases, aliasName);
      super.visitFunctionTypeAlias(node);
      _resolveMetadata(node, node.metadata, _enclosingAlias);
      return null;
    } finally {
      _enclosingAlias = outerAlias;
    }
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = _getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        super.visitFunctionTypedFormalParameter(node);
        _resolveMetadata(node, node.metadata, _enclosingParameter);
        return null;
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {
      return super.visitFunctionTypedFormalParameter(node);
    }
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    super.visitImportDirective(node);
    _resolveAnnotations(
        node, node.metadata, _enclosingUnit.getAnnotations(node.offset));
    return null;
  }

  @override
  Object visitLabeledStatement(LabeledStatement node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      _findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitLabeledStatement(node);
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    super.visitLibraryDirective(node);
    _resolveAnnotations(
        node, node.metadata, _enclosingUnit.getAnnotations(node.offset));
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    ExecutableElement outerExecutable = _enclosingExecutable;
    try {
      Token property = node.propertyKeyword;
      SimpleIdentifier methodName = node.name;
      String nameOfMethod = methodName.name;
      if (property == null) {
        String elementName = nameOfMethod == '-' &&
                node.parameters != null &&
                node.parameters.parameters.isEmpty
            ? 'unary-'
            : nameOfMethod;
        _enclosingExecutable = _findWithNameAndOffset(_enclosingClass.methods,
            methodName, elementName, methodName.offset);
        _expectedElements.remove(_enclosingExecutable);
        methodName.staticElement = _enclosingExecutable;
      } else {
        PropertyAccessorElement accessor;
        if (property.keyword == Keyword.GET) {
          accessor = _findIdentifier(_enclosingClass.accessors, methodName);
        } else if (property.keyword == Keyword.SET) {
          accessor = _findWithNameAndOffset(_enclosingClass.accessors,
              methodName, nameOfMethod + '=', methodName.offset);
          _expectedElements.remove(accessor);
          methodName.staticElement = accessor;
        }
        _enclosingExecutable = accessor;
      }
      super.visitMethodDeclaration(node);
      _resolveMetadata(node, node.metadata, _enclosingExecutable);
      return null;
    } finally {
      _enclosingExecutable = outerExecutable;
    }
  }

  @override
  Object visitPartDirective(PartDirective node) {
    super.visitPartDirective(node);
    _resolveAnnotations(
        node, node.metadata, _enclosingUnit.getAnnotations(node.offset));
    return null;
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    node.element = _enclosingUnit.library;
    return super.visitPartOfDirective(node);
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.parent is! DefaultFormalParameter) {
      SimpleIdentifier parameterName = node.identifier;
      ParameterElement element = _getElementForParameter(node, parameterName);
      ParameterElement outerParameter = _enclosingParameter;
      try {
        _enclosingParameter = element;
        super.visitSimpleFormalParameter(node);
        _resolveMetadata(node, node.metadata, element);
        return null;
      } finally {
        _enclosingParameter = outerParameter;
      }
    } else {}
    return super.visitSimpleFormalParameter(node);
  }

  @override
  Object visitSwitchCase(SwitchCase node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      _findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchCase(node);
  }

  @override
  Object visitSwitchDefault(SwitchDefault node) {
    for (Label label in node.labels) {
      SimpleIdentifier labelName = label.label;
      _findIdentifier(_enclosingExecutable.labels, labelName);
    }
    return super.visitSwitchDefault(node);
  }

  @override
  Object visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    super.visitTopLevelVariableDeclaration(node);
    _resolveMetadata(node, node.metadata, node.variables.variables[0].element);
    return null;
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    SimpleIdentifier parameterName = node.name;
    Element element = null;
    if (_enclosingExecutable != null) {
      element = _findIdentifier(
          _enclosingExecutable.typeParameters, parameterName,
          required: false);
    }
    if (element == null) {
      if (_enclosingClass != null) {
        element =
            _findIdentifier(_enclosingClass.typeParameters, parameterName);
      } else if (_enclosingAlias != null) {
        element =
            _findIdentifier(_enclosingAlias.typeParameters, parameterName);
      }
    }
    if (element == null) {
      String name = parameterName.name;
      int offset = parameterName.offset;
      _mismatch(
          'Could not find type parameter with name "$name" at $offset', node);
    }
    super.visitTypeParameter(node);
    _resolveMetadata(node, node.metadata, element);
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    VariableElement element = null;
    SimpleIdentifier variableName = node.name;
    if (_enclosingExecutable != null) {
      element = _findIdentifier(
          _enclosingExecutable.localVariables, variableName,
          required: false);
    }
    if (element == null && _enclosingClass != null) {
      element = _findIdentifier(_enclosingClass.fields, variableName,
          required: false);
    }
    if (element == null && _enclosingUnit != null) {
      element = _findIdentifier(_enclosingUnit.topLevelVariables, variableName);
    }
    Expression initializer = node.initializer;
    if (initializer != null) {
      ExecutableElement outerExecutable = _enclosingExecutable;
      try {
        _enclosingExecutable = element.initializer;
        return super.visitVariableDeclaration(node);
      } finally {
        _enclosingExecutable = outerExecutable;
      }
    }
    return super.visitVariableDeclaration(node);
  }

  @override
  Object visitVariableDeclarationList(VariableDeclarationList node) {
    super.visitVariableDeclarationList(node);
    if (node.parent is! FieldDeclaration &&
        node.parent is! TopLevelVariableDeclaration) {
      _resolveMetadata(node, node.metadata, node.variables[0].element);
    }
    return null;
  }

  /**
   * Return the element in the given list of [elements] that was created for the
   * declaration at the given [offset]. Throw an [ElementMismatchException] if
   * an element at that offset cannot be found.
   *
   * This method should only be used when there is no name associated with the
   * node.
   */
  Element _findAtOffset(List<Element> elements, AstNode node, int offset) =>
      _findWithNameAndOffset(elements, node, '', offset);

  /**
   * Return the element in the given list of [elements] that was created for the
   * declaration with the given [identifier]. As a side-effect, associate the
   * returned element with the identifier. Throw an [ElementMismatchException]
   * if an element corresponding to the identifier cannot be found unless
   * [required] is `false`, in which case return `null`.
   */
  Element _findIdentifier(List<Element> elements, SimpleIdentifier identifier,
      {bool required: true}) {
    Element element = _findWithNameAndOffset(
        elements, identifier, identifier.name, identifier.offset,
        required: required);
    _expectedElements.remove(element);
    identifier.staticElement = element;
    return element;
  }

  /**
   * Return the element in the given list of [elements] that was created for the
   * declaration with the given [name] at the given [offset]. Throw an
   * [ElementMismatchException] if an element corresponding to the identifier
   * cannot be found unless [required] is `false`, in which case return `null`.
   */
  Element _findWithNameAndOffset(
      List<Element> elements, AstNode node, String name, int offset,
      {bool required: true}) {
    int length = elements.length;
    for (int i = 0; i < length; i++) {
      Element element = elements[i];
      if (element.nameOffset == offset && element.name == name) {
        return element;
      }
    }
    if (!required) {
      return null;
    }
    for (int i = 0; i < length; i++) {
      Element element = elements[i];
      if (element.name == name) {
        _mismatch(
            'Found element with name "$name" at ${element.nameOffset}, '
            'but expected offset of $offset',
            node);
      }
      if (element.nameOffset == offset) {
        _mismatch(
            'Found element with name "${element.name}" at $offset, '
            'but expected element with name "$name"',
            node);
      }
    }
    _mismatch('Could not find element with name "$name" at $offset', node);
    return null; // Never reached
  }

  /**
   * Search the most closely enclosing list of parameter elements for a
   * parameter, defined by the given [node], with the given [parameterName].
   * Return the element that was found, or throw an [ElementMismatchException]
   * if an element corresponding to the identifier cannot be found.
   */
  ParameterElement _getElementForParameter(
      FormalParameter node, SimpleIdentifier parameterName) {
    List<ParameterElement> parameters = null;
    if (_enclosingParameter != null) {
      parameters = _enclosingParameter.parameters;
    }
    if (parameters == null && _enclosingExecutable != null) {
      parameters = _enclosingExecutable.parameters;
    }
    if (parameters == null && _enclosingAlias != null) {
      parameters = _enclosingAlias.parameters;
    }
    if (parameters == null) {
      StringBuffer buffer = new StringBuffer();
      buffer.writeln('Could not find parameter in enclosing scope');
      buffer.writeln(
          '(_enclosingParameter == null) == ${_enclosingParameter == null}');
      buffer.writeln(
          '(_enclosingExecutable == null) == ${_enclosingExecutable == null}');
      buffer.writeln('(_enclosingAlias == null) == ${_enclosingAlias == null}');
      _mismatch(buffer.toString(), parameterName);
    }
    return _findIdentifier(parameters, parameterName);
  }

  /**
   * Associate each of the annotation [nodes] with the corresponding
   * [ElementAnnotation] in [annotations]. If there is a problem, report it
   * against the given [parent] node.
   */
  void _resolveAnnotations(AstNode parent, NodeList<Annotation> nodes,
      List<ElementAnnotation> annotations) {
    int nodeCount = nodes.length;
    if (nodeCount != annotations.length) {
      _mismatch(
          'Found $nodeCount annotation nodes and '
          '${annotations.length} element annotations',
          parent);
    }
    for (int i = 0; i < nodeCount; i++) {
      nodes[i].elementAnnotation = annotations[i];
    }
  }

  /**
   * If [element] is not `null`, associate each of the annotation [nodes] with
   * the corresponding [ElementAnnotation] in [element.metadata]. If there is a
   * problem, report it against the given [parent] node.
   *
   * If [element] is `null`, do nothing--this allows us to be robust in the
   * case where we are operating on an element model that hasn't been fully
   * built.
   */
  void _resolveMetadata(
      AstNode parent, NodeList<Annotation> nodes, Element element) {
    if (element != null) {
      _resolveAnnotations(parent, nodes, element.metadata);
    }
  }

  /**
   * Throw an exception if there are non-synthetic elements in the element model
   * that were not associated with an AST node.
   */
  void _validateResolution() {
    if (_expectedElements.isNotEmpty) {
      StringBuffer buffer = new StringBuffer();
      buffer.write(_expectedElements.length);
      buffer.writeln(' unmatched elements found:');
      for (Element element in _expectedElements) {
        buffer.write('  ');
        buffer.writeln(element);
      }
      throw new _ElementMismatchException(buffer.toString());
    }
  }
}

/**
 * A visitor that can be used to collect all of the non-synthetic elements in an
 * element model.
 */
class _ElementGatherer extends GeneralizingElementVisitor {
  /**
   * The set in which the elements are collected.
   */
  final Set<Element> elements = new HashSet<Element>();

  /**
   * Initialize the visitor.
   */
  _ElementGatherer();

  @override
  void visitElement(Element element) {
    if (!element.isSynthetic) {
      elements.add(element);
    }
    super.visitElement(element);
  }
}

class _ElementMismatchException extends AnalysisException {
  /**
   * Initialize a newly created exception to have the given [message] and
   * [cause].
   */
  _ElementMismatchException(String message, [CaughtException cause = null])
      : super(message, cause);
}

/**
 * A mixin for classes that use an existing element model to resolve a portion
 * of an AST structure.
 */
class _ExistingElementResolver {
  /**
   * The compilation unit containing the AST nodes being visited.
   */
  CompilationUnitElementImpl _enclosingUnit;

  /**
   * Throw an [ElementMismatchException] to report that the element model and the
   * AST do not match. The [message] will have the path to the given [node]
   * appended to it.
   */
  void _mismatch(String message, AstNode node) {
    StringBuffer buffer = new StringBuffer();
    buffer.write('Mismatch in ');
    buffer.write(runtimeType);
    buffer.write(' while resolving ');
    buffer.writeln(_enclosingUnit?.source?.fullName);
    buffer.writeln(message);
    buffer.write('Path to root:');
    String separator = ' ';
    AstNode parent = node;
    while (parent != null) {
      buffer.write(separator);
      buffer.write(parent.runtimeType.toString());
      separator = ', ';
      parent = parent.parent;
    }
    throw new _ElementMismatchException(buffer.toString());
  }
}
