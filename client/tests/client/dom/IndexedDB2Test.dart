#library('IndexedDB1Test');
#import('../../../../lib/unittest/unittest_dom.dart');
#import('dart:dom');
#import('dart:coreimpl');

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


/**
 * Verifies that [actual] has the same graph structure as [expected].
 * Detects cycles and DAG structure in Maps and Lists.
 */
verifyGraph(expected, actual) {
  var eItems = [];
  var aItems = [];

  message(path, reason) => path == ''
      ? reason
      : reason == null ? "path: $path" : "path: $path, $reason";

  walk(path, expected, actual) {
    if (expected is String || expected is num || expected == null) {
      Expect.equals(expected, actual, message(path, 'not equal'));
      return;
    }

    // Cycle or DAG?
    for (int i = 0; i < eItems.length; i++) {
      if (expected === eItems[i]) {
        Expect.identical(aItems[i], actual, message(path, 'back or side edge'));
        return;
      }
    }
    eItems.add(expected);
    aItems.add(actual);

    if (expected is List) {
      Expect.isTrue(actual is List, message(path, '$actual is List'));
      Expect.equals(expected.length, actual.length,
                    message(path, 'different list lengths'));
      for (var i = 0; i < expected.length; i++) {
        walk('$path[$i]', expected[i], actual[i]);
      }
      return;
    }

    if (expected is Map) {
      Expect.isTrue(actual is Map, message(path, '$actual is Map'));
      for (var key in expected.getKeys()) {
        if (!actual.containsKey(key)) {
          Expect.fail(message(path, 'missing key "$key"'));
        }
        walk('$path["$key"]',  expected[key], actual[key]);
      }
      for (var key in actual.getKeys()) {
        if (!expected.containsKey(key)) {
          Expect.fail(message(path, 'extra key "$key"'));
        }
      }
      return;
    }

    Expect.fail('Unhandled type: $expected');
  }

  walk('', expected, actual);
}


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
  forLayoutTests();

  tests_dynamic();
}
