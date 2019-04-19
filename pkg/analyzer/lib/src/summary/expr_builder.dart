// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart' show AstRewriteVisitor;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/generated/testing/token_factory.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:analyzer/src/summary/resynthesize.dart';

bool _isSpreadOrControlFlowEnabled(ExperimentStatus experimentStatus) =>
    experimentStatus.spread_collections ||
    experimentStatus.control_flow_collections;

/**
 * Builder of [Expression]s from [UnlinkedExpr]s.
 */
class ExprBuilder {
  static const ARGUMENT_LIST = 'ARGUMENT_LIST';

  final UnitResynthesizer resynthesizer;
  final ElementImpl context;
  final UnlinkedExpr _uc;
  final bool requireValidConst;
  final bool isSpreadOrControlFlowEnabled;
  final bool becomeSetOrMap;

  int intPtr = 0;
  int doublePtr = 0;
  int stringPtr = 0;
  int refPtr = 0;
  int assignmentOperatorPtr = 0;

  // The stack of values. Note that they are usually [Expression]s, but may be
  // any [CollectionElement] to support map/set/list literals.
  final List<AstNode> stack = <AstNode>[];

  final List<UnlinkedExecutable> localFunctions;

  final _VariablesInScope variablesInScope;

  ExprBuilder(
    this.resynthesizer,
    this.context,
    this._uc, {
    this.requireValidConst: true,
    this.localFunctions,
    _VariablesInScope variablesInScope,
    this.becomeSetOrMap: true,
  })  : this.variablesInScope = variablesInScope ?? _parametersInScope(context),
        this.isSpreadOrControlFlowEnabled = _isSpreadOrControlFlowEnabled(
            (resynthesizer.library.context.analysisOptions
                    as AnalysisOptionsImpl)
                .experimentStatus);

  bool get hasNonEmptyExpr => _uc != null && _uc.operations.isNotEmpty;

