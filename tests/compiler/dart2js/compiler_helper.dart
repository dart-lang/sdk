// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding.

library compiler_helper;

import 'dart:async';
import "package:expect/expect.dart";

import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart'
       as lego;
export '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';

import '../../../sdk/lib/_internal/compiler/implementation/js_backend/js_backend.dart'
       as js;

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       as leg;
export '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show Constant,
            Message,
            MessageKind,
            Selector,
            TypedSelector,
            SourceSpan;

import '../../../sdk/lib/_internal/compiler/implementation/ssa/ssa.dart' as ssa;

import '../../../sdk/lib/_internal/compiler/implementation/types/types.dart'
       as types;
export '../../../sdk/lib/_internal/compiler/implementation/types/types.dart'
       show TypeMask;

import '../../../sdk/lib/_internal/compiler/implementation/util/util.dart';
export '../../../sdk/lib/_internal/compiler/implementation/util/util.dart';

import '../../../sdk/lib/_internal/compiler/implementation/source_file.dart';

import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart'
       show Compiler;

export '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart';

import 'mock_compiler.dart';
export 'mock_compiler.dart';

import 'parser_helper.dart';

String compile(String code, {String entry: 'main',
                             String coreSource: DEFAULT_CORELIB,
                             String interceptorsSource: DEFAULT_INTERCEPTORSLIB,
                             bool enableTypeAssertions: false,
                             bool minify: false,
                             bool analyzeAll: false,
                             bool disableInlining: true}) {
  MockCompiler compiler =
      new MockCompiler(enableTypeAssertions: enableTypeAssertions,
                       coreSource: coreSource,
                       // Type inference does not run when manually
                       // compiling a method.
                       disableTypeInference: true,
                       interceptorsSource: interceptorsSource,
                       enableMinification: minify,
                       disableInlining: disableInlining);
  compiler.parseScript(code);
  lego.Element element = compiler.mainApp.find(entry);
  if (element == null) return null;
  compiler.phase = Compiler.PHASE_RESOLVING;
  compiler.backend.enqueueHelpers(compiler.enqueuer.resolution,
                                  compiler.globalDependencies);
  compiler.processQueue(compiler.enqueuer.resolution, element);
  compiler.world.populate();
  var context = new js.JavaScriptItemCompilationContext();
  leg.ResolutionWorkItem resolutionWork =
      new leg.ResolutionWorkItem(element, context);
  resolutionWork.run(compiler, compiler.enqueuer.resolution);
  leg.CodegenWorkItem work =
      new leg.CodegenWorkItem(element, context);
  compiler.phase = Compiler.PHASE_COMPILING;
  work.run(compiler, compiler.enqueuer.codegen);
  js.JavaScriptBackend backend = compiler.backend;
  return backend.assembleCode(element);
}

// TODO(herhut): Disallow warnings and errors during compilation by default.
MockCompiler compilerFor(String code, Uri uri,
                         {bool analyzeAll: false,
                          bool analyzeOnly: false,
                          String coreSource: DEFAULT_CORELIB,
                          bool disableInlining: true,
                          int expectedErrors,
                          int expectedWarnings}) {
  MockCompiler compiler = new MockCompiler(
      analyzeAll: analyzeAll,
      analyzeOnly: analyzeOnly,
      coreSource: coreSource,
      disableInlining: disableInlining,
      expectedErrors: expectedErrors,
      expectedWarnings: expectedWarnings);
  compiler.sourceFiles[uri.toString()] =
      new StringSourceFile(uri.toString(), code);
  return compiler;
}

