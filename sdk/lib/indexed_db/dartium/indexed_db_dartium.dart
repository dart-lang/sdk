/**
 * A client-side key-value store with support for indexes.
 *
 * Many browsers support IndexedDB&mdash;a web standard for
 * an indexed database.
 * By storing data on the client in an IndexedDB,
 * a web app gets some advantages, such as faster performance and persistence.
 * To find out which browsers support IndexedDB,
 * refer to [Can I Use?](http://caniuse.com/#feat=indexeddb)
 *
 * In IndexedDB, each record is identified by a unique index or key,
 * making data retrieval speedy.
 * You can store structured data,
 * such as images, arrays, and maps using IndexedDB.
 * The standard does not specify size limits for individual data items
 * or for the database itself, but browsers may impose storage limits.
 *
 * ## Using indexed_db
 *
 * The classes in this library provide an interface
 * to the browser's IndexedDB, if it has one.
 * To use this library in your code:
 *
 *     import 'dart:indexed_db';
 *
 * A web app can determine if the browser supports
 * IndexedDB with [IdbFactory.supported]:
 *
 *     if (IdbFactory.supported)
 *       // Use indexeddb.
 *     else
 *       // Find an alternative.
 *
 * Access to the browser's IndexedDB is provided by the app's top-level
 * [Window] object, which your code can refer to with `window.indexedDB`.
 * So, for example,
 * here's how to use window.indexedDB to open a database:
 *
 *     Future open() {
 *       return window.indexedDB.open('myIndexedDB',
 *           version: 1,
 *           onUpgradeNeeded: _initializeDatabase)
 *         .then(_loadFromDB);
 *     }
 *     void _initializeDatabase(VersionChangeEvent e) {
 *       ...
 *     }
 *     Future _loadFromDB(Database db) {
 *       ...
 *     }
 *
 *
 * All data in an IndexedDB is stored within an [ObjectStore].
 * To manipulate the database use [Transaction]s.
 *
 * ## Other resources
 *
 * Other options for client-side data storage include:
 *
 * * [Window.localStorage]&mdash;a
 * basic mechanism that stores data as a [Map],
 * and where both the keys and the values are strings.
 *
 * * [dart:web_sql]&mdash;a database that can be queried with SQL.
 *
 * For a tutorial about using the indexed_db library with Dart,
 * check out
 * [Use IndexedDB](http://www.dartlang.org/docs/tutorials/indexeddb/).
 *
 * [IndexedDB reference](http://docs.webplatform.org/wiki/apis/indexeddb)
 * provides wiki-style docs about indexedDB
 */
library dart.dom.indexed_db;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
import 'dart:js' as js;
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:indexed_db library.





class _KeyRangeFactoryProvider {

  static KeyRange createKeyRange_only(/*IDBKey*/ value) =>
      KeyRange.only_(value);

  static KeyRange createKeyRange_lowerBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      KeyRange.lowerBound_(bound, open);

  static KeyRange createKeyRange_upperBound(
      /*IDBKey*/ bound, [bool open = false]) =>
      KeyRange.upperBound_(bound, open);

  static KeyRange createKeyRange_bound(
      /*IDBKey*/ lower, /*IDBKey*/ upper,
      [bool lowerOpen = false, bool upperOpen = false]) =>
      KeyRange.bound_(lower, upper, lowerOpen, upperOpen);
}
// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final indexed_dbBlinkMap = {
  'IDBCursor': () => Cursor,
  'IDBCursorWithValue': () => CursorWithValue,
  'IDBDatabase': () => Database,
  'IDBFactory': () => IdbFactory,
  'IDBIndex': () => Index,
  'IDBKeyRange': () => KeyRange,
  'IDBObjectStore': () => ObjectStore,
  'IDBOpenDBRequest': () => OpenDBRequest,
  'IDBRequest': () => Request,
  'IDBTransaction': () => Transaction,
  'IDBVersionChangeEvent': () => VersionChangeEvent,

};

