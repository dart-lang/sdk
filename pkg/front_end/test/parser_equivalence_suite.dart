// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:front_end/src/api_prototype/experimental_flags.dart';
import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription;
import "package:yaml/yaml.dart" show YamlMap, loadYamlNode;

import 'parser_suite_utils.dart';
import 'testing/folder_options.dart';
import 'utils/suite_utils.dart';
import 'testing_utils.dart' show checkEnvironment;

void main([List<String> arguments = const []]) => internalMain(
  createContext,
  arguments: arguments,
  displayName: "parser equivalence suite",
  configurationPath: "../testing.json",
);

Future<Context> createContext(Chain suite, Map<String, String> environment) {
  const Set<String> knownEnvironmentKeys = {};
  checkEnvironment(environment, knownEnvironmentKeys);

  return new Future.value(new Context(suite.root, suite.name, environment));
}

class Context extends ChainContext implements StandardContextAdditions {
  @override
  final SuiteFolderOptions folderOptions;
  final String suiteName;
  @override
  final Map<ExperimentalFlag, bool> forcedExperimentalFlags;

  new(Uri baseUri, this.suiteName, Map<String, String> environment)
    : folderOptions = new SuiteFolderOptions(baseUri),
      forcedExperimentalFlags =
          SuiteFolderOptions.computeForcedExperimentalFlags(environment);

  @override
  final List<Step> steps = const <Step>[const ListenerCompareStep()];
}

class ListenerCompareStep
    extends Step<TestDescription, TestDescription, Context> {
  const new();

  @override
  String get name => "listenerCompare";

  @override
  Future<Result<TestDescription>> run(
    TestDescription description,
    Context context,
  ) {
    Map<ExperimentalFlag, bool> experimentalFlags = description
        .computeExplicitExperimentalFlags(context);
    Uri uri = description.uri;
    String contents = new File.fromUri(uri).readAsStringSync();
    YamlMap yaml = loadYamlNode(contents, sourceUrl: uri) as YamlMap;
    List<Uri> files = (yaml["files"] as List)
        .map((s) => uri.resolve(s))
        .toList();
    Set<String> filters = new Set<String>.from(yaml["filters"] ?? []);
    Set<String> ignored = new Set<String>.from(yaml["ignored"] ?? []);

    ParserTestListenerWithMessageFormatting? parserTestListenerFirst =
        doListenerParsing(
          files[0],
          context.suiteName,
          experimentalFlags,
          description.shortName,
        );
    if (parserTestListenerFirst == null) {
      return Future.value(crash(description, StackTrace.current));
    }

    for (int i = 1; i < files.length; i++) {
      ParserTestListenerWithMessageFormatting? parserTestListener =
          doListenerParsing(
            files[i],
            context.suiteName,
            experimentalFlags,
            description.shortName,
          );
      if (parserTestListener == null) {
        return Future.value(crash(description, StackTrace.current));
      }
      String? compareResult = compareTestListeners(
        parserTestListenerFirst,
        parserTestListener,
        filters: filters,
        ignored: ignored,
      );
      if (compareResult != null) {
        return Future.value(
          fail(description, compareResult, StackTrace.current),
        );
      }
    }

    return new Future.value(new Result<TestDescription>.pass(description));
  }
}
