// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportTest);
  });
}

@reflectiveTest
class ImportTest extends AbstractLspAnalysisServerTest {
  /// A helper for creating files for multi-level-parts tests.
  ({Uri uri, String filePath, TestCode code}) createFile(
    String filename,
    String content,
  ) {
    assert(filename.endsWith('.dart'));
    var filePath = join(projectFolderPath, 'lib', filename);
    var code = TestCode.parse(content);
    newFile(filePath, code.code);
    return (uri: toUri(filePath), filePath: filePath, code: code);
  }

  Future<void> test_constant() async {
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'dart:math';!]

void foo() {
  print(p^i);
}
'''),
    );
  }

  Future<void> test_constant_alias() async {
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'dart:math' as math;!]

void foo() {
  print(math.p^i);
}
'''),
    );
  }

  Future<void> test_function() async {
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'dart:math';!]

void foo() {
  ma^x(1, 2);
}
'''),
    );
  }

  Future<void> test_function_alias() async {
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'dart:math' as math;!]

void foo() {
  math.ma^x(1, 2);
}
'''),
    );
  }

  Future<void> test_import_double() async {
    newFile('/home/my_project/lib/other.dart', '''
export 'dart:math';
''');
    await _verifyGoToImports(
      TestCode.parse('''
/*[0*/import 'dart:math';/*0]*/
/*[1*/import 'other.dart';/*1]*/

Rando^m? r;
'''),
    );
  }

  Future<void> test_import_double_ambiguous() async {
    newFile('/home/my_project/lib/a1.dart', '''
class A {}
''');
    newFile('/home/my_project/lib/a2.dart', '''
class A {}
''');
    await _verifyGoToImports(
      TestCode.parse('''
/*[0*/import 'a1.dart';/*0]*/
/*[1*/import 'a2.dart';/*1]*/

// ignore: ambiguous_import
^A? r;
'''),
    );
  }

  Future<void> test_import_double_hide() async {
    newFile('/home/my_project/lib/a1.dart', '''
class A {}
''');
    newFile('/home/my_project/lib/a2.dart', '''
class A {}
''');
    await _verifyGoToImports(
      TestCode.parse('''
import 'a1.dart' hide A;
[!import 'a2.dart';!]

^A? r;
'''),
    );
  }

  Future<void> test_import_double_same_different_alias() async {
    newFile('/home/my_project/lib/other.dart', '''
export 'dart:math';
''');
    await _verifyGoToImports(
      TestCode.parse('''
import 'dart:math' as math;
[!import 'other.dart' as other;!]

other.Rando^m? r;
'''),
    );
  }

  Future<void> test_import_double_same_different_alias_prefix() async {
    newFile('/home/my_project/lib/other.dart', '''
export 'dart:math';
''');
    await _verifyGoToImports(
      TestCode.parse('''
import 'dart:math' as math;
[!import 'other.dart' as other;!]

other.Ran^dom? r;
'''),
    );
  }

  Future<void> test_import_double_show() async {
    newFile('/home/my_project/lib/a1.dart', '''
class A {}

class B {}
''');
    newFile('/home/my_project/lib/a2.dart', '''
class A {}
''');
    await _verifyGoToImports(
      TestCode.parse('''
import 'a1.dart' show B;
[!import 'a2.dart' show A;!]

^A? r;
'''),
    );
  }

  Future<void> test_import_double_unambiguous_aliased() async {
    newFile('/home/my_project/lib/a1.dart', '''
class A {}
''');
    newFile('/home/my_project/lib/a2.dart', '''
class A {}
''');
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'a1.dart' as a;!]
import 'a2.dart' as b;

// ignore: ambiguous_import
a.A^? r;
'''),
    );
  }

  Future<void> test_import_multiLevelParts() async {
    // Create a tree of files that all import 'dart:math' and ensure we find
    // only the import from the parent (not a grandparent, sibling, or child).
    //
    //
    // - root                      has import
    //     - level1_other          has import
    //     - level1                has import, is the used reference
    //         - level2_other      has import
    //         - level2            has reference
    //             - level3_other  has import

    createFile('root.dart', '''
import 'dart:math';
part 'level1_other.dart';
part 'level1.dart';
''');

    createFile('level1_other.dart', '''
part of 'root.dart';
import 'dart:math';
''');

    var level1 = createFile('level1.dart', '''
part of 'root.dart';
[!import 'dart:math';!]
part 'level2_other.dart';
part 'level2.dart';
''');

    createFile('level2_other.dart', '''
part of 'level1.dart';
import 'dart:math';
''');

    var level2 = createFile('level2.dart', '''
