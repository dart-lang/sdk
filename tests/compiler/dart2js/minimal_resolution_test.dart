// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that elements are not needlessly required by dart2js.

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/enqueue.dart';
import 'package:expect/expect.dart';
import 'memory_compiler.dart';

main() {
  asyncTest(() async {
    await analyze('main() {}');
    await analyze('main() => proxy;', proxyConstantComputed: true);
    await analyze('@deprecated main() {}');
    await analyze('@deprecated main() => deprecated;', deprecatedClass: true);
    await analyze('main() => deprecated;', deprecatedClass: true);
  });
}

void checkInstantiated(Compiler compiler, ClassElement cls, bool expected) {
  ResolutionEnqueuer enqueuer = compiler.enqueuer.resolution;
  bool isInstantiated =
      enqueuer.worldBuilder.directlyInstantiatedClasses.contains(cls);
  bool isProcessed = enqueuer.processedClasses.contains(cls);
  Expect.equals(expected, isInstantiated,
      'Unexpected instantiation state of class $cls.');
  Expect.equals(
      expected, isProcessed, 'Unexpected processing state of class $cls.');
}

analyze(String code,
    {bool proxyConstantComputed: false, bool deprecatedClass: false}) async {
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': code}, options: ['--analyze-only']);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  Expect.equals(
      proxyConstantComputed,
      compiler.resolution.wasProxyConstantComputedTestingOnly,
      "Unexpected computation of proxy constant.");

  LibraryElement coreLibrary =
      compiler.frontendStrategy.commonElements.coreLibrary;
  checkInstantiated(
      compiler, coreLibrary.find('_Proxy'), proxyConstantComputed);
  checkInstantiated(compiler, coreLibrary.find('Deprecated'), deprecatedClass);

  LibraryElement jsHelperLibrary =
      compiler.libraryLoader.lookupLibrary(Uris.dart__js_helper);
  jsHelperLibrary.forEachLocalMember((Element element) {
    Uri uri = element.compilationUnit.script.resourceUri;
    if (element.isClass && uri.path.endsWith('annotations.dart')) {
      checkInstantiated(compiler, element, false);
    }
  });
}
