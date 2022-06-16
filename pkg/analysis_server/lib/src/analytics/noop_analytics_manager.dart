// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analytics/analytics_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';

/// An implementation of [AnalyticsManager] that's appropriate to use when
/// analytics have not been enabled.
class NoopAnalyticsManager implements AnalyticsManager {
  @override
  void changedPlugins(PluginManager pluginManager) {}

  @override
  void changedWorkspaceFolders(
      {required List<String> added, required List<String> removed}) {}

  @override
  void handledNotificationMessage(
      {required NotificationMessage notification,
      required DateTime startTime,
      required DateTime endTime}) {}

  @override
  void initialize(InitializeParams params) {}

  @override
  void initialized({required List<String> openWorkspacePaths}) {}

  @override
  void sentResponse({required Response response}) {}

  @override
  void sentResponseMessage({required ResponseMessage response}) {}

  @override
  void shutdown() {}

  @override
  void startedGetRefactoring(EditGetRefactoringParams params) {}

  @override
  void startedRequest(
      {required Request request, required DateTime startTime}) {}

  @override
  void startedRequestMessage(
      {required RequestMessage request, required DateTime startTime}) {}

  @override
  void startedSetAnalysisRoots(AnalysisSetAnalysisRootsParams params) {}

  @override
  void startedSetPriorityFiles(AnalysisSetPriorityFilesParams params) {}

  @override
  void startUp(
      {required DateTime time,
      required List<String> arguments,
      required String clientId,
      required String? clientVersion,
      required String sdkVersion}) {}
}
