// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

import 'procedure_attributes.dart';

// Information associated with a selector, used by the dispatch table generator.
class TableSelectorInfo {
  static const int _calledOnNullBit = 1 << 0;
  static const int _tornOffBit = 1 << 1;
  static const int _callCountShift = 2;
  static const int _flagsMask = (1 << _callCountShift) - 1;
  static const int _callCountBits = 30 - _callCountShift;
  static const int _maxCallCount = (1 << _callCountBits) - 1;

  int _flagsAndCallCount;

  bool get calledOnNull => (_flagsAndCallCount & _calledOnNullBit) != 0;
  set calledOnNull(bool value) {
    _flagsAndCallCount = value
        ? (_flagsAndCallCount | _calledOnNullBit)
        : (_flagsAndCallCount & ~_calledOnNullBit);
  }

  bool get tornOff => (_flagsAndCallCount & _tornOffBit) != 0;
  set tornOff(bool value) {
    _flagsAndCallCount = value
        ? (_flagsAndCallCount | _tornOffBit)
        : (_flagsAndCallCount & ~_tornOffBit);
  }

  int get callCount => _flagsAndCallCount >>> _callCountShift;
  set callCount(int value) {
    if (value < 0 || value > _maxCallCount) {
      throw RangeError.range(value, 0, _maxCallCount, 'callCount');
    }
    _flagsAndCallCount =
        (value << _callCountShift) | (_flagsAndCallCount & _flagsMask);
  }

  TableSelectorInfo() : _flagsAndCallCount = 0;

  TableSelectorInfo.readFromBinary(BinarySource source)
    : _flagsAndCallCount = source.readUInt30();

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(_flagsAndCallCount);
  }
}

class TableSelectorMetadata {
  final List<TableSelectorInfo> selectors;

  TableSelectorMetadata()
    : selectors = <TableSelectorInfo>[TableSelectorInfo()] {
    assert(
      selectors.length == ProcedureAttributesMetadata.kInvalidSelectorId + 1,
    );
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
    TableSelectorMetadata metadata,
    Node node,
    BinarySink sink,
  ) {
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
      length,
      (_) => TableSelectorInfo.readFromBinary(source),
    );
    return TableSelectorMetadata.fromSelectors(selectors);
  }
}
