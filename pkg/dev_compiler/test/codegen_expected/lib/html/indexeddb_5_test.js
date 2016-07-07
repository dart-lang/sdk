dart_library.library('lib/html/indexeddb_5_test', null, /* Imports */[
  'dart_sdk',
  'unittest'
], function load__indexeddb_5_test(exports, dart_sdk, unittest) {
  'use strict';
  const core = dart_sdk.core;
  const indexed_db = dart_sdk.indexed_db;
  const html = dart_sdk.html;
  const async = dart_sdk.async;
  const _interceptors = dart_sdk._interceptors;
  const dart = dart_sdk.dart;
  const dartx = dart_sdk.dartx;
  const html_config = unittest.html_config;
  const unittest$ = unittest.unittest;
  const src__matcher__expect = unittest.src__matcher__expect;
  const src__matcher__core_matchers = unittest.src__matcher__core_matchers;
  const indexeddb_5_test = Object.create(null);
  let FutureOfDatabase = () => (FutureOfDatabase = dart.constFn(async.Future$(indexed_db.Database)))();
  let ListOfString = () => (ListOfString = dart.constFn(core.List$(core.String)))();
  let JSArrayOfString = () => (JSArrayOfString = dart.constFn(_interceptors.JSArray$(core.String)))();
  let DatabaseTodynamic = () => (DatabaseTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [indexed_db.Database])))();
  let dynamicTovoid = () => (dynamicTovoid = dart.constFn(dart.definiteFunctionType(dart.void, [dart.dynamic])))();
  let IdbFactoryToFutureOfDatabase = () => (IdbFactoryToFutureOfDatabase = dart.constFn(dart.definiteFunctionType(FutureOfDatabase(), [indexed_db.IdbFactory])))();
  let VoidToFuture = () => (VoidToFuture = dart.constFn(dart.definiteFunctionType(async.Future, [])))();
  let ListOfStringTodynamic = () => (ListOfStringTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [ListOfString()])))();
  let dynamicTodynamic = () => (dynamicTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [dart.dynamic])))();
  let VoidTodynamic = () => (VoidTodynamic = dart.constFn(dart.definiteFunctionType(dart.dynamic, [])))();
  indexeddb_5_test.main = function() {
    html_config.useHtmlConfiguration();
    if (!dart.test(indexed_db.IdbFactory[dartx.supported])) {
      return;
    }
    let dbName = 'test_db_5';
    let storeName = 'test_store';
    let indexName = 'name_index';
    let db = null;
    unittest$.test('init', dart.fn(() => html.window[dartx.indexedDB][dartx.deleteDatabase](dbName).then(FutureOfDatabase())(dart.fn(_ => html.window[dartx.indexedDB][dartx.open](dbName, {version: 1, onUpgradeNeeded: dart.fn(e => {
        let db = dart.dload(dart.dload(e, 'target'), 'result');
        let objectStore = dart.dsend(db, 'createObjectStore', storeName, {autoIncrement: true});
        let index = dart.dsend(objectStore, 'createIndex', indexName, 'name_index', {unique: false});
      }, dynamicTovoid())}), IdbFactoryToFutureOfDatabase())).then(dart.dynamic)(dart.fn(database => {
      db = database;
    }, DatabaseTodynamic())), VoidToFuture()));
    if (dart.test(html.window[dartx.indexedDB][dartx.supportsDatabaseNames])) {
      unittest$.test('getDatabaseNames', dart.fn(() => html.window[dartx.indexedDB][dartx.getDatabaseNames]().then(dart.dynamic)(dart.fn(names => {
        src__matcher__expect.expect(names[dartx.contains](dbName), src__matcher__core_matchers.isTrue);
      }, ListOfStringTodynamic())), VoidToFuture()));
    }
    let value = dart.map({name_index: 'one', value: 'add_value'});
    unittest$.test('add/delete', dart.fn(() => {
      let transaction = dart.dsend(db, 'transaction', storeName, 'readwrite');
      let key = null;
      return dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value), 'then', dart.fn(addedKey => {
        key = addedKey;
      }, dynamicTodynamic())), 'then', dart.fn(_ => dart.dload(transaction, 'completed'), dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        return dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'getObject', key);
      }, dynamicTodynamic())), 'then', dart.fn(readValue => {
        src__matcher__expect.expect(dart.dindex(readValue, 'value'), value[dartx.get]('value'));
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transactionList', JSArrayOfString().of([storeName]), 'readwrite');
        return dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'delete', key);
      }, dynamicTodynamic())), 'then', dart.fn(_ => dart.dload(transaction, 'completed'), dynamicTodynamic())), 'then', dart.fn(_ => {
        let transaction = dart.dsend(db, 'transactionList', JSArrayOfString().of([storeName]), 'readonly');
        return dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'count');
      }, dynamicTodynamic())), 'then', dart.fn(count => {
        src__matcher__expect.expect(count, 0);
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('clear/count', dart.fn(() => {
      let transaction = dart.dsend(db, 'transaction', storeName, 'readwrite');
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value);
      return dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dload(transaction, 'completed'), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        return dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'count');
      }, dynamicTodynamic())), 'then', dart.fn(count => {
        src__matcher__expect.expect(count, 1);
      }, dynamicTodynamic())), 'then', dart.fn(_ => dart.dload(transaction, 'completed'), dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transactionList', JSArrayOfString().of([storeName]), 'readwrite');
        dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'clear');
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        let transaction = dart.dsend(db, 'transactionList', JSArrayOfString().of([storeName]), 'readonly');
        return dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'count');
      }, dynamicTodynamic())), 'then', dart.fn(count => {
        src__matcher__expect.expect(count, 0);
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
    unittest$.test('index', dart.fn(() => {
      let transaction = dart.dsend(db, 'transaction', storeName, 'readwrite');
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value);
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value);
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value);
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value);
      return dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dload(transaction, 'completed'), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transactionList', JSArrayOfString().of([storeName]), 'readonly');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        return dart.dsend(index, 'count');
      }, dynamicTodynamic())), 'then', dart.fn(count => {
        src__matcher__expect.expect(count, 4);
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        return dart.dload(dart.dsend(index, 'openCursor', {autoAdvance: true}), 'length');
      }, dynamicTodynamic())), 'then', dart.fn(cursorsLength => {
        src__matcher__expect.expect(cursorsLength, 4);
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        return dart.dload(dart.dsend(index, 'openKeyCursor', {autoAdvance: true}), 'length');
      }, dynamicTodynamic())), 'then', dart.fn(cursorsLength => {
        src__matcher__expect.expect(cursorsLength, 4);
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        return dart.dsend(index, 'get', 'one');
      }, dynamicTodynamic())), 'then', dart.fn(readValue => {
        src__matcher__expect.expect(dart.dindex(readValue, 'value'), value[dartx.get]('value'));
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readwrite');
        dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'clear');
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
    let deleteValue = dart.map({name_index: 'two', value: 'delete_value'});
    let updateValue = dart.map({name_index: 'three', value: 'update_value'});
    let updatedValue = dart.map({name_index: 'three', value: 'updated_value'});
    unittest$.test('cursor', dart.fn(() => {
      let transaction = dart.dsend(db, 'transaction', storeName, 'readwrite');
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', value);
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', deleteValue);
      dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'add', updateValue);
      return dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dsend(dart.dload(transaction, 'completed'), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transactionList', JSArrayOfString().of([storeName]), 'readwrite');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        let cursors = dart.dsend(dart.dsend(index, 'openCursor'), 'asBroadcastStream');
        dart.dsend(cursors, 'listen', dart.fn(cursor => {
          let value = dart.dload(cursor, 'value');
          if (dart.equals(dart.dindex(value, 'value'), 'delete_value')) {
            dart.dsend(dart.dsend(cursor, 'delete'), 'then', dart.fn(_ => {
              dart.dsend(cursor, 'next');
            }, dynamicTodynamic()));
          } else if (dart.equals(dart.dindex(value, 'value'), 'update_value')) {
            dart.dsend(dart.dsend(cursor, 'update', updatedValue), 'then', dart.fn(_ => {
              dart.dsend(cursor, 'next');
            }, dynamicTodynamic()));
          } else {
            dart.dsend(cursor, 'next');
          }
        }, dynamicTodynamic()));
        return dart.dload(cursors, 'last');
      }, dynamicTodynamic())), 'then', dart.fn(_ => dart.dload(transaction, 'completed'), dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        return dart.dsend(index, 'get', 'three');
      }, dynamicTodynamic())), 'then', dart.fn(readValue => {
        src__matcher__expect.expect(dart.dindex(readValue, 'value'), 'updated_value');
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic())), 'then', dart.fn(_ => {
        transaction = dart.dsend(db, 'transaction', storeName, 'readonly');
        let index = dart.dsend(dart.dsend(transaction, 'objectStore', storeName), 'index', indexName);
        return dart.dsend(index, 'get', 'two');
      }, dynamicTodynamic())), 'then', dart.fn(readValue => {
        src__matcher__expect.expect(readValue, src__matcher__core_matchers.isNull);
        return dart.dload(transaction, 'completed');
      }, dynamicTodynamic()));
    }, VoidTodynamic()));
  };
  dart.fn(indexeddb_5_test.main, VoidTodynamic());
  // Exports:
  exports.indexeddb_5_test = indexeddb_5_test;
});
