// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dev_compiler/runtime/dart_logging_runtime.dart' as devc;
import 'package:unittest/unittest.dart';

class A<T> {
  T x;
  A(this.x);
}

class B extends A<String> {
  B() : super("B!");
}

void runTest() {
  var astring = new A<String>("").runtimeType;
  var l = [new A<String>("hello"), new A("world"), new B(), 42];
  for (var item in l) {
    try {
      devc.cast(item, dynamic, astring);
    } catch (e) {
      // Do nothing
    }
  }
}

final expected = '''
Key test/runtime/dart_logging_runtime_test.dart 22:16 in runTest:
 - static type: A<String>
 - runtime types: {A, int}
 - success: 0 (0.0)
 - failure: 1 (0.5)
 - mismatch: 1 (0.5)
 - error: 0 (0.0)
''';

void main() {
  test('summary', () {
    runTest();
    var output = devc.summary();
    expect(output, equals(expected));
  });

  test('handler', () {
    int devcFailures = 0;
    int dartFailures = 0;
    devc.castRecordHandler = (String key, devc.CastRecord record) {
      devcFailures += record.soundCast ? 0 : 1;
      dartFailures += record.dartCast ? 0 : 1;
    };
    runTest();
    expect(devcFailures, equals(2));
    expect(dartFailures, equals(1));
  });
}
