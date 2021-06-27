// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observatory/object_graph.dart';
import 'package:observatory/service_io.dart';
import 'package:test/test.dart';
import 'service_test_common.dart';
import 'test_helper.dart';

@pragma("vm:entry-point") // Prevent obfuscation
class Foo {}

@pragma("vm:entry-point") // Prevent obfuscation
class Bar {}

class Container1 {
  @pragma("vm:entry-point") // Prevent obfuscation
  Foo foo = Foo();
  @pragma("vm:entry-point") // Prevent obfuscation
  Bar bar = Bar();
}

class Container2 {
  Container2(this.foo);

  @pragma("vm:entry-point") // Prevent obfuscation
  Foo foo;
  @pragma("vm:entry-point") // Prevent obfuscation
  Bar bar = Bar();
}

class Container3 {
  @pragma("vm:entry-point") // Prevent obfuscation
  int number = 42;
  @pragma("vm:entry-point") // Prevent obfuscation
  double doub = 3.14;
  @pragma("vm:entry-point") // Prevent obfuscation
  String foo = 'foobar';
  @pragma("vm:entry-point") // Prevent obfuscation
  bool bar = false;
  @pragma("vm:entry-point") // Prevent obfuscation
  late Map baz;
  @pragma("vm:entry-point") // Prevent obfuscation
  late List list;
  @pragma("vm:entry-point") // Prevent obfuscation
  late List unmodifiableList;

  Container3() {
    baz = {
      'a': 'b',
    };
    list = [1, 2, 3];
    unmodifiableList = List.empty();
  }
}

@pragma("vm:entry-point") // Prevent obfuscation
late Container1 c1;
@pragma("vm:entry-point") // Prevent obfuscation
late Container2 c2;
@pragma("vm:entry-point") // Prevent obfuscation
late Container3 c3;

void script() {
  c1 = Container1();
  c2 = Container2(c1.foo);
  c3 = Container3();
}

late SnapshotGraph snapshot1;
late SnapshotObject snapshot1Foo;
late SnapshotObject snapshot1Bar;

late SnapshotGraph snapshot2;
late SnapshotObject snapshot2Foo;
late SnapshotObject snapshot2Bar;

late SnapshotGraph snapshot3;

final tests = <IsolateTest>[
  (Isolate isolate) async {
    snapshot1 = await isolate.fetchHeapSnapshot().done;

    Iterable<SnapshotObject> container1s = snapshot1.objects.where(
      (SnapshotObject obj) => obj.klass.name == 'Container1',
    );
    expect(container1s.length, 1);

    final c1Obj = container1s.first;

    c1Obj.successors.forEach((element) {
      print(element.klass.name);
    });
    snapshot1Foo = c1Obj.successors.firstWhere(
      (element) => element.klass.name == 'Foo',
    );
    expect(
      snapshot1Foo.identityHashCode != 0,
      true,
    );

    snapshot1Bar = c1Obj.successors.firstWhere(
      (element) => element.klass.name == 'Bar',
    );
    expect(
      snapshot1Bar.identityHashCode != 0,
      true,
    );
  },
  (Isolate isolate) async {
    snapshot2 = await isolate.fetchHeapSnapshot().done;
    Iterable<SnapshotObject> container2s = snapshot2.objects.where(
      (SnapshotObject obj) => obj.klass.name == 'Container2',
    );
    expect(container2s.length, 1);

    final c2Obj = container2s.first;

    snapshot2Foo = c2Obj.successors.firstWhere(
      (element) => element.klass.name == 'Foo',
    );
    expect(
      snapshot2Foo.identityHashCode != 0,
      true,
    );
    expect(
      snapshot1Foo.identityHashCode == snapshot2Foo.identityHashCode,
      true,
    );

    snapshot2Bar = c2Obj.successors.firstWhere(
      (element) => element.klass.name == 'Bar',
    );
    expect(
      snapshot2Bar.identityHashCode != 0,
      true,
    );
    expect(
      snapshot1Bar.identityHashCode != snapshot2Bar.identityHashCode,
      true,
    );
  },
  (Isolate isolate) async {
    snapshot3 = await isolate.fetchHeapSnapshot().done;
    Iterable<SnapshotObject> container3s = snapshot3.objects.where(
      (SnapshotObject obj) => obj.klass.name == 'Container3',
    );
    expect(container3s.length, 1);
    final c3Obj = container3s.first;
    for (final successor in c3Obj.successors) {
      expect(successor.identityHashCode, 0);
    }
  },
];

main(args) => runIsolateTests(
      args,
      tests,
      testeeBefore: script,
      pause_on_exit: true,
    );
