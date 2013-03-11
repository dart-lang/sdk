// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test of the graph segmentation algorithm used by deferred loading
// to determine which elements can be deferred and which libraries
// much be included in the initial download (loaded eagerly).

import 'dart:async' show Future;
import 'dart:uri' show Uri;

import '../../../sdk/lib/_internal/compiler/implementation/apiimpl.dart'
       show Compiler;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       as dart2js;

import '../../../sdk/lib/_internal/compiler/implementation/filenames.dart'
       show getCurrentDirectory;

import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart'
       show SourceFile;

import '../../../sdk/lib/_internal/compiler/implementation/source_file_provider.dart'
       show FormattingDiagnosticHandler,
            SourceFileProvider;

class MemorySourceFileProvider extends SourceFileProvider {
  Future<String> readStringFromUri(Uri resourceUri) {
    if (resourceUri.scheme != 'memory') {
      return super.readStringFromUri(resourceUri);
    }
    String source = MEMORY_SOURCE_FILES[resourceUri.path];
    // TODO(ahe): Return new Future.immediateError(...) ?
    if (source == null) throw 'No such file $resourceUri';
    String resourceName = '$resourceUri';
    this.sourceFiles[resourceName] = new SourceFile(resourceName, source);
    return new Future.immediate(source);
  }
}

void main() {
  Uri cwd = getCurrentDirectory();
  Uri script = cwd.resolve(new Options().script);
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

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

  var expando =
      deferredClasses.where((e) => e.name.slowToString() == 'Expando').single;

  var myClass =
      deferredClasses.where((e) => e.name.slowToString() == 'MyClass').single;

  var deferredLibrary = compiler.libraries['memory:deferred.dart'];

  Expect.equals(deferredLibrary, myClass.getLibrary());
  Expect.equals(compiler.coreLibrary, expando.declaration.getLibrary());
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': """
import 'dart:async';

@lazy import 'deferred.dart';

const lazy = const DeferredLibrary('deferred');

main() {
  lazy.load().then((_) {
    Expect.equals(42, new MyClass().foo(87));
  });
}

""",
  'deferred.dart': """
library deferred;

class MyClass {
  const MyClass();

  foo(x) {
    new Expando();
    return (x - 3) ~/ 2;
  }
}
""",
};
