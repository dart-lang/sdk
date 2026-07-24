// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/type_inference/type_inference_engine.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../kernel/external_ast_helper.dart' as extern;
import '../kernel/external_ast_helper.dart';
import '../kernel/inferred_collections.dart';
import '../source/source_library_builder.dart';
import 'type_schema_environment.dart';

/// Builder object used for lowering list literals.
abstract class ListLiteralBuilder {
  factory(
    TypeInferenceEngine engine,
    SourceLibraryBuilder libraryBuilder, {
    required DartType elementType,
    required bool isConst,
  }) => isConst
      ? new _ConstListLiteralBuilder(
          engine,
          libraryBuilder,
          elementType: elementType,
        )
      : new _NonConstListLiteralBuilder(
          engine,
          libraryBuilder,
          elementType: elementType,
        );

  /// Creates the lowered [Expression] for a list literal containing the given
  /// [elements].
  Expression translate({
    required List<InferredElement> elements,
    required int fileOffset,
  });
}

/// Builder object used for lowering map literals.
abstract class MapLiteralBuilder._(
  super.engine,
  super.libraryBuilder, {
  required final DartType _keyType,
  required final DartType _valueType,
}) extends _LiteralBuilder {
  factory(
    TypeInferenceEngine engine,
    SourceLibraryBuilder libraryBuilder, {
    required DartType keyType,
    required DartType valueType,
    required bool isConst,
  }) => isConst
      ? new _ConstMapLiteralBuilder(
          engine,
          libraryBuilder,
          keyType: keyType,
          valueType: valueType,
        )
      : new _NonConstMapLiteralBuilder(
          engine,
          libraryBuilder,
          keyType: keyType,
          valueType: valueType,
        );

  /// Creates the lowered [Expression] for a list literal containing the given
  /// [entries].
  Expression translate({
    required List<InferredElement> entries,
    required int fileOffset,
  });

  /// Helper method used for creating a map literal from [entries}.
  ///
  /// All [entries] are assumed to be [InferredMapEntryElement].
  MapLiteral _createMapLiteral({
    required int fileOffset,
    required List<InferredElement> entries,
    required bool isConst,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new MapLiteral(
      new List.generate(entries.length, (int index) {
        InferredMapEntryElement entry =
            entries[index] as InferredMapEntryElement;
        return extern.createMapLiteralEntry(
          entry.key,
          entry.value,
          fileOffset: entry.fileOffset,
        );
      }),
      keyType: _keyType,
      valueType: _valueType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }
}

/// Builder object used for lowering set literals.
abstract class SetLiteralBuilder {
  factory(
    TypeInferenceEngine engine,
    SourceLibraryBuilder libraryBuilder, {
    required DartType elementType,
    required bool isConst,
  }) => isConst
      ? new _ConstSetLiteralBuilder(
          engine,
          libraryBuilder,
          elementType: elementType,
        )
      : new _NonConstSetLiteralBuilder(
          engine,
          libraryBuilder,
          elementType: elementType,
        );

  /// Creates the lowered [Expression] for a set literal containing the given
  /// [elements].
  Expression translate({
    required List<InferredElement> elements,
    required int fileOffset,
  });
}

/// Builder for lowering const list literals.
class _ConstListLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required super.elementType,
}) extends _ConstListOrSetLiteralBuilder implements ListLiteralBuilder {
  @override
  Expression _createConcatenation({
    required List<Expression> parts,
    required int fileOffset,
  }) {
    return new ListConcatenation(parts, typeArgument: _elementType)
      ..fileOffset = fileOffset;
  }

  @override
  Expression _createLiteral({
    required List<Expression> expressions,
    required int fileOffset,
  }) {
    return _createListLiteral(
      fileOffset: fileOffset,
      elementType: _elementType,
      expressions: expressions,
      isConst: true,
    );
  }
}

