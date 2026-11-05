// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support `dart/workspace/fixes/*`.
final dartWorkspaceFixesClasses = <LspEntity>[
  interface('DartGetWorkspaceFixesParams', [
    field(
      'diagnosticCodes',
      type: 'String',
      array: true,
      canBeUndefined: true,
      comment: 'An optional set of diagnostic codes to filter to.',
    ),
  ]),
  interface('DartGetWorkspaceFixesResult', [
    field(
      'edit',
      type: 'WorkspaceEdit',
      canBeNull: true,
      comment: 'The edits to be applied to the workspace or `null` if there are none.',
    ),
    field(
      'details',
      type: 'LspBulkFix',
      array: true,
      comment: 'Additional details about the fixes we have returned edits for.',
    ),
  ]),
  interface('LspBulkFix', [
    field(
      'uri',
      type: 'Uri',
      comment: 'The URI of the library these fixes were applied to.',
    ),
    field(
      'fixes',
      type: 'LspBulkFixDetail',
      array: true,
      comment: 'A list of bulk fix details.',
    ),
  ]),
  interface('LspBulkFixDetail', [
    field(
      'code',
      type: 'String',
      comment: 'The code of the diagnostic associated with the fix.',
    ),
    field(
      'occurrences',
      type: 'int',
      comment: 'The number times the associated diagnostic was fixed in the associated source edit.',
    ),
  ]),
];
