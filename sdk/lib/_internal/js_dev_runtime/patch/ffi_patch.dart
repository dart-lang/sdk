// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, Since;
import 'dart:isolate';
import 'dart:typed_data';

@patch
int sizeOf<T extends SizedNativeType>() => throw UnsupportedError('sizeOf');

@patch
class Pointer<T extends NativeType> {
  @patch
  factory Pointer.fromAddress(int ptr) =>
      throw UnsupportedError('Pointer.fromAddress');

  @patch
  static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
    Function f, [
    Object? exceptionalReturn,
  ]) => throw UnsupportedError('Pointer.fromFunction');

  @patch
  int get address => throw UnsupportedError('Pointer.address');

  @patch
  Pointer<U> cast<U extends NativeType>() =>
      throw UnsupportedError('Pointer.cast');
}

@patch
abstract final class NativeCallable<T extends Function> {
  @patch
  bool get keepIsolateAlive =>
      throw UnsupportedError('NativeCallable.keepIsolateAlive');

  @patch
  set keepIsolateAlive(bool value) =>
      throw UnsupportedError('NativeCallable.keepIsolateAlive=');
}

abstract final class _NativeCallableBase<T extends Function>
    implements NativeCallable<T> {
  Pointer<NativeFunction<T>> _pointer;

  _NativeCallableBase(this._pointer);

  @override
  Pointer<NativeFunction<T>> get nativeFunction =>
      throw UnsupportedError('_NativeCallableBase.nativeFunction');

  @override
  void close() => throw UnsupportedError('_NativeCallableBase.close');

  @override
  void set keepIsolateAlive(bool value) =>
      throw UnsupportedError('_NativeCallableBase.keepIsolateAlive=');

  @override
  bool get keepIsolateAlive =>
      throw UnsupportedError('_NativeCallableBase.keepIsolateAlive');
}

final class _NativeCallableIsolateLocal<T extends Function>
    extends _NativeCallableBase<T> {
  _NativeCallableIsolateLocal(super._pointer) {
    throw UnsupportedError('_NativeCallableIsolateLocal.new');
  }
}

final class _NativeCallableListener<T extends Function>
    extends _NativeCallableBase<T> {
  _NativeCallableListener(void Function(List) handler, String portDebugName)
    : super(nullptr) {
    throw UnsupportedError('_NativeCallableListener.new');
  }
}

final class _NativeCallableIsolateGroupBound<T extends Function>
    extends _NativeCallableBase<T> {
  _NativeCallableIsolateGroupBound(super._pointer) {
    throw UnsupportedError('_NativeCallableIsolateGroupBound.new');
  }
}

@patch
extension NativeFunctionPointer<NF extends Function>
    on Pointer<NativeFunction<NF>> {
  @patch
  DF asFunction<DF extends Function>({bool isLeaf = false}) =>
      throw UnsupportedError('NativeFunctionPointer.asFunction');
}

@patch
abstract final class NativeApi {
  @patch
  static int get majorVersion =>
      throw UnsupportedError('NativeApi.majorVersion');

  @patch
  static int get minorVersion =>
      throw UnsupportedError('NativeApi.minorVersion');

  @patch
  static Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>
  get postCObject => throw UnsupportedError('NativeApi.postCObject');

  @patch
  static Pointer<
    NativeFunction<
      Int64 Function(
        Pointer<Uint8>,
        Pointer<NativeFunction<Dart_NativeMessageHandler>>,
        Int8,
      )
    >
  >
  get newNativePort => throw UnsupportedError('NativeApi.newNativePort');

  @patch
  static Pointer<NativeFunction<Int8 Function(Int64)>> get closeNativePort =>
      throw UnsupportedError('NativeApi.closeNativePort');

  @patch
  static Pointer<Void> get initializeApiDLData =>
      throw UnsupportedError('NativeApi.initializeApiDLData');
}

@patch
final class Native<T> {
  @patch
  static Pointer<T> addressOf<T extends NativeType>(Object native) =>
      throw UnsupportedError('Native.addressOf');
}

@patch
final class _ArraySize<T extends NativeType> implements Array<T> {
  @patch
  final int _offsetInBytes = 0;

  @patch
  final Object _typedDataBase = const Object();
}

@patch
extension Int8Pointer on Pointer<Int8> {
  @patch
  int get value => throw UnsupportedError('Int8Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Int8Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Int8Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int8Pointer.[]=');
  @patch
  Int8List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Int8Pointer.asTypedList');
}

