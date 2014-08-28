// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [

(Isolate isolate) =>
  isolate.vm.get('_echo').then((result) {
    expect(result['type'], equals("message"));
    expect(result['id'], equals("_echo"));
    expect(result.owner, equals(isolate.vm));
}),

(Isolate isolate) =>
  isolate.get('_echo').then((result) {
    expect(result['type'], equals("message"));
    expect(result['id'], equals("_echo"));
    expect(result.owner, equals(isolate));
}),

(Isolate isolate) {
  Completer completer = new Completer();
  isolate.vm.events.stream.listen((ServiceEvent event) {
    if (event.eventType == '_Echo') {
      expect(event.data.lengthInBytes, equals(3));
      expect(event.data.getUint8(0), equals(0));
      expect(event.data.getUint8(1), equals(128));
      expect(event.data.getUint8(2), equals(255));
      completer.complete();
    }
  });
  isolate.get('_echo/event');
  return completer.future;
},

];

main(args) => runIsolateTests(args, tests);