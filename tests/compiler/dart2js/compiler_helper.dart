// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler_helper;

import 'dart:async';
import "package:expect/expect.dart";

import 'package:compiler/src/elements/elements.dart'
       as lego;
export 'package:compiler/src/elements/elements.dart';

import 'package:compiler/src/js_backend/js_backend.dart'
       as js;

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/codegen.dart';
import 'package:compiler/src/common/resolution.dart';

export 'package:compiler/src/diagnostics/messages.dart';
export 'package:compiler/src/diagnostics/source_span.dart';
export 'package:compiler/src/diagnostics/spannable.dart';

import 'package:compiler/src/types/types.dart'
       as types;
export 'package:compiler/src/types/types.dart'
       show TypeMask;

import 'package:compiler/src/util/util.dart';
export 'package:compiler/src/util/util.dart';

import 'package:compiler/src/compiler.dart'
       show Compiler;

export 'package:compiler/src/tree/tree.dart';

import 'mock_compiler.dart';
export 'mock_compiler.dart';

import 'memory_compiler.dart' hide compilerFor;

import 'output_collector.dart';
export 'output_collector.dart';

/// Compile [code] and returns either the code for [entry] or, if [returnAll] is
/// true, the code for the entire program.
///
/// If [check] is provided, it is executed on the code for [entry] before
/// returning. If [useMock] is `true` the [MockCompiler] is used for
/// compilation, otherwise the memory compiler is used.
Future<String> compile(String code,
                       {String entry: 'main',
                        bool enableTypeAssertions: false,
                        bool minify: false,
                        bool analyzeAll: false,
                        bool disableInlining: true,
                        bool trustJSInteropTypeAnnotations: false,
                        bool useMock: false,
                        void check(String generatedEntry),
                        bool returnAll: false}) async {
  OutputCollector outputCollector = returnAll ? new OutputCollector() : null;
  if (useMock) {
    // TODO(johnniwinther): Remove this when no longer needed by
    // `arithmetic_simplication_test.dart`.
    MockCompiler compiler = new MockCompiler.internal(
        enableTypeAssertions: enableTypeAssertions,
        // Type inference does not run when manually
        // compiling a method.
        disableTypeInference: true,
        enableMinification: minify,
        disableInlining: disableInlining,
        trustJSInteropTypeAnnotations: trustJSInteropTypeAnnotations,
        outputProvider: outputCollector);
    await compiler.init();
    compiler.parseScript(code);
    lego.Element element = compiler.mainApp.find(entry);
    if (element == null) return null;
    compiler.phase = Compiler.PHASE_RESOLVING;
    compiler.backend.enqueueHelpers(compiler.enqueuer.resolution,
                                    compiler.globalDependencies);
    compiler.processQueue(compiler.enqueuer.resolution, element);
    compiler.world.populate();
    compiler.backend.onResolutionComplete();
    var context = new js.JavaScriptItemCompilationContext();
    ResolutionWorkItem resolutionWork =
        new ResolutionWorkItem(element, context);
    resolutionWork.run(compiler, compiler.enqueuer.resolution);
    CodegenWorkItem work =
        new CodegenWorkItem(compiler, element, context);
    compiler.phase = Compiler.PHASE_COMPILING;
    work.run(compiler, compiler.enqueuer.codegen);
    js.JavaScriptBackend backend = compiler.backend;
    String generated = backend.getGeneratedCode(element);
    if (check != null) {
      check(generated);
    }
    return returnAll ? outputCollector.getOutput('', 'js') : generated;
  } else {
    List<String> options = <String>[
        Flags.disableTypeInference];
    if (enableTypeAssertions) {
      options.add(Flags.enableCheckedMode);
    }
    if (minify) {
      options.add(Flags.minify);
    }
    if (analyzeAll) {
      options.add(Flags.analyzeAll);
    }
    if (trustJSInteropTypeAnnotations) {
      options.add(Flags.trustJSInteropTypeAnnotations);
    }

    if (disableInlining) {
      options.add(Flags.disableInlining);
    }

    Map<String, String> source;
    if (entry != 'main') {
      source = {'main.dart': "$code\n\nmain() => $entry;" };
    } else {
      source = {'main.dart': code};
    }

    CompilationResult result = await runCompiler(
        memorySourceFiles: source,
        options: options,
        outputProvider: outputCollector);
    Expect.isTrue(result.isSuccess);
    Compiler compiler =  result.compiler;
    lego.Element element = compiler.mainApp.find(entry);
    js.JavaScriptBackend backend = compiler.backend;
    String generated = backend.getGeneratedCode(element);
    if (check != null) {
      check(generated);
    }
    return returnAll ? outputCollector.getOutput('', 'js') : generated;
  }
}

Future<String> compileAll(String code,
                          {Map<String, String> coreSource,
                           bool disableInlining: true,
                           bool trustTypeAnnotations: false,
                           bool minify: false,
                           int expectedErrors,
                           int expectedWarnings}) {
  Uri uri = new Uri(scheme: 'source');
  OutputCollector outputCollector = new OutputCollector();
  MockCompiler compiler = compilerFor(
      code, uri, coreSource: coreSource, disableInlining: disableInlining,
      minify: minify, expectedErrors: expectedErrors,
      trustTypeAnnotations: trustTypeAnnotations,
      expectedWarnings: expectedWarnings,
      outputProvider: outputCollector);
  compiler.diagnosticHandler = createHandler(compiler, code);
  return compiler.run(uri).then((compilationSucceded) {
    Expect.isTrue(compilationSucceded,
                  'Unexpected compilation error(s): '
                  '${compiler.diagnosticCollector.errors}');
    return outputCollector.getOutput('', 'js');
  });
}

