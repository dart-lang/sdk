// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';

/**
 * Builder of [Expression]s from [UnlinkedExpr]s.
 */
class ExprBuilder {
  static const ARGUMENT_LIST = 'ARGUMENT_LIST';

  final UnitResynthesizer resynthesizer;
  final ElementImpl context;
  final UnlinkedExpr uc;
  final bool requireValidConst;

  int intPtr = 0;
  int doublePtr = 0;
  int stringPtr = 0;
  int refPtr = 0;
  int assignmentOperatorPtr = 0;
  final List<Expression> stack = <Expression>[];

  final List<UnlinkedExecutable> localFunctions;

  final Map<String, ParameterElement> parametersInScope;

  ExprBuilder(this.resynthesizer, this.context, this.uc,
      {this.requireValidConst: true,
      this.localFunctions,
      Map<String, ParameterElement> parametersInScope})
      : this.parametersInScope =
            parametersInScope ?? _parametersInScope(context);

  Expression build() {
    if (requireValidConst && !uc.isValidConst) {
      return null;
    }
    try {
      for (UnlinkedExprOperation operation in uc.operations) {
        switch (operation) {
          case UnlinkedExprOperation.pushNull:
            _push(AstTestFactory.nullLiteral());
            break;
          // bool
          case UnlinkedExprOperation.pushFalse:
            _push(AstTestFactory.booleanLiteral(false));
            break;
          case UnlinkedExprOperation.pushTrue:
            _push(AstTestFactory.booleanLiteral(true));
            break;
          // literals
          case UnlinkedExprOperation.pushInt:
            int value = uc.ints[intPtr++];
            _push(AstTestFactory.integer(value));
            break;
          case UnlinkedExprOperation.pushLongInt:
            int value = 0;
            int count = uc.ints[intPtr++];
            for (int i = 0; i < count; i++) {
              int next = uc.ints[intPtr++];
              value = value << 32 | next;
            }
            _push(AstTestFactory.integer(value));
            break;
          case UnlinkedExprOperation.pushDouble:
            double value = uc.doubles[doublePtr++];
            _push(AstTestFactory.doubleLiteral(value));
            break;
          case UnlinkedExprOperation.makeSymbol:
            String component = uc.strings[stringPtr++];
            _push(AstTestFactory.symbolLiteral([component]));
            break;
          // String
          case UnlinkedExprOperation.pushString:
            String value = uc.strings[stringPtr++];
            _push(AstTestFactory.string2(value));
            break;
          case UnlinkedExprOperation.concatenate:
            int count = uc.ints[intPtr++];
            List<InterpolationElement> elements = <InterpolationElement>[];
            for (int i = 0; i < count; i++) {
              Expression expr = _pop();
              InterpolationElement element = _newInterpolationElement(expr);
              elements.insert(0, element);
            }
            _push(AstTestFactory.string(elements));
            break;
          // binary
          case UnlinkedExprOperation.equal:
            _pushBinary(TokenType.EQ_EQ);
            break;
          case UnlinkedExprOperation.notEqual:
            _pushBinary(TokenType.BANG_EQ);
            break;
          case UnlinkedExprOperation.and:
            _pushBinary(TokenType.AMPERSAND_AMPERSAND);
            break;
          case UnlinkedExprOperation.or:
            _pushBinary(TokenType.BAR_BAR);
            break;
          case UnlinkedExprOperation.bitXor:
            _pushBinary(TokenType.CARET);
            break;
          case UnlinkedExprOperation.bitAnd:
            _pushBinary(TokenType.AMPERSAND);
            break;
          case UnlinkedExprOperation.bitOr:
            _pushBinary(TokenType.BAR);
            break;
          case UnlinkedExprOperation.bitShiftLeft:
            _pushBinary(TokenType.LT_LT);
            break;
          case UnlinkedExprOperation.bitShiftRight:
            _pushBinary(TokenType.GT_GT);
            break;
          case UnlinkedExprOperation.add:
            _pushBinary(TokenType.PLUS);
            break;
          case UnlinkedExprOperation.subtract:
            _pushBinary(TokenType.MINUS);
            break;
          case UnlinkedExprOperation.multiply:
            _pushBinary(TokenType.STAR);
            break;
          case UnlinkedExprOperation.divide:
            _pushBinary(TokenType.SLASH);
            break;
          case UnlinkedExprOperation.floorDivide:
            _pushBinary(TokenType.TILDE_SLASH);
            break;
          case UnlinkedExprOperation.modulo:
            _pushBinary(TokenType.PERCENT);
            break;
          case UnlinkedExprOperation.greater:
            _pushBinary(TokenType.GT);
            break;
          case UnlinkedExprOperation.greaterEqual:
            _pushBinary(TokenType.GT_EQ);
            break;
          case UnlinkedExprOperation.less:
            _pushBinary(TokenType.LT);
            break;
          case UnlinkedExprOperation.lessEqual:
            _pushBinary(TokenType.LT_EQ);
            break;
          // prefix
          case UnlinkedExprOperation.complement:
            _pushPrefix(TokenType.TILDE);
            break;
          case UnlinkedExprOperation.negate:
            _pushPrefix(TokenType.MINUS);
            break;
          case UnlinkedExprOperation.not:
            _pushPrefix(TokenType.BANG);
            break;
          // conditional
          case UnlinkedExprOperation.conditional:
            Expression elseExpr = _pop();
            Expression thenExpr = _pop();
            Expression condition = _pop();
            _push(AstTestFactory.conditionalExpression(
                condition, thenExpr, elseExpr));
            break;
          case UnlinkedExprOperation.invokeMethodRef:
            _pushInvokeMethodRef();
            break;
          case UnlinkedExprOperation.invokeMethod:
            List<Expression> arguments = _buildArguments();
            TypeArgumentList typeArguments = _buildTypeArguments();
            Expression target = _pop();
            String name = uc.strings[stringPtr++];
            _push(AstTestFactory.methodInvocation3(
                target, name, typeArguments, arguments));
            break;
          // containers
          case UnlinkedExprOperation.makeUntypedList:
            _pushList(null);
            break;
          case UnlinkedExprOperation.makeTypedList:
            TypeAnnotation itemType = _newTypeName();
            _pushList(
                AstTestFactory.typeArgumentList(<TypeAnnotation>[itemType]));
            break;
          case UnlinkedExprOperation.makeUntypedMap:
            _pushMap(null);
            break;
          case UnlinkedExprOperation.makeTypedMap:
            TypeAnnotation keyType = _newTypeName();
            TypeAnnotation valueType = _newTypeName();
            _pushMap(AstTestFactory
                .typeArgumentList(<TypeAnnotation>[keyType, valueType]));
            break;
          case UnlinkedExprOperation.pushReference:
            _pushReference();
            break;
          case UnlinkedExprOperation.extractProperty:
            _pushExtractProperty();
            break;
          case UnlinkedExprOperation.invokeConstructor:
            _pushInstanceCreation();
            break;
          case UnlinkedExprOperation.pushParameter:
            String name = uc.strings[stringPtr++];
            SimpleIdentifier identifier = AstTestFactory.identifier3(name);
            identifier.staticElement = parametersInScope[name];
            _push(identifier);
            break;
          case UnlinkedExprOperation.ifNull:
            _pushBinary(TokenType.QUESTION_QUESTION);
            break;
          case UnlinkedExprOperation.await:
            Expression expression = _pop();
            _push(AstTestFactory.awaitExpression(expression));
            break;
          case UnlinkedExprOperation.pushLocalFunctionReference:
            _pushLocalFunctionReference();
            break;
          case UnlinkedExprOperation.assignToRef:
            var ref = _createReference();
            _push(_createAssignment(ref));
            break;
          case UnlinkedExprOperation.typeCast:
            Expression expression = _pop();
            TypeAnnotation type = _newTypeName();
            _push(AstTestFactory.asExpression(expression, type));
            break;
          case UnlinkedExprOperation.typeCheck:
            Expression expression = _pop();
            TypeAnnotation type = _newTypeName();
            _push(AstTestFactory.isExpression(expression, false, type));
            break;
          case UnlinkedExprOperation.throwException:
            Expression expression = _pop();
            _push(AstTestFactory.throwExpression2(expression));
            break;
          case UnlinkedExprOperation.assignToProperty:
            Expression target = _pop();
            String name = uc.strings[stringPtr++];
            SimpleIdentifier propertyNode = AstTestFactory.identifier3(name);
            PropertyAccess propertyAccess =
                AstTestFactory.propertyAccess(target, propertyNode);
            _push(_createAssignment(propertyAccess));
            break;
          case UnlinkedExprOperation.assignToIndex:
            Expression index = _pop();
            Expression target = _pop();
            IndexExpression indexExpression =
                AstTestFactory.indexExpression(target, index);
            _push(_createAssignment(indexExpression));
            break;
          case UnlinkedExprOperation.extractIndex:
            Expression index = _pop();
            Expression target = _pop();
            _push(AstTestFactory.indexExpression(target, index));
            break;
          case UnlinkedExprOperation.pushSuper:
          case UnlinkedExprOperation.pushThis:
            throw const _InvalidConstantException(); // TODO(paulberry)
          case UnlinkedExprOperation.cascadeSectionBegin:
          case UnlinkedExprOperation.cascadeSectionEnd:
          case UnlinkedExprOperation.pushLocalFunctionReference:
          case UnlinkedExprOperation.pushError:
          case UnlinkedExprOperation.pushTypedAbstract:
          case UnlinkedExprOperation.pushUntypedAbstract:
            throw new UnimplementedError(
                'Unexpected $operation in a constant expression.');
        }
      }
    } on _InvalidConstantException {
      return AstTestFactory.identifier3(r'#invalidConst');
    }
    return stack.single;
  }

