// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'dylib_utils.dart';

final ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");
void main() {
  // Force dlopen so @Native lookups in DynamicLibrary.process() succeed.
  dlopenGlobalPlatformSpecific('ffi_test_functions');

  testMixed();
  testManyHandlesAllDifferent();
  testManyHandlesAllSame();
  testCallbackHandleCases();
}

void testHandleInReturn() {
  final string = 'foo';
  Expect.identical(string, stringFromString(string));
  Expect.identical(string, stringFromObject(string));
  Expect.identical(42, intFromInt(42));
  Expect.identical(42, intFromObject(42));
  // TODO(https://dartbug.com/49518): Uncomment the lines below when the
  // runtime checks are added.
  //
  // Expect.throws(() => stringFromObject(Object()));
  // Expect.throws(() => stringFromObject(42));
  // Expect.throws(() => intFromObject(Object()));
  // Expect.throws(() => intFromObject(string));
}

@Native<Handle Function(Handle)>(symbol: "PassObjectToC")
external String stringFromString(String arg);

@Native<Handle Function(Handle)>(symbol: "PassObjectToC")
external String stringFromObject(Object arg);

@Native<Handle Function(Handle)>(symbol: "PassObjectToC")
external int intFromInt(int arg);

@Native<Handle Function(Handle)>(symbol: "PassObjectToC")
external int intFromObject(Object arg);

void testCallbackHandleCases() {
  final o = Object();
  final s = 'foo';

  Object returnObject(Object obj) => obj;
  final nc0 = NativeCallable<Handle Function(Handle)>.isolateLocal(returnObject)
    ..keepIsolateAlive = false;
  Expect.identical(o, callClosureWithArgumentViaHandle(nc0.nativeFunction, o));
  Expect.identical(s, callClosureWithArgumentViaHandle(nc0.nativeFunction, s));
  Expect.identical(
    42,
    callClosureWithArgumentViaHandle(nc0.nativeFunction, 42),
  );
  // TODO(https://dartbug.com/49518): Uncomment the lines below when the
  // runtime checks are added.
  //
  // Expect.throws(
  //   () => callClosureWithArgumentViaHandle(nc0.nativeFunction, null),
  // );

  int returnInt(int obj) => obj;
  final nc1 = NativeCallable<Handle Function(Handle)>.isolateLocal(returnInt)
    ..keepIsolateAlive = false;
  Expect.identical(
    42,
    callClosureWithArgumentViaHandle(nc1.nativeFunction, 42),
  );
  // TODO(https://dartbug.com/49518): Uncomment the lines below when the
  // runtime checks are added.
  //
  // Expect.throws(() => callClosureWithArgumentViaHandle(nc1.nativeFunction, o));
  // Expect.throws(() => callClosureWithArgumentViaHandle(nc1.nativeFunction, s));
  // Expect.throws(
  //   () => callClosureWithArgumentViaHandle(nc1.nativeFunction, null),
  // );

  String returnString(String obj) => obj;
  final nc2 = NativeCallable<Handle Function(Handle)>.isolateLocal(returnString)
    ..keepIsolateAlive = false;
  Expect.identical(s, callClosureWithArgumentViaHandle(nc2.nativeFunction, s));
  // TODO(https://dartbug.com/49518): Uncomment the lines below when the
  // runtime checks are added.
  //
  // Expect.throws(() => callClosureWithArgumentViaHandle(nc2.nativeFunction, o));
  // Expect.throws(() => callClosureWithArgumentViaHandle(nc2.nativeFunction, 42));
  // Expect.throws(
  //   () => callClosureWithArgumentViaHandle(nc2.nativeFunction, null),
  // );
}

@Native<
  Handle Function(Pointer<NativeFunction<Handle Function(Handle)>>, Handle)
>(symbol: "CallClosureWithArgumentViaHandle")
external Object? callClosureWithArgumentViaHandle(
  Pointer<NativeFunction<Handle Function(Handle)>> callback,
  Object? argument,
);

void testMixed() {
  callUpdateNode(
    id: 42,
    label: 'A: root',
    labelAttributes: <Object>[],
    rect: Object(),
    transform: Float64List(0),
    childrenInTraversalOrder: Int32List.fromList(<int>[84, 96]),
    childrenInHitTestOrder: Int32List.fromList(<int>[96, 84]),
    actions: 0,
    flags: 0,
    maxValueLength: 0,
    currentValueLength: 0,
    textSelectionBase: 0,
    textSelectionExtent: 0,
    platformViewId: 0,
    scrollChildren: 0,
    scrollIndex: 0,
    scrollPosition: 0.0,
    scrollExtentMax: 0.0,
    scrollExtentMin: 0.0,
    elevation: 0.0,
    thickness: 0.0,
    hint: '',
    hintAttributes: <Object>[],
    value: '',
    valueAttributes: <Object>[],
    increasedValue: '',
    increasedValueAttributes: <Object>[],
    decreasedValue: '',
    decreasedValueAttributes: <Object>[],
    tooltip: 'tooltip',
    additionalActions: Int32List(0),
  );
}

