// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support completion resolution.
final completionResolutionClasses = <LspEntity>[
  interface(
    // Used as a base class for all resolution data classes so that we have a
    // single `fromJson()` method that deserializes into the correct subtypes.
    'CompletionResolutionInfo',
    [],
  ),
  // Merged completion resolution info for Dart files.
  //
  // As an optimization, some Dart resolution info is (if supported by the
  // client) provided once on the entire completion list instead of on each
  // item. For better type safety, this means we now have three types:
  //
  // - DartCompletionItemResolutionInfo - Original per-item data, but with
  //   optional fields
  // - DartCompletionRequestResolutionInfo - Request-level data used as defaults
  //   where not overridden by the per-item data. This only includes fields that
  //   make sense to supply at the request level.
  // - DartCompletionMergedResolutionInfo - A type that extends both of the
  //   above to be used in the resolve handler.
  interface(
    'DartCompletionMergedResolutionInfo',
    [],
    baseTypes: [
      'DartCompletionItemResolutionInfo',
      'DartCompletionRequestResolutionInfo',
      'CompletionResolutionInfo',
    ],
  ),
  // Request-level resolution info for completion in Dart files.
  // These values are merged with the per-item data (with per-item data fields
  // overriding these).
  interface('DartCompletionRequestResolutionInfo', [
    field(
      'file',
      type: 'string',
      comment:
          'The file where the completion is being inserted.\n\n'
          'This is used to compute where to add the import.',
    ),
  ], baseType: 'CompletionResolutionInfo'),
  // Per-item resolution info for Dart file completions.
  interface('DartCompletionItemResolutionInfo', [
    field(
      'file',
      type: 'string',
      // This is optional now, because it may be provided at the request level
      // instead of being duplicated on all items.
      canBeUndefined: true,
      comment:
          'The file where the completion is being inserted.\n\n'
          'This is used to compute where to add the import.',
    ),
    field(
      'importUris',
      type: 'string',
      array: true,
      // Optional, because we may use resolve for documentation even without
      // imports.
      canBeUndefined: true,
      comment: 'The URIs to be imported if this completion is selected.',
    ),
    field(
      'ref',
      type: 'string',
      canBeUndefined: true,
      comment:
          'The encoded ElementLocation2 of the item being completed.\n\n'
          'This is used to provide documentation in the resolved response.',
    ),
  ], baseType: 'CompletionResolutionInfo'),
  // Per-item resolution info for Package names in YAML files.
  interface('PubPackageCompletionItemResolutionInfo', [
    field('packageName', type: 'string'),
  ], baseType: 'CompletionResolutionInfo'),
];