  List<Expression> _buildArguments() {
    List<Expression> arguments;
    {
      int numNamedArgs = uc.ints[intPtr++];
      int numPositionalArgs = uc.ints[intPtr++];
      int numArgs = numNamedArgs + numPositionalArgs;
      arguments = _removeTopItems(numArgs);
      // add names to the named arguments
      for (int i = 0; i < numNamedArgs; i++) {
        String name = uc.strings[stringPtr++];
        int index = numPositionalArgs + i;
        arguments[index] =
            AstTestFactory.namedExpression2(name, arguments[index]);
      }
    }
    return arguments;
  }

  /**
   * Build the identifier sequence (a single or prefixed identifier, or a
   * property access) corresponding to the given reference [info].
   */
  Expression _buildIdentifierSequence(ReferenceInfo info) {
    Expression enclosing;
    if (info.enclosing != null) {
      enclosing = _buildIdentifierSequence(info.enclosing);
    }
    Element element = info.element;
    if (element == null && info.name == 'length') {
      element = _getStringLengthElement();
    }
    if (enclosing == null) {
      return AstTestFactory.identifier3(info.name)..staticElement = element;
    }
    if (enclosing is SimpleIdentifier) {
      SimpleIdentifier identifier = AstTestFactory.identifier3(info.name)
        ..staticElement = element;
      return AstTestFactory.identifier(enclosing, identifier);
    }
    if (requireValidConst && element == null) {
      throw const _InvalidConstantException();
    }
    SimpleIdentifier property = AstTestFactory.identifier3(info.name)
      ..staticElement = element;
    return AstTestFactory.propertyAccess(enclosing, property);
  }

