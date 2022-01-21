// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show jsonDecode;

import 'dart:io' show File;

import 'package:front_end/src/api_prototype/incremental_kernel_generator.dart';
import 'package:front_end/src/fasta/util/outline_extractor.dart';
import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;
import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        ExpectationSet,
        Result,
        Step,
        TestDescription,
        runMe;
import 'package:kernel/src/equivalence.dart';
import 'package:front_end/src/api_prototype/compiler_options.dart';
import 'package:front_end/src/api_prototype/memory_file_system.dart';
import 'package:kernel/ast.dart';

import 'fasta/testing/suite.dart' show UPDATE_EXPECTATIONS;
import 'utils/kernel_chain.dart' show MatchContext;

import 'testing_utils.dart' show checkEnvironment;

import 'incremental_suite.dart' as helper;

const String EXPECTATIONS = '''
[
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail"
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail"
  }
]
''';

void main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, configurationPath: "../testing.json");

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  const Set<String> knownEnvironmentKeys = {
    "updateExpectations",
  };
  checkEnvironment(environment, knownEnvironmentKeys);

  bool updateExpectations = environment["updateExpectations"] == "true";

  return new Context(suite.name, updateExpectations);
}

class Context extends ChainContext with MatchContext {
  @override
  final bool updateExpectations;

  @override
  String get updateExpectationsOption => '${UPDATE_EXPECTATIONS}=true';

  @override
  bool get canBeFixWithUpdateExpectations => true;

  final String suiteName;

  Context(this.suiteName, this.updateExpectations);

  @override
  final List<Step> steps = const <Step>[
    const OutlineExtractorStep(),
    const CompileAndCompareStep(),
  ];

  @override
  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(jsonDecode(EXPECTATIONS));

  // Override special handling of negative tests.
  @override
  Result processTestResult(
      TestDescription description, Result result, bool last) {
    return result;
  }
}

class OutlineExtractorStep
    extends Step<TestDescription, TestDescription, Context> {
  const OutlineExtractorStep();

  @override
  String get name => "OutlineExtractorStep";

  @override
  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    Uri? packages = description.uri.resolve(".packages");
    if (!new File.fromUri(packages).existsSync()) {
      packages = null;
    }
    Map<Uri, String> result =
        await extractOutline([description.uri], packages: packages);

    StringBuffer sb = new StringBuffer();
    Uri uri = description.uri;
    Uri base = uri.resolve(".");
    Uri dartBase = Uri.base;

    for (MapEntry<Uri, String> entry in result.entries) {
      sb.writeln("${entry.key}:");
      sb.writeln(entry.value);
      sb.writeln("\n\n");
    }

    String actual = sb.toString();
    actual = actual.replaceAll("$base", "org-dartlang-testcase:///");
    actual = actual.replaceAll("$dartBase", "org-dartlang-testcase-sdk:///");
    actual = actual.replaceAll("\\n", "\n");

    return context.match<TestDescription>(
      ".outline_extracted",
      actual,
      description.uri,
      description,
    );
  }
}

