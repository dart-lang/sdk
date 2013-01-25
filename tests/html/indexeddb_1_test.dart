library IndexedDB1Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html' as html;
import 'dart:indexed_db' as idb;

const String DB_NAME = 'Test';
const String STORE_NAME = 'TEST';
const int VERSION = 1;

testReadWrite(key, value, matcher,
              [dbName = DB_NAME,
               storeName = STORE_NAME,
               version = VERSION]) => () {
  var db;

  fail(e) {
    guardAsync(() {
      throw new Exception('IndexedDB failure');
    });
  }

  createObjectStore(db) {
    var store = db.createObjectStore(storeName);
    expect(store, isNotNull);
  }

  step2(e) {
    var transaction = db.transaction(storeName, 'readonly');
    var request = transaction.objectStore(storeName).getObject(key);
    request.on.success.add(expectAsync1((e) {
      var object = e.target.result;
      db.close();
      expect(object, matcher);
    }));
    request.on.error.add(fail);
  }

  step1() {
    var transaction = db.transaction([storeName], 'readwrite');
    var request = transaction.objectStore(storeName).put(value, key);
    request.on.success.add(expectAsync1(step2));
    request.on.error.add(fail);
  }

  initDb(e) {
    db = e.target.result;
    if (version != db.version) {
      // Legacy 'setVersion' upgrade protocol. Chrome 23 and earlier.
      var request = db.setVersion('$version');
      request.on.success.add(
        expectAsync1((e) {
          createObjectStore(db);
          var transaction = e.target.result;
          transaction.on.complete.add(expectAsync1((e) => step1()));
          transaction.on.error.add(fail);
        })
      );
      request.on.error.add(fail);
    } else {
      step1();
    }
  }

  openDb(e) {
    var request = html.window.indexedDB.open(dbName, version);
    expect(request, isNotNull);
    request.on.success.add(expectAsync1(initDb));
    request.on.error.add(fail);
    if (request is idb.OpenDBRequest) {
      // New upgrade protocol.  Old API has no 'upgradeNeeded' and uses
      // setVersion instead. This path take by FireFox 15, Chrome 24.
      request.on.upgradeNeeded.add((e) {
          guardAsync(() {
              createObjectStore(e.target.result);
            });
        });
    }
  }

  // Delete any existing DB.
  var deleteRequest = html.window.indexedDB.deleteDatabase(dbName);
  deleteRequest.on.success.add(expectAsync1(openDb));
  deleteRequest.on.error.add(fail);
};

testReadWriteTyped(key, value, matcher,
                   [dbName = DB_NAME,
                    storeName = STORE_NAME,
                    version = VERSION]) => () {
  idb.Database db;

  fail(e) {
    guardAsync(() {
      throw new Exception('IndexedDB failure');
    });
  }

  createObjectStore(db) {
    idb.ObjectStore store = db.createObjectStore(storeName);
    expect(store, isNotNull);
  }

  step2(e) {
    idb.Transaction transaction = db.transaction(storeName, 'readonly');
    idb.Request request = transaction.objectStore(storeName).getObject(key);
    request.on.success.add(expectAsync1((e) {
      var object = e.target.result;
      db.close();
      expect(object, matcher);
    }));
    request.on.error.add(fail);
  }

  step1() {
    idb.Transaction transaction = db.transaction([storeName], 'readwrite');
    idb.Request request = transaction.objectStore(storeName).put(value, key);
    request.on.success.add(expectAsync1(step2));
    request.on.error.add(fail);
  }

  initDb(e) {
    db = e.target.result;
    if (version != db.version) {
      // Legacy 'setVersion' upgrade protocol.
      idb.Request request = db.setVersion('$version');
      request.on.success.add(
        expectAsync1((e) {
          createObjectStore(db);
          idb.Transaction transaction = e.target.result;
          transaction.on.complete.add(expectAsync1((e) => step1()));
          transaction.on.error.add(fail);
        })
      );
      request.on.error.add(fail);
    } else {
      step1();
    }
  }

  openDb(e) {
    idb.Request request = html.window.indexedDB.open(dbName, version);
    expect(request, isNotNull);
    request.on.success.add(expectAsync1(initDb));
    request.on.error.add(fail);
    if (request is idb.OpenDBRequest) {
      // New upgrade protocol.  Old API has no 'upgradeNeeded' and uses
      // setVersion instead.
      request.on.upgradeNeeded.add((e) {
          guardAsync(() {
              createObjectStore(e.target.result);
            });
        });
    }
  }

  // Delete any existing DB.
  idb.Request deleteRequest = html.window.indexedDB.deleteDatabase(dbName);
  deleteRequest.on.success.add(expectAsync1(openDb));
  deleteRequest.on.error.add(fail);
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

  test('throws when unsupported', () {
    var expectation = idb.IdbFactory.supported ? returnsNormally : throws;

    expect(() {
      var db = html.window.indexedDB;
    }, expectation);
  });

  // Don't bother with these tests if it's unsupported.
  if (idb.IdbFactory.supported) {
    tests_dynamic();
    tests_typed();
  }
}
