// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

bool _shouldLowerVariable(VariableDeclaration variable) => variable.isLate;

bool _shouldLowerUninitializedVariable(VariableDeclaration variable) =>
    _shouldLowerVariable(variable) && variable.initializer == null;

bool _shouldLowerInitializedVariable(VariableDeclaration variable) =>
    _shouldLowerVariable(variable) && variable.initializer != null;

bool _shouldLowerField(Field field) =>
    field.isLate && field.isStatic && field.initializer == null;

class _Reader {
  final Procedure _procedure;
  final FunctionType _type;
  FunctionType _typeWithoutTypeParameters;

  _Reader(this._procedure) : _type = _procedure.getterType {
    _typeWithoutTypeParameters = _type.withoutTypeParameters;
  }
}

class LateLowering {
  final CoreTypes _coreTypes;

  final bool omitLateNames;

  final _Reader _readLocal;
  final _Reader _readField;
  final _Reader _readInitialized;
  final _Reader _readInitializedFinal;

  // Each map contains the mapping from late local variables to cells for a
  // given function scope.
  final List<Map<VariableDeclaration, VariableDeclaration>> _variableCells = [];

  final Map<Field, Field> _fieldCells = {};

  Member _contextMember;

  LateLowering(this._coreTypes, {this.omitLateNames})
      : assert(omitLateNames != null),
        _readLocal = _Reader(_coreTypes.cellReadLocal),
        _readField = _Reader(_coreTypes.cellReadField),
        _readInitialized = _Reader(_coreTypes.initializedCellRead),
        _readInitializedFinal = _Reader(_coreTypes.initializedCellReadFinal);

  Nullability get nonNullable => _contextMember.enclosingLibrary.nonNullable;

  void transformAdditionalExports(Library library) {
    List<Reference> additionalExports = library.additionalExports;
    Set<Reference> newExports = {};
    additionalExports.removeWhere((Reference reference) {
      Field cell = _fieldCells[reference.node];
      if (cell == null) return false;
      newExports.add(cell.getterReference);
      return true;
    });
    additionalExports.addAll(newExports);
  }

  ConstructorInvocation _callCellConstructor(Expression name, int fileOffset) =>
      omitLateNames
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
      omitLateNames
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

  StringLiteral _nameLiteral(String name, int fileOffset) =>
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
                .substituteType(reader._typeWithoutTypeParameters))
      ..fileOffset = fileOffset;
  }

  InstanceSet _callSetter(Procedure _setter, Expression receiver,
          Expression value, int fileOffset) =>
      InstanceSet(InstanceAccessKind.Instance, receiver, _setter.name, value,
          interfaceTarget: _setter)
        ..fileOffset = fileOffset;

  void enterFunction() {
    _variableCells.add(null);
  }

  void exitFunction() {
    _variableCells.removeLast();
  }

  VariableDeclaration _lookupVariableCell(VariableDeclaration variable) {
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
    String name = variable.name;
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
    String name = variable.name;
    final cell = VariableDeclaration(name,
        initializer: _callInitializedCellConstructor(
            _nameLiteral(name, fileOffset),
            _initializerClosure(variable.initializer, variable.type),
            fileOffset),
        type: InterfaceType(_coreTypes.initializedCellClass, nonNullable),
        isFinal: true)
      ..fileOffset = fileOffset;
    return _addToCurrentScope(variable, cell);
  }

  TreeNode transformVariableDeclaration(
      VariableDeclaration variable, Member contextMember) {
    _contextMember = contextMember;

    if (!_shouldLowerVariable(variable)) return variable;

    // A [VariableDeclaration] being used as a statement must be a direct child
    // of a [Block].
    if (variable.parent is! Block) return variable;

    return _variableCell(variable);
  }

  VariableGet _variableCellAccess(
      VariableDeclaration variable, int fileOffset) {
    assert(_shouldLowerVariable(variable));
    return VariableGet(_variableCell(variable))..fileOffset = fileOffset;
  }

  TreeNode transformVariableGet(VariableGet node, Member contextMember) {
    _contextMember = contextMember;

    VariableDeclaration variable = node.variable;
    if (!_shouldLowerVariable(variable)) return node;

    int fileOffset = node.fileOffset;
    VariableGet cell = _variableCellAccess(variable, fileOffset);
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
    VariableGet cell = _variableCellAccess(variable, fileOffset);
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
    assert(_shouldLowerField(field));
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

  StaticGet _fieldCellAccess(Field field, int fileOffset) =>
      StaticGet(_fieldCell(field))..fileOffset = fileOffset;

  TreeNode transformField(Field field, Member contextMember) {
    _contextMember = contextMember;

    if (!_shouldLowerField(field)) return field;

    return _fieldCell(field);
  }

  TreeNode transformStaticGet(StaticGet node, Member contextMember) {
    _contextMember = contextMember;

    Member target = node.target;
    if (target is Field && _shouldLowerField(target)) {
      int fileOffset = node.fileOffset;
      StaticGet cell = _fieldCellAccess(target, fileOffset);
      return _callReader(_readField, cell, target.type, fileOffset);
    } else {
      return node;
    }
  }

  TreeNode transformStaticSet(StaticSet node, Member contextMember) {
    _contextMember = contextMember;

    Member target = node.target;
    if (target is Field && _shouldLowerField(target)) {
      int fileOffset = node.fileOffset;
      StaticGet cell = _fieldCellAccess(target, fileOffset);
      Procedure setter = target.isFinal
          ? _coreTypes.cellFinalFieldValueSetter
          : _coreTypes.cellValueSetter;
      return _callSetter(setter, cell, node.value, fileOffset);
    } else {
      return node;
    }
  }
}
