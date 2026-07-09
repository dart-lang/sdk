// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// functionFilter=mainImpl
// functionFilter=mod.*Use
// functionFilter=MyConstClass
// functionFilter=shared-const
// tableFilter=cross-module-funcs
// globalFilter=MyConstClass
// globalFilter=shared-const
// type=MyConstClass
// compilerOption=--enable-deferred-loading
// compilerOption=--no-minify

import 'deferred.constant.multi_module_use.h.0.dart' deferred as h0;
import 'deferred.constant.multi_module_use.h.1.dart' deferred as h1;

void main() async {
  await h0.loadLibrary();
  await h1.loadLibrary();

  final returnShared = int.parse('1') == 0;
  mainImpl(returnShared);
}

@pragma('wasm:never-inline')
void mainImpl(bool returnShared) {
  if (!identical(h0.modH0Use(returnShared), h1.modH1Use(returnShared))) {
    throw 'bad';
  }
}
