// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that the compiler emits a warning on import of 'dart:mirrors' unless
// the flag --enable-experimental-mirrors is used.

library dart2js.test.import;

import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/dart2jslib.dart' show MessageKind;
import 'memory_compiler.dart';

const DIRECT_IMPORT = const {
  '/main.dart': '''
import 'dart:mirrors';

main() {}
''',

  'paths':
      "main.dart => dart:mirrors",
};

const INDIRECT_IMPORT1 = const {
  '/main.dart': '''
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "first.dart => dart:mirrors",
  'verbosePaths':
      "main.dart => first.dart => dart:mirrors",
};

const INDIRECT_IMPORT2 = const {
  '/main.dart': '''
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'second.dart';
''',
  '/second.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "second.dart => dart:mirrors",
  'verbosePaths':
      "main.dart => first.dart => second.dart => dart:mirrors",
};

const INDIRECT_PACKAGE_IMPORT1 = const {
  '/main.dart': '''
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'package:second.dart';
''',
  '/pkg/second.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "first.dart => package:second.dart => dart:mirrors",
  'verbosePaths':
      "main.dart => first.dart => package:second.dart => dart:mirrors",
};

const INDIRECT_PACKAGE_IMPORT2 = const {
  '/main.dart': '''
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'package:package-name/second.dart';
''',
  '/pkg/package-name/second.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "first.dart => package:package-name => dart:mirrors",
  'verbosePaths':
      "main.dart => first.dart => package:package-name/second.dart "
      "=> dart:mirrors",
};

const INDIRECT_PACKAGE_IMPORT3 = const {
  '/main.dart': '''
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'package:package1/second.dart';
''',
  '/pkg/package1/second.dart': '''
import 'package:package2/third.dart';
''',
  '/pkg/package2/third.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "first.dart => package:package1 => package:package2 => dart:mirrors",
  'verbosePaths':
      "main.dart => first.dart => package:package1/second.dart "
      "=> package:package2/third.dart => dart:mirrors",
};

const INDIRECT_PACKAGE_IMPORT4 = const {
  '/main.dart': '''
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'package:package1/second.dart';
''',
  '/pkg/package1/second.dart': '''
import 'sub/third.dart';
''',
  '/pkg/package1/sub/third.dart': '''
import 'package:package2/fourth.dart';
''',
  '/pkg/package2/fourth.dart': '''
import 'lib/src/fifth.dart';
''',
  '/pkg/package2/lib/src/fifth.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "first.dart => package:package1 => package:package2 => dart:mirrors",
  'verbosePaths':
      "main.dart => first.dart => package:package1/second.dart "
      "=> package:package1/sub/third.dart => package:package2/fourth.dart "
      "=> package:package2/lib/src/fifth.dart => dart:mirrors",
};

const DUAL_DIRECT_IMPORT = const {
  '/main.dart': '''
import 'dart:mirrors';
import 'dart:mirrors';

main() {}
''',

  'paths':
      "main.dart => dart:mirrors",
};

const DUAL_INDIRECT_IMPORT1 = const {
  '/main.dart': '''
import 'dart:mirrors';
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'dart:mirrors';
''',

  'paths': const
      ["main.dart => dart:mirrors",
       "first.dart => dart:mirrors"],
  'verbosePaths': const
      ["main.dart => dart:mirrors",
       "main.dart => first.dart => dart:mirrors"],
};

const DUAL_INDIRECT_IMPORT2 = const {
  '/main.dart': '''
import 'first.dart';
import 'second.dart';

main() {}
''',
  '/first.dart': '''
import 'dart:mirrors';
''',
  '/second.dart': '''
import 'dart:mirrors';
''',

  'paths': const
      ["first.dart => dart:mirrors",
       "second.dart => dart:mirrors"],
  'verbosePaths': const
      ["main.dart => first.dart => dart:mirrors",
       "main.dart => second.dart => dart:mirrors"],
};

const DUAL_INDIRECT_IMPORT3 = const {
  '/main.dart': '''
import 'first.dart';
import 'second.dart';

main() {}
''',
  '/first.dart': '''
import 'third.dart';
''',
  '/second.dart': '''
import 'third.dart';
''',
  '/third.dart': '''
import 'dart:mirrors';
''',

  'paths':
      "third.dart => dart:mirrors",
  'verbosePaths': const
      ["main.dart => first.dart => third.dart => dart:mirrors",
       "main.dart => second.dart => third.dart => dart:mirrors"],
};

const DUAL_INDIRECT_PACKAGE_IMPORT1 = const {
  '/main.dart': '''
import 'package:package1/second.dart';
import 'first.dart';

main() {}
''',
  '/first.dart': '''
import 'package:package2/third.dart';
''',
  '/pkg/package1/second.dart': '''
import 'dart:mirrors';
''',
  '/pkg/package2/third.dart': '''
import 'dart:mirrors';
''',

  'paths': const
      ["main.dart => package:package1 => dart:mirrors",
       "first.dart => package:package2 => dart:mirrors"],
  'verbosePaths': const
      ["main.dart => package:package1/second.dart => dart:mirrors",
       "main.dart => first.dart => package:package2/third.dart => dart:mirrors"]
};


test(Map sourceFiles,
    {expectedPaths,
     bool verbose: false,
     bool enableExperimentalMirrors: false}) {
  if (expectedPaths is! List) {
    expectedPaths = [expectedPaths];
  }
  var collector = new DiagnosticCollector();
  var options = [];
  if (verbose) {
    options.add('--verbose');
  }
  if (enableExperimentalMirrors) {
    options.add('--enable-experimental-mirrors');
  }
  var compiler = compilerFor(sourceFiles, diagnosticHandler: collector,
                             packageRoot: Uri.parse('memory:/pkg/'),
                             options: options);
  asyncTest(() => compiler.run(Uri.parse('memory:/main.dart')).then((_) {
    Expect.equals(0, collector.errors.length, 'Errors: ${collector.errors}');
    if (enableExperimentalMirrors) {
      Expect.equals(0, collector.warnings.length,
                    'Warnings: ${collector.errors}');
    } else {
      Expect.equals(1, collector.warnings.length,
                    'Warnings: ${collector.errors}');
      Expect.equals(
          MessageKind.IMPORT_EXPERIMENTAL_MIRRORS.message(
              {'importChain': expectedPaths.join(
                  MessageKind.IMPORT_EXPERIMENTAL_MIRRORS_PADDING)}).toString(),
          collector.warnings.first.message);
    }
  }));
}

checkPaths(Map sourceData) {
  Map sourceFiles = sourceData;
  var expectedPaths = sourceData['paths'];
  var expectedVerbosePaths = sourceData['verbosePaths'];
  if (expectedVerbosePaths == null) {
    expectedVerbosePaths = expectedPaths;
  }
  test(sourceFiles, expectedPaths: expectedPaths);
  test(sourceFiles, expectedPaths: expectedVerbosePaths, verbose: true);
  test(sourceFiles, enableExperimentalMirrors: true);
}

void main() {
  checkPaths(DIRECT_IMPORT);
  checkPaths(INDIRECT_IMPORT1);
  checkPaths(INDIRECT_IMPORT2);
  checkPaths(INDIRECT_PACKAGE_IMPORT1);
  checkPaths(INDIRECT_PACKAGE_IMPORT2);
  checkPaths(INDIRECT_PACKAGE_IMPORT3);
  checkPaths(INDIRECT_PACKAGE_IMPORT4);
  checkPaths(DUAL_DIRECT_IMPORT);
  checkPaths(DUAL_INDIRECT_IMPORT1);
  checkPaths(DUAL_INDIRECT_IMPORT2);
  checkPaths(DUAL_INDIRECT_IMPORT3);
  checkPaths(DUAL_INDIRECT_PACKAGE_IMPORT1);
}
