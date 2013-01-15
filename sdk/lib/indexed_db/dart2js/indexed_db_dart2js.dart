library indexed_db;

import 'dart:async';
import 'dart:html';
import 'dart:html_common';
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated dart:svg library.





class _KeyRangeFactoryProvider {

  static KeyRange createKeyRange_only(/*Key*/ value) =>
      _only(_class(), _translateKey(value));

  static KeyRange createKeyRange_lowerBound(
      /*Key*/ bound, [bool open = false]) =>
      _lowerBound(_class(), _translateKey(bound), open);

  static KeyRange createKeyRange_upperBound(
      /*Key*/ bound, [bool open = false]) =>
      _upperBound(_class(), _translateKey(bound), open);

  static KeyRange createKeyRange_bound(/*Key*/ lower, /*Key*/ upper,
      [bool lowerOpen = false, bool upperOpen = false]) =>
      _bound(_class(), _translateKey(lower), _translateKey(upper),
             lowerOpen, upperOpen);

  static var _cachedClass;

  static _class() {
    if (_cachedClass != null) return _cachedClass;
    return _cachedClass = _uncachedClass();
  }

  static _uncachedClass() =>
    JS('var',
       '''window.webkitIDBKeyRange || window.mozIDBKeyRange ||
          window.msIDBKeyRange || window.IDBKeyRange''');

  static _translateKey(idbkey) => idbkey;  // TODO: fixme.

  static KeyRange _only(cls, value) =>
       JS('KeyRange', '#.only(#)', cls, value);

  static KeyRange _lowerBound(cls, bound, open) =>
       JS('KeyRange', '#.lowerBound(#, #)', cls, bound, open);

  static KeyRange _upperBound(cls, bound, open) =>
       JS('KeyRange', '#.upperBound(#, #)', cls, bound, open);

  static KeyRange _bound(cls, lower, upper, lowerOpen, upperOpen) =>
       JS('KeyRange', '#.bound(#, #, #, #)',
          cls, lower, upper, lowerOpen, upperOpen);
}

// Conversions for IDBKey.
//
// Per http://www.w3.org/TR/IndexedDB/#key-construct
//
// "A value is said to be a valid key if it is one of the following types: Array
// JavaScript objects [ECMA-262], DOMString [WEBIDL], Date [ECMA-262] or float
// [WEBIDL]. However Arrays are only valid keys if every item in the array is
// defined and is a valid key (i.e. sparse arrays can not be valid keys) and if
// the Array doesn't directly or indirectly contain itself. Any non-numeric
// properties are ignored, and thus does not affect whether the Array is a valid
// key. Additionally, if the value is of type float, it is only a valid key if
// it is not NaN, and if the value is of type Date it is only a valid key if its
// [[PrimitiveValue]] internal property, as defined by [ECMA-262], is not NaN."

// What is required is to ensure that an Lists in the key are actually
// JavaScript arrays, and any Dates are JavaScript Dates.


/**
 * Converts a native IDBKey into a Dart object.
 *
 * May return the original input.  May mutate the original input (but will be
 * idempotent if mutation occurs).  It is assumed that this conversion happens
 * on native IDBKeys on all paths that return IDBKeys from native DOM calls.
 *
 * If necessary, JavaScript Dates are converted into Dart Dates.
 */
_convertNativeToDart_IDBKey(nativeKey) {
  containsDate(object) {
    if (isJavaScriptDate(object)) return true;
    if (object is List) {
      for (int i = 0; i < object.length; i++) {
        if (containsDate(object[i])) return true;
      }
    }
    return false;  // number, string.
  }
  if (containsDate(nativeKey)) {
    throw new UnimplementedError('Key containing Date');
  }
  // TODO: Cache conversion somewhere?
  return nativeKey;
}

/**
 * Converts a Dart object into a valid IDBKey.
 *
 * May return the original input.  Does not mutate input.
 *
 * If necessary, [dartKey] may be copied to ensure all lists are converted into
 * JavaScript Arrays and Dart Dates into JavaScript Dates.
 */
_convertDartToNative_IDBKey(dartKey) {
  // TODO: Implement.
  return dartKey;
}



/// May modify original.  If so, action is idempotent.
_convertNativeToDart_IDBAny(object) {
  return convertNativeToDart_AcceptStructuredClone(object, mustCopy: false);
}


