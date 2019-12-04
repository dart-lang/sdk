// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// SharedObjects=ffi_test_functions

import 'dart:ffi';

import 'dylib_utils.dart';

DynamicLibrary ffiTestFunctions = dlopenPlatformSpecific("ffi_test_functions");

final triggerGc = ffiTestFunctions
    .lookupFunction<Void Function(), void Function()>("TriggerGC");

main(List<String> args) {
  final foo = [Float(), Double(), Uint8()];
  triggerGc();
  print(foo);
}
