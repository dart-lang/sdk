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
  if (s is OneByteString) {
    final fromArray = s.array;
    final toArray = WasmArray<WasmI16>(fromArray.length);
    for (int i = 0; i < fromArray.length; ++i) {
      toArray.write(i, fromArray.readUnsigned(i));
    }
    return JSStringImpl(
      _jsStringFromCharCodeArray(
        toArray,
        0.toWasmI32(),
        toArray.length.toWasmI32(),
      ),
    );
  }
  if (s is TwoByteString) {
    return JSStringImpl(
      _jsStringFromCharCodeArray(s.array, 0.toWasmI32(), s.length.toWasmI32()),
    );
  }

  return unsafeCast<JSStringImpl>(s);
}

@patch
String jsStringToDartString(JSStringImpl jsString) {
  final length = jsString.length;
  two_byte:
  {
    final oneByteString = OneByteString.withLength(length);
    final array = oneByteString.array;
    for (int i = 0; i < length; ++i) {
      final int codeUnit = jsString.codeUnitAtUnchecked(i);
      if (codeUnit > 255) break two_byte;
      array.write(i, codeUnit);
    }
    return oneByteString;
  }
  final twoByteString = TwoByteString.withLength(length);
  final array = twoByteString.array;
  for (int i = 0; i < length; ++i) {
    array.write(i, jsString.codeUnitAtUnchecked(i));
  }
  return twoByteString;
}

@pragma("wasm:import", "wasm:js-string.fromCharCodeArray")
external WasmExternRef _jsStringFromCharCodeArray(
  WasmArray<WasmI16>? array,
  WasmI32 start,
  WasmI32 end,
);

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

  if (l is I8List) {
    final length = l.length;
    final jsArray = (JSInt8Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI8Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Int8Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef? jsUint8ArrayFromDartUint8List(Uint8List l) {
  assert(l is! JSArrayBase);

  if (l is U8List) {
    final length = l.length;
    final jsArray = (JSUint8Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI8Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Uint8Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef? jsUint8ClampedArrayFromDartUint8ClampedList(Uint8ClampedList l) {
  assert(l is! JSArrayBase);

  if (l is U8ClampedList) {
    final length = l.length;
    final jsArray =
        (JSUint8ClampedArray.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI8Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Uint8ClampedArray, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt16ArrayFromDartInt16List(Int16List l) {
  assert(l is! JSArrayBase);

  if (l is I16List) {
    final length = l.length;
    final jsArray = (JSInt16Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI16Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Int16Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint16ArrayFromDartUint16List(Uint16List l) {
  assert(l is! JSArrayBase);

  if (l is U16List) {
    final length = l.length;
    final jsArray = (JSUint16Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI16Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Uint16Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsInt32ArrayFromDartInt32List(Int32List l) {
  assert(l is! JSArrayBase);

  if (l is I32List) {
    final length = l.length;
    final jsArray = (JSInt32Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI32Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Int32Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsUint32ArrayFromDartUint32List(Uint32List l) {
  assert(l is! JSArrayBase);

  if (l is U32List) {
    final length = l.length;
    final jsArray = (JSUint32Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmI32Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Uint32Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsFloat32ArrayFromDartFloat32List(Float32List l) {
  assert(l is! JSArrayBase);

  if (l is F32List) {
    final length = l.length;
    final jsArray = (JSFloat32Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmF32Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Float32Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsFloat64ArrayFromDartFloat64List(Float64List l) {
  assert(l is! JSArrayBase);

  if (l is F64List) {
    final length = l.length;
    final jsArray = (JSFloat64Array.withLength(length) as JSValue).toExternRef!;
    _copyFromWasmF64Array(jsArray, 0, l.data, l.offsetInElements, length);
    return jsArray;
  }

  return JS<WasmExternRef>('l => arrayFromDartList(Float64Array, l)', l);
}

@patch
@pragma('wasm:prefer-inline')
WasmExternRef jsDataViewFromDartByteData(ByteData l, int length) {
  assert(l is! JSDataViewImpl);

  if (l is I8ByteData) {
    final jsArrayBuffer = JSArrayBuffer(length);
    final jsArray = JSUint8Array(jsArrayBuffer, 0, length);
    _copyFromWasmI8Array(
      (jsArray as JSValue).toExternRef!,
      0,
      l.data,
      l.offsetInBytes,
      length,
    );
    return (JSDataView(jsArrayBuffer, 0, length) as JSValue).toExternRef!;
  }

  return JS<WasmExternRef>(
    """(data, length) => {
          const getValue = dartInstance.exports.\$byteDataGetUint8;
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
            view.setUint8(i, getValue(data, i));
          }
          return view;
        }""",
    l,
    length.toWasmI32(),
  );
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

@pragma("wasm:export", "\$byteDataGetUint8")
WasmI32 _byteDataGetUint8(WasmExternRef? ref, WasmI32 index) {
  final byteData = unsafeCastOpaque<ByteData>(
    unsafeCast<WasmExternRef>(ref).internalize(),
  );
  return byteData.getUint8(index.toIntSigned()).toWasmI32();
}
