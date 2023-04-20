// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:expect/expect.dart';

import 'package:path/path.dart' as path;
import 'heap_snapshot_test.dart';
import 'use_flag_test_helper.dart';

@pragma('vm:entry-point')
class FooBar {
  @pragma('vm:entry-point')
  BarBaz bar;
  int value;
  @pragma('vm:entry-point')
  List<int> bar2;
  FooBar(this.bar, this.value, this.bar2);

  String toString() => 'FooBar($bar, $value, $bar2)';
}

@pragma('vm:entry-point')
class BarBaz {
  final int value;
  BarBaz(this.value);
  String toString() => 'BarBaz($value)';
}

@pragma('vm:entry-point')
var global;

main() async {
  if (const bool.fromEnvironment('dart.vm.product')) return;

  await withTempDir('heap_snapshot_test', (String dir) async {
    final file = path.join(dir, 'state1.heapsnapshot');

    // Closures are the example this is a regresion test for, so ensure there's
    // a reachable closure in the heapsnapshot.
    global = alwaysTrue ? FooBar(BarBaz(1), 2, List.filled(1, 3)) : null;
    NativeRuntime.writeHeapSnapshotToFile(file);
    Expect.equals('FooBar(BarBaz(1), 2, [3])', global.toString());

    final snapshot = loadHeapSnapshotFromFile(file);
    final classes = snapshot.classes;

    // Ensure all objects have same number of references as fields, except for
    // variable-length lists.
    final reachableObjects = findReachableObjects(snapshot);
    for (final object in reachableObjects) {
      final klass = snapshot.classes[object.classId];
      final uri = klass.libraryUri.toString();
      final fields = klass.fields;

      // Variable-length data may have more references than fields.
      if (uri == '') {
        // We don't verify non-user-visible objects.
      } else if (uri.startsWith('dart') &&
          ['Array', 'List', 'Record'].any((p) => klass.name.contains(p))) {
        Expect.isTrue(fields.length <= object.references.length);
      } else {
        Expect.equals(fields.length, object.references.length, klass.name);
      }
    }

    // Specifically look at layout and references of [FooBar] class.
    final fooClass = classes.singleWhere((c) => c.name == 'FooBar');
    final barClass = classes.singleWhere((c) => c.name == 'BarBaz');
    final listClass = classes.singleWhere((c) => c.name == '_List');

    final barField = fooClass.fields.singleWhere((f) => f.name == 'bar');
    final bar2Field = fooClass.fields.singleWhere((f) => f.name == 'bar2');

    // There should be one instance of [FooBar].
    final fooObject = reachableObjects
        .where((object) => object.classId == fooClass.classId)
        .single;
    final fooObjectBarField =
        snapshot.objects[fooObject.references[barField.index]];
    final fooObjectBar2Field =
        snapshot.objects[fooObject.references[bar2Field.index]];
    Expect.equals(3, fooObject.references.length);
    Expect.equals(0, barField.index);
    Expect.equals(2, bar2Field.index);
    Expect.equals(barClass.classId, fooObjectBarField.classId);
    Expect.equals(listClass.classId, fooObjectBar2Field.classId);
    Expect.equals(
        listClass.fields.length + 1, fooObjectBar2Field.references.length);
  });
}
