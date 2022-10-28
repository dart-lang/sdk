// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@ReifyFunctionTypes(false)
library dart._runtime;

import 'dart:async';
import 'dart:collection';

import 'dart:_debugger' show stackTraceMapper, trackCall;
import 'dart:_foreign_helper'
    show JS, JS_CLASS_REF, JS_GET_FLAG, JS_GET_NAME, JSExportName, rest, spread;
import 'dart:_interceptors'
    show
        JSArray,
        jsNull,
        JSFunction,
        NativeError,
        JavaScriptObject,
        LegacyJavaScriptObject;
import 'dart:_internal' as internal show LateError, Symbol;
import 'dart:_js_helper'
    show
        AssertionErrorImpl,
        BooleanConversionAssertionError,
        DartIterator,
        DeferredNotLoadedError,
        TypeErrorImpl,
        JsLinkedHashMap,
        ImmutableMap,
        PrivateSymbol,
        ReifyFunctionTypes,
        NoReifyGeneric,
        notNull,
        undefined;
import 'dart:_js_shared_embedded_names';
import 'dart:_rti' as rti
    show
        constructorRtiCachePropertyName,
        instanceType,
        interfaceTypeRecipePropertyName;

export 'dart:_debugger' show getDynamicStats, clearDynamicStats, trackCall;

part 'utils.dart';
part 'classes.dart';
part 'rtti.dart';
part 'types.dart';
part 'errors.dart';
part 'operations.dart';

// TODO(vsm): Move polyfill code to dart:html.
// Note, native extensions are registered onto types in dart.global.
// This polyfill needs to run before the corresponding dart:html code is run.
final _polyfilled = JS('', 'Symbol("_polyfilled")');

bool polyfill(window) => JS('', '''(() => {
  if ($window[$_polyfilled]) return false;
  $window[$_polyfilled] = true;

  if (typeof $window.NodeList !== "undefined") {
    // TODO(vsm): Do we still need these?
    $window.NodeList.prototype.get = function(i) { return this[i]; };
    $window.NamedNodeMap.prototype.get = function(i) { return this[i]; };
    $window.DOMTokenList.prototype.get = function(i) { return this[i]; };
    $window.HTMLCollection.prototype.get = function(i) { return this[i]; };

    // Expose constructors for DOM types dart:html needs to assume are
    // available on window.
    if (typeof $window.PannerNode == "undefined") {
      let audioContext;
      if (typeof $window.AudioContext == "undefined" &&
          (typeof $window.webkitAudioContext != "undefined")) {
        audioContext = new $window.webkitAudioContext();
      } else {
        audioContext = new $window.AudioContext();
        $window.StereoPannerNode =
            audioContext.createStereoPanner().constructor;
      }
      $window.PannerNode = audioContext.createPanner().constructor;
    }
    if (typeof $window.AudioSourceNode == "undefined") {
      $window.AudioSourceNode = MediaElementAudioSourceNode.__proto__;
    }
    if (typeof $window.FontFaceSet == "undefined") {
      // CSS Font Loading is not supported on Edge.
      if (typeof $window.document.fonts != "undefined") {
        $window.FontFaceSet = $window.document.fonts.__proto__.constructor;
      }
    }
    if (typeof $window.MemoryInfo == "undefined") {
      if (typeof $window.performance.memory != "undefined") {
        $window.MemoryInfo = function () {};
        $window.MemoryInfo.prototype = $window.performance.memory.__proto__;
      }
    }
    if (typeof $window.Geolocation == "undefined") {
      $window.Geolocation == $window.navigator.geolocation.constructor;
    }
    if (typeof $window.Animation == "undefined") {
      let d = $window.document.createElement('div');
      if (typeof d.animate != "undefined") {
        $window.Animation = d.animate(d).constructor;
      }
    }
    if (typeof $window.SourceBufferList == "undefined") {
      if ('MediaSource' in $window) {
        $window.SourceBufferList =
          new $window.MediaSource().sourceBuffers.constructor;
      }
    }
    if (typeof $window.SpeechRecognition == "undefined") {
      $window.SpeechRecognition = $window.webkitSpeechRecognition;
      $window.SpeechRecognitionError = $window.webkitSpeechRecognitionError;
      $window.SpeechRecognitionEvent = $window.webkitSpeechRecognitionEvent;
    }
  }
  return true;
})()''');