class CompileAndCompareStep
    extends Step<TestDescription, TestDescription, Context> {
  const CompileAndCompareStep();

  @override
  String get name => "CompileAndCompare";

  @override
  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    Uri? packages = description.uri.resolve(".packages");
    if (!new File.fromUri(packages).existsSync()) {
      packages = null;
    }
    Map<Uri, String> processedFiles =
        await extractOutline([description.uri], packages: packages);

    void onDiagnostic(DiagnosticMessage message) {
      if (message.severity == Severity.error ||
          message.severity == Severity.warning) {
        throw ("Unexpected error: ${message.plainTextFormatted.join('\n')}");
      }
    }

    Library lib1;
    {
      CompilerOptions options = helper.getOptions();
      options.onDiagnostic = onDiagnostic;
      options.packagesFileUri = packages;
      helper.TestIncrementalCompiler compiler =
          new helper.TestIncrementalCompiler(options, description.uri,
              /* initializeFrom = */ null, /* outlineOnly = */ true);
      IncrementalCompilerResult c = await compiler.computeDelta();
      lib1 = c.component.libraries
          .firstWhere((element) => element.fileUri == description.uri);
    }
    Library lib2;
    {
      CompilerOptions options = helper.getOptions();
      options.onDiagnostic = onDiagnostic;
      options.packagesFileUri = packages;
      MemoryFileSystem mfs = new MemoryFileSystem(Uri.base);
      if (packages != null) {
        mfs.entityForUri(packages).writeAsBytesSync(
            await options.fileSystem.entityForUri(packages).readAsBytes());
      }
      if (options.sdkSummary != null) {
        mfs.entityForUri(options.sdkSummary!).writeAsBytesSync(await options
            .fileSystem
            .entityForUri(options.sdkSummary!)
            .readAsBytes());
      }
      if (options.librariesSpecificationUri != null) {
        mfs.entityForUri(options.librariesSpecificationUri!).writeAsBytesSync(
            await options.fileSystem
                .entityForUri(options.librariesSpecificationUri!)
                .readAsBytes());
      }
      for (MapEntry<Uri, String> entry in processedFiles.entries) {
        mfs.entityForUri(entry.key).writeAsStringSync(entry.value);
      }
      options.fileSystem = mfs;
      helper.TestIncrementalCompiler compiler =
          new helper.TestIncrementalCompiler(options, description.uri,
              /* initializeFrom = */ null, /* outlineOnly = */ true);
      IncrementalCompilerResult c = await compiler.computeDelta();
      lib2 = c.component.libraries
          .firstWhere((element) => element.fileUri == description.uri);
    }
    EquivalenceResult result =
        checkEquivalence(lib1, lib2, strategy: const Strategy());

    if (result.isEquivalent) {
      return new Result<TestDescription>.pass(description);
    } else {
      print("Bad:");
      print(result);
      return new Result<TestDescription>.fail(
          description, /* error = */ result);
    }
  }
}

class Strategy extends EquivalenceStrategy {
  const Strategy();

  @override
  bool checkTreeNode_fileOffset(
      EquivalenceVisitor visitor, TreeNode node, TreeNode other) {
    return true;
  }

  @override
  bool checkAssertStatement_conditionStartOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return true;
  }

  @override
  bool checkAssertStatement_conditionEndOffset(
      EquivalenceVisitor visitor, AssertStatement node, AssertStatement other) {
    return true;
  }

  @override
  bool checkClass_startFileOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return true;
  }

  @override
  bool checkClass_fileEndOffset(
      EquivalenceVisitor visitor, Class node, Class other) {
    return true;
  }

  @override
  bool checkProcedure_startFileOffset(
      EquivalenceVisitor visitor, Procedure node, Procedure other) {
    return true;
  }

  @override
  bool checkConstructor_startFileOffset(
      EquivalenceVisitor visitor, Constructor node, Constructor other) {
    return true;
  }

  @override
  bool checkMember_fileEndOffset(
      EquivalenceVisitor visitor, Member node, Member other) {
    return true;
  }

  @override
  bool checkFunctionNode_fileEndOffset(
      EquivalenceVisitor visitor, FunctionNode node, FunctionNode other) {
    return true;
  }

  @override
  bool checkBlock_fileEndOffset(
      EquivalenceVisitor visitor, Block node, Block other) {
    return true;
  }

  @override
  bool checkLibrary_additionalExports(
      EquivalenceVisitor visitor, Library node, Library other) {
    return visitor.checkSets(
        node.additionalExports.toSet(),
        other.additionalExports.toSet(),
        visitor.matchReferences,
        visitor.checkReferences,
        'additionalExports');
  }

  @override
  bool checkClass_procedures(
      EquivalenceVisitor visitor, Class node, Class other) {
    // Check procedures as a set instead of a list to allow for reordering.
    List<Procedure> a = node.procedures.toList();
    int sorter(Procedure x, Procedure y) {
      int result = x.name.text.compareTo(y.name.text);
      if (result != 0) return result;
      result = x.kind.index - y.kind.index;
      if (result != 0) return result;
      // other stuff?
      return 0;
    }

    a.sort(sorter);
    List<Procedure> b = other.procedures.toList();
    b.sort(sorter);
    // return visitor.checkSets(a.toSet(), b.toSet(),
    //     visitor.matchNamedNodes, visitor.checkNodes, 'procedures');

    return visitor.checkLists(a, b, visitor.checkNodes, 'procedures');
  }
}
