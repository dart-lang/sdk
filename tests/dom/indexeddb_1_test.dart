#library('IndexedDB1Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');

final String DB_NAME = 'Test';
final String STORE_NAME = 'TEST';
final String VERSION = '1';

testReadWrite(key, value, check,
              [dbName = DB_NAME,
               storeName = STORE_NAME,
               version = VERSION]) => () {
  var db;

  fail(e) {
    callbackDone();
    Expect.fail('IndexedDB failure');
  }

  createObjectStore() {
    var store = db.createObjectStore(storeName);
    Expect.isNotNull(store);
  }

  step2() {
    var transaction = db.transaction(storeName, IDBTransaction.READ_ONLY);
    var request = transaction.objectStore(storeName).getObject(key);
    request.addEventListener('success', (e) {
        var object = e.target.result;
        check(value, object);
        callbackDone();
      });
    request.addEventListener('error', fail);
  }

  step1() {
    var transaction = db.transaction([storeName], IDBTransaction.READ_WRITE);
    var request = transaction.objectStore(storeName).put(value, key);
    request.addEventListener('success', (e) { step2(); });
    request.addEventListener('error', fail);
  }

  initDb(e) {
    db = e.target.result;
    if (version != db.version) {
      // TODO.  Some browsers do this the w3 way - passing the version to the
      // open call and listening to onversionchange.  Can we feature-detect the
      // difference and make it work?
      var request = db.setVersion(version);
      request.addEventListener('success',
                               (e) { createObjectStore(); step1(); });
      request.addEventListener('error', fail);
    } else {
      step1();
    }
  }

  var request = window.webkitIndexedDB.open(dbName);
  Expect.isNotNull(request);
  request.addEventListener('success', initDb);
  request.addEventListener('error', fail);
};

testReadWriteTyped(key, value, check,
                   [dbName = DB_NAME,
                    storeName = STORE_NAME,
                    version = VERSION]) => () {
  IDBDatabase db;

  fail(e) {
    callbackDone();
    Expect.fail('IndexedDB failure');
  }

  createObjectStore() {
    IDBObjectStore store = db.createObjectStore(storeName);
    Expect.isNotNull(store);
  }

  step2() {
    IDBTransaction transaction =
       db.transaction(storeName, IDBTransaction.READ_ONLY);
    IDBRequest request = transaction.objectStore(storeName).getObject(key);
    request.addEventListener('success', (e) {
        var object = e.target.result;
        check(value, object);
        callbackDone();
      });
    request.addEventListener('error', fail);
  }

  step1() {
    IDBTransaction transaction =
    db.transaction([storeName], IDBTransaction.READ_WRITE);
    IDBRequest request = transaction.objectStore(storeName).put(value, key);
    request.addEventListener('success', (e) { step2(); });
    request.addEventListener('error', fail);
  }

  initDb(e) {
    db = e.target.result;
    if (version != db.version) {
      IDBRequest request = db.setVersion(version);
      request.addEventListener('success',
                               (e) { createObjectStore(); step1(); });
      request.addEventListener('error', fail);
    } else {
      step1();
    }
  }

  IDBRequest request = window.webkitIndexedDB.open(dbName);
  Expect.isNotNull(request);
  request.addEventListener('success', initDb);
  request.addEventListener('error', fail);
};

tests_dynamic() {
  asyncTest('test1', 1, testReadWrite(123, 'Hoot!', Expect.equals));
  asyncTest('test2', 1, testReadWrite(123, 12345, Expect.equals));
  asyncTest('test3', 1, testReadWrite(123, [1,2,3], Expect.listEquals));
  asyncTest('test4', 1, testReadWrite(123, const [2, 3, 4], Expect.listEquals));
}

tests_typed() {
  asyncTest('test1', 1, testReadWriteTyped(123, 'Hoot!', Expect.equals));
  asyncTest('test2', 1, testReadWriteTyped(123, 12345, Expect.equals));
  asyncTest('test3', 1, testReadWriteTyped(123, [1,2,3], Expect.listEquals));
  asyncTest('test4', 1,
            testReadWriteTyped(123, const [2, 3, 4], Expect.listEquals));
}

main() {
  useDomConfiguration();

  tests_dynamic();
  tests_typed();
}
