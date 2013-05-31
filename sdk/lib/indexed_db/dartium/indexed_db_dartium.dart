library dart.dom.indexed_db;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
import 'dart:nativewrappers';
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
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBCursor')
@Unstable
class Cursor extends NativeFieldWrapperClass1 {
  @DomName('IDBCursor.delete')
  Future delete() {
   try {
      return _completeRequest($dom_delete());
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBCursor.value')
  Future update(value) {
   try {
      return _completeRequest($dom_update(value));
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

    Cursor.internal();

  @DomName('IDBCursor.direction')
  @DocsEditable
  String get direction native "IDBCursor_direction_Getter";

  @DomName('IDBCursor.key')
  @DocsEditable
  Object get key native "IDBCursor_key_Getter";

  @DomName('IDBCursor.primaryKey')
  @DocsEditable
  Object get primaryKey native "IDBCursor_primaryKey_Getter";

  @DomName('IDBCursor.source')
  @DocsEditable
  dynamic get source native "IDBCursor_source_Getter";

  @DomName('IDBCursor.advance')
  @DocsEditable
  void advance(int count) native "IDBCursor_advance_Callback";

  @DomName('IDBCursor.delete')
  @DocsEditable
  Request $dom_delete() native "IDBCursor_delete_Callback";

  @DomName('IDBCursor.next')
  @DocsEditable
  @Experimental // non-standard
  void next([Object key]) native "IDBCursor_next_Callback";

  @DomName('IDBCursor.update')
  @DocsEditable
  Request $dom_update(Object value) native "IDBCursor_update_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBCursorWithValue')
@Unstable
class CursorWithValue extends Cursor {
  CursorWithValue.internal() : super.internal();

  @DomName('IDBCursorWithValue.value')
  @DocsEditable
  Object get value native "IDBCursorWithValue_value_Getter";

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('IDBDatabase')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental
@Unstable
class Database extends EventTarget {
  @DomName('IDBDatabase.createObjectStore')
  @DocsEditable
  ObjectStore createObjectStore(String name,
      {String keyPath, bool autoIncrement}) {
    var options = {};
    if (keyPath != null) {
      options['keyPath'] = keyPath;
    }
    if (autoIncrement != null) {
      options['autoIncrement'] = autoIncrement;
    }

    return $dom_createObjectStore(name, options);
  }


  Database.internal() : super.internal();

  @DomName('IDBDatabase.abortEvent')
  @DocsEditable
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DomName('IDBDatabase.errorEvent')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('IDBDatabase.versionchangeEvent')
  @DocsEditable
  static const EventStreamProvider<VersionChangeEvent> versionChangeEvent = const EventStreamProvider<VersionChangeEvent>('versionchange');

  @DomName('IDBDatabase.name')
  @DocsEditable
  String get name native "IDBDatabase_name_Getter";

  @DomName('IDBDatabase.objectStoreNames')
  @DocsEditable
  List<String> get objectStoreNames native "IDBDatabase_objectStoreNames_Getter";

  @DomName('IDBDatabase.version')
  @DocsEditable
  dynamic get version native "IDBDatabase_version_Getter";

  @DomName('IDBDatabase.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_addEventListener_Callback";

  @DomName('IDBDatabase.close')
  @DocsEditable
  void close() native "IDBDatabase_close_Callback";

  @DomName('IDBDatabase.createObjectStore')
  @DocsEditable
  ObjectStore $dom_createObjectStore(String name, [Map options]) native "IDBDatabase_createObjectStore_Callback";

  @DomName('IDBDatabase.deleteObjectStore')
  @DocsEditable
  void deleteObjectStore(String name) native "IDBDatabase_deleteObjectStore_Callback";

  @DomName('IDBDatabase.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native "IDBDatabase_dispatchEvent_Callback";

  @DomName('IDBDatabase.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_removeEventListener_Callback";

  Transaction transaction(storeName_OR_storeNames, String mode) {
    if ((storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_1(storeName_OR_storeNames, mode);
    }
    if ((storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_2(storeName_OR_storeNames, mode);
    }
    if ((storeName_OR_storeNames is String || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_3(storeName_OR_storeNames, mode);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Transaction _transaction_1(storeName_OR_storeNames, mode) native "IDBDatabase__transaction_1_Callback";

  Transaction _transaction_2(storeName_OR_storeNames, mode) native "IDBDatabase__transaction_2_Callback";

  Transaction _transaction_3(storeName_OR_storeNames, mode) native "IDBDatabase__transaction_3_Callback";

  @DomName('IDBDatabase.onabort')
  @DocsEditable
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DomName('IDBDatabase.onerror')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('IDBDatabase.onversionchange')
  @DocsEditable
  Stream<VersionChangeEvent> get onVersionChange => versionChangeEvent.forTarget(this);
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBFactory')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental
@Unstable
class IdbFactory extends NativeFieldWrapperClass1 {
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
        request = $dom_open(name, version);
      } else {
        request = $dom_open(name);
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
      var request = $dom_deleteDatabase(name);

      if (onBlocked != null) {
        request.onBlocked.listen(onBlocked);
      }
      var completer = new Completer.sync();
      request.onSuccess.listen((e) {
        completer.complete(this);
      });
      request.onError.listen((e) {
        completer.completeError(e);
      });
      return completer.future;
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBFactory.getDatabaseNames')
  @SupportedBrowser(SupportedBrowser.CHROME)
  @Experimental
  Future<List<String>> getDatabaseNames() {
    try {
      var request = $dom_webkitGetDatabaseNames();

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

  IdbFactory.internal();

  @DomName('IDBFactory.cmp')
  @DocsEditable
  int cmp(Object first, Object second) native "IDBFactory_cmp_Callback";

  @DomName('IDBFactory.deleteDatabase')
  @DocsEditable
  OpenDBRequest $dom_deleteDatabase(String name) native "IDBFactory_deleteDatabase_Callback";

  OpenDBRequest $dom_open(String name, [int version]) {
    if (?version) {
      return _open_1(name, version);
    }
    return _open_2(name);
  }

  OpenDBRequest _open_1(name, version) native "IDBFactory__open_1_Callback";

  OpenDBRequest _open_2(name) native "IDBFactory__open_2_Callback";

  @DomName('IDBFactory.webkitGetDatabaseNames')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  Request $dom_webkitGetDatabaseNames() native "IDBFactory_webkitGetDatabaseNames_Callback";

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
  request.onError.listen((e) {
    completer.completeError(e);
  });
  return completer.future;
}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBIndex')
@Unstable
class Index extends NativeFieldWrapperClass1 {
  @DomName('IDBIndex.count')
  Future<int> count([key_OR_range]) {
   try {
      var request;
      if (key_OR_range != null) {
        request = $dom_count(key_OR_range);
      } else {
        request = $dom_count();
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBIndex.get')
  Future get(key) {
    try {
      var request = $dom_get(key);

      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBIndex.getKey')
  Future getKey(key) {
    try {
      var request = $dom_getKey(key);

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
      request = $dom_openCursor(key_OR_range);
    } else {
      request = $dom_openCursor(key_OR_range, direction);
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
      request = $dom_openKeyCursor(key_OR_range);
    } else {
      request = $dom_openKeyCursor(key_OR_range, direction);
    }
    return ObjectStore._cursorStreamFromResult(request, autoAdvance);
  }

    Index.internal();

  @DomName('IDBIndex.keyPath')
  @DocsEditable
  dynamic get keyPath native "IDBIndex_keyPath_Getter";

  @DomName('IDBIndex.multiEntry')
  @DocsEditable
  bool get multiEntry native "IDBIndex_multiEntry_Getter";

  @DomName('IDBIndex.name')
  @DocsEditable
  String get name native "IDBIndex_name_Getter";

  @DomName('IDBIndex.objectStore')
  @DocsEditable
  ObjectStore get objectStore native "IDBIndex_objectStore_Getter";

  @DomName('IDBIndex.unique')
  @DocsEditable
  bool get unique native "IDBIndex_unique_Getter";

  Request $dom_count([key_OR_range]) {
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_1(key_OR_range);
    }
    if (?key_OR_range) {
      return _count_2(key_OR_range);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _count_1(key_OR_range) native "IDBIndex__count_1_Callback";

  Request _count_2(key_OR_range) native "IDBIndex__count_2_Callback";

  Request $dom_get(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    if (?key) {
      return _get_2(key);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _get_1(key) native "IDBIndex__get_1_Callback";

  Request _get_2(key) native "IDBIndex__get_2_Callback";

  Request $dom_getKey(key) {
    if ((key is KeyRange || key == null)) {
      return _getKey_1(key);
    }
    if (?key) {
      return _getKey_2(key);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _getKey_1(key) native "IDBIndex__getKey_1_Callback";

  Request _getKey_2(key) native "IDBIndex__getKey_2_Callback";

  Request $dom_openCursor([key_OR_range, String direction]) {
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_1(key_OR_range, direction);
    }
    if (?key_OR_range && (direction is String || direction == null)) {
      return _openCursor_2(key_OR_range, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _openCursor_1(key_OR_range, direction) native "IDBIndex__openCursor_1_Callback";

  Request _openCursor_2(key_OR_range, direction) native "IDBIndex__openCursor_2_Callback";

  Request $dom_openKeyCursor([key_OR_range, String direction]) {
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openKeyCursor_1(key_OR_range, direction);
    }
    if (?key_OR_range && (direction is String || direction == null)) {
      return _openKeyCursor_2(key_OR_range, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _openKeyCursor_1(key_OR_range, direction) native "IDBIndex__openKeyCursor_1_Callback";

  Request _openKeyCursor_2(key_OR_range, direction) native "IDBIndex__openKeyCursor_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBKeyRange')
@Unstable
class KeyRange extends NativeFieldWrapperClass1 {
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

  KeyRange.internal();

  @DomName('IDBKeyRange.lower')
  @DocsEditable
  Object get lower native "IDBKeyRange_lower_Getter";

  @DomName('IDBKeyRange.lowerOpen')
  @DocsEditable
  bool get lowerOpen native "IDBKeyRange_lowerOpen_Getter";

  @DomName('IDBKeyRange.upper')
  @DocsEditable
  Object get upper native "IDBKeyRange_upper_Getter";

  @DomName('IDBKeyRange.upperOpen')
  @DocsEditable
  bool get upperOpen native "IDBKeyRange_upperOpen_Getter";

  @DomName('IDBKeyRange.bound_')
  @DocsEditable
  @Experimental // non-standard
  static KeyRange bound_(Object lower, Object upper, [bool lowerOpen, bool upperOpen]) native "IDBKeyRange_bound__Callback";

  @DomName('IDBKeyRange.lowerBound_')
  @DocsEditable
  @Experimental // non-standard
  static KeyRange lowerBound_(Object bound, [bool open]) native "IDBKeyRange_lowerBound__Callback";

  @DomName('IDBKeyRange.only_')
  @DocsEditable
  @Experimental // non-standard
  static KeyRange only_(Object value) native "IDBKeyRange_only__Callback";

  @DomName('IDBKeyRange.upperBound_')
  @DocsEditable
  @Experimental // non-standard
  static KeyRange upperBound_(Object bound, [bool open]) native "IDBKeyRange_upperBound__Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBObjectStore')
@Unstable
class ObjectStore extends NativeFieldWrapperClass1 {

  @DomName('IDBObjectStore.add')
  Future add(value, [key]) {
    try {
      var request;
      if (key != null) {
        request = $dom_add(value, key);
      } else {
        request = $dom_add(value);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.clear')
  Future clear() {
    try {
      return _completeRequest($dom_clear());
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.delete')
  Future delete(key_OR_keyRange){
    try {
      return _completeRequest($dom_delete(key_OR_keyRange));
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.count')
  Future<int> count([key_OR_range]) {
   try {
      var request;
      if (key_OR_range != null) {
        request = $dom_count(key_OR_range);
      } else {
        request = $dom_count();
      }
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
        request = $dom_put(value, key);
      } else {
        request = $dom_put(value);
      }
      return _completeRequest(request);
    } catch (e, stacktrace) {
      return new Future.error(e, stacktrace);
    }
  }

  @DomName('IDBObjectStore.get')
  Future getObject(key) {
    try {
      var request = $dom_get(key);

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
      request = $dom_openCursor(key_OR_range);
    } else {
      request = $dom_openCursor(key_OR_range, direction);
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

    return $dom_createIndex(name, keyPath, options);
  }

  ObjectStore.internal();

  @DomName('IDBObjectStore.autoIncrement')
  @DocsEditable
  bool get autoIncrement native "IDBObjectStore_autoIncrement_Getter";

  @DomName('IDBObjectStore.indexNames')
  @DocsEditable
  List<String> get indexNames native "IDBObjectStore_indexNames_Getter";

  @DomName('IDBObjectStore.keyPath')
  @DocsEditable
  dynamic get keyPath native "IDBObjectStore_keyPath_Getter";

  @DomName('IDBObjectStore.name')
  @DocsEditable
  String get name native "IDBObjectStore_name_Getter";

  @DomName('IDBObjectStore.transaction')
  @DocsEditable
  Transaction get transaction native "IDBObjectStore_transaction_Getter";

  @DomName('IDBObjectStore.add')
  @DocsEditable
  Request $dom_add(Object value, [Object key]) native "IDBObjectStore_add_Callback";

  @DomName('IDBObjectStore.clear')
  @DocsEditable
  Request $dom_clear() native "IDBObjectStore_clear_Callback";

  Request $dom_count([key_OR_range]) {
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_1(key_OR_range);
    }
    if (?key_OR_range) {
      return _count_2(key_OR_range);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _count_1(key_OR_range) native "IDBObjectStore__count_1_Callback";

  Request _count_2(key_OR_range) native "IDBObjectStore__count_2_Callback";

  Index $dom_createIndex(String name, keyPath, [Map options]) {
    if ((name is String || name == null) && (keyPath is List<String> || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_1(name, keyPath, options);
    }
    if ((name is String || name == null) && (keyPath is String || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_2(name, keyPath, options);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Index _createIndex_1(name, keyPath, options) native "IDBObjectStore__createIndex_1_Callback";

  Index _createIndex_2(name, keyPath, options) native "IDBObjectStore__createIndex_2_Callback";

  Request $dom_delete(key_OR_keyRange) {
    if ((key_OR_keyRange is KeyRange || key_OR_keyRange == null)) {
      return _delete_1(key_OR_keyRange);
    }
    if (?key_OR_keyRange) {
      return _delete_2(key_OR_keyRange);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _delete_1(key_OR_keyRange) native "IDBObjectStore__delete_1_Callback";

  Request _delete_2(key_OR_keyRange) native "IDBObjectStore__delete_2_Callback";

  @DomName('IDBObjectStore.deleteIndex')
  @DocsEditable
  void deleteIndex(String name) native "IDBObjectStore_deleteIndex_Callback";

  Request $dom_get(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    if (?key) {
      return _get_2(key);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _get_1(key) native "IDBObjectStore__get_1_Callback";

  Request _get_2(key) native "IDBObjectStore__get_2_Callback";

  @DomName('IDBObjectStore.index')
  @DocsEditable
  Index index(String name) native "IDBObjectStore_index_Callback";

  Request $dom_openCursor([key_OR_range, String direction]) {
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_1(key_OR_range, direction);
    }
    if (?key_OR_range && (direction is String || direction == null)) {
      return _openCursor_2(key_OR_range, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  Request _openCursor_1(key_OR_range, direction) native "IDBObjectStore__openCursor_1_Callback";

  Request _openCursor_2(key_OR_range, direction) native "IDBObjectStore__openCursor_2_Callback";

  @DomName('IDBObjectStore.put')
  @DocsEditable
  Request $dom_put(Object value, [Object key]) native "IDBObjectStore_put_Callback";


  /**
   * Helper for iterating over cursors in a request.
   */
  static Stream<Cursor> _cursorStreamFromResult(Request request,
      bool autoAdvance) {
    // TODO: need to guarantee that the controller provides the values
    // immediately as waiting until the next tick will cause the transaction to
    // close.
    var controller = new StreamController(sync: true);

    request.onError.listen((e) {
      //TODO: Report stacktrace once issue 4061 is resolved.
      controller.addError(e);
    });

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


@DocsEditable
@DomName('IDBOpenDBRequest')
@Unstable
class OpenDBRequest extends Request implements EventTarget {
  OpenDBRequest.internal() : super.internal();

  @DomName('IDBOpenDBRequest.blockedEvent')
  @DocsEditable
  static const EventStreamProvider<Event> blockedEvent = const EventStreamProvider<Event>('blocked');

  @DomName('IDBOpenDBRequest.upgradeneededEvent')
  @DocsEditable
  static const EventStreamProvider<VersionChangeEvent> upgradeNeededEvent = const EventStreamProvider<VersionChangeEvent>('upgradeneeded');

  @DomName('IDBOpenDBRequest.onblocked')
  @DocsEditable
  Stream<Event> get onBlocked => blockedEvent.forTarget(this);

  @DomName('IDBOpenDBRequest.onupgradeneeded')
  @DocsEditable
  Stream<VersionChangeEvent> get onUpgradeNeeded => upgradeNeededEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBRequest')
@Unstable
class Request extends EventTarget {
  Request.internal() : super.internal();

  @DomName('IDBRequest.errorEvent')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('IDBRequest.successEvent')
  @DocsEditable
  static const EventStreamProvider<Event> successEvent = const EventStreamProvider<Event>('success');

  @DomName('IDBRequest.error')
  @DocsEditable
  DomError get error native "IDBRequest_error_Getter";

  @DomName('IDBRequest.readyState')
  @DocsEditable
  String get readyState native "IDBRequest_readyState_Getter";

  @DomName('IDBRequest.result')
  @DocsEditable
  dynamic get result native "IDBRequest_result_Getter";

  @DomName('IDBRequest.source')
  @DocsEditable
  dynamic get source native "IDBRequest_source_Getter";

  @DomName('IDBRequest.transaction')
  @DocsEditable
  Transaction get transaction native "IDBRequest_transaction_Getter";

  @DomName('IDBRequest.webkitErrorMessage')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  String get errorMessage native "IDBRequest_webkitErrorMessage_Getter";

  @DomName('IDBRequest.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_addEventListener_Callback";

  @DomName('IDBRequest.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native "IDBRequest_dispatchEvent_Callback";

  @DomName('IDBRequest.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_removeEventListener_Callback";

  @DomName('IDBRequest.onerror')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DomName('IDBRequest.onsuccess')
  @DocsEditable
  Stream<Event> get onSuccess => successEvent.forTarget(this);

}
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DomName('IDBTransaction')
@Unstable
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
      completer.completeError(e);
    });

    return completer.future;
  }

  Transaction.internal() : super.internal();

  @DomName('IDBTransaction.abortEvent')
  @DocsEditable
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DomName('IDBTransaction.completeEvent')
  @DocsEditable
  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  @DomName('IDBTransaction.errorEvent')
  @DocsEditable
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DomName('IDBTransaction.db')
  @DocsEditable
  Database get db native "IDBTransaction_db_Getter";

  @DomName('IDBTransaction.error')
  @DocsEditable
  DomError get error native "IDBTransaction_error_Getter";

  @DomName('IDBTransaction.mode')
  @DocsEditable
  String get mode native "IDBTransaction_mode_Getter";

  @DomName('IDBTransaction.webkitErrorMessage')
  @DocsEditable
  @SupportedBrowser(SupportedBrowser.CHROME)
  @SupportedBrowser(SupportedBrowser.SAFARI)
  @Experimental
  String get errorMessage native "IDBTransaction_webkitErrorMessage_Getter";

  @DomName('IDBTransaction.abort')
  @DocsEditable
  void abort() native "IDBTransaction_abort_Callback";

  @DomName('IDBTransaction.addEventListener')
  @DocsEditable
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_addEventListener_Callback";

  @DomName('IDBTransaction.dispatchEvent')
  @DocsEditable
  bool dispatchEvent(Event evt) native "IDBTransaction_dispatchEvent_Callback";

  @DomName('IDBTransaction.objectStore')
  @DocsEditable
  ObjectStore objectStore(String name) native "IDBTransaction_objectStore_Callback";

  @DomName('IDBTransaction.removeEventListener')
  @DocsEditable
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_removeEventListener_Callback";

  @DomName('IDBTransaction.onabort')
  @DocsEditable
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DomName('IDBTransaction.oncomplete')
  @DocsEditable
  Stream<Event> get onComplete => completeEvent.forTarget(this);

  @DomName('IDBTransaction.onerror')
  @DocsEditable
  Stream<Event> get onError => errorEvent.forTarget(this);

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBVersionChangeEvent')
@Unstable
class VersionChangeEvent extends Event {
  VersionChangeEvent.internal() : super.internal();

  @DomName('IDBVersionChangeEvent.newVersion')
  @DocsEditable
  dynamic get newVersion native "IDBVersionChangeEvent_newVersion_Getter";

  @DomName('IDBVersionChangeEvent.oldVersion')
  @DocsEditable
  dynamic get oldVersion native "IDBVersionChangeEvent_oldVersion_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBAny')
@deprecated // nonstandard
abstract class _IDBAny extends NativeFieldWrapperClass1 {
  _IDBAny.internal();

}
