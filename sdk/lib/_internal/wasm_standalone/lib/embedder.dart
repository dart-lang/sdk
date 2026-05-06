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

/// Get the frequency of ticks reported by [monotonicClockTicks] in Hz.
///
/// Currently, the only supported values are 1kHz and 1MHz. Attempting to use
/// a stopwatch in Dart will fail if the function returns an unsupported value.
///
/// This function must return the same value every time it is called.
@pragma("wasm:import", "dart.monotonicClockFrequency")
external WasmI32 monotonicClockFrequency();

/// An integer incrementing with [monotonicClockFrequency].
@pragma("wasm:import", "dart.monotonicClockTicks")
external WasmI64 monotonicClockTicks();

/// Creates a weak reference wrapping [originalValue].
///
/// The SDK verifies that [originalValue] is a valid target (not a number,
/// boolean, string, record or FFI type) before calling this.
@pragma("wasm:import", "dart.weakRefCreate")
external WasmExternRef weakRefCreate(WasmAnyRef originalValue);

/// Returns the value wrapped in [weakRefCreate], or null.
@pragma("wasm:import", "dart.weakRefGet")
external WasmAnyRef? weakRefGet(WasmExternRef? weakReference);

/// Creates a new [Expando].
@pragma("wasm:import", "dart.expandoCreate")
external WasmExternRef expandoCreate();

/// Lookup a value stored on [target] with [expandoSet].
///
/// The SDK verifies that [target] is a valid target before calling this.
@pragma("wasm:import", "dart.expandoGet")
external WasmAnyRef? expandoGet(
  WasmExternRef? expando,
  WasmAnyRef target,
  WasmI64 targetIdentityHashCode,
);

/// Associates the [value] with the [target] object in the expando.
///
/// The SDK verifies that [target] is a valid target before calling this.
@pragma("wasm:import", "dart.expandoSet")
external WasmVoid expandoSet(
  WasmExternRef? expando,
  WasmAnyRef target,
  WasmI64 targetIdentityHashCode,
  WasmAnyRef? value,
);

/// Creates a native finalizer that may invoke the [callback] with the
/// [firstParameter] and a second token when a registered object becomes
/// unreachable.
@pragma("wasm:import", "dart.finalizerCreate")
external WasmExternRef finalizerCreate(
  WasmFunction<WasmVoid Function(WasmAnyRef, WasmAnyRef?)> callback,
  WasmAnyRef firstParameter,
);

/// Attaches an object to a finalizer.
///
/// After [object] becomes unreachable, the `callback` passed to
/// [finalizerCreate] may be invoked with [token] as a second parameter.
///
/// If [detachToken] is non-null, it can later be passed to [finalizerDetach] to
/// remove the [object] from the finalizer.
@pragma("wasm:import", "dart.finalizerAttach")
external WasmVoid finalizerAttach(
  WasmExternRef? finalizer,
  WasmAnyRef object,
  WasmAnyRef? token,
  WasmAnyRef? detachToken,
);

@pragma("wasm:import", "dart.finalizerDetach")
external WasmVoid finalizerDetach(
  WasmExternRef? finalizer,
  WasmAnyRef detachToken,
);

/// Returns the string value for [Uri.base], or null if no base URI exists.
@pragma("wasm:import", "dart.baseUri")
external WasmExternRef? baseUri();

/// Returns `1` if running on Windows, `0` otherwise.
@pragma("wasm:import", "dart.isWindows")
external WasmI32 isWindows();

/// Creates a stack trace object from the current call stack.
///
/// This backs [StackTrace.current], so implementations should hide calls to
/// this extern from the created stack trace.
@pragma("wasm:import", "dart.stackTraceGetCurrent")
external WasmExternRef stackTraceGetCurrent();

/// Renders a stack trace returned by [stackTraceGetCurrent] as a string.
@pragma("wasm:import", "dart.stackTraceToString")
external WasmExternRef stackTraceToString(WasmExternRef? trace);

/// Attempts to parse a string as a double, following semantics described in
/// [double.parse].
///
/// If the string can't be parsed as a double, return null. Otherwise, returns a
/// structure that can be used by [tryParseResultGetDouble] to extract the
/// parsed double.
@pragma("wasm:import", "dart.doubleTryParse")
external WasmExternRef? doubleTryParse(WasmExternRef? string);

/// Extracts the double parsed from [doubleTryParse] returning a non-nullable
/// value.
@pragma("wasm:import", "dart.tryParseResultGetDouble")
external WasmF64 tryParseResultGetDouble(WasmExternRef? parseResult);

/// The implementation of [int.toRadixString].
///
/// The SDK will only call this with radix values between 2 and 36 (inclusive).
@pragma("wasm:import", "dart.i64ToString")
external WasmExternRef i64ToString(WasmI64 value, WasmI32 radix);

/// This and [f64ToExponentialWithFractionDigits] must behave exactly as
/// `Number.prototype.toExponential` in JavaScript.
@pragma("wasm:import", "dart.f64ToExponential")
external WasmExternRef f64ToExponential(WasmF64 value);

@pragma("wasm:import", "dart.f64ToExponentialWithFractionDigits")
external WasmExternRef f64ToExponentialWithFractionDigits(
  WasmF64 value,
  WasmI32 fractionDigits,
);

