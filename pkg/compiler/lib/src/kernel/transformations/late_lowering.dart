// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.12

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../../options.dart';

class _Reader {
  final Procedure _procedure;
  final FunctionType _type;
  late final FunctionType _typeWithoutTypeParameters;

  _Reader(this._procedure) : _type = _procedure.getterType as FunctionType {
    _typeWithoutTypeParameters = _type.withoutTypeParameters;
  }
}

class LateLowering {
  final CoreTypes _coreTypes;

  final bool _omitLateNames;
  final bool _lowerInstanceVariables;

  final _Reader _readLocal;
  final _Reader _readField;
  final _Reader _readInitialized;
  final _Reader _readInitializedFinal;

  // Each map contains the mapping from late local variables to cells for a
  // given function scope. All late local variables are lowered to cells.
  final List<Map<VariableDeclaration, VariableDeclaration>?> _variableCells =
      [];

  // Uninitialized late static fields are lowered to cells.
  final Map<Field, Field> _fieldCells = {};

  // Late instance fields are lowered to a backing field (plus a getter/setter
  // pair).
  final Map<Field, Field> _backingInstanceFields = {};

  // TODO(fishythefish): Remove this when [FieldInitializer] maintains a correct
  // [Reference] to its [Field].
  final Map<Procedure, Field> _getterToField = {};

  Member? _contextMember;

  LateLowering(this._coreTypes, CompilerOptions? _options)
      : _omitLateNames = _options?.omitLateNames ?? false,
        _lowerInstanceVariables =
            _options?.experimentLateInstanceVariables ?? false,
        _readLocal = _Reader(_coreTypes.cellReadLocal),
        _readField = _Reader(_coreTypes.cellReadField),
        _readInitialized = _Reader(_coreTypes.initializedCellRead),
        _readInitializedFinal = _Reader(_coreTypes.initializedCellReadFinal);

  Nullability get nonNullable => _contextMember!.enclosingLibrary.nonNullable;

  bool _shouldLowerVariable(VariableDeclaration variable) => variable.isLate;

  bool _shouldLowerUninitializedVariable(VariableDeclaration variable) =>
      _shouldLowerVariable(variable) && variable.initializer == null;

  bool _shouldLowerInitializedVariable(VariableDeclaration variable) =>
      _shouldLowerVariable(variable) && variable.initializer != null;

  bool _shouldLowerStaticField(Field field) =>
      field.isLate && field.isStatic && field.initializer == null;

  bool _shouldLowerInstanceField(Field field) =>
      field.isLate && !field.isStatic && _lowerInstanceVariables;

  String _mangleFieldName(Field field) {
    assert(_shouldLowerInstanceField(field));
    Class cls = field.enclosingClass!;
    return '_#${cls.name}#${field.name.text}';
  }

  void transformAdditionalExports(Library library) {
    List<Reference> additionalExports = library.additionalExports;
    Set<Reference> newExports = {};
    additionalExports.removeWhere((Reference reference) {
      Field? cell = _fieldCells[reference.node];
      if (cell == null) return false;
      newExports.add(cell.getterReference);
      return true;
    });
    additionalExports.addAll(newExports);
  }

  ConstructorInvocation _callCellConstructor(Expression name, int fileOffset) =>
      _omitLateNames
          ? _callCellUnnamedConstructor(fileOffset)
          : _callCellNamedConstructor(name, fileOffset);

  ConstructorInvocation _callCellUnnamedConstructor(int fileOffset) =>
      ConstructorInvocation(_coreTypes.cellConstructor,
          Arguments.empty()..fileOffset = fileOffset)
        ..fileOffset = fileOffset;

  ConstructorInvocation _callCellNamedConstructor(
          Expression name, int fileOffset) =>
      ConstructorInvocation(_coreTypes.cellNamedConstructor,
          Arguments([name])..fileOffset = fileOffset)
        ..fileOffset = fileOffset;

  ConstructorInvocation _callInitializedCellConstructor(
          Expression name, Expression initializer, int fileOffset) =>
      _omitLateNames
          ? _callInitializedCellUnnamedConstructor(initializer, fileOffset)
          : _callInitializedCellNamedConstructor(name, initializer, fileOffset);

