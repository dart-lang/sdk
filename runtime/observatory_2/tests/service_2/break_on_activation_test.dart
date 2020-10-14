// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';

genRepeater(value) {
  return () => print(value);
}

genRepeaterNamed(value) {
  return ({x, y}) => print(value);
}

var r1;
var r2;
var r3;

var r1_named;
var r2_named;
var r3_named;

void testeeSetup() {
  // These closures have the same function.
  r1 = genRepeater('r1');
  r2 = genRepeater('r2');
  r3 = genRepeater('r3');

  // These closures have the same function.
  r1_named = genRepeaterNamed('r1_named');
  r2_named = genRepeaterNamed('r2_named');
  r3_named = genRepeaterNamed('r3_named');
}

void testeeDo() {
  r1();
  r2();
  r3();
}

void testeeDoNamed() {
  r1_named(y: 'Not a closure', x: 'Not a closure');
  r2_named(y: 'Not a closure', x: 'Not a closure');
  r3_named(y: 'Not a closure', x: 'Not a closure');
}

var tests = <IsolateTest>[
  (Isolate isolate) async {
    Library rootLib = await isolate.rootLibrary.load();

    var breaksHit = 0;

    var subscriptionFuture =
        isolate.vm.listenEventStream(VM.kDebugStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print("Hit breakpoint ${event.breakpoint}");
        breaksHit++;
        isolate.resume();
      }
    });

    valueOfField(String name) async {
      var field = rootLib.variables.singleWhere((v) => v.name == name);
      await field.load();
      return field.staticValue as Instance;
    }

    var r1Ref = await valueOfField('r1');

    var bpt1 = await isolate.addBreakOnActivation(r1Ref);
    print("Added breakpoint $bpt1");
    expect(bpt1 is Breakpoint, isTrue);
    expect(breaksHit, equals(0));
    await r1Ref.reload();
    expect(r1Ref.activationBreakpoint, equals(bpt1));
    print("testeeDo()");
    var res = await rootLib.evaluate("testeeDo()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(1));

    await isolate.removeBreakpoint(bpt1);
    print("Removed breakpoint $bpt1");
    print("testeeDo()");
    await r1Ref.reload();
    expect(r1Ref.activationBreakpoint, equals(null));
    res = await rootLib.evaluate("testeeDo()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(1));

    await cancelFutureSubscription(subscriptionFuture);
  },
  (Isolate isolate) async {
    Library rootLib = await isolate.rootLibrary.load();

    var breaksHit = 0;

    var subscriptionFuture =
        isolate.vm.listenEventStream(VM.kDebugStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print("Hit breakpoint ${event.breakpoint}");
        breaksHit++;
        isolate.resume();
      }
    });

    valueOfField(String name) async {
      var field = rootLib.variables.singleWhere((v) => v.name == name);
      await field.load();
      return field.staticValue as Instance;
    }

    var r1Ref = await valueOfField('r1_named');

    var bpt1 = await isolate.addBreakOnActivation(r1Ref);
    print("Added breakpoint $bpt1");
    expect(bpt1 is Breakpoint, isTrue);
    expect(breaksHit, equals(0));
    await r1Ref.reload();
    expect(r1Ref.activationBreakpoint, equals(bpt1));
    print("testeeDoNamed()");
    var res = await rootLib.evaluate("testeeDoNamed()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(1));

    await isolate.removeBreakpoint(bpt1);
    print("Removed breakpoint $bpt1");
    await r1Ref.reload();
    expect(r1Ref.activationBreakpoint, equals(null));
    print("testeeDoNamed()");
    res = await rootLib.evaluate("testeeDoNamed()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(1));

    await cancelFutureSubscription(subscriptionFuture);
  },
  (Isolate isolate) async {
    Library rootLib = await isolate.rootLibrary.load();

    var breaksHit = 0;

    var subscriptionFuture =
        isolate.vm.listenEventStream(VM.kDebugStream, (ServiceEvent event) {
      if (event.kind == ServiceEvent.kPauseBreakpoint) {
        print("Hit breakpoint ${event.breakpoint}");
        breaksHit++;
        isolate.resume();
      }
    });

    valueOfField(String name) async {
      var field = rootLib.variables.singleWhere((v) => v.name == name);
      await field.load();
      return field.staticValue as Instance;
    }

    var r1Ref = await valueOfField('r1');
    var r2Ref = await valueOfField('r2');

    var bpt1 = await isolate.addBreakOnActivation(r1Ref);
    print("Added breakpoint $bpt1");
    expect(bpt1 is Breakpoint, isTrue);
    expect(breaksHit, equals(0));
    await r1Ref.reload();
    expect(r1Ref.activationBreakpoint, equals(bpt1));
    print("testeeDo()");
    var res = await rootLib.evaluate("testeeDo()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(1));

    var bpt2 = await isolate.addBreakOnActivation(r2Ref);
    print("Added breakpoint $bpt2");
    expect(bpt2 is Breakpoint, isTrue);
    expect(breaksHit, equals(1));
    await r2Ref.reload();
    expect(r2Ref.activationBreakpoint, equals(bpt2));
    print("testeeDo()");
    res = await rootLib.evaluate("testeeDo()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(3));

    await isolate.removeBreakpoint(bpt1);
    print("Removed breakpoint $bpt1");
    await r1Ref.reload();
    expect(r1Ref.activationBreakpoint, equals(null));
    print("testeeDo()");
    res = await rootLib.evaluate("testeeDo()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(4));

    await isolate.removeBreakpoint(bpt2);
    print("Removed breakpoint $bpt2");
    await r2Ref.reload();
    expect(r2Ref.activationBreakpoint, equals(null));
    print("testeeDo()");
    res = await rootLib.evaluate("testeeDo()");
    expect(res is Instance, isTrue); // Not error.
    expect(breaksHit, equals(4));

    await cancelFutureSubscription(subscriptionFuture);
  },
];

main(args) => runIsolateTests(args, tests, testeeBefore: testeeSetup);