Future<String> compileAll(String code,
                          {String coreSource: DEFAULT_CORELIB,
                          bool disableInlining: true,
                          int expectedErrors,
                          int expectedWarnings}) {
  Uri uri = new Uri(scheme: 'source');
  MockCompiler compiler = compilerFor(
      code, uri, coreSource: coreSource, disableInlining: disableInlining,
      expectedErrors: expectedErrors, expectedWarnings: expectedWarnings);
  return compiler.runCompiler(uri).then((_) {
    Expect.isFalse(compiler.compilationFailed,
                   'Unexpected compilation error');
    return compiler.assembledCode;
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
  return compiler.runCompiler(uri).then((_) {
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

  return compiler.runCompiler(mainUri).then((_) {
    return check(compiler);
  });
}

lego.Element findElement(compiler, String name) {
  var element = compiler.mainApp.find(name);
  Expect.isNotNull(element, 'Could not locate $name.');
  return element;
}

types.TypeMask findTypeMask(compiler, String name,
                            [String how = 'nonNullExact']) {
  var sourceName = name;
  var element = compiler.mainApp.find(sourceName);
  if (element == null) {
    element = compiler.interceptorsLibrary.find(sourceName);
  }
  if (element == null) {
    element = compiler.coreLibrary.find(sourceName);
  }
  Expect.isNotNull(element, 'Could not locate $name');
  switch (how) {
    case 'exact': return new types.TypeMask.exact(element);
    case 'nonNullExact': return new types.TypeMask.nonNullExact(element);
    case 'subclass': return new types.TypeMask.subclass(element);
    case 'nonNullSubclass': return new types.TypeMask.nonNullSubclass(element);
    case 'subtype': return new types.TypeMask.subtype(element);
    case 'nonNullSubtype': return new types.TypeMask.nonNullSubtype(element);
  }
  Expect.fail('Unknown TypeMask constructor $how');
}

String anyIdentifier = "[a-zA-Z][a-zA-Z0-9]*";

String getIntTypeCheck(String variable) {
  return "\\($variable ?!== ?\\($variable ?\\| ?0\\)|"
         "\\($variable ?>>> ?0 ?!== ?$variable";
}

String getNumberTypeCheck(String variable) {
  return """\\(typeof $variable ?!== ?"number"\\)""";
}

bool checkNumberOfMatches(Iterator it, int nb) {
  bool hasNext = it.moveNext();
  for (int i = 0; i < nb; i++) {
    Expect.isTrue(hasNext, "Found less than $nb matches");
    hasNext = it.moveNext();
  }
  Expect.isFalse(hasNext, "Found more than $nb matches");
}

void compileAndMatch(String code, String entry, RegExp regexp) {
  String generated = compile(code, entry: entry);
  Expect.isTrue(regexp.hasMatch(generated),
                '"$generated" does not match /$regexp/');
}

void compileAndDoNotMatch(String code, String entry, RegExp regexp) {
  String generated = compile(code, entry: entry);
  Expect.isFalse(regexp.hasMatch(generated),
                 '"$generated" has a match in /$regexp/');
}

int length(Link link) => link.isEmpty ? 0 : length(link.tail) + 1;

// Does a compile and then a match where every 'x' is replaced by something
// that matches any variable, and every space is optional.
void compileAndMatchFuzzy(String code, String entry, String regexp) {
  compileAndMatchFuzzyHelper(code, entry, regexp, true);
}

void compileAndDoNotMatchFuzzy(String code, String entry, String regexp) {
  compileAndMatchFuzzyHelper(code, entry, regexp, false);
}

void compileAndMatchFuzzyHelper(
    String code, String entry, String regexp, bool shouldMatch) {
  String generated = compile(code, entry: entry);
  final xRe = new RegExp('\\bx\\b');
  regexp = regexp.replaceAll(xRe, '(?:$anyIdentifier)');
  final spaceRe = new RegExp('\\s+');
  regexp = regexp.replaceAll(spaceRe, '(?:\\s*)');
  if (shouldMatch) {
    Expect.isTrue(new RegExp(regexp).hasMatch(generated));
  } else {
    Expect.isFalse(new RegExp(regexp).hasMatch(generated));
  }
}
