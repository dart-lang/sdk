// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All imports must be in all FFI patch files to not depend on the order
// the patches are applied.
import "dart:_internal" show patch;
import 'dart:typed_data';
import 'dart:isolate';

const Map<Type, int> _knownSizes = {
  Int8: 1,
  Uint8: 1,
  Int16: 2,
  Uint16: 2,
  Int32: 4,
  Uint32: 4,
  Int64: 8,
  Uint64: 8,
  Float: 4,
  Double: 8,
};

@pragma("vm:prefer-inline")
int get _intPtrSize => (const [8, 4, 4])[_abi()];

@patch
int sizeOf<T extends NativeType>() {
  // This is not super fast, but it is faster than a runtime entry.
  // Hot loops with elementAt().load() do not use this sizeOf, elementAt is
  // optimized per NativeType statically to prevent use of sizeOf at runtime.
  final int? knownSize = _knownSizes[T];
  if (knownSize != null) return knownSize;
  if (T == IntPtr) return _intPtrSize;
  if (T == Pointer) return _intPtrSize;
  // For structs we fall back to a runtime entry.
  return _sizeOf<T>();
}

int _sizeOf<T extends NativeType>() native "Ffi_sizeOf";

@pragma("vm:recognized", "other")
Pointer<T> _fromAddress<T extends NativeType>(int ptr) native "Ffi_fromAddress";

// The real implementation of this function (for interface calls) lives in
// BuildFfiAsFunctionCall in the Kernel frontend. No calls can actually reach
// this function.
@pragma("vm:recognized", "other")
DS _asFunctionInternal<DS extends Function, NS extends Function>(
    Pointer<NativeFunction<NS>> ptr) native "Ffi_asFunctionInternal";

dynamic _asExternalTypedData(Pointer ptr, int count)
    native "Ffi_asExternalTypedData";

// Returns a Function object for a native callback.
//
// Calls to [Pointer.fromFunction] are re-written by the FE into calls to this
// method + _pointerFromFunction. All three arguments must be constants.
//
// In AOT we evaluate calls to this function during precompilation and replace
// them with Constant instruction referencing the callback trampoline, to ensure
// that it will be precompiled.
//
// In all JIT modes we call a native runtime entry. We *cannot* use the IL
// implementation, since that would pull the callback trampoline into JIT
// snapshots. The callback trampolines can only be serialized into AOT snapshots
// because they embed the addresses of runtime routines in JIT mode.
//
// Function objects returned by this native method are not Dart instances,
// so we need to use top type as a return type to avoid type check.
@pragma("vm:recognized", "other")
dynamic _nativeCallbackFunction<NS extends Function>(Function target,
    Object? exceptionalReturn) native "Ffi_nativeCallbackFunction";

Pointer<NS> _pointerFromFunction<NS extends NativeFunction>(dynamic function)
    native "Ffi_pointerFromFunction";

@patch
@pragma("vm:entry-point")
class Pointer<T extends NativeType> {
  @patch
  factory Pointer.fromAddress(int ptr) => _fromAddress(ptr);

  // All static calls to this method are replaced by the FE into
  // _nativeCallbackFunction + _pointerFromFunction.
  //
  // We still need to throw an error on a dynamic invocations, invocations
  // through tearoffs or reflective calls.
  @patch
  static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
      @DartRepresentationOf("T") Function f,
      [Object? exceptionalReturn]) {
    throw UnsupportedError(
        "Pointer.fromFunction cannot be called dynamically.");
  }

  @patch
  @pragma("vm:recognized", "other")
  int get address native "Ffi_address";

  // For statically known types, this is rewired.
  // (Method sizeOf is slow, see notes above.)
  @patch
  Pointer<T> elementAt(int index) =>
      Pointer.fromAddress(address + sizeOf<T>() * index);

  @patch
  Pointer<T> _offsetBy(int offsetInBytes) =>
      Pointer.fromAddress(address + offsetInBytes);

  @patch
  Pointer<U> cast<U extends NativeType>() => Pointer.fromAddress(address);
}

/// Returns an integer encoding the ABI used for size and alignment
/// calculations. See pkg/vm/lib/transformations/ffi.dart.
@pragma("vm:recognized", "other")
@pragma('vm:prefer-inline')
int _abi()
    native "Recognized method: IR graph is built in the flow graph builder.";

