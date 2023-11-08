// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart';
import 'package:kernel/type_algebra.dart';

import '../../options.dart';

class _Reader {
  final Procedure _procedure;
  final FunctionType _type;

  _Reader(this._procedure) : _type = _procedure.getterType as FunctionType;
}

const _lateInstanceFieldPrefix = '_#';
const _lateFinalUninitializedSuffix = '#F';
const _lateAssignableUninitializedSuffix = '#A';
const _lateFinalInitializedSuffix = '#FI';
const _lateAssignableInitializedSuffix = '#AI';

bool _hasFinalSuffix(String name) {
  return name.endsWith(_lateFinalUninitializedSuffix) ||
      name.endsWith(_lateFinalInitializedSuffix);
}

bool _hasAssignableSuffix(String name) {
  return name.endsWith(_lateAssignableUninitializedSuffix) ||
      name.endsWith(_lateAssignableInitializedSuffix);
}

bool isBackingFieldForLateInstanceField(Field field) {
  assert(!field.isStatic);
  if (!field.isInternalImplementation) return false;
  final name = field.name.text;
  return name.startsWith(_lateInstanceFieldPrefix) &&
      (_hasFinalSuffix(name) || _hasAssignableSuffix(name));
}

bool isBackingFieldForLateFinalInstanceField(Field field) {
  if (!field.isInternalImplementation) return false;
  final name = field.name.text;
  return name.startsWith(_lateInstanceFieldPrefix) && _hasFinalSuffix(name);
}

class LateLowering {
  final CoreTypes _coreTypes;

  final bool _omitLateNames;

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

  Member? _contextMember;

  LateLowering(this._coreTypes, CompilerOptions? _options)
      : _omitLateNames = _options?.omitLateNames ?? false,
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
      field.isLate && !field.isStatic;

  Name _mangleFieldCellName(Field field) {
    assert(_shouldLowerStaticField(field));
    return Name('_#${field.name.text}', field.enclosingLibrary);
  }

  Name _mangleFieldName(Field field) {
    assert(_shouldLowerInstanceField(field));
    final prefix = _lateInstanceFieldPrefix;
    final suffix = field.initializer == null
        ? field.isFinal
            ? _lateFinalUninitializedSuffix
            : _lateAssignableUninitializedSuffix
        : field.isFinal
            ? _lateFinalInitializedSuffix
            : _lateAssignableInitializedSuffix;

    Class cls = field.enclosingClass!;
    return Name(
        '$prefix${cls.name}#${field.name.text}$suffix', field.enclosingLibrary);
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
            FunctionTypeInstantiator.instantiate(reader._type, typeArguments))
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

  void exitLibrary() {
    assert(_variableCells.isEmpty);
    _fieldCells.clear();
    _backingInstanceFields.clear();
  }

  void enterScope() {
    _variableCells.add(null);
  }