  ConstructorInvocation _callInitializedCellUnnamedConstructor(
          Expression initializer, int fileOffset) =>
      ConstructorInvocation(_coreTypes.initializedCellConstructor,
          Arguments([initializer])..fileOffset = fileOffset)
        ..fileOffset = fileOffset;

  ConstructorInvocation _callInitializedCellNamedConstructor(
          Expression name, Expression initializer, int fileOffset) =>
      ConstructorInvocation(_coreTypes.initializedCellNamedConstructor,
          Arguments([name, initializer])..fileOffset = fileOffset)
        ..fileOffset = fileOffset;

  StringLiteral _nameLiteral(String? name, int fileOffset) =>
      StringLiteral(name ?? '')..fileOffset = fileOffset;

  InstanceInvocation _callReader(
      _Reader reader, Expression receiver, DartType type, int fileOffset) {
    Procedure procedure = reader._procedure;
    List<DartType> typeArguments = [type];
    return InstanceInvocation(
        InstanceAccessKind.Instance,
        receiver,
        procedure.name,
        Arguments(const [], types: typeArguments)..fileOffset = fileOffset,
        interfaceTarget: procedure,
        functionType:
            Substitution.fromPairs(reader._type.typeParameters, typeArguments)
                    .substituteType(reader._typeWithoutTypeParameters)
                as FunctionType)
      ..fileOffset = fileOffset;
  }

  InstanceSet _callSetter(Procedure _setter, Expression receiver,
          Expression value, int fileOffset) =>
      InstanceSet(InstanceAccessKind.Instance, receiver, _setter.name, value,
          interfaceTarget: _setter)
        ..fileOffset = fileOffset;

  StaticInvocation _callIsSentinel(Expression value, int fileOffset) =>
      StaticInvocation(_coreTypes.isSentinelMethod,
          Arguments([value])..fileOffset = fileOffset)
        ..fileOffset = fileOffset;

  void enterFunction() {
    _variableCells.add(null);
  }

  void exitFunction() {
    _variableCells.removeLast();
  }

  VariableDeclaration? _lookupVariableCell(VariableDeclaration variable) {
    assert(_shouldLowerVariable(variable));
    for (final scope in _variableCells) {
      if (scope == null) continue;
      final cell = scope[variable];
      if (cell != null) return cell;
    }
    return null;
  }

  VariableDeclaration _addToCurrentScope(
      VariableDeclaration variable, VariableDeclaration cell) {
    assert(_shouldLowerVariable(variable));
    assert(_lookupVariableCell(variable) == null);
    return (_variableCells.last ??= {})[variable] = cell;
  }

  VariableDeclaration _variableCell(VariableDeclaration variable) {
    assert(_shouldLowerVariable(variable));
    final cell = _lookupVariableCell(variable);
    if (cell != null) return cell;
    return variable.initializer == null
        ? _uninitializedVariableCell(variable)
        : _initializedVariableCell(variable);
  }

  VariableDeclaration _uninitializedVariableCell(VariableDeclaration variable) {
    assert(_shouldLowerUninitializedVariable(variable));
    int fileOffset = variable.fileOffset;
    String? name = variable.name;
    final cell = VariableDeclaration(name,
        initializer:
            _callCellConstructor(_nameLiteral(name, fileOffset), fileOffset),
        type: InterfaceType(_coreTypes.cellClass, nonNullable),
        isFinal: true)
      ..fileOffset = fileOffset;
    return _addToCurrentScope(variable, cell);
  }

  FunctionExpression _initializerClosure(
      Expression initializer, DartType type) {
    int fileOffset = initializer.fileOffset;
    ReturnStatement body = ReturnStatement(initializer)
      ..fileOffset = fileOffset;
    FunctionNode closure = FunctionNode(body, returnType: type)
      ..fileOffset = fileOffset;
    return FunctionExpression(closure)..fileOffset = fileOffset;
  }

