// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'runtime.dart';
import 'wasm_error.dart';
import 'wasmer_api.dart';

/// A compiled module that can be instantiated.
class WasmModule {
  late final Pointer<WasmerStore> _store;
  late final Pointer<WasmerModule> _module;

  /// Compile a module.
  WasmModule(Uint8List data) {
    var runtime = WasmRuntime();
    _store = runtime.newStore(this);
    _module = runtime.compile(this, _store, data);
  }

  /// Returns a [WasmInstanceBuilder] that is used to add all the imports that
  /// the module needs before instantiating it.
  WasmInstanceBuilder builder() => WasmInstanceBuilder._(this);

  /// Create a new memory with the given number of initial pages, and optional
  /// maximum number of pages.
  WasmMemory createMemory(int pages, [int? maxPages]) =>
      WasmMemory._create(_store, pages, maxPages);

  /// Returns a description of all of the module's imports and exports, for
  /// debugging.
  String describe() {
    var description = StringBuffer();
    var runtime = WasmRuntime();
    var imports = runtime.importDescriptors(_module);
    for (var imp in imports) {
      description.write('import $imp\n');
    }
    var exports = runtime.exportDescriptors(_module);
    for (var exp in exports) {
      description.write('export $exp\n');
    }
    return description.toString();
  }
}

Pointer<WasmerTrap> _wasmFnImportTrampoline(
  Pointer<_WasmFnImport> imp,
  Pointer<WasmerValVec> args,
  Pointer<WasmerValVec> results,
) {
  try {
    _WasmFnImport._call(imp, args, results);
  } catch (exception) {
    return WasmRuntime().newTrap(imp.ref.store, exception);
  }
  return nullptr;
}

void _wasmFnImportFinalizer(Pointer<_WasmFnImport> imp) {
  _wasmFnImportToFn.remove(imp.address);
  calloc.free(imp);
}

final _wasmFnImportTrampolineNative = Pointer.fromFunction<
    Pointer<WasmerTrap> Function(
  Pointer<_WasmFnImport>,
  Pointer<WasmerValVec>,
  Pointer<WasmerValVec>,
)>(_wasmFnImportTrampoline);
final _wasmFnImportToFn = <int, Function>{};
final _wasmFnImportFinalizerNative =
    Pointer.fromFunction<Void Function(Pointer<_WasmFnImport>)>(
  _wasmFnImportFinalizer,
);

class _WasmFnImport extends Struct {
  @Int32()
  external int returnType;

  external Pointer<WasmerStore> store;

  static void _call(
    Pointer<_WasmFnImport> imp,
    Pointer<WasmerValVec> rawArgs,
    Pointer<WasmerValVec> rawResult,
  ) {
    var fn = _wasmFnImportToFn[imp.address] as Function;
    var args = [];
    for (var i = 0; i < rawArgs.ref.length; ++i) {
      args.add(rawArgs.ref.data[i].toDynamic);
    }
    assert(
      rawResult.ref.length == 1 || imp.ref.returnType == wasmerValKindVoid,
    );
    var result = Function.apply(fn, args);
    if (imp.ref.returnType != wasmerValKindVoid) {
      rawResult.ref.data[0].kind = imp.ref.returnType;
      switch (imp.ref.returnType) {
        case wasmerValKindI32:
          rawResult.ref.data[0].i32 = result as int;
          break;
        case wasmerValKindI64:
          rawResult.ref.data[0].i64 = result as int;
          break;
        case wasmerValKindF32:
          rawResult.ref.data[0].f32 = result as int;
          break;
        case wasmerValKindF64:
          rawResult.ref.data[0].f64 = result as int;
          break;
      }
    }
  }
}

/// Used to collect all of the imports that a [WasmModule] requires before it is
/// built.
class WasmInstanceBuilder {
  final _importOwner = _WasmImportOwner();
  final _importIndex = <String, int>{};
  final _imports = calloc<WasmerExternVec>();
  final WasmModule _module;
  late final List<WasmImportDescriptor> _importDescs;
  Pointer<WasmerWasiEnv> _wasiEnv = nullptr;

  WasmInstanceBuilder._(this._module)
      : _importDescs = WasmRuntime().importDescriptors(_module._module) {
    _imports.ref.length = _importDescs.length;
    _imports.ref.data = calloc<Pointer<WasmerExtern>>(_importDescs.length);
    for (var i = 0; i < _importDescs.length; ++i) {
      var imp = _importDescs[i];
      _importIndex['${imp.moduleName}::${imp.name}'] = i;
      _imports.ref.data[i] = nullptr;
    }
  }

  int _getIndex(String moduleName, String name) {
    var index = _importIndex['$moduleName::$name'];
    if (index == null) {
      throw WasmError('Import not found: $moduleName::$name');
    } else if (_imports.ref.data[index] != nullptr) {
      throw WasmError('Import already filled: $moduleName::$name');
    } else {
      return index;
    }
  }

