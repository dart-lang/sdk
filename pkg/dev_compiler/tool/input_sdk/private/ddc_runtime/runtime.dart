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
        AssertionErrorWithMessage,
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
@JSExportName('global')
final global_ = JS(
    '',
    '''
  function () {
    if (typeof NodeList !== "undefined") {
      // TODO(vsm): Do we still need these?
      NodeList.prototype.get = function(i) { return this[i]; };
      NamedNodeMap.prototype.get = function(i) { return this[i]; };
      DOMTokenList.prototype.get = function(i) { return this[i]; };
      HTMLCollection.prototype.get = function(i) { return this[i]; };

      // Expose constructors for DOM types dart:html needs to assume are
      // available on window.
      if (typeof PannerNode == "undefined") {
        let audioContext;
        if (typeof AudioContext == "undefined" &&
            (typeof webkitAudioContext != "undefined")) {
          audioContext = new webkitAudioContext();
        } else {
          audioContext = new AudioContext();
          window.StereoPannerNode =
              audioContext.createStereoPanner().constructor;
        }
        window.PannerNode = audioContext.createPanner().constructor;
      }
      if (typeof AudioSourceNode == "undefined") {
        window.AudioSourceNode = MediaElementAudioSourceNode.__proto__;
      }
      if (typeof FontFaceSet == "undefined") {
        // CSS Font Loading is not supported on Edge.
        if (typeof document.fonts != "undefined") {
          window.FontFaceSet = document.fonts.__proto__.constructor;
        }
      }
      if (typeof MemoryInfo == "undefined") {
        if (typeof window.performance.memory != "undefined") {
          window.MemoryInfo = window.performance.memory.constructor;
        }
      }
      if (typeof Geolocation == "undefined") {
        navigator.geolocation.constructor;
      }
      if (typeof Animation == "undefined") {
        let d = document.createElement('div');
        if (typeof d.animate != "undefined") {
          window.Animation = d.animate(d).constructor;
        }
      }
      if (typeof SourceBufferList == "undefined") {
        window.SourceBufferList = new MediaSource().sourceBuffers.constructor;
      }
      if (typeof SpeechRecognition == "undefined") {
        window.SpeechRecognition = window.webkitSpeechRecognition;
        window.SpeechRecognitionError = window.webkitSpeechRecognitionError;
        window.SpeechRecognitionEvent = window.webkitSpeechRecognitionEvent;
      }
    }

    var globalState = (typeof window != "undefined") ? window
      : (typeof global != "undefined") ? global
      : (typeof self != "undefined") ? self : {};

    // These settings must be configured before the application starts so that
    // user code runs with the correct configuration.
    let settings = 'ddcSettings' in globalState ? globalState.ddcSettings : {};
    $trapRuntimeErrors(
        'trapRuntimeErrors' in settings ? settings.trapRuntimeErrors : true);
    $ignoreWhitelistedErrors(
        'ignoreWhitelistedErrors' in settings ?
            settings.ignoreWhitelistedErrors : true);

    $ignoreAllErrors(
        'ignoreAllErrors' in settings ?settings.ignoreAllErrors : false);

    $failForWeakModeIsChecks(
        'failForWeakModeIsChecks' in settings ?
            settings.failForWeakModeIsChecks : true);
    $trackProfile(
        'trackProfile' in settings ? settings.trackProfile : false);

    return globalState;
  }()
''');

final JsSymbol = JS('', 'Symbol');