@patch
extension Int16Pointer on Pointer<Int16> {
  @patch
  int get value => throw UnsupportedError('Int16Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Int16Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Int16Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int16Pointer.[]=');
  @patch
  Int16List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Int16Pointer.asTypedList');
}

@patch
extension Int32Pointer on Pointer<Int32> {
  @patch
  int get value => throw UnsupportedError('Int32Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Int32Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Int32Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int32Pointer.[]=');
  @patch
  Int32List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Int32Pointer.asTypedList');
}

@patch
extension Int64Pointer on Pointer<Int64> {
  @patch
  int get value => throw UnsupportedError('Int64Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Int64Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Int64Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int64Pointer.[]=');
  @patch
  Int64List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Int64Pointer.asTypedList');
}

@patch
extension Uint8Pointer on Pointer<Uint8> {
  @patch
  int get value => throw UnsupportedError('Uint8Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Uint8Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Uint8Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint8Pointer.[]=');
  @patch
  Uint8List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Uint8Pointer.asTypedList');
}

@patch
extension Uint16Pointer on Pointer<Uint16> {
  @patch
  int get value => throw UnsupportedError('Uint16Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Uint16Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Uint16Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint16Pointer.[]=');
  @patch
  Uint16List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Uint16Pointer.asTypedList');
}

@patch
extension Uint32Pointer on Pointer<Uint32> {
  @patch
  int get value => throw UnsupportedError('Uint32Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Uint32Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Uint32Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint32Pointer.[]=');
  @patch
  Uint32List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Uint32Pointer.asTypedList');
}

@patch
extension Uint64Pointer on Pointer<Uint64> {
  @patch
  int get value => throw UnsupportedError('Uint64Pointer.value');
  @patch
  set value(int value) => throw UnsupportedError('Uint64Pointer.value=');
  @patch
  int operator [](int index) => throw UnsupportedError('Uint64Pointer.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint64Pointer.[]=');
  @patch
  Uint64List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('Uint64Pointer.asTypedList');
}

@patch
extension FloatPointer on Pointer<Float> {
  @patch
  double get value => throw UnsupportedError('FloatPointer.value');
  @patch
  set value(double value) => throw UnsupportedError('FloatPointer.value=');
  @patch
  double operator [](int index) => throw UnsupportedError('FloatPointer.[]');
  @patch
  void operator []=(int index, double value) =>
      throw UnsupportedError('FloatPointer.[]=');
  @patch
  Float32List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('FloatPointer.asTypedList');
}

@patch
extension DoublePointer on Pointer<Double> {
  @patch
  double get value => throw UnsupportedError('DoublePointer.value');
  @patch
  set value(double value) => throw UnsupportedError('DoublePointer.value=');
  @patch
  double operator [](int index) => throw UnsupportedError('DoublePointer.[]');
  @patch
  void operator []=(int index, double value) =>
      throw UnsupportedError('DoublePointer.[]=');
  @patch
  Float64List asTypedList(
    int length, {
    Pointer<NativeFinalizerFunction>? finalizer,
    Pointer<Void>? token,
  }) => throw UnsupportedError('DoublePointer.asTypedList');
}

@patch
extension BoolPointer on Pointer<Bool> {
  @patch
  bool get value => throw UnsupportedError('BoolPointer.value');
  @patch
  set value(bool value) => throw UnsupportedError('BoolPointer.value=');
  @patch
  bool operator [](int index) => throw UnsupportedError('BoolPointer.[]');
  @patch
  void operator []=(int index, bool value) =>
      throw UnsupportedError('BoolPointer.[]=');
}

@patch
extension Int8Array on Array<Int8> {
  @patch
  int operator [](int index) => throw UnsupportedError('Int8Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int8Array.[]=');
  @patch
  Int8List get elements => throw UnsupportedError('Int8Array.elements');
}

@patch
extension Int16Array on Array<Int16> {
  @patch
  int operator [](int index) => throw UnsupportedError('Int16Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int16Array.[]=');
  @patch
  Int16List get elements => throw UnsupportedError('Int16Array.elements');
}

@patch
extension Int32Array on Array<Int32> {
  @patch
  int operator [](int index) => throw UnsupportedError('Int32Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int32Array.[]=');
  @patch
  Int32List get elements => throw UnsupportedError('Int32Array.elements');
}

@patch
extension Int64Array on Array<Int64> {
  @patch
  int operator [](int index) => throw UnsupportedError('Int64Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Int64Array.[]=');
  @patch
  Int64List get elements => throw UnsupportedError('Int64Array.elements');
}

