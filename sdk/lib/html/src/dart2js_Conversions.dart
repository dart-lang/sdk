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

part of html;

Window _convertNativeToDart_Window(win) {
  return _DOMWindowCrossFrame._createSafe(win);
}

EventTarget _convertNativeToDart_EventTarget(e) {
  // Assume it's a Window if it contains the setInterval property.  It may be
  // from a different frame - without a patched prototype - so we cannot
  // rely on Dart type checking.
  if (JS('bool', r'"setInterval" in #', e))
    return _DOMWindowCrossFrame._createSafe(e);
  else
    return e;
}

EventTarget _convertDartToNative_EventTarget(e) {
  if (e is _DOMWindowCrossFrame) {
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

  // None of the native getters that return ImageData have the type ImageData
  // since that is incorrect for FireFox (which returns a plain Object).  So we
  // need something that tells the compiler that the ImageData class has been
  // instantiated.
  // TODO(sra): Remove this when all the ImageData returning APIs have been
  // annotated as returning the union ImageData + Object.
  JS('ImageData', '0');

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
  if (imageData is _TypedImageData) {
    return JS('', '{data: #, height: #, width: #}',
        imageData.data, imageData.height, imageData.width);
  }
  return imageData;
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
    if (isJavaScriptDate(object)) return true;
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
  return convertNativeToDart_AcceptStructuredClone(object, mustCopy: false);
}


const String _idbKey = '=List|=Object|num|String';  // TODO(sra): Add Date.
const _annotation_Creates_IDBKey = const Creates(_idbKey);
const _annotation_Returns_IDBKey = const Returns(_idbKey);
