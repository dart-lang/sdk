// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "internal_patch.dart";

@pragma("wasm:entry-point")
class ClassID {
  external static int getID(Object? value);

  @pragma("wasm:class-id", "dart.typed_data#_ExternalUint8Array")
  external static int get cidExternalUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8List")
  external static int get cidUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ArrayView")
  external static int get cidUint8ArrayView;
  @pragma("wasm:class-id", "dart.core#Object")
  external static int get cidObject;
  @pragma("wasm:class-id", "dart.async#Future")
  external static int get cidFuture;
  @pragma("wasm:class-id", "dart.core#Function")
  external static int get cidFunction;

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
  @pragma("wasm:class-id", "dart.core#_GenericFunctionType")
  external static int get cidGenericFunctionType;

  // Dummy, only used by VM-specific hash table code.
  static final int numPredefinedCids = 1;
}
