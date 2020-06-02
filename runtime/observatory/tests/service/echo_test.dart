// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

var tests = <IsolateTest>[
  (Isolate isolate) =>
      isolate.vm.invokeRpcNoUpgrade('_echo', {'text': 'hello'}).then((result) {
        expect(result['type'], equals('_EchoResponse'));
        expect(result['text'], equals('hello'));
      }),
  (Isolate isolate) =>
      isolate.invokeRpcNoUpgrade('_echo', {'text': 'hello'}).then((result) {
        expect(result['type'], equals('_EchoResponse'));
        expect(result['text'], equals('hello'));
      }),
  (Isolate isolate) async {
    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream('_Echo');
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      assert(event.kind == '_Echo');
      expect(event.data!.lengthInBytes, equals(3));
      expect(event.data![0], equals(0));
      expect(event.data![1], equals(128));
      expect(event.data![2], equals(255));
      subscription.cancel();
      completer.complete();
    });

    await isolate.invokeRpc('_triggerEchoEvent', {'text': 'hello'});
    await completer.future;
  },
];

main(args) => runIsolateTests(args, tests);