@JSExportName('global')
final Object global_ = JS('', '''
  function () {
    // Find global object.
    var globalState = (typeof window != "undefined") ? window
      : (typeof global != "undefined") ? global
      : (typeof self != "undefined") ? self : null;
    if (!globalState) {
      // Some platforms (e.g., d8) do not define any of the above.  The
      // following is a non-CSP safe way to access the global object:
      globalState = new Function('return this;')();
    }

    $polyfill(globalState);

    // By default, stack traces cutoff at 10.  Set the limit to Infinity for
    // better debugging.
    if (globalState.Error) {
      globalState.Error.stackTraceLimit = Infinity;
    }

    // These settings must be configured before the application starts so that
    // user code runs with the correct configuration.
    let settings = 'ddcSettings' in globalState ? globalState.ddcSettings : {};

    $trackProfile(
        'trackProfile' in settings ? settings.trackProfile : false);

    return globalState;
  }()
''');

void trackProfile(bool flag) {
  JS('', 'dart.__trackProfile = #', flag);
}

final JsSymbol = JS('', 'Symbol');

/// The prototype used for all Dart libraries.
///
/// This makes it easy to identify Dart library objects, and also improves
/// performance (JS engines such as V8 tend to assume `Object.create(null)` is
/// used for a Map, so they don't optimize it as they normally would for
/// class-like objects).
///
/// The `dart.library` field is set by the compiler during SDK bootstrapping
/// (because it is needed for dart:_runtime itself), so we don't need to
/// initialize it here. The name `dart.library` is used because it reads nicely,
/// for example:
///
///     const my_library = Object.create(dart.library);
///
Object libraryPrototype = JS('', 'dart.library');

// TODO(vsm): Remove once this flag we've removed the ability to
// whitelist / fallback on the old behavior.
bool startAsyncSynchronously = true;
void setStartAsyncSynchronously([bool value = true]) {
  startAsyncSynchronously = value;
}

/// A list of all JS Maps used for caching results, such as by [isSubtypeOf] and
/// [generic].
///
/// This is used by [hotRestart] to ensure we don't leak types from previous
/// libraries.
/// Results made against Null are cached in _nullComparisonSet and must be
/// cleared separately.
@notNull
final List<Object> _cacheMaps = JS('!', '[]');

/// A list of functions to reset static fields back to their uninitialized
/// state.
///
/// This is populated by [defineLazyField] and only contains fields that have
/// been initialized.
@notNull
final List<void Function()> resetFields = JS('', '[]');

/// A counter to track each time [hotRestart] is invoked. This is used to ensure
/// that pending callbacks that were created on a previous iteration (e.g. a
/// timer callback or a DOM callback) will not execute when they get invoked.
// TODO(sigmund): consider whether we should track and cancel callbacks to
// reduce memory leaks.
int hotRestartIteration = 0;

/// Clears out runtime state in `dartdevc` so we can hot-restart.
///
/// This should be called when the user requests a hot-restart, when the UI is
/// handling that user action.
void hotRestart() {
  // TODO(sigmund): prevent DOM callbacks from firing.
  hotRestartIteration++;
  for (var f in resetFields) f();
  resetFields.clear();
  for (var m in _cacheMaps) JS('', '#.clear()', m);
  _cacheMaps.clear();
  JS('', '#.clear()', _nullComparisonSet);
  JS('', '#.clear()', constantMaps);
  JS('', '#.clear()', deferredImports);
}

/// Marks enqueuing an async operation.
///
/// This will be called by library code when enqueuing an async operation
/// controlled by the JavaScript event handler.
///
/// It will also call [removeAsyncCallback] when Dart callback is about to be
/// executed (note this is called *before* the callback executes, so more
/// async operations could be added from that).
void Function() addAsyncCallback = JS('', 'function() {}');

/// Marks leaving a javascript async operation.
///
/// See [addAsyncCallback].
void Function() removeAsyncCallback = JS('', 'function() {}');
