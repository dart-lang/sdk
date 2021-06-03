// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'shared.dart';
import 'wasmer_api.dart';

part 'runtime.g.dart';

class WasmImportDescriptor {
  int kind;
  String moduleName;
  String name;
  Pointer<WasmerFunctype> funcType;

  WasmImportDescriptor(this.kind, this.moduleName, this.name, this.funcType);

  @override
  String toString() {
    var kindName = wasmerExternKindName(kind);
    if (kind == WasmerExternKindFunction) {
      var runtime = WasmRuntime();
      var sig = WasmRuntime.getSignatureString(
        '$moduleName::$name',
        runtime.getArgTypes(funcType),
        runtime.getReturnType(funcType),
      );
      return '$kindName: $sig';
    } else {
      return '$kindName: $moduleName::$name';
    }
  }
}

class WasmExportDescriptor {
  int kind;
  String name;
  Pointer<WasmerFunctype> funcType;

  WasmExportDescriptor(this.kind, this.name, this.funcType);

  @override
  String toString() {
    var kindName = wasmerExternKindName(kind);
    if (kind == WasmerExternKindFunction) {
      var runtime = WasmRuntime();
      var sig = WasmRuntime.getSignatureString(
        name,
        runtime.getArgTypes(funcType),
        runtime.getReturnType(funcType),
      );
      return '$kindName: $sig';
    } else {
      return '$kindName: $name';
    }
  }
}

class _WasmTrapsEntry {
  Object exception;

  _WasmTrapsEntry(this.exception);
}

class _WasiStreamIterator implements Iterator<List<int>> {
  static const int _bufferLength = 1024;
  final Pointer<WasmerWasiEnv> _env;
  final Function _reader;
  final Pointer<Uint8> _buf = calloc<Uint8>(_bufferLength);
  int _length = 0;

  _WasiStreamIterator(this._env, this._reader);

  @override
  bool moveNext() {
    _length = _reader(_env, _buf, _bufferLength) as int;
    return true;
  }

  @override
  List<int> get current => _buf.asTypedList(_length);
}

class _WasiStreamIterable extends Iterable<List<int>> {
  final Pointer<WasmerWasiEnv> _env;
  final Function _reader;

  _WasiStreamIterable(this._env, this._reader);

  @override
  Iterator<List<int>> get iterator => _WasiStreamIterator(_env, _reader);
}

String _getLibName() {
  if (Platform.isMacOS) return appleLib;
  if (Platform.isLinux) return linuxLib;
  // TODO(dartbug.com/37882): Support more platforms.
  throw Exception('Wasm not currently supported on this platform');
}

String? _getLibPathFrom(Uri root) {
  final pkgRoot = packageRootUri(root);

  return pkgRoot?.resolve('$wasmToolDir${_getLibName()}').path;
}

String _getLibPath() {
  var path = _getLibPathFrom(Platform.script.resolve('./'));
  if (path != null) return path;
  path = _getLibPathFrom(Directory.current.uri);
  if (path != null) return path;
  throw Exception('Wasm library not found. Did you `$invocationString`?');
}
