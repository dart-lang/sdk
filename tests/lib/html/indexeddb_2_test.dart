// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library IndexedDB1Test;

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;
import 'dart:collection';
import 'utils.dart';

// Write and re-read Maps: simple Maps; Maps with DAGs; Maps with cycles.

const String DB_NAME = 'Test2';
const String STORE_NAME = 'TEST';
const int VERSION = 1;

testReadWrite(key, value, check,
    [dbName = DB_NAME, storeName = STORE_NAME, version = VERSION]) async {
  void createObjectStore(e) {
    idb.ObjectStore store = e.target.result.createObjectStore(storeName);
    expect(store, isNotNull);
  }

  idb.Database? db;
  // Delete any existing DBs.
  try {
    await html.window.indexedDB!.deleteDatabase(dbName);
    db = await html.window.indexedDB!
        .open(dbName, version: version, onUpgradeNeeded: createObjectStore);

    idb.Transaction transaction = db.transactionList([storeName], 'readwrite');
    transaction.objectStore(storeName).put(value, key);

    db = await transaction.completed;
    transaction = db.transaction(storeName, 'readonly');
    var object = await transaction.objectStore(storeName).getObject(key);

    db.close();
    check(value, object);
  } catch (error) {
    if (db != null) {
      db.close();
    }
    throw error;
  }
}

List<String> get nonNativeListData {
  List<String> list = [];
  list.add("data");
  list.add("clone");
  list.add("error");
  list.add("test");
  return list;
}

main() {
  var obj1 = {'a': 100, 'b': 's'};
  var obj2 = {'x': obj1, 'y': obj1}; // DAG.

  var obj3 = {};
  obj3['a'] = 100;
  obj3['b'] = obj3; // Cycle.

  var obj4 = new SplayTreeMap<String, dynamic>(); // Different implementation.
  obj4['a'] = 100;
  obj4['b'] = 's';

  var cyclic_list = <Object>[1, 2, 3];
  cyclic_list[1] = cyclic_list;

  go(name, data) => testReadWrite(123, data, verifyGraph);

  test('test_verifyGraph', () {
    // Nice to know verifyGraph is working before we rely on it.
    verifyGraph(obj4, obj4);
    verifyGraph(obj1, new Map.from(obj1));
    verifyGraph(obj4, new Map.from(obj4));

    var l1 = [1, 2, 3];
    var l2 = [
      const [1, 2, 3],
      const [1, 2, 3]
    ];
    verifyGraph([l1, l1], l2);
    // Use a try-catch block, since failure can be an expect exception.
    // package:expect does not allow catching test exceptions.
    try {
      verifyGraph([
        [1, 2, 3],
        [1, 2, 3]
      ], l2);
      fail("Expected failure in verifying the graph.");
    } catch (_) {
      // Expected failure. Continue.
    }

    verifyGraph(cyclic_list, cyclic_list);
  });

  // Don't bother with these tests if it's unsupported.
  // Support is tested in indexeddb_1_test
  if (idb.IdbFactory.supported) {
    asyncTest(() async {
      await go('test_simple', obj1);
      await go('test_DAG', obj2);
      await go('test_cycle', obj3);
      await go('test_simple_splay', obj4);
      await go('const_array_1', const [
        const [1],
        const [2]
      ]);
      await go('const_array_dag', const [
        const [1],
        const [1]
      ]);
      await go('array_deferred_copy', [1, 2, 3, obj3, obj3, 6]);
      await go('array_deferred_copy_2', [
        1,
        2,
        3,
        [4, 5, obj3],
        [obj3, 6]
      ]);
      await go('cyclic_list', cyclic_list);
      await go('non-native lists', nonNativeListData);
    });
  }
}
