// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test_dart_copy.status_file_parser;

import "dart:async";
import "dart:convert" show LineSplitter, utf8;
import "dart:io";

import "path.dart";
import "status_expression.dart";

import '../expectation.dart' show Expectation, ExpectationSet;

final RegExp SplitComment = new RegExp("^([^#]*)(#.*)?\$");
final RegExp HeaderPattern = new RegExp(r"^\[([^\]]+)\]");
final RegExp RulePattern = new RegExp(r"\s*([^: ]*)\s*:(.*)");
final RegExp IssueNumberPattern = new RegExp("[Ii]ssue ([0-9]+)");

class StatusFile {
  final Path location;

  StatusFile(this.location);
}

// TODO(whesse): Implement configuration_info library that contains data
// structures for test configuration, including Section.
class Section {
  final StatusFile statusFile;

  final BooleanExpression condition;
  final List<TestRule> testRules;
  final int lineNumber;

  Section.always(this.statusFile, this.lineNumber)
      : condition = null,
        testRules = new List<TestRule>();
  Section(this.statusFile, this.condition, this.lineNumber)
      : testRules = new List<TestRule>();

  bool isEnabled(Map<String, String> environment) =>
      condition == null || condition.evaluate(environment);

  String toString() {
    return "Section: $condition";
  }
}

Future<TestExpectations> ReadTestExpectations(List<String> statusFilePaths,
    Map<String, String> environment, ExpectationSet expectationSet) {
  var testExpectations = new TestExpectations(expectationSet);
  return Future.wait(statusFilePaths.map((String statusFile) {
    return ReadTestExpectationsInto(testExpectations, statusFile, environment);
  })).then((_) => testExpectations);
}

Future<void> ReadTestExpectationsInto(TestExpectations expectations,
    String statusFilePath, Map<String, String> environment) {
  var completer = new Completer();
  List<Section> sections = new List<Section>();

  void sectionsRead() {
    for (Section section in sections) {
      if (section.isEnabled(environment)) {
        for (var rule in section.testRules) {
          expectations.addRule(rule, environment);
        }
      }
    }
    completer.complete();
  }

  ReadConfigurationInto(new Path(statusFilePath), sections, sectionsRead);
  return completer.future;
}

void ReadConfigurationInto(Path path, List<Section> sections, void onDone()) {
  StatusFile statusFile = new StatusFile(path);
  File file = new File(path.toNativePath());
  if (!file.existsSync()) {
    throw new Exception('Cannot find test status file $path');
  }
  int lineNumber = 0;
  Stream<String> lines = file
      .openRead()
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(new LineSplitter());

  Section currentSection = new Section.always(statusFile, -1);
  sections.add(currentSection);

  lines.listen((String line) {
    lineNumber++;
    Match match = SplitComment.firstMatch(line);
    line = (match == null) ? "" : match[1];
    line = line.trim();
    if (line.isEmpty) return;

    // Extract the comment to get the issue number if needed.
    String comment = (match == null || match[2] == null) ? "" : match[2];

    match = HeaderPattern.firstMatch(line);
    if (match != null) {
      String condition_string = match[1].trim();
      List<String> tokens = new Tokenizer(condition_string).tokenize();
      ExpressionParser parser = new ExpressionParser(new Scanner(tokens));
      currentSection =
          new Section(statusFile, parser.parseBooleanExpression(), lineNumber);
      sections.add(currentSection);
      return;
    }

    match = RulePattern.firstMatch(line);
    if (match != null) {
      String name = match[1].trim();
      // TODO(whesse): Handle test names ending in a wildcard (*).
      String expression_string = match[2].trim();
      List<String> tokens = new Tokenizer(expression_string).tokenize();
      SetExpression expression =
          new ExpressionParser(new Scanner(tokens)).parseSetExpression();

      // Look for issue number in comment.
      String issueString = null;
      match = IssueNumberPattern.firstMatch(comment);
      if (match != null) {
        issueString = match[1];
        if (issueString == null) issueString = match[2];
      }
      int issue = issueString != null ? int.parse(issueString) : null;
      currentSection.testRules
          .add(new TestRule(name, expression, issue, lineNumber));
      return;
    }

    print("unmatched line: $line");
  }, onDone: onDone);
}

class TestRule {
  String name;
  SetExpression expression;
  int issue;
  int lineNumber;

  TestRule(this.name, this.expression, this.issue, this.lineNumber);

  bool get hasIssue => issue != null;

  String toString() => 'TestRule($name, $expression, $issue)';
}

class TestExpectations {
  // Only create one copy of each Set<Expectation>.
  // We just use .toString as a key, so we may make a few
  // sets that only differ in their toString element order.
  static Map<String, Set<Expectation>> _cachedSets = {};

  final ExpectationSet expectationSet;

  Map<String, Set<Expectation>> _map;
  bool _preprocessed = false;
  Map<String, RegExp> _regExpCache;
  Map<String, List<RegExp>> _keyToRegExps;

  /**
   * Create a TestExpectations object. See the [expectations] method
   * for an explanation of matching.
   */
  TestExpectations(this.expectationSet) : _map = {};

  /**
   * Add a rule to the expectations.
   */
  void addRule(TestRule testRule, Map<String, String> environment) {
    // Once we have started using the expectations we cannot add more
    // rules.
    if (_preprocessed) {
      throw "TestExpectations.addRule: cannot add more rules";
    }
    var names = testRule.expression.evaluate(environment);
    var expectations = names.map((name) => expectationSet[name]);
    _map.putIfAbsent(testRule.name, () => new Set()).addAll(expectations);
  }

  /**
   * Compute the expectations for a test based on the filename.
   *
   * For every (key, expectation) pair. Match the key with the file
   * name. Return the union of the expectations for all the keys
   * that match.
   *
   * Normal matching splits the key and the filename into path
   * components and checks that the anchored regular expression
   * "^$keyComponent\$" matches the corresponding filename component.
   */
  Set<Expectation> expectations(String filename) {
    var result = new Set<Expectation>();
    var splitFilename = filename.split('/');

    // Create mapping from keys to list of RegExps once and for all.
    _preprocessForMatching();

    _map.forEach((key, expectation) {
      List regExps = _keyToRegExps[key];
      if (regExps.length > splitFilename.length) return;
      for (var i = 0; i < regExps.length; i++) {
        if (!regExps[i].hasMatch(splitFilename[i])) return;
      }
      // If all components of the status file key matches the filename
      // add the expectations to the result.
      result.addAll(expectation);
    });

    // If no expectations were found the expectation is that the test
    // passes.
    if (result.isEmpty) {
      result.add(Expectation.Pass);
    }
    return _cachedSets.putIfAbsent(result.toString(), () => result);
  }

  // Preprocess the expectations for matching against
  // filenames. Generate lists of regular expressions once and for all
  // for each key.
  void _preprocessForMatching() {
    if (_preprocessed) return;

    _keyToRegExps = {};
    _regExpCache = {};

    _map.forEach((key, expectations) {
      if (_keyToRegExps[key] != null) return;
      var splitKey = key.split('/');
      var regExps = new List<RegExp>(splitKey.length);
      for (var i = 0; i < splitKey.length; i++) {
        var component = splitKey[i];
        var regExp = _regExpCache[component];
        if (regExp == null) {
          var pattern = "^${splitKey[i]}\$".replaceAll('*', '.*');
          regExp = new RegExp(pattern);
          _regExpCache[component] = regExp;
        }
        regExps[i] = regExp;
      }
      _keyToRegExps[key] = regExps;
    });

    _regExpCache = null;
    _preprocessed = true;
  }
}
