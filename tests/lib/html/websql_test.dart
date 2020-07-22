// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library WebDBTest;

import 'dart:async';
import 'dart:html';
import 'dart:web_sql';

import 'package:async_helper/async_minitest.dart';

Future<SqlResultSet> createTable(
    SqlTransaction transaction, String tableName, String columnName) async {
  return transaction.executeSql('CREATE TABLE $tableName ($columnName)', []);
}

Future<SqlResultSet> insertTable(SqlTransaction transaction, String tableName,
    String columnName, value) async {
  final sql = 'INSERT INTO $tableName ($columnName) VALUES (?)';
  return transaction.executeSql(sql, [value]);
}

Future<SqlResultSet> queryTable(
    SqlTransaction transaction, String tableName) async {
  final sql = 'SELECT * FROM $tableName';
  return transaction.executeSql(sql, []);
}

Future<SqlResultSet?> dropTable(SqlTransaction transaction, String tableName,
    [bool ignoreFailure = false]) async {
  try {
    var result = await transaction.executeSql('DROP TABLE $tableName', []);
    return result;
  } catch (error) {
    if (!ignoreFailure) throw error;
  }
}

final tableName = 'test_table';
final columnName = 'test_data';

late SqlDatabase db;
late SqlTransaction tx;

Future setup() async {
  if (SqlDatabase.supported) {
    db = await window.openDatabase('test_db', '1.0', 'test_db', 1024 * 1024);
    expect(db, isNotNull, reason: 'Unable to open database');

    tx = await db.transaction_future();
    expect(tx, isNotNull, reason: "Transaction not ready");
  }
}

main() async {
  await setup();

  group('Database', () {
    test('Open/Transaction', () async {
      if (!SqlDatabase.supported) return;

      expect(tx, isNotNull, reason: "Transaction not ready");

      // Should not succeed table doesn't exist to be dropped.
      try {
        await dropTable(tx, tableName);
        expect(false, true, reason: "dropTable should fail");
      } on DomException catch (error) {
        expect(error.message,
            "could not prepare statement (1 no such table: test_table)");
      }
    });

    test('create', () async {
      if (!SqlDatabase.supported) return;

      expect(tx, isNotNull, reason: "Transaction not ready");
      try {
        SqlResultSet createResult =
            await createTable(tx, tableName, columnName);
        expect(createResult.insertId, 0);
      } on DomException catch (error) {
        expect(false, true, reason: "createTable failed - ${error.message}");
      }
    });

    test('insert', () async {
      if (!SqlDatabase.supported) return;

      expect(tx, isNotNull, reason: "Transaction not ready");
      try {
        SqlResultSet insertResult =
            await insertTable(tx, tableName, columnName, 'Some text data');
        expect(insertResult.insertId, 1);
        expect(insertResult.rowsAffected, 1);
      } on DomException catch (error) {
        expect(false, true, reason: "insert failed - ${error.message}");
      }
    });

    test('query', () async {
      if (!SqlDatabase.supported) return;

      expect(tx, isNotNull, reason: "Transaction not ready");
      try {
        SqlResultSet queryResult = await queryTable(tx, tableName);
        expect(queryResult.rows!.length, 1);
        expect(queryResult.rows![0]['test_data'], "Some text data");
      } on DomException catch (error) {
        expect(false, true, reason: "queryTable failed - ${error.message}");
      }
    });

    test('cleanup', () async {
      if (!SqlDatabase.supported) return;

      expect(tx, isNotNull, reason: "Transaction not ready");
      await dropTable(tx, tableName, true);
    });
  });
}
