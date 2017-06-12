library IndexedDB3Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db';

// Read with cursor.

const String DB_NAME = 'Test3';
const String STORE_NAME = 'TEST';
const int VERSION = 1;

Future<Database> createAndOpenDb() {
  return html.window.indexedDB.deleteDatabase(DB_NAME).then((_) {
    return html.window.indexedDB.open(DB_NAME, version: VERSION,
        onUpgradeNeeded: (e) {
      var db = e.target.result;
      db.createObjectStore(STORE_NAME);
    });
  });
}

Future<Database> writeItems(Database db) {
  Future<Object> write(index) {
    var transaction = db.transaction(STORE_NAME, 'readwrite');
    transaction.objectStore(STORE_NAME).put('Item $index', index);
    return transaction.completed;
  }

  var future = write(0);
  for (var i = 1; i < 100; ++i) {
    future = future.then((_) => write(i));
  }

  // Chain on the DB so we return it at the end.
  return future.then((_) => db);
}

Future<Database> setupDb() {
  return createAndOpenDb().then(writeItems);
}

Future<Database> readAllViaCursor(Database db) {
  Transaction txn = db.transaction(STORE_NAME, 'readonly');
  ObjectStore objectStore = txn.objectStore(STORE_NAME);
  int itemCount = 0;
  int sumKeys = 0;
  var lastKey = null;

  var cursors = objectStore.openCursor().asBroadcastStream();
  cursors.listen((cursor) {
    ++itemCount;
    lastKey = cursor.key;
    sumKeys += cursor.key;
    expect(cursor.value, 'Item ${cursor.key}');
    cursor.next();
  });
  cursors.last.then((cursor) {
    expect(lastKey, 99);
    expect(sumKeys, (100 * 99) ~/ 2);
    expect(itemCount, 100);
  });

  return cursors.last.then((_) => db);
}

Future<Database> readAllReversedViaCursor(Database db) {
  Transaction txn = db.transaction(STORE_NAME, 'readonly');
  ObjectStore objectStore = txn.objectStore(STORE_NAME);
  int itemCount = 0;
  int sumKeys = 0;
  var lastKey = null;

  var cursors = objectStore.openCursor(direction: 'prev').asBroadcastStream();
  cursors.listen((cursor) {
    ++itemCount;
    lastKey = cursor.key;
    sumKeys += cursor.key;
    expect(cursor.value, 'Item ${cursor.key}');
    cursor.next();
  });
  cursors.last.then((cursor) {
    expect(lastKey, 0);
    expect(sumKeys, (100 * 99) ~/ 2);
    expect(itemCount, 100);
  });
  return cursors.last.then((_) => db);
}

main() {
  useHtmlConfiguration();

  // Don't bother with these tests if it's unsupported.
  // Support is tested in indexeddb_1_test
  if (IdbFactory.supported) {
    var db;
    test('prepare', () {
      return setupDb().then((result) {
        db = result;
      });
    });
    test('readAll1', () {
      return readAllViaCursor(db);
    });

    test('readAll2', () {
      return readAllReversedViaCursor(db);
    });
  }
}