/// Must behave exactly as `Number.prototype.toPrecision` in JavaScript.
@pragma("wasm:import", "dart.f64ToPrecision")
external WasmExternRef f64ToPrecision(WasmF64 value, WasmI32 fractionDigits);

/// Must behave exactly as `Number.prototype.toFixed` in JavaScript.
@pragma("wasm:import", "dart.f64ToFixed")
external WasmExternRef f64ToFixed(WasmF64 value, WasmI32 fractionDigits);

/// Implements [double.toString].
@pragma("wasm:import", "dart.f64ToString")
external WasmExternRef f64ToString(WasmF64 value);

/// Creates a string buffer object.
@pragma("wasm:import", "dart.stringBufferCreate")
external WasmExternRef stringBufferCreate();

/// Appends a string to a string buffer.
@pragma("wasm:import", "dart.stringBufferWriteString")
external WasmVoid stringBufferWriteString(
  WasmExternRef? buffer,
  WasmExternRef? string,
);

/// Appends a string containing the character with the [code] point to a string
/// buffer.
@pragma("wasm:import", "dart.stringBufferWriteCharCode")
external WasmVoid stringBufferWriteCharCode(
  WasmExternRef? buffer,
  WasmI32 code,
);

/// Clears the contents of a string buffer.
@pragma("wasm:import", "dart.stringBufferClear")
external WasmVoid stringBufferClear(WasmExternRef? buffer);

/// The current length of a string in a string buffer.
@pragma("wasm:import", "dart.stringBufferLength")
external WasmI32 stringBufferLength(WasmExternRef? buffer);

/// Turn a string buffer into a string.
@pragma("wasm:import", "dart.stringBufferToString")
external WasmExternRef stringBufferToString(WasmExternRef? buffer);

/// Attempts to parse the `string` as a regular expression with the given
/// options.
///
/// Returns a regular expression object if that succeeds, or an error message as
/// a string otherwise.
@pragma("wasm:import", "dart.regexpCreateOrFailWithString")
external WasmExternRef regexpCreateOrFailWithString(
  WasmExternRef? string,
  WasmI32 multiLine,
  WasmI32 caseSensitive,
  WasmI32 unicode,
  WasmI32 dotAll,
);

/// Called with the return value of [regexpCreateOrFailWithString], returns
/// whether [ref] is a regular expression object.
///
/// If this returns `0`, the return value is interpreted as an error message
/// string instead.
@pragma("wasm:import", "dart.regexpIsRegexp")
external WasmI32 regexpIsRegexp(WasmExternRef? ref);

/// Implementation of [RegExp.escape].
@pragma("wasm:import", "dart.regexpEscape")
external WasmExternRef regexpEscape(WasmExternRef? string);

/// If [asPrefix] is `0`, return the first match of [string] for [regexp] at or
/// after [start] code units.
///
/// If [asPrefix] is `1`, only return the match if it starts exactly at [start].
@pragma("wasm:import", "dart.regexpMatch")
external WasmExternRef? regexpMatch(
  WasmExternRef? regexp,
  WasmExternRef? string,
  WasmI32 start,
  WasmI32 asPrefix,
);

/// Implementation of [Match.start] for a [regexpMatch].
@pragma("wasm:import", "dart.regexpMatchGetStart")
external WasmI32 regexpMatchGetStart(WasmExternRef? match);

/// Implementation of [Match.end] for a [regexpMatch].
@pragma("wasm:import", "dart.regexpMatchGetEnd")
external WasmI32 regexpMatchGetEnd(WasmExternRef? match);

/// Implementation of [Match.groupCount] for a [regexpMatch].
@pragma("wasm:import", "dart.regexpMatchGetGroupCount")
external WasmI32 regexpMatchGetGroupCount(WasmExternRef? match);

/// Implementation of [Match.group] for a [regexpMatch].
///
/// This is only called with an index between 0 and [regexpMatchGetGroupCount]
/// (inclusive).
@pragma("wasm:import", "dart.regexpMatchGetGroup")
external WasmExternRef? regexpMatchGetGroup(
  WasmExternRef? match,
  WasmI32 index,
);

/// The amount of named groups in a regexp match.
@pragma("wasm:import", "dart.regexpMatchGetNamedGroups")
external WasmI32 regexpMatchGetNamedGroups(WasmExternRef? match);

/// For an index between 0 and [regexpMatchGetNamedGroups] (exclusive), returns
/// the name of the regexp group.
@pragma("wasm:import", "dart.regexpMatchGetGroupName")
external WasmExternRef regexpMatchGetGroupName(
  WasmExternRef? match,
  WasmI32 index,
);

/// For an index of [regexpMatchGetNamedGroups], returns the match of the group
/// named `regexpMatchGetGroupName(match, nameIndex)`.
@pragma("wasm:import", "dart.regexpMatchGetGroupByName")
external WasmExternRef? regexpMatchGetGroupByName(
  WasmExternRef? match,
  WasmI32 nameIndex,
);

@pragma("wasm:import", "dart.timeZoneNameForClampedSeconds")
external WasmExternRef timeZoneNameForClampedSeconds(WasmI64 secondsSinceEpoch);

@pragma("wasm:import", "dart.timeZoneOffsetInSecondsForClampedSeconds")
external WasmI32 timeZoneOffsetInSecondsForClampedSeconds(
  WasmI64 secondsSinceEpoch,
);
