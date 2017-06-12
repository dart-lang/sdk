library WebDBTest;

import 'dart:async';
import 'dart:html';
import 'dart:web_sql';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';

Future<SqlTransaction> transaction(SqlDatabase db) {
  final completer = new Completer<SqlTransaction>.sync();

  db.transaction((SqlTransaction transaction) {
    completer.complete(transaction);
  }, (SqlError error) {
    completer.completeError(error);
  });

  return completer.future;
}

Future<SqlResultSet> createTable(
    SqlTransaction transaction, String tableName, String columnName) {
  final completer = new Completer<SqlResultSet>.sync();

  final sql = 'CREATE TABLE $tableName ($columnName)';
  transaction.executeSql(sql, [], (SqlTransaction tx, SqlResultSet rs) {
    completer.complete(rs);
  }, (SqlTransaction tx, SqlError error) {
    completer.completeError(error);
  });

  return completer.future;
}

Future<SqlResultSet> insert(
    SqlTransaction transaction, String tableName, String columnName, value) {
  final completer = new Completer<SqlResultSet>.sync();

  final sql = 'INSERT INTO $tableName ($columnName) VALUES (?)';
  transaction.executeSql(sql, [value], (SqlTransaction tx, SqlResultSet rs) {
    completer.complete(rs);
  }, (SqlTransaction tx, SqlError error) {
    completer.completeError(error);
  });

  return completer.future;
}

Future<SqlResultSet> queryTable(SqlTransaction transaction, String tableName) {
  final completer = new Completer<SqlResultSet>.sync();

  final sql = 'SELECT * FROM $tableName';
  transaction.executeSql(sql, [], (SqlTransaction tx, SqlResultSet rs) {
    completer.complete(rs);
  }, (SqlTransaction tx, SqlError error) {
    completer.completeError(error);
  });

  return completer.future;
}

Future<SqlResultSet> dropTable(SqlTransaction transaction, String tableName,
    [bool ignoreFailure = false]) {
  final completer = new Completer<SqlResultSet>.sync();

  final sql = 'DROP TABLE $tableName';
  transaction.executeSql(sql, [], (SqlTransaction tx, SqlResultSet rs) {
    completer.complete(rs);
  }, (SqlTransaction tx, SqlError error) {
    if (ignoreFailure) {
      completer.complete(null);
    } else {
      completer.completeError(error);
    }
  });

  return completer.future;
}

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(SqlDatabase.supported, true);
    });
  });

  group('functional', () {
    test('unsupported throws', () {
      var expectation = SqlDatabase.supported ? returnsNormally : throws;
      expect(() {
        window.openDatabase('test_db', '1.0', 'test_db', 1024 * 1024);
      }, expectation);
    });
    test('Web Database', () {
      // Skip if not supported.
      if (!SqlDatabase.supported) {
        return new Future.value();
      }

      final tableName = 'test_table';
      final columnName = 'test_data';

      final db = window.openDatabase('test_db', '1.0', 'test_db', 1024 * 1024);

      expect(db, isNotNull, reason: 'Unable to open database');

      var tx;
      return transaction(db).then((transaction) {
        tx = transaction;
      }).then((_) {
        // Attempt to clear out any tables which may be lurking from previous
        // runs.
        return dropTable(tx, tableName, true);
      }).then((_) {
        return createTable(tx, tableName, columnName);
      }).then((_) {
        return insert(tx, tableName, columnName, 'Some text data');
      }).then((_) {
        return queryTable(tx, tableName);
      }).then((resultSet) {
        expect(resultSet.rows.length, 1);
        var row = resultSet.rows.item(0);
        expect(row.containsKey(columnName), isTrue);
        expect(row[columnName], 'Some text data');
        expect(resultSet.rows[0], row);
      }).then((_) {
        return dropTable(tx, tableName);
      });
    });
  });
}
