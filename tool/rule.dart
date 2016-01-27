// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:args/args.dart';

/// Generates rule and rule test stub files (int src/rules and test/rules
/// respectively), as well as the rule index (rules.dart).
void main([args]) {
  var parser = new ArgParser(allowTrailingOptions: true);

  parser.addOption('out', abbr: 'o', help: 'Specifies project root.');
  parser.addOption('library',
      abbr: 'l', help: 'Specifies lower_underscore rule library name.');

  var options;
  try {
    options = parser.parse(args);
  } on FormatException catch (err) {
    printUsage(parser, err.message);
    return;
  }

  var outDir = options['out'];

  if (outDir != null) {
    Directory d = new Directory(outDir);
    if (!d.existsSync()) {
      print("Directory '${d.path}' does not exist");
      return;
    }
  }

  var libName = options['library'];

  if (libName == null) {
    printUsage(parser);
    return;
  }

  // Generate rule stub.
  generateStub(libName, outDir: outDir);

  // Generate test stub.
  generateTest(libName, outDir: outDir);

  // Update rule registry.
  updateRuleRegistry(libName);
}

String capitalize(String s) => s.substring(0, 1).toUpperCase() + s.substring(1);

void generateStub(String libName, {String outDir}) {
  var generated = _generateStub(libName, toClassName(libName));
  if (outDir != null) {
    var outPath = '$outDir/lib/src/rules/$libName.dart';
    print('Writing to $outPath');
    new File(outPath).writeAsStringSync(generated);
  } else {
    print(generated);
  }
}

void generateTest(String libName, {String outDir}) {
  var generated = _generateTest(libName, toClassName(libName));
  if (outDir != null) {
    var outPath = '$outDir/test/rules/$libName.dart';
    print('Writing to $outPath');
    new File(outPath).writeAsStringSync(generated);
  } else {
    print(generated);
  }
}

void printUsage(ArgParser parser, [String error]) {
  var message = error ?? 'Generates rule stubs.';

  stdout.write('''$message
Usage: rule
${parser.usage}
''');
}

String toClassName(String libName) =>
    libName.split('_').map((bit) => capitalize(bit)).join();

void updateRuleRegistry(String libName) {
  //TODO: find right place to insert into imports and ruleMap
  print("Don't forget to update lib/rules.dart with a line like:");
  print("  ..register(new ${toClassName(libName)}())");
  print("Then run your test like so:");
  print("  dart test/util/solo_test.dart $libName");
}

String _generateStub(String libName, String className) => """
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library linter.src.rules.$libName;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:linter/src/linter.dart';

const desc = r' ';

const details = r'''

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
          name: '$libName',
            description: desc,
            details: details,
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
// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `dart test/util/solo_test.dart $libName`

''';
