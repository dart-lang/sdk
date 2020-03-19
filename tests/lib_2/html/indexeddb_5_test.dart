library IndexedDB1Test;

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;

var dbName = 'test_db_5';
var storeName = 'test_store';
var indexName = 'name_index';
var db;
var value = {'name_index': 'one', 'value': 'add_value'};

Future testInit() async {
  await html.window.indexedDB.deleteDatabase(dbName);
  db = await html.window.indexedDB.open(dbName, version: 1,
      onUpgradeNeeded: (idb.VersionChangeEvent e) {
    var db = e.target.result;
    var objectStore = db.createObjectStore(storeName, autoIncrement: true);
    objectStore.createIndex(indexName, 'name_index', unique: false);
  });
}

Future testAddDelete() async {
  var transaction = db.transaction(storeName, 'readwrite');
  var key = await transaction.objectStore(storeName).add(value);
  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  var readValue = await transaction.objectStore(storeName).getObject(key);
  expect(readValue['value'], value['value']);
  await transaction.completed;
  transaction = db.transactionList([storeName], 'readwrite');
  await transaction.objectStore(storeName).delete(key);
  await transaction.completed;
  transaction = db.transactionList([storeName], 'readonly');
  var count = await transaction.objectStore(storeName).count();
  expect(count, 0);
}

Future testClearCount() async {
  var transaction = db.transaction(storeName, 'readwrite');
  transaction.objectStore(storeName).add(value);

  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  var count = await transaction.objectStore(storeName).count();
  expect(count, 1);
  await transaction.completed;
  transaction = db.transactionList([storeName], 'readwrite');
  transaction.objectStore(storeName).clear();
  await transaction.completed;
  transaction = db.transactionList([storeName], 'readonly');
  count = await transaction.objectStore(storeName).count();
  expect(count, 0);
}

Future testIndex() async {
  var transaction = db.transaction(storeName, 'readwrite');
  transaction.objectStore(storeName).add(value);
  transaction.objectStore(storeName).add(value);
  transaction.objectStore(storeName).add(value);
  transaction.objectStore(storeName).add(value);

  await transaction.completed;
  transaction = db.transactionList([storeName], 'readonly');
  var index = transaction.objectStore(storeName).index(indexName);
  var count = await index.count();
  expect(count, 4);
  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  index = transaction.objectStore(storeName).index(indexName);
  var cursorsLength = await index.openCursor(autoAdvance: true).length;
  expect(cursorsLength, 4);
  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  index = transaction.objectStore(storeName).index(indexName);
  cursorsLength = await index.openKeyCursor(autoAdvance: true).length;
  expect(cursorsLength, 4);
  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  index = transaction.objectStore(storeName).index(indexName);
  var readValue = await index.get('one');
  expect(readValue['value'], value['value']);
  await transaction.completed;
  transaction = db.transaction(storeName, 'readwrite');
  transaction.objectStore(storeName).clear();
  return transaction.completed;
}

Future testCursor() async {
  var deleteValue = {'name_index': 'two', 'value': 'delete_value'};
  var updateValue = {'name_index': 'three', 'value': 'update_value'};
  var updatedValue = {'name_index': 'three', 'value': 'updated_value'};
  var transaction = db.transaction(storeName, 'readwrite');
  transaction.objectStore(storeName).add(value);
  transaction.objectStore(storeName).add(deleteValue);
  transaction.objectStore(storeName).add(updateValue);

  await transaction.completed;
  transaction = db.transactionList([storeName], 'readwrite');
  var index = transaction.objectStore(storeName).index(indexName);
  var cursors = index.openCursor().asBroadcastStream();

  cursors.listen((cursor) {
    var value = cursor.value;
    if (value['value'] == 'delete_value') {
      cursor.delete().then((_) {
        cursor.next();
      });
    } else if (value['value'] == 'update_value') {
      cursor.update(updatedValue).then((_) {
        cursor.next();
      });
    } else {
      cursor.next();
    }
  });
  await cursors.last;
  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  index = transaction.objectStore(storeName).index(indexName);
  var readValue = await index.get('three');
  expect(readValue['value'], 'updated_value');
  await transaction.completed;
  transaction = db.transaction(storeName, 'readonly');
  index = transaction.objectStore(storeName).index(indexName);
  readValue = await index.get('two');
  expect(readValue, isNull);
  return transaction.completed;
}

main() {
  if (!idb.IdbFactory.supported) {
    return;
  }
  asyncTest(() async {
    await testInit();
    await testAddDelete();
    await testClearCount();
    await testIndex();
    await testCursor();
  });
}
