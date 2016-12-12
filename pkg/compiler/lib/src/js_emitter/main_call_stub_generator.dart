// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter;

class MainCallStubGenerator {
  final Compiler compiler;
  final JavaScriptBackend backend;
  final CodeEmitterTask emitterTask;

  MainCallStubGenerator(this.compiler, this.backend, this.emitterTask);

  BackendHelpers get helpers => backend.helpers;

  /// Returns the code equivalent to:
  ///   `function(args) { $.startRootIsolate(X.main$closure(), args); }`
  jsAst.Expression _buildIsolateSetupClosure(
      Element appMain, Element isolateMain) {
    jsAst.Expression mainAccess =
        emitterTask.isolateStaticClosureAccess(appMain);
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    return js('function(a){ #(#, a); }',
        [emitterTask.staticFunctionAccess(isolateMain), mainAccess]);
  }

  jsAst.Statement generateInvokeMain() {
    Element main = compiler.mainFunction;
    jsAst.Expression mainCallClosure = null;
    if (backend.hasIsolateSupport) {
      Element isolateMain =
          helpers.isolateHelperLibrary.find(BackendHelpers.START_ROOT_ISOLATE);
      mainCallClosure = _buildIsolateSetupClosure(main, isolateMain);
    } else if (compiler.options.hasIncrementalSupport) {
      mainCallClosure = js(
          'function() { return #(); }', emitterTask.staticFunctionAccess(main));
    } else {
      mainCallClosure = emitterTask.staticFunctionAccess(main);
    }

    jsAst.Expression currentScriptAccess =
        emitterTask.generateEmbeddedGlobalAccess(embeddedNames.CURRENT_SCRIPT);

    // This code finds the currently executing script by listening to the
    // onload event of all script tags and getting the first script which
    // finishes. Since onload is called immediately after execution this should
    // not substantially change execution order.
    return js.statement(
        '''
      (function (callback) {
        if (typeof document === "undefined") {
          callback(null);
          return;
        }
        // When running as a content-script of a chrome-extension the
        // 'currentScript' is `null` (but not undefined).
        if (typeof document.currentScript != 'undefined') {
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

        if (typeof dartMainRunner === "function") {
          dartMainRunner(#mainCallClosure, []);
        } else {
          #mainCallClosure([]);
        }
      })''',
        {
          'currentScript': currentScriptAccess,
          'mainCallClosure': mainCallClosure
        });
  }
}
