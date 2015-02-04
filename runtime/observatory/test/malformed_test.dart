// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [

(Isolate isolate) =>
  isolate.invokeRpc('_respondWithMalformedJson', { }).then((result) {
    // Should not execute.
    expect(true, false);
  }).catchError((ServiceException exception) {
    expect(exception.kind, equals('JSONDecodeException'));
  }),

(Isolate isolate) =>
  isolate.invokeRpc('_respondWithMalformedObject', { }).then((result) {
    // Should not execute.
    expect(true, false);
  }).catchError((ServiceException exception) {
    expect(exception.kind, equals('ResponseFormatException'));
  }),
];

main(args) => runIsolateTests(args, tests);