// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=mod.*Use
// functionFilter=H[0-1]
// tableFilter=cross-module-funcs
// globalFilter=H[0-1]
// typeFilter=H[0-1]
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

import 'deferred.constant.h.0.dart' deferred as h0;
import 'deferred.constant.h.1.dart' deferred as h1;

void main() async {
  // Ensure the deferred libraries are loaded.
  await h0.loadLibrary();
  await h1.loadLibrary();

  // Directly use the H0 constant in the main module.
  modMainUseH0();

  // Call to H1 module to use the constants in H1 module.
  h1.modH1UseH1();
}

@pragma('wasm:never-inline')
void modMainUseH0() {
  print(h0.constH0);
  h0.constH0.fun(1);
}
