library IndexedDB1Test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;

main() {
  useHtmlConfiguration();

  if (!idb.IdbFactory.supported) {
    return;
  }

  var dbName = 'test_db_5';
  var storeName = 'test_store';
  var indexName = 'name_index';
  var db;

  test('init', () {
    return html.window.indexedDB.deleteDatabase(dbName).then((_) {
      return html.window.indexedDB.open(dbName, version: 1,
          onUpgradeNeeded: (e) {
        var db = e.target.result;
        var objectStore = db.createObjectStore(storeName, autoIncrement: true);
        var index =
            objectStore.createIndex(indexName, 'name_index', unique: false);
      });
    }).then((database) {
      db = database;
    });
  });

  if (html.window.indexedDB.supportsDatabaseNames) {
    test('getDatabaseNames', () {
      return html.window.indexedDB.getDatabaseNames().then((names) {
        expect(names.contains(dbName), isTrue);
      });
    });
  }

  var value = {'name_index': 'one', 'value': 'add_value'};
  test('add/delete', () {
    var transaction = db.transaction(storeName, 'readwrite');
    var key;
    return transaction.objectStore(storeName).add(value).then((addedKey) {
      key = addedKey;
    }).then((_) {
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readonly');
      return transaction.objectStore(storeName).getObject(key);
    }).then((readValue) {
      expect(readValue['value'], value['value']);
      return transaction.completed;
    }).then((_) {
      transaction = db.transactionList([storeName], 'readwrite');
      return transaction.objectStore(storeName).delete(key);
    }).then((_) {
      return transaction.completed;
    }).then((_) {
      var transaction = db.transactionList([storeName], 'readonly');
      return transaction.objectStore(storeName).count();
    }).then((count) {
      expect(count, 0);
    });
  });

  test('clear/count', () {
    var transaction = db.transaction(storeName, 'readwrite');
    transaction.objectStore(storeName).add(value);

    return transaction.completed.then((_) {
      transaction = db.transaction(storeName, 'readonly');
      return transaction.objectStore(storeName).count();
    }).then((count) {
      expect(count, 1);
    }).then((_) {
      return transaction.completed;
    }).then((_) {
      transaction = db.transactionList([storeName], 'readwrite');
      transaction.objectStore(storeName).clear();
      return transaction.completed;
    }).then((_) {
      var transaction = db.transactionList([storeName], 'readonly');
      return transaction.objectStore(storeName).count();
    }).then((count) {
      expect(count, 0);
    });
  });

  test('index', () {
    var transaction = db.transaction(storeName, 'readwrite');
    transaction.objectStore(storeName).add(value);
    transaction.objectStore(storeName).add(value);
    transaction.objectStore(storeName).add(value);
    transaction.objectStore(storeName).add(value);

    return transaction.completed.then((_) {
      transaction = db.transactionList([storeName], 'readonly');
      var index = transaction.objectStore(storeName).index(indexName);
      return index.count();
    }).then((count) {
      expect(count, 4);
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readonly');
      var index = transaction.objectStore(storeName).index(indexName);
      return index.openCursor(autoAdvance: true).length;
    }).then((cursorsLength) {
      expect(cursorsLength, 4);
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readonly');
      var index = transaction.objectStore(storeName).index(indexName);
      return index.openKeyCursor(autoAdvance: true).length;
    }).then((cursorsLength) {
      expect(cursorsLength, 4);
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readonly');
      var index = transaction.objectStore(storeName).index(indexName);
      return index.get('one');
    }).then((readValue) {
      expect(readValue['value'], value['value']);
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readwrite');
      transaction.objectStore(storeName).clear();
      return transaction.completed;
    });
  });

  var deleteValue = {'name_index': 'two', 'value': 'delete_value'};
  var updateValue = {'name_index': 'three', 'value': 'update_value'};
  var updatedValue = {'name_index': 'three', 'value': 'updated_value'};
  test('cursor', () {
    var transaction = db.transaction(storeName, 'readwrite');
    transaction.objectStore(storeName).add(value);
    transaction.objectStore(storeName).add(deleteValue);
    transaction.objectStore(storeName).add(updateValue);

    return transaction.completed.then((_) {
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
      return cursors.last;
    }).then((_) {
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readonly');
      var index = transaction.objectStore(storeName).index(indexName);
      return index.get('three');
    }).then((readValue) {
      expect(readValue['value'], 'updated_value');
      return transaction.completed;
    }).then((_) {
      transaction = db.transaction(storeName, 'readonly');
      var index = transaction.objectStore(storeName).index(indexName);
      return index.get('two');
    }).then((readValue) {
      expect(readValue, isNull);
      return transaction.completed;
    });
  });
}
