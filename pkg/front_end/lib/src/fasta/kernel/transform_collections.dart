// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.transform_collections;

import 'package:kernel/ast.dart';

import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/src/legacy_erasure.dart';
import 'package:kernel/type_algebra.dart';

import 'package:kernel/type_environment.dart'
    show SubtypeCheckMode, TypeEnvironment;

import 'collections.dart'
    show
        ControlFlowElement,
        ControlFlowMapEntry,
        ForElement,
        ForInElement,
        ForInMapEntry,
        ForMapEntry,
        IfElement,
        IfMapEntry,
        SpreadElement,
        SpreadMapEntry;

import '../problems.dart' show getFileUri, unhandled;

import '../source/source_loader.dart';

import 'redirecting_factory_body.dart' show RedirectingFactoryBody;

class CollectionTransformer extends Transformer {
  final SourceLoader _loader;
  final TypeEnvironment _typeEnvironment;
  final Procedure _listAdd;
  late final FunctionType _listAddFunctionType;
  final Procedure _listAddAll;
  late final FunctionType _listAddAllFunctionType;
  final Procedure _listOf;
  final Procedure _setFactory;
  final Procedure _setAdd;
  late final FunctionType _setAddFunctionType;
  final Procedure _setAddAll;
  late final FunctionType _setAddAllFunctionType;
  final Procedure _setOf;
  final Procedure _mapEntries;
  final Procedure _mapPut;
  late final FunctionType _mapPutFunctionType;
  final Class _mapEntryClass;
  final Field _mapEntryKey;
  final Field _mapEntryValue;
  final SourceLoaderDataForTesting? _dataForTesting;

  /// Library that contains the transformed nodes.
  ///
  /// The transformation of the nodes is affected by the NNBD opt-in status of
  /// the library.
  Library? _currentLibrary;

  static Procedure _findSetFactory(CoreTypes coreTypes, String name) {
    Procedure factory = coreTypes.index.getProcedure('dart:core', 'Set', name);
    RedirectingFactoryBody body =
        factory.function.body as RedirectingFactoryBody;
    return body.target as Procedure;
  }

  CollectionTransformer(this._loader)
      : _typeEnvironment = _loader.typeInferenceEngine.typeSchemaEnvironment,
        _listAdd =
            _loader.coreTypes.index.getProcedure('dart:core', 'List', 'add'),
        _listAddAll =
            _loader.coreTypes.index.getProcedure('dart:core', 'List', 'addAll'),
        _listOf =
            _loader.coreTypes.index.getProcedure('dart:core', 'List', 'of'),
        _setFactory = _findSetFactory(_loader.coreTypes, ''),
        _setAdd =
            _loader.coreTypes.index.getProcedure('dart:core', 'Set', 'add'),
        _setAddAll =
            _loader.coreTypes.index.getProcedure('dart:core', 'Set', 'addAll'),
        _setOf = _findSetFactory(_loader.coreTypes, 'of'),
        _mapEntries = _loader.coreTypes.index
            .getProcedure('dart:core', 'Map', 'get:entries'),
        _mapPut =
            _loader.coreTypes.index.getProcedure('dart:core', 'Map', '[]='),
        _mapEntryClass =
            _loader.coreTypes.index.getClass('dart:core', 'MapEntry'),
        _mapEntryKey =
            _loader.coreTypes.index.getField('dart:core', 'MapEntry', 'key'),
        _mapEntryValue =
            _loader.coreTypes.index.getField('dart:core', 'MapEntry', 'value'),
        _dataForTesting = _loader.dataForTesting {
    _listAddFunctionType = _listAdd.getterType as FunctionType;
    _listAddAllFunctionType = _listAddAll.getterType as FunctionType;
    _setAddFunctionType = _setAdd.getterType as FunctionType;
    _setAddAllFunctionType = _setAddAll.getterType as FunctionType;
    _mapPutFunctionType = _mapPut.getterType as FunctionType;
  }

  T? _transformNullable<T extends TreeNode>(T? node) {
    if (node == null) {
      return null;
    } else {
      return transform(node);
    }
  }

