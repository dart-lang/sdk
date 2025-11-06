// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

enum ApiSurface { none, signatureFormalParameters, signatureReturnType }

enum MutationKind {
  insertUnitHeaderComment(
    'insert_unit_header_comment',
    apiSurface: ApiSurface.none,
    selector: SelectorMode.parsed,
  ),

  removeLastFormalParameter(
    'remove_last_formal_parameter',
    apiSurface: ApiSurface.signatureFormalParameters,
    selector: SelectorMode.parsed,
  ),

  renameLocalVariable(
    'rename_local_variable',
    apiSurface: ApiSurface.none,
    selector: SelectorMode.resolved,
  ),

  swapTopLevelFunctions(
    'swap_top_level_functions',
    apiSurface: ApiSurface.none,
    selector: SelectorMode.parsed,
  ),

  toggleReturnTypeNullability(
    'toggle_return_type_nullability',
    apiSurface: ApiSurface.signatureReturnType,
    selector: SelectorMode.parsed,
  );

  static final Map<String, MutationKind> byId = {
    for (final kind in MutationKind.values) kind.id: kind,
  };

  final String id;
  final ApiSurface apiSurface;
  final SelectorMode selector;

  const MutationKind(
    this.id, {
    required this.apiSurface,
    required this.selector,
  });

  static MutationKind parse(String id) {
    return byId[id] ?? (throw ArgumentError('Unknown kind: $id'));
  }
}

enum SelectorMode { parsed, resolved }
