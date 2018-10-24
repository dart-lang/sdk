// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.inferred_type;

import 'package:kernel/ast.dart';

/// Metadata for annotating nodes with an inferred type information.
class InferredType {
  final Reference _concreteClassReference;
  final int _flags;

  static const int flagNullable = 1 << 0;
  static const int flagInt = 1 << 1;

  // For Parameters and Fields, whether a type-check is required at assignment
  // (invocation/setter). Not meaningful on other kernel nodes.
  static const int flagSkipCheck = 1 << 2;

  // Entire list may be null if no type arguments were inferred.
  // Will always be null if `concreteClass` is null.
  //
  // Each component may be null if that particular type argument was not
  // inferred.
  //
  // Otherwise, a non-null type argument indicates that that particular type
  // argument (in the runtime type) is always exactly a particular `DartType`.
  final List<DartType> exactTypeArguments;

  InferredType(Class concreteClass, bool nullable, bool isInt,
      {List<DartType> exactTypeArguments, bool skipCheck: false})
      : this._byReference(
            getClassReference(concreteClass),
            (nullable ? flagNullable : 0) |
                (isInt ? flagInt : 0) |
                (skipCheck ? flagSkipCheck : 0),
            exactTypeArguments);

  InferredType._byReference(
      this._concreteClassReference, this._flags, this.exactTypeArguments) {
    assert(exactTypeArguments == null || _concreteClassReference != null);
  }

  Class get concreteClass => _concreteClassReference?.asClass;

  bool get nullable => (_flags & flagNullable) != 0;
  bool get isInt => (_flags & flagInt) != 0;
  bool get skipCheck => (_flags & flagSkipCheck) != 0;

  @override
  String toString() {
    final base =
        "${concreteClass != null ? concreteClass : (isInt ? 'int' : '!')}";
    final suffix = "${nullable ? '?' : ''}";
    String typeArgs = "";
    if (exactTypeArguments != null) {
      typeArgs =
          exactTypeArguments.map((t) => t != null ? "$t" : "?").join(", ");
      typeArgs = "<" + typeArgs + ">";
    }
    final skip = skipCheck ? " (skip check)" : "";
    return base + suffix + typeArgs + skip;
  }
}

/// Repository for [InferredType].
class InferredTypeMetadataRepository extends MetadataRepository<InferredType> {
  @override
  final String tag = 'vm.inferred-type.metadata';

  @override
  final Map<TreeNode, InferredType> mapping = <TreeNode, InferredType>{};

  @override
  void writeToBinary(InferredType metadata, Node node, BinarySink sink) {
    // TODO(sjindel/tfa): Implement serialization of type arguments when can use
    // them for optimizations.
    sink.writeCanonicalNameReference(
        getCanonicalNameOfClass(metadata.concreteClass));
    sink.writeByte(metadata._flags);
  }

  @override
  InferredType readFromBinary(Node node, BinarySource source) {
    // TODO(sjindel/tfa): Implement serialization of type arguments when can use
    // them for optimizations.
    final concreteClassReference =
        source.readCanonicalNameReference()?.getReference();
    final flags = source.readByte();
    return new InferredType._byReference(concreteClassReference, flags, null);
  }
}
