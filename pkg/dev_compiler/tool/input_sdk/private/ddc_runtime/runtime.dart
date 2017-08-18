// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._runtime;

import 'dart:async';
import 'dart:collection';

import 'dart:_debugger' show stackTraceMapper;
import 'dart:_foreign_helper' show JS, JSExportName, rest, spread;
import 'dart:_interceptors' show JSArray;
import 'dart:_js_helper'
    show
        AssertionErrorImpl,
        BooleanConversionAssertionError,
        CastErrorImplementation,
        getTraceFromException,
        Primitives,
        TypeErrorImplementation,
        StrongModeCastError,
        StrongModeErrorImplementation,
        StrongModeTypeError,
        SyncIterable;
import 'dart:_internal' as _internal;

part 'classes.dart';
part 'rtti.dart';
part 'types.dart';
part 'errors.dart';
part 'generators.dart';
part 'operations.dart';
part 'profile.dart';
part 'utils.dart';

// TODO(vsm): Move polyfill code to dart:html.
// Note, native extensions are registered onto types in dart.global.
// This polyfill needs to run before the corresponding dart:html code is run.
final _polyfilled = JS('', 'Symbol("_polyfilled")');

bool polyfill(window) => JS(
    '',
    '''(() => {
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
        $window.MemoryInfo = $window.performance.memory.constructor;
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
      $window.SourceBufferList =
        new $window.MediaSource().sourceBuffers.constructor;
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
final global_ = JS(
    '',
    '''
  function () {
    // Find global object.
    var globalState = (typeof window != "undefined") ? window
      : (typeof global != "undefined") ? global
      : (typeof self != "undefined") ? self : {};

    $polyfill(globalState);

    // These settings must be configured before the application starts so that
    // user code runs with the correct configuration.
    let settings = 'ddcSettings' in globalState ? globalState.ddcSettings : {};
    $trapRuntimeErrors(
        'trapRuntimeErrors' in settings ? settings.trapRuntimeErrors : true);
    $ignoreWhitelistedErrors(
        'ignoreWhitelistedErrors' in settings ?
            settings.ignoreWhitelistedErrors : true);

    $ignoreAllErrors(
        'ignoreAllErrors' in settings ? settings.ignoreAllErrors : false);

    $trackProfile(
        'trackProfile' in settings ? settings.trackProfile : false);

    return globalState;
  }()
''');

final JsSymbol = JS('', 'Symbol');