part of 'level1.dart';
part 'level3_other.dart';

Rando^m? r;
''');

    createFile('level3_other.dart', '''
part of 'level2.dart';
import 'dart:math';
''');

    await _verifyGoToImports(
      // Test the position in level2.
      level2.code,
      fileUri: level2.uri,
      // Expect only the nearest parent import (level1).
      expecting: (level1.uri, level1.code.ranges),
    );
  }

  Future<void> test_import_multiLevelParts_findsInGrandParent() async {
    var root = createFile('root.dart', '''
[!import 'dart:math';!]
part 'level1.dart';
''');

    createFile('level1.dart', '''
part of 'root.dart';
part 'level2.dart';
''');

    var level2 = createFile('level2.dart', '''
part of 'level1.dart';
Rando^m? r;''');

    await _verifyGoToImports(
      // Test the position in level2, expect reference in root.
      level2.code,
      fileUri: level2.uri,
      expecting: (root.uri, root.code.ranges),
    );
  }

  Future<void> test_import_multiLevelParts_findsInParent() async {
    createFile('root.dart', '''
part 'level1.dart';
''');

    var level1 = createFile('level1.dart', '''
part of 'root.dart';
[!import 'dart:math';!]
part 'level2.dart';
''');

    var level2 = createFile('level2.dart', '''
part of 'level1.dart';
Rando^m? r;''');

    await _verifyGoToImports(
      // Test the position in level2, expect reference in level1.
      level2.code,
      fileUri: level2.uri,
      expecting: (level1.uri, level1.code.ranges),
    );
  }

  Future<void> test_import_multiLevelParts_findsInSelf() async {
    createFile('root.dart', '''
part 'level1.dart';
''');

    createFile('level1.dart', '''
part of 'root.dart';
part 'level2.dart';
''');

    var level2 = createFile('level2.dart', '''
part of 'level1.dart';
[!import 'dart:math';!]
Rando^m? r;''');

    await _verifyGoToImports(
      // Test the position in level2, expect reference in same.
      level2.code,
      fileUri: level2.uri,
      expecting: (level2.uri, level2.code.ranges),
    );
  }

  Future<void> test_import_part() async {
    var otherFileUri = Uri.file(join(projectFolderPath, 'lib', 'other.dart'));
    var main = TestCode.parse('''
[!import 'dart:math';!]

part '$otherFileUri';
''');
    newFile(mainFilePath, main.code);
    await _verifyGoToImports(
      TestCode.parse('''
part of '$mainFileUri';

Rando^m? r;
'''),
      fileUri: otherFileUri,
      expecting: (mainFileUri, main.ranges),
    );
  }

  Future<void> test_import_single() async {
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'dart:math';!]

Rando^m? r;
'''),
    );
  }

  Future<void> test_import_single_aliased() async {
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'dart:math' as math;!]

math.Rando^m? r;
'''),
    );
  }

  Future<void> test_import_single_exported() async {
    newFile('/home/my_project/lib/other.dart', '''
export 'dart:math';
''');
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'other.dart';!]

Rando^m? r;
'''),
    );
  }

  Future<void> test_local_no_result() async {
    await _verifyGoToImports(
      TestCode.parse('''
import 'dart:math';

Random? r;
L^ocalClass? l;

class LocalClass {}
'''),
    );
  }

  Future<void> test_nestedInvocations() async {
    newFile('/home/my_project/lib/other.dart', '''
class A {
  const A();
  A foo() => A();
  void bar() {}
}
''');
    await _verifyGoToImports(
      TestCode.parse('''
import 'other.dart';

var a = A().foo().ba^r();
'''),
    );
  }

  Future<void> test_nestedInvocations_extension() async {
    newFile('/home/my_project/lib/other.dart', '''
extension E on int {
  void bar() {}
}
''');
    await _verifyGoToImports(
      TestCode.parse('''
[!import 'other.dart';!]

var a = 1.abs().ba^r();
'''),
    );
  }

  Future<void> _verifyGoToImports(
    TestCode code, {
    Uri? fileUri,
    (Uri, List<TestCodeRange>)? expecting,
  }) async {
    expecting ??= (fileUri ?? mainFileUri, code.ranges);
    var (expectedUri, expectedRanges) = expecting;
    var expectedLocations = [
      for (var range in expectedRanges)
        Location(uri: expectedUri, range: range.range),
    ];

    newFile(fromUri(fileUri ?? mainFileUri), code.code);
    await initialize();
    await initialAnalysis;
    var res = await getImports(fileUri ?? mainFileUri, code.position.position);

    expect(res ?? [], expectedLocations);
  }
}
