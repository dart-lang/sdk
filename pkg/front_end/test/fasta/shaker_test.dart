// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

/// Tests basic functionality of the API tree-shaker.
///
/// Each input file is built and tree-shaken, then we check that the set of
/// libraries, classes, and members that are retained match those declared in an
/// expectations file.
///
/// Input files may contain markers to turn on flags that configure this
/// runner. Currently only the following marker is recognized:
///   @@SHOW_CORE_LIBRARIES@@ - whether to check for retained information from
///      the core libraries. By default this runner only checks for members of
///      pkg/front_end/testcases/shaker/lib/lib.dart.
library fasta.test.shaker_test;

import 'dart:async' show Future;
import 'dart:convert' show JSON;
import 'dart:io' show File;

export 'package:testing/testing.dart' show Chain, runMe;
import 'package:front_end/compiler_options.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/deprecated_problems.dart'
    show deprecated_InputError;
import 'package:front_end/src/fasta/kernel/kernel_outline_shaker.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;
import 'package:front_end/src/fasta/kernel/verifier.dart' show verifyProgram;
import 'package:front_end/src/fasta/testing/kernel_chain.dart'
    show BytesCollector, runDiff;
import 'package:front_end/src/fasta/testing/patched_sdk_location.dart';
import 'package:front_end/src/fasta/util/relativize.dart' show relativizeUri;
import 'package:kernel/ast.dart' show Program;
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/kernel.dart' show loadProgramFromBytes;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;
import 'package:kernel/text/ast_to_text.dart';
import 'package:testing/testing.dart'
    show Chain, ChainContext, ExpectationSet, Result, Step, TestDescription;
import 'testing/suite.dart';

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");

Future<TreeShakerContext> createContext(
    Chain suite, Map<String, String> environment) {
  return TreeShakerContext.create(environment);
}

/// Context used to run the tree-shaking test suite.
class TreeShakerContext extends ChainContext {
  final ProcessedOptions options;
  final Uri outlineUri;
  final List<Step> steps;
  final List<int> outlineBytes;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(JSON.decode(EXPECTATIONS));

  TreeShakerContext(
      this.outlineUri, this.options, this.outlineBytes, bool updateExpectations)
      : steps = <Step>[
          const BuildProgram(),
          new CheckShaker(updateExpectations: updateExpectations),
          new CheckOutline(updateExpectations: updateExpectations),
        ];

  Program loadPlatformOutline() {
    // Note: we rebuild the platform outline on every test because the
    // tree-shaker mutates the in-memory representation of the program without
    // cloning it.
    return loadProgramFromBytes(outlineBytes);
  }

  static create(Map<String, String> environment) async {
    environment[ENABLE_FULL_COMPILE] = "";
    environment[AST_KIND_INDEX] = "${AstKind.Kernel.index}";
    bool updateExpectations = environment["updateExpectations"] == "true";
    Uri sdk = await computePatchedSdk();
    Uri outlineUri = sdk.resolve('outline.dill');
    var options = new CompilerOptions()
      ..packagesFileUri = Uri.base.resolve(".packages");
    List<int> outlineBytes = new File.fromUri(outlineUri).readAsBytesSync();
    return new TreeShakerContext(outlineUri, new ProcessedOptions(options),
        outlineBytes, updateExpectations);
  }
}

/// Step that extracts the test-specific options and builds the program without
/// applying tree-shaking.
class BuildProgram
    extends Step<TestDescription, _IntermediateData, TreeShakerContext> {
  const BuildProgram();
  String get name => "build program";
  Future<Result<_IntermediateData>> run(
      TestDescription description, TreeShakerContext context) async {
    return await CompilerContext.runWithOptions(context.options, (_) async {
      try {
        var platformOutline = context.loadPlatformOutline();
        var uriTranslator = await context.options.getUriTranslator();
        var dillTarget = new DillTarget(context.options.ticker, uriTranslator,
            new VmFastaTarget(new TargetFlags(strongMode: false)));
        dillTarget.loader.appendLibraries(platformOutline);
        var sourceTarget = new KernelTarget(
            context.options.fileSystem, false, dillTarget, uriTranslator);
        await dillTarget.buildOutlines();

        var inputUri = description.uri;
        sourceTarget.read(inputUri);
        var contents = new File.fromUri(inputUri).readAsStringSync();
        var showCoreLibraries = contents.contains("@@SHOW_CORE_LIBRARIES@@");

        await sourceTarget.buildOutlines();
        var program = await sourceTarget.buildProgram();

        bool isIncluded(Uri uri) => uri == inputUri;

        Program outline;
        {
          var bytesCollector = new BytesCollector();
          serializeTrimmedOutline(bytesCollector, program, isIncluded);
          var bytes = bytesCollector.collect();
          outline = new Program();
          new BinaryBuilder(bytes).readProgram(outline);
        }

        trimProgram(program, isIncluded);

        return pass(new _IntermediateData(
            inputUri, program, outline, showCoreLibraries));
      } on deprecated_InputError catch (e, s) {
        return fail(null, e.error, s);
      }
    });
  }
}

