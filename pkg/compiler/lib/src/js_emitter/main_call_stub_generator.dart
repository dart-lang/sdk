// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library;

import 'package:compiler/src/options.dart';
import 'package:js_runtime/synced/embedded_names.dart' as embedded_names;

import '../common/elements.dart';
import '../elements/entities.dart';
import '../js/js.dart' as js_ast;
import '../js/js.dart' show js;

import 'js_emitter.dart' show Emitter;

class MainCallStubGenerator {
  static js_ast.Statement generateInvokeMain(
      CommonElements commonElements,
      Emitter emitter,
      FunctionEntity main,
      bool requiresStartupMetrics,
      CompilerOptions options) {
    js_ast.Expression mainAccess = emitter.staticFunctionAccess(main);
    js_ast.Expression currentScriptAccess =
        emitter.generateEmbeddedGlobalAccess(embedded_names.CURRENT_SCRIPT);

    // TODO(https://github.com/dart-lang/language/issues/1120#issuecomment-670802088):
    // Validate constraints on `main()` in resolution for dart2js, and in DDC.

    final parameterStructure = main.parameterStructure;

    // The forwarding stub passes all arguments, i.e. both required and optional
    // positional arguments. We ignore named arguments, assuming the `main()`
    // has been validated earlier.
    int positionalParameters = parameterStructure.positionalParameters;

    js_ast.Expression mainCallClosure;
    if (positionalParameters == 0) {
      if (parameterStructure.namedParameters.isEmpty) {
        // e.g. `void main()`.
        // No parameters. The compiled Dart `main` has no parameters and will
        // ignore any extra parameters passed in, so it can be used directly.
        mainCallClosure = mainAccess;
      } else {
        // e.g. `void main({arg})`.  We should not get here. Drop the named
        // arguments as we don't know how to convert them.
        mainCallClosure = js(r'''function() { return #(); }''', mainAccess);
      }
    } else {
      js_ast.Expression convertArgumentList =
          emitter.staticFunctionAccess(commonElements.convertMainArgumentList);
      if (positionalParameters == 1) {
        // e.g. `void main(List<String> args)`,  `main([args])`.
        mainCallClosure = js(
          r'''function(args) { return #(#(args)); }''',
          [mainAccess, convertArgumentList],
        );
      } else {
        // positionalParameters == 2.
        // e.g. `void main(List<String> args, Object? extra)`
        mainCallClosure = js(
          r'''function(args, extra) { return #(#(args), extra); }''',
          [mainAccess, convertArgumentList],
        );
      }
    }

    // This code finds the currently executing script by listening to the
    // onload event of all script tags and getting the first script which
    // finishes. Since onload is called immediately after execution this should
    // not substantially change execution order.
    return js.statement('''
      (function (callback) {
        if (typeof document === "undefined") {
          callback(null);
          return;
        }
        // When running as a content-script of a chrome-extension the
        // 'currentScript' is `null` (but not undefined).
        if (typeof document.currentScript != "undefined") {
          callback(document.currentScript);
          return;
        }

        var scripts = document.scripts;
        function onLoad(event) {
          for (var i = 0; i < scripts.length; ++i) {
            scripts[i].removeEventListener("load", onLoad, false);
          }
          callback(event.target);
        }
        for (var i = 0; i < scripts.length; ++i) {
          scripts[i].addEventListener("load", onLoad, false);
        }
      })(function(currentScript) {
        #currentScript = currentScript;

        if (#startupMetrics) {
          init.#startupMetricsEmbeddedGlobal.add('callMainMs');
        }
        if (#isCollectingRuntimeMetrics) {
          self.#runtimeMetricsContainer = self.#runtimeMetricsContainer || Object.create(null);
          self.#runtimeMetricsContainer[currentScript.src] = init.#runtimeMetricsEmbeddedGlobal;
        }
        var callMain = #mainCallClosure;
        if (typeof dartMainRunner === "function") {
          dartMainRunner(callMain, []);
        } else {
          callMain([]);
        }
      })''', {
      'currentScript': currentScriptAccess,
      'mainCallClosure': mainCallClosure,
      'isCollectingRuntimeMetrics': options.experimentalTrackAllocations,
      'runtimeMetricsContainer': embedded_names.RUNTIME_METRICS_CONTAINER,
      'runtimeMetricsEmbeddedGlobal': embedded_names.RUNTIME_METRICS,
      'startupMetrics': requiresStartupMetrics,
      'startupMetricsEmbeddedGlobal': embedded_names.STARTUP_METRICS,
    });
  }
}
