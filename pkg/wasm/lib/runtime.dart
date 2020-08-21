// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as path;

const int WasmerResultOk = 1;
const int WasmerResultError = 2;

const int WasmerValueTagI32 = 0;
const int WasmerValueTagI64 = 1;
const int WasmerValueTagF32 = 2;
const int WasmerValueTagF64 = 3;

class WasmerModule extends Struct {}

typedef NativeWasmerCompileFn = Uint32 Function(
    Pointer<Pointer<WasmerModule>>, Pointer<Uint8>, Uint32);
typedef WasmerCompileFn = int Function(
    Pointer<Pointer<WasmerModule>>, Pointer<Uint8>, int);

class WasmRuntime {
  static WasmRuntime _inst;

  DynamicLibrary _lib;
  WasmerCompileFn _compile;

  factory WasmRuntime() {
    if (_inst == null) {
      _inst = WasmRuntime._init();
    }
    return _inst;
  }

  static String _getLibName() {
    if (Platform.isMacOS) return "libwasmer.dylib";
    if (Platform.isLinux) return "libwasmer.so";
    throw Exception("Wasm not currently supported on this platform");
  }

  static String _getLibDir() {
    // The common case, and how cli_util.dart computes the Dart SDK directory,
    // path.dirname called twice on Platform.resolvedExecutable.
    var commonLibDir = path.join(
        path.absolute(path.dirname(path.dirname(Platform.resolvedExecutable))),
        'bin',
        'third_party',
        'wasmer');
    if (Directory(commonLibDir).existsSync()) {
      return commonLibDir;
    }

    // This is the less common case where the user is in the checked out Dart
    // SDK, and is executing dart via:
    // ./out/ReleaseX64/dart ...
    var checkedOutLibDir = path.join(
        path.absolute(path.dirname(Platform.resolvedExecutable)),
        'dart-sdk',
        'bin',
        'third_party',
        'wasmer');
    if (Directory(checkedOutLibDir).existsSync()) {
      return checkedOutLibDir;
    }

    // If neither returned above, we return the common case:
    return commonLibDir;
  }

  WasmRuntime._init() {
    var libPath = path.join(_getLibDir(), _getLibName());
    _lib = DynamicLibrary.open(libPath);
    _compile = _lib
        .lookup<NativeFunction<NativeWasmerCompileFn>>('wasmer_compile')
        .asFunction();
  }

  Pointer<WasmerModule> compile(Uint8List data) {
    var dataPtr = allocate<Uint8>(count: data.length);
    for (int i = 0; i < data.length; ++i) {
      dataPtr[i] = data[i];
    }

    var modulePtrPtr = allocate<Pointer<WasmerModule>>();
    int result = _compile(modulePtrPtr, dataPtr, data.length);
    Pointer<WasmerModule> modulePtr = modulePtrPtr.value;

    free(modulePtrPtr);
    free(dataPtr);

    if (result != WasmerResultOk) {
      throw Exception("Wasm module compile failed");
    }

    return modulePtr;
  }
}
