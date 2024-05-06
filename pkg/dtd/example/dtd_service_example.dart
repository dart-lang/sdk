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

  try {
    // Set up the services that will be used to show service method
    // interactions.
    clientA = await DartToolingDaemon.connect(Uri.parse(dtdUrl));
    clientB = await DartToolingDaemon.connect(Uri.parse(dtdUrl));

    // Register the ExampleServer.getServerState service method so that other
    // clients can call it.
    await clientA.registerService(
      'ExampleServer',
      'getServerState',
      (params) async {
        // This callback is what will be run when clients call
        // ExampleServer.getServerState.
        final getStateRequest = GetStateRequest.fromParams(params);

        final duration = const Duration(minutes: 45);
        final status =
            getStateRequest.verbose ? 'The server is running' : 'Running';

        return ExampleStateResponse(duration, status).toJson();
      },
    );

    // Call the registered service from a different client.
    final response = await clientB.getServerState(verbose: true);

    // The ExampleServerState response is now printed.
    print(jsonEncode(response.toJson()));
  } finally {
    await clientA?.close();
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
