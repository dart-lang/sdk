library IndexedDB4Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:indexed_db';

// Test for KeyRange and Cursor.

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
    catch(e) { } // Chrome and Firefox
    db.createObjectStore(STORE_NAME);
  }

  var db;

  _openDb(afterOpen()) {
    var request = window.indexedDB.open(DB_NAME, VERSION);
    if (request is OpenDBRequest) {
      // New upgrade protocol.
      request.onSuccess.listen(expectAsync1((e) {
            db = e.target.result;
            afterOpen();
          }));
      request.onUpgradeNeeded.listen((e) {
          guardAsync(() {
              _createObjectStore(e.target.result);
            });
        });
      request.onError.listen(fail('open'));
    } else {
      // Legacy setVersion upgrade protocol.
      request.onSuccess.listen(expectAsync1((e) {
            db = e.target.result;
            if (db.version != '$VERSION') {
              var setRequest = db.setVersion('$VERSION');
              setRequest.onSuccess.listen(
                  expectAsync1((e) {
                      _createObjectStore(db);
                      var transaction = e.target.result;
                      transaction.onComplete.listen(
                          expectAsync1((e) => afterOpen()));
                      transaction.onError.listen(fail('Upgrade'));
                    }));
              setRequest.onError.listen(fail('setVersion error'));
            } else {
              afterOpen();
            }
          }));
      request.onError.listen(fail('open'));
    }
  }

  _createAndOpenDb(afterOpen()) {
    var request = window.indexedDB.deleteDatabase(DB_NAME);
    request.onSuccess.listen(expectAsync1((e) { _openDb(afterOpen); }));
    request.onError.listen(fail('delete old Db'));
  }

  writeItems(int index) {
    if (index < 100) {
      var transaction = db.transaction([STORE_NAME], 'readwrite');
      var request = transaction.objectStore(STORE_NAME)
          .put('Item $index', index);
      request.onSuccess.listen(expectAsync1((e) {
          writeItems(index + 1);
        }
      ));
      request.onError.listen(fail('put'));
    }
  }

  setupDb() { _createAndOpenDb(() => writeItems(0)); }

  testRange(range, expectedFirst, expectedLast) {
    Transaction txn = db.transaction(STORE_NAME, 'readonly');
    ObjectStore objectStore = txn.objectStore(STORE_NAME);
    Request cursorRequest = objectStore.openCursor(range);
    int itemCount = 0;
    int firstKey = null;
    int lastKey = null;
    cursorRequest.onSuccess.listen(expectAsync1((e) {
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
    cursorRequest.onError.listen(fail('openCursor'));
  }

  only1() => testRange(new KeyRange.only(55), 55, 55);
  only2() => testRange(new KeyRange.only(100), null, null);
  only3() => testRange(new KeyRange.only(-1), null, null);

  lower1() => testRange(new KeyRange.lowerBound(40), 40, 99);
  // OPTIONALS lower2() => testRange(new KeyRange.lowerBound(40, open: true), 41, 99);
  lower2() => testRange(new KeyRange.lowerBound(40, true), 41, 99);
  // OPTIONALS lower3() => testRange(new KeyRange.lowerBound(40, open: false), 40, 99);
  lower3() => testRange(new KeyRange.lowerBound(40, false), 40, 99);

  upper1() => testRange(new KeyRange.upperBound(40), 0, 40);
  // OPTIONALS upper2() => testRange(new KeyRange.upperBound(40, open: true), 0, 39);
  upper2() => testRange(new KeyRange.upperBound(40, true), 0, 39);
  // upper3() => testRange(new KeyRange.upperBound(40, open: false), 0, 40);
  upper3() => testRange(new KeyRange.upperBound(40, false), 0, 40);

  bound1() => testRange(new KeyRange.bound(20, 30), 20, 30);

  bound2() => testRange(new KeyRange.bound(-100, 200), 0, 99);

  bound3() =>
      // OPTIONALS testRange(new KeyRange.bound(20, 30, upperOpen: true),
      testRange(new KeyRange.bound(20, 30, false, true),
                         20, 29);

  bound4() =>
      // OPTIONALS testRange(new KeyRange.bound(20, 30, lowerOpen: true),
      testRange(new KeyRange.bound(20, 30, true),
                         21, 30);

  bound5() =>
      // OPTIONALS testRange(new KeyRange.bound(20, 30, lowerOpen: true, upperOpen: true),
      testRange(new KeyRange.bound(20, 30, true, true),
                         21, 29);

}

main() {
  useHtmlConfiguration();

  // Don't bother with these tests if it's unsupported.
  // Support is tested in indexeddb_1_test
  if (IdbFactory.supported) {
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
}
