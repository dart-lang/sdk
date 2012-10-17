// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding.

#library("compiler_helper");

#import("dart:uri");

#import("../../../lib/compiler/implementation/elements/elements.dart", prefix: "lego");
#import("../../../lib/compiler/implementation/js_backend/js_backend.dart", prefix: "js");
#import("../../../lib/compiler/implementation/leg.dart", prefix: "leg");
#import("../../../lib/compiler/implementation/ssa/ssa.dart", prefix: "ssa");
#import("../../../lib/compiler/implementation/util/util.dart");
#import('../../../lib/compiler/implementation/source_file.dart');

#import("mock_compiler.dart");
#import("parser_helper.dart");

String compile(String code, {String entry: 'main',
                             bool enableTypeAssertions: false,
                             bool minify: false}) {
  MockCompiler compiler =
      new MockCompiler(enableTypeAssertions: enableTypeAssertions,
                       enableMinification: minify);
  compiler.parseScript(code);
  lego.Element element = compiler.mainApp.find(buildSourceString(entry));
  if (element === null) return null;
  compiler.backend.enqueueHelpers(compiler.enqueuer.resolution);
  compiler.processQueue(compiler.enqueuer.resolution, element);
  var context = new js.JavaScriptItemCompilationContext();
  leg.WorkItem work = new leg.WorkItem(element, null, context);
  work.run(compiler, compiler.enqueuer.codegen);
  return compiler.enqueuer.codegen.lookupCode(element);
}

MockCompiler compilerFor(String code, Uri uri) {
  MockCompiler compiler = new MockCompiler();
  compiler.sourceFiles[uri.toString()] = new SourceFile(uri.toString(), code);
  return compiler;
}

String compileAll(String code) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  MockCompiler compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  Expect.isFalse(compiler.compilationFailed,
                 'Unexpected compilation error');
  return compiler.assembledCode;
}

dynamic compileAndCheck(String code,
                        String name,
                        check(MockCompiler compiler, lego.Element element)) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  MockCompiler compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  lego.Element element = findElement(compiler, name);
  return check(compiler, element);
}

lego.Element findElement(compiler, String name) {
  var element = compiler.mainApp.find(buildSourceString(name));
  Expect.isNotNull(element, 'Could not locate $name.');
  return element;
}

String anyIdentifier = "[a-zA-Z][a-zA-Z0-9]*";

String getIntTypeCheck(String variable) {
  return "\\($variable ?!== ?\\($variable ?\\| ?0\\)\\)";
}

String getNumberTypeCheck(String variable) {
  return "\\(typeof $variable ?!== ?'number'\\)";
}

bool checkNumberOfMatches(Iterator it, int nb) {
  for (int i = 0; i < nb; i++) {
    Expect.isTrue(it.hasNext(), "Found less than $nb matches");
    it.next();
  }
  Expect.isFalse(it.hasNext(), "Found more than $nb matches");
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

int length(Link link) => link.isEmpty() ? 0 : length(link.tail) + 1;

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

