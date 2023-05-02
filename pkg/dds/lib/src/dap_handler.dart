// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;

import '../dap.dart';
import 'dap/adapters/dds_hosted_adapter.dart';
import 'dap/constants.dart';
import 'dds_impl.dart';

/// Responds to incoming DAP messages using a debug adapter connected to DDS.
class DapHandler {
  DapHandler(this.dds);

  Future<Map<String, dynamic>> handle(
    DdsHostedAdapter adapter,
    json_rpc.Parameters parameters,
  ) async {
    if (adapter.ddsUri == null) {
      _startAdapter(adapter);
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
      'message': result.toJson(),
    };
  }

  Future<void> _startAdapter(DdsHostedAdapter adapter) async {
    adapter.ddsUri = dds.uri;

    // TODO(helin24): Most likely we'll want the client to do these
    // initialization steps so that clients can differentiate capabilities. This
    // may require a custom stream for the debug adapter.
    int seq = 1;
    // TODO(helin24): Add waiting for `InitializedEvent`.
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
  }

  final DartDevelopmentServiceImpl dds;
}

void noopCallback() {}
