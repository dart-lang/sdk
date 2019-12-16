// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server_client/listener/server_listener.dart';
import 'package:analysis_server_client/server.dart';
import 'package:dartfix/listener/bad_message_listener.dart';
import 'package:dartfix/listener/timed_listener.dart';

/// [RecordingListener] caches all messages exchanged with the server
/// and print them if a problem occurs.
///
/// This is primarily used when testing and debugging the analysis server.
class RecordingListener with ServerListener, BadMessageListener, TimedListener {
  /// True if we are currently printing out messages exchanged with the server.
  bool _echoMessages = false;

  /// Messages which have been exchanged with the server; we buffer these
  /// up until the test finishes, so that they can be examined in the debugger
  /// or printed out in response to a call to [echoMessages].
  final _messages = <String>[];

  /// Print out any messages exchanged with the server.  If some messages have
  /// already been exchanged with the server, they are printed out immediately.
  void echoMessages() {
    if (_echoMessages) {
      return;
    }
    _echoMessages = true;
    for (String line in _messages) {
      print(line);
    }
  }

  /// Called when the [Server] is terminating the server process
  /// rather than requesting that the server stop itself.
  @override
  void killingServerProcess(String reason) {
    echoMessages();
    super.killingServerProcess(reason);
  }

  /// Log a timed message about interaction with the server.
  @override
  void logTimed(double elapseTime, String prefix, String details) {
    String line = '$elapseTime: $prefix $details';
    if (_echoMessages) {
      print(line);
    }
    _messages.add(line);
  }

  @override
  void throwDelayedException(String prefix, String details) {
    echoMessages();
    super.throwDelayedException(prefix, details);
  }
}
