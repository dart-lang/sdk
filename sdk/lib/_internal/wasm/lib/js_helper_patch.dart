// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast, unsafeCastOpaque;
import 'dart:_js_helper' show JS;
import 'dart:_js_types' show JSArrayBase, JSDataViewImpl;
import 'dart:js_interop';
import 'dart:_string';
import 'dart:_typed_data';
import 'dart:_wasm';
import 'dart:typed_data';

@patch
@pragma('wasm:prefer-inline')
JSStringImpl jsStringFromDartString(String s) {
  return unsafeCast<JSStringImpl>(s);
}

@patch
@pragma('wasm:prefer-inline')
String jsStringToDartString(JSStringImpl s) {
  return s;
}

@pragma('wasm:prefer-inline')
void _copyFromWasmI8Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmI8> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const getValue = dartInstance.exports.\$wasmI8ArrayGet;
          for (let i = 0; i < length; i++) {
            jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void copyToWasmI8Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmI8> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const setValue = dartInstance.exports.\$wasmI8ArraySet;
          for (let i = 0; i < length; i++) {
            setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void _copyFromWasmI16Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmI16> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const getValue = dartInstance.exports.\$wasmI16ArrayGet;
          for (let i = 0; i < length; i++) {
            jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void copyToWasmI16Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmI16> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const setValue = dartInstance.exports.\$wasmI16ArraySet;
          for (let i = 0; i < length; i++) {
            setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void _copyFromWasmI32Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmI32> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const getValue = dartInstance.exports.\$wasmI32ArrayGet;
          for (let i = 0; i < length; i++) {
            jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void copyToWasmI32Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmI32> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const setValue = dartInstance.exports.\$wasmI32ArraySet;
          for (let i = 0; i < length; i++) {
            setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void _copyFromWasmF32Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmF32> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const getValue = dartInstance.exports.\$wasmF32ArrayGet;
          for (let i = 0; i < length; i++) {
            jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void copyToWasmF32Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmF32> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const setValue = dartInstance.exports.\$wasmF32ArraySet;
          for (let i = 0; i < length; i++) {
            setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void _copyFromWasmF64Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmF64> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const getValue = dartInstance.exports.\$wasmF64ArrayGet;
          for (let i = 0; i < length; i++) {
            jsArray[jsArrayOffset + i] = getValue(wasmArray, wasmArrayOffset + i);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@pragma('wasm:prefer-inline')
void copyToWasmF64Array(
  WasmExternRef jsArray,
  int jsArrayOffset,
  WasmArray<WasmF64> wasmArray,
  int wasmOffset,
  int length,
) {
  JS<WasmExternRef?>(
    """(jsArray, jsArrayOffset, wasmArray, wasmArrayOffset, length) => {
          const setValue = dartInstance.exports.\$wasmF64ArraySet;
          for (let i = 0; i < length; i++) {
            setValue(wasmArray, wasmArrayOffset + i, jsArray[jsArrayOffset + i]);
          }
        }""",
    jsArray,
    jsArrayOffset.toWasmI32(),
    wasmArray,
    wasmOffset.toWasmI32(),
    length.toWasmI32(),
  );
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt8ArrayFromDartInt8List(Int8List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSInt8Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is I8List) {
    _copyFromWasmI8Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef? jsUint8ArrayFromDartUint8List(Uint8List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSUint8Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is U8List) {
    _copyFromWasmI8Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }

  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef? jsUint8ClampedArrayFromDartUint8ClampedList(Uint8ClampedList l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSUint8ClampedArray.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is U8ClampedList) {
    _copyFromWasmI8Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt16ArrayFromDartInt16List(Int16List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSInt16Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is I16List) {
    _copyFromWasmI16Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint16ArrayFromDartUint16List(Uint16List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSUint16Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is U16List) {
    _copyFromWasmI16Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt32ArrayFromDartInt32List(Int32List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSInt32Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is I32List) {
    _copyFromWasmI32Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }

  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint32ArrayFromDartUint32List(Uint32List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSUint32Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is U32List) {
    _copyFromWasmI32Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsFloat32ArrayFromDartFloat32List(Float32List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSFloat32Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is F32List) {
    _copyFromWasmF32Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsFloat64ArrayFromDartFloat64List(Float64List l) {
  assert(l is! JSArrayBase);
  final length = l.length;

  final jsArray = JSFloat64Array.withLength(length);
  final jsArrayRef = (jsArray as JSValue).toExternRef!;
  if (l is F64List) {
    _copyFromWasmF64Array(jsArrayRef, 0, l.data, l.offsetInElements, length);
  } else {
    jsArray.toDart.setRange(0, length, l);
  }
  return jsArrayRef;
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsDataViewFromDartByteData(ByteData l, int length) {
  assert(l is! JSDataViewImpl);

  final jsArrayBuffer = JSArrayBuffer(length);
  final jsArray = JSUint8Array(jsArrayBuffer, 0, length);
  if (l is I8ByteData) {
    _copyFromWasmI8Array(
      (jsArray as JSValue).toExternRef!,
      0,
      l.data,
      l.offsetInBytes,
      length,
    );
  } else {
    jsArray.toDart.setRange(0, length, Uint8List.sublistView(l, length));
  }

  return (JSDataView(jsArrayBuffer, 0, length) as JSValue).toExternRef!;
}

@pragma("wasm:export", "\$wasmI8ArrayGet")
WasmI32 _wasmI8ArrayGet(WasmExternRef? ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmI8>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  return array.readUnsigned(index.toIntUnsigned()).toWasmI32();
}

@pragma("wasm:export", "\$wasmI8ArraySet")
void _wasmI8ArraySet(WasmExternRef? ref, WasmI32 index, WasmI32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmI8>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  array.write(index.toIntUnsigned(), value.toIntUnsigned());
}

@pragma("wasm:export", "\$wasmI16ArrayGet")
WasmI32 _wasmI16ArrayGet(WasmExternRef? ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmI16>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  return array.readUnsigned(index.toIntUnsigned()).toWasmI32();
}

@pragma("wasm:export", "\$wasmI16ArraySet")
void _wasmI16ArraySet(WasmExternRef? ref, WasmI32 index, WasmI32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmI16>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  array.write(index.toIntUnsigned(), value.toIntUnsigned());
}

@pragma("wasm:export", "\$wasmI32ArrayGet")
WasmI32 _wasmI32ArrayGet(WasmExternRef? ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmI32>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  return array.readUnsigned(index.toIntUnsigned()).toWasmI32();
}

@pragma("wasm:export", "\$wasmI32ArraySet")
void _wasmI32ArraySet(WasmExternRef? ref, WasmI32 index, WasmI32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmI32>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  array.write(index.toIntUnsigned(), value.toIntUnsigned());
}

@pragma("wasm:export", "\$wasmF32ArrayGet")
WasmF32 _wasmF32ArrayGet(WasmExternRef? ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmF32>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  return array[index.toIntUnsigned()];
}

@pragma("wasm:export", "\$wasmF32ArraySet")
void _wasmF32ArraySet(WasmExternRef? ref, WasmI32 index, WasmF32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmF32>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  array[index.toIntUnsigned()] = value;
}

@pragma("wasm:export", "\$wasmF64ArrayGet")
WasmF64 _wasmF64ArrayGet(WasmExternRef? ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmF64>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  return array[index.toIntUnsigned()];
}

@pragma("wasm:export", "\$wasmF64ArraySet")
void _wasmF64ArraySet(WasmExternRef? ref, WasmI32 index, WasmF64 value) {
  final array = unsafeCastOpaque<WasmArray<WasmF64>>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  array[index.toIntUnsigned()] = value;
}
