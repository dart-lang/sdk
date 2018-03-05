// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/fasta/resolution_storer.dart';
import 'package:front_end/src/base/syntactic_entity.dart';
import 'package:front_end/src/scanner/token.dart';
import 'package:kernel/kernel.dart' as kernel;

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST.
class ResolutionApplier extends GeneralizingAstVisitor {
  final LibraryElement _enclosingLibraryElement;
  final TypeContext _typeContext;

  final List<Element> _declaredElements;
  int _declaredElementIndex = 0;

  final List<Element> _referencedElements;
  int _referencedElementIndex = 0;

  final List<kernel.DartType> _types;
  int _typeIndex = 0;

  /// The current label scope. Each [Block] adds a new one.
  _LabelScope _labelScope = new _LabelScope(null);

  /// Indicates whether we are applying resolution to an annotation.
  ///
  /// When this field is `true`, [PropertyInducingElement]s should be replaced
  /// with corresponding getters.
  bool _inAnnotation = false;

  ResolutionApplier(this._enclosingLibraryElement, this._typeContext,
      this._declaredElements, this._referencedElements, this._types);

  /// Apply resolution to annotations of the given [node].
  void applyToAnnotations(AnnotatedNode node) {
    _inAnnotation = true;
    node.metadata.accept(this);
    _inAnnotation = false;
  }

  /// Verifies that all types passed to the constructor have been applied.
  void checkDone() {
    if (_declaredElementIndex != _declaredElements.length) {
      throw new StateError('Some declarations were not consumed, starting at '
          '${_declaredElements[_declaredElementIndex]}');
    }
    if (_referencedElementIndex != _referencedElements.length) {
      throw new StateError('Some references were not consumed, starting at '
          '${_referencedElements[_referencedElementIndex]}');
    }
    if (_typeIndex != _types.length) {
      throw new StateError(
          'Some types were not consumed, starting at ${_types[_typeIndex]}');
    }
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    node.strings.accept(this);
    node.staticType = _typeContext.stringType;
  }

  @override
  void visitAnnotation(Annotation node) {
    SimpleIdentifier constructorName = node.constructorName;

    // Peek forward and check if the next element is a PrefixElement.
    SimpleIdentifier topEntity;
    if (_referencedElements[_referencedElementIndex] is PrefixElement) {
      PrefixedIdentifier prefixedIdentifier = node.name;

      SimpleIdentifier prefix = prefixedIdentifier.prefix;
      PrefixElement prefixElement = _getReferenceFor(prefix);
      _getTypeFor(prefix); // prefix type
      prefix.staticElement = prefixElement;

      topEntity = prefixedIdentifier.identifier;
    } else {
      topEntity = node.name;
    }

    Element element = _getReferenceFor(topEntity);
    DartType type = _getTypeFor(topEntity);
    node.element = element;

    if (element is ConstructorElement) {
      topEntity.staticElement = element.enclosingElement;

      if (constructorName != null) {
        constructorName.staticElement = element;
        constructorName.staticType = element.type;
      }

      ArgumentList argumentList = node.arguments;
      if (argumentList != null) {
        _applyResolutionToArguments(argumentList);
        _resolveNamedArguments(argumentList, element.parameters);
      }
    } else {
      topEntity.staticElement = element;
      topEntity.staticType = type;
      if (constructorName != null) {
        constructorName.accept(this);
        node.element = constructorName.staticElement;
      }
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.expression.accept(this);
    applyToTypeAnnotation(
        _enclosingLibraryElement, _getTypeFor(node.asOperator), node.type);
    node.staticType = _getTypeFor(node.asOperator);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);

    SyntacticEntity entity = _getAssignmentEntity(node.leftHandSide);
    node.staticElement = _getReferenceFor(entity);
    node.staticType = _getTypeFor(entity);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);

    TokenType operatorType = node.operator.type;
    if (operatorType != TokenType.QUESTION_QUESTION &&
        operatorType != TokenType.AMPERSAND_AMPERSAND &&
        operatorType != TokenType.BAR_BAR) {
      node.staticElement = _getReferenceFor(node.operator);
      _getTypeFor(node.operator); // callee type
      _getTypeFor(node.operator); // invocation type
      _getTypeFor(node.operator); // type arguments
    }

