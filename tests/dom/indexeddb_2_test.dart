#library('IndexedDB1Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom_deprecated');
#import('dart:coreimpl');
#import('utils.dart');

// Write and re-read Maps: simple Maps; Maps with DAGs; Maps with cycles.

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


tests_dynamic() {
  var obj1 = {'a': 100, 'b': 's'};
  var obj2 = {'x': obj1, 'y': obj1};  // DAG.

  var obj3 = {};
  obj3['a'] = 100;
  obj3['b'] = obj3;  // Cycle.

  var obj4 = new SplayTreeMap<String, Dynamic>();  // Different implementation.
  obj4['a'] = 100;
  obj4['b'] = 's';

  asyncTest('test_simple', 1, testReadWrite(123, obj1, verifyGraph));
  asyncTest('test_DAG', 1, testReadWrite(123, obj2, verifyGraph));
  asyncTest('test_cycle', 1, testReadWrite(123, obj3, verifyGraph));
  asyncTest('test_simple_splay', 1, testReadWrite(123, obj4, verifyGraph));
}

main() {
  useDomConfiguration();

  tests_dynamic();
}
