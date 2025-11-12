// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart' show jsonRpcVersion;
import 'package:analysis_server/src/server/driver.dart';

import 'log_entry.dart';

/// The driver used to communicate with the analysis server.
class ServerDriver {
  /// The protocol being used by the server.
  final ServerProtocol _protocol;

  /// A list of additional arguments from the comman-line used to start the
  /// server.
  final List<String> additionalArguments = [];

  /// The sink used to send messages from the IDE to the server's stdin, or
  /// `null` if the server has not been started using [start].
  IOSink? _stdinSink;

  /// The socket used to send messages from DTD to the server, or `null` if the
  /// server has not been connected to DTD using [connectToDtd].
  WebSocket? _dtdSocket;

  /// The messages read from the analysis server's stdout.
  final List<String> _messagesFromServer = [];

  /// Creates a new driver that can be used to communicate with a server.
  ///
  /// When the server is [start]ed, it will use the given [protocol].
  ///
  /// The server is run in a separate process.
  // TODO(brianwilkerson): Add a flag controlling whether the server is in the
  //  same process as the driver or in a separate process.
  ServerDriver({required ServerProtocol protocol}) : _protocol = protocol;

  /// Returns the list of additional arguments that were passes on the command
  /// line when the server was started that should be passed to the server
  /// created by this driver.
  List<String> get filteredAdditionalArguments {
    var arguments = <String>[];
    var nextIndex = 0;
    while (nextIndex < additionalArguments.length) {
      var nextArgument = additionalArguments[nextIndex];
      if (nextArgument == Driver.withFineDependenciesOption) {
        arguments.add(nextArgument);
      }
      nextIndex++;
    }
    return arguments;
  }

  /// Returns the path to the `dart` executable.
  String get _dartExecutable {
    return Platform.resolvedExecutable;
  }

  /// Create a websocket through which DTD messages can be sent to the server
  /// and send a request to the server asking it to connect to the socket.
  // ignore: unnecessary_async
  Future<void> connectToDtd() async {
    // TODO(brianwilkerson): Implement this.
    throw UnimplementedError();
    // var socketUri = 'ws://';
    // _dtdSocket = await WebSocket.connect(socketUri);
  }

  /// Send an exit request to the server, then close the communication channels
  /// used to communicate with the server.
  void exit() {
    if (_protocol == ServerProtocol.lsp) {
      sendMessageFromIde(
        Message({
          'id': 0,
          'method': 'exit',
          'jsonrpc': jsonRpcVersion,
          'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    }
    _stdinSink?.close();
    _dtdSocket?.close();
  }

  void sendMessageFromDTD(Message message) {
    if (_dtdSocket case var socket?) {
      socket.add(json.encode(message));
    } else {
      throw StateError(
        "The method 'connectToDtd' must be invoked before "
        'messages can be sent from DTD.',
      );
    }
  }

  void sendMessageFromFileWatcher(Message message) {
    // TODO(brianwilkerson): Implementing this will require some additional
    //  support in the server. The most likely approach is to add support for a
    //  new protocol that will fake receiving a watch event.
  }

  /// Send the given [message] to the server using the communication channel
  /// used by the IDE.
  void sendMessageFromIde(Message message) {
    if (_stdinSink case IOSink writeSink) {
      writeSink.writeln(json.encode(message));
    } else {
      throw StateError(
        "The method 'start' must be invoked before "
        'messages can be sent from the IDE.',
      );
    }
  }

  void sendMessageFromPluginIsolate(Message message) {
    // TODO(brianwilkerson): Implementing this will require some additional
    //  support in the server. Two possibilities to consider:
    //  1. Add a protocol to fake receiving a messsage from the plugin isolate.
    //  2. Add a protocol to connect to a web socket as if it were a connection
    //     to a plugin isolate.
    //  The first is likely to be the easier path forward.
  }

  /// Send a shutdown request to the server.
  void shutdown() {
    if (_protocol == ServerProtocol.legacy) {
      sendMessageFromIde(
        Message({
          'id': 0,
          'method': 'server.shutdown',
          'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    } else if (_protocol == ServerProtocol.lsp) {
      sendMessageFromIde(
        Message({
          'id': 0,
          'method': 'shutdown',
          'jsonrpc': jsonRpcVersion,
          'clientRequestTime': DateTime.now().millisecondsSinceEpoch,
        }),
      );
    }
  }

  /// Create and start the server.
  Future<void> start() async {
    var process = await Process.start(_dartExecutable, [
      'language-server',
      '--protocol=${_protocol.flagValue}',
      '--suppress-analytics',
      ...filteredAdditionalArguments,
    ]);
    _stdinSink = process.stdin;
    process.stdout
        .transform(const Utf8Decoder())
        .transform(const LineSplitter())
        .listen(_receiveMessageFromServer);
  }

  void _receiveMessageFromServer(String message) {
    _messagesFromServer.add(message);
  }
}

/// An indication of the protocol to be used when communicating with the server.
enum ServerProtocol {
  legacy('analyzer'),
  lsp('lsp');

  final String flagValue;
  const ServerProtocol(this.flagValue);
}
