// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


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

// Conversions for Window.  These check if the window is the local
// window, and if it's not, wraps or unwraps it with a secure wrapper.
// We need to test for EventTarget here as well as it's a base type.
// We omit an unwrapper for Window as no methods take a non-local
// window as a parameter.

Window _convertNativeToDart_Window(win) {
  return _DOMWindowCrossFrameImpl._createSafe(win);
}

EventTarget _convertNativeToDart_EventTarget(e) {
  // Assume it's a Window if it contains the setInterval property.  It may be
  // from a different frame - without a patched prototype - so we cannot
  // rely on Dart type checking.
  if (JS('bool', r'"setInterval" in #', e))
    return _DOMWindowCrossFrameImpl._createSafe(e);
  else
    return e;
}

EventTarget _convertDartToNative_EventTarget(e) {
  if (e is _DOMWindowCrossFrameImpl) {
    return e._window;
  } else {
    return e;
  }
}

// Conversions for ImageData
//
// On Firefox, the returned ImageData is a plain object.

class _TypedImageData implements ImageData {
  final Uint8ClampedArray data;
  final int height;
  final int width;

  _TypedImageData(this.data, this.height, this.width);
}

ImageData _convertNativeToDart_ImageData(nativeImageData) {
  if (nativeImageData is ImageData) return nativeImageData;

  // On Firefox the above test fails because imagedata is a plain object.
  // So we create a _TypedImageData.

  return new _TypedImageData(
      JS('var', '#.data', nativeImageData),
      JS('var', '#.height', nativeImageData),
      JS('var', '#.width', nativeImageData));
}

// We can get rid of this conversion if _TypedImageData implements the fields
// with native names.
_convertDartToNative_ImageData(ImageData imageData) {
  if (imageData is _ImageDataImpl) return imageData;
  return JS('Object', '{data: #, height: #, width: #}',
            imageData.data, imageData.height, imageData.width);
}


/// Converts a JavaScript object with properties into a Dart Map.
/// Not suitable for nested objects.
Map _convertNativeToDart_Dictionary(object) {
  if (object == null) return null;
  var dict = {};
  for (final key in JS('List', 'Object.getOwnPropertyNames(#)', object)) {
    dict[key] = JS('var', '#[#]', object, key);
  }
  return dict;
}

/// Converts a flat Dart map into a JavaScript object with properties.
_convertDartToNative_Dictionary(Map dict) {
  if (dict == null) return null;
  var object = JS('var', '{}');
  dict.forEach((String key, value) {
      JS('void', '#[#] = #', object, key, value);
    });
  return object;
}


/**
 * Ensures that the input is a JavaScript Array.
 *
 * Creates a new JavaScript array if necessary, otherwise returns the original.
 */
List _convertDartToNative_StringArray(List<String> input) {
  // TODO(sra).  Implement this.
  return input;
}


// -----------------------------------------------------------------------------

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
    if (_isJavaScriptDate(object)) return true;
    if (object is List) {
      for (int i = 0; i < object.length; i++) {
        if (containsDate(object[i])) return true;
      }
    }
    return false;  // number, string.
  }
  if (containsDate(nativeKey)) {
    throw new UnimplementedError('IDBKey containing Date');
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
  return _convertNativeToDart_AcceptStructuredClone(object, mustCopy: false);
}

/// Converts a Dart value into a JavaScript SerializedScriptValue.
_convertDartToNative_SerializedScriptValue(value) {
  return _convertDartToNative_PrepareForStructuredClone(value);
}

/// Since the source object may be viewed via a JavaScript event listener the
/// original may not be modified.
_convertNativeToDart_SerializedScriptValue(object) {
  return _convertNativeToDart_AcceptStructuredClone(object, mustCopy: true);
}


/**
 * Converts a Dart value into a JavaScript SerializedScriptValue.  Returns the
 * original input or a functional 'copy'.  Does not mutate the original.
 *
 * The main transformation is the translation of Dart Maps are converted to
 * JavaScript Objects.
 *
 * The algorithm is essentially a dry-run of the structured clone algorithm
 * described at
 * http://www.whatwg.org/specs/web-apps/current-work/multipage/common-dom-interfaces.html#structured-clone
 * https://www.khronos.org/registry/typedarray/specs/latest/#9
 *
 * Since the result of this function is expected to be passed only to JavaScript
 * operations that perform the structured clone algorithm which does not mutate
 * its output, the result may share structure with the input [value].
 */