const String _idbKey = '=List|=Object|num|String';  // TODO(sra): Add Date.
const _annotation_Creates_IDBKey = const Creates(_idbKey);
const _annotation_Returns_IDBKey = const Returns(_idbKey);
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBCursor; @docsEditable true
class Cursor native "*IDBCursor" {

  /// @domName IDBCursor.direction; @docsEditable true
  final String direction;

  /// @domName IDBCursor.key; @docsEditable true
  @_annotation_Creates_IDBKey @_annotation_Returns_IDBKey
  final Object key;

  /// @domName IDBCursor.primaryKey; @docsEditable true
  final Object primaryKey;

  /// @domName IDBCursor.source; @docsEditable true
  final dynamic source;

  /// @domName IDBCursor.advance; @docsEditable true
  void advance(int count) native;

  /// @domName IDBCursor.continueFunction; @docsEditable true
  void continueFunction([/*IDBKey*/ key]) {
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      _continueFunction_1(key_1);
      return;
    }
    _continueFunction_2();
    return;
  }
  @JSName('continue')
  void _continueFunction_1(key) native;
  @JSName('continue')
  void _continueFunction_2() native;

  /// @domName IDBCursor.delete; @docsEditable true
  Request delete() native;

  /// @domName IDBCursor.update; @docsEditable true
  Request update(/*any*/ value) {
    var value_1 = convertDartToNative_SerializedScriptValue(value);
    return _update_1(value_1);
  }
  @JSName('update')
  Request _update_1(value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBCursorWithValue; @docsEditable true
class CursorWithValue extends Cursor native "*IDBCursorWithValue" {

  /// @domName IDBCursorWithValue.value; @docsEditable true
  @annotation_Creates_SerializedScriptValue @annotation_Returns_SerializedScriptValue
  final Object value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBDatabase
class Database extends EventTarget native "*IDBDatabase" {

  Transaction transaction(storeName_OR_storeNames, String mode) {
    if (mode != 'readonly' && mode != 'readwrite') {
      throw new ArgumentError(mode);
    }

    // TODO(sra): Ensure storeName_OR_storeNames is a string or List<String>,
    // and copy to JavaScript array if necessary.

    // Try and create a transaction with a string mode.  Browsers that expect a
    // numeric mode tend to convert the string into a number.  This fails
    // silently, resulting in zero ('readonly').
    return _transaction(storeName_OR_storeNames, mode);
  }

  @JSName('transaction')
  Transaction _transaction(stores, mode) native;


  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<UpgradeNeededEvent> versionChangeEvent = const EventStreamProvider<UpgradeNeededEvent>('versionchange');

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  DatabaseEvents get on =>
    new DatabaseEvents(this);

  /// @domName IDBDatabase.name; @docsEditable true
  final String name;

  /// @domName IDBDatabase.objectStoreNames; @docsEditable true
  @Returns('DomStringList') @Creates('DomStringList')
  final List<String> objectStoreNames;

  /// @domName IDBDatabase.version; @docsEditable true
  final dynamic version;

  /// @domName IDBDatabase.addEventListener; @docsEditable true
  @JSName('addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  /// @domName IDBDatabase.close; @docsEditable true
  void close() native;

  /// @domName IDBDatabase.createObjectStore; @docsEditable true
  ObjectStore createObjectStore(String name, [Map options]) {
    if (?options) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createObjectStore_1(name, options_1);
    }
    return _createObjectStore_2(name);
  }
  @JSName('createObjectStore')
  ObjectStore _createObjectStore_1(name, options) native;
  @JSName('createObjectStore')
  ObjectStore _createObjectStore_2(name) native;

  /// @domName IDBDatabase.deleteObjectStore; @docsEditable true
  void deleteObjectStore(String name) native;

  /// @domName IDBDatabase.dispatchEvent; @docsEditable true
  @JSName('dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  /// @domName IDBDatabase.removeEventListener; @docsEditable true
  @JSName('removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<UpgradeNeededEvent> get onVersionChange => versionChangeEvent.forTarget(this);
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


/// @domName IDBFactory
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
class IdbFactory native "*IDBFactory" {
  /**
   * Checks to see if Indexed DB is supported on the current platform.
   */
  static bool get supported {
    return JS('bool',
        '!!(window.indexedDB || '
        'window.webkitIndexedDB || '
        'window.mozIndexedDB)');
  }


  /// @domName IDBFactory.cmp; @docsEditable true
  int cmp(/*IDBKey*/ first, /*IDBKey*/ second) {
    var first_1 = _convertDartToNative_IDBKey(first);
    var second_2 = _convertDartToNative_IDBKey(second);
    return _cmp_1(first_1, second_2);
  }
  @JSName('cmp')
  int _cmp_1(first, second) native;

  /// @domName IDBFactory.deleteDatabase; @docsEditable true
  VersionChangeRequest deleteDatabase(String name) native;

  /// @domName IDBFactory.open; @docsEditable true
  @Returns('Request') @Creates('Request') @Creates('Database')
  OpenDBRequest open(String name, [int version]) native;

  /// @domName IDBFactory.webkitGetDatabaseNames; @docsEditable true
  Request webkitGetDatabaseNames() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBIndex; @docsEditable true
class Index native "*IDBIndex" {

  /// @domName IDBIndex.keyPath; @docsEditable true
  final dynamic keyPath;

  /// @domName IDBIndex.multiEntry; @docsEditable true
  final bool multiEntry;

  /// @domName IDBIndex.name; @docsEditable true
  final String name;

  /// @domName IDBIndex.objectStore; @docsEditable true
  final ObjectStore objectStore;

  /// @domName IDBIndex.unique; @docsEditable true
  final bool unique;

  /// @domName IDBIndex.count; @docsEditable true
  Request count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    if (?key_OR_range) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _count_3(key_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('count')
  Request _count_1() native;
  @JSName('count')
  Request _count_2(KeyRange range) native;
  @JSName('count')
  Request _count_3(key) native;

  /// @domName IDBIndex.get; @docsEditable true
  Request get(key) {
    if ((key is KeyRange || key == null)) {
      return _get_1(key);
    }
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      return _get_2(key_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('get')
  @Returns('Request') @Creates('Request') @annotation_Creates_SerializedScriptValue
  Request _get_1(KeyRange key) native;
  @JSName('get')
  @Returns('Request') @Creates('Request') @annotation_Creates_SerializedScriptValue
  Request _get_2(key) native;

  /// @domName IDBIndex.getKey; @docsEditable true
  Request getKey(key) {
    if ((key is KeyRange || key == null)) {
      return _getKey_1(key);
    }
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      return _getKey_2(key_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('getKey')
  @Returns('Request') @Creates('Request') @annotation_Creates_SerializedScriptValue @Creates('ObjectStore')
  Request _getKey_1(KeyRange key) native;
  @JSName('getKey')
  @Returns('Request') @Creates('Request') @annotation_Creates_SerializedScriptValue @Creates('ObjectStore')
  Request _getKey_2(key) native;

  /// @domName IDBIndex.openCursor; @docsEditable true
  Request openCursor([key_OR_range, String direction]) {
    if (!?key_OR_range &&
        !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) &&
        !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range &&
        !?direction) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_4(key_1);
    }
    if (?key_OR_range) {
      var key_2 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_5(key_2, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_1() native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_2(KeyRange range) native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_3(KeyRange range, direction) native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_4(key) native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_5(key, direction) native;

  /// @domName IDBIndex.openKeyCursor; @docsEditable true
  Request openKeyCursor([key_OR_range, String direction]) {
    if (!?key_OR_range &&
        !?direction) {
      return _openKeyCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) &&
        !?direction) {
      return _openKeyCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _openKeyCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range &&
        !?direction) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _openKeyCursor_4(key_1);
    }
    if (?key_OR_range) {
      var key_2 = _convertDartToNative_IDBKey(key_OR_range);
      return _openKeyCursor_5(key_2, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('openKeyCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openKeyCursor_1() native;
  @JSName('openKeyCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openKeyCursor_2(KeyRange range) native;
  @JSName('openKeyCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openKeyCursor_3(KeyRange range, direction) native;
  @JSName('openKeyCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openKeyCursor_4(key) native;
  @JSName('openKeyCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openKeyCursor_5(key, direction) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBKey; @docsEditable true
class Key native "*IDBKey" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBKeyRange
class KeyRange native "*IDBKeyRange" {
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


  /// @domName IDBKeyRange.lower; @docsEditable true
  dynamic get lower => _convertNativeToDart_IDBKey(this._lower);
  @JSName('lower')
  final dynamic _lower;

  /// @domName IDBKeyRange.lowerOpen; @docsEditable true
  final bool lowerOpen;

  /// @domName IDBKeyRange.upper; @docsEditable true
  dynamic get upper => _convertNativeToDart_IDBKey(this._upper);
  @JSName('upper')
  final dynamic _upper;

  /// @domName IDBKeyRange.upperOpen; @docsEditable true
  final bool upperOpen;

  /// @domName IDBKeyRange.bound_; @docsEditable true
  static KeyRange bound_(/*IDBKey*/ lower, /*IDBKey*/ upper, [bool lowerOpen, bool upperOpen]) {
    if (?upperOpen) {
      var lower_1 = _convertDartToNative_IDBKey(lower);
      var upper_2 = _convertDartToNative_IDBKey(upper);
      return _bound__1(lower_1, upper_2, lowerOpen, upperOpen);
    }
    if (?lowerOpen) {
      var lower_3 = _convertDartToNative_IDBKey(lower);
      var upper_4 = _convertDartToNative_IDBKey(upper);
      return _bound__2(lower_3, upper_4, lowerOpen);
    }
    var lower_5 = _convertDartToNative_IDBKey(lower);
    var upper_6 = _convertDartToNative_IDBKey(upper);
    return _bound__3(lower_5, upper_6);
  }
  @JSName('bound')
  static KeyRange _bound__1(lower, upper, lowerOpen, upperOpen) native;
  @JSName('bound')
  static KeyRange _bound__2(lower, upper, lowerOpen) native;
  @JSName('bound')
  static KeyRange _bound__3(lower, upper) native;

  /// @domName IDBKeyRange.lowerBound_; @docsEditable true
  static KeyRange lowerBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      var bound_1 = _convertDartToNative_IDBKey(bound);
      return _lowerBound__1(bound_1, open);
    }
    var bound_2 = _convertDartToNative_IDBKey(bound);
    return _lowerBound__2(bound_2);
  }
  @JSName('lowerBound')
  static KeyRange _lowerBound__1(bound, open) native;
  @JSName('lowerBound')
  static KeyRange _lowerBound__2(bound) native;

  /// @domName IDBKeyRange.only_; @docsEditable true
  static KeyRange only_(/*IDBKey*/ value) {
    var value_1 = _convertDartToNative_IDBKey(value);
    return _only__1(value_1);
  }
  @JSName('only')
  static KeyRange _only__1(value) native;

  /// @domName IDBKeyRange.upperBound_; @docsEditable true
  static KeyRange upperBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      var bound_1 = _convertDartToNative_IDBKey(bound);
      return _upperBound__1(bound_1, open);
    }
    var bound_2 = _convertDartToNative_IDBKey(bound);
    return _upperBound__2(bound_2);
  }
  @JSName('upperBound')
  static KeyRange _upperBound__1(bound, open) native;
  @JSName('upperBound')
  static KeyRange _upperBound__2(bound) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBObjectStore; @docsEditable true
class ObjectStore native "*IDBObjectStore" {

  /// @domName IDBObjectStore.autoIncrement; @docsEditable true
  final bool autoIncrement;

  /// @domName IDBObjectStore.indexNames; @docsEditable true
  @Returns('DomStringList') @Creates('DomStringList')
  final List<String> indexNames;

  /// @domName IDBObjectStore.keyPath; @docsEditable true
  final dynamic keyPath;

  /// @domName IDBObjectStore.name; @docsEditable true
  final String name;

  /// @domName IDBObjectStore.transaction; @docsEditable true
  final Transaction transaction;

  /// @domName IDBObjectStore.add; @docsEditable true
  Request add(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      var value_1 = convertDartToNative_SerializedScriptValue(value);
      var key_2 = _convertDartToNative_IDBKey(key);
      return _add_1(value_1, key_2);
    }
    var value_3 = convertDartToNative_SerializedScriptValue(value);
    return _add_2(value_3);
  }
  @JSName('add')
  @Returns('Request') @Creates('Request') @_annotation_Creates_IDBKey
  Request _add_1(value, key) native;
  @JSName('add')
  @Returns('Request') @Creates('Request') @_annotation_Creates_IDBKey
  Request _add_2(value) native;

  /// @domName IDBObjectStore.clear; @docsEditable true
  Request clear() native;

  /// @domName IDBObjectStore.count; @docsEditable true
  Request count([key_OR_range]) {
    if (!?key_OR_range) {
      return _count_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _count_2(key_OR_range);
    }
    if (?key_OR_range) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _count_3(key_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('count')
  Request _count_1() native;
  @JSName('count')
  Request _count_2(KeyRange range) native;
  @JSName('count')
  Request _count_3(key) native;

  /// @domName IDBObjectStore.createIndex; @docsEditable true
  Index createIndex(String name, keyPath, [Map options]) {
    if ((keyPath is List<String> || keyPath == null) &&
        !?options) {
      return _createIndex_1(name, keyPath);
    }
    if ((keyPath is List<String> || keyPath == null)) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createIndex_2(name, keyPath, options_1);
    }
    if ((keyPath is String || keyPath == null) &&
        !?options) {
      return _createIndex_3(name, keyPath);
    }
    if ((keyPath is String || keyPath == null)) {
      var options_2 = convertDartToNative_Dictionary(options);
      return _createIndex_4(name, keyPath, options_2);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('createIndex')
  Index _createIndex_1(name, List<String> keyPath) native;
  @JSName('createIndex')
  Index _createIndex_2(name, List<String> keyPath, options) native;
  @JSName('createIndex')
  Index _createIndex_3(name, String keyPath) native;
  @JSName('createIndex')
  Index _createIndex_4(name, String keyPath, options) native;

  /// @domName IDBObjectStore.delete; @docsEditable true
  Request delete(key_OR_keyRange) {
    if ((key_OR_keyRange is KeyRange || key_OR_keyRange == null)) {
      return _delete_1(key_OR_keyRange);
    }
    if (?key_OR_keyRange) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_keyRange);
      return _delete_2(key_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('delete')
  Request _delete_1(KeyRange keyRange) native;
  @JSName('delete')
  Request _delete_2(key) native;

  /// @domName IDBObjectStore.deleteIndex; @docsEditable true
  void deleteIndex(String name) native;

  /// @domName IDBObjectStore.getObject; @docsEditable true
  Request getObject(key) {
    if ((key is KeyRange || key == null)) {
      return _getObject_1(key);
    }
    if (?key) {
      var key_1 = _convertDartToNative_IDBKey(key);
      return _getObject_2(key_1);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('get')
  @Returns('Request') @Creates('Request') @annotation_Creates_SerializedScriptValue
  Request _getObject_1(KeyRange key) native;
  @JSName('get')
  @Returns('Request') @Creates('Request') @annotation_Creates_SerializedScriptValue
  Request _getObject_2(key) native;

  /// @domName IDBObjectStore.index; @docsEditable true
  Index index(String name) native;

  /// @domName IDBObjectStore.openCursor; @docsEditable true
  Request openCursor([key_OR_range, String direction]) {
    if (!?key_OR_range &&
        !?direction) {
      return _openCursor_1();
    }
    if ((key_OR_range is KeyRange || key_OR_range == null) &&
        !?direction) {
      return _openCursor_2(key_OR_range);
    }
    if ((key_OR_range is KeyRange || key_OR_range == null)) {
      return _openCursor_3(key_OR_range, direction);
    }
    if (?key_OR_range &&
        !?direction) {
      var key_1 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_4(key_1);
    }
    if (?key_OR_range) {
      var key_2 = _convertDartToNative_IDBKey(key_OR_range);
      return _openCursor_5(key_2, direction);
    }
    throw new ArgumentError("Incorrect number or type of arguments");
  }
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_1() native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_2(KeyRange range) native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_3(KeyRange range, direction) native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_4(key) native;
  @JSName('openCursor')
  @Returns('Request') @Creates('Request') @Creates('Cursor')
  Request _openCursor_5(key, direction) native;

  /// @domName IDBObjectStore.put; @docsEditable true
  Request put(/*any*/ value, [/*IDBKey*/ key]) {
    if (?key) {
      var value_1 = convertDartToNative_SerializedScriptValue(value);
      var key_2 = _convertDartToNative_IDBKey(key);
      return _put_1(value_1, key_2);
    }
    var value_3 = convertDartToNative_SerializedScriptValue(value);
    return _put_2(value_3);
  }
  @JSName('put')
  @Returns('Request') @Creates('Request') @_annotation_Creates_IDBKey
  Request _put_1(value, key) native;
  @JSName('put')
  @Returns('Request') @Creates('Request') @_annotation_Creates_IDBKey
  Request _put_2(value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBOpenDBRequest; @docsEditable true
class OpenDBRequest extends Request implements EventTarget native "*IDBOpenDBRequest" {

  static const EventStreamProvider<Event> blockedEvent = const EventStreamProvider<Event>('blocked');

  static const EventStreamProvider<VersionChangeEvent> upgradeNeededEvent = const EventStreamProvider<VersionChangeEvent>('upgradeneeded');

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  OpenDBRequestEvents get on =>
    new OpenDBRequestEvents(this);

  Stream<Event> get onBlocked => blockedEvent.forTarget(this);

  Stream<VersionChangeEvent> get onUpgradeNeeded => upgradeNeededEvent.forTarget(this);
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


/// @domName IDBRequest; @docsEditable true
class Request extends EventTarget native "*IDBRequest" {

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  static const EventStreamProvider<Event> successEvent = const EventStreamProvider<Event>('success');

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  RequestEvents get on =>
    new RequestEvents(this);

  /// @domName IDBRequest.error; @docsEditable true
  final DomError error;

  /// @domName IDBRequest.readyState; @docsEditable true
  final String readyState;

  /// @domName IDBRequest.result; @docsEditable true
  dynamic get result => _convertNativeToDart_IDBAny(this._result);
  @JSName('result')
  @Creates('Null')
  final dynamic _result;

  /// @domName IDBRequest.source; @docsEditable true
  @Creates('Null')
  final dynamic source;

  /// @domName IDBRequest.transaction; @docsEditable true
  final Transaction transaction;

  /// @domName IDBRequest.webkitErrorMessage; @docsEditable true
  final String webkitErrorMessage;

  /// @domName IDBRequest.addEventListener; @docsEditable true
  @JSName('addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  /// @domName IDBRequest.dispatchEvent; @docsEditable true
  @JSName('dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  /// @domName IDBRequest.removeEventListener; @docsEditable true
  @JSName('removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onError => errorEvent.forTarget(this);

  Stream<Event> get onSuccess => successEvent.forTarget(this);
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


/// @domName IDBTransaction; @docsEditable true
class Transaction extends EventTarget native "*IDBTransaction" {

  static const EventStreamProvider<Event> abortEvent = const EventStreamProvider<Event>('abort');

  static const EventStreamProvider<Event> completeEvent = const EventStreamProvider<Event>('complete');

  static const EventStreamProvider<Event> errorEvent = const EventStreamProvider<Event>('error');

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  TransactionEvents get on =>
    new TransactionEvents(this);

  /// @domName IDBTransaction.db; @docsEditable true
  final Database db;

  /// @domName IDBTransaction.error; @docsEditable true
  final DomError error;

  /// @domName IDBTransaction.mode; @docsEditable true
  final String mode;

  /// @domName IDBTransaction.webkitErrorMessage; @docsEditable true
  final String webkitErrorMessage;

  /// @domName IDBTransaction.abort; @docsEditable true
  void abort() native;

  /// @domName IDBTransaction.addEventListener; @docsEditable true
  @JSName('addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  /// @domName IDBTransaction.dispatchEvent; @docsEditable true
  @JSName('dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  /// @domName IDBTransaction.objectStore; @docsEditable true
  ObjectStore objectStore(String name) native;

  /// @domName IDBTransaction.removeEventListener; @docsEditable true
  @JSName('removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

  Stream<Event> get onAbort => abortEvent.forTarget(this);

  Stream<Event> get onComplete => completeEvent.forTarget(this);

  Stream<Event> get onError => errorEvent.forTarget(this);
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


/// @domName IDBVersionChangeEvent; @docsEditable true
class UpgradeNeededEvent extends Event native "*IDBVersionChangeEvent" {

  /// @domName IDBVersionChangeEvent.newVersion; @docsEditable true
  final int newVersion;

  /// @domName IDBVersionChangeEvent.oldVersion; @docsEditable true
  final int oldVersion;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBVersionChangeEvent; @docsEditable true
class VersionChangeEvent extends Event native "*IDBVersionChangeEvent" {

  /// @domName IDBVersionChangeEvent.version; @docsEditable true
  final String version;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


/// @domName IDBVersionChangeRequest; @docsEditable true
class VersionChangeRequest extends Request implements EventTarget native "*IDBVersionChangeRequest" {

  static const EventStreamProvider<Event> blockedEvent = const EventStreamProvider<Event>('blocked');

  /// @domName EventTarget.addEventListener, EventTarget.removeEventListener, EventTarget.dispatchEvent; @docsEditable true
  VersionChangeRequestEvents get on =>
    new VersionChangeRequestEvents(this);

  Stream<Event> get onBlocked => blockedEvent.forTarget(this);
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


/// @domName IDBAny; @docsEditable true
class _Any native "*IDBAny" {
}
