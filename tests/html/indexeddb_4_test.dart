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
    var request = window.webkitIndexedDB.open(DB_NAME);
    Expect.isNotNull(request);
    request.on.success.add(initDb);
    request.on.error.add(fail('open'));
  }

  initDb(e) {
    db = e.target.result;
    // TODO.  Some browsers do this the w3 way - passing the VERSION to the
    // open call and listening to onversionchange.  Can we feature-detect the
    // difference and make it work?
    var request = db.setVersion(VERSION);
    request.on.success.add((e) {
        try {
          // Nuke object store if it already exists.
          db.deleteObjectStore(STORE_NAME);
        } catch (IDBDatabaseException e) { }
        db.createObjectStore(STORE_NAME);
        writeItems(0);
      });
    request.on.error.add(fail('setVersion error'));
  }

  writeItems(int index) {
    if (index < 100) {
      var transaction = db.transaction([STORE_NAME], IDBTransaction.READ_WRITE);
      var request = transaction.objectStore(STORE_NAME)
          .put('Item $index', index);
      request.on.success.add((e) { writeItems(index + 1); });
      request.on.error.add(fail('put'));
    } else {
      callbackDone();
    }
  }

  fail(message) => (e) {
    callbackDone();
    Expect.fail('IndexedDB failure: $message');
  };

  testRange(range, expectedFirst, expectedLast) {
    IDBTransaction txn = db.transaction(STORE_NAME, IDBTransaction.READ_ONLY);
    IDBObjectStore objectStore = txn.objectStore(STORE_NAME);
    IDBRequest cursorRequest = objectStore.openCursor(range);
    int itemCount = 0;
    int firstKey = null;
    int lastKey = null;
    cursorRequest.on.success.add((e) {
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
          callbackDone();
        }
      });
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

  var test = new Test();
  asyncTest('prepare', 1, test.start);

  asyncTest('only1', 1, test.only1);
  asyncTest('only2', 1, test.only2);
  asyncTest('only3', 1, test.only3);

  asyncTest('lower1', 1, test.lower1);
  asyncTest('lower2', 1, test.lower2);
  asyncTest('lower3', 1, test.lower3);

  asyncTest('upper1', 1, test.upper1);
  asyncTest('upper2', 1, test.upper2);
  asyncTest('upper3', 1, test.upper3);

  asyncTest('bound1', 1, test.bound1);
  asyncTest('bound2', 1, test.bound2);
  asyncTest('bound3', 1, test.bound3);
  asyncTest('bound4', 1, test.bound4);
  asyncTest('bound5', 1, test.bound5);

}
