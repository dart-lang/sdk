// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'procedure_attributes.dart';

// Information associated with a selector, used by the dispatch table generator.
class TableSelectorInfo {
  static const int kCalledOnNullBit = 1 << 0;
  static const int kTornOffBit = 1 << 1;

  int callCount;
  int flags;

  bool get calledOnNull => (flags & kCalledOnNullBit) != 0;
  set calledOnNull(bool value) {
    flags = value ? (flags | kCalledOnNullBit) : (flags & ~kCalledOnNullBit);
  }

  bool get tornOff => (flags & kTornOffBit) != 0;
  set tornOff(bool value) {
    flags = value ? (flags | kTornOffBit) : (flags & ~kTornOffBit);
  }

  TableSelectorInfo()
      : callCount = 0,
        flags = 0;

  TableSelectorInfo.readFromBinary(BinarySource source)
      : callCount = source.readUInt30(),
        flags = source.readByte();

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(callCount);
    sink.writeByte(flags);
  }
}

class TableSelectorMetadata {
  final List<TableSelectorInfo> selectors;

  TableSelectorMetadata()
      : selectors = <TableSelectorInfo>[TableSelectorInfo()] {
    assert(
        selectors.length == ProcedureAttributesMetadata.kInvalidSelectorId + 1);
  }

  TableSelectorMetadata.fromSelectors(this.selectors);

  int addSelector() {
    final int selectorId = selectors.length;
    selectors.add(TableSelectorInfo());
    return selectorId;
  }
}

class TableSelectorMetadataRepository
    extends MetadataRepository<TableSelectorMetadata> {
  static const repositoryTag = 'vm.table-selector.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, TableSelectorMetadata> mapping =
      <TreeNode, TableSelectorMetadata>{};

  @override
  void writeToBinary(
      TableSelectorMetadata metadata, Node node, BinarySink sink) {
    final List<TableSelectorInfo> selectors = metadata.selectors;
    sink.writeUInt30(selectors.length);
    for (TableSelectorInfo selector in selectors) {
      selector.writeToBinary(sink);
    }
  }

  @override
  TableSelectorMetadata readFromBinary(Node node, BinarySource source) {
    final int length = source.readUInt30();
    final List<TableSelectorInfo> selectors = List<TableSelectorInfo>.generate(
        length, (_) => TableSelectorInfo.readFromBinary(source));
    return TableSelectorMetadata.fromSelectors(selectors);
  }
}
