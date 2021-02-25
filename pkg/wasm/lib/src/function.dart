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
  Pointer<WasmerFunc> _func;
  List<int> _argTypes;
  int _returnType;
  Pointer<WasmerValVec> _args = allocate<WasmerValVec>();
  Pointer<WasmerValVec> _results = allocate<WasmerValVec>();

  WasmFunction(this._name, this._func, this._argTypes, this._returnType) {
    _args.ref.length = _argTypes.length;
    _args.ref.data = _argTypes.length == 0
        ? nullptr
        : allocate<WasmerVal>(count: _argTypes.length);
    _results.ref.length = _returnType == WasmerValKindVoid ? 0 : 1;
    _results.ref.data =
        _returnType == WasmerValKindVoid ? nullptr : allocate<WasmerVal>();
    for (var i = 0; i < _argTypes.length; ++i) {
      _args.ref.data[i].kind = _argTypes[i];
    }
  }

  String toString() {
    return WasmRuntime.getSignatureString(_name, _argTypes, _returnType);
  }

  bool _fillArg(dynamic arg, int i) {
    switch (_argTypes[i]) {
      case WasmerValKindI32:
        if (arg is! int) return false;
        _args.ref.data[i].i32 = arg;
        return true;
      case WasmerValKindI64:
        if (arg is! int) return false;
        _args.ref.data[i].i64 = arg;
        return true;
      case WasmerValKindF32:
        if (arg is! num) return false;
        _args.ref.data[i].f32 = arg;
        return true;
      case WasmerValKindF64:
        if (arg is! num) return false;
        _args.ref.data[i].f64 = arg;
        return true;
    }
    return false;
  }

  dynamic apply(List<dynamic> args) {
    if (args.length != _argTypes.length) {
      throw ArgumentError("Wrong number arguments for WASM function: $this");
    }
    for (var i = 0; i < args.length; ++i) {
      if (!_fillArg(args[i], i)) {
        throw ArgumentError("Bad argument type for WASM function: $this");
      }
    }
    WasmRuntime().call(_func, _args, _results, toString());

    if (_returnType == WasmerValKindVoid) {
      return null;
    }
    var result = _results.ref.data[0];
    assert(_returnType == result.kind);
    switch (_returnType) {
      case WasmerValKindI32:
        return result.i32;
      case WasmerValKindI64:
        return result.i64;
      case WasmerValKindF32:
        return result.f32;
      case WasmerValKindF64:
        return result.f64;
    }
  }

  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #call) {
      return apply(invocation.positionalArguments);
    }
    return super.noSuchMethod(invocation);
  }
}
