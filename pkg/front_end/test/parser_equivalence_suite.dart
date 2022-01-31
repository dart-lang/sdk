// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import "package:yaml/yaml.dart" show YamlMap, loadYamlNode;

import 'package:testing/testing.dart'
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import 'testing_utils.dart' show checkEnvironment;

import 'parser_suite.dart'
    show ListenerStep, ParserTestListenerWithMessageFormatting;

void main([List<String> arguments = const []]) => runMe(
      arguments,
      createContext,
      configurationPath: "../testing.json",
    );

Future<Context> createContext(
    Chain suite, Map<String, String> environment) async {
  const Set<String> knownEnvironmentKeys = {};
  checkEnvironment(environment, knownEnvironmentKeys);

  return new Context(suite.name);
}

class Context extends ChainContext {
  final String suiteName;

  Context(this.suiteName);

  @override
  final List<Step> steps = const <Step>[
    const ListenerCompareStep(),
  ];
}

class ListenerCompareStep
    extends Step<TestDescription, TestDescription, Context> {
  const ListenerCompareStep();

  @override
  String get name => "listenerCompare";

  @override
  Future<Result<TestDescription>> run(
      TestDescription description, Context context) {
    Uri uri = description.uri;
    String contents = new File.fromUri(uri).readAsStringSync();
    YamlMap yaml = loadYamlNode(contents, sourceUrl: uri) as YamlMap;
    List<Uri> files =
        (yaml["files"] as List).map((s) => uri.resolve(s)).toList();
    Set<String> filters = new Set<String>.from(yaml["filters"] ?? []);
    Set<String> ignored = new Set<String>.from(yaml["ignored"] ?? []);

    ParserTestListenerWithMessageFormatting? parserTestListenerFirst =
        ListenerStep.doListenerParsing(
      files[0],
      context.suiteName,
      description.shortName,
    );
    if (parserTestListenerFirst == null) {
      return Future.value(crash(description, StackTrace.current));
    }

    for (int i = 1; i < files.length; i++) {
      ParserTestListenerWithMessageFormatting? parserTestListener =
          ListenerStep.doListenerParsing(
        files[i],
        context.suiteName,
        description.shortName,
      );
      if (parserTestListener == null) {
        return Future.value(crash(description, StackTrace.current));
      }
      String? compareResult = compare(
          parserTestListenerFirst, parserTestListener, filters, ignored);
      if (compareResult != null) {
        return Future.value(
            fail(description, compareResult, StackTrace.current));
      }
    }

    return new Future.value(new Result<TestDescription>.pass(description));
  }

  String? compare(
      ParserTestListenerWithMessageFormatting a,
      ParserTestListenerWithMessageFormatting b,
      Set<String> filters,
      Set<String> ignored) {
    List<String> aLines = a.sb.toString().split("\n");
    List<String> bLines = b.sb.toString().split("\n");

    bool doRemoveListenerArguments =
        filters.contains("ignoreListenerArguments");

    int aIndex = 0;
    int bIndex = 0;
    while (aIndex < aLines.length && bIndex < bLines.length) {
      String aLine = aLines[aIndex];
      String bLine = bLines[bIndex];
      if (doRemoveListenerArguments) {
        aLine = removeListenerArguments(aLine);
        bLine = removeListenerArguments(bLine);
      }
      bool anyIgnored = false;
      if (ignored.contains(aLine.trim())) {
        anyIgnored = true;
        aIndex++;
      }
      if (ignored.contains(bLine.trim())) {
        anyIgnored = true;
        bIndex++;
      }
      if (anyIgnored) continue;
      if (aLine != bLine) {
        return "Disagreement: '${aLine}' vs '${bLine}'";
      }
      aIndex++;
      bIndex++;
    }

    // Any trailing lines?
    while (aIndex < aLines.length) {
      String aLine = aLines[aIndex];
      if (doRemoveListenerArguments) {
        aLine = removeListenerArguments(aLine);
      }
      if (ignored.contains(aLine.trim())) {
        aIndex++;
        continue;
      }
      return "Unmatched line at end: '$aLine'";
    }
    while (bIndex < bLines.length) {
      String bLine = bLines[bIndex];
      if (doRemoveListenerArguments) {
        bLine = removeListenerArguments(bLine);
      }
      if (ignored.contains(bLine.trim())) {
        bIndex++;
        continue;
      }
      return "Unmatched line at end: '$bLine'";
    }
    return null;
  }

  String removeListenerArguments(String s) {
    int index = s.indexOf("(");
    if (index < 0) return s;
    return s.substring(0, index);
  }
}
