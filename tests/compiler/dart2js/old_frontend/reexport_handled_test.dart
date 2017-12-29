// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library reexport_handled_test;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";
import 'package:compiler/src/elements/elements.dart' show LibraryElement;
import 'mock_compiler.dart';

final exportingLibraryUri = Uri.parse('exporting.dart');
const String EXPORTING_LIBRARY_SOURCE = '''
library exporting;
var foo;
''';

final reexportingLibraryUri = Uri.parse('reexporting.dart');
const String REEXPORTING_LIBRARY_SOURCE = '''
library reexporting;
export 'exporting.dart';
''';

void main() {
  MockCompiler compiler;
  asyncTest(() => MockCompiler.create((MockCompiler c) {
        compiler = c;
        compiler.registerSource(exportingLibraryUri, EXPORTING_LIBRARY_SOURCE);
        compiler.registerSource(
            reexportingLibraryUri, REEXPORTING_LIBRARY_SOURCE);
        return compiler.libraryLoader.loadLibrary(exportingLibraryUri);
      }).then((loadedLibraries) {
        compiler.processLoadedLibraries(loadedLibraries);
        LibraryElement exportingLibrary = loadedLibraries.rootLibrary;
        Expect.isTrue(exportingLibrary.exportsHandled);
        var foo = exportingLibrary.findExported('foo');
        Expect.isNotNull(foo);
        Expect.isTrue(foo.isField);

        // Load reexporting library when exports are handled on the exporting library.
        return compiler.libraryLoader.loadLibrary(reexportingLibraryUri);
      }).then((dynamic loadedLibraries) {
        compiler.processLoadedLibraries(loadedLibraries);
        var foo = loadedLibraries.rootLibrary.findExported('foo');
        Expect.isNotNull(foo);
        Expect.isTrue(foo.isField);
      }));
}
