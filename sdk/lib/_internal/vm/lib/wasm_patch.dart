// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import "dart:nativewrappers" show NativeFieldWrapperClass1;
import 'dart:typed_data';

@patch
@pragma("vm:entry-point")
class Int32 {}

@patch
@pragma("vm:entry-point")
class Int64 {}

@patch
@pragma("vm:entry-point")
class Float {}

@patch
@pragma("vm:entry-point")
class Double {}

@patch
@pragma("vm:entry-point")
class Void {}

@patch
class WasmModule {
  @patch
  factory WasmModule(Uint8List data) {
    return _NativeWasmModule(data);
  }
}

@patch
class WasmMemory {
  @patch
  factory WasmMemory(int initialPages, [int? maxPages]) {
    return _NativeWasmMemory(initialPages, maxPages);
  }
}

@patch
class WasmImports {
  @patch
  factory WasmImports() {
    return _NativeWasmImports();
  }
}

class _NativeWasmModule extends NativeFieldWrapperClass1 implements WasmModule {
  _NativeWasmModule(Uint8List data) {
    _init(data);
  }

  WasmInstance instantiate(covariant _NativeWasmImports imports) {
    return _NativeWasmInstance(this, imports);
  }

  void _init(Uint8List data) native 'Wasm_initModule';
  String describe() native 'Wasm_describeModule';
}

class _NativeWasmImports extends NativeFieldWrapperClass1
    implements WasmImports {
  List<WasmMemory> _memories;
  List<Function> _fns;

  _NativeWasmImports()
      : _memories = [],
        _fns = [] {
    _init();
  }

  void addMemory(String moduleName, String name, WasmMemory memory) {
    _memories.add(memory);
    _addMemory(moduleName, name, memory);
  }

  void addGlobal<T>(String moduleName, String name, num value, bool mutable) {
    _addGlobal(moduleName, name, value, T, mutable);
  }

  void addFunction<T extends Function>(
      String moduleName, String name, Function fn) {
    int id = _fns.length;
    _fns.add(fn);
    _addFunction(moduleName, name, id, T);
  }

  @pragma("vm:entry-point")
  static Function getFunction(_NativeWasmImports imp, int id) {
    return imp._fns[id];
  }

  void _init() native 'Wasm_initImports';
  void _addMemory(String moduleName, String name, WasmMemory memory)
      native 'Wasm_addMemoryImport';
  void _addGlobal(String moduleName, String name, num value, Type type,
      bool mutable) native 'Wasm_addGlobalImport';
  void _addFunction(String moduleName, String name, int id, Type type)
      native 'Wasm_addFunctionImport';
}

class _NativeWasmMemory extends NativeFieldWrapperClass1 implements WasmMemory {
  late int _pages;
  late Uint8List _buffer;

  _NativeWasmMemory(int initialPages, int? maxPages) {
    _buffer = _init(initialPages, maxPages);
    _pages = initialPages;
  }

  _NativeWasmMemory.fromInstance(_NativeWasmInstance inst) {
    _buffer = _initFromInstance(inst);
    _pages = _getPages();
  }

  int get lengthInPages => _pages;
  int get lengthInBytes => _buffer.lengthInBytes;
  int operator [](int index) => _buffer[index];
  void operator []=(int index, int value) {
    _buffer[index] = value;
  }

  int grow(int deltaPages) {
    int oldPages = _pages;
    _buffer = _grow(deltaPages);
    _pages += deltaPages;
    return oldPages;
  }

  Uint8List _init(int initialPages, int? maxPages) native 'Wasm_initMemory';
  Uint8List _grow(int deltaPages) native 'Wasm_growMemory';
  Uint8List _initFromInstance(_NativeWasmInstance inst)
      native 'Wasm_initMemoryFromInstance';
  int _getPages() native 'Wasm_getMemoryPages';
}

class _NativeWasmInstance extends NativeFieldWrapperClass1
    implements WasmInstance {
  _NativeWasmModule _module;
  _NativeWasmImports _imports;

  _NativeWasmInstance(_NativeWasmModule module, _NativeWasmImports imports)
      : _module = module,
        _imports = imports {
    _init(module, imports);
  }

  WasmFunction<T> lookupFunction<T extends Function>(String name) {
    return _NativeWasmFunction<T>(this, name);
  }

  WasmMemory get memory {
    return _NativeWasmMemory.fromInstance(this);
  }

  void _init(_NativeWasmModule module, _NativeWasmImports imports)
      native 'Wasm_initInstance';
}

class _NativeWasmFunction<T extends Function> extends NativeFieldWrapperClass1
    implements WasmFunction<T> {
  _NativeWasmInstance _inst;

  _NativeWasmFunction(_NativeWasmInstance inst, String name) : _inst = inst {
    _init(inst, name, T);
  }

  num call(List<num> args) {
    var arg_copy = List<num>.from(args, growable: false);
    return _call(arg_copy);
  }

  void _init(_NativeWasmInstance inst, String name, Type fnType)
      native 'Wasm_initFunction';
  num _call(List<num> args) native 'Wasm_callFunction';
}
