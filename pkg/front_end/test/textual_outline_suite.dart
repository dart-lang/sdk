// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/scanner/abstract_scanner.dart'
    show ScannerConfiguration;
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:dart_style/dart_style.dart' show DartFormatter;
import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:front_end/src/util/textual_outline.dart';
import 'package:testing/testing.dart'
    show
        Chain,
        ChainContext,
        Expectation,
        ExpectationSet,
        Result,
        Step,
        TestDescription;

import 'utils/kernel_chain.dart' show MatchContext;
import 'utils/suite_utils.dart';
import 'testing/environment_keys.dart';
import 'testing/folder_options.dart';

const int minSupportedMajorVersion = 2;
const int minSupportedMinorVersion = 12;

const List<Map<String, String>> EXPECTATIONS = [
  {
    "name": "ExpectationFileMismatch",
    "group": "Fail",
  },
  {
    "name": "ExpectationFileMissing",
    "group": "Fail",
  },
  {
    "name": "EmptyOutput",
    "group": "Fail",
  },
  {
    "name": "UnknownChunk",
    "group": "Fail",
  },
  {
    "name": "FormatterCrash",
    "group": "Fail",
  },
];

Future<Context> createContext(Chain suite, Map<String, String> environment) {
  return new Future.value(new Context(suite.root, environment));
}

void main([List<String> arguments = const []]) => internalMain(
      createContext,
      arguments: arguments,
      displayName: "textual outline suite",
      configurationPath: "../testing.json",
    );

class Context extends ChainContext with MatchContext {
  final SuiteFolderOptions suiteFolderOptions;
  final Map<ExperimentalFlag, bool> forcedExperimentalFlags;

  @override
  final bool updateExpectations;

  @override
  String get updateExpectationsOption =>
      '${EnvironmentKeys.updateExpectations}=true';

  @override
  bool get canBeFixWithUpdateExpectations => true;

  Context(Uri baseUri, Map<String, String> environment)
      : suiteFolderOptions = new SuiteFolderOptions(baseUri),
        updateExpectations =
            environment[EnvironmentKeys.updateExpectations] == "true",
        forcedExperimentalFlags =
            SuiteFolderOptions.computeForcedExperimentalFlags(environment);

  @override
  final List<Step> steps = const <Step>[
    const TextualOutline(),
  ];

  @override
  final ExpectationSet expectationSet =
      new ExpectationSet.fromJsonList(EXPECTATIONS);
}

class TextualOutline extends Step<TestDescription, TestDescription, Context> {
  const TextualOutline();

  @override
  String get name => "TextualOutline";

  @override
  Future<Result<TestDescription>> run(
      TestDescription description, Context context) async {
    FolderOptions folderOptions =
        context.suiteFolderOptions.computeFolderOptions(description);
    Map<ExperimentalFlag, bool> experimentalFlags = folderOptions
        .computeExplicitExperimentalFlags(context.forcedExperimentalFlags);
    Map<ExperimentalFlag, bool> experimentalFlagsExplicit =
        folderOptions.computeExplicitExperimentalFlags(const {});

    Uint8List bytes = new File.fromUri(description.uri).readAsBytesSync();
    for (bool modelled in [false, true]) {
      TextualOutlineInfoForTesting info = new TextualOutlineInfoForTesting();
      String? result = textualOutline(
        bytes,
        new ScannerConfiguration(
          enableExtensionMethods: isExperimentEnabled(
              ExperimentalFlag.extensionMethods,
              explicitExperimentalFlags: experimentalFlags),
          enableNonNullable: isExperimentEnabled(ExperimentalFlag.nonNullable,
              explicitExperimentalFlags: experimentalFlags),
          enableTripleShift: isExperimentEnabled(ExperimentalFlag.tripleShift,
              explicitExperimentalFlags: experimentalFlags),
        ),
        throwOnUnexpected: true,
        performModelling: modelled,
        returnNullOnError: false,
        enablePatterns: isExperimentEnabled(ExperimentalFlag.patterns,
            explicitExperimentalFlags: experimentalFlags),
        infoForTesting: info,
      );
      if (result == null) {
        return new Result(
            null, context.expectationSet["EmptyOutput"], description.uri);
      }

      bool containsUnknownChunk = info.hasUnknownChunk;
      bool tryFormat = !containsUnknownChunk;
      for (LanguageVersionToken version in info.languageVersionTokens) {
        if (version.major < minSupportedMajorVersion) {
          tryFormat = false;
        } else if (version.major == minSupportedMajorVersion &&
            version.minor < minSupportedMinorVersion) {
          tryFormat = false;
        }
      }
      dynamic formatterException;
      StackTrace? formatterExceptionSt;
      if (tryFormat) {
        try {
          List<String> experimentFlags = [];
          for (MapEntry<ExperimentalFlag, bool> entry
              in experimentalFlags.entries) {
            if (entry.value) {
              experimentFlags.add(entry.key.name);
            }
          }

          // Default to the latest language version. If the test should be at
          // an older language version, it will contain a `// @dart=x.y`
          // comment, which takes precedence over this argument.
          result = new DartFormatter(
                  languageVersion: DartFormatter.latestLanguageVersion,
                  experimentFlags: experimentFlags)
              .format(result);
        } catch (e, st) {
          formatterException = e;
          formatterExceptionSt = st;
        }
      }

      String filename = ".textual_outline.expect";
      if (modelled) {
        filename = ".textual_outline_modelled.expect";
      }

      Result<TestDescription> expectMatch =
          await context.match<TestDescription>(
              filename, result!, description.uri, description);
      if (expectMatch.outcome != Expectation.pass) return expectMatch;

      if (containsUnknownChunk) {
        return new Result(
            null, context.expectationSet["UnknownChunk"], description.uri);
      }

      if (formatterException != null && !info.hasParserErrors) {
        bool hasUnreleasedExperiment = false;
        for (MapEntry<ExperimentalFlag, bool> entry
            in experimentalFlagsExplicit.entries) {
          if (entry.value) {
            if (!entry.key.isEnabledByDefault) {
              hasUnreleasedExperiment = true;
              break;
            }
          }
        }
        if (!hasUnreleasedExperiment) {
          return new Result(null, context.expectationSet["FormatterCrash"],
              formatterException,
              trace: formatterExceptionSt);
        }
      }
    }

    return new Result.pass(description);
  }
}
