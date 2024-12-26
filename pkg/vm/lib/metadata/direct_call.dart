// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.direct_call;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

/// Metadata for annotating invocations converted to direct calls.
class DirectCallMetadata {
  // Target of the direct call or enclosing member of a closure.
  final Reference _memberReference;
  final int _flags;
  final int _closureId;

  static const int flagCheckReceiverForNull = 1 << 0;
  static const int flagClosure = 1 << 1;

  DirectCallMetadata.targetMember(Member target, bool checkReceiverForNull)
      : this._(getNonNullableMemberReferenceGetter(target),
            checkReceiverForNull ? flagCheckReceiverForNull : 0, 0);

  DirectCallMetadata.targetClosure(
      Member closureMember, int closureId, bool checkReceiverForNull)
      : this._(
            getNonNullableMemberReferenceGetter(closureMember),
            (checkReceiverForNull ? flagCheckReceiverForNull : 0) | flagClosure,
            closureId);

  DirectCallMetadata._(this._memberReference, this._flags, this._closureId)
      : assert(_closureId >= 0);

  // Target member or enclosing member of a closure.
  Member get _member => _memberReference.asMember;

  Member? get targetMember => isClosure ? null : _member;

  bool get checkReceiverForNull => (_flags & flagCheckReceiverForNull) != 0;
  bool get isClosure => (_flags & flagClosure) != 0;

  /// When calling a closure, the enclosing member of the closure, and the
  /// closure index.
  ///
  /// Closures in a member are assigned ids based on pre-order traversal of the
  /// member body, and the member itself also counts as a closure (for
  /// tear-offs). So index 0 is the member itself, called as a closure
  /// (tear-off).
  (Member, int)? get targetClosure => isClosure ? (_member, _closureId) : null;

  @override
  String toString() => isClosure
      ? 'closure ${_closureId} in ${_member.toText(astTextStrategyForTesting)}'
      : '${_member.toText(astTextStrategyForTesting)}${checkReceiverForNull ? '??' : ''}';
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
        getMemberReferenceGetter(metadata._member));
    sink.writeByte(metadata._flags);
    if (metadata.isClosure) {
      sink.writeUInt30(metadata._closureId);
    }
  }

  @override
  DirectCallMetadata readFromBinary(Node node, BinarySource source) {
    final memberReference =
        source.readNullableCanonicalNameReference()?.reference;
    if (memberReference == null) {
      throw 'DirectCallMetadata should have a non-null member';
    }
    final flags = source.readByte();
    final closureId =
        (flags & DirectCallMetadata.flagClosure) != 0 ? source.readUInt30() : 0;
    return DirectCallMetadata._(memberReference, flags, closureId);
  }
}