  VariableDeclaration _initializedVariableCell(VariableDeclaration variable) {
    assert(_shouldLowerInitializedVariable(variable));
    int fileOffset = variable.fileOffset;
    String? name = variable.name;
    final cell = VariableDeclaration(name,
        initializer: _callInitializedCellConstructor(
            _nameLiteral(name, fileOffset),
            _initializerClosure(variable.initializer!, variable.type),
            fileOffset),
        type: InterfaceType(_coreTypes.initializedCellClass, nonNullable),
        isFinal: true)
      ..fileOffset = fileOffset;
    return _addToCurrentScope(variable, cell);
  }

  TreeNode transformVariableDeclaration(
      VariableDeclaration variable, Member? contextMember) {
    _contextMember = contextMember;

    if (!_shouldLowerVariable(variable)) return variable;

    // A [VariableDeclaration] being used as a statement must be a direct child
    // of a [Block].
    if (variable.parent is! Block) return variable;

    return _variableCell(variable);
  }

  VariableGet _variableCellRead(VariableDeclaration variable, int fileOffset) {
    assert(_shouldLowerVariable(variable));
    return VariableGet(_variableCell(variable))..fileOffset = fileOffset;
  }

  TreeNode transformVariableGet(VariableGet node, Member contextMember) {
    _contextMember = contextMember;

    VariableDeclaration variable = node.variable;
    if (!_shouldLowerVariable(variable)) return node;

    int fileOffset = node.fileOffset;
    VariableGet cell = _variableCellRead(variable, fileOffset);
    _Reader reader = variable.initializer == null
        ? _readLocal
        : (variable.isFinal ? _readInitializedFinal : _readInitialized);
    return _callReader(
        reader, cell, node.promotedType ?? variable.type, fileOffset);
  }

  TreeNode transformVariableSet(VariableSet node, Member contextMember) {
    _contextMember = contextMember;

    VariableDeclaration variable = node.variable;
    if (!_shouldLowerVariable(variable)) return node;

    int fileOffset = node.fileOffset;
    VariableGet cell = _variableCellRead(variable, fileOffset);
    Procedure setter = variable.initializer == null
        ? (variable.isFinal
            ? _coreTypes.cellFinalLocalValueSetter
            : _coreTypes.cellValueSetter)
        : (variable.isFinal
            ? _coreTypes.initializedCellFinalValueSetter
            : _coreTypes.initializedCellValueSetter);
    return _callSetter(setter, cell, node.value, fileOffset);
  }

  Field _fieldCell(Field field) {
    assert(_shouldLowerStaticField(field));
    return _fieldCells.putIfAbsent(field, () {
      int fileOffset = field.fileOffset;
      Name name = field.name;
      field.getterReference.canonicalName?.unbind();
      field.setterReference?.canonicalName?.unbind();
      return Field.immutable(name,
          type: InterfaceType(_coreTypes.cellClass, nonNullable),
          initializer: _callCellConstructor(
              _nameLiteral(name.text, fileOffset), fileOffset),
          isFinal: true,
          isStatic: true,
          fileUri: field.fileUri)
        ..fileOffset = fileOffset
        ..isNonNullableByDefault = true;
    });
  }

  Field _backingInstanceField(Field field) {
    assert(_shouldLowerInstanceField(field));
    return _backingInstanceFields[field] ??=
        _computeBackingInstanceField(field);
  }

