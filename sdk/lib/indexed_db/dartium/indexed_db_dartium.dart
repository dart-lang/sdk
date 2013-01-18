library indexed_db;

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
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBCursor')
class Cursor extends NativeFieldWrapperClass1 {
  Cursor.internal();

  @DocsEditable
  @DomName('IDBCursor.direction')
  String get direction native "IDBCursor_direction_Getter";

  @DocsEditable
  @DomName('IDBCursor.key')
  Object get key native "IDBCursor_key_Getter";

  @DocsEditable
  @DomName('IDBCursor.primaryKey')
  Object get primaryKey native "IDBCursor_primaryKey_Getter";

  @DocsEditable
  @DomName('IDBCursor.source')
  dynamic get source native "IDBCursor_source_Getter";

  @DocsEditable
  @DomName('IDBCursor.advance')
  void advance(int count) native "IDBCursor_advance_Callback";

  void continueFunction([/*IDBKey*/ key]) {
    if (?key) {
      _continue_1(key);
      return;
    }
    _continue_2();
  }

  @DocsEditable
  @DomName('IDBCursor.continue_1')
  void _continue_1(key) native "IDBCursor_continue_1_Callback";

  @DocsEditable
  @DomName('IDBCursor.continue_2')
  void _continue_2() native "IDBCursor_continue_2_Callback";

  @DocsEditable
  @DomName('IDBCursor.delete')
  Request delete() native "IDBCursor_delete_Callback";

  @DocsEditable
  @DomName('IDBCursor.update')
  Request update(Object value) native "IDBCursor_update_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBCursorWithValue')
class CursorWithValue extends Cursor {
  CursorWithValue.internal() : super.internal();

  @DocsEditable
  @DomName('IDBCursorWithValue.value')
  Object get value native "IDBCursorWithValue_value_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBDatabase')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
class Database extends EventTarget {
  Database.internal() : super.internal();

  @DocsEditable
  @DomName('IDBDatabase.abort')
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DocsEditable
  @DomName('IDBDatabase.error')
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('IDBDatabase.versionchange')
  static const EventStreamProvider<UpgradeNeededEvent> versionChangeEvent = const EventStreamProvider<UpgradeNeededEvent>('versionchange');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  DatabaseEvents get on =>
    new DatabaseEvents(this);

  @DocsEditable
  @DomName('IDBDatabase.name')
  String get name native "IDBDatabase_name_Getter";

  @DocsEditable
  @DomName('IDBDatabase.objectStoreNames')
  List<String> get objectStoreNames native "IDBDatabase_objectStoreNames_Getter";

  @DocsEditable
  @DomName('IDBDatabase.version')
  dynamic get version native "IDBDatabase_version_Getter";

