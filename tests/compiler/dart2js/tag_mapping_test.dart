// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of import tag to library mapping.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';

const MAIN_CODE = """
import 'library.dart';

main() {
}
""";

const LIB_CODE = """
library lib;
""";

void main() {
  var sources = <String, String>{
    'main.dart': MAIN_CODE,
    'library.dart': LIB_CODE,
  };

  asyncTest(() => compileSources(sources, (MockCompiler compiler) {
    LibraryElement mainApp = compiler.libraries['source:/main.dart'];
    LibraryElement lib = compiler.libraries['source:/library.dart'];
    Expect.isNotNull(mainApp, 'Could not find main.dart library');
    Expect.isNotNull(lib, 'Could not find library.dart library');

    Import tag = mainApp.tags.single;
    Expect.isNotNull(tag, 'Could not find import tag in $mainApp');

    // Test that we can get from the import tag in main.dart to the
    // library element representing library.dart.
    Expect.identical(lib, mainApp.getLibraryFromTag(tag));
  }));
}
