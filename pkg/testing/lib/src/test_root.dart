// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.test_root;

import 'dart:async' show Future;

import 'dart:convert' show json;

import 'dart:io' show File;

import '../testing.dart' show Chain;

import 'analyze.dart' show Analyze;

import 'suite.dart' show Dart, Suite;

/// Records properties of a test root. The information is read from a JSON file.
///
/// Example with comments:
///     {
///       # Path to the `.packages` file used.
///       "packages": "test/.packages",
///       # A list of test suites (collection of tests).
///       "suites": [
///         # A list of suite objects. See the subclasses of [Suite] below.
///       ],
///       "analyze": {
///         # Uris to analyze.
///         "uris": [
///           "lib/",
///           "bin/dartk.dart",
///           "bin/repl.dart",
///           "test/log_analyzer.dart",
///           "third_party/testing/lib/"
///         ],
///         # Regular expressions of file names to ignore when analyzing.
///         "exclude": [
///           "/third_party/dart-sdk/pkg/compiler/",
///           "/third_party/kernel/"
///         ]
///       }
///     }
class TestRoot {
  final Uri packages;

  final List<Suite> suites;

  TestRoot(this.packages, this.suites);

  Analyze get analyze => suites.last;

  List<Uri> get urisToAnalyze => analyze.uris;

  List<RegExp> get excludedFromAnalysis => analyze.exclude;

  Iterable<Dart> get dartSuites {
    return new List<Dart>.from(suites.where((Suite suite) => suite is Dart));
  }

  Iterable<Chain> get toolChains {
    return new List<Chain>.from(suites.where((Suite suite) => suite is Chain));
  }

  String toString() {
    return "TestRoot($suites, $urisToAnalyze)";
  }

  static Future<TestRoot> fromUri(Uri uri) async {
    String jsonText = await new File.fromUri(uri).readAsString();
    Map data = json.decode(jsonText);

    addDefaults(data);

    Uri packages = uri.resolve(data["packages"]);

    List<Suite> suites = new List<Suite>.from(
        data["suites"].map((Map json) => new Suite.fromJsonMap(uri, json)));

    Analyze analyze = await Analyze.fromJsonMap(uri, data["analyze"], suites);

    suites.add(analyze);

    return new TestRoot(packages, suites);
  }

  static void addDefaults(Map data) {
    data.putIfAbsent("packages", () => ".packages");
    data.putIfAbsent("suites", () => []);
    Map analyze = data.putIfAbsent("analyze", () => {});
    analyze.putIfAbsent("uris", () => []);
    analyze.putIfAbsent("exclude", () => []);
  }
}