/// Copies data byte-wise from [source] to [target].
///
/// [source] and [target] should either be [Pointer] or [TypedData].
///
/// TODO(dartbug.com/37271): Make recognized method and use MemoryCopyInstr.
void _memCopy(Object target, int targetOffsetInBytes, Object source,
    int sourceOffsetInBytes, int lengthInBytes) {
  assert(source is Pointer || source is TypedData);
  assert(target is Pointer || target is TypedData);
  if (source is Pointer) {
    final sourcePointer = source.cast<Uint8>();
    if (target is Pointer) {
      final targetPointer = target.cast<Uint8>();
      for (int i = 0; i < lengthInBytes; i++) {
        targetPointer[i + targetOffsetInBytes] =
            sourcePointer[i + sourceOffsetInBytes];
      }
    } else if (target is TypedData) {
      final targetTypedData = target.buffer.asUint8List(target.offsetInBytes);
      for (int i = 0; i < lengthInBytes; i++) {
        targetTypedData[i + targetOffsetInBytes] =
            sourcePointer[i + sourceOffsetInBytes];
      }
    }
  } else if (source is TypedData) {
    final sourceTypedData = source.buffer.asUint8List(source.offsetInBytes);
    if (target is Pointer) {
      final targetPointer = target.cast<Uint8>();
      for (int i = 0; i < lengthInBytes; i++) {
        targetPointer[i + targetOffsetInBytes] =
            sourceTypedData[i + sourceOffsetInBytes];
      }
    } else if (target is TypedData) {
      final targetTypedData = target.buffer.asUint8List(target.offsetInBytes);
      targetTypedData.setRange(
          targetOffsetInBytes,
          targetOffsetInBytes + lengthInBytes,
          sourceTypedData.sublist(sourceOffsetInBytes));
    }
  }
}

// The following functions are implemented in the method recognizer.
//
// TODO(38172): Since these are not inlined (force optimize), they force
// allocating a Pointer with in elementAt/offsetBy. Allocating these pointers
// and GCing new spaces takes a lot of the benchmark time. The next speedup is
// getting rid of these allocations by inlining these functions.
@pragma("vm:recognized", "other")
int _loadInt8(Pointer pointer, int offsetInBytes) native "Ffi_loadInt8";

@pragma("vm:recognized", "other")
int _loadInt16(Pointer pointer, int offsetInBytes) native "Ffi_loadInt16";

@pragma("vm:recognized", "other")
int _loadInt32(Pointer pointer, int offsetInBytes) native "Ffi_loadInt32";

@pragma("vm:recognized", "other")
int _loadInt64(Pointer pointer, int offsetInBytes) native "Ffi_loadInt64";

@pragma("vm:recognized", "other")
int _loadUint8(Pointer pointer, int offsetInBytes) native "Ffi_loadUint8";

@pragma("vm:recognized", "other")
int _loadUint16(Pointer pointer, int offsetInBytes) native "Ffi_loadUint16";

@pragma("vm:recognized", "other")
int _loadUint32(Pointer pointer, int offsetInBytes) native "Ffi_loadUint32";

@pragma("vm:recognized", "other")
int _loadUint64(Pointer pointer, int offsetInBytes) native "Ffi_loadUint64";

@pragma("vm:recognized", "other")
int _loadIntPtr(Pointer pointer, int offsetInBytes) native "Ffi_loadIntPtr";

@pragma("vm:recognized", "other")
double _loadFloat(Pointer pointer, int offsetInBytes) native "Ffi_loadFloat";

@pragma("vm:recognized", "other")
double _loadDouble(Pointer pointer, int offsetInBytes) native "Ffi_loadDouble";

@pragma("vm:recognized", "other")
Pointer<S> _loadPointer<S extends NativeType>(
    Pointer pointer, int offsetInBytes) native "Ffi_loadPointer";

S _loadStruct<S extends Struct>(Pointer<S> pointer, int index)
    native "Ffi_loadStruct";

