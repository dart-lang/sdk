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
  final List<UnboxingType> argsInfo;
  UnboxingType returnInfo;
  bool mustUseStackCallingConvention;

  UnboxingInfoMetadata(int argsLen)
      : argsInfo = List<UnboxingType>.filled(argsLen, UnboxingType.kUnknown,
            growable: true),
        returnInfo = UnboxingType.kUnknown,
        mustUseStackCallingConvention = false;

  UnboxingInfoMetadata.readFromBinary(BinarySource source)
      : argsInfo = List<UnboxingType>.generate(
            source.readUInt30(), (_) => UnboxingType.readFromBinary(source),
            growable: true),
        returnInfo = UnboxingType.readFromBinary(source),
        mustUseStackCallingConvention = source.readByte() != 0;

  // Returns `true` if this [UnboxingInfoMetadata] matches default one:
  // all arguments and the return value are boxed and the method is not
  // forced to use stack based calling convention.
  //
  // Trivial metadata can be omitted and not written into the Kernel binary.
  bool get isTrivial {
    if (returnInfo != UnboxingType.kBoxed) return false;
    for (final argInfo in argsInfo) {
      if (argInfo != UnboxingType.kBoxed) return false;
    }
    if (mustUseStackCallingConvention) {
      return false;
    }
    return true;
  }

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(argsInfo.length);
    for (final argInfo in argsInfo) {
      argInfo.writeToBinary(sink);
    }
    returnInfo.writeToBinary(sink);
    sink.writeByte(mustUseStackCallingConvention ? 1 : 0);
  }

  /// Remove placeholder parameter info slot for setters that the getter is
  /// grouped with.
  UnboxingInfoMetadata toGetterInfo() => UnboxingInfoMetadata(0)
    ..returnInfo = returnInfo
    ..mustUseStackCallingConvention = mustUseStackCallingConvention;

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