void callUpdateNode({
  required int id,
  required int flags,
  required int actions,
  required int maxValueLength,
  required int currentValueLength,
  required int textSelectionBase,
  required int textSelectionExtent,
  required int platformViewId,
  required int scrollChildren,
  required int scrollIndex,
  required double scrollPosition,
  required double scrollExtentMax,
  required double scrollExtentMin,
  required double elevation,
  required double thickness,
  required Object rect,
  required String label,
  required List<Object> labelAttributes,
  required String value,
  required List<Object> valueAttributes,
  required String increasedValue,
  required List<Object> increasedValueAttributes,
  required String decreasedValue,
  required List<Object> decreasedValueAttributes,
  required String hint,
  required List<Object> hintAttributes,
  String? tooltip,
  Object? textDirection,
  required Float64List transform,
  required Int32List childrenInTraversalOrder,
  required Int32List childrenInHitTestOrder,
  required Int32List additionalActions,
}) {
  updateNode(
    nullptr,
    id,
    flags,
    actions,
    maxValueLength,
    currentValueLength,
    textSelectionBase,
    textSelectionExtent,
    platformViewId,
    scrollChildren,
    scrollIndex,
    scrollPosition,
    scrollExtentMax,
    scrollExtentMin,
    3.0,
    4.0,
    5.0,
    6.0,
    elevation,
    thickness,
    label,
    labelAttributes,
    value,
    valueAttributes,
    increasedValue,
    increasedValueAttributes,
    decreasedValue,
    decreasedValueAttributes,
    hint,
    hintAttributes,
    tooltip ?? '',
    textDirection != null ? 1 : 0,
    transform,
    childrenInTraversalOrder,
    childrenInHitTestOrder,
    additionalActions,
  );
}

@Native<
  Void Function(
    Pointer<Void>,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Int32,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Double,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Int32,
    Handle,
    Handle,
    Handle,
    Handle,
  )
>(symbol: 'SemanticsUpdateBuilderUpdateNode')
external void updateNode(
  Pointer<Void> this_,
  int id,
  int flags,
  int actions,
  int maxValueLength,
  int currentValueLength,
  int textSelectionBase,
  int textSelectionExtent,
  int platformViewId,
  int scrollChildren,
  int scrollIndex,
  double scrollPosition,
  double scrollExtentMax,
  double scrollExtentMin,
  double left,
  double top,
  double right,
  double bottom,
  double elevation,
  double thickness,
  String label,
  List<Object> labelAttributes,
  String value,
  List<Object> valueAttributes,
  String increasedValue,
  List<Object> increasedValueAttributes,
  String decreasedValue,
  List<Object> decreasedValueAttributes,
  String hint,
  List<Object> hintAttributes,
  String tooltip,
  int textDirection,
  Float64List transform,
  Int32List childrenInTraversalOrder,
  Int32List childrenInHitTestOrder,
  Int32List additionalActions,
);

void testManyHandlesAllDifferent() {
  manyHandlesAllDifferent(
    'foo0',
    'foo1',
    'foo2',
    'foo3',
    'foo4',
    'foo5',
    'foo6',
    'foo7',
    'foo8',
    'foo9',
    'foo10',
    'foo11',
    'foo12',
    'foo13',
    'foo14',
    'foo15',
    'foo16',
    'foo17',
    'foo18',
    'foo19',
  );
}

/// Only invoked with 20 different const String arguments.
@Native<
  Void Function(
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
  )
>(symbol: 'ManyHandles')
external void manyHandlesAllDifferent(
  Object a0,
  Object a1,
  Object a2,
  Object a3,
  Object a4,
  Object a5,
  Object a6,
  Object a7,
  Object a8,
  Object a9,
  Object a10,
  Object a11,
  Object a12,
  Object a13,
  Object a14,
  Object a15,
  Object a16,
  Object a17,
  Object a18,
  Object a19,
);

void testManyHandlesAllSame() {
  manyHandlesAllSame(
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
    'foo0',
  );
}

/// Only invoked with 20 equal const String arguments.
@Native<
  Void Function(
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
    Handle,
  )
>(symbol: 'ManyHandles')
external void manyHandlesAllSame(
  Object a0,
  Object a1,
  Object a2,
  Object a3,
  Object a4,
  Object a5,
  Object a6,
  Object a7,
  Object a8,
  Object a9,
  Object a10,
  Object a11,
  Object a12,
  Object a13,
  Object a14,
  Object a15,
  Object a16,
  Object a17,
  Object a18,
  Object a19,
);
