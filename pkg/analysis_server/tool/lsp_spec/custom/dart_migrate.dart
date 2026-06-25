// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support `dart/workspace/migrate`.
final dartMigrateClasses = <LspEntity>[
  interface('DartMigrateParams', [
    field(
      'uris',
      type: 'DocumentUri',
      array: true,
      comment:
          'The URIs of the directories (packages or workspaces) to migrate. '
          'Individual file URIs are not supported.',
    ),
    field(
      'apply',
      type: 'boolean',
      canBeUndefined: true,
      comment: 'Whether to apply the migration changes.',
    ),
  ]),
  interface('DartMigrateResult', [
    field(
      'summary',
      type: 'String',
      canBeNull: true,
      comment:
          'A summary of the migration results, detailing which fixes '
          'succeeded, which fixes failed to be applied, and the new '
          'SDK version constraint applied to the pubspec.yaml.',
    ),
    field(
      'edit',
      type: 'WorkspaceEdit',
      canBeNull: true,
      comment: 'The edits to be applied to the workspace.',
    ),
  ]),
];
