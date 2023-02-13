// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

@pragma("wasm:entry-point")
class ClassID {
  external static int getID(Object? value);

  @pragma("wasm:class-id", "dart.typed_data#_ExternalUint8Array")
  external static int get cidExternalUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8List")
  external static int get cidUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ArrayView")
  external static int get cidUint8ArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Uint8ClampedList")
  external static int get cidUint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedList")
  external static int get cid_Uint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedArrayView")
  external static int get cidUint8ClampedArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Int8List")
  external static int get cidInt8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8List")
  external static int get cid_Int8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8ArrayView")
  external static int get cidInt8ArrayView;
  @pragma("wasm:class-id", "dart.core#Object")
  external static int get cidObject;
  @pragma("wasm:class-id", "dart.async#Future")
  external static int get cidFuture;
  @pragma("wasm:class-id", "dart.core#Function")
  external static int get cidFunction;
  @pragma("wasm:class-id", "dart.core#_Closure")
  external static int get cid_Closure;
  @pragma("wasm:class-id", "dart.core#_List")
  external static int get cidFixedLengthList;
  @pragma("wasm:class-id", "dart.core#_ListBase")
  external static int get cidListBase;
  @pragma("wasm:class-id", "dart.core#_GrowableList")
  external static int get cidGrowableList;
  @pragma("wasm:class-id", "dart.core#_ImmutableList")
  external static int get cidImmutableList;
  @pragma("wasm:class-id", "dart.core#Record")
  external static int get cidRecord;

  // Class IDs for RTI Types.
  @pragma("wasm:class-id", "dart.core#_NeverType")
  external static int get cidNeverType;
  @pragma("wasm:class-id", "dart.core#_DynamicType")
  external static int get cidDynamicType;
  @pragma("wasm:class-id", "dart.core#_VoidType")
  external static int get cidVoidType;
  @pragma("wasm:class-id", "dart.core#_NullType")
  external static int get cidNullType;
  @pragma("wasm:class-id", "dart.core#_FutureOrType")
  external static int get cidFutureOrType;
  @pragma("wasm:class-id", "dart.core#_InterfaceType")
  external static int get cidInterfaceType;
  @pragma("wasm:class-id", "dart.core#_FunctionType")
  external static int get cidFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionTypeParameterType")
  external static int get cidFunctionTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_InterfaceTypeParameterType")
  external static int get cidInterfaceTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_RecordType")
  external static int get cidRecordType;

  // Dummy, only used by VM-specific hash table code.
  static final int numPredefinedCids = 1;
}