@patch
extension Uint8Array on Array<Uint8> {
  @patch
  int operator [](int index) => throw UnsupportedError('Uint8Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint8Array.[]=');
  @patch
  Uint8List get elements => throw UnsupportedError('Uint8Array.elements');
}

@patch
extension Uint16Array on Array<Uint16> {
  @patch
  int operator [](int index) => throw UnsupportedError('Uint16Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint16Array.[]=');
  @patch
  Uint16List get elements => throw UnsupportedError('Uint16Array.elements');
}

@patch
extension Uint32Array on Array<Uint32> {
  @patch
  int operator [](int index) => throw UnsupportedError('Uint32Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint32Array.[]=');
  @patch
  Uint32List get elements => throw UnsupportedError('Uint32Array.elements');
}

@patch
extension Uint64Array on Array<Uint64> {
  @patch
  int operator [](int index) => throw UnsupportedError('Uint64Array.[]');
  @patch
  void operator []=(int index, int value) =>
      throw UnsupportedError('Uint64Array.[]=');
  @patch
  Uint64List get elements => throw UnsupportedError('Uint64Array.elements');
}

@patch
extension FloatArray on Array<Float> {
  @patch
  double operator [](int index) => throw UnsupportedError('FloatArray.[]');
  @patch
  void operator []=(int index, double value) =>
      throw UnsupportedError('FloatArray.[]=');
  @patch
  Float32List get elements => throw UnsupportedError('FloatArray.elements');
}

@patch
extension DoubleArray on Array<Double> {
  @patch
  double operator [](int index) => throw UnsupportedError('DoubleArray.[]');
  @patch
  void operator []=(int index, double value) =>
      throw UnsupportedError('DoubleArray.[]=');
  @patch
  Float64List get elements => throw UnsupportedError('DoubleArray.elements');
}

@patch
extension BoolArray on Array<Bool> {
  @patch
  bool operator [](int index) => throw UnsupportedError('BoolArray.[]');
  @patch
  void operator []=(int index, bool value) =>
      throw UnsupportedError('BoolArray.[]=');
  @patch
  List<bool> get elements => throw UnsupportedError('BoolArray.elements');
}

@patch
extension Int8ListAddress on Int8List {
  @patch
  Pointer<Int8> get address =>
      throw UnsupportedError('Int8ListAddress.address');
}

@patch
extension Int16ListAddress on Int16List {
  @patch
  Pointer<Int16> get address =>
      throw UnsupportedError('Int16ListAddress.address');
}

@patch
extension Int32ListAddress on Int32List {
  @patch
  Pointer<Int32> get address =>
      throw UnsupportedError('Int32ListAddress.address');
}

@patch
extension Int64ListAddress on Int64List {
  @patch
  Pointer<Int64> get address =>
      throw UnsupportedError('Int64ListAddress.address');
}

@patch
extension Uint8ListAddress on Uint8List {
  @patch
  Pointer<Uint8> get address =>
      throw UnsupportedError('Uint8ListAddress.address');
}

@patch
extension Uint16ListAddress on Uint16List {
  @patch
  Pointer<Uint16> get address =>
      throw UnsupportedError('Uint16ListAddress.address');
}

@patch
extension Uint32ListAddress on Uint32List {
  @patch
  Pointer<Uint32> get address =>
      throw UnsupportedError('Uint32ListAddress.address');
}

@patch
extension Uint64ListAddress on Uint64List {
  @patch
  Pointer<Uint64> get address =>
      throw UnsupportedError('Uint64ListAddress.address');
}

@patch
extension Float32ListAddress on Float32List {
  @patch
  Pointer<Float> get address =>
      throw UnsupportedError('Float32ListAddress.address');
}

@patch
extension Float64ListAddress on Float64List {
  @patch
  Pointer<Double> get address =>
      throw UnsupportedError('Float64ListAddress.address');
}

@patch
extension PointerPointer<T extends NativeType> on Pointer<Pointer<T>> {
  @patch
  Pointer<T> get value => throw UnsupportedError('PointerPointer.value');
  @patch
  set value(Pointer<T> value) =>
      throw UnsupportedError('PointerPointer.value=');
  @patch
  Pointer<T> operator [](int index) =>
      throw UnsupportedError('PointerPointer.[]');
  @patch
  void operator []=(int index, Pointer<T> value) =>
      throw UnsupportedError('PointerPointer.[]=');
  @patch
  Pointer<Pointer<T>> elementAt(int index) =>
      throw UnsupportedError('PointerPointer.elementAt');
  @patch
  Pointer<Pointer<T>> operator +(int offset) =>
      throw UnsupportedError('PointerPointer.+');
  @patch
  Pointer<Pointer<T>> operator -(int offset) =>
      throw UnsupportedError('PointerPointer.-');
}

