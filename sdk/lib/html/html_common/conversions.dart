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

part of html_common;


/// Converts a JavaScript object with properties into a Dart Map.
/// Not suitable for nested objects.
Map convertNativeToDart_Dictionary(object) {
  if (object == null) return null;
  var dict = {};
  var keys = JS('JSExtendableArray', 'Object.getOwnPropertyNames(#)', object);
  for (final key in keys) {
    dict[key] = JS('var', '#[#]', object, key);
  }
  return dict;
}

/// Converts a flat Dart map into a JavaScript object with properties.
convertDartToNative_Dictionary(Map dict) {
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
List convertDartToNative_StringArray(List<String> input) {
  // TODO(sra).  Implement this.
  return input;
}

DateTime convertNativeToDart_DateTime(date) {
  var millisSinceEpoch = JS('int', '#.getTime()', date);
  return new DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch, isUtc: true);
}

convertDartToNative_DateTime(DateTime date) {
  return JS('', 'new Date(#)', date.millisecondsSinceEpoch);
}


// -----------------------------------------------------------------------------

/// Converts a Dart value into a JavaScript SerializedScriptValue.
convertDartToNative_SerializedScriptValue(value) {
  return _convertDartToNative_PrepareForStructuredClone(value);
}

/// Since the source object may be viewed via a JavaScript event listener the
/// original may not be modified.
convertNativeToDart_SerializedScriptValue(object) {
  return convertNativeToDart_AcceptStructuredClone(object, mustCopy: true);
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
    if (e is DateTime) {
      return convertDartToNative_DateTime(e);
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

    if (e is File) return e;
    if (e is Blob) return e;
    if (e is FileList) return e;

    // TODO(sra): Firefox: How to convert _TypedImageData on the other end?
    if (e is ImageData) return e;
    if (e is NativeByteBuffer) return e;

    if (e is NativeTypedData) return e;

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
          copy = JS('JSExtendableArray', 'new Array(#)', length);
          writeSlot(slot, copy);
        }
        return copy;
      }

      int i = 0;

      // Always clone the list, as it may have non-native properties or methods
      // from interceptors and such.
      copy = JS('JSExtendableArray', 'new Array(#)', length);
      writeSlot(slot, copy);

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
convertNativeToDart_AcceptStructuredClone(object, {mustCopy: false}) {

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

    if (isJavaScriptDate(e)) {
      return convertNativeToDart_DateTime(e);
    }

    if (isJavaScriptRegExp(e)) {
      // TODO(sra).
      throw new UnimplementedError('structured clone of RegExp');
    }

    if (isJavaScriptSimpleObject(e)) {
      // TODO(sra): If mustCopy is false, swizzle the prototype for one of a Map
      // implementation that uses the properies as storage.
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;
      copy = {};

      writeSlot(slot, copy);
      for (final key in JS('JSExtendableArray', 'Object.keys(#)', e)) {
        copy[key] = walk(JS('var', '#[#]', e, key));
      }
      return copy;
    }

    if (isJavaScriptArray(e)) {
      var slot = findSlot(e);
      var copy = readSlot(slot);
      if (copy != null) return copy;

      int length = e.length;
      // Since a JavaScript Array is an instance of Dart List, we can modify it
      // in-place unless we must copy.
      copy = mustCopy ? JS('JSExtendableArray', 'new Array(#)', length) : e;
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

// Conversions for ContextAttributes.
//
// On Firefox, the returned ContextAttributes is a plain object.
class _TypedContextAttributes implements gl.ContextAttributes {
  bool alpha;
  bool antialias;
  bool depth;
  bool premultipliedAlpha;
  bool preserveDrawingBuffer;
  bool stencil;
  bool failIfMajorPerformanceCaveat;

  _TypedContextAttributes(this.alpha, this.antialias, this.depth,
      this.failIfMajorPerformanceCaveat, this.premultipliedAlpha,
      this.preserveDrawingBuffer, this.stencil);
}

gl.ContextAttributes convertNativeToDart_ContextAttributes(
    nativeContextAttributes) {
  if (nativeContextAttributes is gl.ContextAttributes) {
    return nativeContextAttributes;
  }

  // On Firefox the above test fails because ContextAttributes is a plain
  // object so we create a _TypedContextAttributes.

  return new _TypedContextAttributes(
      JS('var', '#.alpha', nativeContextAttributes),
      JS('var', '#.antialias', nativeContextAttributes),
      JS('var', '#.depth', nativeContextAttributes),
      JS('var', '#.failIfMajorPerformanceCaveat', nativeContextAttributes),
      JS('var', '#.premultipliedAlpha', nativeContextAttributes),
      JS('var', '#.preserveDrawingBuffer', nativeContextAttributes),
      JS('var', '#.stencil', nativeContextAttributes));
}

// Conversions for ImageData
//
// On Firefox, the returned ImageData is a plain object.

class _TypedImageData implements ImageData {
  final NativeUint8ClampedList data;
  final int height;
  final int width;

  _TypedImageData(this.data, this.height, this.width);
}

ImageData convertNativeToDart_ImageData(nativeImageData) {

  // None of the native getters that return ImageData are declared as returning
  // [ImageData] since that is incorrect for FireFox, which returns a plain
  // Object.  So we need something that tells the compiler that the ImageData
  // class has been instantiated.
  // TODO(sra): Remove this when all the ImageData returning APIs have been
  // annotated as returning the union ImageData + Object.
  JS('ImageData', '0');

  if (nativeImageData is ImageData) {

    // Fix for Issue 16069: on IE, the `data` field is a CanvasPixelArray which
    // has Array as the constructor property.  This interferes with finding the
    // correct interceptor.  Fix it by overwriting the constructor property.
    var data = nativeImageData.data;
    if (JS('bool', '#.constructor === Array', data)) {
      if (JS('bool', 'typeof CanvasPixelArray !== "undefined"')) {
        JS('void', '#.constructor = CanvasPixelArray', data);
        // This TypedArray property is missing from CanvasPixelArray.
        JS('void', '#.BYTES_PER_ELEMENT = 1', data);
      }
    }

    return nativeImageData;
  }

  // On Firefox the above test fails because [nativeImageData] is a plain
  // object.  So we create a _TypedImageData.

  return new _TypedImageData(
      JS('NativeUint8ClampedList', '#.data', nativeImageData),
      JS('var', '#.height', nativeImageData),
      JS('var', '#.width', nativeImageData));
}

// We can get rid of this conversion if _TypedImageData implements the fields
// with native names.
convertDartToNative_ImageData(ImageData imageData) {
  if (imageData is _TypedImageData) {
    return JS('', '{data: #, height: #, width: #}',
        imageData.data, imageData.height, imageData.width);
  }
  return imageData;
}


bool isJavaScriptDate(value) => JS('bool', '# instanceof Date', value);
bool isJavaScriptRegExp(value) => JS('bool', '# instanceof RegExp', value);
bool isJavaScriptArray(value) => JS('bool', '# instanceof Array', value);
bool isJavaScriptSimpleObject(value) =>
    JS('bool', 'Object.getPrototypeOf(#) === Object.prototype', value);
bool isImmutableJavaScriptArray(value) =>
    JS('bool', r'!!(#.immutable$list)', value);



const String _serializedScriptValue =
    'num|String|bool|'
    'JSExtendableArray|=Object|'
    'Blob|File|NativeByteBuffer|NativeTypedData'
    // TODO(sra): Add Date, RegExp.
    ;
const annotation_Creates_SerializedScriptValue =
    const Creates(_serializedScriptValue);
const annotation_Returns_SerializedScriptValue =
    const Returns(_serializedScriptValue);
