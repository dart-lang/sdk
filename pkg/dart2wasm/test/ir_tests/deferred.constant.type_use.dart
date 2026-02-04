// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=useFoo
// tableFilter=static[0-9]+
// globalFilter=Foo
// typeFilter=Foo
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

import 'deferred.constant.type_use.h.0.dart';
import 'deferred.constant.type_use.h.1.dart' deferred as h1;

void main() async {
  // Ensure the deferred libraries are loaded.
  await h1.loadLibrary();

  useFoo();
}

@pragma('wasm:never-inline')
void useFoo() {
  // We use `Foo` as type but that doesn't mean
  // => This shouldn't require the code for `Foo` to be bundled with the main
  // module.
  useFooAsType();

  // We use `Foo` code, but only via deferred library which uses `Foo`
  // directly.
  // => This should require the code for `Foo` to end up in the deferred
  // library.
  h1.useFooAsObject();
}

@pragma('wasm:never-inline')
void useFooAsType() {
  print(Foo);
}
