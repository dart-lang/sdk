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

  InferredType(Class concreteClass, bool nullable, bool isInt)
      : this._byReference(getClassReference(concreteClass),
            (nullable ? flagNullable : 0) | (isInt ? flagInt : 0));

  InferredType._byReference(this._concreteClassReference, this._flags);

  Class get concreteClass => _concreteClassReference?.asClass;

  bool get nullable => (_flags & flagNullable) != 0;
  bool get isInt => (_flags & flagInt) != 0;

  @override
  String toString() =>
      "${concreteClass != null ? concreteClass : (isInt ? 'int' : '!')}${nullable ? '?' : ''}";
}

/// Repository for [InferredType].
class InferredTypeMetadataRepository extends MetadataRepository<InferredType> {
  @override
  final String tag = 'vm.inferred-type.metadata';

  @override
  final Map<TreeNode, InferredType> mapping = <TreeNode, InferredType>{};

  @override
  void writeToBinary(InferredType metadata, Node node, BinarySink sink) {
    sink.writeCanonicalNameReference(
        getCanonicalNameOfClass(metadata.concreteClass));
    sink.writeByte(metadata._flags);
  }

  @override
  InferredType readFromBinary(Node node, BinarySource source) {
    final concreteClassReference =
        source.readCanonicalNameReference()?.getReference();
    final flags = source.readByte();
    return new InferredType._byReference(concreteClassReference, flags);
  }
}
