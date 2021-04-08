// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/library_index.dart';
import 'package:kernel/type_algebra.dart';

bool _shouldLowerVariable(VariableDeclaration node) =>
    node.initializer == null && node.isLate;

class LateLowering {
  final Class _cellClass;
  final Constructor _cellConstructor;

  final Procedure _readLocal;
  List<TypeParameter> _readLocalTypeParameters;
  FunctionType _readLocalTypeWithoutTypeParameters;

  final Procedure _setValue;
  final Procedure _setFinalLocalValue;

  final Map<VariableDeclaration, VariableDeclaration> _cells = {};

  Member _contextMember;

  LateLowering(LibraryIndex index)
      : _cellClass = index.getClass('dart:_late_helper', '_Cell'),
        _cellConstructor = index.getMember('dart:_late_helper', '_Cell', ''),
        _readLocal = index.getMember('dart:_late_helper', '_Cell', 'readLocal'),
        _setValue = index.getMember('dart:_late_helper', '_Cell', 'set:value'),
        _setFinalLocalValue = index.getMember(
            'dart:_late_helper', '_Cell', 'set:finalLocalValue') {
    FunctionType _readLocalType = _readLocal.getterType;
    _readLocalTypeParameters = _readLocalType.typeParameters;
    _readLocalTypeWithoutTypeParameters = _readLocalType.withoutTypeParameters;
  }

  VariableDeclaration _variableCell(VariableDeclaration variable) {
    assert(_shouldLowerVariable(variable));
    return _cells.putIfAbsent(variable, () {
      int fileOffset = variable.fileOffset;
      return VariableDeclaration(variable.name,
          initializer:
              ConstructorInvocation(_cellConstructor, Arguments.empty())
                ..fileOffset = fileOffset,
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
    List<DartType> typeArguments = [node.promotedType ?? variable.type];
    return InstanceInvocation(
        InstanceAccessKind.Instance,
        cell,
        _readLocal.name,
        Arguments(const [], types: typeArguments)..fileOffset = fileOffset,
        interfaceTarget: _readLocal,
        functionType:
            Substitution.fromPairs(_readLocalTypeParameters, typeArguments)
                .substituteType(_readLocalTypeWithoutTypeParameters))
      ..fileOffset = fileOffset;
  }

  TreeNode transformVariableSet(VariableSet node, Member contextMember) {
    _contextMember = contextMember;

    VariableDeclaration variable = node.variable;
    if (!_shouldLowerVariable(variable)) return node;

    int fileOffset = node.fileOffset;
    VariableGet cell = _variableCellAccess(variable, fileOffset);
    if (variable.isFinal) {
      return InstanceSet(InstanceAccessKind.Instance, cell,
          _setFinalLocalValue.name, node.value,
          interfaceTarget: _setFinalLocalValue)
        ..fileOffset = fileOffset;
    } else {
      return InstanceSet(
          InstanceAccessKind.Instance, cell, _setValue.name, node.value,
          interfaceTarget: _setValue)
        ..fileOffset = fileOffset;
    }
  }
}
