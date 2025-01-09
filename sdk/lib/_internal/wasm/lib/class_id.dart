// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "internal_patch.dart";

@pragma("wasm:entry-point")
class ClassID {
  @pragma("wasm:intrinsic")
  external static WasmI32 getID(Object? value);

  @pragma("wasm:class-id", "dart.typed_data#_ExternalUint8Array")
  external static WasmI32 get cidExternalUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8List")
  external static WasmI32 get cidUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ArrayView")
  external static WasmI32 get cidUint8ArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Uint8ClampedList")
  external static WasmI32 get cidUint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedList")
  external static WasmI32 get cid_Uint8ClampedList;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ClampedArrayView")
  external static WasmI32 get cidUint8ClampedArrayView;
  @pragma("wasm:class-id", "dart.typed_data#Int8List")
  external static WasmI32 get cidInt8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8List")
  external static WasmI32 get cid_Int8List;
  @pragma("wasm:class-id", "dart.typed_data#_Int8ArrayView")
  external static WasmI32 get cidInt8ArrayView;
  @pragma("wasm:class-id", "dart.async#Future")
  external static WasmI32 get cidFuture;
  @pragma("wasm:class-id", "dart.core#Function")
  external static WasmI32 get cidFunction;
  @pragma("wasm:class-id", "dart.core#_Closure")
  external static WasmI32 get cid_Closure;
  @pragma("wasm:class-id", "dart.core#List")
  external static WasmI32 get cidList;
  @pragma("wasm:class-id", "dart._list#ModifiableFixedLengthList")
  external static WasmI32 get cidFixedLengthList;
  @pragma("wasm:class-id", "dart._list#WasmListBase")
  external static WasmI32 get cidListBase;
  @pragma("wasm:class-id", "dart._list#GrowableList")
  external static WasmI32 get cidGrowableList;
  @pragma("wasm:class-id", "dart._list#ImmutableList")
  external static WasmI32 get cidImmutableList;
  @pragma("wasm:class-id", "dart.core#Record")
  external static WasmI32 get cidRecord;
  @pragma("wasm:class-id", "dart.core#Symbol")
  external static WasmI32 get cidSymbol;

  // Class IDs for RTI Types.
  @pragma("wasm:class-id", "dart.core#_BottomType")
  external static WasmI32 get cidBottomType;
  @pragma("wasm:class-id", "dart.core#_TopType")
  external static WasmI32 get cidTopType;
  @pragma("wasm:class-id", "dart.core#_FutureOrType")
  external static WasmI32 get cidFutureOrType;
  @pragma("wasm:class-id", "dart.core#_InterfaceType")
  external static WasmI32 get cidInterfaceType;
  @pragma("wasm:class-id", "dart.core#_AbstractFunctionType")
  external static WasmI32 get cidAbstractFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionType")
  external static WasmI32 get cidFunctionType;
  @pragma("wasm:class-id", "dart.core#_FunctionTypeParameterType")
  external static WasmI32 get cidFunctionTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_InterfaceTypeParameterType")
  external static WasmI32 get cidInterfaceTypeParameterType;
  @pragma("wasm:class-id", "dart.core#_AbstractRecordType")
  external static WasmI32 get cidAbstractRecordType;
  @pragma("wasm:class-id", "dart.core#_RecordType")
  external static WasmI32 get cidRecordType;
  @pragma("wasm:class-id", "dart.core#_NamedParameter")
  external static WasmI32 get cidNamedParameter;

  // From this class id onwards, all concrete classes are interface classes and
  // do not need to be masqueraded.
  external static WasmI32 get firstNonMasqueradedInterfaceClassCid;

  // Dummy, only used by VM-specific hash table code.
  static final WasmI32 numPredefinedCids = 1.toWasmI32();
}