// FIXME: Can we make this private?
@Deprecated("Internal Use Only")
final indexed_dbBlinkFunctionMap = {
  'IDBCursor': () => Cursor.internalCreateCursor,
  'IDBCursorWithValue': () => CursorWithValue.internalCreateCursorWithValue,
  'IDBDatabase': () => Database.internalCreateDatabase,
  'IDBFactory': () => IdbFactory.internalCreateIdbFactory,
  'IDBIndex': () => Index.internalCreateIndex,
  'IDBKeyRange': () => KeyRange.internalCreateKeyRange,
  'IDBObjectStore': () => ObjectStore.internalCreateObjectStore,
  'IDBOpenDBRequest': () => OpenDBRequest.internalCreateOpenDBRequest,
  'IDBRequest': () => Request.internalCreateRequest,
  'IDBTransaction': () => Transaction.internalCreateTransaction,
  'IDBVersionChangeEvent': () => VersionChangeEvent.internalCreateVersionChangeEvent,

};
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBCursor')
@Unstable()
class Cursor extends DartHtmlDomObject {
  @DomName('IDBCursor.delete')
  Future delete() {
   try {
      return _completeRequest(_delete());
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBCursor.value')
  Future update(value) {
   try {
      return _completeRequest(_update(value));
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

    // To suppress missing implicit constructor warnings.
  factory Cursor._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Cursor internalCreateCursor() {
    return new Cursor._internalWrap();
  }

  factory Cursor._internalWrap() {
    return new Cursor.internal_();
  }

  @Deprecated("Internal Use Only")
  Cursor.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('IDBCursor.direction')
  @DocsEditable()
  String get direction => _blink.BlinkIDBCursor.instance.direction_Getter_(unwrap_jso(this));
  
  @DomName('IDBCursor.key')
  @DocsEditable()
  Object get key => wrap_jso(_blink.BlinkIDBCursor.instance.key_Getter_(unwrap_jso(this)));
  
  @DomName('IDBCursor.primaryKey')
  @DocsEditable()
  Object get primaryKey => wrap_jso(_blink.BlinkIDBCursor.instance.primaryKey_Getter_(unwrap_jso(this)));
  
  @DomName('IDBCursor.source')
  @DocsEditable()
  Object get source => wrap_jso(_blink.BlinkIDBCursor.instance.source_Getter_(unwrap_jso(this)));
  
  @DomName('IDBCursor.advance')
  @DocsEditable()
  void advance(int count) => _blink.BlinkIDBCursor.instance.advance_Callback_1_(unwrap_jso(this), count);
  
  @DomName('IDBCursor.continuePrimaryKey')
  @DocsEditable()
  @Experimental() // untriaged
  void continuePrimaryKey(Object key, Object primaryKey) => _blink.BlinkIDBCursor.instance.continuePrimaryKey_Callback_2_(unwrap_jso(this), key, primaryKey);
  
  @DomName('IDBCursor.delete')
  @DocsEditable()
  Request _delete() => wrap_jso(_blink.BlinkIDBCursor.instance.delete_Callback_0_(unwrap_jso(this)));
  
  void next([Object key]) {
    if (key != null) {
      _blink.BlinkIDBCursor.instance.continue_Callback_1_(unwrap_jso(this), key);
      return;
    }
    _blink.BlinkIDBCursor.instance.continue_Callback_0_(unwrap_jso(this));
    return;
  }

  @DomName('IDBCursor.update')
  @DocsEditable()
  Request _update(Object value) => wrap_jso(_blink.BlinkIDBCursor.instance.update_Callback_1_(unwrap_jso(this), convertDartToNative_SerializedScriptValue(value)));
  
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('IDBCursorWithValue')
@Unstable()
class CursorWithValue extends Cursor {
  // To suppress missing implicit constructor warnings.
  factory CursorWithValue._() { throw new UnsupportedError("Not supported"); }


  @Deprecated("Internal Use Only")
  static CursorWithValue internalCreateCursorWithValue() {
    return new CursorWithValue._internalWrap();
  }

  external factory CursorWithValue._internalWrap();

  @Deprecated("Internal Use Only")
  CursorWithValue.internal_() : super.internal_();


  @DomName('IDBCursorWithValue.value')
  @DocsEditable()
  Object get value => wrap_jso(_blink.BlinkIDBCursorWithValue.instance.value_Getter_(unwrap_jso(this)));
  
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable()
/**
 * An indexed database object for storing client-side data
 * in web apps.
 */
@DomName('IDBDatabase')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
@Unstable()
class Database extends EventTarget {
  @DomName('IDBDatabase.createObjectStore')
  @DocsEditable()
  ObjectStore createObjectStore(String name,
      {String keyPath, bool autoIncrement}) {
    var options = {};
    if (keyPath != null) {
      options['keyPath'] = keyPath;
    }
    if (autoIncrement != null) {
      options['autoIncrement'] = autoIncrement;
    }

    return _createObjectStore(name, options);
  }

  Transaction transaction(storeName_OR_storeNames, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError("Invalid transaction mode $mode");
    }
    var names;
    if (storeName_OR_storeNames == null) {
      throw new ArgumentError("stores may not be null in transaction");
    } else if (storeName_OR_storeNames is String || storeName_OR_storeNames is DomStringList) {
      names = unwrap_jso(storeName_OR_storeNames);
    } else if (storeName_OR_storeNames is List<String>) {
      names = convertDartToNative_List(storeName_OR_storeNames);
    } else {
      throw new ArgumentError("Invalid store(s) $store_Name_OR_storeNames");
    }

    return wrap_jso(_blink.BlinkIDBDatabase.instance.transaction_Callback_2_(unwrap_jso(this), names, mode));
  }

  Transaction transactionList(List<String> storeNames, String mode) => transaction(storeNames, mode);
  Transaction transactionStores(List<String> storeNames, String mode) => transaction(storeNames, mode);
  Transaction transactionStore(String storeName, String mode) => transaction(storeName, mode);

  // To suppress missing implicit constructor warnings.
  factory Database._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBDatabase.abortEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  /**
   * Static factory designed to expose `close` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBDatabase.closeEvent')
  @DocsEditable()
  // https://www.w3.org/Bugs/Public/show_bug.cgi?id=22540
  @Experimental()
  static const EventStreamProvider<Event> closeEvent = const EventStreamProvider<Event>('close');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBDatabase.errorEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `versionchange` events to event
   * handlers that are not necessarily instances of [Database].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBDatabase.versionchangeEvent')
  @DocsEditable()
  static const EventStreamProvider<VersionChangeEvent> versionChangeEvent = const EventStreamProvider<VersionChangeEvent>('versionchange');


  @Deprecated("Internal Use Only")
  static Database internalCreateDatabase() {
    return new Database._internalWrap();
  }

  external factory Database._internalWrap();

  @Deprecated("Internal Use Only")
  Database.internal_() : super.internal_();


  @DomName('IDBDatabase.name')
  @DocsEditable()
  String get name => _blink.BlinkIDBDatabase.instance.name_Getter_(unwrap_jso(this));
  
  @DomName('IDBDatabase.objectStoreNames')
  @DocsEditable()
  List<String> get objectStoreNames => wrap_jso(_blink.BlinkIDBDatabase.instance.objectStoreNames_Getter_(unwrap_jso(this)));
  
  @DomName('IDBDatabase.version')
  @DocsEditable()
  Object get version => wrap_jso(_blink.BlinkIDBDatabase.instance.version_Getter_(unwrap_jso(this)));
  
  @DomName('IDBDatabase.close')
  @DocsEditable()
  void close() => _blink.BlinkIDBDatabase.instance.close_Callback_0_(unwrap_jso(this));
  
  ObjectStore _createObjectStore(String name, [Map options]) {
    if (options != null) {
      return wrap_jso(_blink.BlinkIDBDatabase.instance.createObjectStore_Callback_2_(unwrap_jso(this), name, convertDartToNative_Dictionary(options)));
    }
    return wrap_jso(_blink.BlinkIDBDatabase.instance.createObjectStore_Callback_1_(unwrap_jso(this), name));
  }

  @DomName('IDBDatabase.deleteObjectStore')
  @DocsEditable()
  void deleteObjectStore(String name) => _blink.BlinkIDBDatabase.instance.deleteObjectStore_Callback_1_(unwrap_jso(this), name);
  
  /// Stream of `abort` events handled by this [Database].
  @DomName('IDBDatabase.onabort')
  @DocsEditable()
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  /// Stream of `close` events handled by this [Database].
  @DomName('IDBDatabase.onclose')
  @DocsEditable()
  // https://www.w3.org/Bugs/Public/show_bug.cgi?id=22540
  @Experimental()
  Stream<Event> get onClose => closeEvent.forTarget(this);

  /// Stream of `error` events handled by this [Database].
  @DomName('IDBDatabase.onerror')
  @DocsEditable()
  Stream<Event> get onError => errorEvent.forTarget(this);

  /// Stream of `versionchange` events handled by this [Database].
  @DomName('IDBDatabase.onversionchange')
  @DocsEditable()
  Stream<VersionChangeEvent> get onVersionChange => versionChangeEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBFactory')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
@Unstable()
class IdbFactory extends DartHtmlDomObject {
  /**
   * Checks to see if Indexed DB is supported on the current platform.
   */
  static bool get supported {
    return true;
  }

  @DomName('IDBFactory.open')
  Future<Database> open(String name,
      {int version, void onUpgradeNeeded(VersionChangeEvent),
      void onBlocked(Event)}) {
    if ((version == null) != (onUpgradeNeeded == null)) {
      return new Future.error(new ArgumentError(
          'version and onUpgradeNeeded must be specified together'));
    }
    try {
      var request;
      if (version != null) {
        request = _open(name, version);
      } else {
        request = _open(name);
      }

      if (onUpgradeNeeded != null) {
        request.onUpgradeNeeded.listen(onUpgradeNeeded);
      }
      if (onBlocked != null) {
        request.onBlocked.listen(onBlocked);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBFactory.deleteDatabase')
  Future<IdbFactory> deleteDatabase(String name,
      {void onBlocked(Event)}) {
    try {
      var request = _deleteDatabase(name);

      if (onBlocked != null) {
        request.onBlocked.listen(onBlocked);
      }
      var completer = new Completer.sync();
      request.onSuccess.listen((e) {
        completer.complete(this);
      });
      request.onError.listen(completer.completeError);
      return completer.future;
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBFactory.getDatabaseNames')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental()
  Future<List<String>> getDatabaseNames() {
    try {
      var request = _webkitGetDatabaseNames();

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  /**
   * Checks to see if getDatabaseNames is supported by the current platform.
   */
  bool get supportsDatabaseNames {
    return true;
  }

  // To suppress missing implicit constructor warnings.
  factory IdbFactory._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static IdbFactory internalCreateIdbFactory() {
    return new IdbFactory._internalWrap();
  }

  factory IdbFactory._internalWrap() {
    return new IdbFactory.internal_();
  }

  @Deprecated("Internal Use Only")
  IdbFactory.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('IDBFactory.cmp')
  @DocsEditable()
  int cmp(Object first, Object second) => _blink.BlinkIDBFactory.instance.cmp_Callback_2_(unwrap_jso(this), first, second);
  
  @DomName('IDBFactory.deleteDatabase')
  @DocsEditable()
  OpenDBRequest _deleteDatabase(String name) => wrap_jso(_blink.BlinkIDBFactory.instance.deleteDatabase_Callback_1_(unwrap_jso(this), name));
  
  OpenDBRequest _open(String name, [int version]) {
    if (version != null) {
      return wrap_jso(_blink.BlinkIDBFactory.instance.open_Callback_2_(unwrap_jso(this), name, version));
    }
    return wrap_jso(_blink.BlinkIDBFactory.instance.open_Callback_1_(unwrap_jso(this), name));
  }

  @DomName('IDBFactory.webkitGetDatabaseNames')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  Request _webkitGetDatabaseNames() => wrap_jso(_blink.BlinkIDBFactory.instance.webkitGetDatabaseNames_Callback_0_(unwrap_jso(this)));
  
}


/**
 * Ties a request to a completer, so the completer is completed when it succeeds
 * and errors out when the request errors.
 */
Future _completeRequest(Request request) {
  var completer = new Completer.sync();
  // TODO: make sure that completer.complete is synchronous as transactions
  // may be committed if the result is not processed immediately.
  request.onSuccess.listen((e) {
    completer.complete(request.result);
  });
  request.onError.listen(completer.completeError);
  return completer.future;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBIndex')
@Unstable()
class Index extends DartHtmlDomObject {
  @DomName('IDBIndex.count')
  Future<int> count([key_OR_range]) {
   try {
      var request = _count(key_OR_range);
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBIndex.get')
  Future get(key) {
    try {
      var request = _get(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBIndex.getKey')
  Future getKey(key) {
    try {
      var request = _getKey(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  /**
   * Creates a stream of cursors over the records in this object store.
   *
   * See also:
   *
   * * [ObjectStore.openCursor]
   */
  Stream<CursorWithValue> openCursor({key, KeyRange range, String direction,
      bool autoAdvance}) {
    var key_OR_range = null;
    if (key != null) {
      if (range != null) {
        throw new ArgumentError('Cannot specify both key and range.');
      }
      key_OR_range = key;
    } else {
      key_OR_range = range;
    }
    var request;
    if (direction == null) {
      // FIXME: Passing in "next" should be unnecessary.
      request = _openCursor(key_OR_range, "next");
    } else {
      request = _openCursor(key_OR_range, direction);
    }
    return ObjectStore._cursorStreamFromResult(request, autoAdvance);
  }

  /**
   * Creates a stream of cursors over the records in this object store.
   *
   * See also:
   *
   * * [ObjectStore.openCursor]
   */
  Stream<Cursor> openKeyCursor({key, KeyRange range, String direction,
      bool autoAdvance}) {
    var key_OR_range = null;
    if (key != null) {
      if (range != null) {
        throw new ArgumentError('Cannot specify both key and range.');
      }
      key_OR_range = key;
    } else {
      key_OR_range = range;
    }
    var request;
    if (direction == null) {
      // FIXME: Passing in "next" should be unnecessary.
      request = _openKeyCursor(key_OR_range, "next");
    } else {
      request = _openKeyCursor(key_OR_range, direction);
    }
    return ObjectStore._cursorStreamFromResult(request, autoAdvance);
  }

    // To suppress missing implicit constructor warnings.
  factory Index._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static Index internalCreateIndex() {
    return new Index._internalWrap();
  }

  factory Index._internalWrap() {
    return new Index.internal_();
  }

  @Deprecated("Internal Use Only")
  Index.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('IDBIndex.keyPath')
  @DocsEditable()
  Object get keyPath => wrap_jso(_blink.BlinkIDBIndex.instance.keyPath_Getter_(unwrap_jso(this)));
  
  @DomName('IDBIndex.multiEntry')
  @DocsEditable()
  bool get multiEntry => _blink.BlinkIDBIndex.instance.multiEntry_Getter_(unwrap_jso(this));
  
  @DomName('IDBIndex.name')
  @DocsEditable()
  String get name => _blink.BlinkIDBIndex.instance.name_Getter_(unwrap_jso(this));
  
  @DomName('IDBIndex.objectStore')
  @DocsEditable()
  ObjectStore get objectStore => wrap_jso(_blink.BlinkIDBIndex.instance.objectStore_Getter_(unwrap_jso(this)));
  
  @DomName('IDBIndex.unique')
  @DocsEditable()
  bool get unique => _blink.BlinkIDBIndex.instance.unique_Getter_(unwrap_jso(this));
  
  @DomName('IDBIndex.count')
  @DocsEditable()
  Request _count(Object key) => wrap_jso(_blink.BlinkIDBIndex.instance.count_Callback_1_(unwrap_jso(this), key));
  
  @DomName('IDBIndex.get')
  @DocsEditable()
  Request _get(Object key) => wrap_jso(_blink.BlinkIDBIndex.instance.get_Callback_1_(unwrap_jso(this), key));
  
  Request getAll(Object range, [int maxCount]) {
    if (maxCount != null) {
      return wrap_jso(_blink.BlinkIDBIndex.instance.getAll_Callback_2_(unwrap_jso(this), range, maxCount));
    }
    return wrap_jso(_blink.BlinkIDBIndex.instance.getAll_Callback_1_(unwrap_jso(this), range));
  }

  Request getAllKeys(Object range, [int maxCount]) {
    if (maxCount != null) {
      return wrap_jso(_blink.BlinkIDBIndex.instance.getAllKeys_Callback_2_(unwrap_jso(this), range, maxCount));
    }
    return wrap_jso(_blink.BlinkIDBIndex.instance.getAllKeys_Callback_1_(unwrap_jso(this), range));
  }

  @DomName('IDBIndex.getKey')
  @DocsEditable()
  Request _getKey(Object key) => wrap_jso(_blink.BlinkIDBIndex.instance.getKey_Callback_1_(unwrap_jso(this), key));
  
  Request _openCursor(Object range, [String direction]) {
    if (direction != null) {
      return wrap_jso(_blink.BlinkIDBIndex.instance.openCursor_Callback_2_(unwrap_jso(this), range, direction));
    }
    return wrap_jso(_blink.BlinkIDBIndex.instance.openCursor_Callback_1_(unwrap_jso(this), range));
  }

  Request _openKeyCursor(Object range, [String direction]) {
    if (direction != null) {
      return wrap_jso(_blink.BlinkIDBIndex.instance.openKeyCursor_Callback_2_(unwrap_jso(this), range, direction));
    }
    return wrap_jso(_blink.BlinkIDBIndex.instance.openKeyCursor_Callback_1_(unwrap_jso(this), range));
  }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBKeyRange')
@Unstable()
class KeyRange extends DartHtmlDomObject {
  @DomName('IDBKeyRange.only')
  factory KeyRange.only(/*Key*/ value) =>
      _KeyRangeFactoryProvider.createKeyRange_only(value);

  @DomName('IDBKeyRange.lowerBound')
  factory KeyRange.lowerBound(/*Key*/ bound, [bool open = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_lowerBound(bound, open);

  @DomName('IDBKeyRange.upperBound')
  factory KeyRange.upperBound(/*Key*/ bound, [bool open = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_upperBound(bound, open);

  @DomName('KeyRange.bound')
  factory KeyRange.bound(/*Key*/ lower, /*Key*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_bound(
          lower, upper, lowerOpen, upperOpen);

  // To suppress missing implicit constructor warnings.
  factory KeyRange._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static KeyRange internalCreateKeyRange() {
    return new KeyRange._internalWrap();
  }

  factory KeyRange._internalWrap() {
    return new KeyRange.internal_();
  }

  @Deprecated("Internal Use Only")
  KeyRange.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('IDBKeyRange.lower')
  @DocsEditable()
  Object get lower => wrap_jso(_blink.BlinkIDBKeyRange.instance.lower_Getter_(unwrap_jso(this)));
  
  @DomName('IDBKeyRange.lowerOpen')
  @DocsEditable()
  bool get lowerOpen => _blink.BlinkIDBKeyRange.instance.lowerOpen_Getter_(unwrap_jso(this));
  
  @DomName('IDBKeyRange.upper')
  @DocsEditable()
  Object get upper => wrap_jso(_blink.BlinkIDBKeyRange.instance.upper_Getter_(unwrap_jso(this)));
  
  @DomName('IDBKeyRange.upperOpen')
  @DocsEditable()
  bool get upperOpen => _blink.BlinkIDBKeyRange.instance.upperOpen_Getter_(unwrap_jso(this));
  
  static KeyRange bound_(Object lower, Object upper, [bool lowerOpen, bool upperOpen]) {
    if (upperOpen != null) {
      return wrap_jso(_blink.BlinkIDBKeyRange.instance.bound_Callback_4_(lower, upper, lowerOpen, upperOpen));
    }
    if (lowerOpen != null) {
      return wrap_jso(_blink.BlinkIDBKeyRange.instance.bound_Callback_3_(lower, upper, lowerOpen));
    }
    return wrap_jso(_blink.BlinkIDBKeyRange.instance.bound_Callback_2_(lower, upper));
  }

  static KeyRange lowerBound_(Object bound, [bool open]) {
    if (open != null) {
      return wrap_jso(_blink.BlinkIDBKeyRange.instance.lowerBound_Callback_2_(bound, open));
    }
    return wrap_jso(_blink.BlinkIDBKeyRange.instance.lowerBound_Callback_1_(bound));
  }

  @DomName('IDBKeyRange.only_')
  @DocsEditable()
  @Experimental() // non-standard
  static KeyRange only_(Object value) => wrap_jso(_blink.BlinkIDBKeyRange.instance.only_Callback_1_(value));
  
  static KeyRange upperBound_(Object bound, [bool open]) {
    if (open != null) {
      return wrap_jso(_blink.BlinkIDBKeyRange.instance.upperBound_Callback_2_(bound, open));
    }
    return wrap_jso(_blink.BlinkIDBKeyRange.instance.upperBound_Callback_1_(bound));
  }

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBObjectStore')
@Unstable()
class ObjectStore extends DartHtmlDomObject {

  @DomName('IDBObjectStore.add')
  Future add(value, [key]) {
    try {
      var request;
      if (key != null) {
        request = _add(value, key);
      } else {
        request = _add(value);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.clear')
  Future clear() {
    try {
      return _completeRequest(_clear());
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.delete')
  Future delete(key_OR_keyRange){
    try {
      return _completeRequest(_delete(key_OR_keyRange));
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.count')
  Future<int> count([key_OR_range]) {
   try {
      var request = _count(key_OR_range);
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.put')
  Future put(value, [key]) {
    try {
      var request;
      if (key != null) {
        request = _put(value, key);
      } else {
        request = _put(value);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.get')
  Future getObject(key) {
    try {
      var request = _get(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  /**
   * Creates a stream of cursors over the records in this object store.
   *
   * **The stream must be manually advanced by calling [Cursor.next] after
   * each item or by specifying autoAdvance to be true.**
   *
   *     var cursors = objectStore.openCursor().listen(
   *       (cursor) {
   *         // ...some processing with the cursor
   *         cursor.next(); // advance onto the next cursor.
   *       },
   *       onDone: () {
   *         // called when there are no more cursors.
   *         print('all done!');
   *       });
   *
   * Asynchronous operations which are not related to the current transaction
   * will cause the transaction to automatically be committed-- all processing
   * must be done synchronously unless they are additional async requests to
   * the current transaction.
   */
  @DomName('IDBObjectStore.openCursor')
  Stream<CursorWithValue> openCursor({key, KeyRange range, String direction,
      bool autoAdvance}) {
    var key_OR_range = null;
    if (key != null) {
      if (range != null) {
        throw new ArgumentError('Cannot specify both key and range.');
      }
      key_OR_range = key;
    } else {
      key_OR_range = range;
    }

    // TODO: try/catch this and return a stream with an immediate error.
    var request;
    if (direction == null) {
      request = _openCursor(key_OR_range);
    } else {
      request = _openCursor(key_OR_range, direction);
    }
    return _cursorStreamFromResult(request, autoAdvance);
  }

  @DomName('IDBObjectStore.createIndex')
  Index createIndex(String name, keyPath, {bool unique, bool multiEntry}) {
    var options = {};
    if (unique != null) {
      options['unique'] = unique;
    }
    if (multiEntry != null) {
      options['multiEntry'] = multiEntry;
    }

    return _createIndex(name, keyPath, options);
  }

  // To suppress missing implicit constructor warnings.
  factory ObjectStore._() { throw new UnsupportedError("Not supported"); }

  @Deprecated("Internal Use Only")
  static ObjectStore internalCreateObjectStore() {
    return new ObjectStore._internalWrap();
  }

  factory ObjectStore._internalWrap() {
    return new ObjectStore.internal_();
  }

  @Deprecated("Internal Use Only")
  ObjectStore.internal_() { }

  bool operator ==(other) => unwrap_jso(other) == unwrap_jso(this) || identical(this, other);
  int get hashCode => unwrap_jso(this).hashCode;

  @DomName('IDBObjectStore.autoIncrement')
  @DocsEditable()
  bool get autoIncrement => _blink.BlinkIDBObjectStore.instance.autoIncrement_Getter_(unwrap_jso(this));
  
  @DomName('IDBObjectStore.indexNames')
  @DocsEditable()
  List<String> get indexNames => wrap_jso(_blink.BlinkIDBObjectStore.instance.indexNames_Getter_(unwrap_jso(this)));
  
  @DomName('IDBObjectStore.keyPath')
  @DocsEditable()
  Object get keyPath => wrap_jso(_blink.BlinkIDBObjectStore.instance.keyPath_Getter_(unwrap_jso(this)));
  
  @DomName('IDBObjectStore.name')
  @DocsEditable()
  String get name => _blink.BlinkIDBObjectStore.instance.name_Getter_(unwrap_jso(this));
  
  @DomName('IDBObjectStore.transaction')
  @DocsEditable()
  Transaction get transaction => wrap_jso(_blink.BlinkIDBObjectStore.instance.transaction_Getter_(unwrap_jso(this)));
  
  Request _add(Object value, [Object key]) {
    if (key != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.add_Callback_2_(unwrap_jso(this), convertDartToNative_SerializedScriptValue(value), convertDartToNative_SerializedScriptValue(key)));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.add_Callback_1_(unwrap_jso(this), convertDartToNative_SerializedScriptValue(value)));
  }

  @DomName('IDBObjectStore.clear')
  @DocsEditable()
  Request _clear() => wrap_jso(_blink.BlinkIDBObjectStore.instance.clear_Callback_0_(unwrap_jso(this)));
  
  @DomName('IDBObjectStore.count')
  @DocsEditable()
  Request _count(Object key) => wrap_jso(_blink.BlinkIDBObjectStore.instance.count_Callback_1_(unwrap_jso(this), key));
  
  Index _createIndex(String name, Object keyPath, [Map options]) {
    if (options != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.createIndex_Callback_3_(unwrap_jso(this), name, keyPath, convertDartToNative_Dictionary(options)));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.createIndex_Callback_2_(unwrap_jso(this), name, keyPath));
  }

  @DomName('IDBObjectStore.delete')
  @DocsEditable()
  Request _delete(Object key) => wrap_jso(_blink.BlinkIDBObjectStore.instance.delete_Callback_1_(unwrap_jso(this), key));
  
  @DomName('IDBObjectStore.deleteIndex')
  @DocsEditable()
  void deleteIndex(String name) => _blink.BlinkIDBObjectStore.instance.deleteIndex_Callback_1_(unwrap_jso(this), name);
  
  @DomName('IDBObjectStore.get')
  @DocsEditable()
  Request _get(Object key) => wrap_jso(_blink.BlinkIDBObjectStore.instance.get_Callback_1_(unwrap_jso(this), key));
  
  Request getAll(Object range, [int maxCount]) {
    if (maxCount != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.getAll_Callback_2_(unwrap_jso(this), range, maxCount));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.getAll_Callback_1_(unwrap_jso(this), range));
  }

  Request getAllKeys(Object range, [int maxCount]) {
    if (maxCount != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.getAllKeys_Callback_2_(unwrap_jso(this), range, maxCount));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.getAllKeys_Callback_1_(unwrap_jso(this), range));
  }

  @DomName('IDBObjectStore.index')
  @DocsEditable()
  Index index(String name) => wrap_jso(_blink.BlinkIDBObjectStore.instance.index_Callback_1_(unwrap_jso(this), name));
  
  Request _openCursor(Object range, [String direction]) {
    if (direction != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.openCursor_Callback_2_(unwrap_jso(this), range, direction));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.openCursor_Callback_1_(unwrap_jso(this), range));
  }

  Request openKeyCursor(Object range, [String direction]) {
    if (direction != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.openKeyCursor_Callback_2_(unwrap_jso(this), range, direction));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.openKeyCursor_Callback_1_(unwrap_jso(this), range));
  }

  Request _put(Object value, [Object key]) {
    if (key != null) {
      return wrap_jso(_blink.BlinkIDBObjectStore.instance.put_Callback_2_(unwrap_jso(this), convertDartToNative_SerializedScriptValue(value), convertDartToNative_SerializedScriptValue(key)));
    }
    return wrap_jso(_blink.BlinkIDBObjectStore.instance.put_Callback_1_(unwrap_jso(this), convertDartToNative_SerializedScriptValue(value)));
  }


  /**
   * Helper for iterating over cursors in a request.
   */
  static Stream<Cursor> _cursorStreamFromResult(Request request,
      bool autoAdvance) {
    // TODO: need to guarantee that the controller provides the values
    // immediately as waiting until the next tick will cause the transaction to
    // close.
    var controller = new StreamController(sync: true);

    //TODO: Report stacktrace once issue 4061 is resolved.
    request.onError.listen(controller.addError);

    request.onSuccess.listen((e) {
      Cursor cursor = request.result;
      if (cursor == null) {
        controller.close();
      } else {
        controller.add(cursor);
        if (autoAdvance == true && controller.hasListener) {
          cursor.next();
        }
      }
    });
    return controller.stream;
  }
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('IDBOpenDBRequest')
@Unstable()
class OpenDBRequest extends Request {
  // To suppress missing implicit constructor warnings.
  factory OpenDBRequest._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `blocked` events to event
   * handlers that are not necessarily instances of [OpenDBRequest].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBOpenDBRequest.blockedEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> blockedEvent = const EventStreamProvider<Event>('blocked');

  /**
   * Static factory designed to expose `upgradeneeded` events to event
   * handlers that are not necessarily instances of [OpenDBRequest].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBOpenDBRequest.upgradeneededEvent')
  @DocsEditable()
  static const EventStreamProvider<VersionChangeEvent> upgradeNeededEvent = const EventStreamProvider<VersionChangeEvent>('upgradeneeded');


  @Deprecated("Internal Use Only")
  static OpenDBRequest internalCreateOpenDBRequest() {
    return new OpenDBRequest._internalWrap();
  }

  external factory OpenDBRequest._internalWrap();

  @Deprecated("Internal Use Only")
  OpenDBRequest.internal_() : super.internal_();


  /// Stream of `blocked` events handled by this [OpenDBRequest].
  @DomName('IDBOpenDBRequest.onblocked')
  @DocsEditable()
  Stream<Event> get onBlocked => blockedEvent.forTarget(this);

  /// Stream of `upgradeneeded` events handled by this [OpenDBRequest].
  @DomName('IDBOpenDBRequest.onupgradeneeded')
  @DocsEditable()
  Stream<VersionChangeEvent> get onUpgradeNeeded => upgradeNeededEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('IDBRequest')
@Unstable()
class Request extends EventTarget {
  // To suppress missing implicit constructor warnings.
  factory Request._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [Request].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBRequest.errorEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  /**
   * Static factory designed to expose `success` events to event
   * handlers that are not necessarily instances of [Request].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBRequest.successEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> successEvent = const EventStreamProvider<Event>('success');


  @Deprecated("Internal Use Only")
  static Request internalCreateRequest() {
    return new Request._internalWrap();
  }

  external factory Request._internalWrap();

  @Deprecated("Internal Use Only")
  Request.internal_() : super.internal_();


  @DomName('IDBRequest.error')
  @DocsEditable()
  DomError get error => wrap_jso(_blink.BlinkIDBRequest.instance.error_Getter_(unwrap_jso(this)));
  
  @DomName('IDBRequest.readyState')
  @DocsEditable()
  String get readyState => _blink.BlinkIDBRequest.instance.readyState_Getter_(unwrap_jso(this));
  
  @DomName('IDBRequest.result')
  @DocsEditable()
  Object get result => wrap_jso(_blink.BlinkIDBRequest.instance.result_Getter_(unwrap_jso(this)));
  
  @DomName('IDBRequest.source')
  @DocsEditable()
  Object get source => wrap_jso(_blink.BlinkIDBRequest.instance.source_Getter_(unwrap_jso(this)));
  
  @DomName('IDBRequest.transaction')
  @DocsEditable()
  Transaction get transaction => wrap_jso(_blink.BlinkIDBRequest.instance.transaction_Getter_(unwrap_jso(this)));
  
  /// Stream of `error` events handled by this [Request].
  @DomName('IDBRequest.onerror')
  @DocsEditable()
  Stream<Event> get onError => errorEvent.forTarget(this);

  /// Stream of `success` events handled by this [Request].
  @DomName('IDBRequest.onsuccess')
  @DocsEditable()
  Stream<Event> get onSuccess => successEvent.forTarget(this);

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBTransaction')
@Unstable()
class Transaction extends EventTarget {

  /**
   * Provides a Future which will be completed once the transaction has
   * completed.
   *
   * The future will error if an error occurrs on the transaction or if the
   * transaction is aborted.
   */
  Future<Database> get completed {
    var completer = new Completer<Database>();

    this.onComplete.first.then((_) {
      completer.complete(db);
    });

    this.onError.first.then((e) {
      completer.completeError(e);
    });

    this.onAbort.first.then((e) {
      // Avoid completing twice if an error occurs.
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
    });

    return completer.future;
  }

  // To suppress missing implicit constructor warnings.
  factory Transaction._() { throw new UnsupportedError("Not supported"); }

  /**
   * Static factory designed to expose `abort` events to event
   * handlers that are not necessarily instances of [Transaction].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBTransaction.abortEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  /**
   * Static factory designed to expose `complete` events to event
   * handlers that are not necessarily instances of [Transaction].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBTransaction.completeEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  /**
   * Static factory designed to expose `error` events to event
   * handlers that are not necessarily instances of [Transaction].
   *
   * See [EventStreamProvider] for usage information.
   */
  @DomName('IDBTransaction.errorEvent')
  @DocsEditable()
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');


  @Deprecated("Internal Use Only")
  static Transaction internalCreateTransaction() {
    return new Transaction._internalWrap();
  }

  external factory Transaction._internalWrap();

  @Deprecated("Internal Use Only")
  Transaction.internal_() : super.internal_();


  @DomName('IDBTransaction.db')
  @DocsEditable()
  Database get db => wrap_jso(_blink.BlinkIDBTransaction.instance.db_Getter_(unwrap_jso(this)));
  
  @DomName('IDBTransaction.error')
  @DocsEditable()
  DomError get error => wrap_jso(_blink.BlinkIDBTransaction.instance.error_Getter_(unwrap_jso(this)));
  
  @DomName('IDBTransaction.mode')
  @DocsEditable()
  String get mode => _blink.BlinkIDBTransaction.instance.mode_Getter_(unwrap_jso(this));
  
  @DomName('IDBTransaction.objectStoreNames')
  @DocsEditable()
  @Experimental() // untriaged
  List<String> get objectStoreNames => wrap_jso(_blink.BlinkIDBTransaction.instance.objectStoreNames_Getter_(unwrap_jso(this)));
  
  @DomName('IDBTransaction.abort')
  @DocsEditable()
  void abort() => _blink.BlinkIDBTransaction.instance.abort_Callback_0_(unwrap_jso(this));
  
  @DomName('IDBTransaction.objectStore')
  @DocsEditable()
  ObjectStore objectStore(String name) => wrap_jso(_blink.BlinkIDBTransaction.instance.objectStore_Callback_1_(unwrap_jso(this), name));
  
  /// Stream of `abort` events handled by this [Transaction].
  @DomName('IDBTransaction.onabort')
  @DocsEditable()
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  /// Stream of `complete` events handled by this [Transaction].
  @DomName('IDBTransaction.oncomplete')
  @DocsEditable()
  Stream<Event> get onComplete => completeEvent.forTarget(this);

  /// Stream of `error` events handled by this [Transaction].
  @DomName('IDBTransaction.onerror')
  @DocsEditable()
  Stream<Event> get onError => errorEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable()
@DomName('IDBVersionChangeEvent')
@Unstable()
class VersionChangeEvent extends Event {
  // To suppress missing implicit constructor warnings.
  factory VersionChangeEvent._() { throw new UnsupportedError("Not supported"); }

  @DomName('IDBVersionChangeEvent.IDBVersionChangeEvent')
  @DocsEditable()
  factory VersionChangeEvent(String type, [Map eventInitDict]) {
    if (eventInitDict != null) {
      var eventInitDict_1 = convertDartToNative_Dictionary(eventInitDict);
      return wrap_jso(_blink.BlinkIDBVersionChangeEvent.instance.constructorCallback_2_(type, eventInitDict_1));
    }
    return wrap_jso(_blink.BlinkIDBVersionChangeEvent.instance.constructorCallback_1_(type));
  }


  @Deprecated("Internal Use Only")
  static VersionChangeEvent internalCreateVersionChangeEvent() {
    return new VersionChangeEvent._internalWrap();
  }

  external factory VersionChangeEvent._internalWrap();

  @Deprecated("Internal Use Only")
  VersionChangeEvent.internal_() : super.internal_();


  @DomName('IDBVersionChangeEvent.dataLoss')
  @DocsEditable()
  @Experimental() // untriaged
  String get dataLoss => _blink.BlinkIDBVersionChangeEvent.instance.dataLoss_Getter_(unwrap_jso(this));
  
  @DomName('IDBVersionChangeEvent.dataLossMessage')
  @DocsEditable()
  @Experimental() // untriaged
  String get dataLossMessage => _blink.BlinkIDBVersionChangeEvent.instance.dataLossMessage_Getter_(unwrap_jso(this));
  
  @DomName('IDBVersionChangeEvent.newVersion')
  @DocsEditable()
  int get newVersion => _blink.BlinkIDBVersionChangeEvent.instance.newVersion_Getter_(unwrap_jso(this));
  
  @DomName('IDBVersionChangeEvent.oldVersion')
  @DocsEditable()
  int get oldVersion => _blink.BlinkIDBVersionChangeEvent.instance.oldVersion_Getter_(unwrap_jso(this));
  
}
