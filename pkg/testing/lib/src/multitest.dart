// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library testing.multitest;

import 'dart:async' show Stream, StreamTransformer;

import 'dart:io' show Directory, File;

import 'log.dart' show splitLines;

import 'test_description.dart' show TestDescription;

bool isError(Set<String> expectations) {
  if (expectations.contains("compile-time error")) return true;
  if (expectations.contains("runtime error")) return true;
  return false;
}

bool isCheckedModeError(Set<String> expectations) {
  if (expectations.contains("checked mode compile-time error")) return true;
  if (expectations.contains("dynamic type error")) return true;
  return isError(expectations);
}

class MultitestTransformer
    implements StreamTransformer<TestDescription, TestDescription> {
  static RegExp multitestMarker = new RegExp(r"//[#/]");
  static int _multitestMarkerLength = 3;

  static const List<String> validOutcomesList = const <String>[
    "ok",
    "syntax error",
    "compile-time error",
    "runtime error",
    "static type warning",
    "dynamic type error",
    "checked mode compile-time error",
  ];

  static final Set<String> validOutcomes =
      new Set<String>.from(validOutcomesList);

  Stream<TestDescription> bind(Stream<TestDescription> stream) async* {
    List<String> errors = <String>[];
    reportError(String error) {
      errors.add(error);
      print(error);
    }

    nextTest:
    await for (TestDescription test in stream) {
      String contents = await test.file.readAsString();
      if (!contents.contains(multitestMarker)) {
        yield test;
        continue nextTest;
      }
      // Note: this is modified in the loop below.
      List<String> linesWithoutAnnotations = <String>[];
      Map<String, List<String>> testsAsLines = <String, List<String>>{
        "none": linesWithoutAnnotations,
      };
      Map<String, Set<String>> outcomes = <String, Set<String>>{
        "none": new Set<String>(),
      };
      int lineNumber = 0;
      for (String line in splitLines(contents)) {
        lineNumber++;
        int index = line.indexOf(multitestMarker);
        String subtestName;
        List<String> subtestOutcomesList;
        if (index != -1) {
          String annotationText =
              line.substring(index + _multitestMarkerLength).trim();
          index = annotationText.indexOf(":");
          if (index != -1) {
            subtestName = annotationText.substring(0, index).trim();
            subtestOutcomesList = annotationText
                .substring(index + 1)
                .split(",")
                .map((s) => s.trim())
                .toList();
            if (subtestName == "none") {
              reportError(test.formatError(
                  "$lineNumber: $subtestName can't be used as test name."));
              continue nextTest;
            }
            if (subtestOutcomesList.isEmpty) {
              reportError(test
                  .formatError("$lineNumber: Expected <testname>:<outcomes>"));
              continue nextTest;
            }
          }
        }
        if (subtestName != null) {
          List<String> lines = testsAsLines.putIfAbsent(subtestName,
              () => new List<String>.from(linesWithoutAnnotations));
          lines.add(line);
          Set<String> subtestOutcomes =
              outcomes.putIfAbsent(subtestName, () => new Set<String>());
          if (subtestOutcomesList.length != 1 ||
              subtestOutcomesList.single != "continued") {
            for (String outcome in subtestOutcomesList) {
              if (validOutcomes.contains(outcome)) {
                subtestOutcomes.add(outcome);
              } else {
                reportError(test.formatError(
                    "$lineNumber: '$outcome' isn't a recognized outcome."));
                continue nextTest;
              }
            }
          }
        } else {
          for (List<String> lines in testsAsLines.values) {
            // This will also modify [linesWithoutAnnotations].
            lines.add(line);
          }
        }
      }
      Uri root = Uri.base.resolve("generated/");
      Directory generated = new Directory.fromUri(root.resolve(test.shortName));
      generated = await generated.create(recursive: true);
      for (String name in testsAsLines.keys) {
        List<String> lines = testsAsLines[name];
        Uri uri = generated.uri.resolve("${name}_generated.dart");
        TestDescription subtest =
            new TestDescription(root, new File.fromUri(uri));
        subtest.multitestExpectations = outcomes[name];
        await subtest.file.writeAsString(lines.join(""));
        yield subtest;
      }
    }
    if (errors.isNotEmpty) {
      throw "Error: ${errors.join("\n")}";
    }
  }
}
