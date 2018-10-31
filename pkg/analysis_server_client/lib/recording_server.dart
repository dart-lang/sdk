// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_client/server.dart';

/// A subclass of [Server] that caches all messages exchanged with the server.
/// This is primarily used when testing and debugging the analysis server.
/// Most clients will want to use [Server] rather than this class.
class RecordingServer extends Server {
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

  @override
  Future<int> kill([String reason = 'none']) {
    echoMessages();
    return super.kill(reason);
  }

  @override
  void logBadDataFromServer(String details, {bool silent: false}) {
    echoMessages();
    super.logBadDataFromServer(details, silent: silent);
  }

  /// Record a message that was exchanged with the server,
  /// and print it out if [echoMessages] has been called.
  @override
  void logMessage(String prefix, String details) {
    String line = '$currentElapseTime: $prefix $details';
    if (_echoMessages) {
      print(line);
    }
    _messages.add(line);
  }
}
