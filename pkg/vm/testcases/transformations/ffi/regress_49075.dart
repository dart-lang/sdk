// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

Future<void> main(List<String> arguments) async {
  // ignore: unused_local_variable
  final myFinalizable = await MyFinalizable();
}

class MyFinalizable implements Finalizable {
  MyFinalizable();
}