  TypeArgumentList _buildTypeArguments() {
    int numTypeArguments = uc.ints[intPtr++];
    if (numTypeArguments == 0) {
      return null;
    }

    var typeNames = new List<TypeAnnotation>(numTypeArguments);
    for (int i = 0; i < numTypeArguments; i++) {
      typeNames[i] = _newTypeName();
    }
    return AstTestFactory.typeArgumentList(typeNames);
  }

  TypeAnnotation _buildTypeAst(DartType type) {
    List<TypeAnnotation> argumentNodes;
    if (type is ParameterizedType) {
      if (!resynthesizer.doesTypeHaveImplicitArguments(type)) {
        List<DartType> typeArguments = type.typeArguments;
        argumentNodes = typeArguments.every((a) => a.isDynamic)
            ? null
            : typeArguments.map(_buildTypeAst).toList();
      }
    }
    TypeName node = AstTestFactory.typeName4(type.name, argumentNodes);
    node.type = type;
    (node.name as SimpleIdentifier).staticElement = type.element;
    return node;
  }

  Expression _createAssignment(Expression lhs) {
    Expression binary(TokenType tokenType) {
      return AstTestFactory.assignmentExpression(lhs, tokenType, _pop());
    }

    Expression prefix(TokenType tokenType) {
      return AstTestFactory.prefixExpression(tokenType, lhs);
    }

    Expression postfix(TokenType tokenType) {
      return AstTestFactory.postfixExpression(lhs, tokenType);
    }

    switch (uc.assignmentOperators[assignmentOperatorPtr++]) {
      case UnlinkedExprAssignOperator.assign:
        return binary(TokenType.EQ);
      case UnlinkedExprAssignOperator.ifNull:
        return binary(TokenType.QUESTION_QUESTION_EQ);
      case UnlinkedExprAssignOperator.multiply:
        return binary(TokenType.STAR_EQ);
      case UnlinkedExprAssignOperator.divide:
        return binary(TokenType.SLASH_EQ);
      case UnlinkedExprAssignOperator.floorDivide:
        return binary(TokenType.TILDE_SLASH_EQ);
      case UnlinkedExprAssignOperator.modulo:
        return binary(TokenType.PERCENT_EQ);
      case UnlinkedExprAssignOperator.plus:
        return binary(TokenType.PLUS_EQ);
      case UnlinkedExprAssignOperator.minus:
        return binary(TokenType.MINUS_EQ);
      case UnlinkedExprAssignOperator.shiftLeft:
        return binary(TokenType.LT_LT_EQ);
      case UnlinkedExprAssignOperator.shiftRight:
        return binary(TokenType.GT_GT_EQ);
      case UnlinkedExprAssignOperator.bitAnd:
        return binary(TokenType.AMPERSAND_EQ);
      case UnlinkedExprAssignOperator.bitXor:
        return binary(TokenType.CARET_EQ);
      case UnlinkedExprAssignOperator.bitOr:
        return binary(TokenType.BAR_EQ);
      case UnlinkedExprAssignOperator.prefixIncrement:
        return prefix(TokenType.PLUS_PLUS);
      case UnlinkedExprAssignOperator.prefixDecrement:
        return prefix(TokenType.MINUS_MINUS);
      case UnlinkedExprAssignOperator.postfixIncrement:
        return postfix(TokenType.PLUS_PLUS);
      case UnlinkedExprAssignOperator.postfixDecrement:
        return postfix(TokenType.MINUS_MINUS);
      default:
        throw new UnimplementedError('Unexpected UnlinkedExprAssignOperator');
    }
  }

