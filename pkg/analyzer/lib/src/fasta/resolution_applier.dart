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

  final Map<int, ResolutionData<DartType, Element, Element, PrefixElement>>
      _data;

  /// The current label scope. Each [Block] adds a new one.
  _LabelScope _labelScope = new _LabelScope(null);

  ResolutionApplier(
      this._enclosingLibraryElement, this._typeContext, this._data);

  /// Apply resolution to annotations of the given [node].
  void applyToAnnotations(AnnotatedNode node) {
    node.metadata.accept(this);
  }

  @override
  void visitAdjacentStrings(AdjacentStrings node) {
    node.strings.accept(this);
    node.staticType = _typeContext.stringType;
  }

  @override
  void visitAnnotation(Annotation node) {
    SimpleIdentifier constructorName = node.constructorName;
    SyntacticEntity entity;
    if (constructorName != null) {
      entity = constructorName;
    } else {
      var name = node.name;
      if (name is PrefixedIdentifier) {
        entity = name.identifier;
      } else {
        entity = name;
      }
    }
    var data = _get(entity);

    SimpleIdentifier topEntity;
    if (data.prefixInfo != null) {
      PrefixedIdentifier prefixedIdentifier = node.name;

      SimpleIdentifier prefix = prefixedIdentifier.prefix;
      prefix.staticElement = data.prefixInfo;

      topEntity = prefixedIdentifier.identifier;
    } else {
      topEntity = node.name;
    }

    Element element = data.reference;
    DartType type = data.inferredType;
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

  ResolutionData<DartType, Element, Element, PrefixElement> _get(
      SyntacticEntity entity,
      {bool failIfAbsent: true}) {
    int entityOffset = entity.offset;
    var data = _data[entityOffset];
    if (failIfAbsent && data == null) {
      throw new StateError('No data for $entity at $entityOffset');
    }
    return data;
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.expression.accept(this);
    var data = _get(node.asOperator);
    applyToTypeAnnotation(
        _enclosingLibraryElement, data.literalType, node.type);
    node.staticType = data.inferredType;
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);

    SyntacticEntity entity = _getAssignmentEntity(node.leftHandSide);
    var data = _get(entity);
    node.staticElement = data.combiner;
    node.staticType = data.inferredType;
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);

    var data = _get(node.operator);
    TokenType operatorType = node.operator.type;
    if (operatorType != TokenType.QUESTION_QUESTION &&
        operatorType != TokenType.AMPERSAND_AMPERSAND &&
        operatorType != TokenType.BAR_BAR) {
      node.staticElement = data.reference;
    }

    // Record the return type of the expression.
    node.staticType = data.inferredType;

    node.rightOperand.accept(this);
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
    DartType guardType = _get(node.onKeyword ?? node.catchKeyword).literalType;
    if (node.exceptionType != null) {
      applyToTypeAnnotation(
          _enclosingLibraryElement, guardType, node.exceptionType);
    }

    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      LocalVariableElementImpl element = exception.staticElement;
      DartType type = _get(exception).literalType;
      element.type = type;
      exception.staticElement = element;
      exception.staticType = type;
    }

    SimpleIdentifier stackTrace = node.stackTraceParameter;
    if (stackTrace != null) {
      LocalVariableElementImpl element = stackTrace.staticElement;
      DartType type = _get(stackTrace).literalType;
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
    node.staticType = _get(node.question).inferredType;
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var element = _get(node.equals).reference;
    FieldElement fieldElement =
        element is PropertyAccessorElement ? element.variable : null;
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
    node.staticType = _get(node).inferredType;
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable != null) {
      SimpleIdentifier identifier = loopVariable.identifier;

      DartType type = _get(identifier).inferredType;
      identifier.staticType = type;

      if (loopVariable.type != null) {
        applyToTypeAnnotation(
            _enclosingLibraryElement, type, loopVariable.type);
      }

      VariableElementImpl element = identifier.staticElement;
      if (element != null) {
        _typeContext.encloseVariable(element);
        identifier.staticElement = element;
        element.type = type;
      }
    } else {
      node.identifier.accept(this);
    }
    node.iterable.accept(this);
    node.body.accept(this);
  }

  @override
  void visitFormalParameterList(FormalParameterList parameterList) {
    for (var parameter in parameterList.parameters) {
      if (parameter is DefaultFormalParameter) {
        if (parameter.defaultValue != null) {
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

    FunctionElementImpl element = node.element;
    _typeContext.enterLocalFunction(element);

    functionExpression.body?.accept(this);
    _storeFunctionType(_get(node).inferredType, element);

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

      applyToTypeAnnotation(
          _enclosingLibraryElement, element.returnType, node.returnType);
      applyParameters(
          _enclosingLibraryElement, element.parameters, parameterList);
    }

    _typeContext.exitLocalFunction(element);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    FormalParameterList parameterList = node.parameters;

    FunctionElementImpl element = node.element;
    _typeContext.enterLocalFunction(element);

    // Apply resolution to default values.
    parameterList.accept(this);

    node.body.accept(this);
    _storeFunctionType(_get(node).inferredType, element);

    // Associate the elements with the nodes.
    if (element != null) {
      node.element = element;
      node.staticType = element.type;
      applyParameters(
          _enclosingLibraryElement, element.parameters, parameterList);
    }

    _typeContext.exitLocalFunction(element);
  }

  void _storeFunctionType(DartType type, FunctionElementImpl element) {
    if (type is FunctionType && element != null) {
      element.returnType = type.returnType;
      int normalParameterIndex = 0;
      int optionalParameterIndex = 0;
      for (ParameterElementImpl parameter in element.parameters) {
        if (parameter.isNamed) {
          parameter.type = type.namedParameterTypes[parameter.name];
        } else if (normalParameterIndex < type.normalParameterTypes.length) {
          parameter.type = type.normalParameterTypes[normalParameterIndex++];
        } else if (optionalParameterIndex <
            type.optionalParameterTypes.length) {
          parameter.type =
              type.optionalParameterTypes[optionalParameterIndex++];
        }
      }
    }
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);

    var data = _get(node.argumentList);
    DartType invokeType = data.invokeType;
    node.staticInvokeType = invokeType;

    List<DartType> typeArguments = data.argumentTypes;
    if (node.typeArguments != null && typeArguments is TypeArgumentsDartType) {
      _applyTypeArgumentsToList(
          _enclosingLibraryElement,
          new TypeArgumentsDartType(typeArguments),
          node.typeArguments.arguments);
    }

    DartType resultType = data.inferredType;
    node.staticType = resultType;

    node.argumentList.accept(this);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target.accept(this);

    DartType targetType = node.target.staticType;
    var data = _get(node.leftBracket);
    MethodElement element = data.reference;

    // Convert the raw element into a member.
    if (targetType is InterfaceType) {
      MethodElement member = MethodMember.from(element, targetType);
      node.staticElement = member;
    }

    node.staticType = data.inferredType;

    node.index.accept(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    var data = _get(constructorName);

    PrefixElement prefix = data.prefixInfo;

    ConstructorElement constructor = data.reference;
    DartType type = data.inferredType;

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
    var data = _get(node.isOperator);
    applyToTypeAnnotation(
        _enclosingLibraryElement, data.literalType, node.type);
    node.staticType = data.inferredType;
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
    DartType type = _get(node.constKeyword ?? node.leftBracket).inferredType;
    node.staticType = type;
    if (node.typeArguments != null) {
      _applyTypeArgumentsToList(
          _enclosingLibraryElement, type, node.typeArguments.arguments);
    }
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    node.entries.accept(this);
    DartType type = _get(node.constKeyword ?? node.leftBracket).inferredType;
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

    var data = _get(argumentList);
    Element invokeElement;
    if (data.isImplicitCall) {
      if (node.methodName != null) {
        node.methodName.accept(this);
        invokeElement = node.methodName.staticElement;
      }
    } else {
      invokeElement = data.reference;
    }
    DartType invokeType = data.invokeType;
    List<DartType> typeArguments = data.argumentTypes;
    DartType resultType = data.inferredType;

    if (invokeElement is PropertyInducingElement) {
      PropertyInducingElement property = invokeElement;
      invokeElement = property.getter;
    }

    node.staticInvokeType = invokeType;
    node.staticType = resultType;

    if (node.methodName.name == 'call' && invokeElement == null) {
      // Don't resolve explicit call() invocation of function types.
    } else if (_get(node.methodName, failIfAbsent: false) != null) {
      node.methodName.accept(this);
    } else {
      node.methodName.staticElement = invokeElement;
      node.methodName.staticType = invokeType;
    }

    if (invokeType is FunctionType) {
      if (node.typeArguments != null && typeArguments != null) {
        _applyTypeArgumentsToList(
            _enclosingLibraryElement,
            new TypeArgumentsDartType(typeArguments),
            node.typeArguments.arguments);
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
    var data = _get(entity);
    node.staticElement = data.combiner;
    node.staticType = data.inferredType;
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
      var data = _get(entity);
      node.staticElement = data.combiner;
      node.staticType = data.inferredType;
    } else if (tokenType == TokenType.BANG) {
      // !boolExpression;
      node.staticType = _get(node).inferredType;
    } else {
      // ~v;
      // This is a method invocation, it is associated with the operator.
      SyntacticEntity entity = node.operator;
      var data = _get(entity);
      node.staticElement = data.reference;
      node.staticType = data.inferredType;
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

    ConstructorElement element = _get(constructorName ?? node).reference;
    node.staticElement = element;
    constructorName?.staticElement = element;

    ArgumentList argumentList = node.argumentList;
    _applyResolutionToArguments(argumentList);
    _resolveNamedArguments(argumentList, element?.parameters);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var data = _get(node);
    if (data.prefixInfo != null) {
      node.staticElement = data.prefixInfo;
    } else if (data.declaration != null) {
      node.staticElement = data.declaration;
    } else if (data.reference != null) {
      node.staticElement = data.reference;
    } else {
      node.staticElement = null;
    }
    node.staticType =
        data.isWriteReference ? data.writeContext : data.inferredType;
  }

  @override
  void visitStringInterpolation(StringInterpolation node) {
    for (var element in node.elements) {
      if (element is InterpolationExpression) {
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
  void visitVariableDeclaration(VariableDeclaration node) {
    AstNode parent = node.parent;
    if (parent is VariableDeclarationList &&
        (parent.parent is TopLevelVariableDeclaration ||
            parent.parent is FieldDeclaration)) {
      // Don't visit the name; resolution for it will come from the outline.
    } else {
      DartType type = _get(node.name).inferredType;
      node.name.staticType = type;

      VariableElementImpl element = node.name.staticElement;
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
