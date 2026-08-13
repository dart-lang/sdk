// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'deferred.constant.type_use.h.0.dart';

@pragma('wasm:never-inline')
void useFooAsObject() {
  final f = Foo();
  f.printFoo();
  f.printFoo();
}
