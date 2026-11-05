// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.procedure_attributes;

import 'package:kernel/ast.dart';

/// Metadata for annotating procedures with various attributes.
class ProcedureAttributesMetadata {
  static const int kInvalidSelectorId = 0;

  static const int _methodOrSetterCalledDynamicallyBit = 1 << 0;
  static const int _nonThisUsesBit = 1 << 1;
  static const int _tearOffUsesBit = 1 << 2;
  static const int _thisUsesBit = 1 << 3;
  static const int _getterCalledDynamicallyBit = 1 << 4;
  static const int _numFlags = 5;
  static const int _flagsMask = (1 << _numFlags) - 1;

  static const int _selectorIdBits = (64 - _numFlags) ~/ 2;
  static const int _maxSelectorId = (1 << _selectorIdBits) - 1;
  static const int _selectorIdMask = _maxSelectorId;
  static const int _methodOrSetterSelectorIdShift = _numFlags;
  static const int _getterSelectorIdShift =
      _methodOrSetterSelectorIdShift + _selectorIdBits;

  final int _flagsAndSelectorIds;

  const ProcedureAttributesMetadata._(this._flagsAndSelectorIds);

  ProcedureAttributesMetadata({
    bool methodOrSetterCalledDynamically = true,
    bool getterCalledDynamically = true,
    bool hasThisUses = true,
    bool hasNonThisUses = true,
    bool hasTearOffUses = true,
    int methodOrSetterSelectorId = kInvalidSelectorId,
    int getterSelectorId = kInvalidSelectorId,
  }) : this._(
         _encode(
           methodOrSetterCalledDynamically,
           getterCalledDynamically,
           hasThisUses,
           hasNonThisUses,
           hasTearOffUses,
           methodOrSetterSelectorId,
           getterSelectorId,
         ),
       );

  static int _encode(
    bool methodOrSetterCalledDynamically,
    bool getterCalledDynamically,
    bool hasThisUses,
    bool hasNonThisUses,
    bool hasTearOffUses,
    int methodOrSetterSelectorId,
    int getterSelectorId,
  ) {
    if (methodOrSetterSelectorId < 0 ||
        methodOrSetterSelectorId > _maxSelectorId) {
      throw RangeError.range(
        methodOrSetterSelectorId,
        0,
        _maxSelectorId,
        'methodOrSetterSelectorId',
      );
    }
    if (getterSelectorId < 0 || getterSelectorId > _maxSelectorId) {
      throw RangeError.range(
        getterSelectorId,
        0,
        _maxSelectorId,
        'getterSelectorId',
      );
    }
    return (methodOrSetterCalledDynamically
            ? _methodOrSetterCalledDynamicallyBit
            : 0) |
        (hasNonThisUses ? _nonThisUsesBit : 0) |
        (hasTearOffUses ? _tearOffUsesBit : 0) |
        (hasThisUses ? _thisUsesBit : 0) |
        (getterCalledDynamically ? _getterCalledDynamicallyBit : 0) |
        (methodOrSetterSelectorId << _methodOrSetterSelectorIdShift) |
        (getterSelectorId << _getterSelectorIdShift);
  }

  const ProcedureAttributesMetadata.noDynamicUses({
    bool hasThisUses = true,
    bool hasNonThisUses = true,
    bool hasTearOffUses = true,
  }) : this._(
         (hasNonThisUses ? _nonThisUsesBit : 0) |
             (hasTearOffUses ? _tearOffUsesBit : 0) |
             (hasThisUses ? _thisUsesBit : 0),
       );

  bool get methodOrSetterCalledDynamically =>
      (_flagsAndSelectorIds & _methodOrSetterCalledDynamicallyBit) != 0;
  bool get getterCalledDynamically =>
      (_flagsAndSelectorIds & _getterCalledDynamicallyBit) != 0;
  bool get hasThisUses => (_flagsAndSelectorIds & _thisUsesBit) != 0;
  bool get hasNonThisUses => (_flagsAndSelectorIds & _nonThisUsesBit) != 0;
  bool get hasTearOffUses => (_flagsAndSelectorIds & _tearOffUsesBit) != 0;

  int get methodOrSetterSelectorId =>
      (_flagsAndSelectorIds >>> _methodOrSetterSelectorIdShift) &
      _selectorIdMask;
  int get getterSelectorId => _flagsAndSelectorIds >>> _getterSelectorIdShift;

  int get _flags => _flagsAndSelectorIds & _flagsMask;

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
  static const repositoryTag = 'vm.procedure-attributes.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, ProcedureAttributesMetadata> mapping =
      <TreeNode, ProcedureAttributesMetadata>{};

  @override
  void writeToBinary(
    ProcedureAttributesMetadata metadata,
    Node node,
    BinarySink sink,
  ) {
    sink.writeByte(metadata._flags);
    sink.writeUInt30(metadata.methodOrSetterSelectorId);
    sink.writeUInt30(metadata.getterSelectorId);
  }

  @override
  ProcedureAttributesMetadata readFromBinary(Node node, BinarySource source) {
    final int flags = source.readByte();
    final int methodOrSetterSelectorId = source.readUInt30();
    final int getterSelectorId = source.readUInt30();

    return ProcedureAttributesMetadata._(
      flags |
          (methodOrSetterSelectorId <<
              ProcedureAttributesMetadata._methodOrSetterSelectorIdShift) |
          (getterSelectorId <<
              ProcedureAttributesMetadata._getterSelectorIdShift),
    );
  }
}
