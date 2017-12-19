// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) =>
      isolate.vm.invokeRpc('_echo', {'text': 'hello'}).then((result) {
        expect(result['type'], equals('_EchoResponse'));
        expect(result['text'], equals('hello'));
      }),
  (Isolate isolate) =>
      isolate.invokeRpc('_echo', {'text': 'hello'}).then((result) {
        expect(result['type'], equals('_EchoResponse'));
        expect(result['text'], equals('hello'));
      }),
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream('_Echo');
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      assert(event.kind == '_Echo');
      expect(event.data.lengthInBytes, equals(3));
      expect(event.data.getUint8(0), equals(0));
      expect(event.data.getUint8(1), equals(128));
      expect(event.data.getUint8(2), equals(255));
      subscription.cancel();
      completer.complete();
    });

    await isolate.invokeRpc('_triggerEchoEvent', {'text': 'hello'});
    await completer.future;
  },
];

main(args) => runIsolateTests(args, tests);
