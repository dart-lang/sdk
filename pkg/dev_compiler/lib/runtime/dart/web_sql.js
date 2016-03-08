dart_library.library('dart/web_sql', null, /* Imports */[
  'dart/_runtime',
  'dart/core',
  'dart/_interceptors',
  'dart/html',
  'dart/_metadata',
  'dart/_js_helper',
  'dart/html_common',
  'dart/collection'
], /* Lazy imports */[
], function(exports, dart, core, _interceptors, html, _metadata, _js_helper, html_common, collection) {
  'use strict';
  let dartx = dart.dartx;
  const SqlStatementCallback = dart.typedef('SqlStatementCallback', () => dart.functionType(dart.void, [SqlTransaction, SqlResultSet]));
  const SqlStatementErrorCallback = dart.typedef('SqlStatementErrorCallback', () => dart.functionType(dart.void, [SqlTransaction, SqlError]));
  const SqlTransactionCallback = dart.typedef('SqlTransactionCallback', () => dart.functionType(dart.void, [SqlTransaction]));
  const SqlTransactionErrorCallback = dart.typedef('SqlTransactionErrorCallback', () => dart.functionType(dart.void, [SqlError]));
  dart.defineExtensionNames([
    'changeVersion',
    'readTransaction',
    'transaction',
    'version'
  ]);
  class SqlDatabase extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    static get supported() {
      return !!window.openDatabase;
    }
    get [dartx.version]() {
      return this.version;
    }
    [dartx.changeVersion](oldVersion, newVersion, callback, errorCallback, successCallback) {
      return this.changeVersion(oldVersion, newVersion, callback, errorCallback, successCallback);
    }
    [dartx.readTransaction](callback, errorCallback, successCallback) {
      return this.readTransaction(callback, errorCallback, successCallback);
    }
    [dartx.transaction](callback, errorCallback, successCallback) {
      return this.transaction(callback, errorCallback, successCallback);
    }
  }
  dart.setSignature(SqlDatabase, {
    constructors: () => ({_: [SqlDatabase, []]}),
    methods: () => ({
      [dartx.changeVersion]: [dart.void, [core.String, core.String], [SqlTransactionCallback, SqlTransactionErrorCallback, html.VoidCallback]],
      [dartx.readTransaction]: [dart.void, [SqlTransactionCallback], [SqlTransactionErrorCallback, html.VoidCallback]],
      [dartx.transaction]: [dart.void, [SqlTransactionCallback], [SqlTransactionErrorCallback, html.VoidCallback]]
    })
  });
  SqlDatabase[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('Database')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Experimental()), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("Database"))];
  dart.registerExtension(dart.global.Database, SqlDatabase);
  dart.defineExtensionNames([
    'code',
    'message'
  ]);
  class SqlError extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.code]() {
      return this.code;
    }
    get [dartx.message]() {
      return this.message;
    }
  }
  dart.setSignature(SqlError, {
    constructors: () => ({_: [SqlError, []]})
  });
  SqlError[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SQLError')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SQLError"))];
  SqlError.CONSTRAINT_ERR = 6;
  SqlError.DATABASE_ERR = 1;
  SqlError.QUOTA_ERR = 4;
  SqlError.SYNTAX_ERR = 5;
  SqlError.TIMEOUT_ERR = 7;
  SqlError.TOO_LARGE_ERR = 3;
  SqlError.UNKNOWN_ERR = 0;
  SqlError.VERSION_ERR = 2;
  dart.registerExtension(dart.global.SQLError, SqlError);
  dart.defineExtensionNames([
    'insertId',
    'rows',
    'rowsAffected'
  ]);
  class SqlResultSet extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.insertId]() {
      return this.insertId;
    }
    get [dartx.rows]() {
      return this.rows;
    }
    get [dartx.rowsAffected]() {
      return this.rowsAffected;
    }
  }
  dart.setSignature(SqlResultSet, {
    constructors: () => ({_: [SqlResultSet, []]})
  });
  SqlResultSet[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SQLResultSet')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SQLResultSet"))];
  dart.registerExtension(dart.global.SQLResultSet, SqlResultSet);
  const _item_1 = Symbol('_item_1');
  dart.defineExtensionNames([
    'length',
    'get',
    'set',
    'length',
    'first',
    'last',
    'single',
    'elementAt',
    'item'
  ]);
  class SqlResultSetRowList extends dart.mixin(_interceptors.Interceptor, collection.ListMixin$(core.Map), html.ImmutableListMixin$(core.Map)) {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    get [dartx.length]() {
      return this.length;
    }
    [dartx.get](index) {
      if (index >>> 0 !== index || index >= this[dartx.length]) dart.throw(core.RangeError.index(index, this));
      return this[dartx.item](index);
    }
    [dartx.set](index, value) {
      dart.throw(new core.UnsupportedError("Cannot assign element of immutable List."));
      return value;
    }
    set [dartx.length](value) {
      dart.throw(new core.UnsupportedError("Cannot resize immutable List."));
    }
    get [dartx.first]() {
      if (dart.notNull(this[dartx.length]) > 0) {
        return this[0];
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.last]() {
      let len = this[dartx.length];
      if (dart.notNull(len) > 0) {
        return this[dart.notNull(len) - 1];
      }
      dart.throw(new core.StateError("No elements"));
    }
    get [dartx.single]() {
      let len = this[dartx.length];
      if (len == 1) {
        return this[0];
      }
      if (len == 0) dart.throw(new core.StateError("No elements"));
      dart.throw(new core.StateError("More than one element"));
    }
    [dartx.elementAt](index) {
      return this[dartx.get](index);
    }
    [dartx.item](index) {
      return html_common.convertNativeToDart_Dictionary(this[_item_1](index));
    }
    [_item_1](index) {
      return this.item(index);
    }
  }
  SqlResultSetRowList[dart.implements] = () => [core.List$(core.Map)];
  dart.setSignature(SqlResultSetRowList, {
    constructors: () => ({_: [SqlResultSetRowList, []]}),
    methods: () => ({
      [dartx.get]: [core.Map, [core.int]],
      [dartx.set]: [dart.void, [core.int, core.Map]],
      [dartx.elementAt]: [core.Map, [core.int]],
      [dartx.item]: [core.Map, [core.int]],
      [_item_1]: [dart.dynamic, [dart.dynamic]]
    })
  });
  SqlResultSetRowList[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SQLResultSetRowList')), dart.const(new _metadata.Experimental()), dart.const(new _js_helper.Native("SQLResultSetRowList"))];
  dart.registerExtension(dart.global.SQLResultSetRowList, SqlResultSetRowList);
  dart.defineExtensionNames([
    'executeSql'
  ]);
  class SqlTransaction extends _interceptors.Interceptor {
    static _() {
      dart.throw(new core.UnsupportedError("Not supported"));
    }
    [dartx.executeSql](sqlStatement, arguments$, callback, errorCallback) {
      return this.executeSql(sqlStatement, arguments$, callback, errorCallback);
    }
  }
  dart.setSignature(SqlTransaction, {
    constructors: () => ({_: [SqlTransaction, []]}),
    methods: () => ({[dartx.executeSql]: [dart.void, [core.String, core.List$(core.Object)], [SqlStatementCallback, SqlStatementErrorCallback]]})
  });
  SqlTransaction[dart.metadata] = () => [dart.const(new _metadata.DocsEditable()), dart.const(new _metadata.DomName('SQLTransaction')), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.CHROME)), dart.const(new _metadata.SupportedBrowser(_metadata.SupportedBrowser.SAFARI)), dart.const(new _metadata.Experimental()), core.deprecated, dart.const(new _js_helper.Native("SQLTransaction"))];
  dart.registerExtension(dart.global.SQLTransaction, SqlTransaction);
  // Exports:
  exports.SqlStatementCallback = SqlStatementCallback;
  exports.SqlStatementErrorCallback = SqlStatementErrorCallback;
  exports.SqlTransactionCallback = SqlTransactionCallback;
  exports.SqlTransactionErrorCallback = SqlTransactionErrorCallback;
  exports.SqlDatabase = SqlDatabase;
  exports.SqlError = SqlError;
  exports.SqlResultSet = SqlResultSet;
  exports.SqlResultSetRowList = SqlResultSetRowList;
  exports.SqlTransaction = SqlTransaction;
});
