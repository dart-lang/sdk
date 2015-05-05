// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--compile-all --error_on_bad_type --error_on_bad_override

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [
  (Isolate isolate) async {
    await isolate.invokeRpc('_respondWithMalformedObject', {}).then((result) {
      expect(false, isTrue, reason:'Unreachable');
    }).catchError((ServiceException exception) {
      expect(exception.kind, equals('ResponseFormatException'));
      expect(exception.message,
             startsWith("Response is missing the 'type' field"));
    });
  },

  // Do this test last... it kills the vm connection.
  (Isolate isolate) async {
    await isolate.invokeRpc('_respondWithMalformedJson', {}).then((result) {
      expect(false, isTrue, reason:'Unreachable');
    }).catchError((ServiceException exception) {
      expect(exception.kind, equals('ConnectionClosed'));
      expect(exception.message, startsWith('Error decoding JSON message'));
    });
  },
];

main(args) => runIsolateTests(args, tests);
