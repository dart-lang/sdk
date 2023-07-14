// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(ReferencesTest);
  });
}

@reflectiveTest
class ReferencesTest extends AbstractLspAnalysisServerTest {
  Future<void> test_acrossFiles_includeDeclaration() async {
    final otherContent = '''
import 'main.dart';

void f() {
  [!foo!]();
}
''';

    final mainContent = '''
/// Ensure the function is on a line that
/// does not exist in the mainContents file
/// to ensure we're translating offsets to line/col
/// using the correct file's LineInfo
/// ...
/// ...
/// ...
/// ...
/// ...
[!^foo!]() {}
''';

    await _checkRanges(
      mainContent,
      otherContent: otherContent,
      includeDeclarations: true,
    );
  }

  Future<void> test_acrossFiles_withoutDeclaration() async {
    final otherContent = '''
import 'main.dart';

void f() {
  [!foo!]();
}
''';

    final mainContent = '''
/// Ensure the function is on a line that
/// does not exist in the mainContents file
/// to ensure we're translating offsets to line/col
/// using the correct file's LineInfo
/// ...
/// ...
/// ...
/// ...
/// ...
^foo() {}
''';

    await _checkRanges(
      mainContent,
      otherContent: otherContent,
      includeDeclarations: false,
    );
  }

  Future<void> test_field() async {
    // References on the field should find both the initializing formal and the
    // reference to the getter.
    final content = '''
class AAA {
  final String? aa^a;
  const AAA({this./*[0*/aaa/*0]*/});
}

final a = AAA(aaa: '')./*[1*/aaa/*1]*/;
''';

    await _checkRanges(content);
  }

  Future<void> test_function_startOfParameterList() async {
    final content = '''
foo^() {
  [!foo!]();
}
''';

    await _checkRanges(content);
  }

  Future<void> test_function_startOfTypeParameterList() async {
    final content = '''
foo^<T>() {
  [!foo!]();
}
''';

    await _checkRanges(content);
  }

  Future<void> test_import_prefix() async {
    final content = '''
imp^ort 'dart:async' as async;

/*[0*/async./*0]*/Future<String>? f() {}
/*[1*/async./*1]*/Future<String>? g() {}
''';

    await _checkRanges(content);
  }

  Future<void> test_initializingFormals() async {
    // References on "this.aaa" should only find the matching named argument.
    final content = '''
class AAA {
  final String? aaa;
  const AAA({this.aa^a});
}

final a = AAA([!aaa!]: '').aaa;
''';

    await _checkRanges(content);
  }

  Future<void> test_method_startOfParameterList() async {
    final content = '''
class A {
  foo^() {
    [!foo!]();
  }
}
''';

    await _checkRanges(content);
  }

  Future<void> test_method_startOfTypeParameterList() async {
    final content = '''
class A {
  foo^<T>() {
    [!foo!]();
  }
}
''';

    await _checkRanges(content);
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    final res = await getReferences(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_singleFile_withoutDeclaration() async {
    final content = '''
f^oo() {
  [!foo!]();
}
''';

    await _checkRanges(content, includeDeclarations: false);
  }

  Future<void> test_unopenFile() async {
    final code = TestCode.parse('''
    f^oo() {
      [!foo!]();
    }
    ''');

    newFile(mainFilePath, code.code);
    await initialize();
    final res = await getReferences(mainFileUri, code.position.position);

    final expected = [
      for (final range in code.ranges)
        Location(uri: mainFileUri, range: range.range),
    ];

    expect(res, unorderedEquals(expected));
  }

  Future<void> _checkRanges(
    String mainContent, {
    String? otherContent,
    bool includeDeclarations = false,
  }) async {
    final mainCode = TestCode.parse(mainContent);
    final otherCode =
        otherContent != null ? TestCode.parse(otherContent) : null;
    final otherFileUri = toUri(join(projectFolderPath, 'lib', 'other.dart'));

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    if (otherCode != null) {
      await openFile(otherFileUri, otherCode.code);
    }
    final res = await getReferences(
      mainFileUri,
      mainCode.position.position,
      includeDeclarations: includeDeclarations,
    );

    final expected = [
      for (final range in mainCode.ranges)
        Location(uri: mainFileUri, range: range.range),
      if (otherCode != null)
        for (final range in otherCode.ranges)
          Location(uri: otherFileUri, range: range.range),
    ];

    expect(res, unorderedEquals(expected));
  }
}