@patch
extension StructPointer<T extends Struct> on Pointer<T> {
  @patch
  T get ref => throw UnsupportedError('StructPointer.ref');
  @patch
  set ref(T value) => throw UnsupportedError('StructPointer.ref=');

  @patch
  T refWithFinalizer(
    Pointer<NativeFinalizerFunction> finalizer, {
    Pointer<Void>? token,
  }) => throw UnsupportedError('StructPointer.refWithFinalizer');

  @patch
  T operator [](int index) =>
      throw UnsupportedError('StructPointer.operator []');

  @patch
  void operator []=(int index, T value) =>
      throw UnsupportedError('StructPointer.operator []=');

  @patch
  Pointer<T> elementAt(int index) =>
      throw UnsupportedError('StructPointer.elementAt');

  @patch
  Pointer<T> operator +(int offset) =>
      throw UnsupportedError('StructPointer.operator +');

  @patch
  Pointer<T> operator -(int offset) =>
      throw UnsupportedError('StructPointer.operator -');
}

@patch
extension UnionPointer<T extends Union> on Pointer<T> {
  @patch
  T get ref => throw UnsupportedError('UnionPointer.ref');
  @patch
  set ref(T value) => throw UnsupportedError('UnionPointer.ref=');

  @patch
  T refWithFinalizer(
    Pointer<NativeFinalizerFunction> finalizer, {
    Pointer<Void>? token,
  }) => throw UnsupportedError('UnionPointer.refWithFinalizer');

  @patch
  T operator [](int index) =>
      throw UnsupportedError('UnionPointer.operator []');

  @patch
  void operator []=(int index, T value) =>
      throw UnsupportedError('UnionPointer.operator []=');

  @patch
  Pointer<T> elementAt(int index) =>
      throw UnsupportedError('UnionPointer.elementAt');

  @patch
  Pointer<T> operator +(int offset) =>
      throw UnsupportedError('UnionPointer.operator +');

  @patch
  Pointer<T> operator -(int offset) =>
      throw UnsupportedError('UnionPointer.operator -');
}

@patch
extension AbiSpecificIntegerPointer<T extends AbiSpecificInteger>
    on Pointer<T> {
  @patch
  T get value => throw UnsupportedError('AbiSpecificIntegerPointer.value');
  @patch
  set value(T value) =>
      throw UnsupportedError('AbiSpecificIntegerPointer.value=');

  @patch
  T operator [](int index) =>
      throw UnsupportedError('AbiSpecificIntegerPointer.operator []');

  @patch
  void operator []=(int index, T value) =>
      throw UnsupportedError('AbiSpecificIntegerPointer.operator []=');

  @patch
  Pointer<T> elementAt(int index) =>
      throw UnsupportedError('AbiSpecificIntegerPointer.elementAt');

  @patch
  Pointer<T> operator +(int offset) =>
      throw UnsupportedError('AbiSpecificIntegerPointer.operator +');

  @patch
  Pointer<T> operator -(int offset) =>
      throw UnsupportedError('AbiSpecificIntegerPointer.operator -');
}

@patch
extension PointerArray<T extends NativeType> on Array<Pointer<T>> {
  @patch
  Pointer<T> operator [](int index) =>
      throw UnsupportedError('PointerArray.operator []');

  @patch
  void operator []=(int index, Pointer<T> value) =>
      throw UnsupportedError('PointerArray.operator []=');

  @patch
  List<Pointer<T>> get elements =>
      throw UnsupportedError('PointerArray.elements');
}

@patch
extension StructArray<T extends Struct> on Array<T> {
  @patch
  Pointer<T> operator [](int index) =>
      throw UnsupportedError('StructArray.operator []');

  @patch
  List<T> get elements => throw UnsupportedError('StructArray.elements');
}

@patch
extension UnionArray<T extends Union> on Array<T> {
  @patch
  Pointer<T> operator [](int index) =>
      throw UnsupportedError('UnionArray.operator []');

  @patch
  List<T> get elements => throw UnsupportedError('UnionArray.elements');
}