  Field _computeBackingInstanceField(Field field) {
    assert(_shouldLowerInstanceField(field));
    assert(!_backingInstanceFields.containsKey(field));
    int fileOffset = field.fileOffset;
    Uri fileUri = field.fileUri;
    Name name = field.name;
    String nameText = name.text;
    DartType type = field.type;
    Expression? initializer = field.initializer;
    Class enclosingClass = field.enclosingClass!;

    Name mangledName = Name(_mangleFieldName(field), field.enclosingLibrary);
    Field backingField = Field.mutable(mangledName,
        type: type,
        initializer: StaticInvocation(_coreTypes.createSentinelMethod,
            Arguments(const [], types: [type])..fileOffset = fileOffset)
          ..fileOffset = fileOffset,
        fileUri: fileUri)
      ..fileOffset = fileOffset
      ..isNonNullableByDefault = true
      ..isInternalImplementation = true;
    InstanceGet fieldRead() => InstanceGet(InstanceAccessKind.Instance,
        ThisExpression()..fileOffset = fileOffset, mangledName,
        interfaceTarget: backingField, resultType: type)
      ..fileOffset = fileOffset;
    InstanceSet fieldWrite(Expression value) => InstanceSet(
        InstanceAccessKind.Instance,
        ThisExpression()..fileOffset = fileOffset,
        mangledName,
        value,
        interfaceTarget: backingField)
      ..fileOffset = fileOffset;

    Statement getterBody() {
      if (initializer == null) {
        // The lowered getter for `late T field;` and `late final T field;` is
        //
        // T get field => _lateReadCheck<T>(this._#field, "field");
        return ReturnStatement(
            StaticInvocation(
                _coreTypes.lateReadCheck,
                Arguments([fieldRead(), _nameLiteral(nameText, fileOffset)],
                    types: [type])
                  ..fileOffset = fileOffset)
              ..fileOffset = fileOffset)
          ..fileOffset = fileOffset;
      } else if (field.isFinal) {
        // The lowered getter for `late final T field = e;` is
        //
        // T get field {
        //   var value = this._#field;
        //   if (isSentinel(value)) {
        //     final result = e;
        //     _lateInitializeOnceCheck(this._#field, "field");
        //     value = this._#field = result;
        //   }
        //   return value;
        // }
        VariableDeclaration value =
            VariableDeclaration('value', initializer: fieldRead(), type: type)
              ..fileOffset = fileOffset;
        VariableGet valueRead() => VariableGet(value)..fileOffset = fileOffset;
        VariableDeclaration result = VariableDeclaration('result',
            initializer: initializer, type: type, isFinal: true)
          ..fileOffset = fileOffset;
        VariableGet resultRead() =>
            VariableGet(result)..fileOffset = fileOffset;
        return Block([
          value,
          IfStatement(
              _callIsSentinel(valueRead(), fileOffset),
              Block([
                result,
                ExpressionStatement(
                    StaticInvocation(
                        _coreTypes.lateInitializeOnceCheck,
                        Arguments(
                            [fieldRead(), _nameLiteral(nameText, fileOffset)])
                          ..fileOffset = fileOffset)
                      ..fileOffset = fileOffset)
                  ..fileOffset = fileOffset,
                ExpressionStatement(
                    VariableSet(value, fieldWrite(resultRead()))
                      ..fileOffset = fileOffset)
                  ..fileOffset = fileOffset
              ])
                ..fileOffset = fileOffset,
              null)
            ..fileOffset = fileOffset,
          ReturnStatement(valueRead())..fileOffset = fileOffset
        ])
          ..fileOffset = fileOffset;
      } else {
        // The lowered getter for `late T field = e;` is
        //
        // T get field {
        //   var value = this._#field;
        //   if (isSentinel(value)) {
        //     value = this._#field = e;
        //   }
        //   return value;
        // }
        VariableDeclaration value =
            VariableDeclaration('value', initializer: fieldRead(), type: type)
              ..fileOffset = fileOffset;
        VariableGet valueRead() => VariableGet(value)..fileOffset = fileOffset;
        return Block([
          value,
          IfStatement(
              _callIsSentinel(valueRead(), fileOffset),
              ExpressionStatement(
                  VariableSet(value, fieldWrite(initializer))
                    ..fileOffset = fileOffset)
                ..fileOffset = fileOffset,
              null)
            ..fileOffset = fileOffset,
          ReturnStatement(valueRead())..fileOffset = fileOffset
        ])
          ..fileOffset = fileOffset;
      }
    }

    Procedure getter = Procedure(name, ProcedureKind.Getter,
        FunctionNode(getterBody(), returnType: type)..fileOffset = fileOffset,
        fileUri: fileUri, reference: field.getterReference)
      ..fileOffset = fileOffset
      ..isNonNullableByDefault = true;
    enclosingClass.addProcedure(getter);
    _getterToField[getter] = backingField;

    VariableDeclaration setterValue = VariableDeclaration('value', type: type)
      ..fileOffset = fileOffset;
    VariableGet setterValueRead() =>
        VariableGet(setterValue)..fileOffset = fileOffset;

    Statement? setterBody() {
      if (!field.isFinal) {
        // The lowered setter for `late T field;` and `late T field = e;` is
        //
        // set field(T value) {
        //   this._#field = value;
        // }
        return ExpressionStatement(fieldWrite(setterValueRead()))
          ..fileOffset = fileOffset;
      } else if (initializer == null) {
        // The lowered setter for `late final T field;` is
        //
        // set field(T value) {
        //   _lateWriteOnceCheck(this._#field, "field");
        //   this._#field = value;
        // }
        return Block([
          ExpressionStatement(
              StaticInvocation(
                  _coreTypes.lateWriteOnceCheck,
                  Arguments([fieldRead(), _nameLiteral(nameText, fileOffset)])
                    ..fileOffset = fileOffset)
                ..fileOffset = fileOffset)
            ..fileOffset = fileOffset,
          ExpressionStatement(fieldWrite(setterValueRead()))
            ..fileOffset = fileOffset
        ])
          ..fileOffset = fileOffset;
      } else {
        // There is no setter for `late final T field = e;`.
        return null;
      }
    }

    Statement? body = setterBody();
    if (body != null) {
      Procedure setter = Procedure(
          name,
          ProcedureKind.Setter,
          FunctionNode(body,
              positionalParameters: [setterValue], returnType: VoidType())
            ..fileOffset = fileOffset,
          fileUri: fileUri,
          reference: field.setterReference)
        ..fileOffset = fileOffset
        ..isNonNullableByDefault = true;
      enclosingClass.addProcedure(setter);
    }

    return backingField;
  }