    // Record the return type of the expression.
    node.staticType = _getTypeFor(node.operator);

    node.rightOperand.accept(this);

    // Skip the synthetic Not for `!=`.
    if (operatorType == TokenType.BANG_EQ) {
      _getTypeFor(null, synthetic: true);
    }
  }

  @override
  void visitBlock(Block node) {
    _labelScope = new _LabelScope(_labelScope);
    super.visitBlock(node);
    _labelScope = _labelScope.parent;
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    SimpleIdentifier label = node.label;
    if (label != null) {
      LabelElement labelElement = _labelScope[label.name];
      label.staticElement = labelElement;
    }
  }

  @override
  void visitCascadeExpression(CascadeExpression node) {
    visitNode(node);
    node.staticType = node.target.staticType;
  }

  @override
  void visitCatchClause(CatchClause node) {
    DartType guardType = _getTypeFor(node.onKeyword ?? node.catchKeyword);
    if (node.exceptionType != null) {
      applyToTypeAnnotation(
          _enclosingLibraryElement, guardType, node.exceptionType);
    }

    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      LocalVariableElementImpl element = _getDeclarationFor(exception);
      DartType type = _getTypeFor(exception);
      element.type = type;
      exception.staticElement = element;
      exception.staticType = type;
    }

    SimpleIdentifier stackTrace = node.stackTraceParameter;
    if (stackTrace != null) {
      LocalVariableElementImpl element = _getDeclarationFor(stackTrace);
      DartType type = _getTypeFor(stackTrace);
      element.type = type;
      stackTrace.staticElement = element;
      stackTrace.staticType = type;
    }

    node.body.accept(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
    node.staticType = _getTypeFor(node.question);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    FieldElement fieldElement = _getReferenceFor(node.equals);
    node.fieldName.staticElement = fieldElement;
    node.fieldName.staticType = fieldElement.type;

    node.expression.accept(this);
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    SimpleIdentifier label = node.label;
    if (label != null) {
      LabelElement labelElement = _labelScope[label.name];
      label.staticElement = labelElement;
    }
  }

  @override
  void visitExpression(Expression node) {
    visitNode(node);
    node.staticType = _getTypeFor(node);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable != null) {
      SimpleIdentifier identifier = loopVariable.identifier;

      DartType type = _getTypeFor(identifier);
      identifier.staticType = type;

      if (loopVariable.type != null) {
        applyToTypeAnnotation(
            _enclosingLibraryElement, type, loopVariable.type);
      }

      VariableElementImpl element = _getDeclarationFor(identifier);
      if (element != null) {
        _typeContext.encloseVariable(element);
        identifier.staticElement = element;
        element.type = type;
      }
    } else {
      node.identifier.staticElement = _getReferenceFor(node.identifier);
      node.identifier.staticType = _getTypeFor(node.identifier);
    }
    node.iterable.accept(this);
    node.body.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList parameterList) {
    for (var parameter in parameterList.parameters) {
      if (parameter is DefaultFormalParameter) {
        if (parameter.defaultValue == null) {
          // Consume the Null type, for the implicit default value.
          _getTypeFor(null, synthetic: true);
        } else {
          parameter.defaultValue.accept(this);
        }
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression functionExpression = node.functionExpression;
    FormalParameterList parameterList = functionExpression.parameters;

    // Apply resolution to default values.
    parameterList.accept(this);

    FunctionElementImpl element = _getDeclarationFor(node);
    _typeContext.enterLocalFunction(element);

    if (node.returnType != null && element != null) {
      applyToTypeAnnotation(
          _enclosingLibraryElement, element.returnType, node.returnType);
    }

    // Associate the elements with the nodes.
    if (element != null) {
      functionExpression.element = element;

      node.name.staticElement = element;
      node.name.staticType = element.type;

      TypeParameterList typeParameterList = functionExpression.typeParameters;
      if (typeParameterList != null) {
        List<TypeParameter> typeParameters = typeParameterList.typeParameters;
        for (var i = 0; i < typeParameters.length; i++) {
          TypeParameter typeParameter = typeParameters[i];
          assert(typeParameter.bound == null);
          typeParameter.name.staticElement = element.typeParameters[i];
          typeParameter.name.staticType = _typeContext.typeType;
        }
      }

      applyParameters(
          _enclosingLibraryElement, element.parameters, parameterList);
    }

    functionExpression.body?.accept(this);
    _typeContext.exitLocalFunction(element);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    FormalParameterList parameterList = node.parameters;

    FunctionElementImpl element = _getDeclarationFor(node);
    _typeContext.enterLocalFunction(element);

    // Associate the elements with the nodes.
    if (element != null) {
      node.element = element;
      node.staticType = element.type;
      applyParameters(
          _enclosingLibraryElement, element.parameters, parameterList);
    }

    // Apply resolution to default values.
    parameterList.accept(this);

    node.body.accept(this);
    _typeContext.exitLocalFunction(element);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);

    DartType invokeType = _getTypeFor(node.argumentList);
    node.staticInvokeType = invokeType;

    DartType typeArgumentsDartType = _getTypeFor(node.argumentList);
    if (node.typeArguments != null &&
        typeArgumentsDartType is TypeArgumentsDartType) {
      _applyTypeArgumentsToList(_enclosingLibraryElement, typeArgumentsDartType,
          node.typeArguments.arguments);
    }

    DartType resultType = _getTypeFor(node.argumentList);
    node.staticType = resultType;

    node.argumentList.accept(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target.accept(this);

    DartType targetType = node.target.staticType;
    MethodElement element = _getReferenceFor(node.leftBracket);

    // Convert the raw element into a member.
    if (targetType is InterfaceType) {
      MethodElement member = MethodMember.from(element, targetType);
      node.staticElement = member;
    }

    _getTypeFor(node.leftBracket); // callee type
    _getTypeFor(node.leftBracket); // invoke type
    _getTypeFor(node.leftBracket); // type arguments

    node.staticType = _getTypeFor(node.leftBracket);

    node.index.accept(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;

    // Peek forward and check if the next element is a PrefixElement.
    PrefixElement prefix;
    AstNode constructorEntity = constructorName;
    if (_referencedElements[_referencedElementIndex] is PrefixElement) {
      PrefixedIdentifier typeIdentifier = constructorName.type.name;
      prefix = _getReferenceFor(typeIdentifier.prefix);
      _getTypeFor(typeIdentifier.prefix); // prefix type
      constructorEntity = typeIdentifier.identifier;
    }

    ConstructorElement constructor = _getReferenceFor(constructorEntity);
    DartType type = _getTypeFor(constructorEntity);

    applyConstructorElement(
        _enclosingLibraryElement, prefix, constructor, type, constructorName);

    node.staticElement = constructor;
    node.staticType = type;

    ArgumentList argumentList = node.argumentList;
    _applyResolutionToArguments(argumentList);
    _resolveNamedArguments(argumentList, constructor?.parameters);
  }

  @override
  void visitIsExpression(IsExpression node) {
    node.expression.accept(this);
    applyToTypeAnnotation(
        _enclosingLibraryElement, _getTypeFor(node.isOperator), node.type);
    node.staticType = _getTypeFor(node.isOperator);
  }

  @override
  void visitLabel(Label node) {
    SimpleIdentifier label = node.label;
    String name = label.name;
    var element = new LabelElementImpl(name, label.offset, false, false);
    _labelScope.add(name, element);
    label.staticElement = element;
  }

  @override
  void visitListLiteral(ListLiteral node) {
    node.elements.accept(this);
    DartType type = _getTypeFor(node.constKeyword ?? node.leftBracket);
    node.staticType = type;
    if (node.typeArguments != null) {
      _applyTypeArgumentsToList(
          _enclosingLibraryElement, type, node.typeArguments.arguments);
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    node.entries.accept(this);
    DartType type = _getTypeFor(node.constKeyword ?? node.leftBracket);
    node.staticType = type;
    if (node.typeArguments != null) {
      _applyTypeArgumentsToList(
          _enclosingLibraryElement, type, node.typeArguments.arguments);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);

    ArgumentList argumentList = node.argumentList;

    Element invokeElement = _getReferenceFor(node.methodName);
    _getTypeFor(node.methodName); // static element type
    DartType invokeType = _getTypeFor(argumentList);
    DartType typeArgumentsDartType = _getTypeFor(argumentList);
    DartType resultType = _getTypeFor(argumentList);

    if (invokeElement is PropertyInducingElement) {
      PropertyInducingElement property = invokeElement;
      invokeElement = property.getter;
    }

    node.staticInvokeType = invokeType;
    node.staticType = resultType;

    if (node.methodName.name == 'call' && invokeElement == null) {
      // Don't resolve explicit call() invocation of function types.
    } else {
      node.methodName.staticElement = invokeElement;
      node.methodName.staticType = invokeType;
    }

    if (invokeType is FunctionType) {
      if (node.typeArguments != null &&
          typeArgumentsDartType is TypeArgumentsDartType) {
        _applyTypeArgumentsToList(_enclosingLibraryElement,
            typeArgumentsDartType, node.typeArguments.arguments);
      }
    }

    _applyResolutionToArguments(argumentList);

    {
      var elementForParameters = invokeElement;
      if (elementForParameters is PropertyAccessorElement) {
        PropertyAccessorElement accessor = elementForParameters;
        elementForParameters = accessor.returnType.element;
      }
      if (elementForParameters is FunctionTypedElement) {
        List<ParameterElement> parameters = elementForParameters.parameters;
        _resolveNamedArguments(argumentList, parameters);
      }
    }
  }

  @override
  void visitNativeFunctionBody(NativeFunctionBody node) {
    // nothing to resolve
  }

  @override
  void visitParenthesizedExpression(ParenthesizedExpression node) {
    node.visitChildren(this);
    node.staticType = node.expression.staticType;
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    node.operand.accept(this);
    SyntacticEntity entity = _getAssignmentEntity(node.operand);
    node.staticElement = _getReferenceFor(entity);
    node.staticType = _getTypeFor(entity);
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    node.prefix.accept(this);
    node.identifier.accept(this);
    node.staticType = node.identifier.staticType;
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
    node.operand.accept(this);
    TokenType tokenType = node.operator.type;
    if (tokenType.isIncrementOperator) {
      // ++v;
      // This is an assignment, it is associated with the operand.
      SyntacticEntity entity = _getAssignmentEntity(node.operand);
      node.staticElement = _getReferenceFor(entity);
      node.staticType = _getTypeFor(entity);
    } else if (tokenType == TokenType.BANG) {
      // !boolExpression;
      node.staticType = _getTypeFor(node);
    } else {
      // ~v;
      // This is a method invocation, it is associated with the operator.
      SyntacticEntity entity = node.operator;
      node.staticElement = _getReferenceFor(entity);
      _getTypeFor(entity); // The static function type of the operator.
      _getTypeFor(entity); // The invoke function type of the operator.
      _getTypeFor(entity); // The type arguments (empty).
      node.staticType = _getTypeFor(entity);
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    node.target?.accept(this);
    node.propertyName.accept(this);
    node.staticType = node.propertyName.staticType;
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    SimpleIdentifier constructorName = node.constructorName;

    ConstructorElement element = _getReferenceFor(constructorName ?? node);
    node.staticElement = element;
    constructorName?.staticElement = element;

    ArgumentList argumentList = node.argumentList;
    _applyResolutionToArguments(argumentList);
    _resolveNamedArguments(argumentList, element?.parameters);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    node.staticElement = _getReferenceFor(node);
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    for (var element in node.elements) {
      if (element is InterpolationString) {
        if (element.value.isNotEmpty) {
          _getTypeFor(element);
        }
      } else if (element is InterpolationExpression) {
        element.expression.accept(this);
      }
    }
    node.staticType = _typeContext.stringType;
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    SimpleIdentifier constructorName = node.constructorName;
    var superElement = _typeContext.enclosingClassElement.supertype.element;
    ConstructorElement element;
    if (constructorName == null) {
      element = superElement.unnamedConstructor;
    } else {
      String name = constructorName.name;
      element = superElement.getNamedConstructor(name);
      constructorName.staticElement = element;
    }
    node.staticElement = element;

    ArgumentList argumentList = node.argumentList;
    _applyResolutionToArguments(argumentList);
    _resolveNamedArguments(argumentList, element?.parameters);
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    node.staticType = _typeContext.enclosingClassElement?.type;
  }

  @override
  void visitThisExpression(ThisExpression node) {
    node.staticType = _typeContext.enclosingClassElement?.type;
  }

  @override
  void visitTypeAnnotation(TypeAnnotation node) {
    applyToTypeAnnotation(_enclosingLibraryElement, _getTypeFor(node), node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    AstNode parent = node.parent;
    if (parent is VariableDeclarationList &&
        (parent.parent is TopLevelVariableDeclaration ||
            parent.parent is FieldDeclaration)) {
      // Don't visit the name; resolution for it will come from the outline.
    } else {
      DartType type = _getTypeFor(node.name);
      node.name.staticType = type;

      VariableElementImpl element = _getDeclarationFor(node.name);
      if (element != null) {
        _typeContext.encloseVariable(element);
        node.name.staticElement = element;
        element.type = type;
      }
    }
    node.initializer?.accept(this);
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.parent is TopLevelVariableDeclaration) {
      node.variables.accept(this);
    } else {
      if (node.metadata.isNotEmpty) {
        // TODO(paulberry): handle this case
        throw new UnimplementedError('Metadata on a variable declaration list');
      }
      node.variables.accept(this);
      if (node.type != null) {
        DartType type = node.variables[0].name.staticType;
        // TODO(brianwilkerson) Understand why the type is sometimes `null`.
        if (type != null) {
          applyToTypeAnnotation(_enclosingLibraryElement, type, node.type);
        }
      }
    }
  }

  /// Apply resolution to arguments of the [argumentList].
  void _applyResolutionToArguments(ArgumentList argumentList) {
    for (var argument in argumentList.arguments) {
      if (argument is NamedExpression) {
        argument.expression.accept(this);
      } else {
        argument.accept(this);
      }
    }
  }

  /// Return the [SyntacticEntity] with which the front-end associates
  /// assignment to the given [leftHandSide].
  SyntacticEntity _getAssignmentEntity(Expression leftHandSide) {
    if (leftHandSide is SimpleIdentifier) {
      return leftHandSide;
    } else if (leftHandSide is PrefixedIdentifier) {
      return leftHandSide.identifier;
    } else if (leftHandSide is PropertyAccess) {
      return leftHandSide.propertyName;
    } else if (leftHandSide is IndexExpressionImpl) {
      return leftHandSide.leftBracket;
    } else {
      throw new StateError(
          'Unexpected LHS (${leftHandSide.runtimeType}) $leftHandSide');
    }
  }

  /// Return the element associated with the declaration represented by the
  /// given [node].
  Element _getDeclarationFor(AstNode node) {
    return _declaredElements[_declaredElementIndex++];
  }

  /// Return the element associated with the reference represented by the
  /// given [entity].
  Element _getReferenceFor(SyntacticEntity entity) {
    Element element = _referencedElements[_referencedElementIndex++];
    if (_inAnnotation && element is PropertyInducingElement) {
      return element.getter;
    }
    return element;
  }

  /// Return the type associated with the given [entity].
  ///
  /// If [synthetic] is `true`, the [entity] must be `null` and the type is
  /// an implicit type, e.g. the type of the absent default values of an
  /// optional parameter (i.e. [Null]).
  DartType _getTypeFor(SyntacticEntity entity, {bool synthetic: false}) {
    assert(!synthetic || entity == null);
    kernel.DartType kernelType = _types[_typeIndex++];
    return _typeContext.translateType(kernelType);
  }

  /// Apply resolution to named arguments of the [argumentList].
  void _resolveNamedArguments(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    if (parameters != null) {
      for (var argument in argumentList.arguments) {
        if (argument is NamedExpression) {
          SimpleIdentifier identifier = argument.name.label;
          for (var parameter in parameters) {
            if (parameter.name == identifier.name) {
              identifier.staticElement = parameter;
              break;
            }
          }
        }
      }
    }
  }

  /// Apply the [type] that is created by the [constructorName] and the
  /// [constructorElement] it references.
  static void applyConstructorElement(
      LibraryElement enclosingLibraryElement,
      PrefixElement prefixElement,
      ConstructorElement constructorElement,
      DartType type,
      ConstructorName constructorName) {
    constructorName.staticElement = constructorElement;

    ClassElement classElement = constructorElement?.enclosingElement;

    Identifier typeIdentifier = constructorName.type.name;
    if (prefixElement != null) {
      PrefixedIdentifier prefixedTypeIdentifier = typeIdentifier;
      prefixedTypeIdentifier.staticType = type;

      prefixedTypeIdentifier.prefix.staticElement = prefixElement;

      SimpleIdentifier classNode = prefixedTypeIdentifier.identifier;
      classNode.staticElement = classElement;
      classNode.staticType = type;
    } else {
      if (typeIdentifier is SimpleIdentifier) {
        typeIdentifier.staticElement = classElement;
        typeIdentifier.staticType = type;
      } else if (typeIdentifier is PrefixedIdentifier) {
        constructorName.type = astFactory.typeName(typeIdentifier.prefix, null);
        constructorName.period = typeIdentifier.period;
        constructorName.name = typeIdentifier.identifier;
      }
    }

    constructorName.name?.staticElement = constructorElement;

    applyToTypeAnnotation(enclosingLibraryElement, type, constructorName.type);
  }

  /// Apply the types of the [parameterElements] to the [parameterList] that
  /// have an explicit type annotation.
  static void applyParameters(
      LibraryElement enclosingLibraryElement,
      List<ParameterElement> parameterElements,
      FormalParameterList parameterList) {
    List<FormalParameter> parameters = parameterList.parameters;

    int length = parameterElements.length;
    if (parameters.length != length) {
      throw new StateError('Parameter counts do not match');
    }
    for (int i = 0; i < length; i++) {
      ParameterElementImpl element = parameterElements[i];
      FormalParameter parameter = parameters[i];

      NormalFormalParameter normalParameter;
      if (parameter is NormalFormalParameter) {
        normalParameter = parameter;
      } else if (parameter is DefaultFormalParameter) {
        normalParameter = parameter.parameter;
      }
      assert(normalParameter != null);

      if (normalParameter is SimpleFormalParameterImpl) {
        normalParameter.element = element;
      }

      if (normalParameter.identifier != null) {
        element.nameOffset = normalParameter.identifier.offset;
        normalParameter.identifier.staticElement = element;
        normalParameter.identifier.staticType = element.type;
      }

      // Apply the type or the return type, if a function typed parameter.
      TypeAnnotation functionReturnType;
      FormalParameterList functionParameterList;
      if (normalParameter is SimpleFormalParameter) {
        applyToTypeAnnotation(
            enclosingLibraryElement, element.type, normalParameter.type);
      } else if (normalParameter is FunctionTypedFormalParameter) {
        functionReturnType = normalParameter.returnType;
        functionParameterList = normalParameter.parameters;
      } else if (normalParameter is FieldFormalParameter) {
        if (normalParameter.parameters == null) {
          applyToTypeAnnotation(
              enclosingLibraryElement, element.type, normalParameter.type);
        } else {
          functionReturnType = normalParameter.type;
          functionParameterList = normalParameter.parameters;
        }
      }

      if (functionParameterList != null) {
        FunctionType elementType = element.type;
        if (functionReturnType != null) {
          applyToTypeAnnotation(enclosingLibraryElement, elementType.returnType,
              functionReturnType);
        }
        applyParameters(enclosingLibraryElement, elementType.parameters,
            functionParameterList);
      }
    }
  }

  /// Apply the [type] to the [typeAnnotation] by setting the type of the
  /// [typeAnnotation] to the [type] and recursively applying each of the type
  /// arguments of the [type] to the corresponding type arguments of the
  /// [typeAnnotation].
  static void applyToTypeAnnotation(LibraryElement enclosingLibraryElement,
      DartType type, TypeAnnotation typeAnnotation) {
    if (typeAnnotation is GenericFunctionTypeImpl) {
      if (type is! FunctionType) {
        throw new StateError('Non-function type ($type) '
            'for generic function annotation ($typeAnnotation)');
      }
      FunctionType functionType = type;
      typeAnnotation.type = type;
      applyToTypeAnnotation(enclosingLibraryElement, functionType.returnType,
          typeAnnotation.returnType);
      applyParameters(enclosingLibraryElement, functionType.parameters,
          typeAnnotation.parameters);
    } else if (typeAnnotation is TypeNameImpl) {
      typeAnnotation.type = type;

      Identifier typeIdentifier = typeAnnotation.name;
      SimpleIdentifier typeName;
      if (typeIdentifier is PrefixedIdentifier) {
        if (enclosingLibraryElement != null) {
          String prefixName = typeIdentifier.prefix.name;
          for (var import in enclosingLibraryElement.imports) {
            if (import.prefix?.name == prefixName) {
              typeIdentifier.prefix.staticElement = import.prefix;
              break;
            }
          }
        }
        typeName = typeIdentifier.identifier;
      } else {
        typeName = typeIdentifier;
      }

      Element typeElement = type.element;
      if (typeElement is GenericFunctionTypeElement &&
          typeElement.enclosingElement is GenericTypeAliasElement) {
        typeElement = typeElement.enclosingElement;
      }

      typeName.staticElement = typeElement;
      typeName.staticType = type;
    }
    if (typeAnnotation is NamedType) {
      TypeArgumentList typeArguments = typeAnnotation.typeArguments;
      if (typeArguments != null) {
        _applyTypeArgumentsToList(
            enclosingLibraryElement, type, typeArguments.arguments);
      }
    }
  }

  /// Recursively apply each of the type arguments of the [type] to the
  /// corresponding type arguments of the [typeArguments].
  static void _applyTypeArgumentsToList(LibraryElement enclosingLibraryElement,
      DartType type, List<TypeAnnotation> typeArguments) {
    if (type != null && type.isUndefined) {
      for (TypeAnnotation argument in typeArguments) {
        applyToTypeAnnotation(enclosingLibraryElement, type, argument);
      }
    } else if (type is ParameterizedType) {
      List<DartType> argumentTypes = type.typeArguments;
      int argumentCount = argumentTypes.length;
      if (argumentCount != typeArguments.length) {
        throw new StateError('Found $argumentCount argument types '
            'for ${typeArguments.length} type arguments');
      }
      for (int i = 0; i < argumentCount; i++) {
        applyToTypeAnnotation(
            enclosingLibraryElement, argumentTypes[i], typeArguments[i]);
      }
    } else {
      throw new StateError('Attempting to apply a non-parameterized type '
          '(${type.runtimeType}) to type arguments');
    }
  }
}

/// A container with [typeArguments].
class TypeArgumentsDartType implements ParameterizedType {
  @override
  final List<DartType> typeArguments;

  TypeArgumentsDartType(this.typeArguments);

  @override
  bool get isUndefined => false;

  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() {
    return '<${typeArguments.join(', ')}>';
  }
}

/// Context for translating types.
abstract class TypeContext {
  /// The enclosing [ClassElement], or `null` if not in a class.
  ClassElement get enclosingClassElement;

  DartType get stringType;

  DartType get typeType;

  /// Attach the variable [element] to the current executable.
  void encloseVariable(ElementImpl element);

  /// Finalize the given function [element] - set all types for it.
  /// Then make it the current executable.
  void enterLocalFunction(FunctionElementImpl element);

  /// Restore the current executable that was before the [element].
  void exitLocalFunction(FunctionElementImpl element);

  /// Return the Analyzer [DartType] for the given [kernelType].
  DartType translateType(kernel.DartType kernelType);
}

/// Visitor that applies resolution data from the front end (obtained via
/// [ResolutionStorer]) to an analyzer AST, and also checks file offsets to
/// verify that the types are applied to the correct subexpressions.
class ValidatingResolutionApplier extends ResolutionApplier {
  /// The offset that is used when the actual offset is not know.
  /// The applier should not validate this offset.
  static const UNKNOWN_OFFSET = -2;

  /// Indicates whether debug messages should be printed.
  static const bool _debug = false;

  final List<int> _declaredElementOffsets;
  final List<int> _referencedElementOffsets;
  final List<int> _typeOffsets;

  ValidatingResolutionApplier(
      LibraryElement enclosingLibraryElement,
      TypeContext typeContext,
      List<Element> declaredElements,
      List<Element> referencedElements,
      List<kernel.DartType> types,
      this._declaredElementOffsets,
      this._referencedElementOffsets,
      this._typeOffsets)
      : super(enclosingLibraryElement, typeContext, declaredElements,
            referencedElements, types);

  @override
  void checkDone() {
    if (_declaredElementIndex != _declaredElements.length) {
      throw new StateError('Some declarations were not consumed, starting at '
          'offset ${_declaredElementOffsets[_declaredElementIndex]}');
    }
    if (_referencedElementIndex != _referencedElements.length) {
      throw new StateError('Some references were not consumed, starting at '
          'offset ${_referencedElementOffsets[_referencedElementIndex]}');
    }
    if (_typeIndex != _types.length) {
      throw new StateError('Some types were not consumed, starting at offset '
          '${_typeOffsets[_typeIndex]}');
    }
  }

  @override
  Element _getDeclarationFor(AstNode node) {
    int nodeOffset = node.offset;
    if (_debug) {
      print('Getting declaration element for $node at $nodeOffset');
    }
    if (_declaredElementIndex >= _declaredElements.length) {
      throw new StateError(
          'No declaration information for $node at $nodeOffset');
    }
    int elementOffset = _declaredElementOffsets[_declaredElementIndex];
    if (nodeOffset != elementOffset) {
      throw new StateError(
          'Expected element declaration for analyzer offset $nodeOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getDeclarationFor(node);
  }

  @override
  Element _getReferenceFor(SyntacticEntity entity) {
    int entityOffset = entity.offset;
    if (_debug) {
      print('Getting reference element for $entity at $entityOffset');
    }
    if (_referencedElementIndex >= _referencedElements.length) {
      throw new StateError(
          'No reference information for $entity at $entityOffset');
    }
    int elementOffset = _referencedElementOffsets[_referencedElementIndex];
    if (elementOffset != UNKNOWN_OFFSET && entityOffset != elementOffset) {
      throw new StateError(
          'Expected element reference for analyzer offset $entityOffset; '
          'got one for kernel offset $elementOffset');
    }
    return super._getReferenceFor(entity);
  }

  @override
  DartType _getTypeFor(SyntacticEntity entity, {bool synthetic: false}) {
    var entityOffset = synthetic ? -1 : entity.offset;
    if (_debug) {
      print('Getting type for $entity at $entityOffset');
    }
    if (_typeIndex >= _types.length) {
      throw new StateError('No type information for $entity at $entityOffset');
    }
    int typeOffset = _typeOffsets[_typeIndex];
    if (typeOffset != UNKNOWN_OFFSET &&
        entity != null &&
        entityOffset != typeOffset) {
      throw new StateError('Expected a type for $entity at $entityOffset; '
          'got one for kernel offset $typeOffset');
    }
    return super._getTypeFor(entity);
  }
}

/// The hierarchical scope for labels.
class _LabelScope {
  final _LabelScope parent;
  final Map<String, LabelElement> elements = {};

  _LabelScope(this.parent);

  LabelElement operator [](String name) {
    var element = elements[name];
    if (element != null) {
      return element;
    }
    if (parent != null) {
      return parent[name];
    }
    return null;
  }

  void add(String name, LabelElement element) {
    elements[name] = element;
  }
}