@patch
extension ArrayArray<T extends NativeType> on Array<Array<T>> {
  @patch
  Array<T> operator [](int index) =>
      throw UnsupportedError('ArrayArray.operator []');

  @patch
  void operator []=(int index, Array<T> value) =>
      throw UnsupportedError('ArrayArray.operator []=');

  @patch
  List<Array<T>> get elements => throw UnsupportedError('ArrayArray.elements');
}

@patch
extension AbiSpecificIntegerArray<T extends AbiSpecificInteger> on Array<T> {
  @patch
  Array<T> operator [](int index) =>
      throw UnsupportedError('AbiSpecificIntegerArray.operator []');

  @patch
  void operator []=(int index, Array<T> value) =>
      throw UnsupportedError('AbiSpecificIntegerArray.operator []=');

  @patch
  List<int> get elements =>
      throw UnsupportedError('AbiSpecificIntegerArray.elements');
}

@patch
extension ArrayAddress<T extends NativeType> on Array<T> {
  @patch
  Pointer<T> get address => throw UnsupportedError('ArrayAddress.address');
}

@patch
extension StructAddress<T extends Struct> on T {
  @patch
  Pointer<T> get address => throw UnsupportedError('StructAddress.address');
}

@patch
extension UnionAddress<T extends Union> on T {
  @patch
  Pointer<T> get address => throw UnsupportedError('UnionAddress.address');
}

@patch
extension IntAddress on int {
  @patch
  Pointer<Never> get address => throw UnsupportedError('IntAddress.address');
}

@patch
extension DoubleAddress on double {
  @patch
  Pointer<Never> get address => throw UnsupportedError('DoubleAddress.address');
}

@patch
extension BoolAddress on bool {
  @patch
  Pointer<Never> get address => throw UnsupportedError('BoolAddress.address');
}

@patch
extension NativePort on SendPort {
  @patch
  int get nativePort => throw UnsupportedError('NativePort.nativePort');
}

@patch
class Abi {
  @patch
  factory Abi.current() => throw UnsupportedError('Abi.current');
}

@patch
extension AllocatorAlloc on Allocator {
  @patch
  Pointer<T> call<T extends SizedNativeType>([int count = 1]) =>
      throw UnsupportedError('AllocatorAlloc.call');
}

@patch
class DynamicLibrary {
  @patch
  factory DynamicLibrary.process() =>
      throw UnsupportedError('DynamicLibrary.process');
  @patch
  factory DynamicLibrary.executable() =>
      throw UnsupportedError('DynamicLibrary.executable');
  @patch
  factory DynamicLibrary.open(String path) =>
      throw UnsupportedError('DynamicLibrary.open');
  @patch
  Pointer<T> lookup<T extends NativeType>(String symbolName) =>
      throw UnsupportedError('DynamicLibrary.lookup');
  @patch
  bool providesSymbol(String symbolName) =>
      throw UnsupportedError('DynamicLibrary.providesSymbol');
  @patch
  void close() => throw UnsupportedError('DynamicLibrary.close');
  @patch
  bool operator ==(Object other) => throw UnsupportedError('DynamicLibrary.==');
  @patch
  int get hashCode => throw UnsupportedError('DynamicLibrary.hashCode');
  @patch
  Pointer<Void> get handle => throw UnsupportedError('DynamicLibrary.handle');
}

@patch
extension DynamicLibraryExtension on DynamicLibrary {
  @patch
  F lookupFunction<T extends Function, F extends Function>(
    String symbolName, {
    bool isLeaf = false,
  }) => throw UnsupportedError('DynamicLibraryExtension.lookupFunction');
}

@patch
abstract final class NativeFinalizer {
  @patch
  factory NativeFinalizer(Pointer<NativeFinalizerFunction> callback) =>
      throw UnsupportedError('NativeFinalizer');
}

@patch
void _attachAsTypedListFinalizer(
  Pointer<NativeFinalizerFunction> callback,
  Object typedList,
  Pointer<dynamic> pointer,
  int? externalSize,
) => throw UnsupportedError('_attachAsTypedListFinalizer');

@patch
class Struct {
  @patch
  static T create<T extends Struct>([TypedData? typedData, int offset = 0]) =>
      throw UnsupportedError('Struct.create');
}

@patch
class Union {
  @patch
  static T create<T extends Union>([TypedData? typedData, int offset = 0]) =>
      throw UnsupportedError('Union.create');
}

@patch
class _Compound {
  @patch
  _Compound._() : _typedDataBase = nullptr, _offsetInBytes = 0;
}
