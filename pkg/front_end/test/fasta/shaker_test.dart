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
import 'package:front_end/physical_file_system.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart' show DillTarget;
import 'package:front_end/src/fasta/errors.dart' show InputError;
import 'package:front_end/src/fasta/kernel/kernel_outline_shaker.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart'
    show KernelTarget;
import 'package:front_end/src/fasta/kernel/verifier.dart' show verifyProgram;
import 'package:front_end/src/fasta/testing/kernel_chain.dart' show runDiff;
import 'package:front_end/src/fasta/testing/patched_sdk_location.dart';
import 'package:front_end/src/fasta/ticker.dart' show Ticker;
import 'package:front_end/src/fasta/translate_uri.dart' show TranslateUri;
import 'package:front_end/src/fasta/util/relativize.dart' show relativizeUri;
import 'package:kernel/ast.dart' show Program;
import 'package:kernel/kernel.dart' show loadProgramFromBytes;
import 'package:kernel/target/targets.dart' show TargetFlags;
import 'package:kernel/target/vm_fasta.dart' show VmFastaTarget;
import 'package:testing/testing.dart'
    show Chain, ChainContext, ExpectationSet, Result, Step, TestDescription;
import 'testing/suite.dart';

main(List<String> arguments) =>
    runMe(arguments, createContext, "../../testing.json");

Future<TreeShakerContext> createContext(
    Chain suite, Map<String, String> environment) {
  return TreeShakerContext.create(environment);
}

/// Context used to run the tree-shaking test suite.
class TreeShakerContext extends ChainContext {
  final TranslateUri uriTranslator;
  final Uri outlineUri;
  final List<Step> steps;
  final List<int> outlineBytes;

  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(JSON.decode(EXPECTATIONS));

  TreeShakerContext(this.outlineUri, this.uriTranslator, this.outlineBytes,
      bool updateExpectations)
      : steps = <Step>[
          const BuildProgram(),
          new CheckShaker(updateExpectations: updateExpectations),
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
    Uri packages = Uri.base.resolve(".packages");
    TranslateUri uriTranslator = await TranslateUri
        .parse(PhysicalFileSystem.instance, sdk, packages: packages);
    List<int> outlineBytes = new File.fromUri(outlineUri).readAsBytesSync();
    return new TreeShakerContext(
        outlineUri, uriTranslator, outlineBytes, updateExpectations);
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
    try {
      var platformOutline = context.loadPlatformOutline();
      platformOutline.unbindCanonicalNames();
      var dillTarget = new DillTarget(
          new Ticker(isVerbose: false),
          context.uriTranslator,
          new VmFastaTarget(new TargetFlags(strongMode: false)));
      dillTarget.loader.appendLibraries(platformOutline);
      var sourceTarget = new KernelTarget(
          PhysicalFileSystem.instance, dillTarget, context.uriTranslator);
      await dillTarget.buildOutlines();

      var inputUri = description.uri;
      var libUri = inputUri.resolve('lib/lib.dart');
      sourceTarget.read(libUri);
      sourceTarget.read(inputUri);
      var contents = new File.fromUri(inputUri).readAsStringSync();
      var showCoreLibraries = contents.contains("@@SHOW_CORE_LIBRARIES@@");
      await sourceTarget.buildOutlines();
      var program = await sourceTarget.buildProgram();
      bool isIncluded(Uri uri) => !_isTreeShaken(uri);
      trimProgram(program, isIncluded);
      return pass(new _IntermediateData(inputUri, program, showCoreLibraries));
    } on InputError catch (e, s) {
      return fail(null, e.error, s);
    }
  }
}

/// Intermediate result from the testing chain.
class _IntermediateData {
  /// The input URI provided to the test.
  final Uri uri;

  /// Program built by [BuildProgram].
  final Program program;

  /// Whether the output should include tree-shaking information about the core
  /// libraries. This is specified in a comment on individual test files where
  /// we believe that information is relevant.
  final bool showCoreLibraries;

  _IntermediateData(this.uri, this.program, this.showCoreLibraries);
}

/// A step that runs the tree-shaker and checks againt an expectation file for
/// the list of members and classes that should be preserved by the tree-shaker.
class CheckShaker extends Step<_IntermediateData, String, ChainContext> {
  final bool updateExpectations;
  const CheckShaker({this.updateExpectations: false});

  String get name => "match shaker expectation";

  Future<Result<String>> run(
      _IntermediateData data, ChainContext context) async {
    String actualResult;
    var entryUri = data.uri;
    var program = data.program;

    var errors = verifyProgram(program, isOutline: false);
    if (!errors.isEmpty) {
      return new Result<String>(
          null, context.expectationSet["VerificationError"], errors, null);
    }

    // Build a text representation of what we expect to be retained.
    var buffer = new StringBuffer();
    buffer.writeln('DO NOT EDIT -- this file is autogenerated ---');
    buffer.writeln('Tree-shaker preserved the following:');
    for (var library in program.libraries) {
      var importUri = library.importUri;
      if (!_isTreeShaken(importUri)) continue;
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
    File expectedFile = new File("${entryUri.toFilePath()}.shaker");
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
      return fail(
          actualResult,
          """
Please create file ${expectedFile.path} with this content:
$buffer""");
    }
  }
}

/// A special library used only to test the shaker. The suite above will
/// tree-shake the contents of this library.
const _specialLibraryPath = 'pkg/front_end/testcases/shaker/lib/lib.dart';

/// Tree-shake dart:* libraries and the library under [_specialLibraryPath].
bool _isTreeShaken(Uri uri) =>
    uri.isScheme('dart') ||
    Uri.base.resolveUri(uri).path.endsWith(_specialLibraryPath);