/// Shared builder for lowering const list or set literals.
abstract class _ConstListOrSetLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required final DartType _elementType,
}) extends _ListOrSetLiteralBuilder {
  Expression translate({
    required List<InferredElement> elements,
    required int fileOffset,
  }) {
    // Translate elements in place up to the first non-expression, if any.
    int i = 0;
    for (; i < elements.length; ++i) {
      if (elements[i] is! InferredExpressionElementBase) break;
    }

    // If there were only expressions, we are done.
    if (i == elements.length) {
      return _createLiteral(
        expressions: _convertElementsToExpressions(elements),
        fileOffset: fileOffset,
      );
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<InferredElement>? currentPart = i > 0 ? elements.sublist(0, i) : null;

    DartType iterableType = _typeSchemaEnvironment.iterableType(
      _elementType,
      Nullability.nonNullable,
    );

    for (; i < elements.length; ++i) {
      InferredElement element = elements[i];
      switch (element) {
        case InferredSpreadElement():
          if (currentPart != null) {
            parts.add(translate(elements: currentPart, fileOffset: fileOffset));
            currentPart = null;
          }
          Expression spreadExpression = element.expression;
          if (element.isNullAware) {
            SyntheticVariable temp = _createVariable(
              spreadExpression,
              _typeSchemaEnvironment.iterableType(
                _elementType,
                Nullability.nullable,
              ),
            );
            parts.add(
              _createNullAwareGuard(
                element.fileOffset,
                temp,
                _createLiteral(expressions: [], fileOffset: element.fileOffset),
                iterableType,
              ),
            );
          } else {
            parts.add(spreadExpression);
          }
        case InferredNullAwareElement():
          if (currentPart != null) {
            parts.add(translate(elements: currentPart, fileOffset: fileOffset));
            currentPart = null;
          }
          SyntheticVariable temp = _createVariable(
            element.expression,
            _elementType.withDeclaredNullability(Nullability.nullable),
          );
          parts.add(
            _createNullAwareGuard(
              element.fileOffset,
              temp,
              _createLiteral(expressions: [], fileOffset: element.fileOffset),
              iterableType,
              nullCheckedValue: _createLiteral(
                expressions: [_createNullCheckedVariableGet(temp)],
                fileOffset: element.fileOffset,
              ),
            ),
          );
        case InferredIfElement():
          if (currentPart != null) {
            // Coverage-ignore-block(suite): Not run.
            parts.add(translate(elements: currentPart, fileOffset: fileOffset));
            currentPart = null;
          }
          Expression condition = element.condition;
          Expression then = translate(
            elements: [element.then],
            fileOffset: element.then.fileOffset,
          );
          Expression otherwise = element.otherwise != null
              ? translate(
                  elements: [element.otherwise!],
                  fileOffset: element.otherwise!.fileOffset,
                )
              : _createLiteral(expressions: [], fileOffset: element.fileOffset);
          parts.add(
            _createConditionalExpression(
              element.fileOffset,
              condition,
              then,
              otherwise,
              iterableType,
            ),
          );
        case InferredIfCaseElement():
        case InferredForElement():
        case InferredPatternForElement():
        case InferredForInElement():
          // Coverage-ignore(suite): Not run.
          // Rejected earlier.
          throw new UnsupportedError(
            "Unexpected element in list/set: $element",
          );
        case InferredExpressionElement():
          currentPart ??= [];
          currentPart.add(element);
        case InferredInvalidElement():
          parts.add(element.expression);
        // Coverage-ignore(suite): Not run.
        case InferredMapEntryElement():
        case InferredNullAwareMapEntryElement():
          throw new UnimplementedError('$element');
      }
    }
    if (currentPart != null) {
      parts.add(translate(elements: currentPart, fileOffset: fileOffset));
    }
    return _createConcatenation(parts: parts, fileOffset: fileOffset);
  }

  /// Creates the expression for a const list or set concatenation of the given
  /// [parts].
  Expression _createConcatenation({
    required List<Expression> parts,
    required int fileOffset,
  });

  /// Creates the expression for a const list or set literal of the given
  /// [expressions].
  Expression _createLiteral({
    required List<Expression> expressions,
    required int fileOffset,
  });
}

/// Builder for lowering const map literals.
class _ConstMapLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required super.keyType,
  required super.valueType,
}) extends MapLiteralBuilder {
  this : super._();

  @override
  Expression translate({
    required List<InferredElement> entries,
    required int fileOffset,
  }) {
    // Translate entries in place up to the first control-flow entry, if any.
    int i = 0;
    for (; i < entries.length; ++i) {
      if (entries[i] is! InferredMapEntryElement) break;
    }

    // If there were no control-flow entries we are done.
    if (i == entries.length) {
      return _createMapLiteral(
        fileOffset: fileOffset,
        entries: entries,
        isConst: true,
      );
    }

    Expression makeLiteral(int fileOffset, List<InferredElement> entries) {
      return translate(fileOffset: fileOffset, entries: entries);
    }

    // Build a concatenation node.
    List<Expression> parts = [];
    List<InferredElement>? currentPart = i > 0 ? entries.sublist(0, i) : null;

    DartType collectionType = _typeSchemaEnvironment.mapType(
      _keyType,
      _valueType,
      Nullability.nonNullable,
    );

    for (; i < entries.length; ++i) {
      InferredElement entry = entries[i];
      switch (entry) {
        case InferredSpreadElement():
          if (currentPart != null) {
            parts.add(makeLiteral(fileOffset, currentPart));
            currentPart = null;
          }
          Expression spreadExpression = entry.expression;
          if (entry.isNullAware) {
            SyntheticVariable temp = _createVariable(
              spreadExpression,
              collectionType.withDeclaredNullability(Nullability.nullable),
            );
            parts.add(
              _createNullAwareGuard(
                entry.fileOffset,
                temp,
                makeLiteral(entry.fileOffset, []),
                collectionType,
              ),
            );
          } else {
            parts.add(spreadExpression);
          }
        case InferredMapEntryElement():
          currentPart ??= [];
          currentPart.add(entry);
        case InferredNullAwareMapEntryElement():
          if (currentPart != null) {
            parts.add(makeLiteral(fileOffset, currentPart));
            currentPart = null;
          }

          Expression desugaredExpression = extern.createNullLiteral(
            fileOffset: TreeNode.noOffset,
          );

          if (entry.isKeyNullAware && entry.isValueNullAware) {
            SyntheticVariable keyTemp = _createVariable(
              entry.key,
              _keyType.withDeclaredNullability(Nullability.nullable),
            );
            Expression keyExpression = _createNullCheckedVariableGet(keyTemp);

            SyntheticVariable valueTemp = _createVariable(
              entry.value,
              _valueType.withDeclaredNullability(Nullability.nullable),
            );
            Expression valueExpression = _createNullCheckedVariableGet(
              valueTemp,
            );

            InferredMapEntryElement addedMapLiteralEntry =
                new InferredMapEntryElement(
                  key: keyExpression,
                  value: valueExpression,
                  fileOffset: entry.fileOffset,
                );
            Expression nullCheckedKeyValue = makeLiteral(
              entry.value.fileOffset,
              [addedMapLiteralEntry],
            );
            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              valueTemp,
              makeLiteral(entry.fileOffset, []),
              collectionType,
              nullCheckedValue: nullCheckedKeyValue,
            );
            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              keyTemp,
              makeLiteral(entry.fileOffset, []),
              collectionType,
              nullCheckedValue: desugaredExpression,
            );
          } else if (entry.isValueNullAware) {
            SyntheticVariable valueTemp = _createVariable(
              entry.value,
              _valueType.withDeclaredNullability(Nullability.nullable),
            );
            Expression valueExpression = _createNullCheckedVariableGet(
              valueTemp,
            );
            Expression defaultValue = makeLiteral(entry.fileOffset, []);
            InferredMapEntryElement addedMapLiteralEntry =
                new InferredMapEntryElement(
                  key: entry.key,
                  value: valueExpression,
                  fileOffset: entry.fileOffset,
                );
            Expression nullCheckedValue = makeLiteral(entry.value.fileOffset, [
              addedMapLiteralEntry,
            ]);
            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              valueTemp,
              defaultValue,
              collectionType,
              nullCheckedValue: nullCheckedValue,
            );
          } else {
            assert(entry.isKeyNullAware);
            SyntheticVariable keyTemp = _createVariable(
              entry.key,
              _keyType.withDeclaredNullability(Nullability.nullable),
            );
            Expression keyExpression = _createNullCheckedVariableGet(keyTemp);
            Expression defaultValue = makeLiteral(entry.fileOffset, []);

            InferredMapEntryElement addedMapLiteralEntry =
                new InferredMapEntryElement(
                  key: keyExpression,
                  value: entry.value,
                  fileOffset: entry.fileOffset,
                );
            Expression nullCheckedKey = makeLiteral(entry.key.fileOffset, [
              addedMapLiteralEntry,
            ]);

            desugaredExpression = _createNullAwareGuard(
              entry.fileOffset,
              keyTemp,
              defaultValue,
              collectionType,
              nullCheckedValue: nullCheckedKey,
            );
          }
          parts.add(desugaredExpression);
        case InferredIfElement():
          if (currentPart != null) {
            // Coverage-ignore-block(suite): Not run.
            parts.add(makeLiteral(fileOffset, currentPart));
            currentPart = null;
          }
          Expression condition = entry.condition;
          Expression then = makeLiteral(entry.then.fileOffset, [entry.then]);
          Expression otherwise = entry.otherwise != null
              ? makeLiteral(entry.otherwise!.fileOffset, [entry.otherwise!])
              : makeLiteral(fileOffset, []);
          parts.add(
            _createConditionalExpression(
              entry.fileOffset,
              condition,
              then,
              otherwise,
              collectionType,
            ),
          );
        case InferredInvalidElement():
          parts.add(entry.expression);
        // Coverage-ignore(suite): Not run.
        case InferredIfCaseElement():
        case InferredPatternForElement():
        case InferredForElement():
        case InferredForInElement():
        case InferredExpressionElement():
        case InferredNullAwareElement():
          // Rejected earlier.
          throw new UnsupportedError(
            "_translateConstMap on ${entry.runtimeType}",
          );
      }
    }
    if (currentPart != null) {
      parts.add(makeLiteral(fileOffset, currentPart));
    }
    return new MapConcatenation(
      parts,
      keyType: _keyType,
      valueType: _valueType,
    );
  }
}

