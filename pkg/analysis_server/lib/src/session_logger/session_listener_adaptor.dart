// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/session_listener.dart';
import 'package:analyzer/instrumentation/instrumentation.dart';

/// An instrumentation service that passes information about the analysis server
/// session to a session listener.
class SessionListenerAdaptor(final SessionListener listener)
    implements InstrumentationService {
  @override
  void logError(String message) {
    listener.logException(exception: message);
  }

  @override
  void logException(
    Object exception, [
    StackTrace? stackTrace,
    List<InstrumentationServiceAttachment>? attachments,
  ]) {
    listener.logException(
      exception: exception,
      stackTrace: stackTrace,
      attachments: attachments,
    );
  }

  @override
  void logInfo(String message, [exception]) {
    listener.logInfo(message);
  }

  @override
  void logLogEntry(
    String level,
    DateTime time,
    String message,
    Object exception,
    StackTrace stackTrace,
  ) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logNotification(String notification) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logPluginError(
    PluginData plugin,
    String code,
    String message,
    String stackTrace,
  ) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logPluginException(
    PluginData plugin,
    Object exception,
    StackTrace? stackTrace,
  ) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logPluginNotification(String pluginId, String notification) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logPluginRequest(String pluginId, String request) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logPluginResponse(String pluginId, String response) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logPluginTimeout(PluginData plugin, String request) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logRequest(String request) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logResponse(String response) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logVersion(
    String uuid,
    String clientId,
    String clientVersion,
    String serverVersion,
    String sdkVersion,
  ) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  void logWatchEvent(String folderPath, String filePath, String changeType) {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
  }

  @override
  Future<void> shutdown() {
    // TODO(brianwilkerson): Report that this method was unexpectedly invoked.
    return Future.value();
  }
}
