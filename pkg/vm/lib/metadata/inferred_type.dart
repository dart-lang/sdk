// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.inferred_type;

import 'package:kernel/ast.dart';

/// Metadata for annotating nodes with an inferred type information.
class InferredType {
  final Reference _concreteClassReference;
  final bool nullable;

  InferredType(Class concreteClass, bool nullable)
      : this._byReference(getClassReference(concreteClass), nullable);

  InferredType._byReference(this._concreteClassReference, this.nullable);

  Class get concreteClass => _concreteClassReference?.asClass;

  @override
  String toString() =>
      "${concreteClass != null ? concreteClass : '!'}${nullable ? '?' : ''}";
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
    sink.writeByte(metadata.nullable ? 1 : 0);
  }

  @override
  InferredType readFromBinary(Node node, BinarySource source) {
    final concreteClassReference =
        source.readCanonicalNameReference()?.getReference();
    final nullable = (source.readByte() != 0);
    return new InferredType._byReference(concreteClassReference, nullable);
  }
}
