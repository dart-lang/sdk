#library('IndexedDB3Test');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/dom_config.dart');
#import('dart:dom');
#import('dart:coreimpl');

// Read with cursor.

final String DB_NAME = 'Test';
final String STORE_NAME = 'TEST';
final String VERSION = '1';

class Test {
  var db;

  start() {
    var request = window.webkitIndexedDB.open(DB_NAME);
    Expect.isNotNull(request);
    request.addEventListener('success', initDb);
    request.addEventListener('error', fail('open'));
  }

  initDb(e) {
    db = e.target.result;
    // TODO.  Some browsers do this the w3 way - passing the VERSION to the
    // open call and listening to onversionchange.  Can we feature-detect the
    // difference and make it work?
    var request = db.setVersion(VERSION);
    request.addEventListener('success', (e) {
        try {
          // Nuke object store if it already exists.
          db.deleteObjectStore(STORE_NAME);
        } catch (IDBDatabaseException e) { }
        db.createObjectStore(STORE_NAME);
        writeItems(0);
      });
      request.addEventListener('blocked', fail('setVersion blocked'));
      request.addEventListener('error', fail('setVersion error'));
  }

  writeItems(int index) {
    if (index < 100) {
      var transaction = db.transaction([STORE_NAME], IDBTransaction.READ_WRITE);
      var request = transaction.objectStore(STORE_NAME)
          .put('Item $index', index);
      request.addEventListener('success', (e) { writeItems(index + 1); });
      request.addEventListener('error', fail('put'));
    } else {
      callbackDone();
    }
  }

  fail(message) => (e) {
    callbackDone();
    Expect.fail('IndexedDB failure: $message');
  };

  readAllViaCursor() {
    IDBTransaction txn = db.transaction(STORE_NAME, IDBTransaction.READ_ONLY);
    IDBObjectStore objectStore = txn.objectStore(STORE_NAME);
    IDBRequest cursorRequest = objectStore.openCursor();
    int itemCount = 0;
    int sumKeys = 0;
    int lastKey = null;
    cursorRequest.addEventListener("success", (e) {
        var cursor = e.target.result;
        if (cursor != null) {
          lastKey = cursor.key;
          itemCount += 1;
          sumKeys += cursor.key;
          Expect.equals('Item ${cursor.key}', cursor.value);
          cursor.continueFunction();
        } else {
          // Done
          Expect.equals(99, lastKey);
          Expect.equals(100, itemCount);
          Expect.equals((100 * 99) ~/ 2, sumKeys);
          callbackDone();
        }
      });
    cursorRequest.addEventListener('error', fail('openCursor'));
  }

  readAllReversedViaCursor() {
    IDBTransaction txn = db.transaction(STORE_NAME, IDBTransaction.READ_ONLY);
    IDBObjectStore objectStore = txn.objectStore(STORE_NAME);
    // TODO: create a IDBKeyRange(0,100)
    IDBRequest cursorRequest = objectStore.openCursor(null, IDBCursor.PREV);
    int itemCount = 0;
    int sumKeys = 0;
    int lastKey = null;
    cursorRequest.addEventListener("success", (e) {
        var cursor = e.target.result;
        if (cursor != null) {
          lastKey = cursor.key;
          itemCount += 1;
          sumKeys += cursor.key;
          Expect.equals('Item ${cursor.key}', cursor.value);
          cursor.continueFunction();
        } else {
          // Done
          Expect.equals(0, lastKey);  // i.e. first key (scanned in reverse).
          Expect.equals(100, itemCount);
          Expect.equals((100 * 99) ~/ 2, sumKeys);
          callbackDone();
        }
      });
    cursorRequest.addEventListener('error', fail('openCursor'));
  }
}

main() {
  useDomConfiguration();

  var test = new Test();
  asyncTest('prepare', 1, test.start);
  asyncTest('readAll1', 1, test.readAllViaCursor);
  asyncTest('readAll2', 1, test.readAllReversedViaCursor);
}
