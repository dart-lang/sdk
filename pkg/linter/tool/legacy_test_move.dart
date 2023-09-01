// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math' as math;

// ignore_for_file: avoid_print

/// This is an interactive script that automates parts of the process to move
/// a legacy test to a reflective test.
void main(List<String> args) {
  if (args.isEmpty) {
    print('Usage: legacy_test_move.dart <rule_name>');
    exit(1);
  }
  var ruleName = args.first;
  LegacyTestMover(ruleName).move();
}

class LegacyTestMover {
  final String ruleName;

  LegacyTestMover(this.ruleName);

  String get newTestFileHeader {
    var ruleNameCamelCase = ruleName.splitMapJoin(RegExp('(?:^|_)([a-z])'),
        onMatch: (m) => m[1]!.toUpperCase());
    return '''
// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(${ruleNameCamelCase}Test);
  });
}

@reflectiveTest
class ${ruleNameCamelCase}Test extends LintRuleTest {
  @override
  String get lintRule => '$ruleName';

''';
  }

  List<String> gatherSnippets(List<String> legacyLines) {
    var snippets = <String>[];
    var startIndex = 0;
    var endIndex = math.min(legacyLines.length, 40);
    while (startIndex < legacyLines.length) {
      for (var index = startIndex; index < endIndex; index++) {
        print('${index.toString().padLeft(3)}  ${legacyLines[index]}');
      }
      var ranges = getRanges();
      if (ranges.isEmpty) {
        // Blank input.
        break;
      }
      var snippet = <String>[];
      for (var range in ranges) {
        snippet.addAll(legacyLines.getRange(range.start, range.end + 1));
      }
      snippets.add(snippet.join('\n'));
      startIndex = math.max(0, ranges.first.start - 3);
      endIndex = math.min(legacyLines.length, startIndex + 40);
    }
    return snippets;
  }

  List<Range> getRanges() {
    List<String> lineRanges;
    while (true) {
      stdout.write('Comma-separated lines and ranges (e.g. 1,3,5-7,9-11): ');
      var input = stdin.readLineSync();
      if (input == null) {
        print('Received empty and EOF?');
        // Blank line and EOF?
        exit(1);
      }
      if (input.isEmpty) {
        // Blank input.
        return [];
      }
      if (RegExp(r'[^0-9\-,]').firstMatch(input) != null) {
        print('Bad characters in: $input');
        continue;
      }
      lineRanges = input.split(',');
      break;
    }

    var ranges = <Range>[];
    for (var rangeText in lineRanges) {
      var singleNumber = RegExp(r'^([0-9]+)$').firstMatch(rangeText);
      if (singleNumber != null) {
        var index = int.tryParse(singleNumber[1]!);
        if (index != null) {
          ranges.add(Range(index, index));
        }
      }
      var range = RegExp(r'^([0-9]+)-([0-9]+)$').firstMatch(rangeText);
      if (range != null) {
        var start = int.tryParse(range[1]!);
        var end = int.tryParse(range[2]!);
        if (start != null && end != null) {
          ranges.add(Range(start, end));
        }
      }
      // TODO(srawlins): report error.
    }
    return ranges;
  }

  void move() {
    var legacyTest = File('test_data/rules/$ruleName.dart');
    if (!legacyTest.existsSync()) {
      print('Did not find ${legacyTest.path}!!');
      return;
    }

    var newTest = File('test/rules/${ruleName}_test.dart');
    var newTestExists = newTest.existsSync();

    var legacyLines = legacyTest.readAsLinesSync();

    var snippets = gatherSnippets(legacyLines);

    // [snippets] is now our complete list of snippets.

    var buffer = StringBuffer();
    if (newTestExists) {
      var existingNewTestLines = newTest.readAsLinesSync();
      var classCloseIndex = existingNewTestLines
          .lastIndexWhere((element) => element.startsWith(RegExp('^}')));
      existingNewTestLines.take(classCloseIndex).forEach(buffer.writeln);
      buffer.writeln();
    } else {
      buffer.write(newTestFileHeader);
    }
    for (var testIndex = 0; testIndex < snippets.length; testIndex++) {
      var snippet = snippets[testIndex];
      buffer.writeln(testBody(testIndex.toString(), snippet));
      buffer.writeln();
    }
    buffer.writeln('}');
    newTest.writeAsStringSync(buffer.toString());

    if (!newTestExists) {
      updateAllTestFile();
    }

    print('''
You probably want to run these:

    dart format test/rules/all.dart
    git rm ${legacyTest.path}
    git add test
    dart ${newTest.path}
''');
  }

  String testBody(String name, String code) => code.contains('LINT')
      ? """
  test_$name() async {
    await assertDiagnostics(r'''
$code
''', [
  // TODO
]);
  }
"""
      : """
  test_$name() async {
    await assertNoDiagnostics(r'''
$code
''');
  }
""";

  void updateAllTestFile() {
    var allTest = File('test/rules/all.dart');
    var allTestLines = allTest.readAsLinesSync();
    var allTestBuffer = StringBuffer();
    var allTestIndex = 0;

    // Insert the import, alphabetically.
    while (true) {
      if (allTestIndex >= allTestLines.length) {
        print('bad allTestIndex: $allTestIndex');
        return;
      }
      var line = allTestLines[allTestIndex];
      allTestIndex++;
      var importMatch = RegExp(r"^import '(.*)_test.dart'").firstMatch(line);
      if (importMatch == null) {
        allTestBuffer.writeln(line);
        continue;
      }
      var importPrefix = importMatch[1]!;
      var comparison = importPrefix.compareTo(ruleName);
      if (comparison == 0) {
        print('Got same name?!');
        allTestBuffer.writeln(line);
        break;
      } else if (comparison < 0) {
        // Before; keep going.
        allTestBuffer.writeln(line);
      } else {
        // After; the new import comes just before this one.
        allTestBuffer.writeln("import '${ruleName}_test.dart' as $ruleName;");
        allTestBuffer.writeln(line);
        break;
      }
    }

    // Insert the main call, alphabetically.
    while (true) {
      if (allTestIndex >= allTestLines.length) {
        print('bad allTestIndex: $allTestIndex.');
        return;
      }
      var line = allTestLines[allTestIndex];
      allTestIndex++;
      var runMatch = RegExp(r'^  (.*)\.main\(\);').firstMatch(line);
      if (runMatch == null) {
        allTestBuffer.writeln(line);
        continue;
      }
      var testPrefix = runMatch[1]!;
      var comparison = testPrefix.compareTo(ruleName);
      if (comparison == 0) {
        print('Got same name?!');
        allTestBuffer.writeln(line);
        break;
      } else if (comparison < 0) {
        // Before; keep going.
        allTestBuffer.writeln(line);
      } else {
        // After; the new import comes just before this one.
        allTestBuffer.writeln('  $ruleName.main();');
        allTestBuffer.writeln(line);
        break;
      }
    }

    // Insert the rest of the file.
    while (allTestIndex < allTestLines.length) {
      var line = allTestLines[allTestIndex];
      allTestIndex++;
      allTestBuffer.writeln(line);
    }

    allTest.writeAsStringSync(allTestBuffer.toString());
  }
}

class Range {
  final int start;
  final int end;
  Range(this.start, this.end);
}
