// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test constant folding.

#library("compiler_helper");

#import("dart:uri");
#import("../../../lib/compiler/implementation/leg.dart", prefix: "leg");
#import("../../../lib/compiler/implementation/elements/elements.dart", prefix: "lego");
#import("../../../lib/compiler/implementation/ssa/ssa.dart", prefix: "ssa");
#import("parser_helper.dart");
#import("mock_compiler.dart");

String compile(String code, [String entry = 'main']) {
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript(code);
  lego.Element element = compiler.mainApp.find(buildSourceString(entry));
  if (element === null) return null;
  compiler.processQueue(compiler.enqueuer.resolution, element);
  leg.WorkItem work = new leg.WorkItem(element, null);
  String generated = work.run(compiler, compiler.enqueuer.codegen);
  return generated;
}

String compileAll(String code) {
  MockCompiler compiler = new MockCompiler();
  Uri uri = new Uri(scheme: 'source');
  compiler.sources[uri.toString()] = code;
  compiler.runCompiler(uri);
  return compiler.assembledCode;
}

String anyIdentifier = "[a-zA-Z][a-zA-Z0-9]*";

String getIntTypeCheck(String variable) {
  return "\\($variable !== \\($variable \\| 0\\)\\)";
}

String getNumberTypeCheck(String variable) {
  return "\\(typeof $variable !== 'number'\\)";
}

bool checkNumberOfMatches(Iterator it, int nb) {
  for (int i = 0; i < nb; i++) {
    Expect.isTrue(it.hasNext());
    it.next();
  }
  Expect.isFalse(it.hasNext());
}

void compileAndMatch(String code, String entry, RegExp regexp) {
  String generated = compile(code, entry);
  Expect.isTrue(regexp.hasMatch(generated),
                '"$generated" does not match /$regexp/');
}

void compileAndDoNotMatch(String code, String entry, RegExp regexp) {
  String generated = compile(code, entry);
  Expect.isFalse(regexp.hasMatch(generated),
                 '"$generated" has a match in /$regexp/');
}
