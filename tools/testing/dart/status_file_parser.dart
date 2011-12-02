// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("status_file_parser");


#import("status_expression.dart");

// Possible outcomes of running a test.
final CRASH = "crash";
final TIMEOUT = "timeout";
final FAIL = "fail";
final PASS = "pass";
// An indication to skip the test.  The caller is responsible for skipping it.
final SKIP = "skip";

final RegExp StripComment = const RegExp("^[^#]*");
final RegExp HeaderPattern = const RegExp(@"^\[([^\]]+)\]");
final RegExp RulePattern = const RegExp(@"\s*([^: ]*)\s*:(.*)");
final RegExp PrefixPattern = const RegExp(@"^\s*prefix\s+([\w\_\.\-\/]+)\s*$");

// TODO(whesse): Implement configuration_info library that contains data
// structures for test configuration, including Section.
class Section {
  BooleanExpression condition;
  List<TestRule> testRules;

  Section.always() : condition = null, testRules = new List<TestRule>();
  Section(this.condition) : testRules = new List<TestRule>();

  bool isEnabled(environment) =>
      condition == null || condition.evaluate(environment);
}


// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    new File(path).existsSync() ? path : '../$path';

String getDirname(String path) =>
    new Directory(path).existsSync() ? path : '../$path';

void ReadTestExpectationsInto(TestExpectations expectations,
                              String statusFilePath,
                              environment) {
  List<Section> sections = new List<Section>();
  ReadConfigurationInto(statusFilePath, sections);

  for (Section section in sections) {
    if (section.isEnabled(environment)) {
      for (var rule in section.testRules) {
        expectations.addRule(rule, environment);
      }
    }
  }
}

void ReadConfigurationInto(path, sections) {
  File file = new File(getFilename(path));
  if (!file.existsSync()) return;  // TODO(whesse): Handle missing file.
  FileInputStream file_stream = file.openInputStream();
  StringInputStream lines = new StringInputStream(file_stream);

  Section current = new Section.always();
  sections.add(current);
  String prefix = "";

  String line;
  while ((line = lines.readLine()) != null) {
    Match match = StripComment.firstMatch(line);
    line = (match == null) ? "" : match[0];
    line = line.trim();
    if (line.isEmpty()) continue;

    match = HeaderPattern.firstMatch(line);
    if (match != null) {
      String condition_string = match[1].trim();
      List<String> tokens = new Tokenizer(condition_string).tokenize();
      ExpressionParser parser = new ExpressionParser(new Scanner(tokens));
      current = new Section(parser.parseBooleanExpression());
      sections.add(current);
      continue;
    }

    match = RulePattern.firstMatch(line);
    if (match != null) {
      String name = match[1].trim();
      // TODO(whesse): Handle test names ending in a wildcard (*).
      String expression_string = match[2].trim();
      List<String> tokens = new Tokenizer(expression_string).tokenize();
      SetExpression expression =
          new ExpressionParser(new Scanner(tokens)).parseSetExpression();
      current.testRules.add(new TestRule(name, expression));
      continue;
    }

    match = PrefixPattern.firstMatch(line);
    if (match != null) {
      prefix = match[1];
      continue;
    }

    print("unmatched line: $line");
  }

  file_stream.close();
}


class TestRule {
  String name;
  SetExpression expression;

  TestRule(this.name, this.expression);
}


class TestExpectations {
  bool _complexMatching;
  Map _map;
  bool _preprocessed = false;
  Map _regExpCache;
  Map _keyToRegExps;

  /**
   * Create a TestExpectations object. Optionally specify
   * complexMatching behavior. See the [expectations] method
   * for an explanation of matching.
   */
  TestExpectations([bool complexMatching = false])
      : _complexMatching = complexMatching,
        _map = new Map();

  /**
   * Add a rule to the expectations.
   */
  void addRule(testRule, environment) {
    // Once we have started using the expectations we cannot add more
    // rules.
    if (_preprocessed) {
      throw "TestExpectations.addRule: cannot add more rules";
    }
    var values = testRule.expression.evaluate(environment);
    _map.putIfAbsent(testRule.name, () => new Set()).addAll(values);
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
   *
   * If Complex matching is required the last filename component is
   * translated into multiple components. If the last filename
   * component starts with the second-to-last filename component that
   * part is removed from the last filename component. Then the last
   * component is split into more components at '_'s.
   *
   * Examples of complext filename component splits:
   *
   * a/b/c/d_e_f/d_e_f_A01_t01 -> ['a', 'b', 'c', 'd_e_f', 'A01', 't01']
   * a/b/c/d_e_f_A01_t01 -> ['a', 'b', 'c', 'd', 'e', 'f', 'A01', 't01']
   */
  Set<String> expectations(String filename) {
    var result = new Set();
    var splitFilename = filename.split(new Platform().pathSeparator());

    // If complex matching is required split the last filename
    // component at '_'. Additionally, remove the prefix of the last
    // component if it is identical to the second-to-last component.
    if (_complexMatching && splitFilename.length >= 2) {
      var last = splitFilename.removeLast();
      var secondToLast = splitFilename.last();
      if (last.startsWith(secondToLast)) {
        last = last.substring(secondToLast.length);
      }
      last.split('_').forEach((component) {
        if (!component.isEmpty()) {
          splitFilename.add(component);
        }
      });
    }

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
    if (result.isEmpty()) {
      result.add(PASS);
    }
    return result;
  }

  // Preprocess the expectations for matching against
  // filenames. Generate lists of regular expressions once and for all
  // for each key.
  void _preprocessForMatching() {
    if (_preprocessed) return;

    _keyToRegExps = new Map();
    _regExpCache = new Map();

    _map.forEach((key, expectations) {
      if (_keyToRegExps[key] != null) return;
      var splitKey = key.split('/');
      var regExps = new List(splitKey.length);
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