  @DocsEditable
  @DomName('IDBDatabase.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_addEventListener_Callback";

  @DocsEditable
  @DomName('IDBDatabase.close')
  void close() native "IDBDatabase_close_Callback";

  @DocsEditable
  @DomName('IDBDatabase.createObjectStore')
  ObjectStore createObjectStore(String name, [Map options]) native "IDBDatabase_createObjectStore_Callback";

  @DocsEditable
  @DomName('IDBDatabase.deleteObjectStore')
  void deleteObjectStore(String name) native "IDBDatabase_deleteObjectStore_Callback";

  @DocsEditable
  @DomName('IDBDatabase.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native "IDBDatabase_dispatchEvent_Callback";

  @DocsEditable
  @DomName('IDBDatabase.removeEventListener')
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

  @DocsEditable
  @DomName('IDBDatabase.transaction_1')
  Transaction _transaction_1(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_1_Callback";

  @DocsEditable
  @DomName('IDBDatabase.transaction_2')
  Transaction _transaction_2(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_2_Callback";

  @DocsEditable
  @DomName('IDBDatabase.transaction_3')
  Transaction _transaction_3(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_3_Callback";

  @DocsEditable
  @DomName('IDBDatabase.abort')
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DocsEditable
  @DomName('IDBDatabase.error')
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DocsEditable
  @DomName('IDBDatabase.versionchange')
  Stream<UpgradeNeededEvent> get onVersionChange => versionChangeEvent.forTarget(this);

}

@DocsEditable
class DatabaseEvents extends Events {
  @DocsEditable
  DatabaseEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get versionChange => this['versionchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('IDBFactory')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
class IdbFactory extends NativeFieldWrapperClass1 {
  /**
   * Checks to see if Indexed DB is supported on the current platform.
   */
  static bool get supported {
    return true;
  }

  IdbFactory.internal();

  @DocsEditable
  @DomName('IDBFactory.cmp')
  int cmp(/*IDBKey*/ first, /*IDBKey*/ second) native "IDBFactory_cmp_Callback";

  @DocsEditable
  @DomName('IDBFactory.deleteDatabase')
  VersionChangeRequest deleteDatabase(String name) native "IDBFactory_deleteDatabase_Callback";

  OpenDBRequest open(String name, [int version]) {
    if (?version) {
      return _open_1(name, version);
    }
    return _open_2(name);
  }

  @DocsEditable
  @DomName('IDBFactory.open_1')
  OpenDBRequest _open_1(name, version) native "IDBFactory_open_1_Callback";

  @DocsEditable
  @DomName('IDBFactory.open_2')
  OpenDBRequest _open_2(name) native "IDBFactory_open_2_Callback";

  @DocsEditable
  @DomName('IDBFactory.webkitGetDatabaseNames')
  Request webkitGetDatabaseNames() native "IDBFactory_webkitGetDatabaseNames_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBIndex')
class Index extends NativeFieldWrapperClass1 {
  Index.internal();

  @DocsEditable
  @DomName('IDBIndex.keyPath')
  dynamic get keyPath native "IDBIndex_keyPath_Getter";

  @DocsEditable
  @DomName('IDBIndex.multiEntry')
  bool get multiEntry native "IDBIndex_multiEntry_Getter";

  @DocsEditable
  @DomName('IDBIndex.name')
  String get name native "IDBIndex_name_Getter";

  @DocsEditable
  @DomName('IDBIndex.objectStore')
  ObjectStore get objectStore native "IDBIndex_objectStore_Getter";

  @DocsEditable
  @DomName('IDBIndex.unique')
  bool get unique native "IDBIndex_unique_Getter";

  Request count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    if (?key_OR_range) {
      return _count_3(key_OR_range);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBIndex.count_1')
  Request _count_1() native "IDBIndex_count_1_Callback";

  @DocsEditable
  @DomName('IDBIndex.count_2')
  Request _count_2(key_OR_range) native "IDBIndex_count_2_Callback";

  @DocsEditable
  @DomName('IDBIndex.count_3')
  Request _count_3(key_OR_range) native "IDBIndex_count_3_Callback";

  Request get(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    if (?key) {
      return _get_2(key);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBIndex.get_1')
  Request _get_1(key) native "IDBIndex_get_1_Callback";

  @DocsEditable
  @DomName('IDBIndex.get_2')
  Request _get_2(key) native "IDBIndex_get_2_Callback";

  Request getKey(key) {
    if ((key is KeyRange || key == null)) {
      return _getKey_1(key);
    }
    if (?key) {
      return _getKey_2(key);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBIndex.getKey_1')
  Request _getKey_1(key) native "IDBIndex_getKey_1_Callback";

  @DocsEditable
  @DomName('IDBIndex.getKey_2')
  Request _getKey_2(key) native "IDBIndex_getKey_2_Callback";

  Request openCursor([key_OR_range, String direction]) {
    if (!?key_OR_range && !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range && !?direction) {
      return _openCursor_4(key_OR_range);
    }
    if (?key_OR_range && (direction is String || direction == null)) {
      return _openCursor_5(key_OR_range, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBIndex.openCursor_1')
  Request _openCursor_1() native "IDBIndex_openCursor_1_Callback";

  @DocsEditable
  @DomName('IDBIndex.openCursor_2')
  Request _openCursor_2(key_OR_range) native "IDBIndex_openCursor_2_Callback";

  @DocsEditable
  @DomName('IDBIndex.openCursor_3')
  Request _openCursor_3(key_OR_range, direction) native "IDBIndex_openCursor_3_Callback";

  @DocsEditable
  @DomName('IDBIndex.openCursor_4')
  Request _openCursor_4(key_OR_range) native "IDBIndex_openCursor_4_Callback";

  @DocsEditable
  @DomName('IDBIndex.openCursor_5')
  Request _openCursor_5(key_OR_range, direction) native "IDBIndex_openCursor_5_Callback";

  Request openKeyCursor([key_OR_range, String direction]) {
    if (!?key_OR_range && !?direction) {
      return _openKeyCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && !?direction) {
      return _openKeyCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openKeyCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range && !?direction) {
      return _openKeyCursor_4(key_OR_range);
    }
    if (?key_OR_range && (direction is String || direction == null)) {
      return _openKeyCursor_5(key_OR_range, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBIndex.openKeyCursor_1')
  Request _openKeyCursor_1() native "IDBIndex_openKeyCursor_1_Callback";

  @DocsEditable
  @DomName('IDBIndex.openKeyCursor_2')
  Request _openKeyCursor_2(key_OR_range) native "IDBIndex_openKeyCursor_2_Callback";

  @DocsEditable
  @DomName('IDBIndex.openKeyCursor_3')
  Request _openKeyCursor_3(key_OR_range, direction) native "IDBIndex_openKeyCursor_3_Callback";

  @DocsEditable
  @DomName('IDBIndex.openKeyCursor_4')
  Request _openKeyCursor_4(key_OR_range) native "IDBIndex_openKeyCursor_4_Callback";

  @DocsEditable
  @DomName('IDBIndex.openKeyCursor_5')
  Request _openKeyCursor_5(key_OR_range, direction) native "IDBIndex_openKeyCursor_5_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBKey')
class Key extends NativeFieldWrapperClass1 {
  Key.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('IDBKeyRange')
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

  @DocsEditable
  @DomName('IDBKeyRange.lower')
  dynamic get lower native "IDBKeyRange_lower_Getter";

  @DocsEditable
  @DomName('IDBKeyRange.lowerOpen')
  bool get lowerOpen native "IDBKeyRange_lowerOpen_Getter";

  @DocsEditable
  @DomName('IDBKeyRange.upper')
  dynamic get upper native "IDBKeyRange_upper_Getter";

  @DocsEditable
  @DomName('IDBKeyRange.upperOpen')
  bool get upperOpen native "IDBKeyRange_upperOpen_Getter";

  static KeyRange bound_(/*IDBKey*/ lower, /*IDBKey*/ upper, [bool lowerOpen, bool upperOpen]) {
    if (?upperOpen) {
      return _bound_1(lower, upper, lowerOpen, upperOpen);
    }
    if (?lowerOpen) {
      return _bound_2(lower, upper, lowerOpen);
    }
    return _bound_3(lower, upper);
  }

  @DocsEditable
  @DomName('IDBKeyRange.bound_1')
  static KeyRange _bound_1(lower, upper, lowerOpen, upperOpen) native "IDBKeyRange_bound_1_Callback";

  @DocsEditable
  @DomName('IDBKeyRange.bound_2')
  static KeyRange _bound_2(lower, upper, lowerOpen) native "IDBKeyRange_bound_2_Callback";

  @DocsEditable
  @DomName('IDBKeyRange.bound_3')
  static KeyRange _bound_3(lower, upper) native "IDBKeyRange_bound_3_Callback";

  static KeyRange lowerBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      return _lowerBound_1(bound, open);
    }
    return _lowerBound_2(bound);
  }

  @DocsEditable
  @DomName('IDBKeyRange.lowerBound_1')
  static KeyRange _lowerBound_1(bound, open) native "IDBKeyRange_lowerBound_1_Callback";

  @DocsEditable
  @DomName('IDBKeyRange.lowerBound_2')
  static KeyRange _lowerBound_2(bound) native "IDBKeyRange_lowerBound_2_Callback";

  @DocsEditable
  @DomName('IDBKeyRange.only_')
  static KeyRange only_(/*IDBKey*/ value) native "IDBKeyRange_only__Callback";

  static KeyRange upperBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      return _upperBound_1(bound, open);
    }
    return _upperBound_2(bound);
  }

  @DocsEditable
  @DomName('IDBKeyRange.upperBound_1')
  static KeyRange _upperBound_1(bound, open) native "IDBKeyRange_upperBound_1_Callback";

  @DocsEditable
  @DomName('IDBKeyRange.upperBound_2')
  static KeyRange _upperBound_2(bound) native "IDBKeyRange_upperBound_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBObjectStore')
class ObjectStore extends NativeFieldWrapperClass1 {
  ObjectStore.internal();

  @DocsEditable
  @DomName('IDBObjectStore.autoIncrement')
  bool get autoIncrement native "IDBObjectStore_autoIncrement_Getter";

  @DocsEditable
  @DomName('IDBObjectStore.indexNames')
  List<String> get indexNames native "IDBObjectStore_indexNames_Getter";

  @DocsEditable
  @DomName('IDBObjectStore.keyPath')
  dynamic get keyPath native "IDBObjectStore_keyPath_Getter";

  @DocsEditable
  @DomName('IDBObjectStore.name')
  String get name native "IDBObjectStore_name_Getter";

  @DocsEditable
  @DomName('IDBObjectStore.transaction')
  Transaction get transaction native "IDBObjectStore_transaction_Getter";

  Request add(Object value, [/*IDBKey*/ key]) {
    if (?key) {
      return _add_1(value, key);
    }
    return _add_2(value);
  }

  @DocsEditable
  @DomName('IDBObjectStore.add_1')
  Request _add_1(value, key) native "IDBObjectStore_add_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.add_2')
  Request _add_2(value) native "IDBObjectStore_add_2_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.clear')
  Request clear() native "IDBObjectStore_clear_Callback";

  Request count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    if (?key_OR_range) {
      return _count_3(key_OR_range);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBObjectStore.count_1')
  Request _count_1() native "IDBObjectStore_count_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.count_2')
  Request _count_2(key_OR_range) native "IDBObjectStore_count_2_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.count_3')
  Request _count_3(key_OR_range) native "IDBObjectStore_count_3_Callback";

  Index createIndex(String name, keyPath, [Map options]) {
    if ((name is String || name == null) && (keyPath is List<String> || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_1(name, keyPath, options);
    }
    if ((name is String || name == null) && (keyPath is String || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_2(name, keyPath, options);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBObjectStore.createIndex_1')
  Index _createIndex_1(name, keyPath, options) native "IDBObjectStore_createIndex_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.createIndex_2')
  Index _createIndex_2(name, keyPath, options) native "IDBObjectStore_createIndex_2_Callback";

  Request delete(key_OR_keyRange) {
    if ((key_OR_keyRange is KeyRange || key_OR_keyRange == null)) {
      return _delete_1(key_OR_keyRange);
    }
    if (?key_OR_keyRange) {
      return _delete_2(key_OR_keyRange);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBObjectStore.delete_1')
  Request _delete_1(key_OR_keyRange) native "IDBObjectStore_delete_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.delete_2')
  Request _delete_2(key_OR_keyRange) native "IDBObjectStore_delete_2_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.deleteIndex')
  void deleteIndex(String name) native "IDBObjectStore_deleteIndex_Callback";

  Request getObject(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    if (?key) {
      return _get_2(key);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBObjectStore.get_1')
  Request _get_1(key) native "IDBObjectStore_get_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.get_2')
  Request _get_2(key) native "IDBObjectStore_get_2_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.index')
  Index index(String name) native "IDBObjectStore_index_Callback";

  Request openCursor([key_OR_range, String direction]) {
    if (!?key_OR_range && !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range && !?direction) {
      return _openCursor_4(key_OR_range);
    }
    if (?key_OR_range && (direction is String || direction == null)) {
      return _openCursor_5(key_OR_range, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }

  @DocsEditable
  @DomName('IDBObjectStore.openCursor_1')
  Request _openCursor_1() native "IDBObjectStore_openCursor_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.openCursor_2')
  Request _openCursor_2(key_OR_range) native "IDBObjectStore_openCursor_2_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.openCursor_3')
  Request _openCursor_3(key_OR_range, direction) native "IDBObjectStore_openCursor_3_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.openCursor_4')
  Request _openCursor_4(key_OR_range) native "IDBObjectStore_openCursor_4_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.openCursor_5')
  Request _openCursor_5(key_OR_range, direction) native "IDBObjectStore_openCursor_5_Callback";

  Request put(Object value, [/*IDBKey*/ key]) {
    if (?key) {
      return _put_1(value, key);
    }
    return _put_2(value);
  }

  @DocsEditable
  @DomName('IDBObjectStore.put_1')
  Request _put_1(value, key) native "IDBObjectStore_put_1_Callback";

  @DocsEditable
  @DomName('IDBObjectStore.put_2')
  Request _put_2(value) native "IDBObjectStore_put_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBOpenDBRequest')
class OpenDBRequest extends Request implements EventTarget {
  OpenDBRequest.internal() : super.internal();

  @DocsEditable
  @DomName('IDBOpenDBRequest.blocked')
  static const EventStreamProvider<Event> blockedEvent = const EventStreamProvider<Event>('blocked');

  @DocsEditable
  @DomName('IDBOpenDBRequest.upgradeneeded')
  static const EventStreamProvider<VersionChangeEvent> upgradeNeededEvent = const EventStreamProvider<VersionChangeEvent>('upgradeneeded');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  OpenDBRequestEvents get on =>
    new OpenDBRequestEvents(this);

  @DocsEditable
  @DomName('IDBOpenDBRequest.blocked')
  Stream<Event> get onBlocked => blockedEvent.forTarget(this);

  @DocsEditable
  @DomName('IDBOpenDBRequest.upgradeneeded')
  Stream<VersionChangeEvent> get onUpgradeNeeded => upgradeNeededEvent.forTarget(this);

}

@DocsEditable
class OpenDBRequestEvents extends RequestEvents {
  @DocsEditable
  OpenDBRequestEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get blocked => this['blocked'];

  @DocsEditable
  EventListenerList get upgradeNeeded => this['upgradeneeded'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBRequest')
class Request extends EventTarget {
  Request.internal() : super.internal();

  @DocsEditable
  @DomName('IDBRequest.error')
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('IDBRequest.success')
  static const EventStreamProvider<Event> successEvent = const EventStreamProvider<Event>('success');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  RequestEvents get on =>
    new RequestEvents(this);

  @DocsEditable
  @DomName('IDBRequest.error')
  DomError get error native "IDBRequest_error_Getter";

  @DocsEditable
  @DomName('IDBRequest.readyState')
  String get readyState native "IDBRequest_readyState_Getter";

  @DocsEditable
  @DomName('IDBRequest.result')
  dynamic get result native "IDBRequest_result_Getter";

  @DocsEditable
  @DomName('IDBRequest.source')
  dynamic get source native "IDBRequest_source_Getter";

  @DocsEditable
  @DomName('IDBRequest.transaction')
  Transaction get transaction native "IDBRequest_transaction_Getter";

  @DocsEditable
  @DomName('IDBRequest.webkitErrorMessage')
  String get webkitErrorMessage native "IDBRequest_webkitErrorMessage_Getter";

  @DocsEditable
  @DomName('IDBRequest.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_addEventListener_Callback";

  @DocsEditable
  @DomName('IDBRequest.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native "IDBRequest_dispatchEvent_Callback";

  @DocsEditable
  @DomName('IDBRequest.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_removeEventListener_Callback";

  @DocsEditable
  @DomName('IDBRequest.error')
  Stream<Event> get onError => errorEvent.forTarget(this);

  @DocsEditable
  @DomName('IDBRequest.success')
  Stream<Event> get onSuccess => successEvent.forTarget(this);

}

@DocsEditable
class RequestEvents extends Events {
  @DocsEditable
  RequestEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get error => this['error'];

  @DocsEditable
  EventListenerList get success => this['success'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBTransaction')
class Transaction extends EventTarget {
  Transaction.internal() : super.internal();

  @DocsEditable
  @DomName('IDBTransaction.abort')
  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  @DocsEditable
  @DomName('IDBTransaction.complete')
  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  @DocsEditable
  @DomName('IDBTransaction.error')
  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  TransactionEvents get on =>
    new TransactionEvents(this);

  @DocsEditable
  @DomName('IDBTransaction.db')
  Database get db native "IDBTransaction_db_Getter";

  @DocsEditable
  @DomName('IDBTransaction.error')
  DomError get error native "IDBTransaction_error_Getter";

  @DocsEditable
  @DomName('IDBTransaction.mode')
  String get mode native "IDBTransaction_mode_Getter";

  @DocsEditable
  @DomName('IDBTransaction.webkitErrorMessage')
  String get webkitErrorMessage native "IDBTransaction_webkitErrorMessage_Getter";

  @DocsEditable
  @DomName('IDBTransaction.abort')
  void abort() native "IDBTransaction_abort_Callback";

  @DocsEditable
  @DomName('IDBTransaction.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_addEventListener_Callback";

  @DocsEditable
  @DomName('IDBTransaction.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native "IDBTransaction_dispatchEvent_Callback";

  @DocsEditable
  @DomName('IDBTransaction.objectStore')
  ObjectStore objectStore(String name) native "IDBTransaction_objectStore_Callback";

  @DocsEditable
  @DomName('IDBTransaction.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_removeEventListener_Callback";

  @DocsEditable
  @DomName('IDBTransaction.abort')
  Stream<Event> get onAbort => abortEvent.forTarget(this);

  @DocsEditable
  @DomName('IDBTransaction.complete')
  Stream<Event> get onComplete => completeEvent.forTarget(this);

  @DocsEditable
  @DomName('IDBTransaction.error')
  Stream<Event> get onError => errorEvent.forTarget(this);

}

@DocsEditable
class TransactionEvents extends Events {
  @DocsEditable
  TransactionEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get abort => this['abort'];

  @DocsEditable
  EventListenerList get complete => this['complete'];

  @DocsEditable
  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBVersionChangeEvent')
class UpgradeNeededEvent extends Event {
  UpgradeNeededEvent.internal() : super.internal();

  @DocsEditable
  @DomName('IDBUpgradeNeededEvent.newVersion')
  int get newVersion native "IDBUpgradeNeededEvent_newVersion_Getter";

  @DocsEditable
  @DomName('IDBUpgradeNeededEvent.oldVersion')
  int get oldVersion native "IDBUpgradeNeededEvent_oldVersion_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBVersionChangeEvent')
class VersionChangeEvent extends Event {
  VersionChangeEvent.internal() : super.internal();

  @DocsEditable
  @DomName('IDBVersionChangeEvent.version')
  String get version native "IDBVersionChangeEvent_version_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBVersionChangeRequest')
class VersionChangeRequest extends Request implements EventTarget {
  VersionChangeRequest.internal() : super.internal();

  @DocsEditable
  @DomName('IDBVersionChangeRequest.blocked')
  static const EventStreamProvider<Event> blockedEvent = const EventStreamProvider<Event>('blocked');

  @DocsEditable
  @DomName('EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent')
  VersionChangeRequestEvents get on =>
    new VersionChangeRequestEvents(this);

  @DocsEditable
  @DomName('IDBVersionChangeRequest.blocked')
  Stream<Event> get onBlocked => blockedEvent.forTarget(this);

}

@DocsEditable
class VersionChangeRequestEvents extends RequestEvents {
  @DocsEditable
  VersionChangeRequestEvents(EventTarget _ptr) : super(_ptr);

  @DocsEditable
  EventListenerList get blocked => this['blocked'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


@DocsEditable
@DomName('IDBAny')
class _Any extends NativeFieldWrapperClass1 {
  _Any.internal();

}
