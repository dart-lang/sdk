// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// part of "internal_patch.dart";

@pragma("wasm:entry-point")
class ClassID {
  external static int getID(Object value);

  @pragma("wasm:class-id", "dart.typed_data#_ExternalUint8Array")
  external static int get cidExternalUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8List")
  external static int get cidUint8Array;
  @pragma("wasm:class-id", "dart.typed_data#_Uint8ArrayView")
  external static int get cidUint8ArrayView;

  // Dummy, only used by VM-specific hash table code.
  static final int numPredefinedCids = 1;
}
