// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:dds_service_extensions/dap.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../dap.dart';
import 'dap/adapters/dds_hosted_adapter.dart';
import 'dap/constants.dart';
import 'dds_impl.dart';

/// Responds to incoming DAP messages using a debug adapter connected to DDS.
class DapHandler {
  DapHandler(this.dds);

  final _initializedCompleter = Completer<void>();

  Future<Map<String, dynamic>> sendRequest(
    DdsHostedAdapter adapter,
    json_rpc.Parameters parameters,
  ) async {
    if (adapter.ddsUri == null) {
      await _startAdapter(adapter);
    }

    // TODO(helin24): Consider a sequence offset for incoming messages to avoid
    // overlapping sequence numbers with startup requests.
    final message = parameters['message'].asString;

    // TODO(dantup): If/when DAP needs to care about ordering (eg. it handles
    //  both requests and events), this will need to be changed to have the
    //  caller provide a "responseWriter" function so the the result can be
    //  written directly to the stream synchronously, to avoid future events
    //  being able to be inserted before the response (eg. initializedEvent).
    final responseCompleter = Completer<Response>();
    adapter.handleMessage(message, responseCompleter.complete);
    final result = await responseCompleter.future;

    return <String, dynamic>{
      'type': 'DapResponse',
      'dapResponse': result,
    };
  }

  _handleEvent(Event event) {
    if (event.event == 'initialized') {
      _initializedCompleter.complete();
    }
    dds.streamManager.streamNotify(DapEventStreams.kDAP, {
      'streamId': DapEventStreams.kDAP,
      'event': {
        'kind': DapEventKind.kDAPEvent,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'dapData': event,
      },
    });
  }

  Future<void> _startAdapter(DdsHostedAdapter adapter) async {
    adapter.ddsUri = dds.uri;
    adapter.setEventHandler(_handleEvent);

    // TODO(helin24): Most likely we'll want the client to do these
    // initialization steps so that clients can differentiate capabilities. This
    // may require a custom stream for the debug adapter.

    // Each DAP request has a `seq` number (essentially a message ID) which
    // should be unique.
    //
    // We send a few requsets to initialize the adapter, but these are not
    // visible to the DDS client so if we start at 1, the IDs will be
    // reused.
    //
    // To avoid that, for our own initialization requests, use negative numbers
    // (though they must still ascend) so there's no overlay with the messages
    // we'll forward from the DDS client.
    int seq = -1000;
    await adapter.initializeRequest(
      Request(
        command: Command.initialize,
        seq: seq,
      ),
      InitializeRequestArguments(
        adapterID: 'dds-dap-handler',
      ),
      (capabilities) {},
    );
    await _initializedCompleter.future;
    await adapter.configurationDoneRequest(
      Request(
        arguments: const {},
        command: Command.configurationDone,
        seq: seq++,
      ),
      ConfigurationDoneArguments(),
      noopCallback,
    );
    await adapter.attachRequest(
      Request(
        arguments: const {},
        command: Command.attach,
        seq: seq++,
      ),
      DartAttachRequestArguments(
        vmServiceUri: dds.remoteVmServiceUri.toString(),
      ),
      noopCallback,
    );
    // Wait for the debugger to fully initialize, because the request that
    // triggered this initialization may require things like isolates that will
    // only be known after the debugger has initialized.
    await adapter.debuggerInitialized;
  }

  final DartDevelopmentServiceImpl dds;
}

void noopCallback() {}
