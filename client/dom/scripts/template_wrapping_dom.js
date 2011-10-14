// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT
// Auto-generated Dart DOM implementation.

$!CODE

function __dom_native_TimeoutHander_method(_this, callback, timeout, operation) {
  try {
    return _this.$dom[operation](__dom_unwrap_TimeoutHandler_function(callback),
                                 __dom_unwrap(timeout));
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__DOMWindowWrappingImplementation__setInterval(_this, callback, timeout) {
  return __dom_native_TimeoutHander_method(_this, callback, timeout, 'setInterval');
}

function native__DOMWindowWrappingImplementation__setTimeout(_this, callback, timeout) {
  return __dom_native_TimeoutHander_method(_this, callback, timeout, 'setTimeout');
}

function native__WorkerContextWrappingImplementation__setInterval(_this, callback, timeout) {
  return __dom_native_TimeoutHander_method(_this, callback, timeout, 'setInterval');
}

function native__WorkerContextWrappingImplementation__setTimeout(_this, callback, timeout) {
  return __dom_native_TimeoutHander_method(_this, callback, timeout, 'setTimeout');
}

function native__DOMWindowWrappingImplementation__createFileReader(_this) {
  try {
    return __dom_wrap(new FileReader());
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__DOMWindowWrappingImplementation__createWebKitCSSMatrix(_this) {
  try {
    return __dom_wrap(new WebKitCSSMatrix());
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__DOMWindowWrappingImplementation__createWebKitCSSMatrix_2(_this, cssValue) {
  try {
    return __dom_wrap(new WebKitCSSMatrix(__dom_unwrap(cssValue)));
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__DOMWindowWrappingImplementation__createWebKitPoint(_this, x, y) {
  try {
    return __dom_wrap(new WebKitPoint(x, y));
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__DOMWindowWrappingImplementation__createXMLHttpRequest(_this) {
  try {
    return __dom_wrap(new XMLHttpRequest());
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__CanvasRenderingContext2DWrappingImplementation__setFillStyle(_this, color_OR_gradient_OR_pattern) {
  try {
    _this.$dom.fillStyle = __dom_unwrap(color_OR_gradient_OR_pattern);
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__CanvasRenderingContext2DWrappingImplementation__setFillStyle_2(_this, color_OR_gradient_OR_pattern) {
  try {
    _this.$dom.fillStyle = __dom_unwrap(color_OR_gradient_OR_pattern);
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__CanvasRenderingContext2DWrappingImplementation__setFillStyle_3(_this, color_OR_gradient_OR_pattern) {
  try {
    _this.$dom.fillStyle = __dom_unwrap(color_OR_gradient_OR_pattern);
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__CanvasRenderingContext2DWrappingImplementation__setStrokeStyle(_this, color_OR_gradient_OR_pattern) {
  try {
    _this.$dom.strokeStyle = __dom_unwrap(color_OR_gradient_OR_pattern);
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__CanvasRenderingContext2DWrappingImplementation__setStrokeStyle_2(_this, color_OR_gradient_OR_pattern) {
  try {
    _this.$dom.strokeStyle = __dom_unwrap(color_OR_gradient_OR_pattern);
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__CanvasRenderingContext2DWrappingImplementation__setStrokeStyle_3(_this, color_OR_gradient_OR_pattern) {
  try {
    _this.$dom.strokeStyle = __dom_unwrap(color_OR_gradient_OR_pattern);
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__DOMWindowWrappingImplementation__get__DOMWindow_localStorage(_this) {
  var domWindow = _this.$dom;
  try {
    var isolatetoken = __dom_isolate_token();
    var wrapper = __dom_get_cached('dart_storage', domWindow, isolatetoken);
    if (wrapper) return wrapper;
    wrapper = native__StorageWrappingImplementation_create__StorageWrappingImplementation();
    wrapper.$dom = domWindow.localStorage;
    __dom_set_cached('dart_storage', domWindow, isolatetoken, wrapper)
    return wrapper;
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

// Native methods for factory providers.

function native__FileReaderFactoryProvider_create() {
  try {
    return __dom_wrap(new FileReader());
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__WebKitCSSMatrixFactoryProvider_create(spec) {
  try {
    return __dom_wrap(new WebKitCSSMatrix(spec));  // string doesn't need unwrap.
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__WebKitPointFactoryProvider_create(x, y) {
  try {
    return __dom_wrap(new WebKitPoint(x, y));  // nums don't need unwrap.
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}

function native__XMLHttpRequestFactoryProvider_create() {
  try {
    return __dom_wrap(new XMLHttpRequest());
  } catch (e) {
    throw __dom_wrap_exception(e);
  }
}


var __dom_type_map = {
$!MAP
  // Patches for non-WebKit browsers
  'Window': native__DOMWindowWrappingImplementation_create__DOMWindowWrappingImplementation,
  'global': native__DOMWindowWrappingImplementation_create__DOMWindowWrappingImplementation,
  'KeyEvent': native__KeyboardEventWrappingImplementation_create__KeyboardEventWrappingImplementation, // Opera
  'HTMLPhraseElement': native__HTMLElementWrappingImplementation_create__HTMLElementWrappingImplementation, // IE9
  'MSStyleCSSProperties': native__CSSStyleDeclarationWrappingImplementation_create__CSSStyleDeclarationWrappingImplementation // IE9
};

function __dom_get_class_chrome(ptr) {
  return __dom_type_map[ptr.constructor.name];
}

function __dom_get_class_generic(ptr) {
  var str = Object.prototype.toString.call(ptr);
  var name = str.substring(8, str.length - 1);
  var cls = __dom_type_map[name];
  return cls;
}

if (Object.__proto__) {
  __dom_get_class_generic = function(ptr) {
    var isolatetoken = __dom_isolate_token();
    var result = __dom_get_cached('dart_class', ptr.__proto__, isolatetoken);
    if (result) {
      return result;
    }
    var str = Object.prototype.toString.call(ptr);
    var name = str.substring(8, str.length - 1);
    var cls = __dom_type_map[name];
    __dom_set_cached('dart_class', ptr.__proto__, isolatetoken, cls);
    return cls;
  }
}

var __dom_get_class = __dom_get_class_generic;
if (typeof window !== 'undefined' &&  // webworkers don't have a window
    window.constructor.name == "DOMWindow") {
  __dom_get_class = __dom_get_class_chrome;
}

function __dom_get_cached(hashtablename, obj, isolatetoken) {
  if (!obj.hasOwnProperty(hashtablename)) return (void 0);
  var hashtable = obj[hashtablename];
  var hash = isolatetoken.hashCode;
  while (true) {
    var result = hashtable[hash];
    if (result) {
      if (result.$token === isolatetoken) {
        return result;
      } else {
        hash++;
      }
    } else {
      return (void 0);
    }
  }
}

function __dom_set_cached(hashtablename, obj, isolatetoken, value) {
  var hashtable;
  if (!obj.hasOwnProperty(hashtablename)) {
    hashtable = [];
    obj[hashtablename] = hashtable;
  } else {
    hashtable = obj[hashtablename];
  }
  var hash = isolatetoken.hashCode;
  while (true) {
    var entry = hashtable[hash];
    if (entry) {
      if (entry.$token === isolatetoken) {
        throw "Wrapper already exists for this object: " + obj;
      } else {
        hash++;
      }
    } else {
      value.$token = isolatetoken;
      hashtable[hash] = value;
      return;
    }
  }
}

function __dom_isolate_token() {
  return isolate$current.token;
}

/** @suppress {duplicate} */
function __dom_wrap(ptr) {
  if (ptr == null) {
    return (void 0);
  }
  var type = typeof(ptr);
  if (type != "object" && type != "function") {
    return ptr;
  }
  var isolatetoken = __dom_isolate_token();
  var wrapper = __dom_get_cached('dart_wrapper', ptr, isolatetoken);
  if (wrapper) {
    return wrapper;
  }
  var factory = __dom_get_class(ptr);
  if (!factory) {
    return ptr;
  }
  wrapper = factory();
  wrapper.$dom = ptr;
  __dom_set_cached('dart_wrapper', ptr, isolatetoken, wrapper);
  return wrapper;
}

function __dom_wrap_exception(e) {
  return __dom_wrap(e);
}

function __dom_wrap_primitive(ptr) {
  return (ptr === null) ? (void 0) : ptr;
}


function __dom_finish_unwrap_function(fn, unwrapped) {
  fn.$dom = unwrapped;
  var isolatetoken = __dom_isolate_token();
  __dom_set_cached('dart_wrapper', unwrapped, isolatetoken, fn);
  return unwrapped;
}

/** @suppress {duplicate} */
function __dom_unwrap(obj) {
  if (obj == null) {
    return (void 0);
  }
  if (obj.$dom) {
    return obj.$dom;
  }
  if (obj instanceof Function) {  // BUGBUG: function from other IFrame
    var unwrapped = function () {
      var args = Array.prototype.slice.call(arguments);
      return $dartcall(obj, args.map(__dom_wrap));
      // BUGBUG? Should the result be unwrapped? Or is it always void/bool ?
    };
    return __dom_finish_unwrap_function(obj, unwrapped);
  }
  return obj;
}

function __dom_unwrap_TimeoutHandler_function(fn) {
  // Some browsers (e.g. FF) pass data to the timeout function, others do not.
  // Dart's TimeoutHandler takes no arguments, so drop any arguments passed to
  // the unwrapped callback.
  return __dom_finish_unwrap_function(
      fn,
      function() { return $dartcall(fn, []); });
}

// Declared in src/GlobalProperties.dart
function native__NativeDomGlobalProperties_getWindow() {
  // TODO: Should the window be obtained from an isolate?
  return __dom_wrap(window);
}

// Declared in src/GlobalProperties.dart
function native__NativeDomGlobalProperties_getDocument() {
  // TODO: Should the window be obtained from an isolate?
  return __dom_wrap(window.document);
}
