// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/type_algebra.dart';

bool _shouldLowerVariable(VariableDeclaration node) =>
    node.initializer == null && node.isLate;

bool _shouldLowerField(Field node) =>
    node.initializer == null && node.isStatic && node.isLate;

class _Reader {
  final Procedure _procedure;
  final FunctionType _type;
  FunctionType _typeWithoutTypeParameters;

  _Reader(this._procedure) : _type = _procedure.getterType {
    _typeWithoutTypeParameters = _type.withoutTypeParameters;
  }
}

class LateLowering {
  final Class _cellClass;
  final Constructor _cellConstructor;

  final _Reader _readLocal;
  final _Reader _readField;

  final Procedure _setValue;
  final Procedure _setFinalLocalValue;
  final Procedure _setFinalFieldValue;

  // TODO(fishythefish): Remove cells when exiting their scope.
  final Map<VariableDeclaration, VariableDeclaration> _variableCells = {};
  final Map<Field, Field> _fieldCells = {};

  Member _contextMember;

  LateLowering(LibraryIndex index)
      : _cellClass = index.getClass('dart:_late_helper', '_Cell'),
        _cellConstructor = index.getMember('dart:_late_helper', '_Cell', ''),
        _readLocal =
            _Reader(index.getMember('dart:_late_helper', '_Cell', 'readLocal')),
        _readField =
            _Reader(index.getMember('dart:_late_helper', '_Cell', 'readField')),
        _setValue = index.getMember('dart:_late_helper', '_Cell', 'set:value'),
        _setFinalLocalValue = index.getMember(
            'dart:_late_helper', '_Cell', 'set:finalLocalValue'),
        _setFinalFieldValue = index.getMember(
            'dart:_late_helper', '_Cell', 'set:finalFieldValue');

  ConstructorInvocation _callCellConstructor(int fileOffset) =>
      ConstructorInvocation(
          _cellConstructor, Arguments.empty()..fileOffset = fileOffset)
        ..fileOffset = fileOffset;

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

  InstanceInvocation _callReadLocal(
          Expression receiver, DartType type, int fileOffset) =>
      _callReader(_readLocal, receiver, type, fileOffset);

  InstanceInvocation _callReadField(
          Expression receiver, DartType type, int fileOffset) =>
      _callReader(_readField, receiver, type, fileOffset);

  InstanceSet _callSetter(Procedure _setter, Expression receiver,
          Expression value, int fileOffset) =>
      InstanceSet(InstanceAccessKind.Instance, receiver, _setter.name, value,
          interfaceTarget: _setter)
        ..fileOffset = fileOffset;

  InstanceSet _callSetValue(
          Expression receiver, Expression value, int fileOffset) =>
      _callSetter(_setValue, receiver, value, fileOffset);

  InstanceSet _callSetFinalLocalValue(
          Expression receiver, Expression value, int fileOffset) =>
      _callSetter(_setFinalLocalValue, receiver, value, fileOffset);

  InstanceSet _callSetFinalFieldValue(
          Expression receiver, Expression value, int fileOffset) =>
      _callSetter(_setFinalFieldValue, receiver, value, fileOffset);

  VariableDeclaration _variableCell(VariableDeclaration variable) {
    assert(_shouldLowerVariable(variable));
    return _variableCells.putIfAbsent(variable, () {
      int fileOffset = variable.fileOffset;
      return VariableDeclaration(variable.name,
          initializer: _callCellConstructor(fileOffset),
          type: InterfaceType(
              _cellClass, _contextMember.enclosingLibrary.nonNullable),
          isFinal: true)
        ..fileOffset = fileOffset;
    });
  }

  VariableGet _variableCellAccess(
          VariableDeclaration variable, int fileOffset) =>
      VariableGet(_variableCell(variable))..fileOffset = fileOffset;

  TreeNode transformVariableDeclaration(
      VariableDeclaration node, Member contextMember) {
    _contextMember = contextMember;

    if (!_shouldLowerVariable(node)) return node;

    // A [VariableDeclaration] being used as a statement must be a direct child
    // of a [Block].
    if (node.parent is! Block) return node;

    return _variableCell(node);
  }

  TreeNode transformVariableGet(VariableGet node, Member contextMember) {
    _contextMember = contextMember;

    VariableDeclaration variable = node.variable;
    if (!_shouldLowerVariable(variable)) return node;

    int fileOffset = node.fileOffset;
    VariableGet cell = _variableCellAccess(variable, fileOffset);
    return _callReadLocal(cell, node.promotedType ?? variable.type, fileOffset);
  }

  TreeNode transformVariableSet(VariableSet node, Member contextMember) {
    _contextMember = contextMember;

    VariableDeclaration variable = node.variable;
    if (!_shouldLowerVariable(variable)) return node;

    int fileOffset = node.fileOffset;
    VariableGet cell = _variableCellAccess(variable, fileOffset);
    return variable.isFinal
        ? _callSetFinalLocalValue(cell, node.value, fileOffset)
        : _callSetValue(cell, node.value, fileOffset);
  }

  Field _fieldCell(Field field) {
    assert(_shouldLowerField(field));
    return _fieldCells.putIfAbsent(field, () {
      int fileOffset = field.fileOffset;
      field.getterReference.canonicalName?.unbind();
      field.setterReference?.canonicalName?.unbind();
      return Field.immutable(field.name,
          type: InterfaceType(_cellClass, field.enclosingLibrary.nonNullable),
          initializer: _callCellConstructor(fileOffset),
          isFinal: true,
          isStatic: true,
          fileUri: field.fileUri)
        ..fileOffset = fileOffset
        ..isNonNullableByDefault = true;
    });
  }

  StaticGet _fieldCellAccess(Field field, int fileOffset) =>
      StaticGet(_fieldCell(field))..fileOffset = fileOffset;

  TreeNode transformField(Field node, Member contextMember) {
    _contextMember = contextMember;

    if (!_shouldLowerField(node)) return node;

    return _fieldCell(node);
  }

  TreeNode transformStaticGet(StaticGet node, Member contextMember) {
    _contextMember = contextMember;

    Member target = node.target;
    if (target is Field && _shouldLowerField(target)) {
      int fileOffset = node.fileOffset;
      StaticGet cell = _fieldCellAccess(target, fileOffset);
      return _callReadField(cell, target.type, fileOffset);
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
      return target.isFinal
          ? _callSetFinalFieldValue(cell, node.value, fileOffset)
          : _callSetValue(cell, node.value, fileOffset);
    } else {
      return node;
    }
  }
}
