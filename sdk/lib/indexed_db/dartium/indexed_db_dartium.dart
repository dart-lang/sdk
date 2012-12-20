library indexed_db;

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


/// @domName IDBCursor
class Cursor extends NativeFieldWrapperClass1 {
  Cursor.internal();


  /** @domName IDBCursor.direction */
  String get direction native "IDBCursor_direction_Getter";


  /** @domName IDBCursor.key */
  Object get key native "IDBCursor_key_Getter";


  /** @domName IDBCursor.primaryKey */
  Object get primaryKey native "IDBCursor_primaryKey_Getter";


  /** @domName IDBCursor.source */
  dynamic get source native "IDBCursor_source_Getter";


  /** @domName IDBCursor.advance */
  void advance(int count) native "IDBCursor_advance_Callback";

  void continueFunction([/*IDBKey*/ key]) {
    if (?key) {
      _continue_1(key);
      return;
    }
    _continue_2();
  }


  /** @domName IDBCursor.continue_1 */
  void _continue_1(key) native "IDBCursor_continue_1_Callback";


  /** @domName IDBCursor.continue_2 */
  void _continue_2() native "IDBCursor_continue_2_Callback";


  /** @domName IDBCursor.delete */
  Request delete() native "IDBCursor_delete_Callback";


  /** @domName IDBCursor.update */
  Request update(Object value) native "IDBCursor_update_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBCursorWithValue
class CursorWithValue extends Cursor {
  CursorWithValue.internal(): super.internal();


  /** @domName IDBCursorWithValue.value */
  Object get value native "IDBCursorWithValue_value_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBDatabase
class Database extends EventTarget {
  Database.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  DatabaseEvents get on =>
    new DatabaseEvents(this);


  /** @domName IDBDatabase.name */
  String get name native "IDBDatabase_name_Getter";


  /** @domName IDBDatabase.objectStoreNames */
  List<String> get objectStoreNames native "IDBDatabase_objectStoreNames_Getter";


  /** @domName IDBDatabase.version */
  dynamic get version native "IDBDatabase_version_Getter";


  /** @domName IDBDatabase.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_addEventListener_Callback";


  /** @domName IDBDatabase.close */
  void close() native "IDBDatabase_close_Callback";


  /** @domName IDBDatabase.createObjectStore */
  ObjectStore createObjectStore(String name, [Map options]) native "IDBDatabase_createObjectStore_Callback";


  /** @domName IDBDatabase.deleteObjectStore */
  void deleteObjectStore(String name) native "IDBDatabase_deleteObjectStore_Callback";