  /// Add a WasmMemory to the imports.
  void addMemory(
    String moduleName,
    String name,
    WasmMemory memory,
  ) {
    var index = _getIndex(moduleName, name);
    var imp = _importDescs[index];
    if (imp.kind != wasmerExternKindMemory) {
      throw WasmError('Import is not a memory: $imp');
    }
    _imports.ref.data[index] = WasmRuntime().memoryToExtern(memory._mem);
  }

  /// Add a function to the imports.
  void addFunction(String moduleName, String name, Function fn) {
    var index = _getIndex(moduleName, name);
    var imp = _importDescs[index];

    if (imp.kind != wasmerExternKindFunction) {
      throw WasmError('Import is not a function: $imp');
    }

    var runtime = WasmRuntime();
    var returnType = runtime.getReturnType(imp.funcType);
    var wasmFnImport = calloc<_WasmFnImport>();
    wasmFnImport.ref.returnType = returnType;
    wasmFnImport.ref.store = _module._store;
    _wasmFnImportToFn[wasmFnImport.address] = fn;
    var fnImp = runtime.newFunc(
      _importOwner,
      _module._store,
      imp.funcType,
      _wasmFnImportTrampolineNative,
      wasmFnImport,
      _wasmFnImportFinalizerNative,
    );
    _imports.ref.data[index] = runtime.functionToExtern(fnImp);
  }

  /// Enable WASI and add the default WASI imports.
  void enableWasi({
    bool captureStdout = false,
    bool captureStderr = false,
  }) {
    if (_wasiEnv != nullptr) {
      throw WasmError('WASI is already enabled.');
    }
    var runtime = WasmRuntime();
    var config = runtime.newWasiConfig();
    if (captureStdout) runtime.captureWasiStdout(config);
    if (captureStderr) runtime.captureWasiStderr(config);
    _wasiEnv = runtime.newWasiEnv(config);
    runtime.getWasiImports(_module._store, _module._module, _wasiEnv, _imports);
  }

  /// Build the module instance.
  WasmInstance build() {
    for (var i = 0; i < _importDescs.length; ++i) {
      if (_imports.ref.data[i] == nullptr) {
        throw WasmError('Missing import: ${_importDescs[i]}');
      }
    }
    return WasmInstance._(_module, _importOwner, _imports, _wasiEnv);
  }
}

// TODO: should not be required once the min supported Dart SDK includes
//  github.com/dart-lang/sdk/commit/8fd81f72281d9d3aa5ef3890c947cc7305c56a50
class _WasmImportOwner {}

/// An instantiated [WasmModule].
///
/// Created by calling [WasmInstanceBuilder.build].
class WasmInstance {
  final _WasmImportOwner _importOwner;
  final _functions = <String, WasmFunction>{};
  final WasmModule _module;
  final Pointer<WasmerWasiEnv> _wasiEnv;

  late final Pointer<WasmerInstance> _instance;

  Pointer<WasmerMemory>? _exportedMemory;
  Stream<List<int>>? _stdout;
  Stream<List<int>>? _stderr;

  WasmInstance._(
    this._module,
    this._importOwner,
    Pointer<WasmerExternVec> imports,
    this._wasiEnv,
  ) {
    var runtime = WasmRuntime();
    _instance = runtime.instantiate(
      _importOwner,
      _module._store,
      _module._module,
      imports,
    );
    var exports = runtime.exports(_instance);
    var exportDescs = runtime.exportDescriptors(_module._module);
    assert(exports.ref.length == exportDescs.length);
    for (var i = 0; i < exports.ref.length; ++i) {
      var e = exports.ref.data[i];
      var kind = runtime.externKind(exports.ref.data[i]);
      var name = exportDescs[i].name;
      if (kind == wasmerExternKindFunction) {
        var f = runtime.externToFunction(e);
        var ft = exportDescs[i].funcType;
        _functions[name] = WasmFunction._(
          name,
          f,
          runtime.getArgTypes(ft),
          runtime.getReturnType(ft),
        );
      } else if (kind == wasmerExternKindMemory) {
        // WASM currently allows only one memory per module.
        var mem = runtime.externToMemory(e);
        _exportedMemory = mem;
        if (_wasiEnv != nullptr) {
          runtime.wasiEnvSetMemory(_wasiEnv, mem);
        }
      }
    }
  }

  /// Searches the instantiated module for the given function.
  ///
  /// Returns a [WasmFunction], but the return type is [dynamic] to allow
  /// easy invocation as a [Function].
  ///
  /// Returns `null` if no function exists with name [name].
  dynamic lookupFunction(String name) => _functions[name];

  /// Returns the memory exported from this instance.
  WasmMemory get memory {
    if (_exportedMemory == null) {
      throw WasmError('Wasm module did not export its memory.');
    }
    return WasmMemory._fromExport(_exportedMemory as Pointer<WasmerMemory>);
  }

