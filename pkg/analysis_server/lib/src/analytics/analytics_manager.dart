// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/analytics/google_analytics_manager.dart';
import 'package:analysis_server/src/plugin/plugin_manager.dart';
import 'package:telemetry/telemetry.dart';

/// An interface for managing and reporting analytics.
///
/// Individual methods can either send an analytics event immediately or can
/// collect and even consolidate information to be reported later. Clients are
/// required to invoke the [shutdown] method before the server shuts down in
/// order to send any cached data.
abstract class AnalyticsManager {
  /// Return an analytics manager that will report results using the given
  /// [analytics].
  factory AnalyticsManager.forAnalytics(Analytics analytics) =
      GoogleAnalyticsManager;

  /// Record that the set of plugins known to the [pluginManager] has changed.
  void changedPlugins(PluginManager pluginManager);

  /// Record the number of [added] folders and [removed] folders.
  void changedWorkspaceFolders(
      {required List<String> added, required List<String> removed});

  /// Record that the given [notification] was received and has been handled.
  void handledNotificationMessage(
      {required NotificationMessage notification,
      required DateTime startTime,
      required DateTime endTime}) {}

  /// Record the parameters passed on initialize.
  void initialize(InitializeParams params);

  /// Record the number of [openWorkspacePaths].
  void initialized({required List<String> openWorkspacePaths});

  /// Record that the given [response] was sent to the client.
  void sentResponse({required Response response});

  /// Record that the given [response] was sent to the client.
  void sentResponseMessage({required ResponseMessage response});

  /// The server is shutting down. Report any accumulated analytics data.
  void shutdown();

  /// Record data from the given [params].
  void startedGetRefactoring(EditGetRefactoringParams params);

  /// Record that the server started working on the give [request] at the given
  /// [startTime].
  void startedRequest({required Request request, required DateTime startTime});

  /// Record that the server started working on the give [request] at the given
  /// [startTime].
  void startedRequestMessage(
      {required RequestMessage request, required DateTime startTime});

  /// Record data from the given [params].
  void startedSetAnalysisRoots(AnalysisSetAnalysisRootsParams params);

  /// Record data from the given [params].
  void startedSetPriorityFiles(AnalysisSetPriorityFilesParams params);

  /// Record that the server was started at the given [time], that it was passed
  /// the given command-line [arguments], that it was started by the client with
  /// the given [clientId] and [clientVersion], and that it was invoked from an
  /// SDK with the given [sdkVersion].
  void startUp(
      {required DateTime time,
      required List<String> arguments,
      required String clientId,
      required String? clientVersion,
      required String sdkVersion});
}
