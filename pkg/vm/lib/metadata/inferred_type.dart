// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.inferred_type;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

/// Metadata for annotating nodes with an inferred type information.
class InferredType {
  final InterfaceType? dartType;
  final Constant? _constantValue;
  final Reference? _closureMemberReference;
  final int _closureId;
  final int _flags;

  static const int flagNullable = 1 << 0;
  static const int flagInt = 1 << 1;

  // For invocations: whether to use the unchecked entry-point.
  static const int flagSkipCheck = 1 << 2;

  // Contains inferred constant value.
  static const int flagConstant = 1 << 3;

  static const int flagReceiverNotInt = 1 << 4;

  // Contains inferred closure value.
  static const int flagClosure = 1 << 5;

  // Contains DartType.
  static const int flagHasType = 1 << 6;

  // Whether the inferred type's class is the exact concrete class.
  static const int flagExactClass = 1 << 7;

  // Whether the inferred type (class + type arguments) is exact.
  static const int flagExactType = 1 << 8;

  InferredType(
    InterfaceType? dartType,
    bool nullable,
    bool isInt,
    Constant? constantValue,
    Member? closureMember,
    int closureId, {
    bool isExactClass = false,
    bool isExactType = false,
    bool skipCheck = false,
    bool receiverNotInt = false,
  }) : this._byReference(
         dartType,
         constantValue,
         closureMember?.reference,
         closureId,
         (nullable ? flagNullable : 0) |
             (isInt ? flagInt : 0) |
             (skipCheck ? flagSkipCheck : 0) |
             (constantValue != null ? flagConstant : 0) |
             (receiverNotInt ? flagReceiverNotInt : 0) |
             (closureMember != null ? flagClosure : 0) |
             (dartType != null ? flagHasType : 0) |
             (isExactClass ? flagExactClass : 0) |
             (isExactType ? flagExactType : 0),
       );

  InferredType._byReference(
    this.dartType,
    this._constantValue,
    this._closureMemberReference,
    this._closureId,
    this._flags,
  ) {
    assert(
      dartType == null ||
          (nullable == (dartType!.nullability == Nullability.nullable)),
    );
    assert(!isExactClass || dartType != null);
    assert(!isExactType || isExactClass);
    assert(_constantValue == null || isExactClass);
    assert(_closureMemberReference == null || isExactClass);
    assert(_closureId >= 0);
  }

  Class? get concreteClass => isExactClass ? dartType?.classNode : null;

  Constant? get constantValue => _constantValue;

  Member? get closureMember => _closureMemberReference?.asMember;
  int get closureId => _closureId;

  bool get isExactClass => (_flags & flagExactClass) != 0;
  bool get isExactType => (_flags & flagExactType) != 0;
  bool get nullable => (_flags & flagNullable) != 0;
  bool get isInt => (_flags & flagInt) != 0;
  bool get skipCheck => (_flags & flagSkipCheck) != 0;
  bool get receiverNotInt => (_flags & flagReceiverNotInt) != 0;

  int get flags => _flags;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InferredType &&
        _flags == other._flags &&
        _closureId == other._closureId &&
        _closureMemberReference == other._closureMemberReference &&
        _constantValue == other._constantValue &&
        dartType == other.dartType;
  }

  @override
  int get hashCode => Object.hash(
    _flags,
    _closureId,
    _closureMemberReference,
    _constantValue,
    dartType,
  );

  @override
  String toString() {
    final StringBuffer buf = new StringBuffer();
    final dartType = this.dartType;
    if (dartType != null) {
      buf.write(dartType.toText(astTextStrategyForTesting));
      if (!isExactClass) {
        buf.write(' (inexact)');
      } else if (!isExactType) {
        buf.write(' (inexact type args)');
      }
    } else if (isInt) {
      buf.write('int');
      if (nullable) {
        buf.write('?');
      }
    } else if (nullable) {
      buf.write('?');
    } else {
      buf.write('!');
    }
    if (skipCheck) {
      buf.write(' (skip check)');
    }
    if (_constantValue != null) {
      buf.write(
        ' (value: ${_constantValue.toText(astTextStrategyForTesting)})',
      );
    }
    if (receiverNotInt) {
      buf.write(' (receiver not int)');
    }
    if (closureMember != null) {
      buf.write(
        ' (closure ${closureId} in ${closureMember!.toText(astTextStrategyForTesting)})',
      );
    }
    return buf.toString();
  }
}

/// Repository for [InferredType].
class InferredTypeMetadataRepository extends MetadataRepository<InferredType> {
  static const String repositoryTag = 'vm.inferred-type.metadata';

  @override
  String get tag => repositoryTag;

  @override
  final Map<TreeNode, InferredType> mapping = <TreeNode, InferredType>{};

  final Map<InferredType, InferredType> _canonicalPool;

  InferredTypeMetadataRepository([
    Map<InferredType, InferredType>? canonicalPool,
  ]) : _canonicalPool = canonicalPool ?? <InferredType, InferredType>{};

  InferredType canonicalize(InferredType type) => _canonicalPool[type] ??= type;

  @override
  void writeToBinary(InferredType metadata, Node node, BinarySink sink) {
    final flags = metadata._flags;
    sink.writeUInt30(flags);
    if ((flags & InferredType.flagHasType) != 0) {
      sink.writeDartType(metadata.dartType!);
    }
    if ((flags & InferredType.flagConstant) != 0) {
      sink.writeConstantReference(metadata.constantValue!);
    }
    if ((flags & InferredType.flagClosure) != 0) {
      sink.writeNullAllowedCanonicalNameReference(
        metadata.closureMember!.reference,
      );
      sink.writeUInt30(metadata.closureId);
    }
  }

  @override
  InferredType readFromBinary(Node node, BinarySource source) {
    final flags = source.readUInt30();
    final dartType = (flags & InferredType.flagHasType) != 0
        ? source.readDartType() as InterfaceType
        : null;
    final constantValue = (flags & InferredType.flagConstant) != 0
        ? source.readConstantReference()
        : null;
    final closureMemberReference = (flags & InferredType.flagClosure) != 0
        ? source.readNullableCanonicalNameReference()!.reference
        : null;
    final closureId = (flags & InferredType.flagClosure) != 0
        ? source.readUInt30()
        : 0;

    final candidate = InferredType._byReference(
      dartType,
      constantValue,
      closureMemberReference,
      closureId,
      flags,
    );
    return canonicalize(candidate);
  }
}

/// Repository for incoming argument [InferredType].
class InferredArgTypeMetadataRepository extends InferredTypeMetadataRepository {
  static const String repositoryTag = 'vm.inferred-arg-type.metadata';

  InferredArgTypeMetadataRepository([super.canonicalPool]);

  @override
  String get tag => repositoryTag;
}

/// Repository for returned [InferredType].
class InferredReturnTypeMetadataRepository
    extends InferredTypeMetadataRepository {
  static const String repositoryTag = 'vm.inferred-return-type.metadata';

  InferredReturnTypeMetadataRepository([super.canonicalPool]);

  @override
  String get tag => repositoryTag;
}
