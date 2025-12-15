// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/session_logger/entry_keys.dart' as key;
import 'package:analysis_server/src/session_logger/entry_kind.dart';
import 'package:analysis_server/src/session_logger/process_id.dart';

/// A representation of an entry in a [Log].
///
/// Every entry has a [time] and a [kind]. Other properties are dependent on the
/// [kind]. See [EntryKind] for a description of the properties associated with
/// each [kind].
extension type LogEntry(JsonMap map) {
  /// Returns the command-line arguments used to start the server.
  List<String> get argList =>
      (map[key.argList] as List<dynamic>).cast<String>();

  /// Whether this entry is a command line entry.
  bool get isCommandLine => kind == EntryKind.commandLine;

  /// Whether this entry is a message entry.
  bool get isMessage => kind == EntryKind.message;

  /// Returns the kind of this log entry.
  EntryKind get kind => EntryKind.forName(map[key.kind] as String);

  /// Returns the message for this log entry.
  Message get message => Message(map[key.message] as JsonMap);

  /// Returns the receiver of the message.
  ProcessId get receiver => ProcessId.forName(map[key.receiver] as String);

  /// Returns the sender of the message.
  ProcessId get sender => ProcessId.forName(map[key.sender] as String);
}

/// A representation of a message sent from one process to another.
extension type Message(JsonMap map) {
  /// The ID of the message. All messages have IDs.
  int get id => map['id'] as int;

  /// Whether this message is a request for the server to exit.
  bool get isExit => method == 'exit';

  /// Whether this message is a request for the server to initialize itself.
  bool get isInitialize => method == 'initialize';

  /// Whether this message is a notification to the server indicating that the
  /// client is initialized.
  bool get isInitialized => method == 'initialized';

  /// Whether this message is a request from the server to log a message.
  bool get isLogMessage => method == 'window/logMessage';

  /// Whether this message is a request for the server to connect with DTD.
  bool get isRequestToConnectWithDtd => method == 'dart/connectToDtd';

  /// Whether this is a response to a request.
  bool get isResponse => method == null;

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

  /// Only present if [method] is non-null, and still optional in that case.
  JsonMap? get params => map['params'] as Map<String, Object?>?;

  /// If [method] is null, this should be non-null.
  ///
  /// Could be any valid type for a result, which is dependent on the [method].
  Object? get result => map['result'];
}
