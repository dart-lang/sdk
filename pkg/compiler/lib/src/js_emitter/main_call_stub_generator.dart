// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.main_call_stub_generator;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../js_backend/backend_helpers.dart' show BackendHelpers;
import '../js_backend/js_backend.dart' show JavaScriptBackend;

import 'code_emitter_task.dart' show CodeEmitterTask;

class MainCallStubGenerator {
  final JavaScriptBackend backend;
  final CodeEmitterTask emitterTask;

  MainCallStubGenerator(this.backend, this.emitterTask);

  BackendHelpers get helpers => backend.helpers;

  /// Returns the code equivalent to:
  ///   `function(args) { $.startRootIsolate(X.main$closure(), args); }`
  jsAst.Expression _buildIsolateSetupClosure(
      FunctionEntity appMain, FunctionEntity isolateMain) {
    jsAst.Expression mainAccess =
        emitterTask.isolateStaticClosureAccess(appMain);
    // Since we pass the closurized version of the main method to
    // the isolate method, we must make sure that it exists.
    return js('function(a){ #(#, a); }',
        [emitterTask.staticFunctionAccess(isolateMain), mainAccess]);
  }

  jsAst.Statement generateInvokeMain(FunctionEntity main) {
    jsAst.Expression mainCallClosure = null;
    if (backend.backendUsage.isIsolateInUse) {
      FunctionEntity isolateMain = helpers.startRootIsolate;
      mainCallClosure = _buildIsolateSetupClosure(main, isolateMain);
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
