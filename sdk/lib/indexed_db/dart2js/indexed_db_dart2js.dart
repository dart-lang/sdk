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



@DocsEditable
@DomName('IDBCursor')
class Cursor native "*IDBCursor" {

  @DocsEditable
  @DomName('IDBCursor.direction')
  final String direction;

  @DocsEditable
  @DomName('IDBCursor.key')
  @_annotation_Creates_IDBKey
  @_annotation_Returns_IDBKey
  final Object key;

  @DocsEditable
  @DomName('IDBCursor.primaryKey')
  final Object primaryKey;

  @DocsEditable
  @DomName('IDBCursor.source')
  final dynamic source;

  @DocsEditable
  @DomName('IDBCursor.advance')
  void advance(int count) native;

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
  @DocsEditable
  @DomName('IDBCursor.continue')
  void _continueFunction_1(key) native;
  @JSName('continue')
  @DocsEditable
  @DomName('IDBCursor.continue')
  void _continueFunction_2() native;

  @DocsEditable
  @DomName('IDBCursor.delete')
  Request delete() native;

  Request update(/*any*/ value) {
    var value_1 = convertDartToNative_SerializedScriptValue(value);
    return _update_1(value_1);
  }
  @JSName('update')
  @DocsEditable
  @DomName('IDBCursor.update')
  Request _update_1(value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBCursorWithValue')
class CursorWithValue extends Cursor native "*IDBCursorWithValue" {

  @DocsEditable
  @DomName('IDBCursorWithValue.value')
  @annotation_Creates_SerializedScriptValue
  @annotation_Returns_SerializedScriptValue
  final Object value;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('IDBDatabase')
@SupportedBrowser(SupportedBrowser.CHROME)
@SupportedBrowser(SupportedBrowser.FIREFOX, '15')
@SupportedBrowser(SupportedBrowser.IE, '10')
@Experimental()
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
  final String name;

  @DocsEditable
  @DomName('IDBDatabase.objectStoreNames')
  @Returns('DomStringList')
  @Creates('DomStringList')
  final List<String> objectStoreNames;

  @DocsEditable
  @DomName('IDBDatabase.version')
  final dynamic version;

  @JSName('addEventListener')
  @DocsEditable
  @DomName('IDBDatabase.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @DocsEditable
  @DomName('IDBDatabase.close')
  void close() native;

  ObjectStore createObjectStore(String name, [Map options]) {
    if (?options) {
      var options_1 = convertDartToNative_Dictionary(options);
      return _createObjectStore_1(name, options_1);
    }
    return _createObjectStore_2(name);
  }
  @JSName('createObjectStore')
  @DocsEditable
  @DomName('IDBDatabase.createObjectStore')
  ObjectStore _createObjectStore_1(name, options) native;
  @JSName('createObjectStore')
  @DocsEditable
  @DomName('IDBDatabase.createObjectStore')
  ObjectStore _createObjectStore_2(name) native;

  @DocsEditable
  @DomName('IDBDatabase.deleteObjectStore')
  void deleteObjectStore(String name) native;

  @JSName('dispatchEvent')
  @DocsEditable
  @DomName('IDBDatabase.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable
  @DomName('IDBDatabase.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

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


  int cmp(/*IDBKey*/ first, /*IDBKey*/ second) {
    var first_1 = _convertDartToNative_IDBKey(first);
    var second_2 = _convertDartToNative_IDBKey(second);
    return _cmp_1(first_1, second_2);
  }
  @JSName('cmp')
  @DocsEditable
  @DomName('IDBFactory.cmp')
  int _cmp_1(first, second) native;

  @DocsEditable
  @DomName('IDBFactory.deleteDatabase')
  VersionChangeRequest deleteDatabase(String name) native;

  @DocsEditable
  @DomName('IDBFactory.open')
  @Returns('Request')
  @Creates('Request')
  @Creates('Database')
  OpenDBRequest open(String name, [int version]) native;

  @DocsEditable
  @DomName('IDBFactory.webkitGetDatabaseNames')
  Request webkitGetDatabaseNames() native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBIndex')
class Index native "*IDBIndex" {

  @DocsEditable
  @DomName('IDBIndex.keyPath')
  final dynamic keyPath;

  @DocsEditable
  @DomName('IDBIndex.multiEntry')
  final bool multiEntry;

  @DocsEditable
  @DomName('IDBIndex.name')
  final String name;

  @DocsEditable
  @DomName('IDBIndex.objectStore')
  final ObjectStore objectStore;

  @DocsEditable
  @DomName('IDBIndex.unique')
  final bool unique;

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
  @DocsEditable
  @DomName('IDBIndex.count')
  Request _count_1() native;
  @JSName('count')
  @DocsEditable
  @DomName('IDBIndex.count')
  Request _count_2(KeyRange range) native;
  @JSName('count')
  @DocsEditable
  @DomName('IDBIndex.count')
  Request _count_3(key) native;

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
  @DocsEditable
  @DomName('IDBIndex.get')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  Request _get_1(KeyRange key) native;
  @JSName('get')
  @DocsEditable
  @DomName('IDBIndex.get')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  Request _get_2(key) native;

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
  @DocsEditable
  @DomName('IDBIndex.getKey')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  @Creates('ObjectStore')
  Request _getKey_1(KeyRange key) native;
  @JSName('getKey')
  @DocsEditable
  @DomName('IDBIndex.getKey')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  @Creates('ObjectStore')
  Request _getKey_2(key) native;

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
  @DocsEditable
  @DomName('IDBIndex.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_1() native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBIndex.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_2(KeyRange range) native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBIndex.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_3(KeyRange range, direction) native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBIndex.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_4(key) native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBIndex.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_5(key, direction) native;

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
  @DocsEditable
  @DomName('IDBIndex.openKeyCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openKeyCursor_1() native;
  @JSName('openKeyCursor')
  @DocsEditable
  @DomName('IDBIndex.openKeyCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openKeyCursor_2(KeyRange range) native;
  @JSName('openKeyCursor')
  @DocsEditable
  @DomName('IDBIndex.openKeyCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openKeyCursor_3(KeyRange range, direction) native;
  @JSName('openKeyCursor')
  @DocsEditable
  @DomName('IDBIndex.openKeyCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openKeyCursor_4(key) native;
  @JSName('openKeyCursor')
  @DocsEditable
  @DomName('IDBIndex.openKeyCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openKeyCursor_5(key, direction) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBKey')
class Key native "*IDBKey" {
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


@DocsEditable
@DomName('IDBKeyRange')
class KeyRange native "*IDBKeyRange" {
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


  dynamic get lower => _convertNativeToDart_IDBKey(this._lower);
  @JSName('lower')
  @DocsEditable
  @DomName('IDBKeyRange.lower')
  final dynamic _lower;

  @DocsEditable
  @DomName('IDBKeyRange.lowerOpen')
  final bool lowerOpen;

  dynamic get upper => _convertNativeToDart_IDBKey(this._upper);
  @JSName('upper')
  @DocsEditable
  @DomName('IDBKeyRange.upper')
  final dynamic _upper;

  @DocsEditable
  @DomName('IDBKeyRange.upperOpen')
  final bool upperOpen;

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
  @DocsEditable
  @DomName('IDBKeyRange.bound')
  static KeyRange _bound__1(lower, upper, lowerOpen, upperOpen) native;
  @JSName('bound')
  @DocsEditable
  @DomName('IDBKeyRange.bound')
  static KeyRange _bound__2(lower, upper, lowerOpen) native;
  @JSName('bound')
  @DocsEditable
  @DomName('IDBKeyRange.bound')
  static KeyRange _bound__3(lower, upper) native;

  static KeyRange lowerBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      var bound_1 = _convertDartToNative_IDBKey(bound);
      return _lowerBound__1(bound_1, open);
    }
    var bound_2 = _convertDartToNative_IDBKey(bound);
    return _lowerBound__2(bound_2);
  }
  @JSName('lowerBound')
  @DocsEditable
  @DomName('IDBKeyRange.lowerBound')
  static KeyRange _lowerBound__1(bound, open) native;
  @JSName('lowerBound')
  @DocsEditable
  @DomName('IDBKeyRange.lowerBound')
  static KeyRange _lowerBound__2(bound) native;

  static KeyRange only_(/*IDBKey*/ value) {
    var value_1 = _convertDartToNative_IDBKey(value);
    return _only__1(value_1);
  }
  @JSName('only')
  @DocsEditable
  @DomName('IDBKeyRange.only')
  static KeyRange _only__1(value) native;

  static KeyRange upperBound_(/*IDBKey*/ bound, [bool open]) {
    if (?open) {
      var bound_1 = _convertDartToNative_IDBKey(bound);
      return _upperBound__1(bound_1, open);
    }
    var bound_2 = _convertDartToNative_IDBKey(bound);
    return _upperBound__2(bound_2);
  }
  @JSName('upperBound')
  @DocsEditable
  @DomName('IDBKeyRange.upperBound')
  static KeyRange _upperBound__1(bound, open) native;
  @JSName('upperBound')
  @DocsEditable
  @DomName('IDBKeyRange.upperBound')
  static KeyRange _upperBound__2(bound) native;

}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBObjectStore')
class ObjectStore native "*IDBObjectStore" {

  @DocsEditable
  @DomName('IDBObjectStore.autoIncrement')
  final bool autoIncrement;

  @DocsEditable
  @DomName('IDBObjectStore.indexNames')
  @Returns('DomStringList')
  @Creates('DomStringList')
  final List<String> indexNames;

  @DocsEditable
  @DomName('IDBObjectStore.keyPath')
  final dynamic keyPath;

  @DocsEditable
  @DomName('IDBObjectStore.name')
  final String name;

  @DocsEditable
  @DomName('IDBObjectStore.transaction')
  final Transaction transaction;

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
  @DocsEditable
  @DomName('IDBObjectStore.add')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _add_1(value, key) native;
  @JSName('add')
  @DocsEditable
  @DomName('IDBObjectStore.add')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _add_2(value) native;

  @DocsEditable
  @DomName('IDBObjectStore.clear')
  Request clear() native;

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
  @DocsEditable
  @DomName('IDBObjectStore.count')
  Request _count_1() native;
  @JSName('count')
  @DocsEditable
  @DomName('IDBObjectStore.count')
  Request _count_2(KeyRange range) native;
  @JSName('count')
  @DocsEditable
  @DomName('IDBObjectStore.count')
  Request _count_3(key) native;

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
  @DocsEditable
  @DomName('IDBObjectStore.createIndex')
  Index _createIndex_1(name, List<String> keyPath) native;
  @JSName('createIndex')
  @DocsEditable
  @DomName('IDBObjectStore.createIndex')
  Index _createIndex_2(name, List<String> keyPath, options) native;
  @JSName('createIndex')
  @DocsEditable
  @DomName('IDBObjectStore.createIndex')
  Index _createIndex_3(name, String keyPath) native;
  @JSName('createIndex')
  @DocsEditable
  @DomName('IDBObjectStore.createIndex')
  Index _createIndex_4(name, String keyPath, options) native;

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
  @DocsEditable
  @DomName('IDBObjectStore.delete')
  Request _delete_1(KeyRange keyRange) native;
  @JSName('delete')
  @DocsEditable
  @DomName('IDBObjectStore.delete')
  Request _delete_2(key) native;

  @DocsEditable
  @DomName('IDBObjectStore.deleteIndex')
  void deleteIndex(String name) native;

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
  @DocsEditable
  @DomName('IDBObjectStore.get')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  Request _getObject_1(KeyRange key) native;
  @JSName('get')
  @DocsEditable
  @DomName('IDBObjectStore.get')
  @Returns('Request')
  @Creates('Request')
  @annotation_Creates_SerializedScriptValue
  Request _getObject_2(key) native;

  @DocsEditable
  @DomName('IDBObjectStore.index')
  Index index(String name) native;

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
  @DocsEditable
  @DomName('IDBObjectStore.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_1() native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBObjectStore.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_2(KeyRange range) native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBObjectStore.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_3(KeyRange range, direction) native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBObjectStore.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_4(key) native;
  @JSName('openCursor')
  @DocsEditable
  @DomName('IDBObjectStore.openCursor')
  @Returns('Request')
  @Creates('Request')
  @Creates('Cursor')
  Request _openCursor_5(key, direction) native;

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
  @DocsEditable
  @DomName('IDBObjectStore.put')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _put_1(value, key) native;
  @JSName('put')
  @DocsEditable
  @DomName('IDBObjectStore.put')
  @Returns('Request')
  @Creates('Request')
  @_annotation_Creates_IDBKey
  Request _put_2(value) native;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBOpenDBRequest')
class OpenDBRequest extends Request implements EventTarget native "*IDBOpenDBRequest" {

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



@DocsEditable
@DomName('IDBRequest')
class Request extends EventTarget native "*IDBRequest" {

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
  final DomError error;

  @DocsEditable
  @DomName('IDBRequest.readyState')
  final String readyState;

  dynamic get result => _convertNativeToDart_IDBAny(this._result);
  @JSName('result')
  @DocsEditable
  @DomName('IDBRequest.result')
  @Creates('Null')
  final dynamic _result;

  @DocsEditable
  @DomName('IDBRequest.source')
  @Creates('Null')
  final dynamic source;

  @DocsEditable
  @DomName('IDBRequest.transaction')
  final Transaction transaction;

  @DocsEditable
  @DomName('IDBRequest.webkitErrorMessage')
  final String webkitErrorMessage;

  @JSName('addEventListener')
  @DocsEditable
  @DomName('IDBRequest.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable
  @DomName('IDBRequest.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @JSName('removeEventListener')
  @DocsEditable
  @DomName('IDBRequest.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

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



@DocsEditable
@DomName('IDBTransaction')
class Transaction extends EventTarget native "*IDBTransaction" {

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
  final Database db;

  @DocsEditable
  @DomName('IDBTransaction.error')
  final DomError error;

  @DocsEditable
  @DomName('IDBTransaction.mode')
  final String mode;

  @DocsEditable
  @DomName('IDBTransaction.webkitErrorMessage')
  final String webkitErrorMessage;

  @DocsEditable
  @DomName('IDBTransaction.abort')
  void abort() native;

  @JSName('addEventListener')
  @DocsEditable
  @DomName('IDBTransaction.addEventListener')
  void $dom_addEventListener(String type, EventListener listener, [bool useCapture]) native;

  @JSName('dispatchEvent')
  @DocsEditable
  @DomName('IDBTransaction.dispatchEvent')
  bool $dom_dispatchEvent(Event evt) native;

  @DocsEditable
  @DomName('IDBTransaction.objectStore')
  ObjectStore objectStore(String name) native;

  @JSName('removeEventListener')
  @DocsEditable
  @DomName('IDBTransaction.removeEventListener')
  void $dom_removeEventListener(String type, EventListener listener, [bool useCapture]) native;

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



@DocsEditable
@DomName('IDBVersionChangeEvent')
class UpgradeNeededEvent extends Event native "*IDBVersionChangeEvent" {

  @DocsEditable
  @DomName('IDBUpgradeNeededEvent.newVersion')
  final int newVersion;

  @DocsEditable
  @DomName('IDBUpgradeNeededEvent.oldVersion')
  final int oldVersion;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBVersionChangeEvent')
class VersionChangeEvent extends Event native "*IDBVersionChangeEvent" {

  @DocsEditable
  @DomName('IDBVersionChangeEvent.version')
  final String version;
}
// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.



@DocsEditable
@DomName('IDBVersionChangeRequest')
class VersionChangeRequest extends Request implements EventTarget native "*IDBVersionChangeRequest" {

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



@DocsEditable
@DomName('IDBAny')
class _Any native "*IDBAny" {
}
