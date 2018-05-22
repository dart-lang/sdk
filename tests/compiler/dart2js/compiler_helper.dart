// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler_helper;

import 'dart:async';
import "package:expect/expect.dart";

import 'package:compiler/compiler_new.dart';

import 'package:compiler/src/common_elements.dart';

import 'package:compiler/src/elements/entities.dart';

import 'package:compiler/src/js_backend/js_backend.dart' as js;

import 'package:compiler/src/commandline_options.dart';

export 'package:compiler/src/diagnostics/messages.dart';
export 'package:compiler/src/diagnostics/source_span.dart';
export 'package:compiler/src/diagnostics/spannable.dart';

import 'package:compiler/src/util/util.dart';
export 'package:compiler/src/util/util.dart';

import 'package:compiler/src/world.dart';

import 'package:compiler/src/compiler.dart' show Compiler;

import 'memory_compiler.dart';

import 'output_collector.dart';
export 'output_collector.dart';

/// Compile [code] and returns either the code for [methodName] or, if
/// [returnAll] is true, the code for the entire program.
///
/// If [check] is provided, it is executed on the code for [entry] before
/// returning.
Future<String> compile(String code,
    {String entry: 'main',
    String methodName,
    bool enableTypeAssertions: false,
    bool minify: false,
    bool analyzeAll: false,
    bool disableInlining: true,
    bool trustJSInteropTypeAnnotations: false,
    void check(String generatedEntry),
    bool returnAll: false}) async {
  OutputCollector outputCollector = returnAll ? new OutputCollector() : null;
  List<String> options = <String>[Flags.disableTypeInference];
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
  methodName ??= entry;
  if (entry != 'main') {
    source = {'main.dart': "$code\n\nmain() => $entry;"};
  } else {
    source = {'main.dart': code};
  }

  CompilationResult result = await runCompiler(
      memorySourceFiles: source,
      options: options,
      outputProvider: outputCollector);
  Expect.isTrue(result.isSuccess);
  Compiler compiler = result.compiler;
  ClosedWorld closedWorld = compiler.backendClosedWorldForTesting;
  ElementEnvironment elementEnvironment = closedWorld.elementEnvironment;
  LibraryEntity mainLibrary = elementEnvironment.mainLibrary;
  FunctionEntity element =
      elementEnvironment.lookupLibraryMember(mainLibrary, methodName);
  js.JavaScriptBackend backend = compiler.backend;
  String generated = backend.getGeneratedCode(element);
  if (check != null) {
    check(generated);
  }
  return returnAll ? outputCollector.getOutput('', OutputType.js) : generated;
}

Future<String> compileAll(String code,
    {bool disableInlining: true,
    bool trustTypeAnnotations: false,
    bool minify: false,
    int expectedErrors,
    int expectedWarnings}) async {
  OutputCollector outputCollector = new OutputCollector();
  DiagnosticCollector diagnosticCollector = new DiagnosticCollector();
  List<String> options = <String>[];
  if (disableInlining) {
    options.add(Flags.disableInlining);
  }
  if (trustTypeAnnotations) {
    options.add(Flags.trustTypeAnnotations);
  }
  if (minify) {
    options.add(Flags.minify);
  }
  CompilationResult result = await runCompiler(
      memorySourceFiles: {'main.dart': code},
      options: options,
      outputProvider: outputCollector,
      diagnosticHandler: diagnosticCollector);
  Expect.isTrue(
      result.isSuccess,
      'Unexpected compilation error(s): '
      '${diagnosticCollector.errors}');
  return outputCollector.getOutput('', OutputType.js);
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

Future compileAndMatch(String code, String entry, RegExp regexp) {
  return compile(code, entry: entry, check: (String generated) {
    Expect.isTrue(
        regexp.hasMatch(generated), '"$generated" does not match /$regexp/');
  });
}

Future compileAndDoNotMatch(String code, String entry, RegExp regexp) {
  return compile(code, entry: entry, check: (String generated) {
    Expect.isFalse(
        regexp.hasMatch(generated), '"$generated" has a match in /$regexp/');
  });
}

int length(Link link) => link.isEmpty ? 0 : length(link.tail) + 1;

// Does a compile and then a match where every 'x' is replaced by something
// that matches any variable, and every space is optional.
Future compileAndMatchFuzzy(String code, String entry, String regexp) {
  return compileAndMatchFuzzyHelper(code, entry, regexp, shouldMatch: true);
}

Future compileAndDoNotMatchFuzzy(String code, String entry, String regexp) {
  return compileAndMatchFuzzyHelper(code, entry, regexp, shouldMatch: false);
}

Future compileAndMatchFuzzyHelper(String code, String entry, String regexp,
    {bool shouldMatch}) {
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

/// Returns a 'check' function that uses comments in [test] to drive checking.
///
/// The comments contains one or more 'present:' or 'absent:' tags, each
/// followed by a quoted string. For example, the returned checker for the
/// following text will ensure that the argument contains the three characters
/// 'foo' and does not contain the two characters '""':
///
///    // present: "foo"
///    // absent:  '""'
checkerForAbsentPresent(String test) {
  var matches = _directivePattern.allMatches(test).toList();
  checker(String generated) {
    if (matches.isEmpty) {
      Expect.fail("No 'absent:' or 'present:' directives in '$test'");
    }
    for (Match match in matches) {
      String directive = match.group(1);
      String pattern = match.groups([2, 3]).where((s) => s != null).single;
      if (directive == 'present') {
        Expect.isTrue(generated.contains(pattern),
            "Cannot find '$pattern' in:\n$generated");
      } else {
        assert(directive == 'absent');
        Expect.isFalse(generated.contains(pattern),
            "Must not find '$pattern' in:\n$generated");
      }
    }
  }

  return checker;
}

RegExp _directivePattern = new RegExp(
    //      \1                     \2        \3
    r'''// *(present|absent): *(?:"([^"]*)"|'([^'']*)')''', multiLine: true);
