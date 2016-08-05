dart_library.library('lib/html/indexeddb_1_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__indexeddb_1_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const indexed_db = dart_sdk.indexed_db;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const unittest$ = unittest.unittest;
  const html_individual_config = unittest.html_individual_config;
  const src__matcher__throws_matcher = unittest.src__matcher__throws_matcher;
  const indexeddb_1_test = Object.create(null);
  let FutureOfDatabase = () => (FutureOfDatabase = dart.constFn(async.Future$(indexed_db.Database)))();
  let FutureOfIdbFactory = () => (FutureOfIdbFactory = dart.constFn(async.Future$(indexed_db.IdbFactory)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let JSArrayOfint = () => (JSArrayOfint = dart.constFn(_interceptors.JSArray$(core.int)))();
  let JSArrayOfbool = () => (JSArrayOfbool = dart.constFn(_interceptors.JSArray$(core.bool)))();
  let VoidToString = () => (VoidToString = dart.constFn(dart.definiteFunctionType(core.String, [])))();
  let DatabaseTodynamic = () => (DatabaseTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [indexed_db.Database])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let dynamicToFutureOfDatabase = () => (dynamicToFutureOfDatabase = dart.constFn(dart.definiteFunctionType(FutureOfDatabase(), [dart.dynamic])))();
  let IdbFactoryToFutureOfDatabase = () => (IdbFactoryToFutureOfDatabase = dart.constFn(dart.definiteFunctionType(FutureOfDatabase(), [indexed_db.IdbFactory])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidToFutureOfIdbFactory = () => (VoidToFutureOfIdbFactory = dart.constFn(dart.definiteFunctionType(FutureOfIdbFactory(), [])))();
  let dynamicAnddynamicAnddynamic__Todynamic = () => (dynamicAnddynamicAnddynamic__Todynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic, dart.dynamic, dart.dynamic], [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic])))();
  let DatabaseToFuture = () => (DatabaseToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [indexed_db.Database])))();
  let DatabaseToFutureOfDatabase = () => (DatabaseToFutureOfDatabase = dart.constFn(dart.definiteFunctionType(FutureOfDatabase(), [indexed_db.Database])))();
  let dynamicTobool = () => (dynamicTobool = dart.constFn(dart.definiteFunctionType(core.bool, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  let VoidTovoid = () => (VoidTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [])))();
  indexeddb_1_test.STORE_NAME = 'TEST';
  indexeddb_1_test.VERSION = 1;
  indexeddb_1_test.databaseNameIndex = 0;
  indexeddb_1_test.nextDatabaseName = function() {
    return dart.str`Test1_${(() => {
      let x = indexeddb_1_test.databaseNameIndex;
      indexeddb_1_test.databaseNameIndex = dart.notNull(x) + 1;
      return x;
    })()}`;
  };
  dart.fn(indexeddb_1_test.nextDatabaseName, VoidToString());
  indexeddb_1_test.testUpgrade = function() {
    let dbName = indexeddb_1_test.nextDatabaseName();
    let upgraded = false;
    return html.window[dartx.indexedDB][dartx.deleteDatabase](dbName).then(FutureOfDatabase())(dart.fn(_ => html.window[dartx.indexedDB][dartx.open](dbName, {version: 1, onUpgradeNeeded: dart.fn(e => {
      }, dynamicTovoid())}), IdbFactoryToFutureOfDatabase())).then(dart.dynamic)(dart.fn(db => {
      db[dartx.close]();
    }, DatabaseTodynamic())).then(FutureOfDatabase())(dart.fn(_ => html.window[dartx.indexedDB][dartx.open](dbName, {version: 2, onUpgradeNeeded: dart.fn(e => {
        src__matcher__expect.expect(dart.dload(e, 'oldVersion'), 1);
        src__matcher__expect.expect(dart.dload(e, 'newVersion'), 2);
        upgraded = true;
      }, dynamicTovoid())}), dynamicToFutureOfDatabase())).then(dart.dynamic)(dart.fn(_ => {
      src__matcher__expect.expect(upgraded, src__matcher__core_matchers.isTrue);
    }, DatabaseTodynamic()));
  };
  dart.fn(indexeddb_1_test.testUpgrade, VoidToFuture());
  indexeddb_1_test.testReadWrite = function(key, value, matcher, dbName, storeName, version, stringifyResult) {
    if (dbName === void 0) dbName = null;
    if (storeName === void 0) storeName = indexeddb_1_test.STORE_NAME;
    if (version === void 0) version = indexeddb_1_test.VERSION;
    if (stringifyResult === void 0) stringifyResult = false;
    return dart.fn(() => {
      if (dbName == null) {
        dbName = indexeddb_1_test.nextDatabaseName();
      }
      function createObjectStore(e) {
        let store = dart.dsend(dart.dload(dart.dload(e, 'target'), 'result'), 'createObjectStore', storeName);
        src__matcher__expect.expect(store, src__matcher__core_matchers.isNotNull);
      }
      dart.fn(createObjectStore, dynamicTodynamic());
      let db = null;
      return html.window[dartx.indexedDB][dartx.deleteDatabase](core.String._check(dbName)).then(FutureOfDatabase())(dart.fn(_ => html.window[dartx.indexedDB][dartx.open](core.String._check(dbName), {version: core.int._check(version), onUpgradeNeeded: createObjectStore}), IdbFactoryToFutureOfDatabase())).then(dart.dynamic)(dart.fn(result => {
        db = result;
        let transaction = dart.dsend(db, 'transactionList', [storeName], 'readwrite');
        dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'put', value, key);
        return dart.dload(transaction, 'completed');
      }, DatabaseTodynamic())).then(dart.dynamic)(dart.fn(_ => {
        let transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        return dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'getObject', key);
      }, dynamicTodynamic())).then(dart.dynamic)(dart.fn(object => {
        dart.dsend(db, 'close');
        if (dart.test(stringifyResult)) {
          src__matcher__expect.expect(dart.toString(object), matcher);
        } else {
          src__matcher__expect.expect(object, matcher);
        }
      }, dynamicTodynamic())).whenComplete(dart.fn(() => {
        if (db != null) {
          dart.dsend(db, 'close');
        }
        return html.window[dartx.indexedDB][dartx.deleteDatabase](core.String._check(dbName));
      }, VoidToFutureOfIdbFactory()));
    }, VoidToFuture());
  };
  dart.fn(indexeddb_1_test.testReadWrite, dynamicAnddynamicAnddynamic__Todynamic());
  indexeddb_1_test.testReadWriteTyped = function(key, value, matcher, dbName, storeName, version, stringifyResult) {
    if (dbName === void 0) dbName = null;
    if (storeName === void 0) storeName = indexeddb_1_test.STORE_NAME;
    if (version === void 0) version = indexeddb_1_test.VERSION;
    if (stringifyResult === void 0) stringifyResult = false;
    return dart.fn(() => {
      if (dbName == null) {
        dbName = indexeddb_1_test.nextDatabaseName();
      }
      function createObjectStore(e) {
        let store = dart.dsend(dart.dload(dart.dload(e, 'target'), 'result'), 'createObjectStore', storeName);
        src__matcher__expect.expect(store, src__matcher__core_matchers.isNotNull);
      }
      dart.fn(createObjectStore, dynamicTovoid());
      let db = null;
      return html.window[dartx.indexedDB][dartx.deleteDatabase](core.String._check(dbName)).then(FutureOfDatabase())(dart.fn(_ => html.window[dartx.indexedDB][dartx.open](core.String._check(dbName), {version: core.int._check(version), onUpgradeNeeded: createObjectStore}), IdbFactoryToFutureOfDatabase())).then(FutureOfDatabase())(dart.fn(result => {
        db = result;
        let transaction = db[dartx.transactionList](JSArrayOfString().of([core.String._check(storeName)]), 'readwrite');
        transaction[dartx.objectStore](core.String._check(storeName))[dartx.put](value, key);
        return transaction[dartx.completed];
      }, DatabaseToFutureOfDatabase())).then(async.Future)(dart.fn(result => {
        let transaction = db[dartx.transaction](storeName, 'readonly');
        return transaction[dartx.objectStore](core.String._check(storeName))[dartx.getObject](key);
      }, DatabaseToFuture())).then(dart.dynamic)(dart.fn(object => {
        db[dartx.close]();
        if (dart.test(stringifyResult)) {
          src__matcher__expect.expect(dart.toString(object), matcher);
        } else {
          src__matcher__expect.expect(object, matcher);
        }
      }, dynamicTodynamic())).whenComplete(dart.fn(() => {
        if (db != null) {
          db[dartx.close]();
        }
        return html.window[dartx.indexedDB][dartx.deleteDatabase](core.String._check(dbName));
      }, VoidToFutureOfIdbFactory()));
    }, VoidToFuture());
  };
  dart.fn(indexeddb_1_test.testReadWriteTyped, dynamicAnddynamicAnddynamic__Todynamic());
  indexeddb_1_test.testTypes = function(testFunction) {
    unittest$.test('String', unittest$.TestFunction._check(dart.dcall(testFunction, 123, 'Hoot!', src__matcher__core_matchers.equals('Hoot!'))));
    unittest$.test('int', unittest$.TestFunction._check(dart.dcall(testFunction, 123, 12345, src__matcher__core_matchers.equals(12345))));
    unittest$.test('List', unittest$.TestFunction._check(dart.dcall(testFunction, 123, JSArrayOfint().of([1, 2, 3]), src__matcher__core_matchers.equals(JSArrayOfint().of([1, 2, 3])))));
    unittest$.test('List 2', unittest$.TestFunction._check(dart.dcall(testFunction, 123, JSArrayOfint().of([2, 3, 4]), src__matcher__core_matchers.equals(JSArrayOfint().of([2, 3, 4])))));
    unittest$.test('bool', unittest$.TestFunction._check(dart.dcall(testFunction, 123, JSArrayOfbool().of([true, false]), src__matcher__core_matchers.equals(JSArrayOfbool().of([true, false])))));
    unittest$.test('largeInt', unittest$.TestFunction._check(dart.dcall(testFunction, 123, 1371854424211, src__matcher__core_matchers.equals("1371854424211"), null, indexeddb_1_test.STORE_NAME, indexeddb_1_test.VERSION, true)));
    unittest$.test('largeDoubleConvertedToInt', unittest$.TestFunction._check(dart.dcall(testFunction, 123, 1371854424211.0, src__matcher__core_matchers.equals("1371854424211"), null, indexeddb_1_test.STORE_NAME, indexeddb_1_test.VERSION, true)));
    unittest$.test('largeIntInMap', unittest$.TestFunction._check(dart.dcall(testFunction, 123, dart.map({time: 4503599627370492}, core.String, core.int), src__matcher__core_matchers.equals("{time: 4503599627370492}"), null, indexeddb_1_test.STORE_NAME, indexeddb_1_test.VERSION, true)));
    let now = new core.DateTime.now();
    unittest$.test('DateTime', unittest$.TestFunction._check(dart.dcall(testFunction, 123, now, src__matcher__core_matchers.predicate(dart.fn(date => dart.equals(dart.dload(date, 'millisecondsSinceEpoch'), now.millisecondsSinceEpoch), dynamicTobool())))));
  };
  dart.fn(indexeddb_1_test.testTypes, dynamicTovoid());
  indexeddb_1_test.main = function() {
    html_individual_config.useHtmlIndividualConfiguration();
    unittest$.group('supported', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(indexed_db.IdbFactory[dartx.supported], true);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('supportsDatabaseNames', dart.fn(() => {
      unittest$.test('supported', dart.fn(() => {
        src__matcher__expect.expect(html.window[dartx.indexedDB][dartx.supportsDatabaseNames], src__matcher__core_matchers.isTrue);
      }, VoidTodynamic()));
    }, VoidTovoid()));
    unittest$.group('functional', dart.fn(() => {
      unittest$.test('throws when unsupported', dart.fn(() => {
        let expectation = dart.test(indexed_db.IdbFactory[dartx.supported]) ? src__matcher__core_matchers.returnsNormally : src__matcher__throws_matcher.throws;
        src__matcher__expect.expect(dart.fn(() => {
          let db = html.window[dartx.indexedDB];
          db[dartx.open]('random_db');
        }, VoidTodynamic()), expectation);
      }, VoidTodynamic()));
      if (dart.test(indexed_db.IdbFactory[dartx.supported])) {
        unittest$.test('upgrade', indexeddb_1_test.testUpgrade);
        unittest$.group('dynamic', dart.fn(() => {
          indexeddb_1_test.testTypes(indexeddb_1_test.testReadWrite);
        }, VoidTovoid()));
        unittest$.group('typed', dart.fn(() => {
          indexeddb_1_test.testTypes(indexeddb_1_test.testReadWriteTyped);
        }, VoidTovoid()));
      }
    }, VoidTovoid()));
  };
  dart.fn(indexeddb_1_test.main, VoidTodynamic());
  // Exports:
  exports.indexeddb_1_test = indexeddb_1_test;
});
