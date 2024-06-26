// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_plugin/src/correction/change_workspace.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/file_system/file_system.dart';

/// A [ChangeWorkspace] based on [AnalysisSession]s.
class DartChangeWorkspace implements ChangeWorkspace {
  final List<AnalysisSession> sessions;

  DartChangeWorkspace(this.sessions);

  @override
  ResourceProvider get resourceProvider => sessions.first.resourceProvider;

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
    throw StateError("Not in a context root: '$path'");
  }
}
