// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/analysis_server.dart';

/// A class that can be used to configure an analysis server instance to better
/// support intermittent file systems.
///
/// See also [AnalysisServerOptions.detachableFileSystemManager].
abstract class DetachableFileSystemManager {
  /// Indicate that the [DetachableFileSystemManager] and the containing
  /// analysis server are being shut down.
  void dispose();

  /// Forward on the 'analysis.setAnalysisRoots' request.
  ///
  /// This class can choose to pass through all [setAnalysisRoots] calls to the
  /// underlying analysis server, it can choose to modify the given
  /// [includedPaths] and other parameters, or it could choose to delays calls
  /// to [setAnalysisRoots].
  void setAnalysisRoots(String requestId, List<String> includedPaths,
      List<String> excludedPaths, Map<String, String> packageRoots);

  /// Called exactly once before any calls to [setAnalysisRoots].
  void setAnalysisServer(AnalysisServer server);
}
