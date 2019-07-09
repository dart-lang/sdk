// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This file has been automatically generated. Please do not edit it manually.
// To regenerate the file, use the script
// "pkg/analysis_server/tool/spec/generate_files".

import 'dart:async';

import 'package:analysis_server_client/handler/notification_handler.dart';
import 'package:analysis_server_client/protocol.dart';

/// [AnalysisCompleteHandler] listens to analysis server notifications
/// and detects when analysis has finished.
mixin AnalysisCompleteHandler on NotificationHandler {
  Completer<void> _analysisComplete;

  @override
  void onServerStatus(ServerStatusParams params) {
    if (params.analysis != null && !params.analysis.isAnalyzing) {
      _analysisComplete?.complete();
      _analysisComplete = null;
    }
  }

  Future<void> analysisComplete() {
    _analysisComplete ??= Completer<void>();
    return _analysisComplete.future;
  }
}
