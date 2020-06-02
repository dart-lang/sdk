// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library set_library_debuggable_rpc_test;

import 'package:observatory/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) async {
    var result;

    // debuggable defaults to true.
    var getObjectParams = {
      'objectId': isolate.rootLibrary.id,
    };
    result = await isolate.invokeRpcNoUpgrade('getObject', getObjectParams);
    expect(result['debuggable'], equals(true));

    // Change debuggable to false.
    var setDebugParams = {
      'libraryId': isolate.rootLibrary.id,
      'isDebuggable': false,
    };
    result = await isolate.invokeRpcNoUpgrade(
        'setLibraryDebuggable', setDebugParams);
    expect(result['type'], equals('Success'));

    // Verify.
    result = await isolate.invokeRpcNoUpgrade('getObject', getObjectParams);
    expect(result['debuggable'], equals(false));
  },

  // invalid library.
  (Isolate isolate) async {
    var params = {
      'libraryId': 'libraries/9999999',
      'isDebuggable': false,
    };
    bool caughtException = false;
    try {
      await isolate.invokeRpcNoUpgrade('setLibraryDebuggable', params);
      expect(false, isTrue, reason: 'Unreachable');
    } on ServerRpcException catch (e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(
          e.message,
          "setLibraryDebuggable: "
          "invalid 'libraryId' parameter: libraries/9999999");
    }
    expect(caughtException, isTrue);
  },
];

main(args) async => runIsolateTests(args, tests);
