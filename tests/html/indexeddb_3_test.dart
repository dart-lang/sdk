#library('IndexedDB3Test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

// Read with cursor.

const String DB_NAME = 'Test';
const String STORE_NAME = 'TEST';
const String VERSION = '1';

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
        } on IDBDatabaseException catch(e) { }
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
      request.on.success.add(expectAsync1((e) {
          writeItems(index + 1);
        }
      ));
      request.on.error.add(fail('put'));
    }
  }

  fail(message) => (e) {
    guardAsync(() {
      Expect.fail('IndexedDB failure: $message'); 
    });
  };

  readAllViaCursor() {
    IDBTransaction txn = db.transaction(STORE_NAME, 'readonly');
    IDBObjectStore objectStore = txn.objectStore(STORE_NAME);
    IDBRequest cursorRequest = objectStore.openCursor();
    int itemCount = 0;
    int sumKeys = 0;
    int lastKey = null;
    cursorRequest.on.success.add(expectAsync1((e) {
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
      }
    }, count:101));
    cursorRequest.on.error.add(fail('openCursor'));
  }

  readAllReversedViaCursor() {
    IDBTransaction txn = db.transaction(STORE_NAME, 'readonly');
    IDBObjectStore objectStore = txn.objectStore(STORE_NAME);
    // TODO: create a IDBKeyRange(0,100)
    IDBRequest cursorRequest = objectStore.openCursor(null, 'prev');
    int itemCount = 0;
    int sumKeys = 0;
    int lastKey = null;
    cursorRequest.on.success.add(expectAsync1((e) {
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
      }
    }, count:101));
    cursorRequest.on.error.add(fail('openCursor'));
  }
}

main() {
  useHtmlConfiguration();

  var test_ = new Test();
  test('prepare', test_.start);
  test('readAll1', test_.readAllViaCursor);
  test('readAll2', test_.readAllReversedViaCursor);
}
