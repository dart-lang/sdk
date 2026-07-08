// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: library_private_types_in_public_api

library get_object_rpc;

import 'dart:developer';
import 'dart:ffi';
import 'dart:typed_data';

import 'common/test_helper.dart';

abstract base mixin class _DummyAbstractBaseClass {
  void dummyFunction(int a, [bool b = false]);
}

base class _DummyClass extends _DummyAbstractBaseClass {
  // ignore: unused_field
  static var dummyVar = 11;
  final List<String> dummyList = List<String>.filled(20, '');
  // ignore: unused_field
  static var dummyVarWithInit = foo();
  late String dummyLateVarWithInit = 'bar';
  late String dummyLateVar;
  int get dummyVarGetter => dummyVar;
  set dummyVarSetter(int value) => dummyVar = value;
  @override
  void dummyFunction(int a, [bool b = false]) {}
  void dummyGenericFunction<K, V>(K a, {required V param}) {}
  static List foo() => List<String>.filled(20, '');
}

base class _DummyGenericSubClass<T> extends _DummyClass {}

final class _DummyFinalClass extends _DummyClass {}

sealed class _DummySealedClass {}

interface class _DummyInterfaceClass extends _DummySealedClass {}

base mixin _DummyBaseMixin {
  void dummyMethod1() {}
}

mixin _DummyMixin {
  void dummyMethod2() {}
}

final class _DummyClassWithMixins with _DummyBaseMixin, _DummyMixin {}

void warmup() {
  // Increase the usage count of these methods.
  _DummyClass().dummyFunction(0);
  _DummyClass().dummyGenericFunction<Object, dynamic>(0, param: 0);
}

@pragma('vm:entry-point')
String getChattanooga() => 'Chattanooga';

@pragma('vm:entry-point')
List<int> getList() => [3, 2, 1];

@pragma('vm:entry-point')
Map<String, int> getMap() => {'x': 3, 'y': 4, 'z': 5};

@pragma('vm:entry-point')
Set<int> getSet() => {6, 7, 8};

@pragma('vm:entry-point')
Uint8List getUint8List() => Uint8List.fromList([3, 2, 1]);

@pragma('vm:entry-point')
Uint64List getUint64List() => Uint64List.fromList([3, 2, 1]);

@pragma('vm:entry-point')
(int, double, {int x, double y}) getRecord() => (1, x: 2, 3.0, y: 4.0);

@pragma('vm:entry-point')
_DummyClass getDummyClass() => _DummyClass();

@pragma('vm:entry-point')
_DummyFinalClass getDummyFinalClass() => _DummyFinalClass();

@pragma('vm:entry-point')
_DummyGenericSubClass<Object> getDummyGenericSubClass() =>
    _DummyGenericSubClass<Object>();

@pragma('vm:entry-point')
_DummyInterfaceClass getDummyInterfaceClass() => _DummyInterfaceClass();

@pragma('vm:entry-point')
_DummyClassWithMixins getDummyClassWithMixins() => _DummyClassWithMixins();

@pragma('vm:entry-point')
UserTag getUserTag() => UserTag('Test Tag');

@pragma('vm:entry-point')
Finalizer getFinalizer() {
  // Ensure at least one FinalizerEntry.
  finalizer.attach(
    nonGcedObject,
    _DummyClass(),
    detach: _DummyClass(),
  );
  return finalizer;
}

final finalizer = Finalizer((p0) {});
final nonGcedObject = _DummyClass();

@pragma('vm:entry-point')
NativeFinalizer getNativeFinalizer() {
  // Avoid adding entries here to avoid running on shutdown
  return nativeFinalizer;
}

final nativeFinalizer =
    NativeFinalizer(DynamicLibrary.process().lookup('free'));

@pragma('vm:entry-point')
Pointer<Uint8> getTestPointer() {
  final address = sizeOf<IntPtr>() == 4 ? 0xdeadbeef : 0xdeadbeefdeadbeef;
  return Pointer<Uint8>.fromAddress(address);
}

@pragma('vm:entry-point')
Pointer<Uint8> getTestPointerSmall() => Pointer<Uint8>.fromAddress(0x1);

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: warmup);
}
