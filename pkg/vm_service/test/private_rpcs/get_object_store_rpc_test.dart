// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:vm_service/vm_service.dart';
import 'package:test/test.dart';

import '../common/test_helper.dart';

void testeeMain() {}

// Pulled from DevTools.
class ObjectStore {
  const ObjectStore({
    required this.fields,
  });

  static ObjectStore? parse(Map<String, dynamic>? json) {
    if (json?['type'] != '_ObjectStore') {
      return null;
    }
    final rawFields = json!['fields']! as Map<String, dynamic>;
    return ObjectStore(
      fields: rawFields.map((key, value) {
        return MapEntry(
          key,
          createServiceObject(value, ['InstanceRef']) as ObjRef,
        );
      }),
    );
  }

  final Map<String, ObjRef> fields;
}

extension on VmService {
  Future<ObjectStore> getObjectStore(String isolateId) async {
    final result = await callMethod('_getObjectStore', isolateId: isolateId);
    return ObjectStore.parse(result.json!)!;
  }
}

final tests = <IsolateTest>[
  // Get object_store.
  (VmService service, IsolateRef isolateRef) async {
    final isolateId = isolateRef.id!;
    final objectStore = await service.getObjectStore(isolateId);

    // Sanity check.
    expect(objectStore.fields, isNotEmpty);

    // Checking Closures.
    final entry = objectStore.fields.keys.singleWhere(
      (e) => e == 'closure_functions_',
    );
    expect(entry, isNotNull);
    final value = objectStore.fields[entry]! as InstanceRef;
    expect(value.kind, InstanceKind.kList);
  }
];

void main([args = const <String>[]]) => runIsolateTestsSynchronous(
      args,
      tests,
      'get_object_store_rpc_test.dart',
      testeeBefore: testeeMain,
    );