  Expression _createReference() {
    EntityRef ref = uc.references[refPtr++];
    ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
    if (requireValidConst && node is Identifier && node.staticElement == null) {
      throw const _InvalidConstantException();
    }
    return node;
  }

  PropertyAccessorElement _getStringLengthElement() =>
      resynthesizer.typeProvider.stringType.getGetter('length');

  FormalParameter _makeParameter(ParameterElement param) {
    SimpleFormalParameterImpl simpleParam =
        AstTestFactory.simpleFormalParameter(null, param.name);
    simpleParam.identifier.staticElement = param;
    simpleParam.element = param;
    var unlinkedParam = (param as ParameterElementImpl).unlinkedParam;
    if (unlinkedParam.kind == UnlinkedParamKind.positional) {
      return AstTestFactory.positionalFormalParameter(simpleParam, null);
    } else if (unlinkedParam.kind == UnlinkedParamKind.named) {
      return AstTestFactory.namedFormalParameter(simpleParam, null);
    } else {
      return simpleParam;
    }
  }

  InterpolationElement _newInterpolationElement(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return astFactory.interpolationString(expr.literal, expr.value);
    } else {
      return astFactory.interpolationExpression(
          TokenFactory.tokenFromType(TokenType.STRING_INTERPOLATION_EXPRESSION),
          expr,
          TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET));
    }
  }

  /**
   * Convert the next reference to the [DartType] and return the AST
   * corresponding to this type.
   */
  TypeAnnotation _newTypeName() {
    EntityRef typeRef = uc.references[refPtr++];
    DartType type = resynthesizer.buildType(context, typeRef);
    return _buildTypeAst(type);
  }

  Expression _pop() => stack.removeLast();

  void _push(Expression expr) {
    stack.add(expr);
  }

  void _pushBinary(TokenType operator) {
    Expression right = _pop();
    Expression left = _pop();
    _push(AstTestFactory.binaryExpression(left, operator, right));
  }

  void _pushExtractProperty() {
    Expression target = _pop();
    String name = uc.strings[stringPtr++];
    SimpleIdentifier propertyNode = AstTestFactory.identifier3(name);
    // Only String.length property access can be potentially resolved.
    if (name == 'length') {
      propertyNode.staticElement = _getStringLengthElement();
    }
    _push(AstTestFactory.propertyAccess(target, propertyNode));
  }

  void _pushInstanceCreation() {
    EntityRef ref = uc.references[refPtr++];
    ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    // prepare ConstructorElement
    TypeName typeNode;
    String constructorName;
    ConstructorElement constructorElement;
    if (info.element != null) {
      if (info.element is ConstructorElement) {
        constructorName = info.name;
      } else if (info.element is ClassElement) {
        constructorName = null;
      } else {
        List<Expression> arguments = _buildArguments();
        SimpleIdentifier name = AstTestFactory.identifier3(info.name);
        name.staticElement = info.element;
        name.setProperty(ARGUMENT_LIST, AstTestFactory.argumentList(arguments));
        _push(name);
        return;
      }
      InterfaceType definingType = resynthesizer.createConstructorDefiningType(
          context, info, ref.typeArguments);
      constructorElement =
          resynthesizer.getConstructorForInfo(definingType, info);
      typeNode = _buildTypeAst(definingType);
    } else {
      if (info.enclosing != null) {
        if (info.enclosing.enclosing != null) {
          PrefixedIdentifier typeName = AstTestFactory.identifier5(
              info.enclosing.enclosing.name, info.enclosing.name);
          typeName.prefix.staticElement = info.enclosing.enclosing.element;
          typeName.identifier.staticElement = info.enclosing.element;
          typeName.identifier.staticType = info.enclosing.type;
          typeNode = AstTestFactory.typeName3(typeName);
          typeNode.type = info.enclosing.type;
          constructorName = info.name;
        } else if (info.enclosing.element != null) {
          SimpleIdentifier typeName =
              AstTestFactory.identifier3(info.enclosing.name);
          typeName.staticElement = info.enclosing.element;
          typeName.staticType = info.enclosing.type;
          typeNode = AstTestFactory.typeName3(typeName);
          typeNode.type = info.enclosing.type;
          constructorName = info.name;
        } else {
          typeNode = AstTestFactory.typeName3(
              AstTestFactory.identifier5(info.enclosing.name, info.name));
          constructorName = null;
        }
      } else {
        typeNode = AstTestFactory.typeName4(info.name);
      }
    }
    // prepare arguments
    List<Expression> arguments = _buildArguments();
    // create ConstructorName
    ConstructorName constructorNode;
    if (constructorName != null) {
      constructorNode =
          AstTestFactory.constructorName(typeNode, constructorName);
      constructorNode.name.staticElement = constructorElement;
    } else {
      constructorNode = AstTestFactory.constructorName(typeNode, null);
    }
    constructorNode.staticElement = constructorElement;
    if (constructorElement == null) {
      throw const _InvalidConstantException();
    }
    // create InstanceCreationExpression
    InstanceCreationExpression instanceCreation =
        AstTestFactory.instanceCreationExpression(
            requireValidConst ? Keyword.CONST : Keyword.NEW,
            constructorNode,
            arguments);
    instanceCreation.staticElement = constructorElement;
    _push(instanceCreation);
  }

  void _pushInvokeMethodRef() {
    List<Expression> arguments = _buildArguments();
    EntityRef ref = uc.references[refPtr++];
    ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
    TypeArgumentList typeArguments = _buildTypeArguments();
    var period = TokenFactory.tokenFromType(TokenType.PERIOD);
    var argumentList = AstTestFactory.argumentList(arguments);
    if (node is SimpleIdentifier) {
      _push(astFactory.methodInvocation(
          null, period, node, typeArguments, argumentList));
    } else if (node is PropertyAccess) {
      _push(astFactory.methodInvocation(
          node.target, period, node.propertyName, typeArguments, argumentList));
    } else if (node is PrefixedIdentifier) {
      _push(astFactory.methodInvocation(
          node.prefix, period, node.identifier, typeArguments, argumentList));
    } else {
      throw new UnimplementedError('For ${node?.runtimeType}: $node');
    }
  }

  void _pushList(TypeArgumentList typeArguments) {
    int count = uc.ints[intPtr++];
    List<Expression> elements = <Expression>[];
    for (int i = 0; i < count; i++) {
      elements.insert(0, _pop());
    }
    _push(AstTestFactory.listLiteral2(Keyword.CONST, typeArguments, elements));
  }

  void _pushLocalFunctionReference() {
    _throwIfConst();
    int popCount = uc.ints[intPtr++];
    // Note: nonzero popCount is no longer used.
    assert(popCount == 0);
    int functionIndex = uc.ints[intPtr++];
    var localFunction = localFunctions[functionIndex];
    var parametersInScope =
        new Map<String, ParameterElement>.from(this.parametersInScope);
    var functionElement =
        new FunctionElementImpl.forSerialized(localFunction, context);
    for (ParameterElementImpl parameter in functionElement.parameters) {
      parametersInScope[parameter.name] = parameter;
      if (parameter.unlinkedParam.type == null) {
        // Store a type of `dynamic` for the parameter; this prevents
        // resynthesis from trying to read a type out of the summary (which
        // wouldn't work anyway, since nested functions don't have their
        // parameter types stored in the summary anyhow).
        parameter.type = resynthesizer.typeProvider.dynamicType;
      }
    }
    var parameters = functionElement.parameters.map(_makeParameter).toList();
    var asyncKeyword = localFunction.isAsynchronous
        ? TokenFactory.tokenFromKeyword(Keyword.ASYNC)
        : null;
    FunctionBody functionBody;
    if (localFunction.bodyExpr == null) {
      // Most likely the original source code contained a block function body
      // here.  Block function bodies aren't supported by the summary mechanism.
      // But they are tolerated when their presence doesn't affect inferred
      // types.
      functionBody = AstTestFactory.blockFunctionBody(AstTestFactory.block());
    } else {
      var bodyExpr = new ExprBuilder(
              resynthesizer, functionElement, localFunction.bodyExpr,
              requireValidConst: requireValidConst,
              parametersInScope: parametersInScope,
              localFunctions: localFunction.localFunctions)
          .build();
      functionBody = astFactory.expressionFunctionBody(asyncKeyword,
          TokenFactory.tokenFromType(TokenType.FUNCTION), bodyExpr, null);
    }
    var functionExpression = astFactory.functionExpression(
        null, AstTestFactory.formalParameterList(parameters), functionBody);
    functionExpression.element = functionElement;
    _push(functionExpression);
  }

  void _pushMap(TypeArgumentList typeArguments) {
    int count = uc.ints[intPtr++];
    List<MapLiteralEntry> entries = <MapLiteralEntry>[];
    for (int i = 0; i < count; i++) {
      Expression value = _pop();
      Expression key = _pop();
      entries.insert(0, AstTestFactory.mapLiteralEntry2(key, value));
    }
    _push(AstTestFactory.mapLiteral(Keyword.CONST, typeArguments, entries));
  }

  void _pushPrefix(TokenType operator) {
    Expression operand = _pop();
    _push(AstTestFactory.prefixExpression(operator, operand));
  }

  void _pushReference() {
    _push(_createReference());
  }

  List<Expression> _removeTopItems(int count) {
    int start = stack.length - count;
    int end = stack.length;
    List<Expression> items = stack.getRange(start, end).toList();
    stack.removeRange(start, end);
    return items;
  }

  void _throwIfConst() {
    if (requireValidConst) {
      throw const _InvalidConstantException();
    }
  }

  /// Figures out the default value of [parametersInScope] based on [context].
  ///
  /// If [context] is (or contains) a constructor, then its parameters are used.
  /// Otherwise, no parameters are considered to be in scope.
  static Map<String, ParameterElement> _parametersInScope(Element context) {
    var result = <String, ParameterElement>{};
    for (Element e = context; e != null; e = e.enclosingElement) {
      if (e is ConstructorElement) {
        for (var parameter in e.parameters) {
          result[parameter.name] = parameter;
        }
        return result;
      }
    }
    return result;
  }
}

/**
 * This exception is thrown when we detect that the constant expression
 * being resynthesized is not a valid constant expression.
 */
class _InvalidConstantException {
  const _InvalidConstantException();
}
