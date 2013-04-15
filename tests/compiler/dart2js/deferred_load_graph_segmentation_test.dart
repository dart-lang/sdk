// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       as dart2js;

void main() {
  Uri cwd = getCurrentDirectory();
  Uri script = cwd.resolve(nativeToUriPath(new Options().script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = MEMORY_SOURCE_FILES;
  var provider = new MemorySourceFileProvider();
  var handler = new FormattingDiagnosticHandler(provider);

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   (name, extension) => null,
                                   handler.diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   ['--analyze-only']);
  compiler.run(new Uri('memory:main.dart'));
  var main = compiler.mainApp.find(dart2js.Compiler.MAIN);
  Expect.isNotNull(main, 'Could not find "main"');
  compiler.deferredLoadTask.onResolutionComplete(main);

  var deferredClasses =
      compiler.deferredLoadTask.allDeferredElements.where((e) => e.isClass())
      .toSet();

  var dateTime =
      deferredClasses
          .where((e) => e.name.slowToString() == 'DateTime').single;

  var myClass =
      deferredClasses.where((e) => e.name.slowToString() == 'MyClass').single;

  var deferredLibrary = compiler.libraries['memory:deferred.dart'];

  Expect.equals(deferredLibrary, myClass.getLibrary());
  Expect.equals(compiler.coreLibrary, dateTime.declaration.getLibrary());
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': """
import 'dart:async';

@lazy import 'deferred.dart';

const lazy = const DeferredLibrary('deferred');

main() {
  lazy.load().then((_) {
    if (42 != new MyClass().foo(87)) throw "not equal";
  });
}

""",
  'deferred.dart': """
library deferred;

class MyClass {
  const MyClass();

  foo(x) {
    new DateTime.now();
    return (x - 3) ~/ 2;
  }
}
""",
};
