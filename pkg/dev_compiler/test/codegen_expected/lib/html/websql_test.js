dart_library.library('lib/html/websql_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__websql_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const async = dart_sdk.async;
  const web_sql = dart_sdk.web_sql;
  const _interceptors = dart_sdk._interceptors;
  const html = dart_sdk.html;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_individual_config = unittest.html_individual_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const websql_test = Object.create(null);
  let CompleterOfSqlTransaction = () => (CompleterOfSqlTransaction = dart.constFn(async.Completer$(web_sql.SqlTransaction)))();
  let FutureOfSqlTransaction = () => (FutureOfSqlTransaction = dart.constFn(async.Future$(web_sql.SqlTransaction)))();
  let CompleterOfSqlResultSet = () => (CompleterOfSqlResultSet = dart.constFn(async.Completer$(web_sql.SqlResultSet)))();
  let JSArrayOfObject = () => (JSArrayOfObject = dart.constFn(_interceptors.JSArray$(core.Object)))();
  let FutureOfSqlResultSet = () => (FutureOfSqlResultSet = dart.constFn(async.Future$(web_sql.SqlResultSet)))();
  let SqlTransactionTovoid = () => (SqlTransactionTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [web_sql.SqlTransaction])))();
  let SqlErrorTovoid = () => (SqlErrorTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [web_sql.SqlError])))();
  let SqlDatabaseToFutureOfSqlTransaction = () => (SqlDatabaseToFutureOfSqlTransaction = dart.constFn(dart.definiteFunctionType(FutureOfSqlTransaction(), [web_sql.SqlDatabase])))();
  let SqlTransactionAndSqlResultSetTovoid = () => (SqlTransactionAndSqlResultSetTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [web_sql.SqlTransaction, web_sql.SqlResultSet])))();
  let SqlTransactionAndSqlErrorTovoid = () => (SqlTransactionAndSqlErrorTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [web_sql.SqlTransaction, web_sql.SqlError])))();
  let SqlTransactionAndStringAndStringToFutureOfSqlResultSet = () => (SqlTransactionAndStringAndStringToFutureOfSqlResultSet = dart.constFn(dart.definiteFunctionType(FutureOfSqlResultSet(), [web_sql.SqlTransaction, core.String, core.String])))();
  let SqlTransactionAndStringAndString__ToFutureOfSqlResultSet = () => (SqlTransactionAndStringAndString__ToFutureOfSqlResultSet = dart.constFn(dart.definiteFunctionType(FutureOfSqlResultSet(), [web_sql.SqlTransaction, core.String, core.String, dart.dynamic])))();
  let SqlTransactionAndStringToFutureOfSqlResultSet = () => (SqlTransactionAndStringToFutureOfSqlResultSet = dart.constFn(dart.definiteFunctionType(FutureOfSqlResultSet(), [web_sql.SqlTransaction, core.String])))();
  let SqlTransactionAndString__ToFutureOfSqlResultSet = () => (SqlTransactionAndString__ToFutureOfSqlResultSet = dart.constFn(dart.definiteFunctionType(FutureOfSqlResultSet(), [web_sql.SqlTransaction, core.String], [core.bool])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  let dynamicToFutureOfSqlResultSet = () => (dynamicToFutureOfSqlResultSet = dart.constFn(dart.definiteFunctionType(FutureOfSqlResultSet(), [dart.dynamic])))();
  let SqlResultSetTodynamic = () => (SqlResultSetTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [web_sql.SqlResultSet])))();
  let SqlResultSetToFutureOfSqlResultSet = () => (SqlResultSetToFutureOfSqlResultSet = dart.constFn(dart.definiteFunctionType(FutureOfSqlResultSet(), [web_sql.SqlResultSet])))();
  let SqlTransactionTodynamic = () => (SqlTransactionTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [web_sql.SqlTransaction])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  websql_test.transaction = function(db) {
    let completer = CompleterOfSqlTransaction().sync();
    db[dartx.transaction](dart.fn(transaction => {
      completer.complete(transaction);
    }, SqlTransactionTovoid()), dart.fn(error => {
      completer.completeError(error);
    }, SqlErrorTovoid()));
    return completer.future;
  };
  dart.fn(websql_test.transaction, SqlDatabaseToFutureOfSqlTransaction());
  websql_test.createTable = function(transaction, tableName, columnName) {
    let completer = CompleterOfSqlResultSet().sync();
    let sql = dart.str`CREATE TABLE ${tableName} (${columnName})`;
    transaction[dartx.executeSql](sql, JSArrayOfObject().of([]), dart.fn((tx, rs) => {
      completer.complete(rs);
    }, SqlTransactionAndSqlResultSetTovoid()), dart.fn((tx, error) => {
      completer.completeError(error);
    }, SqlTransactionAndSqlErrorTovoid()));
    return completer.future;
  };
  dart.fn(websql_test.createTable, SqlTransactionAndStringAndStringToFutureOfSqlResultSet());
  websql_test.insert = function(transaction, tableName, columnName, value) {
    let completer = CompleterOfSqlResultSet().sync();
    let sql = dart.str`INSERT INTO ${tableName} (${columnName}) VALUES (?)`;
    transaction[dartx.executeSql](sql, JSArrayOfObject().of([value]), dart.fn((tx, rs) => {
      completer.complete(rs);
    }, SqlTransactionAndSqlResultSetTovoid()), dart.fn((tx, error) => {
      completer.completeError(error);
    }, SqlTransactionAndSqlErrorTovoid()));
    return completer.future;
  };
  dart.fn(websql_test.insert, SqlTransactionAndStringAndString__ToFutureOfSqlResultSet());
  websql_test.queryTable = function(transaction, tableName) {
    let completer = CompleterOfSqlResultSet().sync();
    let sql = dart.str`SELECT * FROM ${tableName}`;
    transaction[dartx.executeSql](sql, JSArrayOfObject().of([]), dart.fn((tx, rs) => {
      completer.complete(rs);
    }, SqlTransactionAndSqlResultSetTovoid()), dart.fn((tx, error) => {
      completer.completeError(error);
    }, SqlTransactionAndSqlErrorTovoid()));
    return completer.future;
  };
  dart.fn(websql_test.queryTable, SqlTransactionAndStringToFutureOfSqlResultSet());
  websql_test.dropTable = function(transaction, tableName, ignoreFailure) {
    if (ignoreFailure === void 0) ignoreFailure = false;
    let completer = CompleterOfSqlResultSet().sync();
    let sql = dart.str`DROP TABLE ${tableName}`;
    transaction[dartx.executeSql](sql, JSArrayOfObject().of([]), dart.fn((tx, rs) => {
      completer.complete(rs);
    }, SqlTransactionAndSqlResultSetTovoid()), dart.fn((tx, error) => {
      if (dart.test(ignoreFailure)) {
        completer.complete(null);
      } else {
        completer.completeError(error);
      }
    }, SqlTransactionAndSqlErrorTovoid()));
    return completer.future;
  };
  dart.fn(websql_test.dropTable, SqlTransactionAndString__ToFutureOfSqlResultSet());
  websql_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(web_sql.SqlDatabase[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('unsupported throws', dart.fn(() => {
        let expectation = dart.test(web_sql.SqlDatabase[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          html.window[dartx.openDatabase]('test_db', '1.0', 'test_db', 1024 * 1024);
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      unittest$.test('Web Database', dart.fn(() => {
        if (!dart.test(web_sql.SqlDatabase[dartx.supported])) {
          return async.Future.value();
        }
        let tableName = 'test_table';
        let columnName = 'test_data';
        let db = html.window[dartx.openDatabase]('test_db', '1.0', 'test_db', 1024 * 1024);
        src__matcher__expect.expect(db, src__matcher__core_matchers.isNotNull, {reason: 'Unable to open database'});
        let tx = null;
        return websql_test.transaction(db).then(dart.dynamic)(dart.fn(transaction => {
          tx = transaction;
        }, SqlTransactionTodynamic())).then(FutureOfSqlResultSet())(dart.fn(_ => websql_test.dropTable(web_sql.SqlTransaction._check(tx), tableName, true), dynamicToFutureOfSqlResultSet())).then(FutureOfSqlResultSet())(dart.fn(_ => websql_test.createTable(web_sql.SqlTransaction._check(tx), tableName, columnName), SqlResultSetToFutureOfSqlResultSet())).then(FutureOfSqlResultSet())(dart.fn(_ => websql_test.insert(web_sql.SqlTransaction._check(tx), tableName, columnName, 'Some text data'), SqlResultSetToFutureOfSqlResultSet())).then(FutureOfSqlResultSet())(dart.fn(_ => websql_test.queryTable(web_sql.SqlTransaction._check(tx), tableName), SqlResultSetToFutureOfSqlResultSet())).then(dart.dynamic)(dart.fn(resultSet => {
          src__matcher__expect.expect(resultSet[dartx.rows][dartx.length], 1);
          let row = resultSet[dartx.rows][dartx.item](0);
          src__matcher__expect.expect(row[dartx.containsKey](columnName), src__matcher__core_matchers.isTrue);
          src__matcher__expect.expect(row[dartx.get](columnName), 'Some text data');
          src__matcher__expect.expect(resultSet[dartx.rows][dartx.get](0), row);
        }, SqlResultSetTodynamic())).then(FutureOfSqlResultSet())(dart.fn(_ => websql_test.dropTable(web_sql.SqlTransaction._check(tx), tableName), dynamicToFutureOfSqlResultSet()));
      }, VoidToFuture()));
    }, VoidTovoid()));
  };
  dart.fn(websql_test.main, VoidTodynamic());
  // Exports:
  exports.websql_test = websql_test;
});