  /** @domName IDBDatabase.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "IDBDatabase_dispatchEvent_Callback";


  /** @domName IDBDatabase.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBDatabase_removeEventListener_Callback";

  Transaction transaction(storeName_OR_storeNames, /*DOMString*/ mode) {
    if ((storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_1(storeName_OR_storeNames, mode);
    }
    if ((storeName_OR_storeNames is List<String> || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_2(storeName_OR_storeNames, mode);
    }
    if ((storeName_OR_storeNames is String || storeName_OR_storeNames == null) && (mode is String || mode == null)) {
      return _transaction_3(storeName_OR_storeNames, mode);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBDatabase.transaction_1 */
  Transaction _transaction_1(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_1_Callback";


  /** @domName IDBDatabase.transaction_2 */
  Transaction _transaction_2(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_2_Callback";


  /** @domName IDBDatabase.transaction_3 */
  Transaction _transaction_3(storeName_OR_storeNames, mode) native "IDBDatabase_transaction_3_Callback";

}

/// @docsEditable true
class DatabaseEvents extends Events {
  /// @docsEditable true
  DatabaseEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get abort => this['abort'];

  /// @docsEditable true
  EventListenerList get error => this['error'];

  /// @docsEditable true
  EventListenerList get versionChange => this['versionchange'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBDatabaseException
class DatabaseException extends NativeFieldWrapperClass1 {
  DatabaseException.internal();

  static const int ABORT_ERR = 20;

  static const int CONSTRAINT_ERR = 4;

  static const int DATA_ERR = 5;

  static const int NON_TRANSIENT_ERR = 2;

  static const int NOT_ALLOWED_ERR = 6;

  static const int NOT_FOUND_ERR = 8;

  static const int NO_ERR = 0;

  static const int QUOTA_ERR = 22;

  static const int READ_ONLY_ERR = 9;

  static const int TIMEOUT_ERR = 23;

  static const int TRANSACTION_INACTIVE_ERR = 7;

  static const int UNKNOWN_ERR = 1;

  static const int VER_ERR = 12;


  /** @domName IDBDatabaseException.code */
  int get code native "IDBDatabaseException_code_Getter";


  /** @domName IDBDatabaseException.message */
  String get message native "IDBDatabaseException_message_Getter";


  /** @domName IDBDatabaseException.name */
  String get name native "IDBDatabaseException_name_Getter";


  /** @domName IDBDatabaseException.toString */
  String toString() native "IDBDatabaseException_toString_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBFactory
class IdbFactory extends NativeFieldWrapperClass1 {
  IdbFactory.internal();


  /** @domName IDBFactory.cmp */
  int cmp(/*IDBKey*/ first, /*IDBKey*/ second) native "IDBFactory_cmp_Callback";


  /** @domName IDBFactory.deleteDatabase */
  VersionChangeRequest deleteDatabase(String name) native "IDBFactory_deleteDatabase_Callback";

  OpenDBRequest open(/*DOMString*/ name, [/*long long*/ version]) {
    if (?version) {
      return _open_1(name, version);
    }
    return _open_2(name);
  }


  /** @domName IDBFactory.open_1 */
  OpenDBRequest _open_1(name, version) native "IDBFactory_open_1_Callback";


  /** @domName IDBFactory.open_2 */
  OpenDBRequest _open_2(name) native "IDBFactory_open_2_Callback";


  /** @domName IDBFactory.webkitGetDatabaseNames */
  Request webkitGetDatabaseNames() native "IDBFactory_webkitGetDatabaseNames_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBIndex
class Index extends NativeFieldWrapperClass1 {
  Index.internal();


  /** @domName IDBIndex.keyPath */
  dynamic get keyPath native "IDBIndex_keyPath_Getter";


  /** @domName IDBIndex.multiEntry */
  bool get multiEntry native "IDBIndex_multiEntry_Getter";


  /** @domName IDBIndex.name */
  String get name native "IDBIndex_name_Getter";


  /** @domName IDBIndex.objectStore */
  ObjectStore get objectStore native "IDBIndex_objectStore_Getter";


  /** @domName IDBIndex.unique */
  bool get unique native "IDBIndex_unique_Getter";

  Request count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    return _count_3(key_OR_range);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.count_1 */
  Request _count_1() native "IDBIndex_count_1_Callback";


  /** @domName IDBIndex.count_2 */
  Request _count_2(key_OR_range) native "IDBIndex_count_2_Callback";


  /** @domName IDBIndex.count_3 */
  Request _count_3(key_OR_range) native "IDBIndex_count_3_Callback";

  Request get(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    return _get_2(key);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.get_1 */
  Request _get_1(key) native "IDBIndex_get_1_Callback";


  /** @domName IDBIndex.get_2 */
  Request _get_2(key) native "IDBIndex_get_2_Callback";

  Request getKey(key) {
    if ((key is KeyRange || key == null)) {
      return _getKey_1(key);
    }
    return _getKey_2(key);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.getKey_1 */
  Request _getKey_1(key) native "IDBIndex_getKey_1_Callback";


  /** @domName IDBIndex.getKey_2 */
  Request _getKey_2(key) native "IDBIndex_getKey_2_Callback";

  Request openCursor([key_OR_range, /*DOMString*/ direction]) {
    if (!?key_OR_range && !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (!?direction) {
      return _openCursor_4(key_OR_range);
    }
    if ((direction is String || direction == null)) {
      return _openCursor_5(key_OR_range, direction);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.openCursor_1 */
  Request _openCursor_1() native "IDBIndex_openCursor_1_Callback";


  /** @domName IDBIndex.openCursor_2 */
  Request _openCursor_2(key_OR_range) native "IDBIndex_openCursor_2_Callback";


  /** @domName IDBIndex.openCursor_3 */
  Request _openCursor_3(key_OR_range, direction) native "IDBIndex_openCursor_3_Callback";


  /** @domName IDBIndex.openCursor_4 */
  Request _openCursor_4(key_OR_range) native "IDBIndex_openCursor_4_Callback";


  /** @domName IDBIndex.openCursor_5 */
  Request _openCursor_5(key_OR_range, direction) native "IDBIndex_openCursor_5_Callback";

  Request openKeyCursor([key_OR_range, /*DOMString*/ direction]) {
    if (!?key_OR_range && !?direction) {
      return _openKeyCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && !?direction) {
      return _openKeyCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openKeyCursor_3(key_OR_range, direction);
    }
    if (!?direction) {
      return _openKeyCursor_4(key_OR_range);
    }
    if ((direction is String || direction == null)) {
      return _openKeyCursor_5(key_OR_range, direction);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBIndex.openKeyCursor_1 */
  Request _openKeyCursor_1() native "IDBIndex_openKeyCursor_1_Callback";


  /** @domName IDBIndex.openKeyCursor_2 */
  Request _openKeyCursor_2(key_OR_range) native "IDBIndex_openKeyCursor_2_Callback";


  /** @domName IDBIndex.openKeyCursor_3 */
  Request _openKeyCursor_3(key_OR_range, direction) native "IDBIndex_openKeyCursor_3_Callback";


  /** @domName IDBIndex.openKeyCursor_4 */
  Request _openKeyCursor_4(key_OR_range) native "IDBIndex_openKeyCursor_4_Callback";


  /** @domName IDBIndex.openKeyCursor_5 */
  Request _openKeyCursor_5(key_OR_range, direction) native "IDBIndex_openKeyCursor_5_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBKey
class Key extends NativeFieldWrapperClass1 {
  Key.internal();

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBKeyRange
class KeyRange extends NativeFieldWrapperClass1 {
  /**
   * @domName IDBKeyRange.only
   */
  factory KeyRange.only(/*Key*/ value) =>
      _KeyRangeFactoryProvider.createKeyRange_only(value);

  /**
   * @domName IDBKeyRange.lowerBound
   */
  factory KeyRange.lowerBound(/*Key*/ bound, [bool open = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_lowerBound(bound, open);

  /**
   * @domName IDBKeyRange.upperBound
   */
  factory KeyRange.upperBound(/*Key*/ bound, [bool open = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_upperBound(bound, open);

  /**
   * @domName KeyRange.bound
   */
  factory KeyRange.bound(/*Key*/ lower, /*Key*/ upper,
                            [bool lowerOpen = false, bool upperOpen = false]) =>
      _KeyRangeFactoryProvider.createKeyRange_bound(
          lower, upper, lowerOpen, upperOpen);

  KeyRange.internal();


  /** @domName IDBKeyRange.lower */
  dynamic get lower native "IDBKeyRange_lower_Getter";


  /** @domName IDBKeyRange.lowerOpen */
  bool get lowerOpen native "IDBKeyRange_lowerOpen_Getter";


  /** @domName IDBKeyRange.upper */
  dynamic get upper native "IDBKeyRange_upper_Getter";


  /** @domName IDBKeyRange.upperOpen */
  bool get upperOpen native "IDBKeyRange_upperOpen_Getter";

  static KeyRange bound_(/*IDBKey*/ lower, /*IDBKey*/ upper, [/*boolean*/ lowerOpen, /*boolean*/ upperOpen]) {
    if (?upperOpen) {
      return _bound_1(lower, upper, lowerOpen, upperOpen);
    }
    if (?lowerOpen) {
      return _bound_2(lower, upper, lowerOpen);
    }
    return _bound_3(lower, upper);
  }


  /** @domName IDBKeyRange.bound_1 */
  static KeyRange _bound_1(lower, upper, lowerOpen, upperOpen) native "IDBKeyRange_bound_1_Callback";


  /** @domName IDBKeyRange.bound_2 */
  static KeyRange _bound_2(lower, upper, lowerOpen) native "IDBKeyRange_bound_2_Callback";


  /** @domName IDBKeyRange.bound_3 */
  static KeyRange _bound_3(lower, upper) native "IDBKeyRange_bound_3_Callback";

  static KeyRange lowerBound_(/*IDBKey*/ bound, [/*boolean*/ open]) {
    if (?open) {
      return _lowerBound_1(bound, open);
    }
    return _lowerBound_2(bound);
  }


  /** @domName IDBKeyRange.lowerBound_1 */
  static KeyRange _lowerBound_1(bound, open) native "IDBKeyRange_lowerBound_1_Callback";


  /** @domName IDBKeyRange.lowerBound_2 */
  static KeyRange _lowerBound_2(bound) native "IDBKeyRange_lowerBound_2_Callback";


  /** @domName IDBKeyRange.only_ */
  static KeyRange only_(/*IDBKey*/ value) native "IDBKeyRange_only__Callback";

  static KeyRange upperBound_(/*IDBKey*/ bound, [/*boolean*/ open]) {
    if (?open) {
      return _upperBound_1(bound, open);
    }
    return _upperBound_2(bound);
  }


  /** @domName IDBKeyRange.upperBound_1 */
  static KeyRange _upperBound_1(bound, open) native "IDBKeyRange_upperBound_1_Callback";


  /** @domName IDBKeyRange.upperBound_2 */
  static KeyRange _upperBound_2(bound) native "IDBKeyRange_upperBound_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBObjectStore
class ObjectStore extends NativeFieldWrapperClass1 {
  ObjectStore.internal();


  /** @domName IDBObjectStore.autoIncrement */
  bool get autoIncrement native "IDBObjectStore_autoIncrement_Getter";


  /** @domName IDBObjectStore.indexNames */
  List<String> get indexNames native "IDBObjectStore_indexNames_Getter";


  /** @domName IDBObjectStore.keyPath */
  dynamic get keyPath native "IDBObjectStore_keyPath_Getter";


  /** @domName IDBObjectStore.name */
  String get name native "IDBObjectStore_name_Getter";


  /** @domName IDBObjectStore.transaction */
  Transaction get transaction native "IDBObjectStore_transaction_Getter";

  Request add(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      return _add_1(value, key);
    }
    return _add_2(value);
  }


  /** @domName IDBObjectStore.add_1 */
  Request _add_1(value, key) native "IDBObjectStore_add_1_Callback";


  /** @domName IDBObjectStore.add_2 */
  Request _add_2(value) native "IDBObjectStore_add_2_Callback";


  /** @domName IDBObjectStore.clear */
  Request clear() native "IDBObjectStore_clear_Callback";

  Request count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    return _count_3(key_OR_range);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.count_1 */
  Request _count_1() native "IDBObjectStore_count_1_Callback";


  /** @domName IDBObjectStore.count_2 */
  Request _count_2(key_OR_range) native "IDBObjectStore_count_2_Callback";


  /** @domName IDBObjectStore.count_3 */
  Request _count_3(key_OR_range) native "IDBObjectStore_count_3_Callback";

  Index createIndex(/*DOMString*/ name, keyPath, [/*Dictionary*/ options]) {
    if ((name is String || name == null) && (keyPath is List<String> || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_1(name, keyPath, options);
    }
    if ((name is String || name == null) && (keyPath is String || keyPath == null) && (options is Map || options == null)) {
      return _createIndex_2(name, keyPath, options);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.createIndex_1 */
  Index _createIndex_1(name, keyPath, options) native "IDBObjectStore_createIndex_1_Callback";


  /** @domName IDBObjectStore.createIndex_2 */
  Index _createIndex_2(name, keyPath, options) native "IDBObjectStore_createIndex_2_Callback";

  Request delete(key_OR_keyRange) {
    if ((key_OR_keyRange is KeyRange || key_OR_keyRange == null)) {
      return _delete_1(key_OR_keyRange);
    }
    return _delete_2(key_OR_keyRange);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.delete_1 */
  Request _delete_1(key_OR_keyRange) native "IDBObjectStore_delete_1_Callback";


  /** @domName IDBObjectStore.delete_2 */
  Request _delete_2(key_OR_keyRange) native "IDBObjectStore_delete_2_Callback";


  /** @domName IDBObjectStore.deleteIndex */
  void deleteIndex(String name) native "IDBObjectStore_deleteIndex_Callback";

  Request getObject(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    return _get_2(key);
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.get_1 */
  Request _get_1(key) native "IDBObjectStore_get_1_Callback";


  /** @domName IDBObjectStore.get_2 */
  Request _get_2(key) native "IDBObjectStore_get_2_Callback";


  /** @domName IDBObjectStore.index */
  Index index(String name) native "IDBObjectStore_index_Callback";

  Request openCursor([key_OR_range, /*DOMString*/ direction]) {
    if (!?key_OR_range && !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) && (direction is String || direction == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (!?direction) {
      return _openCursor_4(key_OR_range);
    }
    if ((direction is String || direction == null)) {
      return _openCursor_5(key_OR_range, direction);
    }
    throw "Incorrect number or type of arguments";
  }


  /** @domName IDBObjectStore.openCursor_1 */
  Request _openCursor_1() native "IDBObjectStore_openCursor_1_Callback";


  /** @domName IDBObjectStore.openCursor_2 */
  Request _openCursor_2(key_OR_range) native "IDBObjectStore_openCursor_2_Callback";


  /** @domName IDBObjectStore.openCursor_3 */
  Request _openCursor_3(key_OR_range, direction) native "IDBObjectStore_openCursor_3_Callback";


  /** @domName IDBObjectStore.openCursor_4 */
  Request _openCursor_4(key_OR_range) native "IDBObjectStore_openCursor_4_Callback";


  /** @domName IDBObjectStore.openCursor_5 */
  Request _openCursor_5(key_OR_range, direction) native "IDBObjectStore_openCursor_5_Callback";

  Request put(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      return _put_1(value, key);
    }
    return _put_2(value);
  }


  /** @domName IDBObjectStore.put_1 */
  Request _put_1(value, key) native "IDBObjectStore_put_1_Callback";


  /** @domName IDBObjectStore.put_2 */
  Request _put_2(value) native "IDBObjectStore_put_2_Callback";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBOpenDBRequest
class OpenDBRequest extends Request implements EventTarget {
  OpenDBRequest.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  OpenDBRequestEvents get on =>
    new OpenDBRequestEvents(this);

}

/// @docsEditable true
class OpenDBRequestEvents extends RequestEvents {
  /// @docsEditable true
  OpenDBRequestEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get blocked => this['blocked'];

  /// @docsEditable true
  EventListenerList get upgradeNeeded => this['upgradeneeded'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBRequest
class Request extends EventTarget {
  Request.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  RequestEvents get on =>
    new RequestEvents(this);


  /** @domName IDBRequest.error */
  DomError get error native "IDBRequest_error_Getter";


  /** @domName IDBRequest.readyState */
  String get readyState native "IDBRequest_readyState_Getter";


  /** @domName IDBRequest.result */
  dynamic get result native "IDBRequest_result_Getter";


  /** @domName IDBRequest.source */
  dynamic get source native "IDBRequest_source_Getter";


  /** @domName IDBRequest.transaction */
  Transaction get transaction native "IDBRequest_transaction_Getter";


  /** @domName IDBRequest.webkitErrorMessage */
  String get webkitErrorMessage native "IDBRequest_webkitErrorMessage_Getter";


  /** @domName IDBRequest.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_addEventListener_Callback";


  /** @domName IDBRequest.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "IDBRequest_dispatchEvent_Callback";


  /** @domName IDBRequest.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBRequest_removeEventListener_Callback";

}

/// @docsEditable true
class RequestEvents extends Events {
  /// @docsEditable true
  RequestEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get error => this['error'];

  /// @docsEditable true
  EventListenerList get success => this['success'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBTransaction
class Transaction extends EventTarget {
  Transaction.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  TransactionEvents get on =>
    new TransactionEvents(this);


  /** @domName IDBTransaction.db */
  Database get db native "IDBTransaction_db_Getter";


  /** @domName IDBTransaction.error */
  DomError get error native "IDBTransaction_error_Getter";


  /** @domName IDBTransaction.mode */
  String get mode native "IDBTransaction_mode_Getter";


  /** @domName IDBTransaction.abort */
  void abort() native "IDBTransaction_abort_Callback";


  /** @domName IDBTransaction.addEventListener */
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_addEventListener_Callback";


  /** @domName IDBTransaction.dispatchEvent */
  bool $dom_dispatchEvent(Event evt) native "IDBTransaction_dispatchEvent_Callback";


  /** @domName IDBTransaction.objectStore */
  ObjectStore objectStore(String name) native "IDBTransaction_objectStore_Callback";


  /** @domName IDBTransaction.removeEventListener */
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native "IDBTransaction_removeEventListener_Callback";

}

/// @docsEditable true
class TransactionEvents extends Events {
  /// @docsEditable true
  TransactionEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get abort => this['abort'];

  /// @docsEditable true
  EventListenerList get complete => this['complete'];

  /// @docsEditable true
  EventListenerList get error => this['error'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBVersionChangeEvent
class UpgradeNeededEvent extends Event {
  UpgradeNeededEvent.internal(): super.internal();


  /** @domName IDBUpgradeNeededEvent.newVersion */
  int get newVersion native "IDBUpgradeNeededEvent_newVersion_Getter";


  /** @domName IDBUpgradeNeededEvent.oldVersion */
  int get oldVersion native "IDBUpgradeNeededEvent_oldVersion_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBVersionChangeEvent
class VersionChangeEvent extends Event {
  VersionChangeEvent.internal(): super.internal();


  /** @domName IDBVersionChangeEvent.version */
  String get version native "IDBVersionChangeEvent_version_Getter";

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBVersionChangeRequest
class VersionChangeRequest extends Request implements EventTarget {
  VersionChangeRequest.internal(): super.internal();

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  VersionChangeRequestEvents get on =>
    new VersionChangeRequestEvents(this);

}

/// @docsEditable true
class VersionChangeRequestEvents extends RequestEvents {
  /// @docsEditable true
  VersionChangeRequestEvents(EventTarget _ptr) : super(_ptr);

  /// @docsEditable true
  EventListenerList get blocked => this['blocked'];
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.


/// @domName IDBAny
class _Any extends NativeFieldWrapperClass1 {
  _Any.internal();

}
