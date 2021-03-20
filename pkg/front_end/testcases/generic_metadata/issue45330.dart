// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part 'issue45330_lib.dart';

void genericMethod<T>() {}

testInMain() {
  genericMethod<void Function<T extends T>()>();
}

main() {}
