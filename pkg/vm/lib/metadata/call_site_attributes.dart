// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.call_site_attributes;

import 'package:kernel/ast.dart';
import 'package:kernel/src/printer.dart';

/// Metadata for annotating call sites with various attributes.
class CallSiteAttributesMetadata {
  final DartType receiverType;

  const CallSiteAttributesMetadata({this.receiverType});

  @override
  String toString() =>
      "receiverType:${receiverType.toText(astTextStrategyForTesting)}";
}

/// Repository for [CallSiteAttributesMetadata].
class CallSiteAttributesMetadataRepository
    extends MetadataRepository<CallSiteAttributesMetadata> {
  static final repositoryTag = 'vm.call-site-attributes.metadata';

  @override
  final String tag = repositoryTag;

  @override
  final Map<TreeNode, CallSiteAttributesMetadata> mapping =
      <TreeNode, CallSiteAttributesMetadata>{};

  @override
  void writeToBinary(
      CallSiteAttributesMetadata metadata, Node node, BinarySink sink) {
    sink.writeDartType(metadata.receiverType);
  }

  @override
  CallSiteAttributesMetadata readFromBinary(Node node, BinarySource source) {
    final type = source.readDartType();
    return new CallSiteAttributesMetadata(receiverType: type);
  }
}
