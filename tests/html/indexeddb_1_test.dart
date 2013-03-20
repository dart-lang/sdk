library IndexedDB1Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;

const String STORE_NAME = 'TEST';
const int VERSION = 1;

var databaseNameIndex = 0;
String nextDatabaseName() {
  return 'Test1_${databaseNameIndex++}';
}

Future testUpgrade() {
  var dbName = nextDatabaseName();
  var upgraded = false;

  // Delete any existing DBs.
  return html.window.indexedDB.deleteDatabase(dbName).then((_) {

      return html.window.indexedDB.open(dbName, version: 1,
          onUpgradeNeeded: (e) {});
    }).then((db) {
      db.close();
    }).then((_) {
      return html.window.indexedDB.open(dbName, version: 2,
          onUpgradeNeeded: (e) {
            // Bug 8265, we're getting the wrong type here.
            //expect(e.oldVersion, 1);
            //expect(e.newVersion, 2);
            upgraded = true;
          });
    }).then((_) {
      expect(upgraded, isTrue);
    });
}

testReadWrite(key, value, matcher,
    [dbName, storeName = STORE_NAME, version = VERSION]) => () {
  if (dbName == null) {
    dbName = nextDatabaseName();
  }
  createObjectStore(e) {
    var store = e.target.result.createObjectStore(storeName);
    expect(store, isNotNull);
  }

  var db;
  return html.window.indexedDB.deleteDatabase(dbName).then((_) {
      return html.window.indexedDB.open(dbName, version: version,
          onUpgradeNeeded: createObjectStore);
    }).then((result) {
      db = result;
      var transaction = db.transaction([storeName], 'readwrite');
      transaction.objectStore(storeName).put(value, key);
      return transaction.completed;
    }).then((_) {
      var transaction = db.transaction(storeName, 'readonly');
      return transaction.objectStore(storeName).getObject(key);
    }).then((object) {
      db.close();
      expect(object, matcher);
    }).whenComplete(() {
      if (db != null) {
        db.close();
      }
      return html.window.indexedDB.deleteDatabase(dbName);
    });
};

testReadWriteTyped(key, value, matcher,
    [dbName, storeName = STORE_NAME, version = VERSION]) => () {
  if (dbName == null) {
    dbName = nextDatabaseName();
  }
  void createObjectStore(e) {
    var store = e.target.result.createObjectStore(storeName);
    expect(store, isNotNull);
  }

  idb.Database db;
  // Delete any existing DBs.
  return html.window.indexedDB.deleteDatabase(dbName).then((_) {
      return html.window.indexedDB.open(dbName, version: version,
        onUpgradeNeeded: createObjectStore);
    }).then((idb.Database result) {
      db = result;
      idb.Transaction transaction = db.transaction([storeName], 'readwrite');
      transaction.objectStore(storeName).put(value, key);

      return transaction.completed;
    }).then((idb.Database result) {
      idb.Transaction transaction = db.transaction(storeName, 'readonly');
      return transaction.objectStore(storeName).getObject(key);
    }).then((object) {
      db.close();
      expect(object, matcher);
    }).whenComplete(() {
      if (db != null) {
        db.close();
      }
      return html.window.indexedDB.deleteDatabase(dbName);
    });
};

tests_dynamic() {
  test('test1', testReadWrite(123, 'Hoot!', equals('Hoot!')));
  test('test2', testReadWrite(123, 12345, equals(12345)));
  test('test3', testReadWrite(123, [1, 2, 3], equals([1, 2, 3])));
  test('test4', testReadWrite(123, [2, 3, 4], equals([2, 3, 4])));
  test('test4', testReadWrite(123, false, equals(false)));
}

tests_typed() {
  test('test1', testReadWriteTyped(123, 'Hoot!', equals('Hoot!')));
  test('test2', testReadWriteTyped(123, 12345, equals(12345)));
  test('test3', testReadWriteTyped(123, [1, 2, 3], equals([1, 2, 3])));
  test('test4', testReadWriteTyped(123, [2, 3, 4], equals([2, 3, 4])));
  test('test4', testReadWriteTyped(123, false, equals(false)));
}

main() {
  useHtmlIndividualConfiguration();

  // Test that indexed_db is properly flagged as supported or not.
  // Note that the rest of the indexed_db tests assume that this has been
  // checked.
  group('supported', () {
    test('supported', () {
      expect(idb.IdbFactory.supported, true);
    });
  });

  group('supportsDatabaseNames', () {
    test('supported', () {
      expect(html.window.indexedDB.supportsDatabaseNames, isTrue);
    });
  });

  group('functional', () {
    test('throws when unsupported', () {
      var expectation = idb.IdbFactory.supported ? returnsNormally : throws;

      expect(() {
        var db = html.window.indexedDB;
        db.open('random_db');
      }, expectation);
    });

    // Don't bother with these tests if it's unsupported.
    if (idb.IdbFactory.supported) {
      test('upgrade', testUpgrade);
      tests_dynamic();
      tests_typed();
    }
  });
}
