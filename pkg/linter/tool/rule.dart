// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:analyzer/src/lint/registry.dart';
import 'package:analyzer/src/lint/state.dart';
import 'package:args/args.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/rules.dart';
import 'package:linter/src/utils.dart';
import 'package:path/path.dart' as path;

import '../test/test_constants.dart';
import 'changelog.dart';
import 'since.dart';

/// Generates rule and rule test stub files (into `src/rules` and `test/rules`
/// respectively), as well as the rule index (`rules.dart`).
void main(List<String> args) {
  var parser = ArgParser()
    ..addOption('out', abbr: 'o', help: 'Specifies project root.')
    ..addOption(
      'name',
      abbr: 'n',
      help: 'Specifies lower_underscore rule name.',
      mandatory: true,
    );

  ArgResults options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'] ?? '.';
  var d = Directory(outDir as String);
  if (!d.existsSync()) {
    printToConsole("Directory '${d.path}' does not exist");
    return;
  }

  var ruleName = options['name'];

  if (ruleName == null) {
    printUsage(parser);
    return;
  }

  // Generate rule stub and update supporting files.
  generateRule(ruleName as String, outDir: outDir);
}

var _supportsTestMode = ['use_build_context_synchronously'];

String get _thisYear => DateTime.now().year.toString();

String capitalize(String s) => s.substring(0, 1).toUpperCase() + s.substring(1);

void generateFile(String ruleName, String stubPath, Generator generator,
    {String? outDir, bool overwrite = false, bool format = false}) {
  var (:file, :contents) = generator(ruleName, toClassName(ruleName));
  if (outDir != null) {
    var outPath = path.join(outDir, stubPath, file);
    var outFile = File(outPath);
    if (!overwrite && outFile.existsSync()) {
      printToConsole('Warning: stub already exists at $outPath; skipping');
      return;
    }
    printToConsole('Writing to $outPath');
    outFile.writeAsStringSync(contents);
    if (format) {
      Process.runSync('dart', ['format', '-o', 'write', outPath]);
    }
  } else {
    printToConsole(contents);
  }
}

void generateRule(String ruleName, {String? outDir}) {
  // Generate rule stub.
  generateFile(ruleName, path.join('lib', 'src', 'rules'), _generateClass,
      outDir: outDir);

  // Generate unit test stub.
  generateFile(ruleName, ruleTestDir, _generateTest, outDir: outDir);

  // Generate test `all.dart` helper.
  generateFile(ruleName, ruleTestDir, _generateAllTestsFile,
      outDir: outDir, overwrite: true, format: true);

  // Generate an example `all.yaml`
  generateFile(ruleName, 'example', _generateAllYaml,
      outDir: outDir, overwrite: true);

  printToConsole('Updating ${SdkVersionFile.filePath}');
  SdkVersionFile().addRule(ruleName);
  printToConsole('Updating ${Changelog.fileName}');
  Changelog().addEntry(RuleStateChange.added, ruleName);

  // Update rule registry.
  generateFile(ruleName, path.join('lib', 'src'), _generateRulesFile,
      outDir: outDir, overwrite: true);

  printToConsole('A unit test has been stubbed out in:');
  printToConsole('  $ruleTestDir/${ruleName}_test.dart');
}

void printUsage(ArgParser parser, [String? error]) {
  var message = error ?? 'Generates rule stubs.';

  stdout.write('''$message
Usage: rule
${parser.usage}
''');
}

String toClassName(String ruleName) =>
    ruleName.split('_').map(capitalize).join();

GeneratedFile _generateAllTestsFile(String libName, String className) {
  registerLintRules();
  var sb = StringBuffer();
  sb.write('''
// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

''');

  var paths = Directory(ruleTestDir).listSync().map((f) => f.path).toList()
    ..sort();

  var testNames = <String>[];
  for (var file in paths) {
    if (!file.endsWith('_test.dart')) continue;
    var filePath = path.relative(file, from: path.join('test', 'rules'));
    var testName = path.split(filePath).last.split('_test').first;
    testNames.add(testName);
    sb.writeln("import '$filePath' as $testName;");
  }

  sb.write(r'''

void main() {
''');
  for (var testName in testNames) {
    sb.writeln('  $testName.main();');
  }
  sb.writeln('}');
  return (file: 'all.dart', contents: sb.toString());
}

GeneratedFile _generateAllYaml(String libName, String className) {
  registerLintRules();
  var sb = StringBuffer();
  sb.write('''
# Auto-generated options enabling all lints.
# Add these to your `analysis_options.yaml` file and tailor to fit!
linter:
  rules:
''');

  var names = Registry.ruleRegistry.rules
      .where((r) =>
          !r.state.isDeprecated && !r.state.isInternal && !r.state.isRemoved)
      .map((r) => r.name)
      .toList();
  names.add(libName);
  names.sort();

  for (var rule in names) {
    sb.writeln('    - $rule');
  }
  return (file: 'all.yaml', contents: sb.toString());
}

GeneratedFile _generateClass(String ruleName, String className) => (
      file: '$ruleName.dart',
      contents: """
// Copyright (c) $_thisYear, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../analyzer.dart';

const _desc = r' ';

const _details = r'''
**DO** ...

**BAD:**
```dart

```

**GOOD:**
```dart

```

''';

class $className extends LintRule {
  static const LintCode code = LintCode(
      '$ruleName', '<add problem message here>',
      correctionMessage: '<add correction message here>');

  $className()
      : super(
            name: '$ruleName',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  LintCode get lintCode => code;

  @override
  void registerNodeProcessors(NodeLintRegistry registry, LinterContext context) {
    var visitor = _Visitor(this);
    registry.addSimpleIdentifier(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor {
  final LintRule rule;

  _Visitor(this.rule);

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    // TODO: implement
  }
}
"""
    );

GeneratedFile _generateRulesFile(String libName, String className) {
  registerLintRules();
  var sb = StringBuffer();
  sb.write('''
// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'analyzer.dart';
''');

  var names = Registry.ruleRegistry.rules.map((r) => r.name).toList();
  names.add(libName);
  names.sort();

  var imports = <String>[];
  for (var name in names) {
    var pathPrefix = Registry.ruleRegistry.getRule(name)?.group == Group.pub
        ? path.join('rules', 'pub')
        : 'rules';
    imports.add("import '$pathPrefix/$name.dart';");
  }

  //ignore: prefer_foreach
  for (var import in imports..sort()) {
    sb.writeln(import);
  }

  sb.write('''

void registerLintRules({bool inTestMode = false}) {
  Analyzer.facade.cacheLinterVersion();
  Analyzer.facade
''');

  for (var (i, name) in names.indexed) {
    var className = toClassName(name);
    var args = _supportsTestMode.contains(name) ? 'inTestMode: inTestMode' : '';
    var suffix = i == names.length - 1 ? ';' : '';
    sb.writeln('    ..register($className($args))$suffix');
  }
  sb.writeln('}');
  return (file: 'rules.dart', contents: sb.toString());
}

GeneratedFile _generateTest(String libName, String className) => (
      file: '${libName}_test.dart',
      contents: '''
// Copyright (c) $_thisYear, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

// TODO: add to all.dart

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(${className}Test);
  });
}

@reflectiveTest
class ${className}Test extends LintRuleTest {
  @override
  String get lintRule => '$libName';
  
  test_firstTest() async {
    await assertDiagnostics(r\'\'\'
  
\'\'\', [
   lint(0, 0),
    ]);
  }
}
'''
    );

typedef GeneratedFile = ({String file, String contents});

typedef Generator = GeneratedFile Function(String libName, String className);
