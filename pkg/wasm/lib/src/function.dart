// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'runtime.dart';
import 'wasmer_api.dart';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

/// WasmFunction is a callable function from a WasmInstance.
class WasmFunction {
  String _name;
  Pointer<WasmerExportFunc> _func;
  List<int> _argTypes;
  int _returnType;
  Pointer<WasmerValue> _args;
  Pointer<WasmerValue> _result;

  WasmFunction(this._name, this._func, this._argTypes, this._returnType)
      : _args = allocate<WasmerValue>(count: _argTypes.length),
        _result = allocate<WasmerValue>() {
    for (var i = 0; i < _argTypes.length; ++i) {
      _args[i].tag = _argTypes[i];
    }
  }

  bool _fillArg(dynamic arg, int i) {
    switch (_argTypes[i]) {
      case WasmerValueTagI32:
        if (arg is! int) return false;
        _args[i].i32 = arg;
        return true;
      case WasmerValueTagI64:
        if (arg is! int) return false;
        _args[i].i64 = arg;
        return true;
      case WasmerValueTagF32:
        if (arg is! num) return false;
        _args[i].f32 = arg;
        return true;
      case WasmerValueTagF64:
        if (arg is! num) return false;
        _args[i].f64 = arg;
        return true;
    }
    return false;
  }

  dynamic apply(List<dynamic> args) {
    if (args.length != _argTypes.length) {
      throw ArgumentError("Wrong number arguments for WASM function: $_name");
    }
    for (var i = 0; i < args.length; ++i) {
      if (!_fillArg(args[i], i)) {
        throw ArgumentError("Bad argument type for WASM function: $_name");
      }
    }
    WasmRuntime().call(_func, _args, _argTypes.length, _result,
        _returnType == WasmerValueTagVoid ? 0 : 1);

    if (_returnType == WasmerValueTagVoid) {
      return null;
    }
    assert(_returnType == _result.ref.tag);
    switch (_returnType) {
      case WasmerValueTagI32:
        return _result.ref.i32;
      case WasmerValueTagI64:
        return _result.ref.i64;
      case WasmerValueTagF32:
        return _result.ref.f32;
      case WasmerValueTagF64:
        return _result.ref.f64;
    }
  }

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return apply(invocation.positionalArguments);
    }
    return super.noSuchMethod(invocation);
  }
}
