// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/listener/server_listener.dart';

/// [TimedListener] appends a timestamp (seconds since server startup)
/// to each logged interaction with the server.
mixin TimedListener on ServerListener {
  /// Stopwatch that we use to generate timing information for debug output.
  final Stopwatch _time = Stopwatch();

  /// The [currentElapseTime] at which the last communication was received from
  /// the server or `null` if no communication has been received.
  double lastCommunicationTime;

  /// The current elapse time (seconds) since the server was started.
  double get currentElapseTime => _time.elapsedTicks / _time.frequency;

  @override
  void log(String prefix, String details) {
    logTimed(currentElapseTime, prefix, details);
  }

  /// Log a timed message about interaction with the server.
  void logTimed(double elapseTime, String prefix, String details);

  @override
  void messageReceived(String json) {
    lastCommunicationTime = currentElapseTime;
    super.messageReceived(json);
  }

  @override
  void startingServer(String dartBinary, List<String> arguments) {
    _time.start();
    super.startingServer(dartBinary, arguments);
  }
}
