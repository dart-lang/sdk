#library('WebDBTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');

void fail(message) {
  guardAsync(() {
      Expect.fail(message);
    });
}

Future<SQLTransaction> createTransaction(Database db) {
  final completer = new Completer<SQLTransaction>();

  db.transaction((SQLTransaction transaction) {
    completer.complete(transaction);
  });

  return completer.future;
}

createTable(tableName, columnName) => (SQLTransaction transaction) {
  final completer = new Completer<SQLTransaction>();

  final sql = 'CREATE TABLE $tableName ($columnName)';
  transaction.executeSql(sql, [],
    (SQLTransaction tx, SQLResultSet rs) {
      completer.complete(transaction);
    },
    (SQLTransaction tx, SQLError error) {
      fail(error.message);
    });

  return completer.future;
};

insert(tableName, columnName, value) => (SQLTransaction transaction) {
  final completer = new Completer<SQLTransaction>();

  final sql = 'INSERT INTO $tableName ($columnName) VALUES (?)';
  transaction.executeSql(sql, [value],
    (SQLTransaction tx, SQLResultSet rs) {
      completer.complete(tx);
    },
    (SQLTransaction tx, SQLError error) {
      fail(error.message);
    });

  return completer.future;
};

queryTable(tableName, callback) => (SQLTransaction transaction) {
  final completer = new Completer<SQLTransaction>();

  final sql = 'SELECT * FROM $tableName';
  transaction.executeSql(sql, [],
    (SQLTransaction tx, SQLResultSet rs) {
      callback(rs);
      completer.complete(tx);
    },
    (SQLTransaction tx, SQLError error) {
      fail(error.message);
    });

  return completer.future;
};

dropTable(tableName, [bool ignoreFailure = false]) =>
    (SQLTransaction transaction) {
  final completer = new Completer<SQLTransaction>();

  final sql = 'DROP TABLE $tableName';
  transaction.executeSql(sql, [],
    (SQLTransaction tx, SQLResultSet rs) {
      completer.complete(tx);
    },
    (SQLTransaction tx, SQLError error) {
      if (ignoreFailure) {
        completer.complete(tx);
      } else {
        fail(error.message);
      }
    });

  return completer.future;
};

main() {
  useHtmlConfiguration();

  test('Web Database', () {
    final tableName = 'test_table';
    final columnName = 'test_data';

    final db = window.openDatabase('test_db', '1.0', 'test_db', 1024 * 1024);

    Expect.isNotNull(db, 'Unable to open database');

    createTransaction(db)
      // Attempt to clear out any tables which may be lurking from previous
      // runs.
      .chain(dropTable(tableName, true))
      .chain(createTable(tableName, columnName))
      .chain(insert(tableName, columnName, 'Some text data'))
      .chain(queryTable(tableName, (resultSet) {
        guardAsync(() {
          Expect.equals(1, resultSet.rows.length);
          var row = resultSet.rows.item(0);
          Expect.isTrue(row.containsKey(columnName));
          Expect.equals('Some text data', row[columnName]);
        });
      }))
      .chain(dropTable(tableName))
      .then(expectAsync1((tx) {}));
  });
}