@pragma("vm:recognized", "other")
void _storeInt8(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeInt8";

@pragma("vm:recognized", "other")
void _storeInt16(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeInt16";

@pragma("vm:recognized", "other")
void _storeInt32(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeInt32";

@pragma("vm:recognized", "other")
void _storeInt64(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeInt64";

@pragma("vm:recognized", "other")
void _storeUint8(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeUint8";

@pragma("vm:recognized", "other")
void _storeUint16(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeUint16";

@pragma("vm:recognized", "other")
void _storeUint32(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeUint32";

@pragma("vm:recognized", "other")
void _storeUint64(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeUint64";

@pragma("vm:recognized", "other")
void _storeIntPtr(Pointer pointer, int offsetInBytes, int value)
    native "Ffi_storeIntPtr";

@pragma("vm:recognized", "other")
void _storeFloat(Pointer pointer, int offsetInBytes, double value)
    native "Ffi_storeFloat";

@pragma("vm:recognized", "other")
void _storeDouble(Pointer pointer, int offsetInBytes, double value)
    native "Ffi_storeDouble";

@pragma("vm:recognized", "other")
void _storePointer<S extends NativeType>(Pointer pointer, int offsetInBytes,
    Pointer<S> value) native "Ffi_storePointer";

Pointer<Int8> _elementAtInt8(Pointer<Int8> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 1 * index);

Pointer<Int16> _elementAtInt16(Pointer<Int16> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 2 * index);

Pointer<Int32> _elementAtInt32(Pointer<Int32> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 4 * index);

Pointer<Int64> _elementAtInt64(Pointer<Int64> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 8 * index);

Pointer<Uint8> _elementAtUint8(Pointer<Uint8> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 1 * index);

Pointer<Uint16> _elementAtUint16(Pointer<Uint16> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 2 * index);

Pointer<Uint32> _elementAtUint32(Pointer<Uint32> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 4 * index);

Pointer<Uint64> _elementAtUint64(Pointer<Uint64> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 8 * index);

Pointer<IntPtr> _elementAtIntPtr(Pointer<IntPtr> pointer, int index) =>
    Pointer.fromAddress(pointer.address + _intPtrSize * index);

Pointer<Float> _elementAtFloat(Pointer<Float> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 4 * index);

Pointer<Double> _elementAtDouble(Pointer<Double> pointer, int index) =>
    Pointer.fromAddress(pointer.address + 8 * index);

Pointer<Pointer<S>> _elementAtPointer<S extends NativeType>(
        Pointer<Pointer<S>> pointer, int index) =>
    Pointer.fromAddress(pointer.address + _intPtrSize * index);

extension NativeFunctionPointer<NF extends Function>
    on Pointer<NativeFunction<NF>> {
  @patch
  DF asFunction<DF extends Function>() =>
      throw UnsupportedError("The body is inlined in the frontend.");
}

//
// The following code is generated, do not edit by hand.
//
// Code generated by `runtime/tools/ffi/sdk_lib_ffi_generator.dart`.
//

extension Int8Pointer on Pointer<Int8> {
  @patch
  int get value => _loadInt8(this, 0);

  @patch
  set value(int value) => _storeInt8(this, 0, value);

  @patch
  int operator [](int index) => _loadInt8(this, index);

  @patch
  operator []=(int index, int value) => _storeInt8(this, index, value);

  @patch
  Int8List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Int16Pointer on Pointer<Int16> {
  @patch
  int get value => _loadInt16(this, 0);

  @patch
  set value(int value) => _storeInt16(this, 0, value);

  @patch
  int operator [](int index) => _loadInt16(this, 2 * index);

  @patch
  operator []=(int index, int value) => _storeInt16(this, 2 * index, value);

  @patch
  Int16List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Int32Pointer on Pointer<Int32> {
  @patch
  int get value => _loadInt32(this, 0);

  @patch
  set value(int value) => _storeInt32(this, 0, value);

  @patch
  int operator [](int index) => _loadInt32(this, 4 * index);

  @patch
  operator []=(int index, int value) => _storeInt32(this, 4 * index, value);

  @patch
  Int32List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Int64Pointer on Pointer<Int64> {
  @patch
  int get value => _loadInt64(this, 0);

  @patch
  set value(int value) => _storeInt64(this, 0, value);

  @patch
  int operator [](int index) => _loadInt64(this, 8 * index);

  @patch
  operator []=(int index, int value) => _storeInt64(this, 8 * index, value);

  @patch
  Int64List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Uint8Pointer on Pointer<Uint8> {
  @patch
  int get value => _loadUint8(this, 0);

  @patch
  set value(int value) => _storeUint8(this, 0, value);

  @patch
  int operator [](int index) => _loadUint8(this, index);

  @patch
  operator []=(int index, int value) => _storeUint8(this, index, value);

  @patch
  Uint8List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Uint16Pointer on Pointer<Uint16> {
  @patch
  int get value => _loadUint16(this, 0);

  @patch
  set value(int value) => _storeUint16(this, 0, value);

  @patch
  int operator [](int index) => _loadUint16(this, 2 * index);

  @patch
  operator []=(int index, int value) => _storeUint16(this, 2 * index, value);

  @patch
  Uint16List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Uint32Pointer on Pointer<Uint32> {
  @patch
  int get value => _loadUint32(this, 0);

  @patch
  set value(int value) => _storeUint32(this, 0, value);

  @patch
  int operator [](int index) => _loadUint32(this, 4 * index);

  @patch
  operator []=(int index, int value) => _storeUint32(this, 4 * index, value);

  @patch
  Uint32List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension Uint64Pointer on Pointer<Uint64> {
  @patch
  int get value => _loadUint64(this, 0);

  @patch
  set value(int value) => _storeUint64(this, 0, value);

  @patch
  int operator [](int index) => _loadUint64(this, 8 * index);

  @patch
  operator []=(int index, int value) => _storeUint64(this, 8 * index, value);

  @patch
  Uint64List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension IntPtrPointer on Pointer<IntPtr> {
  @patch
  int get value => _loadIntPtr(this, 0);

  @patch
  set value(int value) => _storeIntPtr(this, 0, value);

  @patch
  int operator [](int index) => _loadIntPtr(this, _intPtrSize * index);

  @patch
  operator []=(int index, int value) =>
      _storeIntPtr(this, _intPtrSize * index, value);
}

extension FloatPointer on Pointer<Float> {
  @patch
  double get value => _loadFloat(this, 0);

  @patch
  set value(double value) => _storeFloat(this, 0, value);

  @patch
  double operator [](int index) => _loadFloat(this, 4 * index);

  @patch
  operator []=(int index, double value) => _storeFloat(this, 4 * index, value);

  @patch
  Float32List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

extension DoublePointer on Pointer<Double> {
  @patch
  double get value => _loadDouble(this, 0);

  @patch
  set value(double value) => _storeDouble(this, 0, value);

  @patch
  double operator [](int index) => _loadDouble(this, 8 * index);

  @patch
  operator []=(int index, double value) => _storeDouble(this, 8 * index, value);

  @patch
  Float64List asTypedList(int elements) => _asExternalTypedData(this, elements);
}

//
// End of generated code.
//

extension PointerPointer<T extends NativeType> on Pointer<Pointer<T>> {
  @patch
  Pointer<T> get value => _loadPointer(this, 0);

  @patch
  set value(Pointer<T> value) => _storePointer(this, 0, value);

  @patch
  Pointer<T> operator [](int index) => _loadPointer(this, _intPtrSize * index);

  @patch
  operator []=(int index, Pointer<T> value) =>
      _storePointer(this, _intPtrSize * index, value);
}

extension StructPointer<T extends Struct> on Pointer<T> {
  @patch
  T get ref => _loadStruct(this, 0);

  @patch
  T operator [](int index) => _loadStruct(this, index);
}

extension NativePort on SendPort {
  @patch
  int get nativePort native "SendPortImpl_get_id";
}

int _nativeApiFunctionPointer(String symbol)
    native "DartNativeApiFunctionPointer";

int _initializeApiDLData() native "DartApiDLInitializeData";

int _dartApiMajorVersion() native "DartApiDLMajorVersion";

int _dartApiMinorVersion() native "DartApiDLMinorVersion";

@patch
abstract class NativeApi {
  @patch
  static Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
      get postCObject =>
          Pointer.fromAddress(_nativeApiFunctionPointer("Dart_PostCObject"));

  @patch
  static Pointer<
      NativeFunction<
          Int64 Function(
              Pointer<Uint8>,
              Pointer<NativeFunction<Dart_NativeMessageHandler>>,
              Int8)>> get newNativePort =>
      Pointer.fromAddress(_nativeApiFunctionPointer("Dart_NewNativePort"));

  @patch
  static Pointer<NativeFunction<Int8 Function(Int64)>> get closeNativePort =>
      Pointer.fromAddress(_nativeApiFunctionPointer("Dart_CloseNativePort"));

  @patch
  static int get majorVersion => _dartApiMajorVersion();

  @patch
  static int get minorVersion => _dartApiMinorVersion();

  @patch
  static Pointer<Void> get initializeApiDLData =>
      Pointer.fromAddress(_initializeApiDLData());
}
