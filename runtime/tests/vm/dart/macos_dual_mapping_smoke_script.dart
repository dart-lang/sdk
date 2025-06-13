// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:ffi';

int foo(int v) {
  return v + 41;
}

void main(List<String> args) {
  // Use some FFI callbacks to test that image pages are correctly setup.
  final nativeCallable = NativeCallable<Int32 Function(Int32)>.isolateLocal(
    foo,
    exceptionalReturn: 0,
  );
  final result = nativeCallable.nativeFunction.asFunction<int Function(int)>()(
    1,
  );
  nativeCallable.close();

  final String encoded = base64.encode(args[0].codeUnits);
  final String decoded = String.fromCharCodes(base64.decode(encoded));
  print('$result$decoded');
}
