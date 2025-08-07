// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Result,
        Step,
        TestDescription,
        ExpectationSet,
        Expectation;

import '../tool/coverage_merger.dart' as coverageMerger;
import 'coverage_helper.dart';
import 'testing/environment_keys.dart';
import 'testing_utils.dart' show checkEnvironment;
import 'utils/kernel_chain.dart';
import 'utils/suite_utils.dart';
import 'vm_service_coverage.dart';

void main([List<String> arguments = const []]) => internalMain(createContext,
    arguments: arguments,
    displayName: "coverage merger suite",
    configurationPath: "../testing.json");

const List<Map<String, String>> EXPECTATIONS = [
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail",
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail",
  },
];

Future<Context> createContext(Chain suite, Map<String, String> environment) {
  const Set<String> knownEnvironmentKeys = {
    EnvironmentKeys.updateExpectations,
  };
  checkEnvironment(environment, knownEnvironmentKeys);

  return new Future.value(new Context(suite.name, environment));
}

class CheckCoverageData extends Step<TestDescription, void, Context> {
  const CheckCoverageData();

  @override
  String get name => "CheckCoverageData";

  @override
  Future<Result<void>> run(TestDescription description, Context context) async {
    Directory tmpDir =
        Directory.systemTemp.createTempSync("coverage_merger_test");
    try {
      Directory dartToolDir =
          new Directory.fromUri(tmpDir.uri.resolve(".dart_tool/"));
      dartToolDir.createSync(recursive: true);
      File packageConfig = new File.fromUri(
          tmpDir.uri.resolve(".dart_tool/package_config.json"));
      // We claim it being called 'front_end' as that's (currently at least) the
      // only package we process (almost) all files for.
      packageConfig.writeAsStringSync("""{
  "configVersion": 2,
  "packages": [
    {
      "name": "front_end",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.8"
    }
  ]
}""");
      Directory libDir = new Directory.fromUri(tmpDir.uri.resolve("lib/"));
      libDir.createSync(recursive: true);
      File main = new File.fromUri(tmpDir.uri.resolve("lib/main.dart"));
      File sourceFile = new File.fromUri(description.uri);
      main.writeAsStringSync(sourceFile.readAsStringSync().trim());

      CollectingCoverageHelper helper = new CollectingCoverageHelper();
      await helper.start(
        [
          "--disable-dart-dev",
          "--enable-asserts",
          "--pause_isolates_on_exit",
          main.path
        ],
        stdoutReceiver: (String line) {
          print(" > $line");
        },
        stderrReceiver: (String line) {
          print("e> $line");
        },
      );
      Coverage coverage = await helper.completer.future;
      Directory coverageDir =
          new Directory.fromUri(tmpDir.uri.resolve("coverage/"));
      coverageDir.createSync(recursive: true);
      File coverageFile =
          new File.fromUri(tmpDir.uri.resolve("coverage/coverage.json"));
      coverage.writeToFile(coverageFile);

      Map<Uri, coverageMerger.CoverageInfo> coverageData =
          (await coverageMerger.mergeFromDirUri(
        packageConfig.uri,
        coverageDir.uri,
        silent: true,
        extraCoverageIgnores: ["coverage-ignore(suite):"],
        extraCoverageBlockIgnores: ["coverage-ignore-block(suite):"],
        addAndRemoveCommentsInFiles: false,
        stdoutReceiver: (String line) {
          print(" > $line");
        },
        stderrReceiver: (String line) {
          print("e> $line");
        },
      ))!;
      if (coverageData.values.first.error) {
        print("Warning: Got an error.");
      }

      Result<TestDescription> expectMatch =
          await context.match<TestDescription>(
              ".visualization.expect",
              coverageData.values.first.visualization.trim(),
              description.uri,
              description);
      if (expectMatch.outcome != Expectation.pass) return expectMatch;

      coverageData = (await coverageMerger.mergeFromDirUri(
        packageConfig.uri,
        coverageDir.uri,
        silent: true,
        extraCoverageIgnores: ["coverage-ignore(suite):"],
        extraCoverageBlockIgnores: ["coverage-ignore-block(suite):"],
        addAndRemoveCommentsInFiles: true,
        stdoutReceiver: (String line) {
          print(" > $line");
        },
        stderrReceiver: (String line) {
          print("e> $line");
        },
      ))!;

      print("Reading ${main.path}");

      String outputWithComments = main.readAsStringSync().trim();
      return await context.match<TestDescription>(".commented.expect",
          outputWithComments, description.uri, description);
    } finally {
      try {
        tmpDir.deleteSync(recursive: true);
      } catch (e) {
        // Wait a little and retry.
        sleep(const Duration(milliseconds: 42));
        try {
          tmpDir.deleteSync(recursive: true);
        } catch (e) {
          print('Warning: $e');
        }
      }
    }
  }
}

class CollectingCoverageHelper extends CoverageHelper {
  Completer<Coverage> completer = new Completer();

  CollectingCoverageHelper() : super(doPrint: false, forceCompilation: true);

  @override
  void gotCoverage(Coverage coverage) {
    completer.complete(coverage);
  }
}

class Context extends ChainContext with MatchContext {
  final String suiteName;

  @override
  final List<Step> steps = const <Step>[
    const CheckCoverageData(),
  ];

  @override
  final bool updateExpectations;

  @override
  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(EXPECTATIONS);

  Context(this.suiteName, Map<String, String> environment)
      : updateExpectations =
            environment[EnvironmentKeys.updateExpectations] == "true";

  @override
  bool get canBeFixWithUpdateExpectations => true;

  @override
  String get updateExpectationsOption =>
      '${EnvironmentKeys.updateExpectations}=true';
}