/// Intermediate result from the testing chain.
class _IntermediateData {
  /// The input URI provided to the test.
  final Uri uri;

  /// Program built by [BuildProgram].
  final Program program;

  /// Shaken outline of [program].
  final Program outline;

  /// Whether the output should include tree-shaking information about the core
  /// libraries. This is specified in a comment on individual test files where
  /// we believe that information is relevant.
  final bool showCoreLibraries;

  _IntermediateData(
      this.uri, this.program, this.outline, this.showCoreLibraries);
}

/// A step that runs the tree-shaker and checks against an expectation file for
/// the list of members and classes that should be preserved by the tree-shaker.
class CheckShaker
    extends Step<_IntermediateData, _IntermediateData, ChainContext> {
  final bool updateExpectations;
  const CheckShaker({this.updateExpectations: false});

  String get name => "match shaker expectation";

  Future<Result<_IntermediateData>> run(
      _IntermediateData data, ChainContext context) async {
    String actualResult;
    var entryUri = data.uri;
    var program = data.program;

    var errors = verifyProgram(program, isOutline: false);
    if (!errors.isEmpty) {
      return new Result<_IntermediateData>(
          data, context.expectationSet["VerificationError"], errors, null);
    }

    // Build a text representation of what we expect to be retained.
    var buffer = new StringBuffer();

    buffer.writeln('''
This file was autogenerated from running the shaker test suite.
To update this file, either copy the output from a failing test or run
pkg/front_end/tool/fasta testing shaker -DupdateExpectations=true''');

    for (var library in program.libraries) {
      var importUri = library.importUri;
      if (importUri == entryUri) continue;
      if (importUri.isScheme('dart') && !data.showCoreLibraries) continue;
      String uri = relativizeUri(library.importUri);
      buffer.writeln('\nlibrary $uri:');
      for (var member in library.members) {
        buffer.writeln('  - member ${member.name}');
      }
      for (var typedef_ in library.typedefs) {
        buffer.writeln('  - typedef ${typedef_.name}');
      }
      for (var cls in library.classes) {
        buffer.writeln('  - class ${cls.name}');
        for (var member in cls.members) {
          var name = '${member.name}';
          if (name == "") {
            buffer.writeln('    - (default constructor)');
          } else {
            buffer.writeln('    - $name');
          }
        }
      }
    }

    actualResult = "$buffer";

    // Compare against expectations using the text representation.
    File expectedFile = new File("${entryUri.toFilePath()}.shaker.expect");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != actualResult.trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, actualResult);
          return fail(
              null, "$entryUri doesn't match ${expectedFile.uri}\n$diff");
        }
      } else {
        return pass(data);
      }
    }
    if (updateExpectations) {
      expectedFile.writeAsStringSync(actualResult);
      return pass(data);
    } else {
      return fail(data, """
Please create file ${expectedFile.path} with this content:
$buffer""");
    }
  }
}

/// A step that checks outline against an expectation file.
class CheckOutline extends Step<_IntermediateData, String, ChainContext> {
  final bool updateExpectations;

  const CheckOutline({this.updateExpectations: false});

  String get name => "match outline expectation";

  Future<Result<String>> run(
      _IntermediateData data, ChainContext context) async {
    var entryUri = data.uri;
    var outline = data.outline;

    var errors = verifyProgram(outline, isOutline: true);
    if (!errors.isEmpty) {
      return new Result<String>(
          null, context.expectationSet["VerificationError"], errors, null);
    }

    String actualResult;
    {
      StringBuffer buffer = new StringBuffer();

      buffer.writeln('''
This file was autogenerated from running the shaker test suite.
To update this file, either copy the output from a failing test or run
pkg/front_end/tool/fasta testing shaker -DupdateExpectations=true''');

      for (var library in outline.libraries) {
        if (library.importUri.isScheme('dart') && !data.showCoreLibraries) {
          continue;
        }
        String uri = relativizeUri(library.importUri);

        if (library.isExternal) {
          if (library.dependencies.isNotEmpty) {
            return fail(
                null, 'External library $uri should not have dependencies');
          }
          if (library.parts.isNotEmpty) {
            return fail(null, 'External library $uri should not have parts');
          }
        }

        var printer = new Printer(buffer, syntheticNames: new NameSystem());
        buffer.write('----- ');
        if (library.isExternal) {
          buffer.write('external ');
        }
        buffer.writeln(uri);
        printer.writeLibraryFile(library);
        buffer.writeln();
      }
      actualResult = buffer.toString();
    }

    // Compare against expectations using the text representation.
    File expectedFile = new File("${entryUri.toFilePath()}.outline.expect");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != actualResult.trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, actualResult);
          return fail(
              null, "$entryUri doesn't match ${expectedFile.uri}\n$diff");
        }
      } else {
        return pass(actualResult);
      }
    }
    if (updateExpectations) {
      expectedFile.writeAsStringSync(actualResult);
      return pass(actualResult);
    } else {
      return fail(actualResult, """
Please create file ${expectedFile.path} with this content:
$actualResult""");
    }
  }
}
