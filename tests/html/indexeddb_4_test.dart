#library('IndexedDB4Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');

// Test for IDBKeyRange and IDBCursor.

final String DB_NAME = 'Test';
final String STORE_NAME = 'TEST';
final String VERSION = '1';

class Test {
  var db;

  start() {
    var request = window.indexedDB.open(DB_NAME);
    Expect.isNotNull(request);
    request.on.success.add(expectAsync1(initDb));
    request.on.error.add(fail('open'));
  }

  initDb(e) {
    db = e.target.result;
    // TODO.  Some browsers do this the w3 way - passing the VERSION to the
    // open call and listening to onversionchange.  Can we feature-detect the
    // difference and make it work?
    var request = db.setVersion(VERSION);
    request.on.success.add(
      expectAsync1((e) {
        try {
          // Nuke object store if it already exists.
          db.deleteObjectStore(STORE_NAME);
        } catch (IDBDatabaseException e) { }
        db.createObjectStore(STORE_NAME);

        var transaction = e.target.result;
        transaction.on.complete.add(expectAsync1((e) => writeItems(0)));
        transaction.on.error.add(fail);
      })
    );
    request.on.error.add(fail('setVersion error'));
  }

  writeItems(int index) {
    if (index < 100) {
      var transaction = db.transaction([STORE_NAME], 'readwrite');
      var request = transaction.objectStore(STORE_NAME)
          .put('Item $index', index);
      request.on.success.add(
        expectAsync1((e) {
          writeItems(index + 1);
        })
      );
      request.on.error.add(fail('put'));
    }
  }

  fail(message) => (e) {
    guardAsync(() {
      Expect.fail('IndexedDB failure: $message');
    });
  };

  testRange(range, expectedFirst, expectedLast) {
    IDBTransaction txn = db.transaction(STORE_NAME, 'readonly');
    IDBObjectStore objectStore = txn.objectStore(STORE_NAME);
    IDBRequest cursorRequest = objectStore.openCursor(range);
    int itemCount = 0;
    int firstKey = null;
    int lastKey = null;
    cursorRequest.on.success.add(expectAsync1((e) {
      var cursor = e.target.result;
      if (cursor != null) {
        if (firstKey == null) firstKey = cursor.key;
        lastKey = cursor.key;
        itemCount += 1;
        Expect.equals('Item ${cursor.key}', cursor.value);
        cursor.continueFunction();
      } else {
        // Done
        Expect.equals(expectedFirst, firstKey);
        Expect.equals(expectedLast, lastKey);
        if (expectedFirst == null) {
          Expect.equals(0, itemCount);
        } else {
          Expect.equals(expectedLast - expectedFirst + 1, itemCount);
        }
      }
    },
    count: 1 + ((expectedFirst == null) ?
           0 : (expectedLast - expectedFirst + 1))));
    cursorRequest.on.error.add(fail('openCursor'));
  }

  only1() => testRange(new IDBKeyRange.only(55), 55, 55);
  only2() => testRange(new IDBKeyRange.only(100), null, null);
  only3() => testRange(new IDBKeyRange.only(-1), null, null);

  lower1() => testRange(new IDBKeyRange.lowerBound(40), 40, 99);
  lower2() => testRange(new IDBKeyRange.lowerBound(40, open: true), 41, 99);
  lower3() => testRange(new IDBKeyRange.lowerBound(40, open: false), 40, 99);

  upper1() => testRange(new IDBKeyRange.upperBound(40), 0, 40);
  upper2() => testRange(new IDBKeyRange.upperBound(40, open: true), 0, 39);
  upper3() => testRange(new IDBKeyRange.upperBound(40, open: false), 0, 40);

  bound1() => testRange(new IDBKeyRange.bound(20, 30), 20, 30);

  bound2() => testRange(new IDBKeyRange.bound(-100, 200), 0, 99);

  bound3() =>
      testRange(new IDBKeyRange.bound(20, 30, upperOpen: true),
                         20, 29);

  bound4() =>
      testRange(new IDBKeyRange.bound(20, 30, lowerOpen: true),
                         21, 30);

  bound5() =>
      testRange(new IDBKeyRange.bound(20, 30, lowerOpen: true, upperOpen: true),
                         21, 29);

}

main() {
  useHtmlConfiguration();

  var test_ = new Test();
  test('prepare', test_.start);

  test('only1', test_.only1);
  test('only2', test_.only2);
  test('only3', test_.only3);

  test('lower1', test_.lower1);
  test('lower2', test_.lower2);
  test('lower3', test_.lower3);

  test('upper1', test_.upper1);
  test('upper2', test_.upper2);
  test('upper3', test_.upper3);

  test('bound1', test_.bound1);
  test('bound2', test_.bound2);
  test('bound3', test_.bound3);
  test('bound4', test_.bound4);
  test('bound5', test_.bound5);
}
