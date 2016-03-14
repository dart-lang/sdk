dart_library.library('dart/indexed_db', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/html_common',
  'dart/_js_helper',
  'dart/async',
  'dart/_interceptors',
  'dart/_metadata',
  'dart/html'
], /* Lazy imports */[
], function(exports, dart, core, html_common, _js_helper, async, _interceptors, _metadata, html) {
  'use strict';
  let dartx = dart.dartx;
  class _KeyRangeFactoryProvider extends core.Object {
    static createKeyRange_only(value) {
      return _KeyRangeFactoryProvider._only(_KeyRangeFactoryProvider._class(), _KeyRangeFactoryProvider._translateKey(value));
    }
    static createKeyRange_lowerBound(bound, open) {
      if (open === void 0) open = false;
      return _KeyRangeFactoryProvider._lowerBound(_KeyRangeFactoryProvider._class(), _KeyRangeFactoryProvider._translateKey(bound), open);
    }
    static createKeyRange_upperBound(bound, open) {
      if (open === void 0) open = false;
      return _KeyRangeFactoryProvider._upperBound(_KeyRangeFactoryProvider._class(), _KeyRangeFactoryProvider._translateKey(bound), open);
    }
    static createKeyRange_bound(lower, upper, lowerOpen, upperOpen) {
      if (lowerOpen === void 0) lowerOpen = false;
      if (upperOpen === void 0) upperOpen = false;
      return _KeyRangeFactoryProvider._bound(_KeyRangeFactoryProvider._class(), _KeyRangeFactoryProvider._translateKey(lower), _KeyRangeFactoryProvider._translateKey(upper), lowerOpen, upperOpen);
    }
    static _class() {
      if (_KeyRangeFactoryProvider._cachedClass != null) return _KeyRangeFactoryProvider._cachedClass;
      return _KeyRangeFactoryProvider._cachedClass = _KeyRangeFactoryProvider._uncachedClass();
    }
    static _uncachedClass() {
      return window.webkitIDBKeyRange || window.mozIDBKeyRange || window.msIDBKeyRange || window.IDBKeyRange;
    }
    static _translateKey(idbkey) {
      return idbkey;
    }
    static _only(cls, value) {
      return dart.as(cls.only(value), KeyRange);
    }
    static _lowerBound(cls, bound, open) {
      return dart.as(cls.lowerBound(bound, open), KeyRange);
    }
    static _upperBound(cls, bound, open) {
      return dart.as(cls.upperBound(bound, open), KeyRange);
    }
    static _bound(cls, lower, upper, lowerOpen, upperOpen) {
      return dart.as(cls.bound(lower, upper, lowerOpen, upperOpen), KeyRange);
    }
  }
  dart.setSignature(_KeyRangeFactoryProvider, {
    statics: () => ({
      createKeyRange_only: [KeyRange, [dart.dynamic]],
      createKeyRange_lowerBound: [KeyRange, [dart.dynamic], [core.bool]],
      createKeyRange_upperBound: [KeyRange, [dart.dynamic], [core.bool]],
      createKeyRange_bound: [KeyRange, [dart.dynamic, dart.dynamic], [core.bool, core.bool]],
      _class: [dart.dynamic, []],
      _uncachedClass: [dart.dynamic, []],
      _translateKey: [dart.dynamic, [dart.dynamic]],
      _only: [KeyRange, [dart.dynamic, dart.dynamic]],
      _lowerBound: [KeyRange, [dart.dynamic, dart.dynamic, dart.dynamic]],
      _upperBound: [KeyRange, [dart.dynamic, dart.dynamic, dart.dynamic]],
      _bound: [KeyRange, [dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic, dart.dynamic]]
    }),
    names: ['createKeyRange_only', 'createKeyRange_lowerBound', 'createKeyRange_upperBound', 'createKeyRange_bound', '_class', '_uncachedClass', '_translateKey', '_only', '_lowerBound', '_upperBound', '_bound']
  });
  _KeyRangeFactoryProvider._cachedClass = null;
  function _convertNativeToDart_IDBKey(nativeKey) {
    function containsDate(object) {
      if (dart.notNull(html_common.isJavaScriptDate(object))) return true;
      if (dart.is(object, core.List)) {
        for (let i = 0; i < dart.notNull(object[dartx.length]); i++) {
          if (dart.notNull(dart.as(containsDate(object[dartx.get](i)), core.bool))) return true;
        }
      }
      return false;
    }
    dart.fn(containsDate);
    if (dart.notNull(dart.as(containsDate(nativeKey), core.bool))) {
      dart.throw(new core.UnimplementedError('Key containing DateTime'));
    }
    return nativeKey;
  }
  dart.fn(_convertNativeToDart_IDBKey);
  function _convertDartToNative_IDBKey(dartKey) {
    return dartKey;
  }
  dart.fn(_convertDartToNative_IDBKey);
  function _convertNativeToDart_IDBAny(object) {
    return html_common.convertNativeToDart_AcceptStructuredClone(object, {mustCopy: false});
  }
  dart.fn(_convertNativeToDart_IDBAny);
  const _idbKey = 'JSExtendableArray|=Object|num|String';
  const _annotation_Creates_IDBKey = dart.const(new _js_helper.Creates(_idbKey));
  const _annotation_Returns_IDBKey = dart.const(new _js_helper.Returns(_idbKey));
  const _delete = Symbol('_delete');
  const _update = Symbol('_update');
  const _update_1 = Symbol('_update_1');
  dart.defineExtensionNames([
    'delete',
    'update',
    'next',
    'advance',
    'continuePrimaryKey',
    'direction',
    'key',
    'primaryKey',
    'source'
  ]);
  class Cursor extends _interceptors.Interceptor {
    [dartx.delete]() {
      try {
        return _completeRequest(this[_delete]());
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.update](value) {
      try {
        return _completeRequest(this[_update](value));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.next](key) {
      if (key === void 0) key = null;
      if (key == null) {
        this.continue();
      } else {
        this.continue(key);
      }
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.direction]() {
      return this.direction;
    }
    get [dartx.key]() {
      return this.key;
    }
    get [dartx.primaryKey]() {
      return this.primaryKey;
    }
    get [dartx.source]() {
      return this.source;
    }
    [dartx.advance](count) {
      return this.advance(count);
    }
    [dartx.continuePrimaryKey](key, primaryKey) {
      return this.continuePrimaryKey(key, primaryKey);
    }
    [_delete]() {
      return this.delete();
    }
    [_update](value) {
      let value_1 = html_common.convertDartToNative_SerializedScriptValue(value);
      return this[_update_1](value_1);
    }
    [_update_1](value) {
      return this.update(value);
    }
  }
  dart.setSignature(Cursor, {
    constructors: () => ({_: [Cursor, []]}),
    methods: () => ({
      [dartx.delete]: [async.Future, []],
      [dartx.update]: [async.Future, [dart.dynamic]],
      [dartx.next]: [dart.void, [], [core.Object]],
      [dartx.advance]: [dart.void, [core.int]],
      [dartx.continuePrimaryKey]: [dart.void, [core.Object, core.Object]],
      [_delete]: [Request, []],
      [_update]: [Request, [dart.dynamic]],
      [_update_1]: [Request, [dart.dynamic]]
    })
  });
  Cursor[dart.metadata] = () => [dart.const(new _metadata.DomName('IDBCursor')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBCursor"))];
  dart.registerExtension(dart.global.IDBCursor, Cursor);
  const _get_value = Symbol('_get_value');
  dart.defineExtensionNames([
    'value'
  ]);
  class CursorWithValue extends Cursor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.value]() {
      return _convertNativeToDart_IDBAny(this[_get_value]);
    }
    get [_get_value]() {
      return this.value;
    }
  }
  dart.setSignature(CursorWithValue, {
    constructors: () => ({_: [CursorWithValue, []]})
  });
  CursorWithValue[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('IDBCursorWithValue')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBCursorWithValue"))];
  dart.registerExtension(dart.global.IDBCursorWithValue, CursorWithValue);
  const _createObjectStore = Symbol('_createObjectStore');
  const _transaction = Symbol('_transaction');
  const _createObjectStore_1 = Symbol('_createObjectStore_1');
  const _createObjectStore_2 = Symbol('_createObjectStore_2');
  dart.defineExtensionNames([
    'createObjectStore',
    'transaction',
    'transactionStore',
    'transactionList',
    'transactionStores',
    'close',
    'deleteObjectStore',
    'onAbort',
    'onClose',
    'onError',
    'onVersionChange',
    'name',
    'objectStoreNames',
    'version'
  ]);
  class Database extends html.EventTarget {
    [dartx.createObjectStore](name, opts) {
      let keyPath = opts && 'keyPath' in opts ? opts.keyPath : null;
      let autoIncrement = opts && 'autoIncrement' in opts ? opts.autoIncrement : null;
      let options = dart.map();
      if (keyPath != null) {
        options[dartx.set]('keyPath', keyPath);
      }
      if (autoIncrement != null) {
        options[dartx.set]('autoIncrement', autoIncrement);
      }
      return this[_createObjectStore](name, options);
    }
    [dartx.transaction](storeName_OR_storeNames, mode) {
      if (mode != 'readonly' && mode != 'readwrite') {
        dart.throw(new core.ArgumentError(mode));
      }
      return this[_transaction](storeName_OR_storeNames, mode);
    }
    [dartx.transactionStore](storeName, mode) {
      if (mode != 'readonly' && mode != 'readwrite') {
        dart.throw(new core.ArgumentError(mode));
      }
      return this[_transaction](storeName, mode);
    }
    [dartx.transactionList](storeNames, mode) {
      if (mode != 'readonly' && mode != 'readwrite') {
        dart.throw(new core.ArgumentError(mode));
      }
      let storeNames_1 = html_common.convertDartToNative_StringArray(storeNames);
      return this[_transaction](storeNames_1, mode);
    }
    [dartx.transactionStores](storeNames, mode) {
      if (mode != 'readonly' && mode != 'readwrite') {
        dart.throw(new core.ArgumentError(mode));
      }
      return this[_transaction](storeNames, mode);
    }
    [_transaction](stores, mode) {
      return this.transaction(stores, mode);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.name]() {
      return this.name;
    }
    get [dartx.objectStoreNames]() {
      return this.objectStoreNames;
    }
    get [dartx.version]() {
      return this.version;
    }
    [dartx.close]() {
      return this.close();
    }
    [_createObjectStore](name, options) {
      if (options === void 0) options = null;
      if (options != null) {
        let options_1 = html_common.convertDartToNative_Dictionary(options);
        return this[_createObjectStore_1](name, options_1);
      }
      return this[_createObjectStore_2](name);
    }
    [_createObjectStore_1](name, options) {
      return this.createObjectStore(name, options);
    }
    [_createObjectStore_2](name) {
      return this.createObjectStore(name);
    }
    [dartx.deleteObjectStore](name) {
      return this.deleteObjectStore(name);
    }
    get [dartx.onAbort]() {
      return Database.abortEvent.forTarget(this);
    }
    get [dartx.onClose]() {
      return Database.closeEvent.forTarget(this);
    }
    get [dartx.onError]() {
      return Database.errorEvent.forTarget(this);
    }
    get [dartx.onVersionChange]() {
      return Database.versionChangeEvent.forTarget(this);
    }
  }
  dart.setSignature(Database, {
    constructors: () => ({_: [Database, []]}),
    methods: () => ({
      [dartx.createObjectStore]: [ObjectStore, [core.String], {keyPath: core.String, autoIncrement: core.bool}],
      [dartx.transaction]: [Transaction, [dart.dynamic, core.String]],
      [dartx.transactionStore]: [Transaction, [core.String, core.String]],
      [dartx.transactionList]: [Transaction, [core.List$(core.String), core.String]],
      [dartx.transactionStores]: [Transaction, [html.DomStringList, core.String]],
      [_transaction]: [Transaction, [dart.dynamic, dart.dynamic]],
      [dartx.close]: [dart.void, []],
      [_createObjectStore]: [ObjectStore, [core.String], [core.Map]],
      [_createObjectStore_1]: [ObjectStore, [dart.dynamic, dart.dynamic]],
      [_createObjectStore_2]: [ObjectStore, [dart.dynamic]],
      [dartx.deleteObjectStore]: [dart.void, [core.String]]
    })
  });
  Database[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('IDBDatabase')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX, '15')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.Experimental()), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBDatabase"))];
  Database.abortEvent = dart.const(new (html.EventStreamProvider$(html.Event))('abort'));
  Database.closeEvent = dart.const(new (html.EventStreamProvider$(html.Event))('close'));
  Database.errorEvent = dart.const(new (html.EventStreamProvider$(html.Event))('error'));
  dart.defineLazyProperties(Database, {
    get versionChangeEvent() {
      return dart.const(new (html.EventStreamProvider$(VersionChangeEvent))('versionchange'));
    }
  });
  dart.registerExtension(dart.global.IDBDatabase, Database);
  const _open = Symbol('_open');
  const _deleteDatabase = Symbol('_deleteDatabase');
  const _webkitGetDatabaseNames = Symbol('_webkitGetDatabaseNames');
  dart.defineExtensionNames([
    'open',
    'deleteDatabase',
    'getDatabaseNames',
    'supportsDatabaseNames',
    'cmp'
  ]);
  class IdbFactory extends _interceptors.Interceptor {
    static get supported() {
      return !!(window.indexedDB || window.webkitIndexedDB || window.mozIndexedDB);
    }
    [dartx.open](name, opts) {
      let version = opts && 'version' in opts ? opts.version : null;
      let onUpgradeNeeded = opts && 'onUpgradeNeeded' in opts ? opts.onUpgradeNeeded : null;
      let onBlocked = opts && 'onBlocked' in opts ? opts.onBlocked : null;
      if (version == null != (onUpgradeNeeded == null)) {
        return async.Future$(Database).error(new core.ArgumentError('version and onUpgradeNeeded must be specified together'));
      }
      try {
        let request = null;
        if (version != null) {
          request = this[_open](name, version);
        } else {
          request = this[_open](name);
        }
        if (onUpgradeNeeded != null) {
          dart.dsend(dart.dload(request, 'onUpgradeNeeded'), 'listen', onUpgradeNeeded);
        }
        if (onBlocked != null) {
          dart.dsend(dart.dload(request, 'onBlocked'), 'listen', onBlocked);
        }
        return dart.as(_completeRequest(dart.as(request, Request)), async.Future$(Database));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future$(Database).error(e, stacktrace);
      }

    }
    [dartx.deleteDatabase](name, opts) {
      let onBlocked = opts && 'onBlocked' in opts ? opts.onBlocked : null;
      try {
        let request = this[_deleteDatabase](name);
        if (onBlocked != null) {
          request[dartx.onBlocked].listen(dart.as(onBlocked, dart.functionType(dart.void, [html.Event])));
        }
        let completer = async.Completer.sync();
        request[dartx.onSuccess].listen(dart.fn(e => {
          completer.complete(this);
        }, dart.void, [html.Event]));
        request[dartx.onError].listen(dart.bind(completer, 'completeError'));
        return dart.as(completer.future, async.Future$(IdbFactory));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future$(IdbFactory).error(e, stacktrace);
      }

    }
    [dartx.getDatabaseNames]() {
      try {
        let request = this[_webkitGetDatabaseNames]();
        return dart.as(_completeRequest(request), async.Future$(core.List$(core.String)));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future$(core.List$(core.String)).error(e, stacktrace);
      }

    }
    get [dartx.supportsDatabaseNames]() {
      return dart.notNull(IdbFactory.supported) && !!(this.getDatabaseNames || this.webkitGetDatabaseNames);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.cmp](first, second) {
      return this.cmp(first, second);
    }
    [_deleteDatabase](name) {
      return this.deleteDatabase(name);
    }
    [_open](name, version) {
      return this.open(name, version);
    }
    [_webkitGetDatabaseNames]() {
      return this.webkitGetDatabaseNames();
    }
  }
  dart.setSignature(IdbFactory, {
    constructors: () => ({_: [IdbFactory, []]}),
    methods: () => ({
      [dartx.open]: [async.Future$(Database), [core.String], {version: core.int, onUpgradeNeeded: dart.functionType(dart.void, [dart.dynamic]), onBlocked: dart.functionType(dart.void, [dart.dynamic])}],
      [dartx.deleteDatabase]: [async.Future$(IdbFactory), [core.String], {onBlocked: dart.functionType(dart.void, [dart.dynamic])}],
      [dartx.getDatabaseNames]: [async.Future$(core.List$(core.String)), []],
      [dartx.cmp]: [core.int, [core.Object, core.Object]],
      [_deleteDatabase]: [OpenDBRequest, [core.String]],
      [_open]: [OpenDBRequest, [core.String], [core.int]],
      [_webkitGetDatabaseNames]: [Request, []]
    })
  });
  IdbFactory[dart.metadata] = () => [dart.const(new _metadata.DomName('IDBFactory')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.FIREFOX, '15')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.IE, '10')), dart.const(new _metadata.Experimental()), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBFactory"))];
  dart.registerExtension(dart.global.IDBFactory, IdbFactory);
  function _completeRequest(request) {
    let completer = async.Completer.sync();
    request[dartx.onSuccess].listen(dart.fn(e => {
      completer.complete(request[dartx.result]);
    }, dart.void, [html.Event]));
    request[dartx.onError].listen(dart.bind(completer, 'completeError'));
    return completer.future;
  }
  dart.fn(_completeRequest, () => dart.definiteFunctionType(async.Future, [Request]));
  const _count = Symbol('_count');
  const _get = Symbol('_get');
  const _getKey = Symbol('_getKey');
  const _openCursor = Symbol('_openCursor');
  const _openKeyCursor = Symbol('_openKeyCursor');
  dart.defineExtensionNames([
    'count',
    'get',
    'getKey',
    'openCursor',
    'openKeyCursor',
    'keyPath',
    'multiEntry',
    'name',
    'objectStore',
    'unique'
  ]);
  class Index extends _interceptors.Interceptor {
    [dartx.count](key_OR_range) {
      if (key_OR_range === void 0) key_OR_range = null;
      try {
        let request = this[_count](key_OR_range);
        return dart.as(_completeRequest(request), async.Future$(core.int));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future$(core.int).error(e, stacktrace);
      }

    }
    [dartx.get](key) {
      try {
        let request = this[_get](key);
        return _completeRequest(request);
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.getKey](key) {
      try {
        let request = this[_getKey](key);
        return _completeRequest(request);
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.openCursor](opts) {
      let key = opts && 'key' in opts ? opts.key : null;
      let range = opts && 'range' in opts ? opts.range : null;
      let direction = opts && 'direction' in opts ? opts.direction : null;
      let autoAdvance = opts && 'autoAdvance' in opts ? opts.autoAdvance : null;
      let key_OR_range = null;
      if (key != null) {
        if (range != null) {
          dart.throw(new core.ArgumentError('Cannot specify both key and range.'));
        }
        key_OR_range = key;
      } else {
        key_OR_range = range;
      }
      let request = null;
      if (direction == null) {
        request = this[_openCursor](key_OR_range, "next");
      } else {
        request = this[_openCursor](key_OR_range, direction);
      }
      return dart.as(ObjectStore._cursorStreamFromResult(dart.as(request, Request), autoAdvance), async.Stream$(CursorWithValue));
    }
    [dartx.openKeyCursor](opts) {
      let key = opts && 'key' in opts ? opts.key : null;
      let range = opts && 'range' in opts ? opts.range : null;
      let direction = opts && 'direction' in opts ? opts.direction : null;
      let autoAdvance = opts && 'autoAdvance' in opts ? opts.autoAdvance : null;
      let key_OR_range = null;
      if (key != null) {
        if (range != null) {
          dart.throw(new core.ArgumentError('Cannot specify both key and range.'));
        }
        key_OR_range = key;
      } else {
        key_OR_range = range;
      }
      let request = null;
      if (direction == null) {
        request = this[_openKeyCursor](key_OR_range, "next");
      } else {
        request = this[_openKeyCursor](key_OR_range, direction);
      }
      return ObjectStore._cursorStreamFromResult(dart.as(request, Request), autoAdvance);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.keyPath]() {
      return this.keyPath;
    }
    get [dartx.multiEntry]() {
      return this.multiEntry;
    }
    get [dartx.name]() {
      return this.name;
    }
    get [dartx.objectStore]() {
      return this.objectStore;
    }
    get [dartx.unique]() {
      return this.unique;
    }
    [_count](key) {
      return this.count(key);
    }
    [_get](key) {
      return this.get(key);
    }
    [_getKey](key) {
      return this.getKey(key);
    }
    [_openCursor](range, direction) {
      return this.openCursor(range, direction);
    }
    [_openKeyCursor](range, direction) {
      return this.openKeyCursor(range, direction);
    }
  }
  dart.setSignature(Index, {
    constructors: () => ({_: [Index, []]}),
    methods: () => ({
      [dartx.count]: [async.Future$(core.int), [], [dart.dynamic]],
      [dartx.get]: [async.Future, [dart.dynamic]],
      [dartx.getKey]: [async.Future, [dart.dynamic]],
      [dartx.openCursor]: [async.Stream$(CursorWithValue), [], {key: dart.dynamic, range: KeyRange, direction: core.String, autoAdvance: core.bool}],
      [dartx.openKeyCursor]: [async.Stream$(Cursor), [], {key: dart.dynamic, range: KeyRange, direction: core.String, autoAdvance: core.bool}],
      [_count]: [Request, [core.Object]],
      [_get]: [Request, [core.Object]],
      [_getKey]: [Request, [core.Object]],
      [_openCursor]: [Request, [core.Object], [core.String]],
      [_openKeyCursor]: [Request, [core.Object], [core.String]]
    })
  });
  Index[dart.metadata] = () => [dart.const(new _metadata.DomName('IDBIndex')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBIndex"))];
  dart.registerExtension(dart.global.IDBIndex, Index);
  dart.defineExtensionNames([
    'lower',
    'lowerOpen',
    'upper',
    'upperOpen'
  ]);
  class KeyRange extends _interceptors.Interceptor {
    static only(value) {
      return _KeyRangeFactoryProvider.createKeyRange_only(value);
    }
    static lowerBound(bound, open) {
      if (open === void 0) open = false;
      return _KeyRangeFactoryProvider.createKeyRange_lowerBound(bound, open);
    }
    static upperBound(bound, open) {
      if (open === void 0) open = false;
      return _KeyRangeFactoryProvider.createKeyRange_upperBound(bound, open);
    }
    static bound(lower, upper, lowerOpen, upperOpen) {
      if (lowerOpen === void 0) lowerOpen = false;
      if (upperOpen === void 0) upperOpen = false;
      return _KeyRangeFactoryProvider.createKeyRange_bound(lower, upper, lowerOpen, upperOpen);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.lower]() {
      return this.lower;
    }
    get [dartx.lowerOpen]() {
      return this.lowerOpen;
    }
    get [dartx.upper]() {
      return this.upper;
    }
    get [dartx.upperOpen]() {
      return this.upperOpen;
    }
  }
  dart.setSignature(KeyRange, {
    constructors: () => ({
      only: [KeyRange, [dart.dynamic]],
      lowerBound: [KeyRange, [dart.dynamic], [core.bool]],
      upperBound: [KeyRange, [dart.dynamic], [core.bool]],
      bound: [KeyRange, [dart.dynamic, dart.dynamic], [core.bool, core.bool]],
      _: [KeyRange, []]
    }),
    statics: () => ({
      bound_: [KeyRange, [core.Object, core.Object], [core.bool, core.bool]],
      lowerBound_: [KeyRange, [core.Object], [core.bool]],
      only_: [KeyRange, [core.Object]],
      upperBound_: [KeyRange, [core.Object], [core.bool]]
    }),
    names: ['bound_', 'lowerBound_', 'only_', 'upperBound_']
  });
  KeyRange[dart.metadata] = () => [dart.const(new _metadata.DomName('IDBKeyRange')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBKeyRange"))];
  dart.registerExtension(dart.global.IDBKeyRange, KeyRange);
  const _add = Symbol('_add');
  const _clear = Symbol('_clear');
  const _put = Symbol('_put');
  const _createIndex = Symbol('_createIndex');
  const _add_1 = Symbol('_add_1');
  const _add_2 = Symbol('_add_2');
  const _createIndex_1 = Symbol('_createIndex_1');
  const _createIndex_2 = Symbol('_createIndex_2');
  const _createIndex_3 = Symbol('_createIndex_3');
  const _createIndex_4 = Symbol('_createIndex_4');
  const _put_1 = Symbol('_put_1');
  const _put_2 = Symbol('_put_2');
  dart.defineExtensionNames([
    'add',
    'clear',
    'delete',
    'count',
    'put',
    'getObject',
    'openCursor',
    'createIndex',
    'deleteIndex',
    'index',
    'openKeyCursor',
    'autoIncrement',
    'indexNames',
    'keyPath',
    'name',
    'transaction'
  ]);
  class ObjectStore extends _interceptors.Interceptor {
    [dartx.add](value, key) {
      if (key === void 0) key = null;
      try {
        let request = null;
        if (key != null) {
          request = this[_add](value, key);
        } else {
          request = this[_add](value);
        }
        return _completeRequest(dart.as(request, Request));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.clear]() {
      try {
        return _completeRequest(this[_clear]());
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.delete](key_OR_keyRange) {
      try {
        return _completeRequest(this[_delete](key_OR_keyRange));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.count](key_OR_range) {
      if (key_OR_range === void 0) key_OR_range = null;
      try {
        let request = this[_count](key_OR_range);
        return dart.as(_completeRequest(request), async.Future$(core.int));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future$(core.int).error(e, stacktrace);
      }

    }
    [dartx.put](value, key) {
      if (key === void 0) key = null;
      try {
        let request = null;
        if (key != null) {
          request = this[_put](value, key);
        } else {
          request = this[_put](value);
        }
        return _completeRequest(dart.as(request, Request));
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.getObject](key) {
      try {
        let request = this[_get](key);
        return _completeRequest(request);
      } catch (e) {
        let stacktrace = dart.stackTrace(e);
        return async.Future.error(e, stacktrace);
      }

    }
    [dartx.openCursor](opts) {
      let key = opts && 'key' in opts ? opts.key : null;
      let range = opts && 'range' in opts ? opts.range : null;
      let direction = opts && 'direction' in opts ? opts.direction : null;
      let autoAdvance = opts && 'autoAdvance' in opts ? opts.autoAdvance : null;
      let key_OR_range = null;
      if (key != null) {
        if (range != null) {
          dart.throw(new core.ArgumentError('Cannot specify both key and range.'));
        }
        key_OR_range = key;
      } else {
        key_OR_range = range;
      }
      let request = null;
      if (direction == null) {
        request = this[_openCursor](key_OR_range);
      } else {
        request = this[_openCursor](key_OR_range, direction);
      }
      return dart.as(ObjectStore._cursorStreamFromResult(dart.as(request, Request), autoAdvance), async.Stream$(CursorWithValue));
    }
    [dartx.createIndex](name, keyPath, opts) {
      let unique = opts && 'unique' in opts ? opts.unique : null;
      let multiEntry = opts && 'multiEntry' in opts ? opts.multiEntry : null;
      let options = dart.map();
      if (unique != null) {
        options[dartx.set]('unique', unique);
      }
      if (multiEntry != null) {
        options[dartx.set]('multiEntry', multiEntry);
      }
      return this[_createIndex](name, keyPath, options);
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.autoIncrement]() {
      return this.autoIncrement;
    }
    get [dartx.indexNames]() {
      return this.indexNames;
    }
    get [dartx.keyPath]() {
      return this.keyPath;
    }
    get [dartx.name]() {
      return this.name;
    }
    get [dartx.transaction]() {
      return this.transaction;
    }
    [_add](value, key) {
      if (key === void 0) key = null;
      if (key != null) {
        let value_1 = html_common.convertDartToNative_SerializedScriptValue(value);
        let key_2 = html_common.convertDartToNative_SerializedScriptValue(key);
        return this[_add_1](value_1, key_2);
      }
      let value_1 = html_common.convertDartToNative_SerializedScriptValue(value);
      return this[_add_2](value_1);
    }
    [_add_1](value, key) {
      return this.add(value, key);
    }
    [_add_2](value) {
      return this.add(value);
    }
    [_clear]() {
      return this.clear();
    }
    [_count](key) {
      return this.count(key);
    }
    [_createIndex](name, keyPath, options) {
      if (options === void 0) options = null;
      if ((typeof keyPath == 'string' || keyPath == null) && options == null) {
        return this[_createIndex_1](name, dart.as(keyPath, core.String));
      }
      if (options != null && (typeof keyPath == 'string' || keyPath == null)) {
        let options_1 = html_common.convertDartToNative_Dictionary(options);
        return this[_createIndex_2](name, dart.as(keyPath, core.String), options_1);
      }
      if ((dart.is(keyPath, core.List$(core.String)) || keyPath == null) && options == null) {
        let keyPath_1 = html_common.convertDartToNative_StringArray(dart.as(keyPath, core.List$(core.String)));
        return this[_createIndex_3](name, keyPath_1);
      }
      if (options != null && (dart.is(keyPath, core.List$(core.String)) || keyPath == null)) {
        let keyPath_1 = html_common.convertDartToNative_StringArray(dart.as(keyPath, core.List$(core.String)));
        let options_2 = html_common.convertDartToNative_Dictionary(options);
        return this[_createIndex_4](name, keyPath_1, options_2);
      }
      dart.throw(new core.ArgumentError("Incorrect number or type of arguments"));
    }
    [_createIndex_1](name, keyPath) {
      return this.createIndex(name, keyPath);
    }
    [_createIndex_2](name, keyPath, options) {
      return this.createIndex(name, keyPath, options);
    }
    [_createIndex_3](name, keyPath) {
      return this.createIndex(name, keyPath);
    }
    [_createIndex_4](name, keyPath, options) {
      return this.createIndex(name, keyPath, options);
    }
    [_delete](key) {
      return this.delete(key);
    }
    [dartx.deleteIndex](name) {
      return this.deleteIndex(name);
    }
    [_get](key) {
      return this.get(key);
    }
    [dartx.index](name) {
      return this.index(name);
    }
    [_openCursor](range, direction) {
      return this.openCursor(range, direction);
    }
    [dartx.openKeyCursor](range, direction) {
      return this.openKeyCursor(range, direction);
    }
    [_put](value, key) {
      if (key === void 0) key = null;
      if (key != null) {
        let value_1 = html_common.convertDartToNative_SerializedScriptValue(value);
        let key_2 = html_common.convertDartToNative_SerializedScriptValue(key);
        return this[_put_1](value_1, key_2);
      }
      let value_1 = html_common.convertDartToNative_SerializedScriptValue(value);
      return this[_put_2](value_1);
    }
    [_put_1](value, key) {
      return this.put(value, key);
    }
    [_put_2](value) {
      return this.put(value);
    }
    static _cursorStreamFromResult(request, autoAdvance) {
      let controller = async.StreamController.new({sync: true});
      request[dartx.onError].listen(dart.bind(controller, 'addError'));
      request[dartx.onSuccess].listen(dart.fn(e => {
        let cursor = dart.as(request[dartx.result], Cursor);
        if (cursor == null) {
          controller.close();
        } else {
          controller.add(cursor);
          if (autoAdvance == true && dart.notNull(controller.hasListener)) {
            cursor[dartx.next]();
          }
        }
      }, dart.void, [html.Event]));
      return dart.as(controller.stream, async.Stream$(Cursor));
    }
  }
  dart.setSignature(ObjectStore, {
    constructors: () => ({_: [ObjectStore, []]}),
    methods: () => ({
      [dartx.add]: [async.Future, [dart.dynamic], [dart.dynamic]],
      [dartx.clear]: [async.Future, []],
      [dartx.delete]: [async.Future, [dart.dynamic]],
      [dartx.count]: [async.Future$(core.int), [], [dart.dynamic]],
      [dartx.put]: [async.Future, [dart.dynamic], [dart.dynamic]],
      [dartx.getObject]: [async.Future, [dart.dynamic]],
      [dartx.openCursor]: [async.Stream$(CursorWithValue), [], {key: dart.dynamic, range: KeyRange, direction: core.String, autoAdvance: core.bool}],
      [dartx.createIndex]: [Index, [core.String, dart.dynamic], {unique: core.bool, multiEntry: core.bool}],
      [_add]: [Request, [dart.dynamic], [dart.dynamic]],
      [_add_1]: [Request, [dart.dynamic, dart.dynamic]],
      [_add_2]: [Request, [dart.dynamic]],
      [_clear]: [Request, []],
      [_count]: [Request, [core.Object]],
      [_createIndex]: [Index, [core.String, dart.dynamic], [core.Map]],
      [_createIndex_1]: [Index, [dart.dynamic, core.String]],
      [_createIndex_2]: [Index, [dart.dynamic, core.String, dart.dynamic]],
      [_createIndex_3]: [Index, [dart.dynamic, core.List]],
      [_createIndex_4]: [Index, [dart.dynamic, core.List, dart.dynamic]],
      [_delete]: [Request, [core.Object]],
      [dartx.deleteIndex]: [dart.void, [core.String]],
      [_get]: [Request, [core.Object]],
      [dartx.index]: [Index, [core.String]],
      [_openCursor]: [Request, [core.Object], [core.String]],
      [dartx.openKeyCursor]: [Request, [core.Object], [core.String]],
      [_put]: [Request, [dart.dynamic], [dart.dynamic]],
      [_put_1]: [Request, [dart.dynamic, dart.dynamic]],
      [_put_2]: [Request, [dart.dynamic]]
    }),
    statics: () => ({_cursorStreamFromResult: [async.Stream$(Cursor), [Request, core.bool]]}),
    names: ['_cursorStreamFromResult']
  });
  ObjectStore[dart.metadata] = () => [dart.const(new _metadata.DomName('IDBObjectStore')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBObjectStore"))];
  dart.registerExtension(dart.global.IDBObjectStore, ObjectStore);
  const _get_result = Symbol('_get_result');
  dart.defineExtensionNames([
    'result',
    'onError',
    'onSuccess',
    'error',
    'readyState',
    'source',
    'transaction'
  ]);
  class Request extends html.EventTarget {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.error]() {
      return this.error;
    }
    get [dartx.readyState]() {
      return this.readyState;
    }
    get [dartx.result]() {
      return _convertNativeToDart_IDBAny(this[_get_result]);
    }
    get [_get_result]() {
      return this.result;
    }
    get [dartx.source]() {
      return this.source;
    }
    get [dartx.transaction]() {
      return this.transaction;
    }
    get [dartx.onError]() {
      return Request.errorEvent.forTarget(this);
    }
    get [dartx.onSuccess]() {
      return Request.successEvent.forTarget(this);
    }
  }
  dart.setSignature(Request, {
    constructors: () => ({_: [Request, []]})
  });
  Request[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('IDBRequest')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBRequest"))];
  Request.errorEvent = dart.const(new (html.EventStreamProvider$(html.Event))('error'));
  Request.successEvent = dart.const(new (html.EventStreamProvider$(html.Event))('success'));
  dart.registerExtension(dart.global.IDBRequest, Request);
  dart.defineExtensionNames([
    'onBlocked',
    'onUpgradeNeeded'
  ]);
  class OpenDBRequest extends Request {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.onBlocked]() {
      return OpenDBRequest.blockedEvent.forTarget(this);
    }
    get [dartx.onUpgradeNeeded]() {
      return OpenDBRequest.upgradeNeededEvent.forTarget(this);
    }
  }
  dart.setSignature(OpenDBRequest, {
    constructors: () => ({_: [OpenDBRequest, []]})
  });
  OpenDBRequest[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('IDBOpenDBRequest')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBOpenDBRequest,IDBVersionChangeRequest"))];
  OpenDBRequest.blockedEvent = dart.const(new (html.EventStreamProvider$(html.Event))('blocked'));
  dart.defineLazyProperties(OpenDBRequest, {
    get upgradeNeededEvent() {
      return dart.const(new (html.EventStreamProvider$(VersionChangeEvent))('upgradeneeded'));
    }
  });
  dart.registerExtension(dart.global.IDBOpenDBRequest, OpenDBRequest);
  dart.defineExtensionNames([
    'completed',
    'abort',
    'objectStore',
    'onAbort',
    'onComplete',
    'onError',
    'db',
    'error',
    'mode'
  ]);
  class Transaction extends html.EventTarget {
    get [dartx.completed]() {
      let completer = async.Completer$(Database).new();
      this[dartx.onComplete].first.then(dart.fn(_ => {
        completer.complete(this[dartx.db]);
      }, dart.dynamic, [html.Event]));
      this[dartx.onError].first.then(dart.fn(e => {
        completer.completeError(e);
      }, dart.dynamic, [html.Event]));
      this[dartx.onAbort].first.then(dart.fn(e => {
        if (!dart.notNull(completer.isCompleted)) {
          completer.completeError(e);
        }
      }, dart.dynamic, [html.Event]));
      return completer.future;
    }
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.db]() {
      return this.db;
    }
    get [dartx.error]() {
      return this.error;
    }
    get [dartx.mode]() {
      return this.mode;
    }
    [dartx.abort]() {
      return this.abort();
    }
    [dartx.objectStore](name) {
      return this.objectStore(name);
    }
    get [dartx.onAbort]() {
      return Transaction.abortEvent.forTarget(this);
    }
    get [dartx.onComplete]() {
      return Transaction.completeEvent.forTarget(this);
    }
    get [dartx.onError]() {
      return Transaction.errorEvent.forTarget(this);
    }
  }
  dart.setSignature(Transaction, {
    constructors: () => ({_: [Transaction, []]}),
    methods: () => ({
      [dartx.abort]: [dart.void, []],
      [dartx.objectStore]: [ObjectStore, [core.String]]
    })
  });
  Transaction[dart.metadata] = () => [dart.const(new _metadata.DomName('IDBTransaction')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBTransaction"))];
  Transaction.abortEvent = dart.const(new (html.EventStreamProvider$(html.Event))('abort'));
  Transaction.completeEvent = dart.const(new (html.EventStreamProvider$(html.Event))('complete'));
  Transaction.errorEvent = dart.const(new (html.EventStreamProvider$(html.Event))('error'));
  dart.registerExtension(dart.global.IDBTransaction, Transaction);
  dart.defineExtensionNames([
    'dataLoss',
    'dataLossMessage',
    'newVersion',
    'oldVersion'
  ]);
  class VersionChangeEvent extends html.Event {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.dataLoss]() {
      return this.dataLoss;
    }
    get [dartx.dataLossMessage]() {
      return this.dataLossMessage;
    }
    get [dartx.newVersion]() {
      return this.newVersion;
    }
    get [dartx.oldVersion]() {
      return this.oldVersion;
    }
  }
  dart.setSignature(VersionChangeEvent, {
    constructors: () => ({_: [VersionChangeEvent, []]})
  });
  VersionChangeEvent[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('IDBVersionChangeEvent')), dart.const(new _metadata.Unstable()), dart.const(new _js_helper.Native("IDBVersionChangeEvent"))];
  dart.registerExtension(dart.global.IDBVersionChangeEvent, VersionChangeEvent);
  // Exports:
  exports.Cursor = Cursor;
  exports.CursorWithValue = CursorWithValue;
  exports.Database = Database;
  exports.IdbFactory = IdbFactory;
  exports.Index = Index;
  exports.KeyRange = KeyRange;
  exports.ObjectStore = ObjectStore;
  exports.Request = Request;
  exports.OpenDBRequest = OpenDBRequest;
  exports.Transaction = Transaction;
  exports.VersionChangeEvent = VersionChangeEvent;
});
