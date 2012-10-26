#library('IndexedDB4Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

// Test for IDBKeyRange and IDBCursor.

const String DB_NAME = 'Test';
const String STORE_NAME = 'TEST';
const int VERSION = 1;

class Test {
  fail(message) => (e) {
    guardAsync(() {
      expect(false, isTrue, reason: 'IndexedDB failure: $message');
    });
  };

  _createObjectStore(db) {
    try {
      // Nuke object store if it already exists.
      db.deleteObjectStore(STORE_NAME);
    }
    on IDBDatabaseException catch(e) { }  // Chrome
    on DOMException catch(e) { }          // Firefox
    db.createObjectStore(STORE_NAME);
  }

  var db;

  _openDb(afterOpen()) {
    var request = window.indexedDB.open(DB_NAME, VERSION);
    if (request is IDBOpenDBRequest) {
      // New upgrade protocol.
      request.on.success.add(expectAsync1((e) {
            db = e.target.result;
            afterOpen();
          }));
      request.on.upgradeNeeded.add((e) {
          guardAsync(() {
              _createObjectStore(e.target.result);
            });
        });
      request.on.error.add(fail('open'));
    } else {
      // Legacy setVersion upgrade protocol.
      request.on.success.add(expectAsync1((e) {
            db = e.target.result;
            if (db.version != '$VERSION') {
              var setRequest = db.setVersion('$VERSION');
              setRequest.on.success.add(
                  expectAsync1((e) {
                      _createObjectStore(db);
                      var transaction = e.target.result;
                      transaction.on.complete.add(
                          expectAsync1((e) => afterOpen()));
                      transaction.on.error.add(fail('Upgrade'));
                    }));
              setRequest.on.error.add(fail('setVersion error'));
            } else {
              afterOpen();
            }
          }));
      request.on.error.add(fail('open'));
    }
  }

  _createAndOpenDb(afterOpen()) {
    var request = window.indexedDB.deleteDatabase(DB_NAME);
    request.on.success.add(expectAsync1((e) { _openDb(afterOpen); }));
    request.on.error.add(fail('delete old Db'));
  }

  writeItems(int index) {
    if (index < 100) {
      var transaction = db.transaction([STORE_NAME], 'readwrite');
      var request = transaction.objectStore(STORE_NAME)
          .put('Item $index', index);
      request.on.success.add(expectAsync1((e) {
          writeItems(index + 1);
        }
      ));
      request.on.error.add(fail('put'));
    }
  }

  setupDb() { _createAndOpenDb(() => writeItems(0)); }

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
        expect(cursor.value, 'Item ${cursor.key}');
        cursor.continueFunction();
      } else {
        // Done
        expect(firstKey, expectedFirst);
        expect(lastKey, expectedLast);
        if (expectedFirst == null) {
          expect(itemCount, isZero);
        } else {
          expect(itemCount, expectedLast - expectedFirst + 1);
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
  // OPTIONALS lower2() => testRange(new IDBKeyRange.lowerBound(40, open: true), 41, 99);
  lower2() => testRange(new IDBKeyRange.lowerBound(40, true), 41, 99);
  // OPTIONALS lower3() => testRange(new IDBKeyRange.lowerBound(40, open: false), 40, 99);
  lower3() => testRange(new IDBKeyRange.lowerBound(40, false), 40, 99);

  upper1() => testRange(new IDBKeyRange.upperBound(40), 0, 40);
  // OPTIONALS upper2() => testRange(new IDBKeyRange.upperBound(40, open: true), 0, 39);
  upper2() => testRange(new IDBKeyRange.upperBound(40, true), 0, 39);
  // upper3() => testRange(new IDBKeyRange.upperBound(40, open: false), 0, 40);
  upper3() => testRange(new IDBKeyRange.upperBound(40, false), 0, 40);

  bound1() => testRange(new IDBKeyRange.bound(20, 30), 20, 30);

  bound2() => testRange(new IDBKeyRange.bound(-100, 200), 0, 99);

  bound3() =>
      // OPTIONALS testRange(new IDBKeyRange.bound(20, 30, upperOpen: true),
      testRange(new IDBKeyRange.bound(20, 30, false, true),
                         20, 29);

  bound4() =>
      // OPTIONALS testRange(new IDBKeyRange.bound(20, 30, lowerOpen: true),
      testRange(new IDBKeyRange.bound(20, 30, true),
                         21, 30);

  bound5() =>
      // OPTIONALS testRange(new IDBKeyRange.bound(20, 30, lowerOpen: true, upperOpen: true),
      testRange(new IDBKeyRange.bound(20, 30, true, true),
                         21, 29);

}

main() {
  useHtmlConfiguration();

  var test_ = new Test();
  test('prepare', test_.setupDb);

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
