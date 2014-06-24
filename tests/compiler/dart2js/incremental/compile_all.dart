// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Helper file that can be used to manually test the stability of incremental
// compilation.  Currently this test is not run automatically.

import 'dart:async';

import 'dart:io';

import 'dart:profiler' show
    UserTag;

import 'package:dart2js_incremental/dart2js_incremental.dart' show
    IncrementalCompiler;

import '../memory_source_file_helper.dart' show
    Compiler;

import '../memory_compiler.dart' show
    compilerFor;

const bool verbose = false;

main(List<String> arguments) {
  Stopwatch sw = new Stopwatch()..start();
  Map<String, String> sources = <String, String>{};
  for (String argument in arguments) {
    Uri uri = new Uri(scheme: 'memory', path: argument);
    String source =
        new File.fromUri(Uri.base.resolve(argument)).readAsStringSync();
    sources['${uri.path}'] = source;
  }
  sw.stop();
  print(sw.elapsedMilliseconds);
  compileTests(sources);
}

void compileTests(Map<String, String> sources) {
  int cancellations = 0;
  int testCount = 0;
  int skipCount = 0;
  Set<String> crashes = new Set<String>();
  Compiler memoryCompiler = compilerFor(sources);
  memoryCompiler.handler.verbose = verbose;
  var options = ['--analyze-main'];
  if (true || verbose) options.add('--verbose');
  IncrementalCompiler compiler = new IncrementalCompiler(
      libraryRoot: memoryCompiler.libraryRoot,
      inputProvider: memoryCompiler.provider,
      outputProvider: memoryCompiler.outputProvider,
      diagnosticHandler: memoryCompiler.handler,
      packageRoot: memoryCompiler.packageRoot,
      options: options);
  Future.forEach(sources.keys, (String path) {
    UserTag.defaultTag.makeCurrent();
    if (!path.endsWith('_test.dart')) return new Future.value(null);
    testCount++;
    for (String brokenTest in brokenTests) {
      if (path.endsWith(brokenTest)) {
        print('Skipped broken test $path');
        skipCount++;
        return new Future.value(null);
      }
    }
    Stopwatch sw = new Stopwatch()..start();
    return compiler.compile(Uri.parse('memory:$path')).then((bool success) {
      UserTag.defaultTag.makeCurrent();
      sw.stop();
      print('Compiled $path in ${sw.elapsedMilliseconds}');
      if (compiler.compilerWasCancelled) cancellations++;
      sw..reset()..start();
    }).catchError((error, trace) {
      sw.stop();
      print('$error\n$trace');
      print('Crash when compiling $path after ${sw.elapsedMilliseconds}');
      sw..reset()..start();
      crashes.add(path);
    });
  }).then((_) {
    percent(i) => '${(i/testCount*100).toStringAsFixed(3)}%';
    print('''

Total: $testCount tests
 * $cancellations tests (${percent(cancellations)}) cancelled the compiler
 * ${crashes.length} tests (${percent(crashes.length)}) crashed the compiler
 * $skipCount tests (${percent(skipCount)}) were skipped
''');
    for (String crash in crashes) {
      print('Crashed: $crash');
    }
    if (!crashes.isEmpty) {
      throw 'Test had crashes';
    }
  });
}

Set<String> brokenTests = new Set<String>.from([
    // TODO(ahe): Fix the outputProvider to not throw an error.
    "/dart2js_extra/deferred/deferred_class_library.dart",
    "/dart2js_extra/deferred/deferred_class_library2.dart",
    "/dart2js_extra/deferred/deferred_class_test.dart",
    "/dart2js_extra/deferred/deferred_constant2_test.dart",
    "/dart2js_extra/deferred/deferred_constant3_test.dart",
    "/dart2js_extra/deferred/deferred_constant4_test.dart",
    "/dart2js_extra/deferred/deferred_constant_test.dart",
    "/dart2js_extra/deferred/deferred_function_library.dart",
    "/dart2js_extra/deferred/deferred_function_test.dart",
    "/dart2js_extra/deferred/deferred_overlapping_lib1.dart",
    "/dart2js_extra/deferred/deferred_overlapping_lib2.dart",
    "/dart2js_extra/deferred/deferred_overlapping_lib3.dart",
    "/dart2js_extra/deferred/deferred_overlapping_test.dart",
    "/dart2js_extra/deferred/deferred_unused_classes_test.dart",
    "/language/deferred_closurize_load_library_lib.dart",
    "/language/deferred_closurize_load_library_test.dart",
    "/language/deferred_constraints_constants_lib.dart",
    "/language/deferred_constraints_constants_old_syntax_lib.dart",
    "/language/deferred_constraints_constants_old_syntax_test.dart",
    "/language/deferred_constraints_constants_test.dart",
    "/language/deferred_constraints_lib.dart",
    "/language/deferred_constraints_lib2.dart",
    "/language/deferred_constraints_old_syntax_lib.dart",
    "/language/deferred_constraints_type_annotation_old_syntax_test.dart",
    "/language/deferred_constraints_type_annotation_test.dart",
    "/language/deferred_duplicate_prefix1_test.dart",
    "/language/deferred_duplicate_prefix2_test.dart",
    "/language/deferred_duplicate_prefix3_test.dart",
    "/language/deferred_load_inval_code_lib.dart",
    "/language/deferred_load_inval_code_test.dart",
    "/language/deferred_load_library_wrong_args_lib.dart",
    "/language/deferred_load_library_wrong_args_test.dart",
    "/language/deferred_no_prefix_test.dart",
    "/language/deferred_no_such_method_lib.dart",
    "/language/deferred_no_such_method_test.dart",
    "/language/deferred_not_loaded_check_lib.dart",
    "/language/deferred_not_loaded_check_test.dart",
    "/language/deferred_prefix_constraints_lib.dart",
    "/language/deferred_prefix_constraints_lib2.dart",
    "/language/deferred_shadow_load_library_lib.dart",
    "/language/deferred_shadow_load_library_test.dart",

    "/language/bad_constructor_test.dart",
    "/language/black_listed_test.dart",
    "/language/built_in_identifier_illegal_test.dart",
    "/language/built_in_identifier_prefix_test.dart",
    "/language/built_in_identifier_test.dart",
    "/language/class_cycle2_test.dart",
    "/language/class_syntax_test.dart",
    "/language/cyclic_typedef_test.dart",
    "/language/external_test.dart",
    "/language/factory3_negative_test.dart",
    "/language/generic_field_mixin4_test.dart",
    "/language/generic_field_mixin5_test.dart",
    "/language/interface_cycle_test.dart",
    "/language/interface_injection1_negative_test.dart",
    "/language/interface_injection2_negative_test.dart",
    "/language/internal_library_test.dart",
    "/language/malformed_inheritance_test.dart",
    "/language/metadata_test.dart",
    "/language/method_override2_test.dart",
    "/language/mixin_illegal_syntax_test.dart",
    "/language/mixin_invalid_inheritance1_test.dart",
    "/language/null_test.dart",
    "/language/override_inheritance_generic_test.dart",
    "/language/prefix18_negative_test.dart",
    "/language/prefix3_negative_test.dart",
    "/language/script2_negative_test.dart",
    "/language/setter_declaration2_negative_test.dart",
    "/language/source_self_negative_test.dart",
    "/language/syntax_test.dart",
    "/language/type_variable_bounds2_test.dart",
    "/language/type_variable_conflict2_test.dart",
    "/language/type_variable_field_initializer_test.dart",
    "/language/type_variable_nested_test.dart",
    "/language/vm/reflect_core_vm_test.dart",
    "/language/vm/regress_14903_test.dart",
]);
