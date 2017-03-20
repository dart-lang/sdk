// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override --vm-name=Walter

import 'dart:async';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [
  (VM vm) async {
    expect(vm.name, equals('Walter'));

    Completer completer = new Completer();
    var stream = await vm.getEventStream(VM.kVMStream);
    var subscription;
    subscription = stream.listen((ServiceEvent event) {
      if (event.kind == ServiceEvent.kVMUpdate) {
        expect(event.owner.type, equals('VM'));
        expect(event.owner.name, equals('Barbara'));
        subscription.cancel();
        completer.complete();
      }
    });
    
    var result = await vm.setName('Barbara');
    expect(result.type, equals('Success'));

    await completer.future;
    expect(vm.name, equals('Barbara'));
  },
];

main(args) async => runVMTests(args, tests,
                               extraArgs: [ '--trace-service',
                                            '--trace-service-verbose' ]);
