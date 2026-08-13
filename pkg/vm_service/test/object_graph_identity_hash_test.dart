// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'object_graph_identity_hash_lib.dart' as testee_lib;

late HeapSnapshotGraph snapshot1;
late HeapSnapshotObject snapshot1Foo;
late HeapSnapshotObject snapshot1Bar;

late HeapSnapshotGraph snapshot2;
late HeapSnapshotObject snapshot2Foo;
late HeapSnapshotObject snapshot2Bar;

late HeapSnapshotGraph snapshot3;

void main([args = const <String>[]]) => IsolateTestHarness(
      'object_graph_identity_hash_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      snapshot1 = await fetchHeapSnapshot(service, isolateRef);

      final container1s = snapshot1.objects.where(
        (obj) => obj.klass.name == 'Container1',
      );
      expect(container1s.length, 1);

      final c1Obj = container1s.first;

      for (var element in c1Obj.successors) {
        print(element.klass.name);
      }
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
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      snapshot2 = await fetchHeapSnapshot(service, isolateRef);
      final container2s = snapshot2.objects.where(
        (obj) => obj.klass.name == 'Container2',
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
    }).addCustomTest((VmService service, IsolateRef isolateRef) async {
      snapshot3 = await fetchHeapSnapshot(service, isolateRef);
      final container3s = snapshot3.objects.where(
        (obj) => obj.klass.name == 'Container3',
      );
      expect(container3s.length, 1);
      final c3Obj = container3s.first;
      for (final successor in c3Obj.successors) {
        expect(successor.identityHashCode, 0);
      }
    }).run(testeeMain: testee_lib.main, pauseOnExit: true);
