// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=Foo
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

import 'import_name.h.0.dart' deferred as h0;

void main() async {
  await h0.loadLibrary();
  h0.deferredFoo();
}

@pragma('wasm:never-inline')
void mainFoo() {
  print('hello world');
}
