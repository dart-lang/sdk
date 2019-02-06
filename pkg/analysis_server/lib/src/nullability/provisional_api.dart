// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/src/dart/nullability/transitional_api.dart'
    as analyzer;

/// Provisional API for DartFix to perform nullability migration.
///
/// Usage: pass each input source file to [prepareInput].  Then pass each input
/// source file to [processInput].  Then call [finish] to obtain the
/// modifications that need to be made to each source file.
///
/// TODO(paulberry): figure out whether this API is what we want, and figure out
/// what file/folder it belongs in.
class NullabilityMigration {
  final _analyzerMigration = analyzer.NullabilityMigration();

  List<SourceFileEdit> finish() {
    var results = <SourceFileEdit>[];
    _analyzerMigration.finish().forEach((path, modifications) {
      var sourceFileEdit = SourceFileEdit(path, -1);
      for (var modification in modifications) {
        sourceFileEdit
            .add(SourceEdit(modification.location, 0, modification.insert));
      }
      results.add(sourceFileEdit);
    });
    return results;
  }

  void prepareInput(ResolvedUnitResult result) {
    _analyzerMigration.prepareInput(result.path, result.unit);
  }

  void processInput(ResolvedUnitResult result) {
    _analyzerMigration.processInput(result.unit, result.typeProvider);
  }
}
