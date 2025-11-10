// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'log.dart';
library;

import 'package:analysis_server/src/session_logger/process_id.dart';

/// A representation of an entry in a [Log].
extension type LogEntry(JsonMap map) {
  /// The key used in the [map] to access the message associatd with the entry.
  static const String messageKey = 'message';

  /// The key used in the [map] to access the receiver of a message.
  static const String receiverKey = 'receiver';

  /// The key used in the [map] to access the sender of a message.
  static const String senderKey = 'sender';

  /// Returns the message for this log entry.
  Message get message => Message(map[messageKey] as JsonMap);

  /// Returns the receiver of the message.
  ProcessId get receiver => ProcessId.forName(map[receiverKey] as String);

  /// Returns the sender of the message.
  ProcessId get sender => ProcessId.forName(map[senderKey] as String);
}

/// A representation of a message sent from one process to another.
extension type Message(JsonMap map) {
  /// Whether this message is a request for the server to exit.
  bool get isExit => method == 'exit';

  /// Whether this message is a request from the server to log a message.
  bool get isLogMessage => method == 'window/logMessage';

  /// Whether this message is a request for the server to connect with DTD.
  bool get isRequestToConnectWithDtd => method == 'dart/connectToDtd';

  /// Whether this message is a request from the server to show a document to
  /// the user.
  bool get isShowDocument => method == 'window/showDocument';

  /// Whether this message is a request from the server to show a message to the
  /// user.
  bool get isShowMessage => method == 'window/showMessage';

  /// Whether this message is a request from the server to show a message to the
  /// user.
  bool get isShowMessageRequest => method == 'window/showMessageRequest';

  /// Whether this message is a request for the server to shut down.
  bool get isShutdown => method == 'shutdown';

  /// The method being sent in this message, or `null` if this message isn't an
  /// LSP request
  String? get method => map['method'] as String?;
}
