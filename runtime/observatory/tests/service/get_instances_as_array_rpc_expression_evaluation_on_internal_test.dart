// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:observatory/service_io.dart";

import "test_helper.dart";

bool gotError = false;

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Future<void> getInstancesAndExecuteExpression(Map member) async {
      final Map params = {
        "objectId": member["class"]["id"],
        "includeSubclasses": false,
        "includeImplementors": false,
      };
      final result = await isolate.invokeRpc("_getInstancesAsArray", params);
      // This has previously caused an exception like
      // "ServerRpcException(evaluate: Unexpected exception:
      // FormatException: Unexpected character (at offset 329)"
      final evalResult = await isolate.eval(result, "this");
      if (evalResult.isError) {
        gotError = true;
        final DartError error = evalResult as DartError;
        if (error.message
                ?.contains("Cannot evaluate against a VM-internal object") !=
            true) {
          throw "Got error $error but expected another message.";
        }
      }
    }

    final params = {};
    final result =
        await isolate.invokeRpcNoUpgrade('_getAllocationProfile', params);
    final List members = result['members'];
    for (var member in members) {
      final name = member["class"]["name"];
      if (name == "Library") {
        await getInstancesAndExecuteExpression(member);
      }
    }
    if (!gotError) {
      throw "Didn't get expected error!";
    }
  },
];

main(args) async => runIsolateTests(args, tests);