  TreeNode _translateListOrSet(
      Expression node, DartType elementType, List<Expression> elements,
      {bool isSet: false}) {
    // Translate elements in place up to the first non-expression, if any.
    int index = 0;
    for (; index < elements.length; ++index) {
      if (elements[index] is ControlFlowElement) break;
      elements[index] = transform(elements[index])..parent = node;
    }

    // If there were only expressions, we are done.
    if (index == elements.length) return node;

    InterfaceType receiverType = isSet
        ? _typeEnvironment.setType(elementType, _currentLibrary!.nonNullable)
        : _typeEnvironment.listType(elementType, _currentLibrary!.nonNullable);
    VariableDeclaration? result;
    if (index == 0 && elements[index] is SpreadElement) {
      SpreadElement initialSpread = elements[index] as SpreadElement;
      final bool typeMatches = initialSpread.elementType != null &&
          _typeEnvironment.isSubtypeOf(initialSpread.elementType!, elementType,
              SubtypeCheckMode.withNullabilities);
      if (typeMatches && !initialSpread.isNullAware) {
        // Create a list or set of the initial spread element.
        Expression value = transform(initialSpread.expression);
        index++;
        if (isSet) {
          result = _createVariable(
              new StaticInvocation(
                  _setOf,
                  new Arguments([value], types: [elementType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
        } else {
          result = _createVariable(
              new StaticInvocation(
                  _listOf,
                  new Arguments([value], types: [elementType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
        }
      }
    }
    List<Statement>? body;
    if (result == null) {
      // Create a list or set with the elements up to the first non-expression.
      if (isSet) {
        if (_loader.target.backendTarget.supportsSetLiterals) {
          // Include the elements up to the first non-expression in the set
          // literal.
          result = _createVariable(
              _createSetLiteral(
                  node.fileOffset, elementType, elements.sublist(0, index)),
              receiverType);
        } else {
          // TODO(johnniwinther): When all the back ends handle set literals we
          //  can use remove this branch.

          // Create an empty set using the [setFactory] constructor.
          result = _createVariable(
              new StaticInvocation(
                  _setFactory,
                  new Arguments([], types: [elementType])
                    ..fileOffset = node.fileOffset)
                ..fileOffset = node.fileOffset,
              receiverType);
          body = [result];
          // Add the elements up to the first non-expression.
          for (int j = 0; j < index; ++j) {
            _addExpressionElement(elements[j], receiverType, result, body,
                isSet: isSet);
          }
        }
      } else {
        // Include the elements up to the first non-expression in the list
        // literal.
        result = _createVariable(
            _createListLiteral(
                node.fileOffset, elementType, elements.sublist(0, index)),
            receiverType);
      }
    }
    body ??= [result];
    // Translate the elements starting with the first non-expression.
    for (; index < elements.length; ++index) {
      _translateElement(
          elements[index], receiverType, elementType, result, body,
          isSet: isSet);
    }

    return _createBlockExpression(
        node.fileOffset, _createBlock(body), _createVariableGet(result));
  }

  void _translateElement(Expression element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    if (element is SpreadElement) {
      _translateSpreadElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else if (element is IfElement) {
      _translateIfElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else if (element is ForElement) {
      _translateForElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else if (element is ForInElement) {
      _translateForInElement(element, receiverType, elementType, result, body,
          isSet: isSet);
    } else {
      _addExpressionElement(transform(element), receiverType, result, body,
          isSet: isSet);
    }
  }

  void _addExpressionElement(Expression element, InterfaceType receiverType,
      VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    body.add(_createExpressionStatement(_createAdd(
        _createVariableGet(result), receiverType, element,
        isSet: isSet)));
  }

  void _translateIfElement(IfElement element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    List<Statement> thenStatements = [];
    _translateElement(
        element.then, receiverType, elementType, result, thenStatements,
        isSet: isSet);
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(element.otherwise!, receiverType, elementType, result,
          elseStatements = <Statement>[],
          isSet: isSet);
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        : _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          : _createBlock(elseStatements);
    }
    IfStatement ifStatement = _createIf(
        element.fileOffset, transform(element.condition), thenBody, elseBody);
    _dataForTesting?.registerAlias(element, ifStatement);
    body.add(ifStatement);
  }

  void _translateForElement(ForElement element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    List<Statement> statements = <Statement>[];
    _translateElement(
        element.body, receiverType, elementType, result, statements,
        isSet: isSet);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    ForStatement loop = _createForStatement(
        element.fileOffset,
        element.variables,
        _transformNullable(element.condition),
        element.updates,
        loopBody);
    transformList(loop.variables, loop);
    transformList(loop.updates, loop);
    _dataForTesting?.registerAlias(element, loop);
    body.add(loop);
  }

  void _translateForInElement(ForInElement element, InterfaceType receiverType,
      DartType elementType, VariableDeclaration result, List<Statement> body,
      {required bool isSet}) {
    List<Statement> statements;
    Statement? prologue = element.prologue;
    if (prologue == null) {
      statements = <Statement>[];
    } else {
      prologue = transform(prologue);
      statements =
          prologue is Block ? prologue.statements : <Statement>[prologue];
    }
    _translateElement(
        element.body, receiverType, elementType, result, statements,
        isSet: isSet);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    if (element.problem != null) {
      body.add(_createExpressionStatement(transform(element.problem!)));
    }
    ForInStatement loop = _createForInStatement(element.fileOffset,
        element.variable, transform(element.iterable), loopBody,
        isAsync: element.isAsync);
    _dataForTesting?.registerAlias(element, loop);
    body.add(loop);
  }

  void _translateSpreadElement(
      SpreadElement element,
      InterfaceType receiverType,
      DartType elementType,
      VariableDeclaration result,
      List<Statement> body,
      {required bool isSet}) {
    Expression value = transform(element.expression);

    final bool typeMatches = element.elementType != null &&
        _typeEnvironment.isSubtypeOf(element.elementType!, elementType,
            SubtypeCheckMode.withNullabilities);
    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to 'add'.

      // Null-aware spreads require testing the subexpression's value.
      VariableDeclaration? temp;
      if (element.isNullAware) {
        temp = _createVariable(
            value,
            _typeEnvironment.iterableType(
                typeMatches ? elementType : const DynamicType(),
                _currentLibrary!.nullable));
        body.add(temp);
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(_createAddAll(
          _createVariableGet(result), receiverType, value, isSet));

      if (element.isNullAware) {
        statement = _createIf(
            temp!.fileOffset,
            _createEqualsNull(_createVariableGet(temp), notEquals: true),
            statement);
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      VariableDeclaration? temp;
      if (element.isNullAware) {
        temp = _createVariable(
            value,
            _typeEnvironment.iterableType(
                typeMatches ? elementType : const DynamicType(),
                _currentLibrary!.nullable));
        body.add(temp);
        value = _createNullCheckedVariableGet(temp);
      }

      VariableDeclaration variable;
      Statement loopBody;
      if (!typeMatches) {
        variable =
            _createForInVariable(element.fileOffset, const DynamicType());
        VariableDeclaration castedVar = _createVariable(
            _createImplicitAs(element.expression.fileOffset,
                _createVariableGet(variable), elementType),
            elementType);
        loopBody = _createBlock(<Statement>[
          castedVar,
          _createExpressionStatement(_createAdd(_createVariableGet(result),
              receiverType, _createVariableGet(castedVar),
              isSet: isSet))
        ]);
      } else {
        variable = _createForInVariable(element.fileOffset, elementType);
        loopBody = _createExpressionStatement(_createAdd(
            _createVariableGet(result),
            receiverType,
            _createVariableGet(variable),
            isSet: isSet));
      }
      Statement statement =
          _createForInStatement(element.fileOffset, variable, value, loopBody);

      if (element.isNullAware) {
        statement = _createIf(
            temp!.fileOffset,
            _createEqualsNull(_createVariableGet(temp), notEquals: true),
            statement);
      }
      body.add(statement);
    }
  }

  @override
  TreeNode visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      return _translateConstListOrSet(node, node.typeArgument, node.expressions,
          isSet: false);
    }

    return _translateListOrSet(node, node.typeArgument, node.expressions,
        isSet: false);
  }

  @override
  TreeNode visitSetLiteral(SetLiteral node) {
    if (node.isConst) {
      return _translateConstListOrSet(node, node.typeArgument, node.expressions,
          isSet: true);
    }

    return _translateListOrSet(node, node.typeArgument, node.expressions,
        isSet: true);
  }

  @override
  TreeNode visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      return _translateConstMap(node);
    }

    // Translate entries in place up to the first control-flow entry, if any.
    int i = 0;
    for (; i < node.entries.length; ++i) {
      if (node.entries[i] is ControlFlowMapEntry) break;
      node.entries[i] = transform(node.entries[i])..parent = node;
    }

    // If there were no control-flow entries we are done.
    if (i == node.entries.length) return node;

    // Build a block expression and create an empty map.
    InterfaceType receiverType = _typeEnvironment.mapType(
        node.keyType, node.valueType, _currentLibrary!.nonNullable);
    VariableDeclaration result = _createVariable(
        _createMapLiteral(node.fileOffset, node.keyType, node.valueType, []),
        receiverType);
    List<Statement> body = [result];
    // Add all the entries up to the first control-flow entry.
    for (int j = 0; j < i; ++j) {
      _addNormalEntry(node.entries[j], receiverType, result, body);
    }
    for (; i < node.entries.length; ++i) {
      _translateEntry(node.entries[i], receiverType, node.keyType,
          node.valueType, result, body);
    }

    return _createBlockExpression(
        node.fileOffset, _createBlock(body), _createVariableGet(result));
  }

  void _translateEntry(
      MapLiteralEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    if (entry is SpreadMapEntry) {
      _translateSpreadEntry(
          entry, receiverType, keyType, valueType, result, body);
    } else if (entry is IfMapEntry) {
      _translateIfEntry(entry, receiverType, keyType, valueType, result, body);
    } else if (entry is ForMapEntry) {
      _translateForEntry(entry, receiverType, keyType, valueType, result, body);
    } else if (entry is ForInMapEntry) {
      _translateForInEntry(
          entry, receiverType, keyType, valueType, result, body);
    } else {
      _addNormalEntry(transform(entry), receiverType, result, body);
    }
  }

  void _addNormalEntry(MapLiteralEntry entry, InterfaceType receiverType,
      VariableDeclaration result, List<Statement> body) {
    body.add(_createExpressionStatement(_createIndexSet(entry.fileOffset,
        _createVariableGet(result), receiverType, entry.key, entry.value)));
  }

  void _translateIfEntry(
      IfMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> thenBody = [];
    _translateEntry(
        entry.then, receiverType, keyType, valueType, result, thenBody);
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateEntry(entry.otherwise!, receiverType, keyType, valueType,
          result, elseBody = <Statement>[]);
    }
    Statement thenStatement =
        thenBody.length == 1 ? thenBody.first : _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement =
          elseBody.length == 1 ? elseBody.first : _createBlock(elseBody);
    }
    IfStatement ifStatement = _createIf(entry.fileOffset,
        transform(entry.condition), thenStatement, elseStatement);
    _dataForTesting?.registerAlias(entry, ifStatement);
    body.add(ifStatement);
  }

  void _translateForEntry(
      ForMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> statements = <Statement>[];
    _translateEntry(
        entry.body, receiverType, keyType, valueType, result, statements);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    ForStatement loop = _createForStatement(entry.fileOffset, entry.variables,
        _transformNullable(entry.condition), entry.updates, loopBody);
    _dataForTesting?.registerAlias(entry, loop);
    transformList(loop.variables, loop);
    transformList(loop.updates, loop);
    body.add(loop);
  }

  void _translateForInEntry(
      ForInMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    List<Statement> statements;
    Statement? prologue = entry.prologue;
    if (prologue == null) {
      statements = <Statement>[];
    } else {
      prologue = transform(prologue);
      statements =
          prologue is Block ? prologue.statements : <Statement>[prologue];
    }
    _translateEntry(
        entry.body, receiverType, keyType, valueType, result, statements);
    Statement loopBody =
        statements.length == 1 ? statements.first : _createBlock(statements);
    if (entry.problem != null) {
      body.add(_createExpressionStatement(transform(entry.problem!)));
    }
    ForInStatement loop = _createForInStatement(
        entry.fileOffset, entry.variable, transform(entry.iterable), loopBody,
        isAsync: entry.isAsync);
    _dataForTesting?.registerAlias(entry, loop);
    body.add(loop);
  }

  void _translateSpreadEntry(
      SpreadMapEntry entry,
      InterfaceType receiverType,
      DartType keyType,
      DartType valueType,
      VariableDeclaration result,
      List<Statement> body) {
    Expression value = transform(entry.expression);

    final InterfaceType entryType = new InterfaceType(_mapEntryClass,
        _currentLibrary!.nonNullable, <DartType>[keyType, valueType]);
    final bool typeMatches = entry.entryType != null &&
        _typeEnvironment.isSubtypeOf(
            entry.entryType!, entryType, SubtypeCheckMode.withNullabilities);

    // Null-aware spreads require testing the subexpression's value.
    VariableDeclaration? temp;
    if (entry.isNullAware) {
      temp = _createVariable(
          value,
          _typeEnvironment.mapType(
              typeMatches ? keyType : const DynamicType(),
              typeMatches ? valueType : const DynamicType(),
              _currentLibrary!.nullable));
      body.add(temp);
      value = _createNullCheckedVariableGet(temp);
    }

    VariableDeclaration variable;
    Statement loopBody;
    if (!typeMatches) {
      final InterfaceType variableType = new InterfaceType(
          _mapEntryClass,
          _currentLibrary!.nonNullable,
          <DartType>[const DynamicType(), const DynamicType()]);
      variable = _createForInVariable(entry.fileOffset, variableType);
      VariableDeclaration keyVar = _createVariable(
          _createImplicitAs(
              entry.expression.fileOffset,
              _createGetKey(entry.expression.fileOffset,
                  _createVariableGet(variable), variableType),
              keyType),
          keyType);
      VariableDeclaration valueVar = _createVariable(
          _createImplicitAs(
              entry.expression.fileOffset,
              _createGetValue(entry.expression.fileOffset,
                  _createVariableGet(variable), variableType),
              valueType),
          valueType);
      loopBody = _createBlock(<Statement>[
        keyVar,
        valueVar,
        _createExpressionStatement(_createIndexSet(
            entry.expression.fileOffset,
            _createVariableGet(result),
            receiverType,
            _createVariableGet(keyVar),
            _createVariableGet(valueVar)))
      ]);
    } else {
      variable = _createForInVariable(entry.fileOffset, entryType);
      loopBody = _createExpressionStatement(_createIndexSet(
          entry.expression.fileOffset,
          _createVariableGet(result),
          receiverType,
          _createGetKey(entry.expression.fileOffset,
              _createVariableGet(variable), entryType),
          _createGetValue(entry.expression.fileOffset,
              _createVariableGet(variable), entryType)));
    }
    Statement statement = _createForInStatement(entry.fileOffset, variable,
        _createGetEntries(entry.fileOffset, value, receiverType), loopBody);

    if (entry.isNullAware) {
      statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement);
    }
    body.add(statement);
  }

  TreeNode _translateConstListOrSet(
      Expression node, DartType elementType, List<Expression> elements,
      {bool isSet: false}) {
    // Translate elements in place up to the first non-expression, if any.
    int i = 0;
    for (; i < elements.length; ++i) {
      if (elements[i] is ControlFlowElement) break;
      elements[i] = transform(elements[i])..parent = node;
    }

    // If there were only expressions, we are done.
    if (i == elements.length) return node;

    Expression makeLiteral(int fileOffset, List<Expression> expressions) {
      if (isSet) {
        return _createSetLiteral(fileOffset, elementType, expressions,
            isConst: true);
      } else {
        return _createListLiteral(fileOffset, elementType, expressions,
            isConst: true);
      }
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<Expression>? currentPart = i > 0 ? elements.sublist(0, i) : null;

    DartType iterableType = _typeEnvironment.iterableType(
        elementType, _currentLibrary!.nonNullable);

    for (; i < elements.length; ++i) {
      Expression element = elements[i];
      if (element is SpreadElement) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression spreadExpression = transform(element.expression);
        if (element.isNullAware) {
          VariableDeclaration temp = _createVariable(
              spreadExpression,
              _typeEnvironment.iterableType(
                  elementType, _currentLibrary!.nullable));
          parts.add(_createNullAwareGuard(element.fileOffset, temp,
              makeLiteral(element.fileOffset, []), iterableType));
        } else {
          parts.add(spreadExpression);
        }
      } else if (element is IfElement) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression condition = transform(element.condition);
        Expression then =
            transform(makeLiteral(element.then.fileOffset, [element.then]));
        Expression otherwise = element.otherwise != null
            ? transform(makeLiteral(
                element.otherwise!.fileOffset, [element.otherwise!]))
            : makeLiteral(element.fileOffset, []);
        parts.add(_createConditionalExpression(
            element.fileOffset, condition, then, otherwise, iterableType));
      } else if (element is ForElement || element is ForInElement) {
        // Rejected earlier.
        unhandled("${element.runtimeType}", "_translateConstListOrSet",
            element.fileOffset, getFileUri(element));
      } else {
        currentPart ??= <Expression>[];
        currentPart.add(transform(element));
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(node.fileOffset, currentPart));
    }
    if (isSet) {
      return new SetConcatenation(parts, typeArgument: elementType)
        ..fileOffset = node.fileOffset;
    } else {
      return new ListConcatenation(parts, typeArgument: elementType)
        ..fileOffset = node.fileOffset;
    }
  }

  TreeNode _translateConstMap(MapLiteral node) {
    // Translate entries in place up to the first control-flow entry, if any.
    int i = 0;
    for (; i < node.entries.length; ++i) {
      if (node.entries[i] is ControlFlowMapEntry) break;
      node.entries[i] = transform(node.entries[i])..parent = node;
    }

    // If there were no control-flow entries we are done.
    if (i == node.entries.length) return node;

    MapLiteral makeLiteral(int fileOffset, List<MapLiteralEntry> entries) {
      return _createMapLiteral(
          fileOffset, node.keyType, node.valueType, entries,
          isConst: true);
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<MapLiteralEntry>? currentPart =
        i > 0 ? node.entries.sublist(0, i) : null;

    DartType collectionType = _typeEnvironment.mapType(
        node.keyType, node.valueType, _currentLibrary!.nonNullable);

    for (; i < node.entries.length; ++i) {
      MapLiteralEntry entry = node.entries[i];
      if (entry is SpreadMapEntry) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression spreadExpression = transform(entry.expression);
        if (entry.isNullAware) {
          VariableDeclaration temp = _createVariable(
              spreadExpression,
              collectionType
                  .withDeclaredNullability(_currentLibrary!.nullable));
          parts.add(_createNullAwareGuard(entry.fileOffset, temp,
              makeLiteral(entry.fileOffset, []), collectionType));
        } else {
          parts.add(spreadExpression);
        }
      } else if (entry is IfMapEntry) {
        if (currentPart != null) {
          parts.add(makeLiteral(node.fileOffset, currentPart));
          currentPart = null;
        }
        Expression condition = transform(entry.condition);
        Expression then =
            transform(makeLiteral(entry.then.fileOffset, [entry.then]));
        Expression otherwise = entry.otherwise != null
            ? transform(
                makeLiteral(entry.otherwise!.fileOffset, [entry.otherwise!]))
            : makeLiteral(node.fileOffset, []);
        parts.add(_createConditionalExpression(
            entry.fileOffset, condition, then, otherwise, collectionType));
      } else if (entry is ForMapEntry || entry is ForInMapEntry) {
        // Rejected earlier.
        unhandled("${entry.runtimeType}", "_translateConstMap",
            entry.fileOffset, getFileUri(entry));
      } else {
        currentPart ??= <MapLiteralEntry>[];
        currentPart.add(transform(entry));
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(node.fileOffset, currentPart));
    }
    return new MapConcatenation(parts,
        keyType: node.keyType, valueType: node.valueType);
  }

  void enterLibrary(Library library) {
    assert(
        _currentLibrary == null,
        "Attempting to enter library '${library.fileUri}' "
        "without having exited library '${_currentLibrary!.fileUri}'.");
    _currentLibrary = library;
  }

  void exitLibrary() {
    assert(_currentLibrary != null,
        "Attempting to exit a library without having entered one.");
    _currentLibrary = null;
  }

  VariableDeclaration _createVariable(Expression expression, DartType type) {
    // ignore: unnecessary_null_comparison
    assert(expression != null);
    assert(expression.fileOffset != TreeNode.noOffset);
    return new VariableDeclaration.forValue(expression, type: type)
      ..fileOffset = expression.fileOffset;
  }

  VariableDeclaration _createForInVariable(int fileOffset, DartType type) {
    assert(fileOffset != TreeNode.noOffset);
    return new VariableDeclaration.forValue(null, type: type)
      ..fileOffset = fileOffset;
  }

  VariableGet _createVariableGet(VariableDeclaration variable) {
    // ignore: unnecessary_null_comparison
    assert(variable != null);
    assert(variable.fileOffset != TreeNode.noOffset);
    return new VariableGet(variable)..fileOffset = variable.fileOffset;
  }

  VariableGet _createNullCheckedVariableGet(VariableDeclaration variable) {
    // ignore: unnecessary_null_comparison
    assert(variable != null);
    assert(variable.fileOffset != TreeNode.noOffset);
    DartType promotedType =
        variable.type.withDeclaredNullability(_currentLibrary!.nonNullable);
    if (promotedType != variable.type) {
      return new VariableGet(variable, promotedType)
        ..fileOffset = variable.fileOffset;
    }
    return _createVariableGet(variable);
  }

  MapLiteral _createMapLiteral(int fileOffset, DartType keyType,
      DartType valueType, List<MapLiteralEntry> entries,
      {bool isConst: false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new MapLiteral(entries,
        keyType: keyType, valueType: valueType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  ListLiteral _createListLiteral(
      int fileOffset, DartType elementType, List<Expression> elements,
      {bool isConst: false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new ListLiteral(elements,
        typeArgument: elementType, isConst: isConst)
      ..fileOffset = fileOffset;
  }

  Expression _createSetLiteral(
      int fileOffset, DartType elementType, List<Expression> elements,
      {bool isConst: false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    if (isConst) {
      return new SetLiteral(elements,
          typeArgument: elementType, isConst: isConst)
        ..fileOffset = fileOffset;
    } else {
      return new SetLiteral(elements,
          typeArgument: elementType, isConst: isConst)
        ..fileOffset = fileOffset;
    }
  }

  ExpressionStatement _createExpressionStatement(Expression expression) {
    // ignore: unnecessary_null_comparison
    assert(expression != null);
    assert(expression.fileOffset != TreeNode.noOffset);
    return new ExpressionStatement(expression)
      ..fileOffset = expression.fileOffset;
  }

  Expression _createAdd(
      Expression receiver, InterfaceType receiverType, Expression argument,
      {required bool isSet}) {
    // ignore: unnecessary_null_comparison
    assert(receiver != null);
    // ignore: unnecessary_null_comparison
    assert(argument != null);
    assert(argument.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${argument}.");
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(isSet ? _setAddFunctionType : _listAddFunctionType);
    if (!_currentLibrary!.isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('add'), new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: isSet ? _setAdd : _listAdd)
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createAddAll(Expression receiver, InterfaceType receiverType,
      Expression argument, bool isSet) {
    // ignore: unnecessary_null_comparison
    assert(receiver != null);
    // ignore: unnecessary_null_comparison
    assert(argument != null);
    assert(argument.fileOffset != TreeNode.noOffset,
        "No fileOffset on ${argument}.");
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(
            isSet ? _setAddAllFunctionType : _listAddAllFunctionType);
    if (!_currentLibrary!.isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('addAll'), new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: isSet ? _setAddAll : _listAddAll)
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createEqualsNull(Expression expression, {bool notEquals: false}) {
    // ignore: unnecessary_null_comparison
    assert(expression != null);
    assert(expression.fileOffset != TreeNode.noOffset);
    Expression check = new EqualsNull(expression)
      ..fileOffset = expression.fileOffset;
    if (notEquals) {
      check = new Not(check)..fileOffset = expression.fileOffset;
    }
    return check;
  }

  Expression _createIndexSet(int fileOffset, Expression receiver,
      InterfaceType receiverType, Expression key, Expression value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(_mapPutFunctionType);
    if (!_currentLibrary!.isNonNullableByDefault) {
      functionType = legacyErasure(functionType);
    }
    return new InstanceInvocation(InstanceAccessKind.Instance, receiver,
        new Name('[]='), new Arguments([key, value]),
        functionType: functionType as FunctionType, interfaceTarget: _mapPut)
      ..fileOffset = fileOffset
      ..isInvariant = true;
  }

  AsExpression _createImplicitAs(
      int fileOffset, Expression expression, DartType type) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new AsExpression(expression, type)
      ..isTypeError = true
      ..isForNonNullableByDefault = _currentLibrary!.isNonNullableByDefault
      ..fileOffset = fileOffset;
  }

  IfStatement _createIf(int fileOffset, Expression condition, Statement then,
      [Statement? otherwise]) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new IfStatement(condition, then, otherwise)..fileOffset = fileOffset;
  }

  Expression _createGetKey(
      int fileOffset, Expression receiver, InterfaceType entryType) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(_mapEntryKey.type);
    return new InstanceGet(
        InstanceAccessKind.Instance, receiver, new Name('key'),
        interfaceTarget: _mapEntryKey, resultType: resultType)
      ..fileOffset = fileOffset;
  }

  Expression _createGetValue(
      int fileOffset, Expression receiver, InterfaceType entryType) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(_mapEntryValue.type);
    return new InstanceGet(
        InstanceAccessKind.Instance, receiver, new Name('value'),
        interfaceTarget: _mapEntryValue, resultType: resultType)
      ..fileOffset = fileOffset;
  }

  Expression _createGetEntries(
      int fileOffset, Expression receiver, InterfaceType mapType) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(mapType)
        .substituteType(_mapEntries.getterType);
    return new InstanceGet(
        InstanceAccessKind.Instance, receiver, new Name('entries'),
        interfaceTarget: _mapEntries, resultType: resultType)
      ..fileOffset = fileOffset;
  }

  ForStatement _createForStatement(
      int fileOffset,
      List<VariableDeclaration> variables,
      Expression? condition,
      List<Expression> updates,
      Statement body) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new ForStatement(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  ForInStatement _createForInStatement(int fileOffset,
      VariableDeclaration variable, Expression iterable, Statement body,
      {bool isAsync: false}) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new ForInStatement(variable, iterable, body, isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  Let _createNullAwareGuard(int fileOffset, VariableDeclaration variable,
      Expression defaultValue, DartType type) {
    return new Let(
        variable,
        _createConditionalExpression(
            fileOffset,
            _createEqualsNull(_createVariableGet(variable)),
            defaultValue,
            _createNullCheckedVariableGet(variable),
            type))
      ..fileOffset = fileOffset;
  }

  Block _createBlock(List<Statement> statements) {
    return new Block(statements);
  }

  BlockExpression _createBlockExpression(
      int fileOffset, Block body, Expression value) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new BlockExpression(body, value)..fileOffset = fileOffset;
  }

  ConditionalExpression _createConditionalExpression(
      int fileOffset,
      Expression condition,
      Expression then,
      Expression otherwise,
      DartType type) {
    // ignore: unnecessary_null_comparison
    assert(fileOffset != null);
    assert(fileOffset != TreeNode.noOffset);
    return new ConditionalExpression(condition, then, otherwise, type)
      ..fileOffset = fileOffset;
  }
}
