// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.inferred_type;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

/// Metadata for annotating nodes with an inferred type information.
class InferredType {
  final Reference _concreteClassReference;
  final Constant _constantValue;
  final int _flags;

  static const int flagNullable = 1 << 0;
  static const int flagInt = 1 << 1;

  // For invocations: whether to use the unchecked entry-point.
  static const int flagSkipCheck = 1 << 2;

  static const int flagConstant = 1 << 3;

  static const int flagReceiverNotInt = 1 << 4;

  // Entire list may be null if no type arguments were inferred.
  // Will always be null if `concreteClass` is null.
  //
  // Each component may be null if that particular type argument was not
  // inferred.
  //
  // Otherwise, a non-null type argument indicates that that particular type
  // argument (in the runtime type) is always exactly a particular `DartType`.
  final List<DartType> exactTypeArguments;

  InferredType(
      Class concreteClass, bool nullable, bool isInt, Constant constantValue,
      {List<DartType> exactTypeArguments,
      bool skipCheck: false,
      bool receiverNotInt: false})
      : this._byReference(
            getClassReference(concreteClass),
            constantValue,
            (nullable ? flagNullable : 0) |
                (isInt ? flagInt : 0) |
                (skipCheck ? flagSkipCheck : 0) |
                (constantValue != null ? flagConstant : 0) |
                (receiverNotInt ? flagReceiverNotInt : 0),
            exactTypeArguments);

  InferredType._byReference(this._concreteClassReference, this._constantValue,
      this._flags, this.exactTypeArguments) {
    assert(exactTypeArguments == null || _concreteClassReference != null);
    assert(_constantValue == null || _concreteClassReference != null);
  }

  Class get concreteClass => _concreteClassReference?.asClass;

  Constant get constantValue => _constantValue;

  bool get nullable => (_flags & flagNullable) != 0;
  bool get isInt => (_flags & flagInt) != 0;
  bool get skipCheck => (_flags & flagSkipCheck) != 0;
  bool get receiverNotInt => (_flags & flagReceiverNotInt) != 0;

  int get flags => _flags;

  @override
  String toString() {
    final StringBuffer buf = new StringBuffer();
    if (concreteClass != null) {
      buf.write(concreteClass.toText(astTextStrategyForTesting));
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
      buf.write(exactTypeArguments
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
          ' (value: ${_constantValue.toText(astTextStrategyForTesting)})');
    }
    if (receiverNotInt) {
      buf.write(' (receiver not int)');
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
        getCanonicalNameOfClass(metadata.concreteClass));
    sink.writeByte(metadata._flags);
    if (metadata.constantValue != null) {
      sink.writeConstantReference(metadata.constantValue);
    }
  }

  @override
  InferredType readFromBinary(Node node, BinarySource source) {
    // TODO(sjindel/tfa): Implement serialization of type arguments when can use
    // them for optimizations.
    final concreteClassReference =
        source.readCanonicalNameReference()?.getReference();
    final flags = source.readByte();
    final constantValue = (flags & InferredType.flagConstant) != 0
        ? source.readConstantReference()
        : null;
    return new InferredType._byReference(
        concreteClassReference, constantValue, flags, null);
  }
}
