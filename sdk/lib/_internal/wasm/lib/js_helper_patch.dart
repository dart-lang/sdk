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
    return JSStringImpl(JS<WasmExternRef>(r'''
      (s, length) => {
        if (length == 0) return '';

        const read = dartInstance.exports.$stringRead1;
        let result = '';
        let index = 0;
        const chunkLength = Math.min(length - index, 500);
        let array = new Array(chunkLength);
        while (index < length) {
          const newChunkLength = Math.min(length - index, 500);
          for (let i = 0; i < newChunkLength; i++) {
            array[i] = read(s, index++);
          }
          if (newChunkLength < chunkLength) {
            array = array.slice(0, newChunkLength);
          }
          result += String.fromCharCode(...array);
        }
        return result;
      }
      ''', jsObjectFromDartObject(s), s.length.toWasmI32()));
  }
  if (s is TwoByteString) {
    return JSStringImpl(JS<WasmExternRef>(r'''
    (s, length) => {
      if (length == 0) return '';

      const read = dartInstance.exports.$stringRead2;
      let result = '';
      let index = 0;
      const chunkLength = Math.min(length - index, 500);
      let array = new Array(chunkLength);
      while (index < length) {
        const newChunkLength = Math.min(length - index, 500);
        for (let i = 0; i < newChunkLength; i++) {
          array[i] = read(s, index++);
        }
        if (newChunkLength < chunkLength) {
          array = array.slice(0, newChunkLength);
        }
        result += String.fromCharCode(...array);
      }
      return result;
    }
    ''', jsObjectFromDartObject(s), s.length.toWasmI32()));
  }

  return unsafeCast<JSStringImpl>(s);
}

@patch
@pragma('wasm:prefer-inline')
String jsStringToDartString(JSStringImpl s) {
  final length = s.length;
  if (length == 0) return '';

  return JS<String>(r'''
    (s) => {
      let length = s.length;
      let range = 0;
      for (let i = 0; i < length; i++) {
        range |= s.codePointAt(i);
      }
      const exports = dartInstance.exports;
      if (range < 256) {
        if (length <= 10) {
          if (length == 1) {
            return exports.$stringAllocate1_1(s.codePointAt(0));
          }
          if (length == 2) {
            return exports.$stringAllocate1_2(s.codePointAt(0), s.codePointAt(1));
          }
          if (length == 3) {
            return exports.$stringAllocate1_3(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2));
          }
          if (length == 4) {
            return exports.$stringAllocate1_4(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3));
          }
          if (length == 5) {
            return exports.$stringAllocate1_5(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4));
          }
          if (length == 6) {
            return exports.$stringAllocate1_6(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5));
          }
          if (length == 7) {
            return exports.$stringAllocate1_7(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6));
          }
          if (length == 8) {
            return exports.$stringAllocate1_8(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7));
          }
          if (length == 9) {
            return exports.$stringAllocate1_9(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8));
          }
          if (length == 10) {
            return exports.$stringAllocate1_10(s.codePointAt(0), s.codePointAt(1), s.codePointAt(2), s.codePointAt(3), s.codePointAt(4), s.codePointAt(5), s.codePointAt(6), s.codePointAt(7), s.codePointAt(8), s.codePointAt(9));
          }
        }
        const dartString = exports.$stringAllocate1(length);
        const write = exports.$stringWrite1;
        for (let i = 0; i < length; i++) {
          write(dartString, i, s.codePointAt(i));
        }
        return dartString;
      } else {
        const dartString = exports.$stringAllocate2(length);
        const write = exports.$stringWrite2;
        for (let i = 0; i < length; i++) {
          write(dartString, i, s.charCodeAt(i));
        }
        return dartString;
      }
    }
    ''', s.toExternRef);
}

@pragma('wasm:prefer-inline')
void _copyFromWasmI8Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmI8> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void copyToWasmI8Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmI8> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void _copyFromWasmI16Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmI16> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void copyToWasmI16Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmI16> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void _copyFromWasmI32Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmI32> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void copyToWasmI32Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmI32> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void _copyFromWasmF32Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmF32> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void copyToWasmF32Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmF32> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void _copyFromWasmF64Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmF64> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
}

