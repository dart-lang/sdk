// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';
import 'package:observatory_2/models.dart' show InstanceKind;
import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'service_test_common.dart';
import 'test_helper.dart';

class A {}

class B extends A {}

class C extends Object with ListMixin<C> implements List<C> {
  int length = 0;
  C operator [](int index) => throw UnimplementedError();
  void operator []=(int index, C value) {}
}

void testFunction4<T4 extends List<T4>>() {
  debugger();
  print("T4 = $T4");
}

void testFunction3<T3, S3 extends T3>() {
  debugger();
  print("T3 = $T3");
  print("S3 = $S3");
}

void testFunction2<E extends String>(List<E> x) {
  debugger();
  print("x = $x");
}

void testFunction() {
  testFunction2<String>(<String>["a", "b", "c"]);
  testFunction3<A, B>();
  testFunction4<C>();
}

void fooxx<E extends String>(List<E> y) {
  List<E> x = new List<E>.from(["hello"]);
}

var tests = <IsolateTest>[
  hasStoppedAtBreakpoint,
  (Isolate isolate) async {
    {
      // Can add List<E extends String> to List<String> directly.
      Instance result = await isolate.evalFrame(0, '''() {
        List<E> y = new List<E>.from(["hello"]);
        x.addAll(y);
        return x.last;
      }()''') as Instance;
      expect(result.valueAsString, equals("hello"));
      expect(result.kind, equals(InstanceKind.string));
    }
    {
      // Can't add List<String> to List<E extends String> directly.
      DartError result = await isolate.evalFrame(0, '''() {
        List<E> y = [];
        y.addAll(x);
        return y.last;
      }()''') as DartError;
      expect(
          result.message,
          contains(
              "The argument type '_GrowableList<String>' can't be assigned "
              "to the parameter type 'Iterable<E>'"));
    }
    {
      // Can add List<String> to List<E extends String> via cast.
      Instance result = await isolate.evalFrame(0, '''() {
        List<E> y = [];
        y.addAll(x.cast());
        return y.toString();
      }()''') as Instance;
      // Notice how "hello" was added a few evaluations back.
      expect(result.valueAsString, equals("[a, b, c, hello]"));
      expect(result.kind, equals(InstanceKind.string));
    }
    {
      // Can create List<String> from List<E extends String>.
      Instance result = await isolate.evalFrame(0, '''() {
        List<E> y = new List<E>.from(x);
        return y.toString();
      }()''') as Instance;
      // Notice how "hello" was added a few evaluations back.
      expect(result.valueAsString, equals("[a, b, c, hello]"));
      expect(result.kind, equals(InstanceKind.string));
    }
  },
  resumeIsolate,
  (Isolate isolate) async {
    // This is just to make sure the VM doesn't crash.
    Instance result =
        await isolate.evalFrame(0, '''S3.toString()''') as Instance;
    expect(result.valueAsString, equals("B"));
    expect(result.kind, equals(InstanceKind.string));
  },
  resumeIsolate,
  (Isolate isolate) async {
    // This is just to make sure the VM doesn't crash.
    Instance result =
        await isolate.evalFrame(0, '''T4.toString()''') as Instance;
    expect(result.valueAsString, equals("C"));
    expect(result.kind, equals(InstanceKind.string));
  },
];

main(args) => runIsolateTests(args, tests, testeeConcurrent: testFunction);
