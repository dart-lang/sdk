// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-experiment=records

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

void main() {
  if (Platform.isWindows || Platform.isAndroid) {
    // printf is not linked in.
    return;
  }
  using((arena) {
    printf('Something\n'.toNativeUtf8(allocator: arena));
    printfInt32('Something %i\n'.toNativeUtf8(allocator: arena), 32);
    printfInt32x2('Something %i %i\n'.toNativeUtf8(allocator: arena), 32, 64);
  });
}

final printf = DynamicLibrary.executable().lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<()>),
    void Function(Pointer<Utf8>)>('printf');

final printfInt32 = DynamicLibrary.executable().lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32,)>),
    void Function(Pointer<Utf8>, int)>('printf');

final printfInt32x2 = DynamicLibrary.executable().lookupFunction<
    Void Function(Pointer<Utf8>, VarArgs<(Int32, Int32)>),
    void Function(Pointer<Utf8>, int, int)>('printf');
