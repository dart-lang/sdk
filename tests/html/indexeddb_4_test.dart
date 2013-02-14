library IndexedDB4Test;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:async';
import 'dart:html' as html;
import 'dart:indexed_db';
import 'utils.dart';

// Test for KeyRange and Cursor.

const String DB_NAME = 'Test';
const String STORE_NAME = 'TEST';
const int VERSION = 1;

Future<Database> createAndOpenDb() {
  return html.window.indexedDB.deleteDatabase(DB_NAME).then((_) {
    return html.window.indexedDB.open(DB_NAME, version: VERSION,
        onUpgradeNeeded: (e) {
          var db = e.target.result;
          db.createObjectStore(STORE_NAME);
        });
  });
}

Future<Database> writeItems(Database db) {
  Future<Object> write(index) {
    var transaction = db.transaction([STORE_NAME], 'readwrite');
    return transaction.objectStore(STORE_NAME).put('Item $index', index);
  }

  var future = write(0);
  for (var i = 1; i < 100; ++i) {
    future = future.then((_) => write(i));
  }

  // Chain on the DB so we return it at the end.
  return future.then((_) => db);
}

Future<Database> setupDb() {
  return createAndOpenDb().then(writeItems);
}

testRange(db, range, expectedFirst, expectedLast) {
  Transaction txn = db.transaction(STORE_NAME, 'readonly');
  ObjectStore objectStore = txn.objectStore(STORE_NAME);
  var cursors = objectStore.openCursor(range: range, autoAdvance: true)
      .asBroadcastStream();

  int lastKey;
  cursors.listen((cursor) {
    lastKey = cursor.key;
  });

  if (expectedFirst != null) {
    cursors.first.then((cursor) {
      expect(cursor.key, expectedFirst);
    });
  }
  if (expectedLast != null) {
    cursors.last.then((cursor) {
      expect(lastKey, expectedLast);
    });
  }

  return cursors.length.then((length) {
    if (expectedFirst == null) {
      expect(length, isZero);
    } else {
      expect(length, expectedLast - expectedFirst + 1);
    }
  });
}

main() {
  useHtmlConfiguration();

  // Don't bother with these tests if it's unsupported.
  // Support is tested in indexeddb_1_test
  if (IdbFactory.supported) {
    var db;
    futureTest('prepare', () {
      return setupDb().then((result) {
          db = result;
        });
    });

    futureTest('only1', () => testRange(db, new KeyRange.only(55), 55, 55));

    futureTest('only1', () => testRange(db, new KeyRange.only(55), 55, 55));
    futureTest('only2', () => testRange(db, new KeyRange.only(100), null, null));
    futureTest('only3', () => testRange(db, new KeyRange.only(-1), null, null));

    futureTest('lower1', () =>
        testRange(db, new KeyRange.lowerBound(40), 40, 99));
    // OPTIONALS lower2() => testRange(db, new KeyRange.lowerBound(40, open: true), 41, 99);
    futureTest('lower2', () =>
        testRange(db, new KeyRange.lowerBound(40, true), 41, 99));
    // OPTIONALS lower3() => testRange(db, new KeyRange.lowerBound(40, open: false), 40, 99);
    futureTest('lower3', () =>
        testRange(db, new KeyRange.lowerBound(40, false), 40, 99));

    futureTest('upper1', () =>
        testRange(db, new KeyRange.upperBound(40), 0, 40));
    // OPTIONALS upper2() => testRange(db, new KeyRange.upperBound(40, open: true), 0, 39);
    futureTest('upper2', () =>
        testRange(db, new KeyRange.upperBound(40, true), 0, 39));
    // upper3() => testRange(db, new KeyRange.upperBound(40, open: false), 0, 40);
    futureTest('upper3', () =>
        testRange(db, new KeyRange.upperBound(40, false), 0, 40));

    futureTest('bound1', () =>
        testRange(db, new KeyRange.bound(20, 30), 20, 30));

    futureTest('bound2', () =>
        testRange(db, new KeyRange.bound(-100, 200), 0, 99));

    bound3() =>
        // OPTIONALS testRange(db, new KeyRange.bound(20, 30, upperOpen: true),
        testRange(db, new KeyRange.bound(20, 30, false, true), 20, 29);

    bound4() =>
        // OPTIONALS testRange(db, new KeyRange.bound(20, 30, lowerOpen: true),
        testRange(db, new KeyRange.bound(20, 30, true), 21, 30);

    bound5() =>
        // OPTIONALS testRange(db, new KeyRange.bound(20, 30, lowerOpen: true, upperOpen: true),
        testRange(db, new KeyRange.bound(20, 30, true, true), 21, 29);
  }
}