  /// Returns a stream that reads from `stdout`.
  ///
  /// To use this, you must enable WASI when instantiating the module, and set
  /// `captureStdout` to `true`.
  Stream<List<int>> get stdout {
    if (_wasiEnv == nullptr) {
      throw WasmError("Can't capture stdout without WASI enabled.");
    }
    return _stdout ??= WasmRuntime().getWasiStdoutStream(_wasiEnv);
  }

  /// Returns a stream that reads from `stderr`.
  ///
  /// To use this, you must enable WASI when instantiating the module, and set
  /// `captureStderr` to `true`.
  Stream<List<int>> get stderr {
    if (_wasiEnv == nullptr) {
      throw WasmError("Can't capture stderr without WASI enabled.");
    }
    return _stderr ??= WasmRuntime().getWasiStderrStream(_wasiEnv);
  }
}

/// Memory of a [WasmInstance].
///
/// Access via [WasmInstance.memory] or create via [WasmModule.createMemory].
class WasmMemory {
  late final Pointer<WasmerMemory> _mem;
  late Uint8List _view;

  WasmMemory._fromExport(this._mem) {
    _view = WasmRuntime().memoryView(_mem);
  }

  /// Create a new memory with the given number of initial pages, and optional
  /// maximum number of pages.
  WasmMemory._create(Pointer<WasmerStore> store, int pages, int? maxPages) {
    _mem = WasmRuntime().newMemory(this, store, pages, maxPages);
    _view = WasmRuntime().memoryView(_mem);
  }

  /// The WASM spec defines the page size as 64KiB.
  static const int kPageSizeInBytes = 64 * 1024;

  /// The length of the memory in pages.
  int get lengthInPages => WasmRuntime().memoryLength(_mem);

  /// The length of the memory in bytes.
  int get lengthInBytes => _view.lengthInBytes;

  /// The byte at the given [index].
  int operator [](int index) => _view[index];

  /// Sets the byte at the given index to value.
  void operator []=(int index, int value) {
    _view[index] = value;
  }

  /// A view into the memory.
  Uint8List get view => _view;

  /// Grow the memory by [deltaPages] and invalidates any existing views into
  /// the memory.
  void grow(int deltaPages) {
    var runtime = WasmRuntime()..growMemory(_mem, deltaPages);
    _view = runtime.memoryView(_mem);
  }
}

/// A callable function from a [WasmInstance].
///
/// Access by calling [WasmInstance.lookupFunction].
class WasmFunction {
  final String _name;
  final Pointer<WasmerFunc> _func;
  final List<int> _argTypes;
  final int _returnType;
  final Pointer<WasmerValVec> _args = calloc<WasmerValVec>();
  final Pointer<WasmerValVec> _results = calloc<WasmerValVec>();

  WasmFunction._(this._name, this._func, this._argTypes, this._returnType) {
    _args.ref.length = _argTypes.length;
    _args.ref.data =
        _argTypes.isEmpty ? nullptr : calloc<WasmerVal>(_argTypes.length);
    _results.ref.length = _returnType == wasmerValKindVoid ? 0 : 1;
    _results.ref.data =
        _returnType == wasmerValKindVoid ? nullptr : calloc<WasmerVal>();
    for (var i = 0; i < _argTypes.length; ++i) {
      _args.ref.data[i].kind = _argTypes[i];
    }
  }

  @override
  String toString() =>
      WasmRuntime.getSignatureString(_name, _argTypes, _returnType);

  bool _fillArg(dynamic arg, int i) {
    switch (_argTypes[i]) {
      case wasmerValKindI32:
        if (arg is! int) return false;
        _args.ref.data[i].i32 = arg;
        return true;
      case wasmerValKindI64:
        if (arg is! int) return false;
        _args.ref.data[i].i64 = arg;
        return true;
      case wasmerValKindF32:
        if (arg is! num) return false;
        _args.ref.data[i].f32 = arg;
        return true;
      case wasmerValKindF64:
        if (arg is! num) return false;
        _args.ref.data[i].f64 = arg;
        return true;
    }
    return false;
  }

  dynamic apply(List<dynamic> args) {
    if (args.length != _argTypes.length) {
      throw ArgumentError('Wrong number arguments for WASM function: $this');
    }
    for (var i = 0; i < args.length; ++i) {
      if (!_fillArg(args[i], i)) {
        throw ArgumentError('Bad argument type for WASM function: $this');
      }
    }
    WasmRuntime().call(_func, _args, _results, toString());

    if (_returnType == wasmerValKindVoid) {
      return null;
    }
    var result = _results.ref.data[0];
    assert(_returnType == result.kind);
    switch (_returnType) {
      case wasmerValKindI32:
        return result.i32;
      case wasmerValKindI64:
        return result.i64;
      case wasmerValKindF32:
        return result.f32;
      case wasmerValKindF64:
        return result.f64;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return apply(invocation.positionalArguments);
    }
    return super.noSuchMethod(invocation);
  }
}
