// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support completion resolution.
final completionResolutionClasses = <LspEntity>[
  interface(
    // Used as a base class for all resolution data classes.
    'CompletionItemResolutionInfo',
    [],
  ),
  interface('DartCompletionResolutionInfo', [
    field(
      'file',
      type: 'string',
      comment:
          'The file where the completion is being inserted.\n\n'
          'This is used to compute where to add the import.',
    ),
    field(
      'importUris',
      type: 'string',
      array: true,
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
  ], baseType: 'CompletionItemResolutionInfo'),
  interface('PubPackageCompletionItemResolutionInfo', [
    field('packageName', type: 'string'),
  ], baseType: 'CompletionItemResolutionInfo'),
];