_convertDartToNative_PrepareForStructuredClone(value) {

  // TODO(sra): Replace slots with identity hash table.
  var values = [];
  var copies = [];  // initially 'null', 'true' during initial DFS, then a copy.

  int findSlot(value) {
    int length = values.length;
    for (int i = 0; i < length; i++) {
      if (identical(values[i], value)) return i;
    }
    values.add(value);
    copies.add(null);
    return length;
  }
  readSlot(int i) => copies[i];
  writeSlot(int i, x) { copies[i] = x; }
  cleanupSlots() {}  // Will be needed if we mark objects with a property.

  // Returns the input, or a clone of the input.
  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;
    if (e is Date) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of Date');
    }
    if (e is RegExp) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    // The browser's internal structured cloning algorithm will copy certain
    // types of object, but it will copy only its own implementations and not
    // just any Dart implementations of the interface.

    // TODO(sra): The JavaScript objects suitable for direct cloning by the
    // structured clone algorithm could be tagged with an private interface.

    if (e is _FileImpl) return e;
    if (e is File) {
      throw new UnimplementedError('structured clone of File');
    }

    if (e is _BlobImpl) return e;
    if (e is Blob) {
      throw new UnimplementedError('structured clone of Blob');
    }

    if (e is _FileListImpl) return e;

    // TODO(sra): Firefox: How to convert _TypedImageData on the other end?
    if (e is _ImageDataImpl) return e;
    if (e is ImageData) {
      throw new UnimplementedError('structured clone of ImageData');
    }

    if (e is _ArrayBufferImpl) return e;
    if (e is ArrayBuffer) {
      throw new UnimplementedError('structured clone of ArrayBuffer');
    }

    if (e is _ArrayBufferViewImpl) return e;
    if (e is ArrayBufferView) {
      throw new UnimplementedError('structured clone of ArrayBufferView');
    }

    if (e is Map) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = JS('var', '{}');
      writeSlot(slot, copy);
      e.forEach((key, value) {
          JS('void', '#[#] = #', copy, key, walk(value));
        });
      return copy;
    }

    if (e is List) {
      // Since a JavaScript Array is an instance of Dart List it is possible to
      // avoid making a copy of the list if there is no need to copy anything
      // reachable from the array.  We defer creating a new array until a cycle
      // is detected or a subgraph was copied.
      int length = e.length;
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) {
        if (true == copy) {  // Cycle, so commit to making a copy.
          copy = JS('List', 'new Array(#)', length);
          writeSlot(slot, copy);
        }
        return copy;
      }

      int i = 0;

      if (_isJavaScriptArray(e) &&
          // We have to copy immutable lists, otherwise the structured clone
          // algorithm will copy the .immutable$list marker property, making the
          // list immutable when received!
          !_isImmutableJavaScriptArray(e)) {
        writeSlot(slot, true);  // Deferred copy.
        for ( ; i < length; i++) {
          var element = e[i];
          var elementCopy = walk(element);
          if (!identical(elementCopy, element)) {
            copy = readSlot(slot);   // Cyclic reference may have created it.
            if (true == copy) {
              copy = JS('List', 'new Array(#)', length);
              writeSlot(slot, copy);
            }
            for (int j = 0; j < i; j++) {
              copy[j] = e[j];
            }
            copy[i] = elementCopy;
            i++;
            break;
          }
        }
        if (copy == null) {
          copy = e;
          writeSlot(slot, copy);
        }
      } else {
        // Not a JavaScript Array.  We are forced to make a copy.
        copy = JS('List', 'new Array(#)', length);
        writeSlot(slot, copy);
      }

      for ( ; i < length; i++) {
        copy[i] = walk(e[i]);
      }
      return copy;
    }

    throw new UnimplementedError('structured clone of other type');
  }

  var copy = walk(value);
  cleanupSlots();
  return copy;
}

/**
 * Converts a native value into a Dart object.
 *
 * If [mustCopy] is [:false:], may return the original input.  May mutate the
 * original input (but will be idempotent if mutation occurs).  It is assumed
 * that this conversion happens on native serializable script values such values
 * from native DOM calls.
 *
 * [object] is the result of a structured clone operation.
 *
 * If necessary, JavaScript Dates are converted into Dart Dates.
 *
 * If [mustCopy] is [:true:], the entire object is copied and the original input
 * is not mutated.  This should be the case where Dart and JavaScript code can
 * access the value, for example, via multiple event listeners for
 * MessageEvents.  Mutating the object to make it more 'Dart-like' would corrupt
 * the value as seen from the JavaScript listeners.
 */
_convertNativeToDart_AcceptStructuredClone(object, {mustCopy = false}) {

  // TODO(sra): Replace slots with identity hash table that works on non-dart
  // objects.
  var values = [];
  var copies = [];

  int findSlot(value) {
    int length = values.length;
    for (int i = 0; i < length; i++) {
      if (identical(values[i], value)) return i;
    }
    values.add(value);
    copies.add(null);
    return length;
  }
  readSlot(int i) => copies[i];
  writeSlot(int i, x) { copies[i] = x; }

  walk(e) {
    if (e == null) return e;
    if (e is bool) return e;
    if (e is num) return e;
    if (e is String) return e;

    if (_isJavaScriptDate(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of Date');
    }

    if (_isJavaScriptRegExp(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    if (_isJavaScriptSimpleObject(e)) {
      // TODO(sra): If mustCopy is false, swizzle the prototype for one of a Map
      // implementation that uses the properies as storage.
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = {};

      writeSlot(slot, copy);
      for (final key in JS('List', 'Object.keys(#)', e)) {
        copy[key] = walk(JS('var', '#[#]', e, key));
      }
      return copy;
    }

    if (_isJavaScriptArray(e)) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;

      int length = e.length;
      // Since a JavaScript Array is an instance of Dart List, we can modify it
      // in-place unless we must copy.
      copy = mustCopy ? JS('List', 'new Array(#)', length) : e;
      writeSlot(slot, copy);

      for (int i = 0; i < length; i++) {
        copy[i] = walk(e[i]);
      }
      return copy;
    }

    // Assume anything else is already a valid Dart object, either by having
    // already been processed, or e.g. a clonable native class.
    return e;
  }

  var copy = walk(object);
  return copy;
}


bool _isJavaScriptDate(value) => JS('bool', '# instanceof Date', value);
bool _isJavaScriptRegExp(value) => JS('bool', '# instanceof RegExp', value);
bool _isJavaScriptArray(value) => JS('bool', '# instanceof Array', value);
bool _isJavaScriptSimpleObject(value) =>
    JS('bool', 'Object.getPrototypeOf(#) === Object.prototype', value);
bool _isImmutableJavaScriptArray(value) =>
    JS('bool', r'!!(#.immutable$list)', value);
