// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A helper library to connect to an existing VM and trigger a hot-reload via
/// its service protocol.
///
/// Usage:
///
/// ```
///     var remoteVm = new RemoteVm();
///     await remoteVm.reload(uriToEntryScript);
///     ...
///     await remoteVm.disconnect();
/// ```
library front_end.src.vm.reload;

import 'dart:async';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/io.dart';

/// APIs to communicate with a remote VM via the VM's service protocol.
///
/// Only supports APIs to resume the program execution (when isolates are paused
/// at startup) and to trigger hot reloads.
class RemoteVm {
  /// Port used to connect to the vm service protocol, typically 8181.
  final int port;

  /// An peer point used to send service protocol messages. The service
  /// protocol uses JSON rpc on top of web-sockets.
  json_rpc.Peer get rpc => _rpc ??= _createPeer();
  json_rpc.Peer _rpc;

  /// The main isolate ID of the running VM. Needed to indicate to the VM which
  /// isolate to reload.
  FutureOr<String> get mainId async => _mainId ??= await _computeMainId();
  String _mainId;

  RemoteVm([this.port = 8181]);

  /// Establishes the JSON rpc connection.
  json_rpc.Peer _createPeer() {
    StreamChannel socket =
        new IOWebSocketChannel.connect('ws://127.0.0.1:$port/ws');
    var peer = new json_rpc.Peer(socket);
    peer.listen().then((_) {
      if (VERBOSE_DEBUG) print('connection to vm-service closed');
      return disconnect();
    }).catchError((e) {
      if (VERBOSE_DEBUG) print('error connecting to the vm-service');
      return disconnect();
    });
    return peer;
  }

  /// Retrieves the ID of the main isolate using the service protocol.
  Future<String> _computeMainId() async {
    var vm = await rpc.sendRequest('getVM');
    var isolates = vm['isolates'];
    for (var isolate in isolates) {
      if (isolate['name'].contains(r'$main')) {
        return isolate['id'];
      }
    }
    return isolates.first['id'];
  }

  /// Send a request to the VM to reload sources from [entryUri].
  ///
  /// This will establish a connection with the VM assuming it is running on the
  /// local machine and listening on [port] for service protocol requests.
  ///
  /// The result is the JSON map received from the reload request.
  Future<Map> reload(Uri entryUri) async {
    var id = await mainId;
    var result = await rpc.sendRequest('reloadSources', {
      'isolateId': id,
      'rootLibUri': entryUri.path,
    });
    return result;
  }

  Future resume() async {
    var id = await mainId;
    await rpc.sendRequest('resume', {'isolateId': id});
  }

  /// Close any connections used to communicate with the VM.
  Future disconnect() async {
    if (_rpc == null) return null;
    this._mainId = null;
    if (!_rpc.isClosed) {
      var future = _rpc.close();
      _rpc = null;
      return future;
    }
    return null;
  }
}

const VERBOSE_DEBUG = false;

/// This library can be used as a script as well. It connects to an existing
/// VM's service protocol and issues a hot-reload request. The VM must have been
/// launched with `--observe` to enable the service protocol.
///
// TODO(sigmund): provide flags to configure the vm-service port.
main(List<String> args) async {
  if (args.length == 0) {
    print('usage: reload <entry-uri>');
    return;
  }

  var remoteVm = new RemoteVm();
  await remoteVm.reload(Uri.base.resolve(args.first));
  await remoteVm.disconnect();
}
