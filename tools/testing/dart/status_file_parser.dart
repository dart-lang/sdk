// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("status_file_parser");


#import("status_expression.dart");

// Possible outcomes of running a test.
final CRASH = "Crash";
final TIMEOUT = "Timeout";
final FAIL = "Fail";
final PASS = "Pass";
// An indication to skip the test.  The caller is responsible for skipping it.
final SKIP = "Skip";

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
 
TestExpectationsMap ReadTestExpectations(String statusFilePath, environment) {
  List<Section> sections = new List<Section>();
  ReadConfigurationInto(statusFilePath, sections);

  TestExpectationsMap map = new TestExpectationsMap();
  for (Section section in sections) {
    if (section.isEnabled(environment)) {
      for (var rule in section.testRules) {
        map.addTest(rule, environment);
      }
    }
  }
  return map;
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
    if (line == "") continue;

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


class TestExpectationsMap {
  Map<String, Set<String>> map;

  TestExpectationsMap() : map = new Map<String, Set<String>>();

  void addTest(testRule, environment) {
    map[testRule.name] = testRule.expression.evaluate(environment);
  }

  Set<String> expectations(String filename) {
    var result = map[filename];
    return result != null ? result : new Set.from([PASS]);
  }
}
