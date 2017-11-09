// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:args/args.dart';
import 'package:dev_compiler/src/kernel/target.dart';
import 'package:front_end/compilation_message.dart';
import 'package:front_end/compiler_options.dart';
import 'package:front_end/src/kernel_generator_impl.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:kernel/kernel.dart';
import 'package:kernel/core_types.dart';

import 'package:path/path.dart' as path;

import '../compiler/module_builder.dart';
import '../compiler/js_names.dart' as JS;
import '../js_ast/js_ast.dart' as JS;
import 'compiler.dart';
import 'native_types.dart';

/// Invoke the compiler with [args].
///
/// Returns `true` if the program compiled without any fatal errors.
Future<bool> compile(List<String> args) async {
  var argParser = new ArgParser(allowTrailingOptions: true)
    ..addOption('out', abbr: 'o', help: 'Output file (required).')
    ..addOption('dart-sdk-summary',
        help: 'The path to the Dart SDK summary file.', hide: true)
    ..addOption('summary',
        abbr: 's', help: 'summaries to link to', allowMultiple: true);

  addModuleFormatOptions(argParser, singleOutFile: false);

  var declaredVariables = parseAndRemoveDeclaredVariables(args);

  var argResults = argParser.parse(args);

  var moduleFormat = parseModuleFormatOption(argResults).first;
  var ddcPath = path.dirname(path.dirname(path.fromUri(Platform.script)));

  var summaryUris =
      (argResults['summary'] as List<String>).map(Uri.parse).toList();

  var sdkSummaryPath = argResults['dart-sdk-summary'] ??
      path.absolute(ddcPath, 'lib', 'sdk', 'ddc_sdk.dill');

  var succeeded = true;
  void errorHandler(CompilationMessage error) {
    // TODO(jmesserly): front end warning levels do not seem to follow the
    // Strong Mode/Dart 2 spec. So for now, we treat all warnings as
    // compile time errors.
    if (error.severity == Severity.error ||
        error.severity == Severity.warning) {
      succeeded = false;
    }
  }

  var options = new CompilerOptions()
    ..sdkSummary = path.toUri(sdkSummaryPath)
    ..packagesFileUri =
        path.toUri(path.absolute(ddcPath, '..', '..', '.packages'))
    ..inputSummaries = summaryUris
    ..target = new DevCompilerTarget()
    ..onError = errorHandler
    ..chaseDependencies = true
    ..reportMessages = true;

  var inputs = argResults.rest
      .map((a) => a.startsWith('package:') || a.startsWith('dart:')
          ? Uri.parse(a)
          : path.toUri(path.absolute(a)))
      .toList();
  String output = argResults['out'];

  //var program = await kernelForBuildUnit(inputs, options);
  // TODO(jmesserly): use public APIs. For now we need this to access processed
  // options, which has info needed to compute library -> module mapping without
  // re-parsing inputs.
  var processedOpts = new ProcessedOptions(options, true, inputs);
  var compilerResult = await generateKernel(processedOpts);
  var program = compilerResult?.program;

  var sdkSummary = await processedOpts.loadSdkSummary(null);
  var nameRoot = sdkSummary?.root ?? new CanonicalName.root();
  var summaries = await processedOpts.loadInputSummaries(nameRoot);

  if (succeeded) {
    var file = new File(output);
    if (!file.parent.existsSync()) file.parent.createSync(recursive: true);
    // Useful for debugging:
    writeProgramToText(program, path: output + '.txt');

    // TODO(jmesserly): Save .dill file so other modules can link in this one.
    //await writeProgramToBinary(program, output);
    var jsModule =
        compileToJSModule(program, summaries, summaryUris, declaredVariables);
    var jsCode = jsProgramToString(jsModule, moduleFormat);
    file.writeAsStringSync(jsCode);
  }

  return succeeded;
}

JS.Program compileToJSModule(Program p, List<Program> summaries,
    List<Uri> summaryUris, Map<String, String> declaredVariables) {
  var compiler = new ProgramCompiler(new NativeTypeSet(p, new CoreTypes(p)),
      declaredVariables: declaredVariables);
  return compiler.emitProgram(p, summaries, summaryUris);
}

String jsProgramToString(JS.Program moduleTree, ModuleFormat format) {
  var opts = new JS.JavaScriptPrintingOptions(
      allowKeywordsInProperties: true, allowSingleLineIfStatements: true);
  // TODO(jmesserly): Support source maps.
  var printer = new JS.SimpleJavaScriptPrintingContext();

  var tree = transformModuleFormat(format, moduleTree);
  tree.accept(
      new JS.Printer(opts, printer, localNamer: new JS.TemporaryNamer(tree)));

  return printer.getText();
}

/// Parses Dart's non-standard `-Dname=value` syntax for declared variables,
/// and removes them from [args] so the result can be parsed normally.
Map<String, String> parseAndRemoveDeclaredVariables(List<String> args) {
  var declaredVariables = <String, String>{};
  for (int i = 0; i < args.length;) {
    var arg = args[i];
    if (arg.startsWith('-D') && arg.length > 2) {
      var rest = arg.substring(2);
      var eq = rest.indexOf('=');
      if (eq <= 0) {
        var kind = eq == 0 ? 'name' : 'value';
        throw new FormatException('no $kind given to -D option `$arg`');
      }
      var name = rest.substring(0, eq);
      var value = rest.substring(eq + 1);
      declaredVariables[name] = value;
      args.removeAt(i);
    } else {
      i++;
    }
  }
  return declaredVariables;
}
