// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

/// Generates rule and rule test stub files (into `src/rules` and `test/rules`
/// respectively), as well as the rule index (`rules.dart`).
void main([List<String> args]) {
  final parser = new ArgParser(allowTrailingOptions: true)
    ..addOption('out', abbr: 'o', help: 'Specifies project root.')
    ..addOption('name',
        abbr: 'n', help: 'Specifies lower_underscore rule name.');

  var options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  final outDir = options['out'];

  if (outDir != null) {
    final d = new Directory(outDir);
    if (!d.existsSync()) {
      print("Directory '${d.path}' does not exist");
      return;
    }
  }

  final ruleName = options['name'];

  if (ruleName == null) {
    printUsage(parser);
    return;
  }

  // Generate rule stub.
  generateRule(ruleName, outDir: outDir);
}

String capitalize(String s) => s.substring(0, 1).toUpperCase() + s.substring(1);

void generateRule(String ruleName, {String outDir}) {
  // Generate rule stub.
  generateStub(ruleName, 'lib/src/rules', _generateClass, outDir: outDir);

  // Generate test stub.
  generateStub(ruleName, 'test/rules', _generateTest, outDir: outDir);

  // Update rule registry.
  updateRuleRegistry(ruleName);
}

void generateStub(String ruleName, String stubPath, _Generator generator,
    {String outDir}) {
  final generated = generator(ruleName, toClassName(ruleName));
  if (outDir != null) {
    final outPath = '$outDir/$stubPath/$ruleName.dart';
    final outFile = new File(outPath);
    if (outFile.existsSync()) {
      print('Warning: stub already exists at $outPath; skipping');
      return;
    }
    print('Writing to $outPath');
    outFile.writeAsStringSync(generated);
  } else {
    print(generated);
  }
}

void printUsage(ArgParser parser, [String error]) {
  final message = error ?? 'Generates rule stubs.';

  stdout.write('''$message
Usage: rule
${parser.usage}
''');
}

String toClassName(String ruleName) =>
    ruleName.split('_').map(capitalize).join();

void updateRuleRegistry(String ruleName) {
  print("Don't forget to update lib/rules.dart with a line like:");
  print('  ..register(new ${toClassName(ruleName)}())');
  print('and add your rule to `example/all.yaml`.');
  print('Then run your test like so:');
  print('  pub run test -N $ruleName');
}

String _generateClass(String ruleName, String className) => """
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:linter/src/analyzer.dart';
import 'package:linter/src/util/dart_type_utilities.dart';

const _desc = r' ';

const _details = r'''

**DO** ...

**BAD:**
```

```

**GOOD:**
```

```

''';

class $className extends LintRule {
  $className() : super(
          name: '$ruleName',
            description: _desc,
            details: _details,
            group: Group.style);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  final LintRule rule;
  Visitor(this.rule);


}
""";

String _generateTest(String libName, String className) => '''
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N $libName`

''';

typedef String _Generator(String libName, String className);