@pragma('wasm:prefer-inline')
void copyToWasmF64Array(WasmExternRef jsArray, int jsArrayOffset,
    WasmArray<WasmF64> wasmArray, int wasmOffset, int length) {
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
      length.toWasmI32());
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
        (jsArray as JSValue).toExternRef!, 0, l.data, l.offsetInBytes, length);
    return (JSDataView(jsArrayBuffer, 0, length) as JSValue).toExternRef!;
  }

  return JS<WasmExternRef>("""(data, length) => {
          const getValue = dartInstance.exports.\$byteDataGetUint8;
          const view = new DataView(new ArrayBuffer(length));
          for (let i = 0; i < length; i++) {
            view.setUint8(i, getValue(data, i));
          }
          return view;
        }""", l, length.toWasmI32());
}

@pragma("wasm:export", "\$stringAllocate1")
OneByteString _stringAllocate1(WasmI32 length) {
  return OneByteString.withLength(length.toIntSigned());
}

@pragma("wasm:export", "\$stringAllocate1_1")
OneByteString _stringAllocate1_1(WasmI32 a0) {
  final result = OneByteString.withLength(1);
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_2")
OneByteString _stringAllocate1_2(WasmI32 a0, WasmI32 a1) {
  final result = OneByteString.withLength(2);
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_3")
OneByteString _stringAllocate1_3(WasmI32 a0, WasmI32 a1, WasmI32 a2) {
  final result = OneByteString.withLength(3);
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_4")
OneByteString _stringAllocate1_4(
    WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3) {
  final result = OneByteString.withLength(4);
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_5")
OneByteString _stringAllocate1_5(
    WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3, WasmI32 a4) {
  final result = OneByteString.withLength(5);
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_6")
OneByteString _stringAllocate1_6(
    WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3, WasmI32 a4, WasmI32 a5) {
  final result = OneByteString.withLength(6);
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_7")
OneByteString _stringAllocate1_7(WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3,
    WasmI32 a4, WasmI32 a5, WasmI32 a6) {
  final result = OneByteString.withLength(7);
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_8")
OneByteString _stringAllocate1_8(WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3,
    WasmI32 a4, WasmI32 a5, WasmI32 a6, WasmI32 a7) {
  final result = OneByteString.withLength(8);
  result.setUnchecked(7, a7.toIntSigned());
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_9")
OneByteString _stringAllocate1_9(WasmI32 a0, WasmI32 a1, WasmI32 a2, WasmI32 a3,
    WasmI32 a4, WasmI32 a5, WasmI32 a6, WasmI32 a7, WasmI32 a8) {
  final result = OneByteString.withLength(9);
  result.setUnchecked(8, a8.toIntSigned());
  result.setUnchecked(7, a7.toIntSigned());
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringAllocate1_10")
OneByteString _stringAllocate1_10(
    WasmI32 a0,
    WasmI32 a1,
    WasmI32 a2,
    WasmI32 a3,
    WasmI32 a4,
    WasmI32 a5,
    WasmI32 a6,
    WasmI32 a7,
    WasmI32 a8,
    WasmI32 a9) {
  final result = OneByteString.withLength(10);
  result.setUnchecked(9, a9.toIntSigned());
  result.setUnchecked(8, a8.toIntSigned());
  result.setUnchecked(7, a7.toIntSigned());
  result.setUnchecked(6, a6.toIntSigned());
  result.setUnchecked(5, a5.toIntSigned());
  result.setUnchecked(4, a4.toIntSigned());
  result.setUnchecked(3, a3.toIntSigned());
  result.setUnchecked(2, a2.toIntSigned());
  result.setUnchecked(1, a1.toIntSigned());
  result.setUnchecked(0, a0.toIntSigned());
  return result;
}

@pragma("wasm:export", "\$stringRead1")
WasmI32 _stringRead1(WasmExternRef ref, WasmI32 index) {
  final string = unsafeCastOpaque<OneByteString>(ref.internalize());
  return string.codeUnitAtUnchecked(index.toIntSigned()).toWasmI32();
}

@pragma("wasm:export", "\$stringWrite1")
void _stringWrite1(WasmExternRef ref, WasmI32 index, WasmI32 codePoint) {
  final string = unsafeCastOpaque<OneByteString>(ref.internalize());
  string.setUnchecked(index.toIntSigned(), codePoint.toIntSigned());
}

@pragma("wasm:export", "\$stringAllocate2")
TwoByteString _stringAllocate2(WasmI32 length) {
  return TwoByteString.withLength(length.toIntSigned());
}

@pragma("wasm:export", "\$stringRead2")
WasmI32 _stringRead2(WasmExternRef ref, WasmI32 index) {
  final string = unsafeCastOpaque<TwoByteString>(ref.internalize());
  return string.codeUnitAtUnchecked(index.toIntSigned()).toWasmI32();
}

@pragma("wasm:export", "\$stringWrite2")
void _stringWrite2(WasmExternRef ref, WasmI32 index, WasmI32 codePoint) {
  final string = unsafeCastOpaque<TwoByteString>(ref.internalize());
  string.setUnchecked(index.toIntSigned(), codePoint.toIntSigned());
}

@pragma("wasm:export", "\$wasmI8ArrayGet")
WasmI32 _wasmI8ArrayGet(WasmExternRef ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmI8>>(ref.internalize());
  return array.readUnsigned(index.toIntUnsigned()).toWasmI32();
}

@pragma("wasm:export", "\$wasmI8ArraySet")
void _wasmI8ArraySet(WasmExternRef ref, WasmI32 index, WasmI32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmI8>>(ref.internalize());
  array.write(index.toIntUnsigned(), value.toIntUnsigned());
}

@pragma("wasm:export", "\$wasmI16ArrayGet")
WasmI32 _wasmI16ArrayGet(WasmExternRef ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmI16>>(ref.internalize());
  return array.readUnsigned(index.toIntUnsigned()).toWasmI32();
}

@pragma("wasm:export", "\$wasmI16ArraySet")
void _wasmI16ArraySet(WasmExternRef ref, WasmI32 index, WasmI32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmI16>>(ref.internalize());
  array.write(index.toIntUnsigned(), value.toIntUnsigned());
}

@pragma("wasm:export", "\$wasmI32ArrayGet")
WasmI32 _wasmI32ArrayGet(WasmExternRef ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmI32>>(ref.internalize());
  return array.readUnsigned(index.toIntUnsigned()).toWasmI32();
}

@pragma("wasm:export", "\$wasmI32ArraySet")
void _wasmI32ArraySet(WasmExternRef ref, WasmI32 index, WasmI32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmI32>>(ref.internalize());
  array.write(index.toIntUnsigned(), value.toIntUnsigned());
}

@pragma("wasm:export", "\$wasmF32ArrayGet")
WasmF32 _wasmF32ArrayGet(WasmExternRef ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmF32>>(ref.internalize());
  return array[index.toIntUnsigned()];
}

@pragma("wasm:export", "\$wasmF32ArraySet")
void _wasmF32ArraySet(WasmExternRef ref, WasmI32 index, WasmF32 value) {
  final array = unsafeCastOpaque<WasmArray<WasmF32>>(ref.internalize());
  array[index.toIntUnsigned()] = value;
}

@pragma("wasm:export", "\$wasmF64ArrayGet")
WasmF64 _wasmF64ArrayGet(WasmExternRef ref, WasmI32 index) {
  final array = unsafeCastOpaque<WasmArray<WasmF64>>(ref.internalize());
  return array[index.toIntUnsigned()];
}

@pragma("wasm:export", "\$wasmF64ArraySet")
void _wasmF64ArraySet(WasmExternRef ref, WasmI32 index, WasmF64 value) {
  final array = unsafeCastOpaque<WasmArray<WasmF64>>(ref.internalize());
  array[index.toIntUnsigned()] = value;
}

@pragma("wasm:export", "\$byteDataGetUint8")
WasmI32 _byteDataGetUint8(WasmExternRef ref, WasmI32 index) {
  final byteData = unsafeCastOpaque<ByteData>(ref.internalize());
  return byteData.getUint8(index.toIntSigned()).toWasmI32();
}
