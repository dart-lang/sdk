// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_test;

import "dart:async" show Future;

import "dart:convert" show JsonEncoder;

import "dart:io" show File;

import "package:testing/testing.dart"
    show Chain, ChainContext, Result, Step, TestDescription, runMe;

import "package:yaml/yaml.dart" show YamlMap, loadYamlNode;

import "incremental_expectations.dart"
    show IncrementalExpectation, extractJsonExpectations;

import "incremental_source_files.dart" show expandDiff, expandUpdates;

const JsonEncoder json = const JsonEncoder.withIndent("  ");

class Context extends ChainContext {
  final List<Step> steps = const <Step>[
    const ReadTest(),
  ];

  const Context();
}

class ReadTest extends Step<TestDescription, TestCase, Context> {
  const ReadTest();

  String get name => "read test";

  Future<Result<TestCase>> run(
      TestDescription description, Context context) async {
    Uri uri = description.uri;
    String contents = await new File.fromUri(uri).readAsString();
    Map<String, List<String>> sources = <String, List<String>>{};
    List<IncrementalExpectation> expectations;
    bool firstPatch = true;
    YamlMap map = loadYamlNode(contents, sourceUrl: uri);
    map.forEach((_fileName, _contents) {
      String fileName = _fileName; // Strong mode hurray!
      String contents = _contents; // Strong mode hurray!
      if (fileName.endsWith(".patch")) {
        if (firstPatch) {
          expectations = extractJsonExpectations(contents);
        }
        sources[fileName] = expandUpdates(expandDiff(contents));
        firstPatch = false;
      } else {
        sources[fileName] = <String>[contents];
      }
    });
    return new TestCase(sources, expectations).validate(this);
  }
}

class TestCase {
  final Map<String, List<String>> sources;
  final List<IncrementalExpectation> expectations;

  const TestCase(this.sources, this.expectations);

  String toString() {
    return "TestCase(${json.convert(sources)}, ${json.convert(expectations)})";
  }

  Result<TestCase> validate(Step<dynamic, TestCase, ChainContext> step) {
    print(this);
    if (sources == null) {
      return step.fail(this, "No sources.");
    }
    if (expectations == null || expectations.isEmpty) {
      return step.fail(this, "No expectations.");
    }
    for (String name in sources.keys) {
      List<String> versions = sources[name];
      if (versions.length != 1 && versions.length != expectations.length) {
        return step.fail(
            this,
            "Found ${versions.length} versions of $name,"
            " but expected 1 or ${expectations.length}.");
      }
    }
    return step.pass(this);
  }
}

Future<Context> createContext(Chain suite, Map<String, String> environment) {
  return new Future<Context>.value(const Context());
}

main([List<String> arguments = const []]) =>
    runMe(arguments, createContext, "../../testing.json");
