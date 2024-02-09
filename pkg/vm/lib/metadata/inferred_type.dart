// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.inferred_type;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

/// Metadata for annotating nodes with an inferred type information.
class InferredType {
  final Reference? _concreteClassReference;
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

  // Entire list may be null if no type arguments were inferred.
  // Will always be null if `concreteClass` is null.
  //
  // Each component may be null if that particular type argument was not
  // inferred.
  //
  // Otherwise, a non-null type argument indicates that that particular type
  // argument (in the runtime type) is always exactly a particular `DartType`.
  final List<DartType?>? exactTypeArguments;

  InferredType(Class? concreteClass, bool nullable, bool isInt,
      Constant? constantValue, Member? closureMember, int closureId,
      {List<DartType?>? exactTypeArguments,
      bool skipCheck = false,
      bool receiverNotInt = false})
      : this._byReference(
            concreteClass?.reference,
            constantValue,
            closureMember?.reference,
            closureId,
            (nullable ? flagNullable : 0) |
                (isInt ? flagInt : 0) |
                (skipCheck ? flagSkipCheck : 0) |
                (constantValue != null ? flagConstant : 0) |
                (receiverNotInt ? flagReceiverNotInt : 0) |
                (closureMember != null ? flagClosure : 0),
            exactTypeArguments);

  InferredType._byReference(
      this._concreteClassReference,
      this._constantValue,
      this._closureMemberReference,
      this._closureId,
      this._flags,
      this.exactTypeArguments) {
    assert(exactTypeArguments == null || _concreteClassReference != null);
    assert(_constantValue == null || _concreteClassReference != null);
    assert(_closureMemberReference == null || _concreteClassReference != null);
    assert(_closureId >= 0);
  }

  Class? get concreteClass => _concreteClassReference?.asClass;

  Constant? get constantValue => _constantValue;

  Member? get closureMember => _closureMemberReference?.asMember;
  int get closureId => _closureId;

  bool get nullable => (_flags & flagNullable) != 0;
  bool get isInt => (_flags & flagInt) != 0;
  bool get skipCheck => (_flags & flagSkipCheck) != 0;
  bool get receiverNotInt => (_flags & flagReceiverNotInt) != 0;

  int get flags => _flags;

  @override
  String toString() {
    final StringBuffer buf = new StringBuffer();
    if (concreteClass != null) {
      buf.write(concreteClass!.toText(astTextStrategyForTesting));
    } else if (isInt) {
      buf.write('int');
    } else {
      buf.write('!');
    }
    if (nullable) {
      buf.write('?');
    }
    if (exactTypeArguments != null) {
      buf.write('<');
      buf.write(exactTypeArguments!
          .map(
              (t) => t != null ? "${t.toText(astTextStrategyForTesting)}" : "?")
          .join(", "));
      buf.write('>');
    }
    if (skipCheck) {
      buf.write(' (skip check)');
    }
    if (_constantValue != null) {
      buf.write(
          ' (value: ${_constantValue!.toText(astTextStrategyForTesting)})');
    }
    if (receiverNotInt) {
      buf.write(' (receiver not int)');
    }
    if (closureMember != null) {
      buf.write(
          ' (closure ${closureId} in ${closureMember!.toText(astTextStrategyForTesting)})');
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

  @override
  void writeToBinary(InferredType metadata, Node node, BinarySink sink) {
    // TODO(sjindel/tfa): Implement serialization of type arguments when can use
    // them for optimizations.
    sink.writeNullAllowedCanonicalNameReference(
        metadata.concreteClass?.reference);
    final flags = metadata._flags;
    sink.writeByte(metadata._flags);
    if ((flags & InferredType.flagConstant) != 0) {
      sink.writeConstantReference(metadata.constantValue!);
    }
    if ((flags & InferredType.flagClosure) != 0) {
      sink.writeNullAllowedCanonicalNameReference(
          metadata.closureMember!.reference);
      sink.writeUInt30(metadata.closureId);
    }
  }

  @override
  InferredType readFromBinary(Node node, BinarySource source) {
    // TODO(sjindel/tfa): Implement serialization of type arguments when can use
    // them for optimizations.
    final concreteClassReference =
        source.readNullableCanonicalNameReference()?.reference;
    final flags = source.readByte();
    final constantValue = (flags & InferredType.flagConstant) != 0
        ? source.readConstantReference()
        : null;
    final closureMemberReference = (flags & InferredType.flagClosure) != 0
        ? source.readNullableCanonicalNameReference()!.reference
        : null;
    final closureId =
        (flags & InferredType.flagClosure) != 0 ? source.readUInt30() : 0;
    return new InferredType._byReference(concreteClassReference, constantValue,
        closureMemberReference, closureId, flags, null);
  }
}

/// Repository for incoming argument [InferredType].
class InferredArgTypeMetadataRepository extends InferredTypeMetadataRepository {
  static const String repositoryTag = 'vm.inferred-arg-type.metadata';

  @override
  String get tag => repositoryTag;
}
