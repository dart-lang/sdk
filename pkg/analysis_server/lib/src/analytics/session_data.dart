// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Data about the current session.
class SessionData {
  /// The time at which the current session started.
  final DateTime startTime;

  /// The command-line arguments passed to the server on startup.
  final String commandLineArguments;

  /// The parameters passed on initialize.
  String initializeParams = '';

  /// The name of the client that started the server.
  final String clientId;

  /// The version of the client that started the server, or an empty string if
  /// no version information was provided.
  final String clientVersion;

  /// Initialize a newly created data holder.
  SessionData({
    required this.startTime,
    required this.commandLineArguments,
    required this.clientId,
    required this.clientVersion,
  });
}
