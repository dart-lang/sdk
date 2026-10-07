// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
final nonEs6MjsTemplate = Template(r'''(function() {
const exportObject = {};

// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
exportObject.compileStreaming = <<COMPILE_STREAMING>>;

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
exportObject.compile = <<COMPILE>>;

<<REST>>

return exportObject;
})''');

final es6MjsTemplate = Template(
  r'''// Compiles a dart2wasm-generated main module from `source` which can then
// be instantiated via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export <<COMPILE_STREAMING>>

// Compiles a dart2wasm-generated wasm module from `bytes` which is then
// instantiable via the `instantiate` method.
export <<COMPILE>>

<<REST>>''',
);

final compileStreamingTemplate = Template(
  r'''async function compileStreaming(source) {
  const builtins = {<<BUILTINS_MAP_BODY>>};
  return new CompiledApp(
      await _compileStreaming(source, builtins), builtins);
}''',
);

final compileTemplate = Template(r'''async function compile(bytes) {
  const builtins = {<<BUILTINS_MAP_BODY>>};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}''');

/// Helper that delegates to `WebAssembly.compileStreaming` when `compileOptions`
/// (`{builtins: ['js-string']}`) is supported, and falls back to
/// `WebAssembly.compile` otherwise (working around Safari <= 26.5 streaming
/// bugs: https://bugs.webkit.org/show_bug.cgi?id=308136 and
/// https://bugs.webkit.org/show_bug.cgi?id=318710).
const String compileStreamingHelper = r'''
let _isCompileStreamingSupported;
async function _compileStreaming(source, builtins) {
  _isCompileStreamingSupported ??= WebAssembly.compileStreaming(
    new Response(
      new Uint8Array([0,97,115,109,1,0,0,0,1,4,1,96,0,0,2,23,1,14,119,97,115,109,58,106,115,45,115,116,114,105,110,103,4,99,97,115,116,0,0]),
      {headers: {'Content-Type': 'application/wasm'}},
    ),
    builtins,
  ).then(() => false, (e) => e instanceof WebAssembly.CompileError);
  if (await _isCompileStreamingSupported) {
    return WebAssembly.compileStreaming(source, builtins);
  }
  return WebAssembly.compile(await (await source).arrayBuffer(), builtins);
}''';

final jsRuntimeBlobTemplate = Template(r'''
<<COMPILE_STREAMING_HELPER>>

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arguments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `use-load-ids` option is passed. Each load ID maps to
  //   one or more wasm files as specified in the emitted JSON file. It also
  //   takes a callback that should be invoked for each loaded module with 2
  //   arguments: (1) the module name, (2) the loaded module in a format
  //   supported by `WebAssembly.compile` or `WebAssembly.compileStreaming`.
  //   The callback returns a Promise that resolves when the module is
  //   instantiated.
  //   loadDeferredId should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports, {loadDeferredModules, loadDeferredId} = {}) {
    let dartInstance;

    // Prints to the console
    function printToConsole(value) {
      if (typeof dartPrint == "function") {
        dartPrint(value);
        return;
      }
      if (typeof console == "object" && typeof console.log != "undefined") {
        console.log(value);
        return;
      }
      if (typeof print == "function") {
        print(value);
        return;
      }

      throw "Unable to print message: " + value;
    }

    // A special symbol attached to functions that wrap Dart functions.
    const jsWrappedDartFunctionSymbol = Symbol("JSWrappedDartFunction");

    function finalizeWrapper(dartFunction, wrapped) {
      wrapped.dartFunction = dartFunction;
      wrapped[jsWrappedDartFunctionSymbol] = true;
      return wrapped;
    }

    // Imports
    const dart2wasm = {
      <<JS_METHODS>>
    };

    const baseImports = {
      <<INTERNAL_IMPORTS_MODULE_NAME>>: dart2wasm,
      Math: Math,
      Date: Date,
      Object: Object,
      Array: Array,
      Reflect: Reflect,
      WebAssembly: {
        JSTag: WebAssembly.JSTag,
      },
      <<IMPORTED_JS_STRINGS_IN_MJS>>
    };

    <<DEFERRED_LIBRARY_HELPER_METHODS>>

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      <<MODULE_LOADING_IMPORT>>
    });

    return new InstantiatedApp(this, dartInstance);
  }
}

class InstantiatedApp {
  constructor(compiledApp, instantiatedModule) {
    this.compiledApp = compiledApp;
    this.instantiatedModule = instantiatedModule;
  }

  // Call the main function with the given arguments.
  invokeMain(...args) {
    this.instantiatedModule.exports.$invokeMain(args);
  }
}
''');

final moduleLoadingHelperTemplate = Template(r'''
    async function handleDeferredModuleBytes(moduleName, source) {
      const builtins = this.builtins;
      source = await source;
      const module = await ((typeof Response != 'undefined' && source instanceof Response)
          ? _compileStreaming(source, builtins)
          : WebAssembly.compile(source, builtins));
      let moduleInstance = await WebAssembly.instantiate(module, {
        ...baseImports,
        ...additionalImports,
        "<<MAIN_MODULE_NAME>>": dartInstance.exports,
      });
    }
    const moduleLoadingHelper = {
      "loadDeferredModules": async (moduleNames) => {
        if (!loadDeferredModules) {
          throw "No implementation of loadDeferredModules provided.";
        }
        await loadDeferredModules(moduleNames, handleDeferredModuleBytes.bind(this));
      },
      "loadDeferredId": async (loadId) => {
        if (!loadDeferredId) {
          throw "No implementation of loadDeferredId provided.";
        }
        await loadDeferredId(loadId, handleDeferredModuleBytes.bind(this));
      },
    };
''');

class Template {
  static final _templateVariableRegExp = RegExp(r'<<(?<varname>[A-Z_]+)>>');
  final List<_TemplatePart> _parts = [];

  Template(String stringTemplate) {
    int offset = 0;
    for (final match in _templateVariableRegExp.allMatches(stringTemplate)) {
      _parts.add(
        _TemplateStringPart(stringTemplate.substring(offset, match.start)),
      );
      _parts.add(_TemplateVariablePart(match.namedGroup('varname')!));
      offset = match.end;
    }
    _parts.add(
      _TemplateStringPart(
        stringTemplate.substring(offset, stringTemplate.length),
      ),
    );
  }

  String instantiate(Map<String, String> variableValues) {
    final sb = StringBuffer();
    for (final part in _parts) {
      sb.write(part.instantiate(variableValues));
    }
    return sb.toString();
  }
}

abstract class _TemplatePart {
  String instantiate(Map<String, String> variableValues);
}

class _TemplateStringPart extends _TemplatePart {
  final String string;
  _TemplateStringPart(this.string);

  @override
  String instantiate(Map<String, String> variableValues) => string;
}

class _TemplateVariablePart extends _TemplatePart {
  final String variable;
  _TemplateVariablePart(this.variable);

  @override
  String instantiate(Map<String, String> variableValues) {
    final value = variableValues[variable];
    if (value != null) return value;
    throw 'Template contains no value for variable $variable';
  }
}
