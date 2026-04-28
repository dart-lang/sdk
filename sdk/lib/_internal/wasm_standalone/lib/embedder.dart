// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Imported definitions that need to be provided to run `dart2wasm` apps
/// without JavaScript.
///
/// These definitions are currently incomplete. Once all externs in the Dart SDK
/// are implemented with these imports, the `dart2wasm_standalone` target can
/// run without `js_interop`. This will enable embedders without JavaScript
/// support to run `dart2wasm` apps by either:
///
///  - providing `dart:` imports when instantiating the module.
///  - using an external tool like `wasm-merge` to link another module that
///    could provide implementations by e.g. delegating to WASI definitions.
library;

import 'dart:core';
import 'dart:core' as core;
import 'dart:_wasm';

/// Instructs the runtime to invoke `callback(arg)` after the delay in
/// microseconds.
///
/// Returns a handle that can be used with [clearSchedule] to abort the timer.
@pragma("wasm:import", "dart.scheduleOnce")
external WasmExternRef scheduleOnce(
  WasmI64 delay,
  WasmFunction<WasmVoid Function(WasmAnyRef)> callback,
  WasmAnyRef arg,
);

/// Instructs the runtime to invoke `callback(arg)` every `interval`
/// microseconds.
///
/// Returns a handle that can be used with [clearSchedule] to abort the timer.
@pragma("wasm:import", "dart.scheduleRepeated")
external WasmExternRef scheduleRepeated(
  WasmI64 interval,
  WasmFunction<WasmVoid Function(WasmAnyRef)> callback,
  WasmAnyRef arg,
);

/// Instructs the runtime to invoke `callback(arg)` before returning to the
/// event loop.
@pragma("wasm:import", "dart.queueMicrotask")
external WasmVoid queueMicrotask(
  WasmFunction<WasmVoid Function(WasmAnyRef)> callback,
  WasmAnyRef arg,
);

/// Cancels a schedule created through [scheduleOnce] or [scheduleRepeated].
@pragma("wasm:import", "dart.clearSchedule")
external WasmVoid clearSchedule(WasmExternRef? schedule);

@pragma("wasm:import", "dart.currentTime")
external WasmI64 currentTimeMicros();

/// Convert an array of 16-bit char codes into a string.
@pragma("wasm:import", "dart.stringFromCharCodeArray")
@pragma("wasm:entry-point")
external WasmExternRef stringFromCharCodeArray(
  WasmArray<WasmI16> charCodes,
  WasmI32 start,
  WasmI32 length,
);

/// Convert an array of ascii bytes into a string.
@pragma("wasm:import", "dart.stringFromAsciiBytes")
@pragma("wasm:entry-point")
external WasmExternRef stringFromAsciiBytes(
  WasmArray<WasmI8> charCodes,
  WasmI32 start,
  WasmI32 length,
);
