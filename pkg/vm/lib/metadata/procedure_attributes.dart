// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.procedure_attributes;

import 'package:kernel/ast.dart';

/// Metadata for annotating procedures with various attributes.
class ProcedureAttributesMetadata {
  final bool hasDynamicUses;
  final bool hasNonThisUses;
  final bool hasTearOffUses;

  const ProcedureAttributesMetadata(
      {this.hasDynamicUses, this.hasNonThisUses, this.hasTearOffUses});

  const ProcedureAttributesMetadata.noDynamicUses()
      : this(hasDynamicUses: false, hasNonThisUses: true, hasTearOffUses: true);

  @override
  String toString() => "hasDynamicUses:$hasDynamicUses,"
      "hasNonThisUses:$hasNonThisUses,"
      "hasTearOffUses:$hasTearOffUses";
}

/// Repository for [ProcedureAttributesMetadata].
class ProcedureAttributesMetadataRepository
    extends MetadataRepository<ProcedureAttributesMetadata> {
  static const int kDynamicUsesBit = 1 << 0;
  static const int kNonThisUsesBit = 1 << 1;
  static const int kTearOffUsesBit = 1 << 2;

  @override
  final String tag = 'vm.procedure-attributes.metadata';

  @override
  final Map<TreeNode, ProcedureAttributesMetadata> mapping =
      <TreeNode, ProcedureAttributesMetadata>{};

  @override
  void writeToBinary(ProcedureAttributesMetadata metadata, BinarySink sink) {
    int flags = 0;
    if (metadata.hasDynamicUses) {
      flags |= kDynamicUsesBit;
    }
    if (metadata.hasNonThisUses) {
      flags |= kNonThisUsesBit;
    }
    if (metadata.hasTearOffUses) {
      flags |= kTearOffUsesBit;
    }
    sink.writeByte(flags);
  }

  @override
  ProcedureAttributesMetadata readFromBinary(BinarySource source) {
    final int flags = source.readByte();

    final bool hasDynamicUses = (flags & kDynamicUsesBit) == kDynamicUsesBit;
    final bool hasNonThisUses = (flags & kNonThisUsesBit) == kNonThisUsesBit;
    final bool hasTearOffUses = (flags & kTearOffUsesBit) == kTearOffUsesBit;

    return new ProcedureAttributesMetadata(
        hasDynamicUses: hasDynamicUses,
        hasNonThisUses: hasNonThisUses,
        hasTearOffUses: hasTearOffUses);
  }
}