  void exitScope() {
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
        isFinal: true,
        isSynthesized: true)
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
        isFinal: true,
        isSynthesized: true)
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
      Uri fileUri = field.fileUri;
      DartType type = field.type;
      // We need to unbind the canonical name since we reuse the reference but
      // change the name.
      field.fieldReference.canonicalName?.unbind();
      Field fieldCell = Field.immutable(_mangleFieldCellName(field),
          type: InterfaceType(_coreTypes.cellClass, nonNullable),
          initializer: _callCellConstructor(
              _nameLiteral(name.text, fileOffset), fileOffset),
          isFinal: true,
          isStatic: true,
          fileUri: fileUri,
          fieldReference: field.fieldReference)
        ..fileOffset = fileOffset
        ..isNonNullableByDefault = true
        // TODO(fishythefish,srujzs,johnniwinther): Also mark the getter/setter
        //  as extension/extension type members.
        ..isExtensionMember = field.isExtensionMember
        ..isExtensionTypeMember = field.isExtensionTypeMember;
      StaticGet fieldCellAccess() =>
          StaticGet(fieldCell)..fileOffset = fileOffset;

      Procedure getter = Procedure(
          name,
          ProcedureKind.Getter,
          FunctionNode(
              ReturnStatement(
                  _callReader(_readField, fieldCellAccess(), type, fileOffset))
                ..fileOffset = fileOffset,
              returnType: type)
            ..fileOffset = fileOffset,
          isStatic: true,
          fileUri: fileUri,
          reference: field.getterReference)
        ..fileOffset = fileOffset
        ..isNonNullableByDefault = true;

      VariableDeclaration setterValue =
          VariableDeclaration('value', type: type, isSynthesized: true)
            ..fileOffset = fileOffset;
      VariableGet setterValueRead() =>
          VariableGet(setterValue)..fileOffset = fileOffset;

      Procedure setter = Procedure(
          name,
          ProcedureKind.Setter,
          FunctionNode(
              ReturnStatement(_callSetter(
                  field.isFinal
                      ? _coreTypes.cellFinalFieldValueSetter
                      : _coreTypes.cellValueSetter,
                  fieldCellAccess(),
                  setterValueRead(),
                  fileOffset))
                ..fileOffset = fileOffset,
              positionalParameters: [setterValue],
              returnType: VoidType())
            ..fileOffset = fileOffset,
          isStatic: true,
          fileUri: fileUri,
          reference: field.setterReference)
        ..fileOffset = fileOffset
        ..isNonNullableByDefault = true;

      TreeNode parent = field.parent!;
      if (parent is Class) {
        parent.addProcedure(getter);
        parent.addProcedure(setter);
      } else if (parent is Library) {
        parent.addProcedure(getter);
        parent.addProcedure(setter);
      }

      return fieldCell;
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
    Name mangledName = _mangleFieldName(field);
    DartType type = field.type;
    Expression? initializer = field.initializer;
    Class enclosingClass = field.enclosingClass!;

    // We need to unbind the canonical name since we reuse the reference but
    // change the name.
    field.fieldReference.canonicalName?.unbind();
    Field backingField = Field.mutable(mangledName,
        type: type,
        initializer: StaticInvocation(_coreTypes.createSentinelMethod,
            Arguments(const [], types: [type])..fileOffset = fileOffset)
          ..fileOffset = fileOffset,
        fileUri: fileUri,
        fieldReference: field.fieldReference)
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
        VariableDeclaration value = VariableDeclaration('value',
            initializer: fieldRead(), type: type, isSynthesized: true)
          ..fileOffset = fileOffset;
        VariableGet valueRead() => VariableGet(value)..fileOffset = fileOffset;
        VariableDeclaration result = VariableDeclaration('result',
            initializer: initializer,
            type: type,
            isFinal: true,
            isSynthesized: true)
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
        //
        // The following lowering is also possible but currently worse:
        //
        // T get field {
        //   var value = this._#field;
        //   return isSentinel(value) ? this._#field = e : value;
        // }
        //
        // This lowering avoids generating an extra narrowing node in inference,
        // but the generated code is worse due to poor register allocation.
        VariableDeclaration value = VariableDeclaration('value',
            initializer: fieldRead(), type: type, isSynthesized: true)
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
    // The initializer is copied from [field] to [getter] so we copy the
    // transformer flags to reflect whether the getter contains super calls.
    getter.transformerFlags = field.transformerFlags;
    _copyAnnotations(getter, field);
    enclosingClass.addProcedure(getter);

    VariableDeclaration setterValue =
        VariableDeclaration('value', type: type, isSynthesized: true)
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
      _copyAnnotations(setter, field);
      enclosingClass.addProcedure(setter);
    }

    return backingField;
  }

  void _copyAnnotations(Member target, Member source) {
    for (final annotation in source.annotations) {
      if (annotation is ConstantExpression) {
        target.addAnnotation(
            ConstantExpression(annotation.constant, annotation.type)
              ..fileOffset = annotation.fileOffset);
      } else {
        throw StateError('Non-constant annotation on $source');
      }
    }
  }

  TreeNode transformField(Field field, Member contextMember) {
    _contextMember = contextMember;

    if (_shouldLowerStaticField(field)) return _fieldCell(field);
    if (_shouldLowerInstanceField(field)) return _backingInstanceField(field);

    return field;
  }
}
