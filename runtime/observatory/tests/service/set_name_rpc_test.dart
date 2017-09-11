// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --vm-name=Walter

import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';
import 'dart:async';

var tests = [
  (Isolate isolate) async {
    expect(isolate.name, equals('set_name_rpc_test.dart:main()'));

    Completer completer = new Completer();
    var stream = await isolate.vm.getEventStream(VM.kIsolateStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kIsolateUpdate) {
        expect(event.owner.type, equals('Isolate'));
        expect(event.owner.name, equals('Barbara'));
        subscription.cancel();
        completer.complete();
      }
    });

    var result = await isolate.setName('Barbara');
    expect(result.type, equals('Success'));

    await completer.future;
    expect(isolate.name, equals('Barbara'));
  }
];

main(args) async => runIsolateTests(args, tests);
