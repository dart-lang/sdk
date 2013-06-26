// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that tree-shaking hasn't been turned off.

import 'package:expect/expect.dart';
import 'memory_source_file_helper.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show NullSink;

import '../../../sdk/lib/_internal/compiler/compiler.dart'
       show Diagnostic;

import 'dart:async';

main() {
  Uri script = currentDirectory.resolve(nativeToUriPath(Platform.script));
  Uri libraryRoot = script.resolve('../../../sdk/');
  Uri packageRoot = script.resolve('./packages/');

  MemorySourceFileProvider.MEMORY_SOURCE_FILES = MEMORY_SOURCE_FILES;
  var provider = new MemorySourceFileProvider();
  void diagnosticHandler(Uri uri, int begin, int end,
                         String message, Diagnostic kind) {
    if (kind == Diagnostic.VERBOSE_INFO || kind == Diagnostic.WARNING) {
      return;
    }
    throw '$uri:$begin:$end:$message:$kind';
  }

  EventSink<String> outputProvider(String name, String extension) {
    return new NullSink('$name.$extension');
  }

  Compiler compiler = new Compiler(provider.readStringFromUri,
                                   outputProvider,
                                   diagnosticHandler,
                                   libraryRoot,
                                   packageRoot,
                                   []);
  compiler.run(Uri.parse('memory:main.dart'));
  Expect.isFalse(compiler.compilationFailed);
  Expect.isFalse(compiler.enqueuer.resolution.hasEnqueuedEverything);
  Expect.isFalse(compiler.enqueuer.codegen.hasEnqueuedEverything);
  Expect.isFalse(compiler.disableTypeInference);
  Expect.isFalse(compiler.backend.hasRetainedMetadata);
}

const Map MEMORY_SOURCE_FILES = const {
  'main.dart': r"""
import 'dart:mirrors';

class Foo {
  noSuchMethod(invocation) {
    print('Invoked ${MirrorSystem.getName(invocation.memberName)}');
    return reflect('foobar').delegate(invocation);
  }
}

void main() {
  print(new Foo().substring(3));
}
""",
};
