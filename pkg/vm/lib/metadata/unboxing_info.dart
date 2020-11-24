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
            source.readUInt30(), (_) => source.readByte(),
            growable: true),
        returnInfo = source.readByte();

  // Returns `true` if all arguments as well as the return value have to be
  // boxed.
  //
  // We don't have to write out metadata for fully boxed methods, because this
  // is the default.
  bool get isFullyBoxed {
    if (returnInfo != kBoxed) return false;
    for (int argInfo in unboxedArgsInfo) {
      if (argInfo != kBoxed) return false;
    }
    return true;
  }

  void writeToBinary(BinarySink sink) {
    sink.writeUInt30(unboxedArgsInfo.length);
    for (int val in unboxedArgsInfo) {
      sink.writeByte(val);
    }
    sink.writeByte(returnInfo);
  }

  @override
  String toString() {
    final sb = StringBuffer();
    sb.write('(');
    for (int i = 0; i < unboxedArgsInfo.length; ++i) {
      final argInfo = unboxedArgsInfo[i];
      sb.write(_stringifyUnboxingInfo(argInfo));
      if (i != (unboxedArgsInfo.length - 1)) {
        sb.write(',');
      }
    }
    sb.write(')');
    sb.write('->');
    sb.write(_stringifyUnboxingInfo(returnInfo));
    return sb.toString();
  }

  static String _stringifyUnboxingInfo(int info) {
    if (info == UnboxingInfoMetadata.kUnboxedIntCandidate) {
      return 'i';
    } else if (info == UnboxingInfoMetadata.kUnboxedDoubleCandidate) {
      return 'd';
    }
    assert(info == 0);
    return 'b';
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
