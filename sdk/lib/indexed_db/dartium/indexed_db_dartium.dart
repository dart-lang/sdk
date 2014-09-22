library dart.dom.indexed_db;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
import 'dart:_blink' as _blink;
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
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBCursor')
@Unstable()
class Cursor extends NativeFieldWrapperClass2 {
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

  @DomName('IDBCursor.direction')
  @DocsEditable()
  String get direction => _blink.BlinkIDBCursor.direction_Getter(this);

  @DomName('IDBCursor.key')
  @DocsEditable()
  Object get key => _blink.BlinkIDBCursor.key_Getter(this);

  @DomName('IDBCursor.primaryKey')
  @DocsEditable()
  Object get primaryKey => _blink.BlinkIDBCursor.primaryKey_Getter(this);

  @DomName('IDBCursor.source')
  @DocsEditable()
  Object get source => _blink.BlinkIDBCursor.source_Getter(this);

  @DomName('IDBCursor.advance')
  @DocsEditable()
  void advance(int count) => _blink.BlinkIDBCursor.advance_Callback_ul(this, count);

  @DomName('IDBCursor.continuePrimaryKey')
  @DocsEditable()
  @Experimental() // untriaged
  void continuePrimaryKey(Object key, Object primaryKey) => _blink.BlinkIDBCursor.continuePrimaryKey_Callback_ScriptValue_ScriptValue(this, key, primaryKey);

  @DomName('IDBCursor.delete')
  @DocsEditable()
  Request _delete() => _blink.BlinkIDBCursor.delete_Callback(this);

  @DomName('IDBCursor.next')
  @DocsEditable()
  @Experimental() // non-standard
  void next([Object key]) => _blink.BlinkIDBCursor.continue_Callback_ScriptValue(this, key);

  @DomName('IDBCursor.update')
  @DocsEditable()
  Request _update(Object value) => _blink.BlinkIDBCursor.update_Callback_ScriptValue(this, value);

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

  @DomName('IDBCursorWithValue.value')
  @DocsEditable()
  Object get value => _blink.BlinkIDBCursorWithValue.value_Getter(this);

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

  @DomName('IDBDatabase.name')
  @DocsEditable()
  String get name => _blink.BlinkIDBDatabase.name_Getter(this);

  @DomName('IDBDatabase.objectStoreNames')
  @DocsEditable()
  List<String> get objectStoreNames => _blink.BlinkIDBDatabase.objectStoreNames_Getter(this);

  @DomName('IDBDatabase.version')
  @DocsEditable()
  Object get version => _blink.BlinkIDBDatabase.version_Getter(this);

  @DomName('IDBDatabase.close')
  @DocsEditable()
  void close() => _blink.BlinkIDBDatabase.close_Callback(this);

  @DomName('IDBDatabase.createObjectStore')
  @DocsEditable()
  ObjectStore _createObjectStore(String name, [Map options]) => _blink.BlinkIDBDatabase.createObjectStore_Callback_DOMString_Dictionary(this, name, options);

  @DomName('IDBDatabase.deleteObjectStore')
  @DocsEditable()
  void deleteObjectStore(String name) => _blink.BlinkIDBDatabase.deleteObjectStore_Callback_DOMString(this, name);

