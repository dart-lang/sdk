// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library rule_gen;

import 'dart:io';

import 'package:args/args.dart';

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

/// Generates rule and rule test stub files
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

  // Generate rule stub
  generateStub(libName, outDir: outDir);

  // Generate test stub
  generateTest(libName, outDir: outDir);
}

void printUsage(ArgParser parser, [String error]) {
  var message = 'Generates rule stubs.';
  if (error != null) {
    message = error;
  }

  stdout.write('''$message
Usage: rule
${parser.usage}
''');
}

String toClassName(String libName) =>
    libName.split('_').map((bit) => capitalize(bit)).join();

String _generateStub(String libName, String className) => '''
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library $libName;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/scanner.dart';
import 'package:linter/src/linter.dart';

const desc = r' ';

const details = r' ';

class $className extends LintRule {
  $className() : super(
          name: '$className',
          description: desc,
          details: details,
          group: Group.STYLE_GUIDE,
          kind: Kind.AVOID);

  @override
  AstVisitor getVisitor() => new Visitor(this);
}

class Visitor extends SimpleAstVisitor {
  LintRule rule;
  Visitor(this.rule);


}
''';

String _generateTest(String libName, String className) => '''
// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

''';
