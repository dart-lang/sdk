// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.procedure_attributes;

import 'package:kernel/ast.dart';

/// Metadata for annotating procedures with various attributes.
class ProcedureAttributesMetadata {
  final bool hasDynamicUses;
  final bool hasThisUses;
  final bool hasNonThisUses;
  final bool hasTearOffUses;

  const ProcedureAttributesMetadata(
      {this.hasDynamicUses: true,
      this.hasThisUses: true,
      this.hasNonThisUses: true,
      this.hasTearOffUses: true});

  const ProcedureAttributesMetadata.noDynamicUses()
      : this(hasDynamicUses: false);

  @override
  String toString() {
    final attrs = <String>[];
    if (!hasDynamicUses) attrs.add('hasDynamicUses:false');
    if (!hasThisUses) attrs.add('hasThisUses:false');
    if (!hasNonThisUses) attrs.add('hasNonThisUses:false');
    if (!hasTearOffUses) attrs.add('hasTearOffUses:false');
    return attrs.join(',');
  }
}

/// Repository for [ProcedureAttributesMetadata].
class ProcedureAttributesMetadataRepository
    extends MetadataRepository<ProcedureAttributesMetadata> {
  static const int kDynamicUsesBit = 1 << 0;
  static const int kNonThisUsesBit = 1 << 1;
  static const int kTearOffUsesBit = 1 << 2;
  static const int kThisUsesBit = 1 << 3;

  static const repositoryTag = 'vm.procedure-attributes.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, ProcedureAttributesMetadata> mapping =
      <TreeNode, ProcedureAttributesMetadata>{};

  int _getFlags(ProcedureAttributesMetadata metadata) {
    int flags = 0;
    if (metadata.hasDynamicUses) {
      flags |= kDynamicUsesBit;
    }
    if (metadata.hasThisUses) {
      flags |= kThisUsesBit;
    }
    if (metadata.hasNonThisUses) {
      flags |= kNonThisUsesBit;
    }
    if (metadata.hasTearOffUses) {
      flags |= kTearOffUsesBit;
    }
    return flags;
  }

  @override
  void writeToBinary(
      ProcedureAttributesMetadata metadata, Node node, BinarySink sink) {
    sink.writeByte(_getFlags(metadata));
  }

  @override
  ProcedureAttributesMetadata readFromBinary(Node node, BinarySource source) {
    final int flags = source.readByte();

    final bool hasDynamicUses = (flags & kDynamicUsesBit) != 0;
    final bool hasThisUses = (flags & kThisUsesBit) != 0;
    final bool hasNonThisUses = (flags & kNonThisUsesBit) != 0;
    final bool hasTearOffUses = (flags & kTearOffUsesBit) != 0;

    return new ProcedureAttributesMetadata(
        hasDynamicUses: hasDynamicUses,
        hasThisUses: hasThisUses,
        hasNonThisUses: hasNonThisUses,
        hasTearOffUses: hasTearOffUses);
  }

  /// Converts [metadata] into a bytecode attribute.
  Constant getBytecodeAttribute(ProcedureAttributesMetadata metadata) =>
      IntConstant(_getFlags(metadata));
}
