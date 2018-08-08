// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
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

  final Map<int, ResolutionData> _data;

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
    Identifier name = node.name;
    ArgumentList argumentList = node.arguments;

    SimpleIdentifier fieldName;
    SimpleIdentifier constructorName;

    var data = _get(name);
    if (name is SimpleIdentifier) {
      var translatedReference = _translateReference(data);
      name.staticElement = translatedReference;
      name.staticType = _translateType(data.inferredType);
      node.element = translatedReference;
    } else if (name is PrefixedIdentifier) {
      if (data.prefixInfo != null) {
        name.prefix.staticElement = _translatePrefixInfo(data.prefixInfo);

        data = _get(name.identifier);
        name.identifier.staticElement = _translateReference(data);
        name.identifier.staticType = _translateType(data.inferredType);

        if (argumentList == null) {
          fieldName = node.constructorName;
        } else {
          constructorName = node.constructorName;
        }
      } else {
        name.prefix.staticElement = _translateReference(data);
        name.prefix.staticType = _translateType(data.inferredType);

        if (argumentList == null) {
          fieldName = name.identifier;
        } else {
          constructorName = name.identifier;
        }
      }
    }

    if (fieldName != null) {
      data = _get(fieldName);
      var translatedReference = _translateReference(data);
      node.element = translatedReference;
      fieldName.staticElement = translatedReference;
      fieldName.staticType = _translateType(data.inferredType);
    }

    if (argumentList != null) {
      var data = _get(argumentList);
      ConstructorElement element = _translateReference(data);
      node.element = element;

      if (constructorName != null) {
        constructorName.staticElement = element;
        constructorName.staticType = element.type;
      }

      argumentList.accept(this);
      _resolveArgumentsToParameters(argumentList, element.parameters);
    }
  }

  @override
  void visitArgumentList(ArgumentList node) {
    for (var argument in node.arguments) {
      if (argument is NamedExpression) {
        argument.expression.accept(this);
        argument.staticType = argument.expression.staticType;
      } else {
        argument.accept(this);
      }
    }
  }

  @override
  void visitAsExpression(AsExpression node) {
    node.expression.accept(this);
    node.type.accept(this);
    var data = _get(node.asOperator);
    node.staticType = _translateType(data.inferredType);
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    node.leftHandSide.accept(this);
    node.rightHandSide.accept(this);

    SyntacticEntity entity = _getAssignmentEntity(node.leftHandSide);
    var data = _get(entity);
    node.staticElement = _translateAuxiliaryReference(data.combiner);
    node.staticType = _translateType(data.inferredType);
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    node.leftOperand.accept(this);

    var data = _get(node.operator);
    TokenType operatorType = node.operator.type;
    if (operatorType != TokenType.QUESTION_QUESTION &&
        operatorType != TokenType.AMPERSAND_AMPERSAND &&
        operatorType != TokenType.BAR_BAR) {
      node.staticElement = _translateReference(data);
    }

    // Record the return type of the expression.
    node.staticType = _translateType(data.inferredType);

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
    node.exceptionType?.accept(this);
    SimpleIdentifier exception = node.exceptionParameter;
    if (exception != null) {
      LocalVariableElementImpl element = exception.staticElement;
      DartType type = _translateType(
          _get(exception, isSynthetic: exception.isSynthetic).inferredType);
      element.type = type;
      exception.staticType = type;
    }

    SimpleIdentifier stackTrace = node.stackTraceParameter;
    if (stackTrace != null) {
      LocalVariableElementImpl element = stackTrace.staticElement;
      DartType type = _translateType(_get(stackTrace).inferredType);
      element.type = type;
      stackTrace.staticType = type;
    }

    node.body.accept(this);
  }

  @override
  void visitConditionalExpression(ConditionalExpression node) {
    node.condition.accept(this);
    node.thenExpression.accept(this);
    node.elseExpression.accept(this);
    node.staticType = _translateType(_get(node.question).inferredType);
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var element = _translateReference(_get(node.equals));
    if (element is PropertyAccessorElement) {
      node.fieldName.staticElement = element.variable;
    } else {
      node.fieldName.staticElement = element;
    }

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
    node.staticType = _translateType(_get(node).inferredType);
  }

  @override
  void visitForEachStatement(ForEachStatement node) {
    DeclaredIdentifier loopVariable = node.loopVariable;
    if (loopVariable != null) {
      loopVariable.type?.accept(this);
      SimpleIdentifier identifier = loopVariable.identifier;

      DartType type = _translateType(_get(identifier).inferredType);
      identifier.staticType = type;

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
      parameter.metadata?.accept(this);
      NormalFormalParameter normalParameter;
      if (parameter is DefaultFormalParameter) {
        parameter.defaultValue?.accept(this);
        normalParameter = parameter.parameter;
      } else if (parameter is NormalFormalParameter) {
        normalParameter = parameter;
      } else {
        // All parameters should either be DefaultFormalParameter or
        // NormalFormalParameter.
        throw new UnimplementedError('${parameter.runtimeType}');
      }
      if (normalParameter is SimpleFormalParameter) {
        normalParameter.type?.accept(this);
      } else if (normalParameter is FieldFormalParameter) {
        normalParameter.type?.accept(this);
      } else if (normalParameter is FunctionTypedFormalParameter) {
        normalParameter.returnType?.accept(this);
        normalParameter.typeParameters?.accept(this);
        normalParameter.parameters?.accept(this);
        var data = _get(normalParameter.identifier);
        normalParameter.identifier.staticType =
            _translateType(data.inferredType);
      } else {
        // Now that DefaultFormalParameter has been handled, all parameters
        // should be SimpleFormalParameter, FieldFormalParameter, or
        // FunctionTypedFormalParameter.
        throw new UnimplementedError('${normalParameter.runtimeType}');
      }
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionElementImpl element = node.declaredElement;
    _typeContext.enterLocalFunction(element);

    node.returnType?.accept(this);
    FunctionExpression functionExpression = node.functionExpression;
    FormalParameterList parameterList = functionExpression.parameters;

    // Apply resolution to default values.
    parameterList.accept(this);

    functionExpression.body?.accept(this);
    _storeFunctionType(_translateType(_get(node.name).inferredType), element);

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
          typeParameter.name.staticElement = element.typeParameters[i];
          typeParameter.name.staticType = _typeContext.typeType;
        }
      }
    }

    _typeContext.exitLocalFunction(element);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    FormalParameterList parameterList = node.parameters;

    FunctionElementImpl element = node.declaredElement;
    _typeContext.enterLocalFunction(element);

    // Apply resolution to default values.
    parameterList.accept(this);

    node.body.accept(this);
    _storeFunctionType(
        _translateType(_get(node.parameters).inferredType), element);

    // Associate the elements with the nodes.
    if (element != null) {
      node.element = element;
      node.staticType = element.type;
    }

    _typeContext.exitLocalFunction(element);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    node.function.accept(this);
    node.typeArguments?.accept(this);

    var data = _get(node.argumentList);
    DartType invokeType = _translateType(data.invokeType);
    node.staticInvokeType = invokeType;

    DartType resultType = _translateType(data.inferredType);
    node.staticType = resultType;

    node.argumentList.accept(this);
  }

  @override
  void visitGenericFunctionType(covariant GenericFunctionTypeImpl node) {
    var data = _get(node.functionKeyword);
    FunctionType type = _translateType(data.inferredType);
    node.type = type;
    _typeContext.enterLocalFunction(type.element);
    super.visitGenericFunctionType(node);
    _typeContext.exitLocalFunction(type.element);
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    node.target?.accept(this);

    var data = _get(node.leftBracket);
    node.staticElement = _translateReference(data);
    node.staticType = _translateType(data.inferredType);

    node.index.accept(this);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorName constructorName = node.constructorName;
    Identifier typeIdentifier = constructorName.type.name;
    SimpleIdentifier classIdentifier;
    SimpleIdentifier constructorIdentifier;

    constructorName.type.typeArguments?.accept(this);
    var data = _get(typeIdentifier);
    TypeName newTypeName;
    if (typeIdentifier is SimpleIdentifier) {
      classIdentifier = typeIdentifier;
      constructorIdentifier = constructorName.name;
    } else if (typeIdentifier is PrefixedIdentifier) {
      if (data.isPrefixReference) {
        typeIdentifier.prefix.staticElement =
            _translatePrefixInfo(data.prefixInfo);

        classIdentifier = typeIdentifier.identifier;
        constructorIdentifier = node.constructorName.name;

        data = _get(classIdentifier);
      } else {
        classIdentifier = typeIdentifier.prefix;
        constructorIdentifier = typeIdentifier.identifier;

        TypeArgumentList typeArguments = constructorName.type.typeArguments;
        newTypeName = astFactory.typeName(classIdentifier, typeArguments);
        constructorName.type = newTypeName;
        constructorName.period = typeIdentifier.period;
        constructorName.name = constructorIdentifier;
      }
    }
    classIdentifier.staticElement = _translateReference(data);

    data = _get(node.argumentList);

    ConstructorElement constructor = _translateReference(data);
    DartType type = _translateType(data.inferredType);

    node.staticElement = constructor;
    node.staticType = type;

    node.constructorName.staticElement = constructor;
    node.constructorName.type.type = type;

    typeIdentifier.staticType = type;
    classIdentifier.staticType = type;
    constructorIdentifier?.staticElement = constructor;

    ArgumentList argumentList = node.argumentList;
    argumentList.accept(this);
    _resolveArgumentsToParameters(argumentList, constructor?.parameters);
  }

  @override
  void visitIsExpression(IsExpression node) {
    node.expression.accept(this);
    node.type.accept(this);
    var data = _get(node.isOperator);
    node.staticType = _translateType(data.inferredType);
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
    node.typeArguments?.accept(this);
    node.elements.accept(this);
    DartType type = _translateType(
        _get(node.constKeyword ?? node.leftBracket).inferredType);
    node.staticType = type;
  }

  @override
  void visitMapLiteral(MapLiteral node) {
    node.typeArguments?.accept(this);
    node.entries.accept(this);
    DartType type = _translateType(
        _get(node.constKeyword ?? node.leftBracket).inferredType);
    node.staticType = type;
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    node.target?.accept(this);
    node.typeArguments?.accept(this);

    ArgumentList argumentList = node.argumentList;

    var data = _get(argumentList);
    Element invokeElement;
    if (data.loadLibrary != null) {
      LibraryElement libraryElement =
          _translateAuxiliaryReference(data.loadLibrary);
      invokeElement = libraryElement.loadLibraryFunction;
    } else if (data.isImplicitCall) {
      if (node.methodName != null) {
        node.methodName.accept(this);
        invokeElement = node.methodName.staticElement;
      }
    } else {
      invokeElement = _translateReference(data);
    }
    DartType invokeType = _translateType(data.invokeType);
    DartType resultType = _translateType(data.inferredType);

    if (invokeElement is PropertyInducingElement) {
      PropertyInducingElement property = invokeElement;
      invokeElement = property.getter;
    }

    node.staticInvokeType = invokeType;
    node.staticType = resultType;

    if (node.methodName.name == 'call' && invokeElement == null) {
      // Don't resolve explicit call() invocation of function types.
    } else if (_get(node.methodName.token,
            isSynthetic: node.methodName.isSynthetic, failIfAbsent: false) !=
        null) {
      node.methodName.accept(this);
    } else {
      node.methodName.staticElement = invokeElement;
      node.methodName.staticType = invokeType;
    }

    argumentList.accept(this);

    {
      var elementForParameters = invokeElement;
      if (elementForParameters is PropertyAccessorElement) {
        PropertyAccessorElement accessor = elementForParameters;
        elementForParameters = accessor.returnType.element;
      }
      List<ParameterElement> parameters;
      if (elementForParameters is FunctionTypedElement) {
        parameters = elementForParameters.parameters;
      } else if (elementForParameters is ParameterElement) {
        var type = elementForParameters.type;
        if (type is FunctionType) {
          parameters = type.parameters;
        }
      }
      _resolveArgumentsToParameters(argumentList, parameters);
    }

    if (invokeElement is ConstructorElement) {
      _rewriteIntoInstanceCreation(node, invokeElement, invokeType, resultType);
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
    node.staticElement = _translateAuxiliaryReference(data.combiner);
    node.staticType = _translateType(data.inferredType);
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
      node.staticElement = _translateAuxiliaryReference(data.combiner);
      node.staticType = _translateType(data.inferredType);
    } else if (tokenType == TokenType.BANG) {
      // !boolExpression;
      node.staticType = _translateType(_get(node).inferredType);
    } else {
      // ~v;
      // This is a method invocation, it is associated with the operator.
      SyntacticEntity entity = node.operator;
      var data = _get(entity);
      node.staticElement = _translateReference(data);
      node.staticType = _translateType(data.inferredType);
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

    ConstructorElement element =
        _translateReference(_get(constructorName ?? node));
    node.staticElement = element;
    constructorName?.staticElement = element;

    ArgumentList argumentList = node.argumentList;
    argumentList.accept(this);
    _resolveArgumentsToParameters(argumentList, element?.parameters);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var data = _get(node, isSynthetic: node.token.isSynthetic);
    if (data.prefixInfo != null) {
      node.staticElement = _translatePrefixInfo(data.prefixInfo);
    } else if (data.declaration != null) {
      node.staticElement = _translateDeclaration(data.declaration);
    } else if (data.loadLibrary != null) {
      LibraryElement library = _translateAuxiliaryReference(data.loadLibrary);
      node.staticElement = library.loadLibraryFunction;
    } else {
      node.staticElement = _translateReference(data);
    }
    node.staticType = _translateType(
        data.isWriteReference ? data.writeContext : data.inferredType);
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
    argumentList.accept(this);
    _resolveArgumentsToParameters(argumentList, element?.parameters);
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
  void visitTypeName(TypeName node) {
    super.visitTypeName(node);
    node.type = node.name.staticType;
  }

  @override
  visitTypeParameter(TypeParameter node) {
    node.bound?.accept(this);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    AstNode parent = node.parent;
    if (parent is VariableDeclarationList &&
        (parent.parent is TopLevelVariableDeclaration ||
            parent.parent is FieldDeclaration)) {
      // Don't visit the name; resolution for it will come from the outline.
    } else {
      DartType type = _translateType(
          _get(node.name, isSynthetic: node.name.isSynthetic).inferredType);
      node.name.staticType = type;

      VariableElementImpl element = node.name.staticElement;
      if (element != null) {
        _typeContext.encloseVariable(element);
        node.name.staticElement = element;
        element.type = type;
      }

      node.initializer?.accept(this);

      if (element is ConstVariableElement) {
        (element as ConstVariableElement).constantInitializer =
            node.initializer;
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    if (node.parent is TopLevelVariableDeclaration) {
      node.variables.accept(this);
    } else {
      node.type?.accept(this);
      node.metadata.accept(this);
      node.variables.accept(this);
    }
  }

  ResolutionData _get(SyntacticEntity entity,
      {bool failIfAbsent = true, bool isSynthetic = false}) {
    int entityOffset = entity.offset;
    var encodedLocation = 2 * entityOffset + (isSynthetic ? 1 : 0);
    var data = _data[encodedLocation];
    if (failIfAbsent && data == null) {
      String fileName = _enclosingLibraryElement.source.fullName;
      throw new StateError('No data for $entity at (offset=$entityOffset, '
          'isSynthetic=$isSynthetic) in $fileName');
    }
    return data;
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
    } else if (leftHandSide is ParenthesizedExpression) {
      return leftHandSide.rightParenthesis;
    } else {
      throw new StateError(
          'Unexpected LHS (${leftHandSide.runtimeType}) $leftHandSide');
    }
  }

  /// Resolve arguments of the [argumentList] to corresponding [parameters].
  void _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    if (parameters != null) {
      var numberOfPositionalParameters = 0;
      for (var parameter in parameters) {
        if (parameter.isPositional) {
          numberOfPositionalParameters++;
        }
      }

      var numberOfArguments = argumentList.arguments.length;
      if (numberOfArguments == numberOfPositionalParameters &&
          numberOfPositionalParameters == parameters.length) {
        argumentList.correspondingStaticParameters = parameters;
        return;
      }

      var resolvedParameters = new List<ParameterElement>(numberOfArguments);
      for (var i = 0; i < numberOfArguments; i++) {
        var argument = argumentList.arguments[i];
        ParameterElement argumentParameter;
        if (argument is NamedExpression) {
          SimpleIdentifier identifier = argument.name.label;
          for (var parameter in parameters) {
            if (parameter.name == identifier.name) {
              argumentParameter = parameter;
              identifier.staticElement = parameter;
              break;
            }
          }
        } else if (i < parameters.length && parameters[i].isPositional) {
          argumentParameter = parameters[i];
        }
        resolvedParameters[i] = argumentParameter;
      }

      argumentList.correspondingStaticParameters = resolvedParameters;
    }
  }

  /// Rewrite AST if the [node] represents an instance creation.
  void _rewriteIntoInstanceCreation(
      MethodInvocation node,
      ConstructorElement invokeElement,
      DartType invokeType,
      DartType resultType) {
    if (node.isCascaded) {
      return;
    }

    Identifier typeIdentifier;
    Token constructorIdentifierPeriod;
    SimpleIdentifier constructorIdentifier;
    var target = node.target;
    if (target == null) {
      SimpleIdentifier simpleTypeIdentifier = node.methodName;
      simpleTypeIdentifier.staticElement = resultType.element;
      simpleTypeIdentifier.staticType = resultType;

      typeIdentifier = simpleTypeIdentifier;
    } else if (target is SimpleIdentifier) {
      if (target.staticElement is PrefixElement) {
        SimpleIdentifier simpleTypeIdentifier = node.methodName;
        simpleTypeIdentifier.staticElement = resultType.element;
        simpleTypeIdentifier.staticType = resultType;

        typeIdentifier = astFactory.prefixedIdentifier(
            target, node.operator, simpleTypeIdentifier);
      } else {
        typeIdentifier = target;

        constructorIdentifierPeriod = node.operator;
        constructorIdentifier = node.methodName;
      }
    } else {
      PrefixedIdentifier prefixed = target;
      typeIdentifier = prefixed;

      constructorIdentifierPeriod = prefixed.period;
      constructorIdentifier = node.methodName;
    }

    var typeName = astFactory.typeName(typeIdentifier, node.typeArguments);
    typeName.type = resultType;

    var creation = astFactory.instanceCreationExpression(
      null,
      astFactory.constructorName(
        typeName,
        constructorIdentifierPeriod,
        constructorIdentifier,
      ),
      node.argumentList,
    );
    creation.staticElement = invokeElement;
    creation.staticType = resultType;
    NodeReplacer.replace(node, creation);
  }

  void _storeFunctionType(DartType type, FunctionTypedElementImpl element) {
    if (type is FunctionType && element != null) {
      DartType Function(DartType) substituteConstituentType;
      if (type.typeFormals.length == element.typeParameters.length &&
          type.typeFormals.length != 0) {
        var argumentTypes = element.typeParameters.map((e) => e.type).toList();
        var parameterTypes = type.typeFormals.map((e) {
          var type = e.type;
          var element = type.element;
          if (element is TypeParameterMember) {
            return element.baseElement.type;
          } else {
            return type;
          }
        }).toList();
        substituteConstituentType =
            (DartType t) => t.substitute2(argumentTypes, parameterTypes);
        for (int i = 0; i < type.typeFormals.length; i++) {
          (element.typeParameters[i] as TypeParameterElementImpl).bound =
              type.typeFormals[i].bound == null
                  ? null
                  : substituteConstituentType(type.typeFormals[i].bound);
        }
      } else {
        substituteConstituentType = (DartType t) => t;
      }
      element.returnType = substituteConstituentType(type.returnType);
      int normalParameterIndex = 0;
      int optionalParameterIndex = 0;
      for (ParameterElementImpl parameter in element.parameters) {
        if (parameter.isNamed) {
          parameter.type = substituteConstituentType(
              type.namedParameterTypes[parameter.name]);
        } else if (normalParameterIndex < type.normalParameterTypes.length) {
          parameter.type = substituteConstituentType(
              type.normalParameterTypes[normalParameterIndex++]);
        } else if (optionalParameterIndex <
            type.optionalParameterTypes.length) {
          parameter.type = substituteConstituentType(
              type.optionalParameterTypes[optionalParameterIndex++]);
        }
      }
    }
  }

  Element _translateAuxiliaryReference(kernel.Node reference) {
    return _typeContext.translateReference(reference);
  }

  Element _translateDeclaration(int declaration) {
    return _typeContext.translateDeclaration(declaration);
  }

  Element _translatePrefixInfo(int prefixInfo) {
    return _typeContext.translatePrefixInfo(prefixInfo);
  }

  Element _translateReference(ResolutionData data) {
    if (data.isPrefixReference) {
      return _translatePrefixInfo(data.prefixInfo);
    }
    return _typeContext.translateReference(data.reference,
        isWriteReference: data.isWriteReference,
        isTypeReference: data.isTypeReference,
        inferredType: data.inferredType,
        receiverType: data.receiverType);
  }

  DartType _translateType(kernel.DartType type) {
    return _typeContext.translateType(type);
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
  void enterLocalFunction(FunctionTypedElementImpl element);

  /// Restore the current executable that was before the [element].
  void exitLocalFunction(FunctionTypedElementImpl element);

  /// Return the Analyzer [Element] for the local declaration having the given
  /// offset.
  Element translateDeclaration(int declarationOffset);

  /// Return the analyzer [Element] for the import prefix corresponding to the
  /// import having the given offset.
  PrefixElement translatePrefixInfo(int importIndex);

  /// Return the analyzer [Element] for the given kernel node.
  Element translateReference(kernel.Node referencedNode,
      {bool isWriteReference = false,
      bool isTypeReference = false,
      kernel.DartType inferredType,
      kernel.DartType receiverType});

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
