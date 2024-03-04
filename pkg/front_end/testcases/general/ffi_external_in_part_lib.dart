// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "ffi_external_in_part_file.dart";

// This is a number of long comments introduced to push the below
// offsets past the "legal" limit in the "owner" file.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.
// La la la la la la la la la la la la la la la la la la la la la la la.

@Native<Struct1ByteInt Function(Int8)>(symbol: 'ReturnStruct1ByteInt')
external Struct1ByteInt returnStruct1ByteIntNative(int a0);
