// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final jsRuntimeBlobTemplate = Template(r'''
// Compiles a dart2wasm-generated main module from `source` which can then
// instantiatable via the `instantiate` method.
//
// `source` needs to be a `Response` object (or promise thereof) e.g. created
// via the `fetch()` JS API.
export async function compileStreaming(source) {
  const builtins = {<<BUILTINS_MAP_BODY>>};
  return new CompiledApp(
      await WebAssembly.compileStreaming(source, builtins), builtins);
}

// Compiles a dart2wasm-generated wasm modules from `bytes` which is then
// instantiatable via the `instantiate` method.
export async function compile(bytes) {
  const builtins = {<<BUILTINS_MAP_BODY>>};
  return new CompiledApp(await WebAssembly.compile(bytes, builtins), builtins);
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export async function instantiate(modulePromise, importObjectPromise) {
  var moduleOrCompiledApp = await modulePromise;
  if (!(moduleOrCompiledApp instanceof CompiledApp)) {
    moduleOrCompiledApp = new CompiledApp(moduleOrCompiledApp);
  }
  const instantiatedApp = await moduleOrCompiledApp.instantiate(await importObjectPromise);
  return instantiatedApp.instantiatedModule;
}

// DEPRECATED: Please use `compile` or `compileStreaming` to get a compiled app,
// use `instantiate` method to get an instantiated app and then call
// `invokeMain` to invoke the main function.
export const invoke = (moduleInstance, ...args) => {
  moduleInstance.exports.$invokeMain(args);
}

class CompiledApp {
  constructor(module, builtins) {
    this.module = module;
    this.builtins = builtins;
  }

  // The second argument is an options object containing:
  // `loadDeferredModules` is a JS function that takes an array of module names
  //   matching wasm files produced by the dart2wasm compiler. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDeferredId` is a JS function that takes load ID produced by the
  //   compiler when the `load-ids` option is passed. Each load ID maps to one
  //   or more wasm files as specified in the emitted JSON file. It also takes a
  //   callback that should be invoked for each loaded module with 2 arugments:
  //   (1) the module name, (2) the loaded module in a format supported by
  //   `WebAssembly.compile` or `WebAssembly.compileStreaming`. The callback
  //   returns a Promise that resolves when the module is instantiated.
  //   loadDeferredModules should return a Promise that resolves when all the
  //   modules have been loaded and the callback promises have resolved.
  // `loadDynamicModule` is a JS function that takes two string names matching,
  //   in order, a wasm file produced by the dart2wasm compiler during dynamic
  //   module compilation and a corresponding js file produced by the same
  //   compilation. It also takes a callback that should be invoked with the
  //   loaded module in a format supported by `WebAssembly.compile` or
  //   `WebAssembly.compileStreaming` and the result of using the JS 'import'
  //   API on the js file path. It should return a Promise that resolves when
  //   all the modules have been loaded and the callback promises have resolved.
  async instantiate(additionalImports,
      {loadDeferredModules, loadDynamicModule, loadDeferredId} = {}) {
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
      dart2wasm: dart2wasm,
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

    <<JS_STRING_POLYFILL_METHODS>>

    <<DEFERRED_LIBRARY_HELPER_METHODS>>

    dartInstance = await WebAssembly.instantiate(this.module, {
      ...baseImports,
      ...additionalImports,
      <<MODULE_LOADING_IMPORT>>
      <<JS_POLYFILL_IMPORT>>
    });
    dartInstance.exports.$setThisModule(dartInstance);

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

const String jsPolyFillMethods = r'''
const jsStringPolyfill = {
      "charCodeAt": (s, i) => s.charCodeAt(i),
      "compare": (s1, s2) => {
        if (s1 < s2) return -1;
        if (s1 > s2) return 1;
        return 0;
      },
      "concat": (s1, s2) => s1 + s2,
      "equals": (s1, s2) => s1 === s2,
      "fromCharCode": (i) => String.fromCharCode(i),
      "length": (s) => s.length,
      "substring": (s, a, b) => s.substring(a, b),
      "fromCharCodeArray": (a, start, end) => {
        if (end <= start) return '';

        const read = dartInstance.exports.$wasmI16ArrayGet;
        let result = '';
        let index = start;
        const chunkLength = Math.min(end - index, 500);
        let array = new Array(chunkLength);
        while (index < end) {
          const newChunkLength = Math.min(end - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(a, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      },
      "intoCharCodeArray": (s, a, start) => {
        if (s === '') return 0;

        const write = dartInstance.exports.$wasmI16ArraySet;
        for (var i = 0; i < s.length; ++i) {
          write(a, start++, s.charCodeAt(i));
        }
        return s.length;
      },
      "test": (s) => typeof s == "string",
    };
''';

final moduleLoadingHelperTemplate = Template(r'''
    async function handleDeferredModuleBytes(moduleName, source) {
      const builtins = this.builtins;
      const module = await ((source instanceof Response)
          ? WebAssembly.compileStreaming(source, builtins)
          : WebAssembly.compile(source, builtins));
      let moduleInstance = await WebAssembly.instantiate(module, {
        ...baseImports,
        ...additionalImports,
        <<JS_POLYFILL_IMPORT>>
        "<<MAIN_MODULE_NAME>>": dartInstance.exports,
      });
      moduleInstance.exports.$setThisModule(moduleInstance);
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
      "loadDynamicModuleFromUri": async (wasmUri, jsUri) => {
        if (!loadDynamicModule) {
          throw "No implementation of loadDynamicModule provided.";
        }
        let moduleInstance;
        async function handleDynamicModuleBytes(source, jsModule) {
          const builtins = this.builtins;
          const module = await ((source instanceof Response)
              ? WebAssembly.compileStreaming(source, builtins)
              : WebAssembly.compile(source, builtins));
          moduleInstance = await WebAssembly.instantiate(module, {
            "<<MAIN_MODULE_NAME>>": dartInstance.exports,
            ...jsModule.imports(finalizeWrapper),
          });
          moduleInstance.exports.$setThisModule(moduleInstance);
        }
        await loadDynamicModule(wasmUri, jsUri, handleDynamicModuleBytes.bind(this));
        return moduleInstance.exports.$invokeEntryPoint;
      },
    };
''');

final dynamicSubmoduleJsImportTemplate = Template(r'''
export function imports(finalizeWrapper) {
  const dart2wasm = {
    <<JS_METHODS>>
  };

  return {
    dart2wasm: dart2wasm,
    <<IMPORTED_JS_STRINGS_IN_MJS>>
  };
}
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
