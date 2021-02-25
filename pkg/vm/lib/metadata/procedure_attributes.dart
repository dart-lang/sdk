// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.procedure_attributes;

import 'package:kernel/ast.dart';

/// Metadata for annotating procedures with various attributes.
class ProcedureAttributesMetadata {
  static const int kInvalidSelectorId = 0;

  final bool methodOrSetterCalledDynamically;
  final bool getterCalledDynamically;
  final bool hasThisUses;
  final bool hasNonThisUses;
  final bool hasTearOffUses;
  final int methodOrSetterSelectorId;
  final int getterSelectorId;

  const ProcedureAttributesMetadata(
      {this.methodOrSetterCalledDynamically: true,
      this.getterCalledDynamically: true,
      this.hasThisUses: true,
      this.hasNonThisUses: true,
      this.hasTearOffUses: true,
      this.methodOrSetterSelectorId: kInvalidSelectorId,
      this.getterSelectorId: kInvalidSelectorId});

  const ProcedureAttributesMetadata.noDynamicUses()
      : this(
            methodOrSetterCalledDynamically: false,
            getterCalledDynamically: false);

  @override
  String toString() {
    final attrs = <String>[];
    if (!methodOrSetterCalledDynamically) {
      attrs.add('methodOrSetterCalledDynamically:false');
    }
    if (!getterCalledDynamically) attrs.add('getterCalledDynamically:false');
    if (!hasThisUses) attrs.add('hasThisUses:false');
    if (!hasNonThisUses) attrs.add('hasNonThisUses:false');
    if (!hasTearOffUses) attrs.add('hasTearOffUses:false');
    if (methodOrSetterSelectorId != kInvalidSelectorId) {
      attrs.add('methodOrSetterSelectorId:$methodOrSetterSelectorId');
    }
    if (getterSelectorId != kInvalidSelectorId) {
      attrs.add('getterSelectorId:$getterSelectorId');
    }
    return attrs.join(',');
  }
}

/// Repository for [ProcedureAttributesMetadata].
class ProcedureAttributesMetadataRepository
    extends MetadataRepository<ProcedureAttributesMetadata> {
  static const int kMethodOrSetterCalledDynamicallyBit = 1 << 0;
  static const int kNonThisUsesBit = 1 << 1;
  static const int kTearOffUsesBit = 1 << 2;
  static const int kThisUsesBit = 1 << 3;
  static const int kGetterCalledDynamicallyBit = 1 << 4;

  static const repositoryTag = 'vm.procedure-attributes.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, ProcedureAttributesMetadata> mapping =
      <TreeNode, ProcedureAttributesMetadata>{};

  int _getFlags(ProcedureAttributesMetadata metadata) {
    int flags = 0;
    if (metadata.methodOrSetterCalledDynamically) {
      flags |= kMethodOrSetterCalledDynamicallyBit;
    }
    if (metadata.getterCalledDynamically) {
      flags |= kGetterCalledDynamicallyBit;
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
    sink.writeUInt30(metadata.methodOrSetterSelectorId);
    sink.writeUInt30(metadata.getterSelectorId);
  }

  @override
  ProcedureAttributesMetadata readFromBinary(Node node, BinarySource source) {
    final int flags = source.readByte();

    final bool methodOrSetterCalledDynamically =
        (flags & kMethodOrSetterCalledDynamicallyBit) != 0;
    final bool getterCalledDynamically =
        (flags & kGetterCalledDynamicallyBit) != 0;
    final bool hasThisUses = (flags & kThisUsesBit) != 0;
    final bool hasNonThisUses = (flags & kNonThisUsesBit) != 0;
    final bool hasTearOffUses = (flags & kTearOffUsesBit) != 0;

    final int methodOrSetterSelectorId = source.readUInt30();
    final int getterSelectorId = source.readUInt30();

    return new ProcedureAttributesMetadata(
        methodOrSetterCalledDynamically: methodOrSetterCalledDynamically,
        getterCalledDynamically: getterCalledDynamically,
        hasThisUses: hasThisUses,
        hasNonThisUses: hasNonThisUses,
        hasTearOffUses: hasTearOffUses,
        methodOrSetterSelectorId: methodOrSetterSelectorId,
        getterSelectorId: getterSelectorId);
  }
}
