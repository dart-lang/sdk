// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:vm/transformations/type_flow/types.dart' show RecordShape;

enum UnboxingKind {
  boxed,
  int,
  double,
  record,
  unknown, // Not calculated yet.
}

class UnboxingType {
  final UnboxingKind kind;
  final RecordShape? recordShape;

  const UnboxingType._(this.kind, this.recordShape);
  UnboxingType.record(RecordShape shape) : this._(UnboxingKind.record, shape);

  static const kUnknown = UnboxingType._(UnboxingKind.unknown, null);
  static const kInt = UnboxingType._(UnboxingKind.int, null);
  static const kDouble = UnboxingType._(UnboxingKind.double, null);
  static const kBoxed = UnboxingType._(UnboxingKind.boxed, null);

  UnboxingType intersect(UnboxingType other) {
    if (kind == UnboxingKind.unknown) return other;
    if (other.kind == UnboxingKind.unknown) return this;
    if (this == other) return this;
    return kBoxed;
  }

  @override
  bool operator ==(other) =>
      identical(this, other) ||
      (other is UnboxingType &&
          this.kind == other.kind &&
          this.recordShape == other.recordShape);

  @override
  int get hashCode => (kind.index * 31) + recordShape.hashCode;

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(kind.index);
    if (kind == UnboxingKind.record) {
      recordShape!.writeToBinary(sink);
    }
  }

  factory UnboxingType.readFromBinary(BinarySource source) {
    final kind = UnboxingKind.values[source.readUInt30()];
    final recordShape = (kind == UnboxingKind.record)
        ? RecordShape.readFromBinary(source)
        : null;
    return UnboxingType._(kind, recordShape);
  }

  @override
  String toString() {
    switch (kind) {
      case UnboxingKind.boxed:
        return 'b';
      case UnboxingKind.int:
        return 'i';
      case UnboxingKind.double:
        return 'd';
      case UnboxingKind.record:
        {
          final sb = StringBuffer();
          sb.write('r<');
          sb.write(recordShape!.numPositionalFields.toString());
          for (final named in recordShape!.namedFields) {
            sb.write(',');
            sb.write(named);
          }
          sb.write('>');
          return sb.toString();
        }
      case UnboxingKind.unknown:
        return '_|_';
    }
  }
}

class UnboxingInfoMetadata {
  /// For GDT selectors the length of this array reflects minimum number of
  /// direct parameters (excluding this) across all implementations reachable
  /// through a selector. If there is an override with less direct parameters
  /// than interface target has declared then
  /// [hasOverridesWithLessDirectParameters] must be set to `true`.
  final List<UnboxingType> argsInfo;
  UnboxingType returnInfo;
  bool mustUseStackCallingConvention;
  bool hasOverridesWithLessDirectParameters = false;

  UnboxingInfoMetadata(int argsLen,
      {UnboxingType initialValue = UnboxingType.kUnknown})
      : argsInfo = List<UnboxingType>.filled(
          argsLen,
          initialValue,
          growable: true,
        ),
        returnInfo = initialValue,
        mustUseStackCallingConvention = false;

  factory UnboxingInfoMetadata.readFromBinary(BinarySource source) {
    final result = UnboxingInfoMetadata(source.readUInt30(),
        initialValue: UnboxingType.kBoxed);
    final flags = source.readByte();
    result.mustUseStackCallingConvention =
        (flags & _mustUseStackCallingConventionFlag) != 0;
    result.hasOverridesWithLessDirectParameters =
        (flags & _hasOverridesWithLessDirectParametersFlag) != 0;
    if ((flags & _hasUnboxedParameterOrReturnValueFlag) != 0) {
      for (var i = 0; i < result.argsInfo.length; i++) {
        result.argsInfo[i] = UnboxingType.readFromBinary(source);
      }
      result.returnInfo = UnboxingType.readFromBinary(source);
    }
    return result;
  }

  void adjustParameterCount(int argsLen) {
    if (argsLen != argsInfo.length) {
      hasOverridesWithLessDirectParameters = true;
    }

    if (argsLen < argsInfo.length) {
      argsInfo.length = argsLen;
    }
  }

  bool get hasUnboxedParameterOrReturnValue {
    if (returnInfo != UnboxingType.kBoxed) return true;
    for (final argInfo in argsInfo) {
      if (argInfo != UnboxingType.kBoxed) return true;
    }
    return false;
  }

  void setFullyBoxed() {
    argsInfo.length = 0;
    returnInfo = UnboxingType.kBoxed;
    mustUseStackCallingConvention = true;
  }

  // Returns `true` if this [UnboxingInfoMetadata] matches default one:
  // all arguments and the return value are boxed, the method is not
  // forced to use stack based calling convention and there is no override
  // which uses less direct parameters.
  //
  // Trivial metadata can be omitted and not written into the Kernel binary.
  bool get isTrivial {
    return !mustUseStackCallingConvention &&
        !hasOverridesWithLessDirectParameters &&
        !hasUnboxedParameterOrReturnValue;
  }

  static const _mustUseStackCallingConventionFlag = 1 << 0;
  static const _hasUnboxedParameterOrReturnValueFlag = 1 << 1;
  static const _hasOverridesWithLessDirectParametersFlag = 1 << 2;

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(argsInfo.length);
    final flags = (mustUseStackCallingConvention
            ? _mustUseStackCallingConventionFlag
            : 0) |
        (hasUnboxedParameterOrReturnValue
            ? _hasUnboxedParameterOrReturnValueFlag
            : 0) |
        (hasOverridesWithLessDirectParameters
            ? _hasOverridesWithLessDirectParametersFlag
            : 0);
    sink.writeByte(flags);
    if ((flags & _hasUnboxedParameterOrReturnValueFlag) != 0) {
      for (final argInfo in argsInfo) {
        argInfo.writeToBinary(sink);
      }
      returnInfo.writeToBinary(sink);
    }
  }

  /// Remove placeholder parameter info slot for setters that the getter is
  /// grouped with.
  UnboxingInfoMetadata toGetterInfo() => UnboxingInfoMetadata(0)
    ..returnInfo = returnInfo
    ..mustUseStackCallingConvention = mustUseStackCallingConvention;

  UnboxingInfoMetadata toFieldInfo() {
    if (argsInfo.length == 1 && argsInfo[0] == UnboxingType.kUnknown) {
      // Drop information about the setter if we did not compute anything
      // useful.
      return toGetterInfo();
    }
    return this;
  }

  @override
  String toString() {
    final sb = StringBuffer();
    if (mustUseStackCallingConvention) {
      return '[!regcc]';
    }
    sb.write('(');
    for (int i = 0; i < argsInfo.length; ++i) {
      final argInfo = argsInfo[i];
      sb.write(argInfo.toString());
      if (i != (argsInfo.length - 1)) {
        sb.write(',');
      }
    }
    sb.write(')');
    sb.write('->');
    sb.write(returnInfo.toString());
    return sb.toString();
  }
}

class UnboxingInfoMetadataRepository
    extends MetadataRepository<UnboxingInfoMetadata> {
  static const repositoryTag = 'vm.unboxing-info.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, UnboxingInfoMetadata> mapping =
      <TreeNode, UnboxingInfoMetadata>{};

  @override
  void writeToBinary(
      UnboxingInfoMetadata metadata, Node node, BinarySink sink) {
    metadata.writeToBinary(sink);
  }

  @override
  UnboxingInfoMetadata readFromBinary(Node node, BinarySource source) {
    return UnboxingInfoMetadata.readFromBinary(source);
  }
}
