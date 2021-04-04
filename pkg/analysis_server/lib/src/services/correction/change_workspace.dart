// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_workspace.dart';

/// [ChangeWorkspace] based on sessions.
class DartChangeWorkspace implements ChangeWorkspace {
  final List<AnalysisSession> sessions;

  DartChangeWorkspace(this.sessions);

  @override
  bool containsFile(String path) {
    for (var session in sessions) {
      if (session.analysisContext.contextRoot.isAnalyzed(path)) {
        return true;
      }
    }
    return false;
  }

  @override
  AnalysisSession getSession(String path) {
    for (var session in sessions) {
      if (session.analysisContext.contextRoot.isAnalyzed(path)) {
        return session;
      }
    }
    throw StateError('Not in a context root: $path');
  }
}
