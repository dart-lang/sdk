// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that expressions evaluated in a frame see the same scope as the
// frame's method.

import 'dart:async';
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';
import 'test_helper.dart';
import 'service_test_common.dart';

import 'evaluate_activation_in_method_class_other.dart';

var topLevel = "TestLibrary";

class Subclass extends Superclass1 {
  var _instVar = 'Subclass';
  var instVar = 'Subclass';
  method() => 'Subclass';
  static staticMethod() => 'Subclass';
  suppress_warning() => _instVar;
}

testeeDo() {
  var obj = new Subclass();
  obj.test();
}

Future testerDo(Isolate isolate) async {
  await hasStoppedAtBreakpoint(isolate);

  // Make sure we are in the right place.
  var stack = await isolate.getStack();
  var topFrame = 0;
  expect(stack.type, equals('Stack'));
  expect(stack['frames'][topFrame].function.name, equals('test'));
  expect(
      stack['frames'][topFrame].function.dartOwner.name, equals('Superclass1'));

  Instance result;

  result = await isolate.evalFrame(topFrame, '_local');
  print(result);
  expect(result.valueAsString, equals('Superclass1'));

  result = await isolate.evalFrame(topFrame, '_instVar');
  print(result);
  expect(result.valueAsString, equals('Superclass1'));

  result = await isolate.evalFrame(topFrame, 'instVar');
  print(result);
  expect(result.valueAsString, equals('Subclass'));

  result = await isolate.evalFrame(topFrame, 'method()');
  print(result);
  expect(result.valueAsString, equals('Subclass'));

  result = await isolate.evalFrame(topFrame, 'super._instVar');
  print(result);
  expect(result.valueAsString, equals('Superclass2'));

  result = await isolate.evalFrame(topFrame, 'super.instVar');
  print(result);
  expect(result.valueAsString, equals('Superclass2'));

  result = await isolate.evalFrame(topFrame, 'super.method()');
  print(result);
  expect(result.valueAsString, equals('Superclass2'));

  result = await isolate.evalFrame(topFrame, 'staticMethod()');
  print(result);
  expect(result.valueAsString, equals('Superclass1'));

  // function.Owner verus function.Origin
  // The mixin of Superclass is in _other.dart and the mixin
  // application is in _test.dart.
  result = await isolate.evalFrame(topFrame, 'topLevel');
  print(result);
  expect(result.valueAsString, equals('OtherLibrary'));
}

main(args) => runIsolateTests(args, [testerDo], testeeConcurrent: testeeDo);