/// Builder for lowering const set literals.
class _ConstSetLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required super.elementType,
}) extends _ConstListOrSetLiteralBuilder implements SetLiteralBuilder {
  @override
  Expression _createConcatenation({
    required List<Expression> parts,
    required int fileOffset,
  }) {
    return new SetConcatenation(parts, typeArgument: _elementType)
      ..fileOffset = fileOffset;
  }

  @override
  Expression _createLiteral({
    required List<Expression> expressions,
    required int fileOffset,
  }) {
    return _createSetLiteral(
      fileOffset: fileOffset,
      elementType: _elementType,
      expressions: expressions,
      isConst: true,
    );
  }
}

/// Shared builder for lowering list or set literals.
abstract class _ListOrSetLiteralBuilder(super.engine, super.libraryBuilder)
    extends _LiteralBuilder {
  List<Expression> _convertElementsToExpressions(
    List<InferredElement> elements, {
    int? count,
  }) {
    return new List.generate(
      count ?? elements.length,
      (int index) =>
          (elements[index] as InferredExpressionElementBase).expression,
    );
  }

  ListLiteral _createListLiteral({
    required int fileOffset,
    required DartType elementType,
    required List<Expression> expressions,
    required bool isConst,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new ListLiteral(
      expressions,
      typeArgument: elementType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }

  SetLiteral _createSetLiteral({
    required int fileOffset,
    required DartType elementType,
    required List<Expression> expressions,
    required bool isConst,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new SetLiteral(
      expressions,
      typeArgument: elementType,
      isConst: isConst,
    )..fileOffset = fileOffset;
  }
}

/// Shared builder for lowering list literals.
///
/// This provides common helper methods and properties.
abstract class _LiteralBuilder(
  final TypeInferenceEngine _engine,
  final SourceLibraryBuilder _libraryBuilder,
) {
  CoreTypes get _coreTypes => _engine.coreTypes;

  TypeSchemaEnvironment get _typeSchemaEnvironment =>
      _engine.typeSchemaEnvironment;

  Block _createBlock(List<Statement> statements) {
    return new Block(statements);
  }

  BlockExpression _createBlockExpression(
    int fileOffset,
    Block body,
    Expression value,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new BlockExpression(body, value)..fileOffset = fileOffset;
  }

  ConditionalExpression _createConditionalExpression(
    int fileOffset,
    Expression condition,
    Expression then,
    Expression otherwise,
    DartType type,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new ConditionalExpression(condition, then, otherwise, type)
      ..fileOffset = fileOffset;
  }

  Expression _createEqualsNull(
    Expression expression, {
    bool notEquals = false,
  }) {
    assert(expression.fileOffset != TreeNode.noOffset);
    Expression check = new EqualsNull(expression)
      ..fileOffset = expression.fileOffset;
    if (notEquals) {
      check = new Not(check)..fileOffset = expression.fileOffset;
    }
    return check;
  }

  ExpressionStatement _createExpressionStatement(Expression expression) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return new ExpressionStatement(expression)
      ..fileOffset = expression.fileOffset;
  }

  ForInStatement _createForInStatement(
    int fileOffset,
    DeclaredVariable variable,
    Expression iterable,
    Statement body, {
    bool isAsync = false,
  }) {
    assert(fileOffset != TreeNode.noOffset);
    return new ForInStatement(variable, iterable, body, isAsync: isAsync)
      ..fileOffset = fileOffset;
  }

  DeclaredVariable _createForInVariable(int fileOffset, DartType type) {
    assert(fileOffset != TreeNode.noOffset);
    return extern.createUninitializedVariable(
      type: type,
      fileOffset: fileOffset,
      isFinal: true,
      hasDeclaredInitializer: true,
    );
  }

  ForStatement _createForStatement(
    int fileOffset,
    List<VariableDeclaration> variables,
    Expression? condition,
    List<Expression> updates,
    Statement body,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new ForStatement(variables, condition, updates, body)
      ..fileOffset = fileOffset;
  }

  IfStatement _createIf(
    int fileOffset,
    Expression condition,
    Statement then, [
    Statement? otherwise,
  ]) {
    assert(fileOffset != TreeNode.noOffset);
    return new IfStatement(condition, then, otherwise)..fileOffset = fileOffset;
  }

  IfCaseStatement _createIfCase(
    int fileOffset,
    Expression condition,
    DartType matchedValueType,
    PatternGuard patternGuard,
    Statement then, [
    Statement? otherwise,
  ]) {
    assert(fileOffset != TreeNode.noOffset);
    return new IfCaseStatement(condition, patternGuard, then, otherwise)
      ..matchedValueType = matchedValueType
      ..fileOffset = fileOffset;
  }

  AsExpression _createImplicitAs(
    int fileOffset,
    Expression expression,
    DartType type,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    return new AsExpression(expression, type)
      ..isTypeError = true
      ..fileOffset = fileOffset;
  }

  Let _createNullAwareGuard(
    int fileOffset,
    SyntheticVariable variable,
    Expression defaultValue,
    DartType type, {
    Expression? nullCheckedValue,
  }) {
    return extern.createLet(
      variable: variable,
      body: _createConditionalExpression(
        fileOffset,
        _createEqualsNull(_createVariableGet(variable)),
        defaultValue,
        nullCheckedValue ?? _createNullCheckedVariableGet(variable),
        type,
      ),
      fileOffset: fileOffset,
    );
  }

  VariableGet _createNullCheckedVariableGet(Variable variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    DartType promotedType = variable.type.withDeclaredNullability(
      Nullability.nonNullable,
    );
    if (promotedType != variable.type) {
      return new VariableGet(variable, promotedType)
        ..fileOffset = variable.fileOffset;
    }
    return _createVariableGet(variable);
  }

  SyntheticVariable _createVariable(Expression expression, DartType type) {
    assert(expression.fileOffset != TreeNode.noOffset);
    return extern.createVariableCache(expression, type);
  }

  VariableGet _createVariableGet(Variable variable) {
    assert(variable.fileOffset != TreeNode.noOffset);
    return new VariableGet(variable)..fileOffset = variable.fileOffset;
  }
}

/// Builder for lowering non-const list literals.
class _NonConstListLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required super.elementType,
}) extends _NonConstListOrSetLiteralBuilder implements ListLiteralBuilder {
  this
    : super(
        receiverType: engine.typeSchemaEnvironment.listType(
          elementType,
          Nullability.nonNullable,
        ),
      );

  @override
  Expression _createAdd(Expression receiver, Expression argument) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(_receiverType)
        .substituteType(_engine.listAddFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('add'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: _engine.listAdd,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  @override
  Expression _createAddAll(Expression receiver, Expression argument) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(_receiverType)
        .substituteType(_engine.listAddAllFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('addAll'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: _engine.listAddAll,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  @override
  DeclaredVariable _createInitialValueFromExpressions({
    required List<Statement> body,
    required List<Expression> expressions,
    required int fileOffset,
  }) {
    // Include the elements up to the first non-expression in the list
    // literal.
    DeclaredVariable result = _createVariable(
      _createListLiteral(
        elementType: _elementType,
        expressions: expressions,
        fileOffset: fileOffset,
        isConst: false,
      ),
      _receiverType,
    );
    body.add(
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    );
    return result;
  }

  @override
  DeclaredVariable _createInitialValueFromSpread({
    required List<Statement> body,
    required Expression spread,
    required int fileOffset,
  }) {
    DeclaredVariable result = _createVariable(
      new StaticInvocation(
        _engine.listOf,
        new Arguments([spread], types: [_elementType])..fileOffset = fileOffset,
      )..fileOffset = fileOffset,
      _receiverType,
    );
    body.add(
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    );
    return result;
  }

  @override
  Expression _createLiteral({
    required List<Expression> expressions,
    required int fileOffset,
  }) {
    return _createListLiteral(
      elementType: _elementType,
      expressions: expressions,
      fileOffset: fileOffset,
      isConst: false,
    );
  }
}

/// Shared builder for lowering non-const list or set literals.
abstract class _NonConstListOrSetLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required final DartType _elementType,
  required final InterfaceType _receiverType,
}) extends _ListOrSetLiteralBuilder {
  Expression translate({
    required List<InferredElement> elements,
    required int fileOffset,
  }) {
    // Translate elements in place up to the first non-expression, if any.
    int index = 0;
    for (; index < elements.length; ++index) {
      if (elements[index] is! InferredExpressionElementBase) {
        break;
      }
    }

    // If there were only expressions, we are done.
    if (index == elements.length) {
      return _createLiteral(
        expressions: _convertElementsToExpressions(elements),
        fileOffset: fileOffset,
      );
    }

    DeclaredVariable? result;
    List<Statement> body = [];
    if (index == 0 && elements[index] is InferredSpreadElement) {
      InferredSpreadElement initialSpread =
          elements[index] as InferredSpreadElement;
      final bool typeMatches = _typeSchemaEnvironment.isSubtypeOf(
        initialSpread.elementType.expressionType,
        _elementType,
      );
      if (typeMatches && !initialSpread.isNullAware) {
        // Create a list or set of the initial spread element.
        Expression value = initialSpread.expression;
        index++;
        result = _createInitialValueFromSpread(
          body: body,
          spread: value,
          fileOffset: fileOffset,
        );
      }
    }
    if (result == null) {
      // Create a list or set with the elements up to the first non-expression.
      result = _createInitialValueFromExpressions(
        body: body,
        expressions: _convertElementsToExpressions(elements, count: index),
        fileOffset: fileOffset,
      );
    }
    // Translate the elements starting with the first non-expression.
    for (; index < elements.length; ++index) {
      _translateElement(elements[index], result, body);
    }

    return _createBlockExpression(
      fileOffset,
      _createBlock(body),
      _createVariableGet(result),
    );
  }

  void _addExpressionElement(
    Expression expression,
    Variable result,
    List<Statement> body,
  ) {
    body.add(
      _createExpressionStatement(
        _createAdd(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          expression,
        ),
      ),
    );
  }

  /// Creates an expression that calls `add` to add [argument] to the list or
  /// set held by [receiver].
  Expression _createAdd(Expression receiver, Expression argument);

  /// Creates an expression that calls `addAll` to add elements in [argument]
  /// to the list or set held by [receiver].
  Expression _createAddAll(Expression receiver, Expression argument);

  /// Creates the temporary variable and its initialization for the list or set
  /// literal the given initial [expressions].
  ///
  /// The inclusion of the initial [expressions] is done for an optimized
  /// output.
  ///
  /// The declaration of the created variable is added to [body] and returned.
  DeclaredVariable _createInitialValueFromExpressions({
    required List<Statement> body,
    required List<Expression> expressions,
    required int fileOffset,
  });

  /// Creates the temporary variable and its initialization for the list or set
  /// literal whose first element is a spread.
  ///
  /// The declaration of the created variable is added to [body] and returned.
  ///
  /// This is used for an optimized output.
  DeclaredVariable _createInitialValueFromSpread({
    required List<Statement> body,
    required Expression spread,
    required int fileOffset,
  });

  /// Creates the lowered expression for the list or set literal containing
  /// [expressions].
  Expression _createLiteral({
    required List<Expression> expressions,
    required int fileOffset,
  });

  void _translateElement(
    InferredElement element,
    Variable result,
    List<Statement> body,
  ) {
    switch (element) {
      case InferredSpreadElement():
        _translateSpreadElement(element, result, body);
      case InferredNullAwareElement():
        _translateNullAwareElement(element, result, body);
      case InferredIfElement():
        _translateIfElement(element, result, body);
      case InferredIfCaseElement():
        _translateIfCaseElement(element, result, body);
      case InferredForElement():
        _translateForElement(element, result, body);
      case InferredPatternForElement():
        _translatePatternForElement(element, result, body);
      case InferredForInElement():
        _translateForInElement(element, result, body);
      case InferredExpressionElement():
        _addExpressionElement(element.expression, result, body);
      case InferredInvalidElement():
        _addExpressionElement(element.expression, result, body);
      // Coverage-ignore(suite): Not run.
      case InferredMapEntryElement():
      case InferredNullAwareMapEntryElement():
        throw new UnimplementedError('$element');
    }
  }

  void _translateForElement(
    InferredForElement element,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements = <Statement>[];
    _translateElement(element.body, result, statements);
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    ForStatement loop = _createForStatement(
      element.fileOffset,
      element.variables,
      element.condition,
      element.updates,
      loopBody,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(element.nodeForTesting, loop);
    body.add(loop);
  }

  void _translateForInElement(
    InferredForInElement element,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements;
    Statement? bodyPrologue = element.encoding.bodyPrologue;
    if (bodyPrologue == null) {
      statements = [];
    } else {
      statements = bodyPrologue is Block
          ? bodyPrologue.statements
          : [bodyPrologue];
    }
    _translateElement(element.body, result, statements);
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    Statement loop = _createForInStatement(
      element.fileOffset,
      element.variable,
      element.iterable,
      loopBody,
      isAsync: element.isAsync,
    )..scope = element.scope;
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(element.nodeForTesting, loop);

    InvalidExpression? preLoopError = element.encoding.preLoopError;
    if (preLoopError != null) {
      loop = createBlock([
        createExpressionStatement(preLoopError),
        loop,
      ], fileOffset: element.fileOffset);
    }
    body.add(loop);
  }

  void _translateIfCaseElement(
    InferredIfCaseElement element,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> thenStatements = [];
    _translateElement(element.then, result, thenStatements);
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(element.otherwise!, result, elseStatements = []);
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        :
          // Coverage-ignore(suite): Not run.
          _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseStatements);
    }
    IfCaseStatement ifCaseStatement = _createIfCase(
      element.fileOffset,
      element.expression,
      element.matchedValueType,
      element.patternGuard,
      thenBody,
      elseBody,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(element.nodeForTesting, ifCaseStatement);
    body.add(ifCaseStatement);
  }

  void _translateIfElement(
    InferredIfElement element,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> thenStatements = [];
    _translateElement(element.then, result, thenStatements);
    List<Statement>? elseStatements;
    if (element.otherwise != null) {
      _translateElement(element.otherwise!, result, elseStatements = []);
    }
    Statement thenBody = thenStatements.length == 1
        ? thenStatements.first
        : _createBlock(thenStatements);
    Statement? elseBody;
    if (elseStatements != null && elseStatements.isNotEmpty) {
      elseBody = elseStatements.length == 1
          ? elseStatements.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseStatements);
    }
    IfStatement ifStatement = _createIf(
      element.fileOffset,
      element.condition,
      thenBody,
      elseBody,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(element.nodeForTesting, ifStatement);
    body.add(ifStatement);
  }

  void _translateNullAwareElement(
    InferredNullAwareElement element,
    Variable result,
    List<Statement> body,
  ) {
    // The code below lowers null-aware elements into series of statements. For
    // example, the null-aware element in the literal `<String>[?expr]` will be
    // lowered into the following:
    //
    //   String? #temp = expr;
    //   if (#temp != null) {
    //     #t.add(#temp{String});
    //   }
    //
    // In that example `#t` is the collection literal being generated, and
    // `#temp{String}` represents the promotion of the variable `#temp` to the
    // non-nullable type `String`.
    //
    // Note that the type inference ensures that the static type of `expr` is a
    // subtype of `String?`, and by now we don't need to insert another cast to
    // ensure it.

    Expression value = element.expression;
    DartType nullableElementType = _elementType.withDeclaredNullability(
      Nullability.nullable,
    );
    DeclaredVariable temp = _createVariable(value, nullableElementType);
    body.add(
      extern.createVariableStatement(extern.createVariableDeclaration(temp)),
    );

    Statement statement = _createIf(
      temp.fileOffset,
      _createEqualsNull(_createVariableGet(temp), notEquals: true),
      _createExpressionStatement(
        _createAdd(
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          _createNullCheckedVariableGet(temp),
        ),
      ),
    );
    body.add(statement);
  }

  void _translatePatternForElement(
    InferredPatternForElement element,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements = [];
    _translateElement(element.body, result, statements);
    Statement loopBody = statements.length == 1
        ? statements.first
        :
          // Coverage-ignore(suite): Not run.
          _createBlock(statements);
    ForStatement loop = _createForStatement(
      element.fileOffset,
      element.variables,
      element.condition,
      element.updates,
      loopBody,
    );
    body.add(element.patternVariableDeclaration);
    for (VariableDeclaration intermediateVariable
        in element.intermediateVariables) {
      body.add(extern.createVariableStatement(intermediateVariable));
    }
    body.add(loop);

    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(element.nodeForTesting, loop);
  }

  void _translateSpreadElement(
    InferredSpreadElement element,
    Variable result,
    List<Statement> body,
  ) {
    Expression value = element.expression;

    final bool typeMatches = _typeSchemaEnvironment.isSubtypeOf(
      element.elementType.expressionType,
      _elementType,
    );
    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to 'add'.

      // Null-aware spreads require testing the subexpression's value.
      DeclaredVariable? temp;
      if (element.isNullAware) {
        temp = _createVariable(
          value,
          _typeSchemaEnvironment.iterableType(
            _elementType,
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(
        _createAddAll(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          value,
        ),
      );

      if (element.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      DeclaredVariable? temp;
      if (element.isNullAware) {
        temp = _createVariable(
          value,
          _typeSchemaEnvironment.iterableType(
            const DynamicType(),
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      DeclaredVariable variable = _createForInVariable(
        element.fileOffset,
        const DynamicType(),
      );
      DeclaredVariable castedVar = _createVariable(
        _createImplicitAs(
          element.expression.fileOffset,
          _createVariableGet(variable),
          _elementType,
        ),
        _elementType,
      );
      Statement loopBody = _createBlock(<Statement>[
        extern.createVariableStatement(
          extern.createVariableDeclaration(castedVar),
        ),
        _createExpressionStatement(
          _createAdd(
            // Don't make a mess of jumping around (and make scope building
            // impossible).
            _createVariableGet(result)..fileOffset = TreeNode.noOffset,
            _createVariableGet(castedVar),
          ),
        ),
      ]);
      Statement statement = _createForInStatement(
        element.fileOffset,
        variable,
        value,
        loopBody,
      );

      if (element.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    }
  }
}

/// Builder for lowering non-const map literals.
class _NonConstMapLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required super.keyType,
  required super.valueType,
}) extends MapLiteralBuilder {
  final InterfaceType _receiverType;

  this
    : _receiverType = engine.typeSchemaEnvironment.mapType(
        keyType,
        valueType,
        Nullability.nonNullable,
      ),
      super._();

  @override
  Expression translate({
    required List<InferredElement> entries,
    required int fileOffset,
  }) {
    // Translate entries in place up to the first control-flow entry, if any.
    int index = 0;
    for (; index < entries.length; ++index) {
      if (entries[index] is! InferredMapEntryElement) break;
    }

    // If there were no control-flow entries we are done.
    if (index == entries.length) {
      return _createMapLiteral(
        fileOffset: fileOffset,
        entries: entries,
        isConst: false,
      );
    }

    // Build a block expression and create an empty map.
    DeclaredVariable? result;
    if (index == 0 && entries[index] is InferredSpreadElement) {
      InferredSpreadElement initialSpread =
          entries[index] as InferredSpreadElement;
      final bool typeMatches =
          _typeSchemaEnvironment.isSubtypeOf(
            initialSpread.elementType.keyType,
            _keyType,
          ) &&
          _typeSchemaEnvironment.isSubtypeOf(
            initialSpread.elementType.valueType,
            _valueType,
          );
      if (typeMatches && !initialSpread.isNullAware) {
        // Create a map of the initial spread element.
        Expression value = initialSpread.expression;
        index++;
        result = _createVariable(
          new StaticInvocation(
            _engine.mapOf,
            new Arguments([value], types: [_keyType, _valueType])
              ..fileOffset = fileOffset,
          )..fileOffset = fileOffset,
          _receiverType,
        );
      }
    }

    List<Statement>? body;
    if (result == null) {
      result = _createVariable(
        _createMapLiteral(fileOffset: fileOffset, entries: [], isConst: false),
        _receiverType,
      );
      body = [
        extern.createVariableStatement(
          extern.createVariableDeclaration(result),
        ),
      ];
      // Add all the entries up to the first control-flow entry.
      for (int j = 0; j < index; ++j) {
        _addNormalEntry(entries[j] as InferredMapEntryElement, result, body);
      }
    }

    body ??= [
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    ];

    // Translate the elements starting with the first non-expression.
    for (; index < entries.length; ++index) {
      _translateMapEntry(entries[index], result, body);
    }

    return _createBlockExpression(
      fileOffset,
      _createBlock(body),
      _createVariableGet(result),
    );
  }

  void _addNormalEntry(
    InferredMapEntryElement entry,
    Variable result,
    List<Statement> body,
  ) {
    body.add(
      _createExpressionStatement(
        _createIndexSet(
          entry.fileOffset,
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          _receiverType,
          entry.key,
          entry.value,
        ),
      ),
    );
  }

  Expression _createAddAll(
    Expression receiver,
    InterfaceType receiverType,
    Expression argument,
  ) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(_engine.mapAddAllFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('addAll'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: _engine.mapAddAll,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  Expression _createGetEntries(
    int fileOffset,
    Expression receiver,
    InterfaceType mapType,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(mapType)
        .substituteType(_engine.mapEntries.getterType);
    return new InstanceGet(
      InstanceAccessKind.Instance,
      receiver,
      new Name('entries'),
      interfaceTarget: _engine.mapEntries,
      resultType: resultType,
    )..fileOffset = fileOffset;
  }

  Expression _createGetKey(
    int fileOffset,
    Expression receiver,
    InterfaceType entryType,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(_engine.mapEntryKey.type);
    return new InstanceGet(
      InstanceAccessKind.Instance,
      receiver,
      new Name('key'),
      interfaceTarget: _engine.mapEntryKey,
      resultType: resultType,
    )..fileOffset = fileOffset;
  }

  Expression _createGetValue(
    int fileOffset,
    Expression receiver,
    InterfaceType entryType,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType resultType = Substitution.fromInterfaceType(entryType)
        .substituteType(_engine.mapEntryValue.type);
    return new InstanceGet(
      InstanceAccessKind.Instance,
      receiver,
      new Name('value'),
      interfaceTarget: _engine.mapEntryValue,
      resultType: resultType,
    )..fileOffset = fileOffset;
  }

  Expression _createIndexSet(
    int fileOffset,
    Expression receiver,
    InterfaceType receiverType,
    Expression key,
    Expression value,
  ) {
    assert(fileOffset != TreeNode.noOffset);
    DartType functionType = Substitution.fromInterfaceType(receiverType)
        .substituteType(_engine.mapPutFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('[]='),
        new Arguments([key, value]),
        functionType: functionType as FunctionType,
        interfaceTarget: _engine.mapPut,
      )
      ..fileOffset = fileOffset
      ..isInvariant = true;
  }

  void _translateForEntry(
    InferredForElement entry,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements = <Statement>[];
    _translateMapEntry(entry.body, result, statements);
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    ForStatement loop = _createForStatement(
      entry.fileOffset,
      entry.variables,
      entry.condition,
      entry.updates,
      loopBody,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(entry.nodeForTesting, loop);
    body.add(loop);
  }

  void _translateForInEntry(
    InferredForInElement entry,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements;
    Statement? bodyPrologue = entry.encoding.bodyPrologue;
    if (bodyPrologue == null) {
      statements = [];
    } else {
      statements = bodyPrologue is Block
          ? bodyPrologue.statements
          : [bodyPrologue];
    }
    _translateMapEntry(entry.body, result, statements);
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    Statement loop = _createForInStatement(
      entry.fileOffset,
      entry.variable,
      entry.iterable,
      loopBody,
      isAsync: entry.isAsync,
    )..scope = entry.scope;
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(entry.nodeForTesting, loop);

    InvalidExpression? preLoopError = entry.encoding.preLoopError;
    if (preLoopError != null) {
      loop = createBlock([
        createExpressionStatement(preLoopError),
        loop,
      ], fileOffset: entry.fileOffset);
    }

    body.add(loop);
  }

  void _translateIfCaseEntry(
    InferredIfCaseElement entry,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> thenBody = [];
    _translateMapEntry(entry.then, result, thenBody);
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateMapEntry(entry.otherwise!, result, elseBody = <Statement>[]);
    }
    Statement thenStatement = thenBody.length == 1
        ? thenBody.first
        :
          // Coverage-ignore(suite): Not run.
          _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement = elseBody.length == 1
          ? elseBody.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseBody);
    }
    IfCaseStatement ifStatement = _createIfCase(
      entry.fileOffset,
      entry.expression,
      entry.matchedValueType,
      entry.patternGuard,
      thenStatement,
      elseStatement,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(entry.nodeForTesting, ifStatement);
    body.add(ifStatement);
  }

  void _translateIfEntry(
    InferredIfElement entry,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> thenBody = [];
    _translateMapEntry(entry.then, result, thenBody);
    List<Statement>? elseBody;
    if (entry.otherwise != null) {
      _translateMapEntry(entry.otherwise!, result, elseBody = <Statement>[]);
    }
    Statement thenStatement = thenBody.length == 1
        ? thenBody.first
        : _createBlock(thenBody);
    Statement? elseStatement;
    if (elseBody != null && elseBody.isNotEmpty) {
      elseStatement = elseBody.length == 1
          ? elseBody.first
          :
            // Coverage-ignore(suite): Not run.
            _createBlock(elseBody);
    }
    IfStatement ifStatement = _createIf(
      entry.fileOffset,
      entry.condition,
      thenStatement,
      elseStatement,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(entry.nodeForTesting, ifStatement);
    body.add(ifStatement);
  }

  void _translateMapEntry(
    InferredElement entry,
    Variable result,
    List<Statement> body,
  ) {
    switch (entry) {
      case InferredSpreadElement():
        _translateSpreadEntry(entry, result, body);
      case InferredNullAwareMapEntryElement():
        _translateNullAwareMapEntry(entry, result, body);
      case InferredIfElement():
        _translateIfEntry(entry, result, body);
      case InferredIfCaseElement():
        _translateIfCaseEntry(entry, result, body);
      case InferredPatternForElement():
        _translatePatternForEntry(entry, result, body);
      case InferredForElement():
        _translateForEntry(entry, result, body);
      case InferredForInElement():
        _translateForInEntry(entry, result, body);
      case InferredMapEntryElement():
        _addNormalEntry(entry, result, body);
      case InferredInvalidElement():
        body.add(_createExpressionStatement(entry.expression));
      // Coverage-ignore(suite): Not run.
      case InferredNullAwareElement():
      case InferredExpressionElement():
        throw new UnsupportedError('Unexpected map entry ${entry}.');
    }
  }

  void _translateNullAwareMapEntry(
    InferredNullAwareMapEntryElement entry,
    Variable result,
    List<Statement> body,
  ) {
    assert(entry.isKeyNullAware || entry.isValueNullAware);

    // The code below lowers null-aware map entries into series of statements.
    // For example, the null-aware entry in the literal
    // `<String, int>{?key: ?value}` will be lowered into the following:
    //
    //   String? #keyTemp = key as String?;
    //   if (#keyTemp != null) {
    //     int? #valueTemp = value as int?;
    //     if (#valueTemp != null) {
    //       #t[#keyTemp{String}] = #valueTemp{int};
    //     }
    //   }
    //
    // In that example `#t` is the collection literal being generated, and
    // `#keyTemp{String}` and `#valueTemp{int}` represent the promotions of the
    // variables `#keyTemp` and `#valueTemp` to the non-nullable types `String`
    // and `int` correspondingly.
    //
    // Note that the type inference ensures that the static type of `key` and
    // `value` are subtypes of `String?` and `int?` correspondingly, and by now
    // we don't need to insert another cast to ensure it.

    Expression keyExpression = entry.key;
    Expression valueExpression = entry.value;

    // Since the statement adding the entry to the map may include promotions of
    // the key or the value expressions, we can't create that statement until
    // the very end. Instead, we track the guard node that the add-entry
    // statement should be directly nested in and assign the add-entry
    // statement with the necessary promotions when we can create it.
    IfStatement? addedEntryStatementParent;

    Block desugaredStatement = _createBlock([]);

    if (entry.isValueNullAware) {
      DartType nullableValueType = _valueType.withDeclaredNullability(
        Nullability.nullable,
      );
      DeclaredVariable valueTemp = _createVariable(
        valueExpression,
        nullableValueType,
      );
      valueExpression = _createNullCheckedVariableGet(valueTemp);

      IfStatement ifValueNotNullStatement = _createIf(
        valueTemp.fileOffset,
        _createEqualsNull(createVariableGet(valueTemp), notEquals: true),
        desugaredStatement,
      );
      addedEntryStatementParent ??= ifValueNotNullStatement;

      desugaredStatement = _createBlock([
        extern.createVariableStatement(
          extern.createVariableDeclaration(valueTemp),
        ),
        ifValueNotNullStatement,
      ])..fileOffset = entry.fileOffset;
    }

    if (entry.isKeyNullAware) {
      DartType nullableKeyType = _keyType.withDeclaredNullability(
        Nullability.nullable,
      );
      DeclaredVariable keyTemp = _createVariable(
        keyExpression,
        nullableKeyType,
      );
      keyExpression = _createNullCheckedVariableGet(keyTemp);

      IfStatement ifKeyNotNullStatement = _createIf(
        keyTemp.fileOffset,
        _createEqualsNull(createVariableGet(keyTemp), notEquals: true),
        desugaredStatement,
      );
      addedEntryStatementParent ??= ifKeyNotNullStatement;

      desugaredStatement = _createBlock([
        extern.createVariableStatement(
          extern.createVariableDeclaration(keyTemp),
        ),
        ifKeyNotNullStatement,
      ])..fileOffset = entry.fileOffset;
    } else if (entry.isValueNullAware) {
      assert(!entry.isKeyNullAware);
      // The key is non null-aware, but the value is null-aware. In this case,
      // we need to hoist the key expression to preserve the evaluation order.
      // Consider the following example:
      //
      //   <String, int>{keyExpression(): ?valueExpression()}
      //
      // Without hoisting the key expression, the map literal will be desugared
      // as follows:
      //
      //   int? #valueTemp = valueExpression();
      //   if (#valueTemp != null) {
      //     #t[keyExpression()] = #valueTemp{int};
      //   }
      //
      // In that desugaring, `valueExpression` is executed before
      // `keyExpression`, which doesn't match the expected evaluation order.
      // With the hoisting of the key, the desugared expression will look as
      // follows:
      //
      //   String #keyTemp = keyExpression();
      //   int? #valueTemp = valueExpression();
      //   if (#valueTemp != null) {
      //     #t[#keyTemp] = #valueTemp{int};
      //   }

      DeclaredVariable keyTemp = _createVariable(keyExpression, _keyType);
      keyExpression = _createVariableGet(keyTemp);

      desugaredStatement.statements.insert(
        0,
        extern.createVariableStatement(
          extern.createVariableDeclaration(keyTemp),
        )..parent = desugaredStatement,
      );
    }

    // Since either the key or the value is null-aware, [desugaredStatement]
    // should be replaced with a null-checking [IfStatement].
    assert(
      addedEntryStatementParent != null &&
          desugaredStatement is! EmptyStatement,
    );
    addedEntryStatementParent!.then = _createExpressionStatement(
      _createIndexSet(
        entry.fileOffset,
        _createVariableGet(result)..fileOffset = TreeNode.noOffset,
        _receiverType,
        keyExpression,
        valueExpression,
      ),
    );

    body.addAll(desugaredStatement.statements);
  }

  void _translatePatternForEntry(
    InferredPatternForElement entry,
    Variable result,
    List<Statement> body,
  ) {
    List<Statement> statements = <Statement>[];
    _translateMapEntry(entry.body, result, statements);
    Statement loopBody = statements.length == 1
        ? statements.first
        : _createBlock(statements);
    ForStatement loop = _createForStatement(
      entry.fileOffset,
      entry.variables,
      entry.condition,
      entry.updates,
      loopBody,
    );
    _libraryBuilder.loader.dataForTesting
    // Coverage-ignore(suite): Not run.
    ?.registerExternalNode(entry.nodeForTesting, loop);
    body.add(entry.patternVariableDeclaration);
    for (VariableDeclaration intermediateVariable
        in entry.intermediateVariables) {
      body.add(extern.createVariableStatement(intermediateVariable));
    }
    body.add(loop);
  }

  void _translateSpreadEntry(
    InferredSpreadElement entry,
    Variable result,
    List<Statement> body,
  ) {
    Expression value = entry.expression;

    final bool typeMatches =
        _typeSchemaEnvironment.isSubtypeOf(
          entry.elementType.keyType,
          _keyType,
        ) &&
        _typeSchemaEnvironment.isSubtypeOf(
          entry.elementType.valueType,
          _valueType,
        );
    if (typeMatches) {
      // If the type guarantees that all elements are of the required type, use
      // a single 'addAll' call instead of a for-loop with calls to '[]='.

      // Null-aware spreads require testing the subexpression's value.
      DeclaredVariable? temp;
      if (entry.isNullAware) {
        temp = _createVariable(
          value,
          _typeSchemaEnvironment.mapType(
            _keyType,
            _valueType,
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      Statement statement = _createExpressionStatement(
        _createAddAll(
          // Don't make a mess of jumping around (and make scope building
          // impossible).
          _createVariableGet(result)..fileOffset = TreeNode.noOffset,
          _receiverType,
          value,
        ),
      );

      if (entry.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    } else {
      // Null-aware spreads require testing the subexpression's value.
      DeclaredVariable? temp;
      if (entry.isNullAware) {
        temp = _createVariable(
          value,
          _typeSchemaEnvironment.mapType(
            const DynamicType(),
            const DynamicType(),
            Nullability.nullable,
          ),
        );
        body.add(
          extern.createVariableStatement(
            extern.createVariableDeclaration(temp),
          ),
        );
        value = _createNullCheckedVariableGet(temp);
      }

      final InterfaceType variableType = new InterfaceType(
        _engine.mapEntryClass,
        Nullability.nonNullable,
        <DartType>[const DynamicType(), const DynamicType()],
      );
      DeclaredVariable variable = _createForInVariable(
        entry.fileOffset,
        variableType,
      );
      DeclaredVariable keyVar = _createVariable(
        _createImplicitAs(
          entry.expression.fileOffset,
          _createGetKey(
            entry.expression.fileOffset,
            _createVariableGet(variable),
            variableType,
          ),
          _keyType,
        ),
        _keyType,
      );
      DeclaredVariable valueVar = _createVariable(
        _createImplicitAs(
          entry.expression.fileOffset,
          _createGetValue(
            entry.expression.fileOffset,
            _createVariableGet(variable),
            variableType,
          ),
          _valueType,
        ),
        _valueType,
      );
      Statement loopBody = _createBlock(<Statement>[
        extern.createVariableStatement(
          extern.createVariableDeclaration(keyVar),
        ),
        extern.createVariableStatement(
          extern.createVariableDeclaration(valueVar),
        ),
        _createExpressionStatement(
          _createIndexSet(
            entry.expression.fileOffset,
            _createVariableGet(result),
            _receiverType,
            _createVariableGet(keyVar),
            _createVariableGet(valueVar),
          ),
        ),
      ]);
      Statement statement = _createForInStatement(
        entry.fileOffset,
        variable,
        _createGetEntries(entry.fileOffset, value, _receiverType),
        loopBody,
      );

      if (entry.isNullAware) {
        statement = _createIf(
          temp!.fileOffset,
          _createEqualsNull(_createVariableGet(temp), notEquals: true),
          statement,
        );
      }
      body.add(statement);
    }
  }
}

/// Builder for lowering non-const set literals.
class _NonConstSetLiteralBuilder(
  super.engine,
  super.libraryBuilder, {
  required super.elementType,
}) extends _NonConstListOrSetLiteralBuilder implements SetLiteralBuilder {
  this
    : super(
        receiverType: engine.typeSchemaEnvironment.setType(
          elementType,
          Nullability.nonNullable,
        ),
      );

  @override
  Expression _createAdd(Expression receiver, Expression argument) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(_receiverType)
        .substituteType(_engine.setAddFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('add'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: _engine.setAdd,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  @override
  Expression _createAddAll(Expression receiver, Expression argument) {
    assert(
      argument.fileOffset != TreeNode.noOffset,
      "No fileOffset on ${argument}.",
    );
    DartType functionType = Substitution.fromInterfaceType(_receiverType)
        .substituteType(_engine.setAddAllFunctionType);
    return new InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        new Name('addAll'),
        new Arguments([argument]),
        functionType: functionType as FunctionType,
        interfaceTarget: _engine.setAddAll,
      )
      ..fileOffset = argument.fileOffset
      ..isInvariant = true;
  }

  @override
  DeclaredVariable _createInitialValueFromExpressions({
    required List<Statement> body,
    required List<Expression> expressions,
    required int fileOffset,
  }) {
    if (_libraryBuilder.loader.target.backendTarget.supportsSetLiterals) {
      // Coverage-ignore-block(suite): Not run.
      // Include the elements up to the first non-expression in the set
      // literal.
      DeclaredVariable result = _createVariable(
        _lowerSetLiteral(
          _createSetLiteral(
            elementType: _elementType,
            expressions: expressions,
            fileOffset: fileOffset,
            isConst: false,
          ),
        ),
        _receiverType,
      );
      body.add(
        extern.createVariableStatement(
          extern.createVariableDeclaration(result),
        ),
      );
      return result;
    } else {
      // TODO(johnniwinther): When all the back ends handle set literals we
      //  can use remove this branch.

      // Create an empty set using the [setFactory] constructor.
      DeclaredVariable result = _createVariable(
        new StaticInvocation(
          _engine.setFactory,
          new Arguments([], types: [_elementType])..fileOffset = fileOffset,
        )..fileOffset = fileOffset,
        _receiverType,
      );
      body.add(
        extern.createVariableStatement(
          extern.createVariableDeclaration(result),
        ),
      );
      // Add the elements up to the first non-expression.
      for (int j = 0; j < expressions.length; ++j) {
        _addExpressionElement(expressions[j], result, body);
      }
      return result;
    }
  }

  @override
  DeclaredVariable _createInitialValueFromSpread({
    required List<Statement> body,
    required Expression spread,
    required int fileOffset,
  }) {
    DeclaredVariable result = _createVariable(
      new StaticInvocation(
        _engine.setOf,
        new Arguments([spread], types: [_elementType])..fileOffset = fileOffset,
      )..fileOffset = fileOffset,
      _receiverType,
    );
    body.add(
      extern.createVariableStatement(extern.createVariableDeclaration(result)),
    );
    return result;
  }

  @override
  Expression _createLiteral({
    required List<Expression> expressions,
    required int fileOffset,
  }) {
    return _lowerSetLiteral(
      _createSetLiteral(
        elementType: _elementType,
        expressions: expressions,
        fileOffset: fileOffset,
        isConst: false,
      ),
    );
  }

  /// Creates a lowering for [node] for targets that don't support the
  /// [SetLiteral] node.
  Expression _lowerSetLiteral(SetLiteral node) {
    if (_libraryBuilder.loader.target.backendTarget.supportsSetLiterals) {
      return node;
    }
    if (node.isConst) {
      // Const set literals are transformed in the constant evaluator.
      return node;
    }

    // Create the set: Set<E> setVar = new Set<E>();
    InterfaceType receiverType;
    DeclaredVariable setVar = extern.createVariable(
      new StaticInvocation(
        _engine.setFactory,
        new Arguments([], types: [node.typeArgument]),
      ),
      receiverType = new InterfaceType(
        _coreTypes.setClass,
        Nullability.nonNullable,
        [node.typeArgument],
      ),
    );

    // Now create a list of all statements needed.
    List<Statement> statements = [
      extern.createVariableStatement(extern.createVariableDeclaration(setVar)),
    ];
    for (int i = 0; i < node.expressions.length; i++) {
      Expression entry = node.expressions[i];
      DartType functionType = Substitution.fromInterfaceType(receiverType)
          .substituteType(_engine.setAddMethodFunctionType);
      Expression methodInvocation =
          new InstanceInvocation(
              InstanceAccessKind.Instance,
              new VariableGet(setVar),
              new Name("add"),
              new Arguments([entry]),
              functionType: functionType as FunctionType,
              interfaceTarget: _engine.setAddMethod,
            )
            ..fileOffset = entry.fileOffset
            ..isInvariant = true;
      statements.add(
        new ExpressionStatement(methodInvocation)
          ..fileOffset = methodInvocation.fileOffset,
      );
    }

    // Finally, return a BlockExpression with the statements, having the value
    // of the (now created) set.
    return new BlockExpression(new Block(statements), new VariableGet(setVar))
      ..fileOffset = node.fileOffset;
  }
}
