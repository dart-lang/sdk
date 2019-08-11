// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server_client/listener/server_listener.dart';

/// [BadMessageListener] throws an exception if the [Client] receives bad data.
mixin BadMessageListener on ServerListener {
  /// True if we've received bad data from the server.
  bool _receivedBadDataFromServer = false;

  void throwDelayedException(String prefix, String details) {
    if (!_receivedBadDataFromServer) {
      _receivedBadDataFromServer = true;
      // Give the server 1 second to continue outputting bad data
      // such as outputting a stacktrace.
      Future.delayed(Duration(seconds: 1), () {
        throw '$prefix $details';
      });
    }
  }

  @override
  void badMessage(String trimmedLine, exception) {
    super.badMessage(trimmedLine, exception);
    throwDelayedException('JSON decode failure', '$exception');
  }

  @override
  void errorMessage(String line) {
    super.errorMessage(line);
    throwDelayedException('ERR:', line);
  }

  @override
  void unexpectedMessage(Map<String, dynamic> message) {
    super.unexpectedMessage(message);
    throwDelayedException(
        'BAD DATA FROM SERVER:', 'Unexpected message from server');
  }

  @override
  void unexpectedResponse(Map<String, dynamic> message, id) {
    super.unexpectedResponse(message, id);
    throw 'Unexpected response from server: id=$id';
  }

  @override
  void unexpectedStop(int exitCode) {
    super.unexpectedStop(exitCode);
    throwDelayedException('Server terminated with exit code', '$exitCode');
  }
}
