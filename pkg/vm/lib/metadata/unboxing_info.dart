// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

class UnboxingInfoMetadata {
  static const kBoxed = 0;
  static const kUnboxedIntCandidate = 1 << 0;
  static const kUnboxedDoubleCandidate = 1 << 1;
  static const kUnboxingCandidate =
      kUnboxedIntCandidate | kUnboxedDoubleCandidate;

  final List<int> unboxedArgsInfo;
  int returnInfo;

  UnboxingInfoMetadata(int argsLen) : unboxedArgsInfo = [] {
    for (int i = 0; i < argsLen; i++) {
      unboxedArgsInfo.add(kUnboxingCandidate);
    }
    returnInfo = kUnboxingCandidate;
  }

  UnboxingInfoMetadata.readFromBinary(BinarySource source)
      : unboxedArgsInfo = List<int>.generate(
            source.readUInt(), (_) => source.readByte(),
            growable: true),
        returnInfo = source.readByte();

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(unboxedArgsInfo.length);
    for (int val in unboxedArgsInfo) {
      sink.writeByte(val);
    }
    sink.writeByte(returnInfo);
  }
}

class UnboxingInfoMetadataRepository
    extends MetadataRepository<UnboxingInfoMetadata> {
  static const repositoryTag = 'vm.unboxing-info.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, UnboxingInfoMetadata> mapping =
      <TreeNode, UnboxingInfoMetadata>{};

  @override
  void writeToBinary(
      UnboxingInfoMetadata metadata, Node node, BinarySink sink) {
    metadata.writeToBinary(sink);
  }

  @override
  UnboxingInfoMetadata readFromBinary(Node node, BinarySource source) {
    return UnboxingInfoMetadata.readFromBinary(source);
  }
}