  TreeNode transformField(Field field, Member contextMember) {
    _contextMember = contextMember;

    if (_shouldLowerStaticField(field)) return _fieldCell(field);
    if (_shouldLowerInstanceField(field)) return _backingInstanceField(field);

    return field;
  }

  TreeNode transformFieldInitializer(
      FieldInitializer initializer, Member contextMember) {
    _contextMember = contextMember;

    // If the [Field] has been lowered, we can't use `node.field` to retrieve it
    // because the `getterReference` of the original field now points to the new
    // getter for the backing field.
    // TODO(fishythefish): Clean this up when [FieldInitializer] maintains a
    // correct [Reference] to its [Field].
    NamedNode node = initializer.fieldReference.node!;
    Field backingField;
    if (node is Field) {
      if (!_shouldLowerInstanceField(node)) return initializer;
      backingField = _backingInstanceField(node);
    } else {
      backingField = _getterToField[node]!;
    }
    return FieldInitializer(backingField, initializer.value)
      ..fileOffset = initializer.fileOffset;
  }

  StaticGet _fieldCellAccess(Field field, int fileOffset) =>
      StaticGet(_fieldCell(field))..fileOffset = fileOffset;

  TreeNode transformStaticGet(StaticGet node, Member contextMember) {
    _contextMember = contextMember;

    Member target = node.target;
    if (target is Field && _shouldLowerStaticField(target)) {
      int fileOffset = node.fileOffset;
      StaticGet cell = _fieldCellAccess(target, fileOffset);
      return _callReader(_readField, cell, target.type, fileOffset);
    }

    return node;
  }

  TreeNode transformStaticSet(StaticSet node, Member contextMember) {
    _contextMember = contextMember;

    Member target = node.target;
    if (target is Field && _shouldLowerStaticField(target)) {
      int fileOffset = node.fileOffset;
      StaticGet cell = _fieldCellAccess(target, fileOffset);
      Procedure setter = target.isFinal
          ? _coreTypes.cellFinalFieldValueSetter
          : _coreTypes.cellValueSetter;
      return _callSetter(setter, cell, node.value, fileOffset);
    }

    return node;
  }
}
