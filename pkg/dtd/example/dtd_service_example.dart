// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';

/// To run this example pass the DTD uri as a parameter:
///
/// Example:
/// ```sh
/// dart run dtd_service_example.dart ws://127.0.0.1:62925/cKB5QFiAUNMzSzlb
/// ```
void main(List<String> args) async {
  final dtdUrl = args[0]; // pass the url as a param to the example

  DartToolingDaemon? clientA;
  DartToolingDaemon? clientB;

  final serviceRegisteredCompleted = Completer<void>();
  final serviceUnregisteredCompleted = Completer<void>();

  try {
    // Set up the services that will be used to show service method
    // interactions.
    clientA = await DartToolingDaemon.connect(Uri.parse(dtdUrl));
    clientB = await DartToolingDaemon.connect(Uri.parse(dtdUrl));

    // Monitor events that come to the second client over the Service
    // stream.
    clientB.onEvent('Service').listen((e) {
      switch (e.kind) {
        case 'ServiceRegistered':
          if (e.data['service'] == 'ExampleServer') {
            serviceRegisteredCompleted.complete();
          }
        case 'ServiceUnregistered':
          if (e.data['service'] == 'ExampleServer') {
            serviceUnregisteredCompleted.complete();
          }
      }
      print(jsonEncode({'stream': e.stream, 'kind': e.kind, 'data': e.data}));
    });
    await clientB.streamListen('Service');

    // Register the ExampleServer.getServerState service method on the first
    // client so that other other clients can call it.
    await clientA.registerService(
      'ExampleServer',
      'getServerState',
      (params) async {
        // This callback is what will be run when clients call
        // ExampleServer.getServerState.
        final getStateRequest = GetStateRequest.fromParams(params);

        const duration = Duration(minutes: 45);
        final status =
            getStateRequest.verbose ? 'The server is running' : 'Running';

        return ExampleStateResponse(duration, status).toJson();
      },
      capabilities: {
        'supportsNewExamples': true,
      },
    );

    await serviceRegisteredCompleted.future;

    // Call the registered service from a different client.
    final response = await clientB.getServerState(verbose: true);

    // The ExampleServerState response is now printed.
    print(jsonEncode(response.toJson()));
  } finally {
    // Close the first client and wait for the unregistered event before closing
    // the second client.
    await clientA?.close();
    await serviceUnregisteredCompleted.future;
    await clientB?.close();
  }
}

/// A helper class used to simplify passing and receiving json parameters to
/// ExampleServer.getServerState.
class GetStateRequest {
  final bool verbose;
  static const String _kVerbose = 'verbose';
  GetStateRequest(this.verbose);
  factory GetStateRequest.fromParams(Parameters parameters) {
    return GetStateRequest(parameters[_kVerbose].asBool);
  }

  Map<String, Object> toJson() => <String, Object>{
        _kVerbose: verbose,
      };
}

/// A helper class used to simplify passing and receiving json results in the
/// ExampleServer.getServerState response.
class ExampleStateResponse {
  late Duration uptime;
  late String status;

  static String get type => 'ExampleStateResponse';

  static const String _kUptime = 'uptime';
  static const String _kStatus = 'status';

  ExampleStateResponse(this.uptime, this.status);

  ExampleStateResponse._fromDTDResponse(DTDResponse response)
      : uptime = Duration(
          milliseconds: response.result[_kUptime] as int,
        ),
        status = response.result[_kStatus] as String;

  factory ExampleStateResponse.fromDTDResponse(DTDResponse response) {
    // Ensure that the response has the type you expect.
    if (response.type != type) {
      throw RpcException.invalidParams(
        'Expected DTDResponse.type to be $type, got: ${response.type}',
      );
    }
    return ExampleStateResponse._fromDTDResponse(response);
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'type': type,
        _kStatus: status,
        _kUptime: uptime.inMilliseconds,
      };

  @override
  String toString() {
    return '$type(status:$status, uptime:$uptime)';
  }
}

/// Adds the [getServerState] method to [DartToolingDaemon], so that calling the
/// ExampleServer.getServerState service method can be wrapped nicely behind a
/// method call from a given client.
extension ExampleExtension on DartToolingDaemon {
  Future<ExampleStateResponse> getServerState({bool verbose = false}) async {
    final result = await call(
      'ExampleServer',
      'getServerState',
      params: GetStateRequest(verbose).toJson(),
    );
    return ExampleStateResponse.fromDTDResponse(result);
  }
}
