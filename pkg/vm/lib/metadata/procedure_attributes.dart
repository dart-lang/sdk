// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.metadata.procedure_attributes;

import 'package:kernel/ast.dart';

/// Metadata for annotating procedures with various attributes.
class ProcedureAttributesMetadata {
  final bool hasDynamicInvocations;

  const ProcedureAttributesMetadata({this.hasDynamicInvocations});

  const ProcedureAttributesMetadata.noDynamicInvocations()
      : hasDynamicInvocations = false;

  @override
  String toString() => "hasDynamicInvocations:${hasDynamicInvocations}";
}

/// Repository for [ProcedureAttributesMetadata].
class ProcedureAttributesMetadataRepository
    extends MetadataRepository<ProcedureAttributesMetadata> {
  @override
  final String tag = 'vm.procedure-attributes.metadata';

  @override
  final Map<TreeNode, ProcedureAttributesMetadata> mapping =
      <TreeNode, ProcedureAttributesMetadata>{};

  @override
  void writeToBinary(ProcedureAttributesMetadata metadata, BinarySink sink) {
    assert(!metadata.hasDynamicInvocations);
  }

  @override
  ProcedureAttributesMetadata readFromBinary(BinarySource source) {
    return const ProcedureAttributesMetadata.noDynamicInvocations();
  }
}
