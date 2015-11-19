// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for interacting with an analysis server running in a separate
 * process.
 */
library analysis_server.test.stress.utilities.server;

import 'dart:async';
import 'dart:collection';

import 'package:analysis_server/plugin/protocol/protocol.dart';

import '../../integration/integration_test_methods.dart';
import '../../integration/integration_tests.dart' as base;

/**
 * An interface for starting and communicating with an analysis server running
 * in a separate process.
 */
class Server extends base.Server with IntegrationTestMixin {
  /**
   * A list containing the paths of files for which an overlay has been created.
   */
  List<String> filesWithOverlays = <String>[];

  /**
   * A table mapping the absolute paths of files to the most recent set of
   * errors received for that file.
   */
  Map<String, List<AnalysisError>> _errorMap =
      new HashMap<String, List<AnalysisError>>();

  /**
   * Initialize a new analysis server. The analysis server is not running and
   * must be started using [start].
   */
  Server() {
    initializeInttestMixin();
    onAnalysisErrors.listen(_recordErrors);
  }

  /**
   * Return a table mapping the absolute paths of files to the most recent set
   * of errors received for that file. The content of the map will not change
   * when new sets of errors are received.
   */
  Map<String, List<AnalysisError>> get errorMap =>
      new HashMap<String, List<AnalysisError>>.from(_errorMap);

  @override
  base.Server get server => this;

  /**
   * Remove any existing overlays.
   */
  Future<AnalysisUpdateContentResult> removeAllOverlays() {
    Map<String, dynamic> files = new HashMap<String, dynamic>();
    for (String path in filesWithOverlays) {
      files[path] = new RemoveContentOverlay();
    }
    return sendAnalysisUpdateContent(files);
  }

  @override
  Future<AnalysisUpdateContentResult> sendAnalysisUpdateContent(
      Map<String, dynamic> files) {
    files.forEach((String path, dynamic overlay) {
      if (overlay is AddContentOverlay) {
        filesWithOverlays.add(path);
      } else if (overlay is RemoveContentOverlay) {
        filesWithOverlays.remove(path);
      }
    });
    return super.sendAnalysisUpdateContent(files);
  }

  /**
   * Record the errors in the given [params].
   */
  void _recordErrors(AnalysisErrorsParams params) {
    _errorMap[params.file] = params.errors;
  }
}