Future compileAndCheck(String code,
                       String name,
                       check(MockCompiler compiler, lego.Element element),
                       {int expectedErrors, int expectedWarnings}) {
  Uri uri = new Uri(scheme: 'source');
  MockCompiler compiler = compilerFor(code, uri,
      expectedErrors: expectedErrors,
      expectedWarnings: expectedWarnings);
  return compiler.run(uri).then((_) {
    lego.Element element = findElement(compiler, name);
    return check(compiler, element);
  });
}

Future compileSources(Map<String, String> sources,
               check(MockCompiler compiler)) {
  Uri base = new Uri(scheme: 'source');
  Uri mainUri = base.resolve('main.dart');
  String mainCode = sources['main.dart'];
  Expect.isNotNull(mainCode, 'No source code found for "main.dart"');
  MockCompiler compiler = compilerFor(mainCode, mainUri);
  sources.forEach((String path, String code) {
    if (path == 'main.dart') return;
    compiler.registerSource(base.resolve(path), code);
  });

  return compiler.run(mainUri).then((_) {
    return check(compiler);
  });
}

lego.Element findElement(compiler, String name, [Uri library]) {
  lego.LibraryElement lib = compiler.mainApp;
  if (library != null) {
    lib = compiler.libraryLoader.lookupLibrary(library);
    Expect.isNotNull(lib, 'Could not locate library $library.');
  }
  var element = lib.find(name);
  Expect.isNotNull(element, 'Could not locate $name.');
  return element;
}

types.TypeMask findTypeMask(compiler, String name,
                            [String how = 'nonNullExact']) {
  var sourceName = name;
  var element = compiler.mainApp.find(sourceName);
  if (element == null) {
    element = compiler.backend.helpers.interceptorsLibrary.find(sourceName);
  }
  if (element == null) {
    element = compiler.coreLibrary.find(sourceName);
  }
  Expect.isNotNull(element, 'Could not locate $name');
  switch (how) {
    case 'exact':
      return new types.TypeMask.exact(element, compiler.world);
    case 'nonNullExact':
      return new types.TypeMask.nonNullExact(element, compiler.world);
    case 'subclass':
      return new types.TypeMask.subclass(element, compiler.world);
    case 'nonNullSubclass':
      return new types.TypeMask.nonNullSubclass(element, compiler.world);
    case 'subtype':
      return new types.TypeMask.subtype(element, compiler.world);
    case 'nonNullSubtype':
      return new types.TypeMask.nonNullSubtype(element, compiler.world);
  }
  Expect.fail('Unknown TypeMask constructor $how');
  return null;
}

String anyIdentifier = "[a-zA-Z][a-zA-Z0-9]*";

String getIntTypeCheck(String variable) {
  return "\\($variable ?!== ?\\($variable ?\\| ?0\\)|"
         "\\($variable ?>>> ?0 ?!== ?$variable";
}

String getNumberTypeCheck(String variable) {
  return """\\(typeof $variable ?!== ?"number"\\)""";
}

void checkNumberOfMatches(Iterator it, int nb) {
  bool hasNext = it.moveNext();
  for (int i = 0; i < nb; i++) {
    Expect.isTrue(hasNext, "Found less than $nb matches");
    hasNext = it.moveNext();
  }
  Expect.isFalse(hasNext, "Found more than $nb matches");
}

Future compileAndMatch(String code, String entry, RegExp regexp,
                       {bool useMock: false}) {
  return compile(code, entry: entry,
      useMock: useMock,
      check: (String generated) {
    Expect.isTrue(regexp.hasMatch(generated),
                  '"$generated" does not match /$regexp/');
  });
}

Future compileAndDoNotMatch(String code, String entry, RegExp regexp) {
  return compile(code, entry: entry, check: (String generated) {
    Expect.isFalse(regexp.hasMatch(generated),
                   '"$generated" has a match in /$regexp/');
  });
}

int length(Link link) => link.isEmpty ? 0 : length(link.tail) + 1;

// Does a compile and then a match where every 'x' is replaced by something
// that matches any variable, and every space is optional.
Future compileAndMatchFuzzy(String code, String entry, String regexp) {
  return compileAndMatchFuzzyHelper(code, entry, regexp, true);
}

Future compileAndDoNotMatchFuzzy(String code, String entry, String regexp) {
  return compileAndMatchFuzzyHelper(code, entry, regexp, false);
}

Future compileAndMatchFuzzyHelper(
    String code, String entry, String regexp, bool shouldMatch) {
  return compile(code, entry: entry, check: (String generated) {
    final xRe = new RegExp('\\bx\\b');
    regexp = regexp.replaceAll(xRe, '(?:$anyIdentifier)');
    final spaceRe = new RegExp('\\s+');
    regexp = regexp.replaceAll(spaceRe, '(?:\\s*)');
    if (shouldMatch) {
      Expect.isTrue(new RegExp(regexp).hasMatch(generated));
    } else {
      Expect.isFalse(new RegExp(regexp).hasMatch(generated));
    }
  });
}
