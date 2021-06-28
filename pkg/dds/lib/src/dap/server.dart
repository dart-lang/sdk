// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dds/src/dap/adapters/dart.dart';
import 'package:pedantic/pedantic.dart';

import 'adapters/dart_cli.dart';
import 'logging.dart';
import 'protocol_stream.dart';
import 'protocol_stream_transformers.dart';

/// A DAP server that binds to a port and runs in multi-session mode.
class DapServer {
  final ServerSocket _socket;
  final bool enableDds;
  final bool enableAuthCodes;
  final Logger? logger;
  final _channels = <ByteStreamServerChannel>{};
  final _adapters = <DartDebugAdapter>{};

  DapServer._(
    this._socket, {
    this.enableDds = true,
    this.enableAuthCodes = true,
    this.logger,
  }) {
    _socket.listen(_acceptConnection);
  }

  String get host => _socket.address.host;
  int get port => _socket.port;

  Future<void> stop() async {
    _channels.forEach((client) => client.close());
    await _socket.close();
  }

  void _acceptConnection(Socket client) {
    final address = client.remoteAddress;
    logger?.call('Accepted connection from $address');
    client.done.then((_) {
      logger?.call('Connection from $address closed');
    });
    _createAdapter(client.transform(Uint8ListTransformer()), client);
  }

  void _createAdapter(Stream<List<int>> _input, StreamSink<List<int>> _output) {
    // TODO(dantup): This is hard-coded to DartCliDebugAdapter but will
    //   ultimately need to support having a factory passed in to support
    //   tests and/or being used in flutter_tools.
    final channel = ByteStreamServerChannel(_input, _output, logger);
    final adapter = DartCliDebugAdapter(
      channel,
      enableDds: enableDds,
      enableAuthCodes: enableAuthCodes,
      logger: logger,
    );
    _channels.add(channel);
    _adapters.add(adapter);
    unawaited(channel.closed.then((_) {
      _channels.remove(channel);
      _adapters.remove(adapter);
      adapter.shutdown();
    }));
  }

  /// Starts a DAP Server listening on [host]:[port].
  static Future<DapServer> create({
    String host = 'localhost',
    int port = 0,
    bool enableDdds = true,
    bool enableAuthCodes = true,
    Logger? logger,
  }) async {
    final _socket = await ServerSocket.bind(host, port);
    return DapServer._(
      _socket,
      enableDds: enableDdds,
      enableAuthCodes: enableAuthCodes,
      logger: logger,
    );
  }
}
