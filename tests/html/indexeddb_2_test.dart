#library('IndexedDB1Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
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
    guardAsync(() {
      Expect.fail('IndexedDB failure');
    });
  }

  createObjectStore() {
    var store = db.createObjectStore(storeName);
    Expect.isNotNull(store);
  }

  step2(e) {
    var transaction = db.transaction(storeName, 'readonly');
    var request = transaction.objectStore(storeName).getObject(key);
    request.on.success.add(expectAsync1((e) {
        var object = e.target.result;
        check(value, object);
      })
    );
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
      // TODO.  Some browsers do this the w3 way - passing the version to the
      // open call and listening to onversionchange.  Can we feature-detect the
      // difference and make it work?
      var request = db.setVersion(version);
      request.on.success.add(
        expectAsync1((e) {
          createObjectStore();

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

  var request = window.indexedDB.open(dbName);
  Expect.isNotNull(request);
  request.on.success.add(expectAsync1(initDb));
  request.on.error.add(fail);
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

  test('test_simple', testReadWrite(123, obj1, verifyGraph));
  test('test_DAG', testReadWrite(123, obj2, verifyGraph));
  test('test_cycle', testReadWrite(123, obj3, verifyGraph));
  test('test_simple_splay', testReadWrite(123, obj4, verifyGraph));
}

main() {
  useHtmlConfiguration();

  tests_dynamic();
}
