#library('IndexedDB1Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

const String DB_NAME = 'Test';
const String STORE_NAME = 'TEST';
const int VERSION = 1;

testReadWrite(key, value, check,
              [dbName = DB_NAME,
               storeName = STORE_NAME,
               version = VERSION]) => () {
  var db;

  fail(e) {
    guardAsync(() {
      throw const Exception('IndexedDB failure');
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
      check(value, object);
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
    var request = window.indexedDB.open(dbName, version);
    expect(request, isNotNull);
    request.on.success.add(expectAsync1(initDb));
    request.on.error.add(fail);
    if (request is IDBOpenDBRequest) {
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
  var deleteRequest = window.indexedDB.deleteDatabase(dbName);
  deleteRequest.on.success.add(expectAsync1(openDb));
  deleteRequest.on.error.add(fail);
};

testReadWriteTyped(key, value, check,
                   [dbName = DB_NAME,
                    storeName = STORE_NAME,
                    version = VERSION]) => () {
  IDBDatabase db;

  fail(e) {
    guardAsync(() {
      throw const Exception('IndexedDB failure');
    });
  }

  createObjectStore(db) {
    IDBObjectStore store = db.createObjectStore(storeName);
    expect(store, isNotNull);
  }

  step2(e) {
    IDBTransaction transaction = db.transaction(storeName, 'readonly');
    IDBRequest request = transaction.objectStore(storeName).getObject(key);
    request.on.success.add(expectAsync1((e) {
      var object = e.target.result;
      db.close();
      check(value, object);
    }));
    request.on.error.add(fail);
  }

  step1() {
    IDBTransaction transaction = db.transaction([storeName], 'readwrite');
    IDBRequest request = transaction.objectStore(storeName).put(value, key);
    request.on.success.add(expectAsync1(step2));
    request.on.error.add(fail);
  }

  initDb(e) {
    db = e.target.result;
    if (version != db.version) {
      // Legacy 'setVersion' upgrade protocol.
      IDBRequest request = db.setVersion('$version');
      request.on.success.add(
        expectAsync1((e) {
          createObjectStore(db);
          IDBTransaction transaction = e.target.result;
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
    IDBRequest request = window.indexedDB.open(dbName, version);
    expect(request, isNotNull);
    request.on.success.add(expectAsync1(initDb));
    request.on.error.add(fail);
    if (request is IDBOpenDBRequest) {
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
  IDBRequest deleteRequest = window.indexedDB.deleteDatabase(dbName);
  deleteRequest.on.success.add(expectAsync1(openDb));
  deleteRequest.on.error.add(fail);
};

tests_dynamic() {
  test('test1', testReadWrite(123, 'Hoot!', Expect.equals));
  test('test2', testReadWrite(123, 12345, Expect.equals));
  test('test3', testReadWrite(123, [1,2,3], Expect.listEquals));
  test('test4', testReadWrite(123, const [2, 3, 4], Expect.listEquals));
}

tests_typed() {
  test('test1', testReadWriteTyped(123, 'Hoot!', Expect.equals));
  test('test2', testReadWriteTyped(123, 12345, Expect.equals));
  test('test3', testReadWriteTyped(123, [1,2,3], Expect.listEquals));
  test('test4',
            testReadWriteTyped(123, const [2, 3, 4], Expect.listEquals));
}

main() {
  useHtmlConfiguration();

  tests_dynamic();
  tests_typed();
}
