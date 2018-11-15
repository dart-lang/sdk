// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Instances of the class [ClientListener] receive information from [Client]
/// about interactions with the server.
///
/// Clients may mix-in this class, but may not implement it.
mixin ClientListener {
  /// Called when the [Client] could not decode a message.
  void badMessage(String trimmedLine, exception) {
    log('JSON decode failure', '$exception');
  }

  /// Called when the [Client] receives a line on stderr.
  void errorMessage(String line) {
    log('ERR:', line);
  }

  /// Called when the [Client] is terminating the server process
  /// rather than requesting that the server stop itself.
  void killingServerProcess(String reason) {
    log('FORCIBLY TERMINATING SERVER: ', reason);
  }

  /// Log a message about interaction with the server.
  void log(String prefix, String details);

  /// Called when the [Client] received a response or notification.
  void messageReceived(String json) {
    log('<== ', json);
  }

  /// Called when the [Client] sends a request.
  void requestSent(String json) {
    log('==> ', json);
  }

  /// Called when the [Client] starts the server process.
  void startingServer(String dartBinary, List<String> arguments) {
    log('Starting analysis server:', '$dartBinary ${arguments.join(' ')}');
  }

  /// Called when the [Client] receives an unexpected message
  /// which is not a notification or response.
  void unexpectedMessage(Map<String, dynamic> message) {
    log('Unexpected message from server:', '$message');
  }

  /// Called when the [Client] recieved an unexpected response
  /// where the [id] does not match the [id] of an outstanding request.
  void unexpectedResponse(Map<String, dynamic> message, id) {
    log('Unexpected response from server', 'id=$id');
  }

  /// Called when the server process unexpectedly exits
  /// with a non-zero exit code.
  void unexpectedStop(int exitCode) {
    log('Server terminated with exit code', '$exitCode');
  }
}
