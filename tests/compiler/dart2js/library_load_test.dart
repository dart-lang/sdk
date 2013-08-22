// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'mock_compiler.dart';

class ScanMockCompiler extends MockCompiler {
  ScanMockCompiler() {
    isolateHelperLibrary = null;
    foreignLibrary = null;
  }

  LibraryElement scanBuiltinLibrary(String filename) {
    return createLibrary(filename, "main(){}");
  }
}

void main() {
  Compiler compiler = new ScanMockCompiler();
  Expect.equals(null, compiler.isolateHelperLibrary);
  Expect.equals(null, compiler.foreignLibrary);
  compiler.onLibraryLoaded(mockLibrary(compiler, "mock"),
			    new Uri(scheme: 'dart', path: '_isolate_helper'));
  Expect.isTrue(compiler.isolateHelperLibrary != null);
  compiler.onLibraryLoaded(mockLibrary(compiler, "mock"),
			    new Uri(scheme: 'dart', path: '_foreign_helper'));
  Expect.isTrue(compiler.isolateHelperLibrary != null);
  Expect.equals(new Uri(scheme: 'dart', path: '_isolate_helper'),
		 compiler.isolateHelperLibrary.canonicalUri);
  Expect.isTrue(compiler.foreignLibrary != null);
  Expect.equals(new Uri(scheme: 'dart', path: '_foreign_helper'),
		 compiler.foreignLibrary.canonicalUri);
}
