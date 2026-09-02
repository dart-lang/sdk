// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';

extension MigrationStepExtension on MigrationStep {
  String get displayName => switch (this) {
    MigrationStep.Prepare => 'preparatory',
    MigrationStep.Cleanup => 'cleanup',
    MigrationStep.Bump => 'version bump',
    _ => toString(),
  };
}

extension MigrationStepListExtension on List<MigrationStep> {
  bool get runAll => runPrepare && runBump && runCleanup;
  bool get runBump =>
      contains(MigrationStep.All) || contains(MigrationStep.Bump);
  bool get runCleanup =>
      contains(MigrationStep.All) || contains(MigrationStep.Cleanup);
  bool get runPrepare =>
      contains(MigrationStep.All) || contains(MigrationStep.Prepare);
}
