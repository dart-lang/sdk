// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library("status_file_parser");


#import("status_expression.dart");

final RegExp StripComment = const RegExp("^[^#]*");
final RegExp HeaderPattern = const RegExp(@"\[([^\]]+)\]");
final RegExp RulePattern = const RegExp(@"\s*([^: ]*)\s*:(.*)");
final RegExp PrefixPattern = const RegExp(@"^\s*prefix\s+([\w\_\.\-\/]+)\s*$");

// TODO(whesse): Implement configuration_info library that contains data
// structures for test configuration, including Section.
class Section {
  BooleanExpression condition;
  Collection testSettings = const [];

  Section.always() : condition = null;
  Section(this.condition);
}


// Helper method to be able to run the test from the runtime
// directory, or the top directory.
String getFilename(String path) =>
    new File(path).existsSync() ? path : '../$path';

String getDirname(String path) =>
    new Directory(path).existsSync() ? path : '../$path';

 
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
      String path = prefix + match[1].trim();
      String expression_string = match[2].trim();
      List<String> tokens = new Tokenizer(expression_string).tokenize();
      SetExpression expression =
          new ExpressionParser(new Scanner(tokens)).parseSetExpression();
      // TODO(whesse): Save rule in configuration data structure.
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

