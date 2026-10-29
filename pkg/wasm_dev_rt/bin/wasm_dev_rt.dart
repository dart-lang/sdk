// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The Wasm dev runtime app. Modules from the dev compiler import its exports
// as `wasm_dev_rt`.

import 'dart:_js_interop_wasm';
import 'dart:_wasm';
import 'dart:js_interop';

import 'package:wasm_dev_rt/wasm_dev_rt.dart' as rt;

void main() {}

@pragma('wasm:export', 'print')
WasmVoid printMessage(WasmExternRef message) {
  print((message.toJS as JSString).toDart);
  return WasmVoid();
}

@pragma('wasm:export', 'staticId')
WasmI32 staticId(WasmExternRef label) =>
    WasmI32.fromInt(rt.staticId((label.toJS as JSString).toDart));

@pragma('wasm:export', 'defineStatic')
WasmVoid defineStatic(WasmI32 id, WasmFuncRef function) {
  rt.defineStatic(id.toIntSigned(), function);
  return WasmVoid();
}

@pragma('wasm:export', 'lookupStatic')
WasmFuncRef lookupStatic(WasmI32 id) => rt.lookupStatic(id.toIntSigned());

@pragma('wasm:export', 'classId')
WasmI32 classId(WasmExternRef label) =>
    WasmI32.fromInt(rt.classId((label.toJS as JSString).toDart));

@pragma('wasm:export', 'defineClassSupers')
WasmVoid defineClassSupers(WasmI32 id, WasmI32 superclassId) {
  rt.defineClassSupers(id.toIntSigned(), superclassId.toIntSigned());
  return WasmVoid();
}

@pragma('wasm:export', 'instanceMemberId')
WasmI32 instanceMemberId(WasmExternRef name) =>
    WasmI32.fromInt(rt.instanceMemberId((name.toJS as JSString).toDart));

@pragma('wasm:export', 'startInstanceMemberDefinitions')
WasmVoid startInstanceMemberDefinitions(WasmI32 classId) {
  rt.startInstanceMemberDefinitions(classId.toIntSigned());
  return WasmVoid();
}

@pragma('wasm:export', 'defineInstanceMember')
WasmVoid defineInstanceMember(
  WasmI32 classId,
  WasmI32 instanceMemberId,
  WasmFuncRef function,
) {
  rt.defineInstanceMember(
    classId.toIntSigned(),
    instanceMemberId.toIntSigned(),
    function,
  );
  return WasmVoid();
}

@pragma('wasm:export', 'endInstanceMemberDefinitions')
WasmVoid endInstanceMemberDefinitions(WasmI32 classId) {
  rt.endInstanceMemberDefinitions(classId.toIntSigned());
  return WasmVoid();
}

@pragma('wasm:export', 'findTarget')
WasmFuncRef findTarget(WasmI32 classId, WasmI32 instanceMemberId) =>
    rt.findTarget(classId.toIntSigned(), instanceMemberId.toIntSigned());
