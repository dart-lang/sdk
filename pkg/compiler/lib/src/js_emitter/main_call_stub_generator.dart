// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_emitter.main_call_stub_generator;

import 'package:js_runtime/shared/embedded_names.dart' as embeddedNames;

import '../elements/entities.dart';
import '../js/js.dart' as jsAst;
import '../js/js.dart' show js;
import '../common_elements.dart';

import 'code_emitter_task.dart' show Emitter;

class MainCallStubGenerator {
  static jsAst.Statement generateInvokeMain(
      CommonElements commonElements, Emitter emitter, FunctionEntity main) {
    jsAst.Expression mainAccess = emitter.staticFunctionAccess(main);
    jsAst.Expression currentScriptAccess =
        emitter.generateEmbeddedGlobalAccess(embeddedNames.CURRENT_SCRIPT);

    // TODO(https://github.com/dart-lang/language/issues/1120#issuecomment-670802088):
    // Validate constraints on `main()` in resolution for dart2js, and in DDC.

    final parameterStructure = main.parameterStructure;

    // The forwarding stub passes all arguments, i.e. both required and optional
    // positional arguments. We ignore named arguments, assuming the `main()`
    // has been validated earlier.
    int positionalParameters = parameterStructure.positionalParameters;

    jsAst.Expression mainCallClosure;
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
      jsAst.Expression convertArgumentList =
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
        var callMain = #mainCallClosure;
        if (typeof dartMainRunner === "function") {
          dartMainRunner(callMain, []);
        } else {
          callMain([]);
        }
      })''', {
      'currentScript': currentScriptAccess,
      'mainCallClosure': mainCallClosure
    });
  }
}
