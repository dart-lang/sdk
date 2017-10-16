// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/kernel_generator.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';
import 'package:path/path.dart' as path;

import '../compiler/module_builder.dart';
import '../compiler/js_names.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
import 'compiler.dart';
import 'native_types.dart';

Future compile(List<String> args) async {
  var ddcPath = path.dirname(path.dirname(path.fromUri(Platform.script)));
  var argResults = (new ArgParser(allowTrailingOptions: true)
        ..addOption('out', abbr: 'o', help: 'Output file (required).'))
      .parse(args);
  var options = new CompilerOptions()
    ..sdkSummary =
        path.toUri(path.absolute(ddcPath, 'lib', 'sdk', 'ddc_sdk.dill'))
    ..packagesFileUri =
        path.toUri(path.absolute(ddcPath, '..', '..', '.packages'))
    ..throwOnErrorsForDebugging = true
    ..target = new DevCompilerTarget();

  var inputs = argResults.rest.map(path.toUri).toList();
  var output = argResults['out'];

  var program = await kernelForBuildUnit(inputs, options);

  // Useful for debugging:
  writeProgramToText(program);
  // TODO(jmesserly): save .dill file so other modules can link in this one.
  //await writeProgramToBinary(program, output);
  var jsCode = compileToJSModule(program);
  new File(output).writeAsStringSync(jsCode);
}

String compileToJSModule(Program p) {
  var compiler = new ProgramCompiler(new NativeTypeSet(p, new CoreTypes(p)));
  var jsModule = compiler.emitProgram(p);
  return jsProgramToString(jsModule);
}

String jsProgramToString(JS.Program moduleTree) {
  var opts = new JS.JavaScriptPrintingOptions(
      allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
  // TODO(jmesserly): support source maps
  var printer = new JS.SimpleJavaScriptPrintingContext();

  var tree = transformModuleFormat(ModuleFormat.common, moduleTree);
  tree.accept(
      new JS.Printer(opts, printer, localNamer: new JS.TemporaryNamer(tree)));

  return printer.getText();
}
