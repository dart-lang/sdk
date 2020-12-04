// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.direct_call;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

/// Metadata for annotating method invocations converted to direct calls.
class DirectCallMetadata {
  final Reference _targetReference;
  final bool checkReceiverForNull;

  DirectCallMetadata(Member target, bool checkReceiverForNull)
      : this.byReference(
            getMemberReferenceGetter(target), checkReceiverForNull);

  DirectCallMetadata.byReference(
      this._targetReference, this.checkReceiverForNull);

  Member get target => _targetReference.asMember;

  @override
  String toString() => "${target.toText(astTextStrategyForTesting)}"
      "${checkReceiverForNull ? '??' : ''}";
}

/// Repository for [DirectCallMetadata].
class DirectCallMetadataRepository
    extends MetadataRepository<DirectCallMetadata> {
  static const repositoryTag = 'vm.direct-call.metadata';

  @override
  String get tag => repositoryTag;

  @override
  final Map<TreeNode, DirectCallMetadata> mapping =
      <TreeNode, DirectCallMetadata>{};

  @override
  void writeToBinary(DirectCallMetadata metadata, Node node, BinarySink sink) {
    sink.writeNullAllowedCanonicalNameReference(
        getCanonicalNameOfMemberGetter(metadata.target));
    sink.writeByte(metadata.checkReceiverForNull ? 1 : 0);
  }

  @override
  DirectCallMetadata readFromBinary(Node node, BinarySource source) {
    final targetReference = source.readCanonicalNameReference()?.getReference();
    if (targetReference == null) {
      throw 'DirectCallMetadata should have a non-null target';
    }
    final checkReceiverForNull = (source.readByte() != 0);
    return new DirectCallMetadata.byReference(
        targetReference, checkReceiverForNull);
  }
}
