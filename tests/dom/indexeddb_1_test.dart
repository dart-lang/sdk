#library('IndexedDB1Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');

final String DB_NAME = 'Test';
final String STORE_NAME = 'TEST';
final String VERSION = '1';

testReadWrite(key, value, check,
              [dbName = DB_NAME,
               storeName = STORE_NAME,
               version = VERSION]) => () {
  var db;

  fail(e) {
    guardAsync(() {
      Expect.fail('IndexedDB failure');
    });
  }

  createObjectStore() {
    var store = db.createObjectStore(storeName);
    Expect.isNotNull(store);
  }

  step2(e) {
    var transaction = db.transaction(storeName, IDBTransaction.READ_ONLY);
    var request = transaction.objectStore(storeName).getObject(key);
    request.addEventListener('success',
      expectAsync1((e) {
        var object = e.target.result;
        check(value, object);
      })
    );
    request.addEventListener('error', fail);
  }

  step1() {
    var transaction = db.transaction([storeName], IDBTransaction.READ_WRITE);
    var request = transaction.objectStore(storeName).put(value, key);
    request.addEventListener('success', expectAsync1(step2));
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
        expectAsync1((e) {
          createObjectStore();
          step1();
        })
      );
      request.addEventListener('error', fail);
    } else {
      step1();
    }
  }

  var request = window.webkitIndexedDB.open(dbName);
  Expect.isNotNull(request);
  request.addEventListener('success', expectAsync1(initDb));
  request.addEventListener('error', fail);
};

testReadWriteTyped(key, value, check,
                   [dbName = DB_NAME,
                    storeName = STORE_NAME,
                    version = VERSION]) => () {
  IDBDatabase db;

  fail(e) {
    guardAsync(() {
      Expect.fail('IndexedDB failure');
    });
  }

  createObjectStore() {
    IDBObjectStore store = db.createObjectStore(storeName);
    Expect.isNotNull(store);
  }

  step2(e) {
    IDBTransaction transaction =
         db.transaction(storeName, IDBTransaction.READ_ONLY);
    IDBRequest request = transaction.objectStore(storeName).getObject(key);
    request.addEventListener('success',
      expectAsync1((e) {
        var object = e.target.result;
        check(value, object);
      })
    );
    request.addEventListener('error', fail);
  }

  step1() {
    IDBTransaction transaction =
    db.transaction([storeName], IDBTransaction.READ_WRITE);
    IDBRequest request = transaction.objectStore(storeName).put(value, key);
    request.addEventListener('success', expectAsync1(step2));
    request.addEventListener('error', fail);
  }

  initDb(e) {
    db = e.target.result;
    if (version != db.version) {
      IDBRequest request = db.setVersion(version);
      request.addEventListener('success',
        expectAsync1((e) {
          createObjectStore();
          step1();
        })
      );
      request.addEventListener('error', fail);
    } else {
      step1();
    }
  }

  IDBRequest request = window.webkitIndexedDB.open(dbName);
  Expect.isNotNull(request);
  request.addEventListener('success', expectAsync1(initDb));
  request.addEventListener('error', fail);
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
  test('test4', testReadWriteTyped(123, const [2, 3, 4], Expect.listEquals));
}

main() {
  useDomConfiguration();

  tests_dynamic();
  tests_typed();
}