  Transaction transaction(storeName_OR_storeNames, String mode) {
    if ((mode is String || mode == null) && (storeName_OR_storeNames is String || storeName_OR_storeNames == null)) {
      return _blink.BlinkIDBDatabase.transaction_Callback_DOMString_DOMString(this, storeName_OR_storeNames, mode);
    }
    if ((mode is String || mode == null) && (storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null)) {
      return _blink.BlinkIDBDatabase.transaction_Callback_SEQ_DOMString_SEQ_DOMString(this, storeName_OR_storeNames, mode);
    }
    if ((mode is String || mode == null) && (storeName_OR_storeNames is DomStringList || storeName_OR_storeNames == null)) {
      return _blink.BlinkIDBDatabase.transaction_Callback_DOMStringList_DOMString(this, storeName_OR_storeNames, mode);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('IDBDatabase.transactionList')
  @DocsEditable()
  Transaction transactionList(List<String> storeNames, String mode) => _blink.BlinkIDBDatabase.transaction_Callback_SEQ_DOMString_SEQ_DOMString(this, storeNames, mode);

  @DomName('IDBDatabase.transactionStore')
  @DocsEditable()
  Transaction transactionStore(String storeName, String mode) => _blink.BlinkIDBDatabase.transaction_Callback_DOMString_DOMString(this, storeName, mode);

  @DomName('IDBDatabase.transactionStores')
  @DocsEditable()
  Transaction transactionStores(List<String> storeNames, String mode) => _blink.BlinkIDBDatabase.transaction_Callback_DOMStringList_DOMString(this, storeNames, mode);

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
class IdbFactory extends NativeFieldWrapperClass2 {
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

  @DomName('IDBFactory.cmp')
  @DocsEditable()
  int cmp(Object first, Object second) => _blink.BlinkIDBFactory.cmp_Callback_ScriptValue_ScriptValue(this, first, second);

  @DomName('IDBFactory.deleteDatabase')
  @DocsEditable()
  OpenDBRequest _deleteDatabase(String name) => _blink.BlinkIDBFactory.deleteDatabase_Callback_DOMString(this, name);

  OpenDBRequest _open(String name, [int version]) {
    if (version != null) {
      return _blink.BlinkIDBFactory.open_Callback_DOMString_ull(this, name, version);
    }
    return _blink.BlinkIDBFactory.open_Callback_DOMString(this, name);
  }

  @DomName('IDBFactory.webkitGetDatabaseNames')
  @DocsEditable()
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental()
  Request _webkitGetDatabaseNames() => _blink.BlinkIDBFactory.webkitGetDatabaseNames_Callback(this);

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
class Index extends NativeFieldWrapperClass2 {
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
      request = _openCursor(key_OR_range);
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
      request = _openKeyCursor(key_OR_range);
    } else {
      request = _openKeyCursor(key_OR_range, direction);
    }
    return ObjectStore._cursorStreamFromResult(request, autoAdvance);
  }

    // To suppress missing implicit constructor warnings.
  factory Index._() { throw new UnsupportedError("Not supported"); }

  @DomName('IDBIndex.keyPath')
  @DocsEditable()
  Object get keyPath => _blink.BlinkIDBIndex.keyPath_Getter(this);

  @DomName('IDBIndex.multiEntry')
  @DocsEditable()
  bool get multiEntry => _blink.BlinkIDBIndex.multiEntry_Getter(this);

  @DomName('IDBIndex.name')
  @DocsEditable()
  String get name => _blink.BlinkIDBIndex.name_Getter(this);

  @DomName('IDBIndex.objectStore')
  @DocsEditable()
  ObjectStore get objectStore => _blink.BlinkIDBIndex.objectStore_Getter(this);

  @DomName('IDBIndex.unique')
  @DocsEditable()
  bool get unique => _blink.BlinkIDBIndex.unique_Getter(this);

  @DomName('IDBIndex.count')
  @DocsEditable()
  Request _count(Object key) => _blink.BlinkIDBIndex.count_Callback_ScriptValue(this, key);

  @DomName('IDBIndex.get')
  @DocsEditable()
  Request _get(Object key) => _blink.BlinkIDBIndex.get_Callback_ScriptValue(this, key);

  @DomName('IDBIndex.getKey')
  @DocsEditable()
  Request _getKey(Object key) => _blink.BlinkIDBIndex.getKey_Callback_ScriptValue(this, key);

  @DomName('IDBIndex.openCursor')
  @DocsEditable()
  Request _openCursor(Object key, [String direction]) => _blink.BlinkIDBIndex.openCursor_Callback_ScriptValue_DOMString(this, key, direction);

  @DomName('IDBIndex.openKeyCursor')
  @DocsEditable()
  Request _openKeyCursor(Object key, [String direction]) => _blink.BlinkIDBIndex.openKeyCursor_Callback_ScriptValue_DOMString(this, key, direction);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBKeyRange')
@Unstable()
class KeyRange extends NativeFieldWrapperClass2 {
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

  @DomName('IDBKeyRange.lower')
  @DocsEditable()
  Object get lower => _blink.BlinkIDBKeyRange.lower_Getter(this);

  @DomName('IDBKeyRange.lowerOpen')
  @DocsEditable()
  bool get lowerOpen => _blink.BlinkIDBKeyRange.lowerOpen_Getter(this);

  @DomName('IDBKeyRange.upper')
  @DocsEditable()
  Object get upper => _blink.BlinkIDBKeyRange.upper_Getter(this);

  @DomName('IDBKeyRange.upperOpen')
  @DocsEditable()
  bool get upperOpen => _blink.BlinkIDBKeyRange.upperOpen_Getter(this);

  @DomName('IDBKeyRange.bound_')
  @DocsEditable()
  @Experimental() // non-standard
  static KeyRange bound_(Object lower, Object upper, [bool lowerOpen, bool upperOpen]) => _blink.BlinkIDBKeyRange.bound_Callback_ScriptValue_ScriptValue_boolean_boolean(lower, upper, lowerOpen, upperOpen);

  @DomName('IDBKeyRange.lowerBound_')
  @DocsEditable()
  @Experimental() // non-standard
  static KeyRange lowerBound_(Object bound, [bool open]) => _blink.BlinkIDBKeyRange.lowerBound_Callback_ScriptValue_boolean(bound, open);

  @DomName('IDBKeyRange.only_')
  @DocsEditable()
  @Experimental() // non-standard
  static KeyRange only_(Object value) => _blink.BlinkIDBKeyRange.only_Callback_ScriptValue(value);

  @DomName('IDBKeyRange.upperBound_')
  @DocsEditable()
  @Experimental() // non-standard
  static KeyRange upperBound_(Object bound, [bool open]) => _blink.BlinkIDBKeyRange.upperBound_Callback_ScriptValue_boolean(bound, open);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBObjectStore')
@Unstable()
class ObjectStore extends NativeFieldWrapperClass2 {

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

  @DomName('IDBObjectStore.autoIncrement')
  @DocsEditable()
  bool get autoIncrement => _blink.BlinkIDBObjectStore.autoIncrement_Getter(this);

  @DomName('IDBObjectStore.indexNames')
  @DocsEditable()
  List<String> get indexNames => _blink.BlinkIDBObjectStore.indexNames_Getter(this);

  @DomName('IDBObjectStore.keyPath')
  @DocsEditable()
  Object get keyPath => _blink.BlinkIDBObjectStore.keyPath_Getter(this);

  @DomName('IDBObjectStore.name')
  @DocsEditable()
  String get name => _blink.BlinkIDBObjectStore.name_Getter(this);

  @DomName('IDBObjectStore.transaction')
  @DocsEditable()
  Transaction get transaction => _blink.BlinkIDBObjectStore.transaction_Getter(this);

  @DomName('IDBObjectStore.add')
  @DocsEditable()
  Request _add(Object value, [Object key]) => _blink.BlinkIDBObjectStore.add_Callback_ScriptValue_ScriptValue(this, value, key);

  @DomName('IDBObjectStore.clear')
  @DocsEditable()
  Request _clear() => _blink.BlinkIDBObjectStore.clear_Callback(this);

  @DomName('IDBObjectStore.count')
  @DocsEditable()
  Request _count(Object key) => _blink.BlinkIDBObjectStore.count_Callback_ScriptValue(this, key);

  Index _createIndex(String name, keyPath, [Map options]) {
    if ((options is Map || options == null) && (keyPath is String || keyPath == null) && (name is String || name == null)) {
      return _blink.BlinkIDBObjectStore.createIndex_Callback_DOMString_DOMString_Dictionary(this, name, keyPath, options);
    }
    if ((options is Map || options == null) && (keyPath is List<String> || keyPath == null) && (name is String || name == null)) {
      return _blink.BlinkIDBObjectStore.createIndex_Callback_DOMString_SEQ_DOMString_SEQ_Dictionary(this, name, keyPath, options);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DomName('IDBObjectStore.delete')
  @DocsEditable()
  Request _delete(Object key) => _blink.BlinkIDBObjectStore.delete_Callback_ScriptValue(this, key);

  @DomName('IDBObjectStore.deleteIndex')
  @DocsEditable()
  void deleteIndex(String name) => _blink.BlinkIDBObjectStore.deleteIndex_Callback_DOMString(this, name);

  @DomName('IDBObjectStore.get')
  @DocsEditable()
  Request _get(Object key) => _blink.BlinkIDBObjectStore.get_Callback_ScriptValue(this, key);

  @DomName('IDBObjectStore.index')
  @DocsEditable()
  Index index(String name) => _blink.BlinkIDBObjectStore.index_Callback_DOMString(this, name);

  @DomName('IDBObjectStore.openCursor')
  @DocsEditable()
  Request _openCursor(Object range, [String direction]) => _blink.BlinkIDBObjectStore.openCursor_Callback_ScriptValue_DOMString(this, range, direction);

  @DomName('IDBObjectStore.openKeyCursor')
  @DocsEditable()
  @Experimental() // untriaged
  Request openKeyCursor(Object range, String direction) => _blink.BlinkIDBObjectStore.openKeyCursor_Callback_ScriptValue_DOMString(this, range, direction);

  @DomName('IDBObjectStore.put')
  @DocsEditable()
  Request _put(Object value, [Object key]) => _blink.BlinkIDBObjectStore.put_Callback_ScriptValue_ScriptValue(this, value, key);


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

  @DomName('IDBRequest.error')
  @DocsEditable()
  DomError get error => _blink.BlinkIDBRequest.error_Getter(this);

  @DomName('IDBRequest.readyState')
  @DocsEditable()
  String get readyState => _blink.BlinkIDBRequest.readyState_Getter(this);

  @DomName('IDBRequest.result')
  @DocsEditable()
  Object get result => _blink.BlinkIDBRequest.result_Getter(this);

  @DomName('IDBRequest.source')
  @DocsEditable()
  Object get source => _blink.BlinkIDBRequest.source_Getter(this);

  @DomName('IDBRequest.transaction')
  @DocsEditable()
  Transaction get transaction => _blink.BlinkIDBRequest.transaction_Getter(this);

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

  @DomName('IDBTransaction.db')
  @DocsEditable()
  Database get db => _blink.BlinkIDBTransaction.db_Getter(this);

  @DomName('IDBTransaction.error')
  @DocsEditable()
  DomError get error => _blink.BlinkIDBTransaction.error_Getter(this);

  @DomName('IDBTransaction.mode')
  @DocsEditable()
  String get mode => _blink.BlinkIDBTransaction.mode_Getter(this);

  @DomName('IDBTransaction.abort')
  @DocsEditable()
  void abort() => _blink.BlinkIDBTransaction.abort_Callback(this);

  @DomName('IDBTransaction.objectStore')
  @DocsEditable()
  ObjectStore objectStore(String name) => _blink.BlinkIDBTransaction.objectStore_Callback_DOMString(this, name);

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

  @DomName('IDBVersionChangeEvent.dataLoss')
  @DocsEditable()
  @Experimental() // untriaged
  String get dataLoss => _blink.BlinkIDBVersionChangeEvent.dataLoss_Getter(this);

  @DomName('IDBVersionChangeEvent.dataLossMessage')
  @DocsEditable()
  @Experimental() // untriaged
  String get dataLossMessage => _blink.BlinkIDBVersionChangeEvent.dataLossMessage_Getter(this);

  @DomName('IDBVersionChangeEvent.newVersion')
  @DocsEditable()
  int get newVersion => _blink.BlinkIDBVersionChangeEvent.newVersion_Getter(this);

  @DomName('IDBVersionChangeEvent.oldVersion')
  @DocsEditable()
  int get oldVersion => _blink.BlinkIDBVersionChangeEvent.oldVersion_Getter(this);

}