  Expression build() {
    if (requireValidConst && !_uc.isValidConst) {
      return null;
    }
    int startingVariableCount = variablesInScope.count;
    for (UnlinkedExprOperation operation in _uc.operations) {
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
          int value = _uc.ints[intPtr++];
          _push(AstTestFactory.integer(value));
          break;
        case UnlinkedExprOperation.pushLongInt:
          int value = 0;
          int count = _uc.ints[intPtr++];
          for (int i = 0; i < count; i++) {
            int next = _uc.ints[intPtr++];
            value = value << 32 | next;
          }
          _push(AstTestFactory.integer(value));
          break;
        case UnlinkedExprOperation.pushDouble:
          double value = _uc.doubles[doublePtr++];
          _push(AstTestFactory.doubleLiteral(value));
          break;
        case UnlinkedExprOperation.makeSymbol:
          String component = _uc.strings[stringPtr++];
          _push(AstTestFactory.symbolLiteral([component]));
          break;
        // String
        case UnlinkedExprOperation.pushString:
          String value = _uc.strings[stringPtr++];
          _push(AstTestFactory.string2(value));
          break;
        case UnlinkedExprOperation.concatenate:
          int count = _uc.ints[intPtr++];
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
        case UnlinkedExprOperation.bitShiftRightLogical:
          _pushBinary(TokenType.GT_GT_GT);
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
          String name = _uc.strings[stringPtr++];
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
        case UnlinkedExprOperation.makeUntypedSetOrMap:
          _pushSetOrMap(null);
          break;
        case UnlinkedExprOperation.makeUntypedMap:
          _pushMap(null);
          break;
        case UnlinkedExprOperation.makeTypedMap:
          TypeAnnotation keyType = _newTypeName();
          TypeAnnotation valueType = _newTypeName();
          _pushMap(AstTestFactory.typeArgumentList(
              <TypeAnnotation>[keyType, valueType]));
          break;
        case UnlinkedExprOperation.makeMapLiteralEntry:
          _pushMapLiteralEntry();
          break;
        case UnlinkedExprOperation.makeTypedMap2:
          TypeAnnotation keyType = _newTypeName();
          TypeAnnotation valueType = _newTypeName();
          _pushSetOrMap(AstTestFactory.typeArgumentList(
              <TypeAnnotation>[keyType, valueType]));
          break;
        case UnlinkedExprOperation.makeUntypedSet:
          _pushSet(null);
          break;
        case UnlinkedExprOperation.makeTypedSet:
          TypeAnnotation itemType = _newTypeName();
          if (isSpreadOrControlFlowEnabled) {
            _pushSetOrMap(
                AstTestFactory.typeArgumentList(<TypeAnnotation>[itemType]));
          } else {
            _pushSet(
                AstTestFactory.typeArgumentList(<TypeAnnotation>[itemType]));
          }
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
          String name = _uc.strings[stringPtr++];
          SimpleIdentifier identifier = AstTestFactory.identifier3(name);
          identifier.staticElement = variablesInScope[name];
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
          String name = _uc.strings[stringPtr++];
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
          _push(AstTestFactory.superExpression());
          break;
        case UnlinkedExprOperation.pushThis:
          _push(AstTestFactory.thisExpression());
          break;
        case UnlinkedExprOperation.spreadElement:
          _pushSpread(TokenType.PERIOD_PERIOD_PERIOD);
          break;
        case UnlinkedExprOperation.nullAwareSpreadElement:
          _pushSpread(TokenType.PERIOD_PERIOD_PERIOD_QUESTION);
          break;
        case UnlinkedExprOperation.ifElement:
          _pushIfElement(false);
          break;
        case UnlinkedExprOperation.ifElseElement:
          _pushIfElement(true);
          break;
        case UnlinkedExprOperation.forParts:
          _pushForParts();
          break;
        case UnlinkedExprOperation.forElement:
          _pushForElement(false);
          break;
        case UnlinkedExprOperation.forElementWithAwait:
          _pushForElement(true);
          break;
        case UnlinkedExprOperation.pushEmptyExpression:
          _push(null);
          break;
        case UnlinkedExprOperation.variableDeclarationStart:
          _variableDeclarationStart();
          break;
        case UnlinkedExprOperation.variableDeclaration:
          _variableDeclaration();
          break;
        case UnlinkedExprOperation.forInitializerDeclarationsUntyped:
          _forInitializerDeclarations(false);
          break;
        case UnlinkedExprOperation.forInitializerDeclarationsTyped:
          _forInitializerDeclarations(true);
          break;
        case UnlinkedExprOperation.assignToParameter:
          String name = _uc.strings[stringPtr++];
          SimpleIdentifier identifier = AstTestFactory.identifier3(name);
          identifier.staticElement = variablesInScope[name];
          _push(_createAssignment(identifier));
          break;
        case UnlinkedExprOperation.forEachPartsWithIdentifier:
          _forEachPartsWithIdentifier();
          break;
        case UnlinkedExprOperation.forEachPartsWithUntypedDeclaration:
          _forEachPartsWithDeclaration(false);
          break;
        case UnlinkedExprOperation.forEachPartsWithTypedDeclaration:
          _forEachPartsWithDeclaration(true);
          break;
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
    assert(startingVariableCount == variablesInScope.count);
    return stack.single;
  }

  List<Expression> _buildArguments() {
    List<Expression> arguments;
    {
      int numNamedArgs = _uc.ints[intPtr++];
      int numPositionalArgs = _uc.ints[intPtr++];
      int numArgs = numNamedArgs + numPositionalArgs;
      arguments = _removeTopExpressions(numArgs);
      // add names to the named arguments
      for (int i = 0; i < numNamedArgs; i++) {
        String name = _uc.strings[stringPtr++];
        int index = numPositionalArgs + i;
        arguments[index] =
            AstTestFactory.namedExpression2(name, arguments[index]);
      }
    }
    return arguments;
  }

  /// Given the sequence of identifiers in [node], and the [classElement] or
  /// [constructorElement] to which this sequence resolves, build the
  /// [InstanceCreationExpression].
  InstanceCreationExpression _buildCreation(
    Expression node,
    TypeArgumentList typeArguments,
    ArgumentList argumentList, {
    ClassElement classElement,
    ConstructorElement constructorElement,
  }) {
    InstanceCreationExpression composeCreation(
        DartType type,
        ConstructorName constructorName,
        ConstructorElement constructorElement,
        ArgumentList argumentList) {
      TypeName typeName = constructorName.type;
      typeName.type = type;

      constructorName.name?.staticElement = constructorElement;

      var creation = astFactory.instanceCreationExpression(
          _uc.isValidConst
              ? TokenFactory.tokenFromKeyword(Keyword.CONST)
              : TokenFactory.tokenFromKeyword(Keyword.NEW),
          constructorName,
          argumentList);

      creation.staticElement = constructorElement;
      creation.staticType = type;
      return creation;
    }

    classElement ??= constructorElement?.enclosingElement;
    var type = AstRewriteVisitor.getType(
        resynthesizer.typeSystem, classElement, typeArguments);

    // C()
    if (node is SimpleIdentifier && classElement != null) {
      constructorElement = type.lookUpConstructor('', resynthesizer.library);
      node.staticType = type;
      return composeCreation(
        type,
        astFactory.constructorName(
          astFactory.typeName(node, typeArguments),
          null,
          null,
        ),
        constructorElement,
        argumentList,
      );
    }
    if (node is PrefixedIdentifier) {
      // C.n()
      if (constructorElement != null) {
        constructorElement =
            type.lookUpConstructor(node.identifier.name, resynthesizer.library);
        node.prefix.staticType = type;
        return composeCreation(
          type,
          astFactory.constructorName(
            astFactory.typeName(node.prefix, typeArguments),
            TokenFactory.tokenFromType(TokenType.PERIOD),
            node.identifier,
          ),
          constructorElement,
          argumentList,
        );
      }
      // p.C()
      if (classElement != null) {
        constructorElement = type.lookUpConstructor('', resynthesizer.library);
        node.identifier.staticType = type;
        return composeCreation(
          type,
          astFactory.constructorName(
            astFactory.typeName(node.identifier, typeArguments),
            null,
            null,
          ),
          constructorElement,
          argumentList,
        );
      }
    }
    // p.C.n()
    if (node is PropertyAccess && constructorElement != null) {
      constructorElement =
          type.lookUpConstructor(node.propertyName.name, resynthesizer.library);
      var typeIdentifier = (node.target as PrefixedIdentifier).identifier;
      typeIdentifier.staticType = type;
      return composeCreation(
        type,
        astFactory.constructorName(
          astFactory.typeName(typeIdentifier, typeArguments),
          TokenFactory.tokenFromType(TokenType.PERIOD),
          node.propertyName,
        ),
        constructorElement,
        argumentList,
      );
    }

    throw new UnimplementedError('For ${node?.runtimeType}: $node; '
        'class: $classElement;  constructor: $constructorElement');
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
    SimpleIdentifier property = AstTestFactory.identifier3(info.name)
      ..staticElement = element;
    return AstTestFactory.propertyAccess(enclosing, property);
  }

  TypeArgumentList _buildTypeArguments() {
    int numTypeArguments = _uc.ints[intPtr++];
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

    switch (_uc.assignmentOperators[assignmentOperatorPtr++]) {
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
    EntityRef ref = _uc.references[refPtr++];
    if (ref.paramReference != 0) {
      // This is a reference to a type parameter.  For type inference purposes
      // we don't actually need to know which type parameter it's a reference
      // to; we just need to know that it represents a type.  So map it to
      // `Object`.
      return AstTestFactory.identifier3('Object')
        ..staticElement = resynthesizer.typeProvider.objectType.element;
    }
    ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    return _buildIdentifierSequence(info);
  }

  void _forEachPartsWithDeclaration(bool hasType) {
    var iterable = _pop();
    var name = _uc.strings[stringPtr++];
    var element = LocalVariableElementImpl(name, -1);
    var keyword = hasType ? null : Keyword.VAR;
    var type = hasType ? _newTypeName() : null;
    var loopVariable = AstTestFactory.declaredIdentifier2(keyword, type, name);
    loopVariable.identifier.staticElement = element;
    if (hasType) {
      element.type = type.type;
    }
    _pushNode(
        AstTestFactory.forEachPartsWithDeclaration(loopVariable, iterable));
    variablesInScope.push(element);
  }

  void _forEachPartsWithIdentifier() {
    var iterable = _pop();
    SimpleIdentifier identifier = _pop();
    _pushNode(AstTestFactory.forEachPartsWithIdentifier(identifier, iterable));
  }

  void _forInitializerDeclarations(bool hasType) {
    var count = _uc.ints[intPtr++];
    var variables = List<VariableDeclaration>.filled(count, null);
    for (int i = 0; i < count; i++) {
      variables[count - 1 - i] = _popNode();
    }
    var type = hasType ? _newTypeName() : null;
    var keyword = hasType ? null : Keyword.VAR;
    _pushNode(AstTestFactory.variableDeclarationList(keyword, type, variables));
  }

  PropertyAccessorElement _getStringLengthElement() =>
      resynthesizer.typeProvider.stringType.getGetter('length');

  FormalParameter _makeParameter(ParameterElement param) {
    SimpleFormalParameterImpl simpleParam =
        AstTestFactory.simpleFormalParameter(null, param.name);
    simpleParam.identifier.staticElement = param;
    simpleParam.declaredElement = param;
    var unlinkedParam = (param as ParameterElementImpl).unlinkedParam;
    if (unlinkedParam.kind == UnlinkedParamKind.optionalPositional) {
      return AstTestFactory.positionalFormalParameter(simpleParam, null);
    } else if (unlinkedParam.kind == UnlinkedParamKind.requiredNamed ||
        unlinkedParam.kind == UnlinkedParamKind.optionalNamed) {
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
    EntityRef typeRef = _uc.references[refPtr++];
    DartType type = resynthesizer.buildType(context, typeRef);
    return _buildTypeAst(type);
  }

  Expression _pop() => stack.removeLast() as Expression;

  CollectionElement _popCollectionElement() =>
      stack.removeLast() as CollectionElement;

  AstNode _popNode() => stack.removeLast();

  void _push(Expression expr) {
    stack.add(expr);
  }

  void _pushBinary(TokenType operator) {
    Expression right = _pop();
    Expression left = _pop();
    _push(AstTestFactory.binaryExpression(left, operator, right));
  }

  void _pushCollectionElement(CollectionElement collectionElement) {
    stack.add(collectionElement);
  }

  void _pushExtractProperty() {
    Expression target = _pop();
    String name = _uc.strings[stringPtr++];
    SimpleIdentifier propertyNode = AstTestFactory.identifier3(name);
    // Only String.length property access can be potentially resolved.
    if (name == 'length') {
      propertyNode.staticElement = _getStringLengthElement();
    }
    _push(AstTestFactory.propertyAccess(target, propertyNode));
  }

  void _pushForElement(bool hasAwait) {
    var body = _popCollectionElement();
    var forLoopParts = _popNode() as ForLoopParts;
    if (forLoopParts is ForPartsWithDeclarations) {
      variablesInScope.pop(forLoopParts.variables.variables.length);
    } else if (forLoopParts is ForEachPartsWithDeclaration) {
      variablesInScope.pop(1);
    }
    _pushCollectionElement(
        AstTestFactory.forElement(forLoopParts, body, hasAwait: hasAwait));
  }

  void _pushForParts() {
    var updaterCount = _uc.ints[intPtr++];
    var updaters = <Expression>[];
    for (int i = 0; i < updaterCount; i++) {
      updaters.insert(0, _pop());
    }
    Expression condition = _pop();
    AstNode initialization = _popNode();
    if (initialization is Expression || initialization == null) {
      _pushNode(AstTestFactory.forPartsWithExpression(
          initialization, condition, updaters));
    } else if (initialization is VariableDeclarationList) {
      _pushNode(AstTestFactory.forPartsWithDeclarations(
          initialization, condition, updaters));
    } else {
      throw StateError('Unrecognized for parts');
    }
  }

  void _pushIfElement(bool hasElse) {
    CollectionElement elseElement = hasElse ? _popCollectionElement() : null;
    CollectionElement thenElement = _popCollectionElement();
    Expression condition = _pop();
    _pushCollectionElement(
        AstTestFactory.ifElement(condition, thenElement, elseElement));
  }

  void _pushInstanceCreation() {
    EntityRef ref = _uc.references[refPtr++];
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
        // Unexpected element, consider it unresolved.
        _buildArguments();
        var identifier = AstTestFactory.identifier3('__unresolved__')
          ..staticType = resynthesizer.typeProvider.dynamicType;
        _push(identifier);
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
    EntityRef ref = _uc.references[refPtr++];
    ReferenceInfo info = resynthesizer.getReferenceInfo(ref.reference);
    Expression node = _buildIdentifierSequence(info);
    TypeArgumentList typeArguments = _buildTypeArguments();
    var period = TokenFactory.tokenFromType(TokenType.PERIOD);
    var argumentList = AstTestFactory.argumentList(arguments);

    // Check for optional new/const.
    if (info.element is ClassElement) {
      _push(_buildCreation(node, typeArguments, argumentList,
          classElement: info.element));
      return;
    }
    if (info.element is ConstructorElement) {
      _push(_buildCreation(node, typeArguments, argumentList,
          constructorElement: info.element));
      return;
    }

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
    int count = _uc.ints[intPtr++];
    List<CollectionElement> elements =
        isSpreadOrControlFlowEnabled ? <CollectionElement>[] : <Expression>[];
    for (int i = 0; i < count; i++) {
      elements.insert(0, _popCollectionElement());
    }
    var typeArg = typeArguments == null
        ? resynthesizer.typeProvider.dynamicType
        : typeArguments.arguments[0].type;
    var staticType = resynthesizer.typeProvider.listType.instantiate([typeArg]);
    _push(AstTestFactory.listLiteral2(Keyword.CONST, typeArguments, elements)
      ..staticType = staticType);
  }

  void _pushLocalFunctionReference() {
    int popCount = _uc.ints[intPtr++];
    // Note: nonzero popCount is no longer used.
    assert(popCount == 0);
    int functionIndex = _uc.ints[intPtr++];
    var localFunction = localFunctions[functionIndex];
    var functionElement =
        new FunctionElementImpl.forSerialized(localFunction, context);
    for (ParameterElementImpl parameter in functionElement.parameters) {
      variablesInScope.push(parameter);
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
              variablesInScope: variablesInScope,
              localFunctions: localFunction.localFunctions)
          .build();
      functionBody = astFactory.expressionFunctionBody(asyncKeyword,
          TokenFactory.tokenFromType(TokenType.FUNCTION), bodyExpr, null);
    }
    variablesInScope.pop(functionElement.parameters.length);
    FunctionExpressionImpl functionExpression = astFactory.functionExpression(
        null, AstTestFactory.formalParameterList(parameters), functionBody);
    functionExpression.declaredElement = functionElement;
    _push(functionExpression);
  }

  void _pushMap(TypeArgumentList typeArguments) {
    int count = _uc.ints[intPtr++];
    List<MapLiteralEntry> entries = <MapLiteralEntry>[];
    for (int i = 0; i < count; i++) {
      Expression value = _pop();
      Expression key = _pop();
      entries.insert(0, AstTestFactory.mapLiteralEntry2(key, value));
    }
    var keyType = typeArguments == null
        ? resynthesizer.typeProvider.dynamicType
        : typeArguments.arguments[0].type;
    var valueType = typeArguments == null
        ? resynthesizer.typeProvider.dynamicType
        : typeArguments.arguments[1].type;
    var staticType =
        resynthesizer.typeProvider.mapType.instantiate([keyType, valueType]);
    SetOrMapLiteralImpl literal =
        AstTestFactory.setOrMapLiteral(Keyword.CONST, typeArguments, entries);
    literal.becomeMap();
    literal.staticType = staticType;
    _push(literal);
  }

  void _pushMapLiteralEntry() {
    Expression value = _pop();
    Expression key = _pop();
    _pushCollectionElement(AstTestFactory.mapLiteralEntry2(key, value));
  }

  void _pushNode(AstNode node) {
    stack.add(node);
  }

  void _pushPrefix(TokenType operator) {
    Expression operand = _pop();
    _push(AstTestFactory.prefixExpression(operator, operand));
  }

  void _pushReference() {
    _push(_createReference());
  }

  void _pushSet(TypeArgumentList typeArguments) {
    int count = _uc.ints[intPtr++];
    List<Expression> elements = <Expression>[];
    for (int i = 0; i < count; i++) {
      elements.insert(0, _pop());
    }
    SetOrMapLiteralImpl literal =
        AstTestFactory.setOrMapLiteral(Keyword.CONST, typeArguments, elements);
    literal.becomeSet();
    _push(literal);
  }

  void _pushSetOrMap(TypeArgumentList typeArguments) {
    int count = _uc.ints[intPtr++];
    List<CollectionElement> elements = <CollectionElement>[];
    for (int i = 0; i < count; i++) {
      elements.insert(0, _popCollectionElement());
    }

    bool isMap = true; // assume Map unless can prove otherwise
    DartType staticType;
    if (typeArguments != null) {
      if (typeArguments.arguments.length == 2) {
        var keyType = typeArguments.arguments[0].type;
        var valueType = typeArguments.arguments[1].type;
        staticType = resynthesizer.typeProvider.mapType
            .instantiate([keyType, valueType]);
      } else if (typeArguments.arguments.length == 1) {
        isMap = false;
        var valueType = typeArguments == null
            ? resynthesizer.typeProvider.dynamicType
            : typeArguments.arguments[0].type;
        staticType =
            resynthesizer.typeProvider.setType.instantiate([valueType]);
      }
    } else {
      for (var i = 0; i < elements.length; ++i) {
        var element = elements[i];
        if (element is Expression) {
          isMap = false;
        }
      }
    }

    SetOrMapLiteral setOrMapLiteral = astFactory.setOrMapLiteral(
      constKeyword: TokenFactory.tokenFromKeyword(Keyword.CONST),
      typeArguments: typeArguments,
      leftBracket: TokenFactory.tokenFromType(TokenType.OPEN_CURLY_BRACKET),
      elements: elements,
      rightBracket: TokenFactory.tokenFromType(TokenType.CLOSE_CURLY_BRACKET),
    );
    if (becomeSetOrMap) {
      if (isMap) {
        (setOrMapLiteral as SetOrMapLiteralImpl).becomeMap();
      } else {
        (setOrMapLiteral as SetOrMapLiteralImpl).becomeSet();
      }
    }
    _push(setOrMapLiteral..staticType = staticType);
  }

  void _pushSpread(TokenType operator) {
    Expression operand = _pop();
    _pushCollectionElement(AstTestFactory.spreadElement(operator, operand));
  }

  List<Expression> _removeTopExpressions(int count) {
    int start = stack.length - count;
    int end = stack.length;
    List<Expression> items = List<Expression>.from(stack.getRange(start, end));
    stack.removeRange(start, end);
    return items;
  }

  void _variableDeclaration() {
    var index = _uc.ints[intPtr++];
    var element = variablesInScope.recent(index);
    var initializer = _pop();
    var variableDeclaration =
        AstTestFactory.variableDeclaration2(element.name, initializer);
    variableDeclaration.name.staticElement = element;
    _pushNode(variableDeclaration);
  }

  void _variableDeclarationStart() {
    var name = _uc.strings[stringPtr++];
    variablesInScope.push(LocalVariableElementImpl(name, -1));
  }

  /// Figures out the default value of [parametersInScope] based on [context].
  ///
  /// If [context] is (or contains) a constructor, then its parameters are used.
  /// Otherwise, no parameters are considered to be in scope.
  static _VariablesInScope _parametersInScope(Element context) {
    var result = _VariablesInScope();
    for (Element e = context; e != null; e = e.enclosingElement) {
      if (e is ConstructorElement) {
        for (var parameter in e.parameters) {
          result.push(parameter);
        }
        return result;
      }
    }
    return result;
  }
}

/// Tracks the set of variables that are in scope while resynthesizing an
/// expression from a summary.
class _VariablesInScope {
  final _variableElements = <VariableElement>[];

  /// Returns the number of variables that have been pushed but not popped.
  int get count => _variableElements.length;

  /// Looks up the variable with the given [name].  Returns `null` if no
  /// variable is found.
  VariableElement operator [](String name) {
    for (int i = _variableElements.length - 1; i >= 0; i--) {
      if (_variableElements[i].name == name) return _variableElements[i];
    }
    return null;
  }

  /// Un-does the effect of the last [count] calls to `push`.
  void pop(int count) {
    _variableElements.length -= count;
  }

  /// Stores a new declaration based on the given [variableElement].  The
  /// declaration shadows any previous declaration with the same name.
  void push(VariableElement variableElement) {
    _variableElements.add(variableElement);
  }

  /// Retrieves the [index]th most recently pushed element (that hasn't been
  /// popped).  [index] counts from zero.
  VariableElement recent(int index) =>
      _variableElements[_variableElements.length - 1 - index];
}
