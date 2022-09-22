// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_folding.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';
import '../../utils/test_code_format.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FoldingComputerTest);
  });
}

@reflectiveTest
class FoldingComputerTest extends AbstractContextTest {
  static const commentKinds = {
    FoldingKind.FILE_HEADER,
    FoldingKind.COMMENT,
    FoldingKind.DOCUMENTATION_COMMENT
  };

  late String sourcePath;
  late TestCode code;
  List<FoldingRegion> regions = [];

  /// Expects to find a [FoldingRegion] for the code marked [index] with a
  /// [FoldingKind] of [kind].
  void expectRegions(Map<int, FoldingKind> expected) {
    final expectedRegions = expected.entries.map((entry) {
      final range = code.ranges[entry.key].sourceRange;
      return FoldingRegion(entry.value, range.offset, range.length);
    }).toSet();

    expect(regions, expectedRegions);
  }

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_annotations() async {
    var content = '''
@myMultilineAnnotation/*[0*/(
  "this",
  "is a test"
)/*0]*/
void f() {}

@noFoldNecessary
main2() {}

@multipleAnnotations1/*[1*/(
  "this",
  "is a test"
)
@multipleAnnotations2()
@multipleAnnotations3/*1]*/
main3() {}

@noFoldsForSingleClassAnnotation
class MyClass {}

@folded.classAnnotation1/*[2*/()
@foldedClassAnnotation2/*2]*/
class MyClass2 {/*[3*/
  @fieldAnnotation1/*[4*/
  @fieldAnnotation2/*4]*/
  int myField;

  @getterAnnotation1/*[5*/
  @getterAnnotation2/*5]*/
  int get myThing => 1;

  @setterAnnotation1/*[6*/
  @setterAnnotation2/*6]*/
  void set myThing(int value) {}

  @methodAnnotation1/*[7*/
  @methodAnnotation2/*7]*/
  void myMethod() {}

  @constructorAnnotation1/*[8*/
  @constructorAnnotation1/*8]*/
  MyClass2() {}
/*3]*/}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.ANNOTATIONS,
      1: FoldingKind.ANNOTATIONS,
      2: FoldingKind.ANNOTATIONS,
      3: FoldingKind.CLASS_BODY,
      4: FoldingKind.ANNOTATIONS,
      5: FoldingKind.ANNOTATIONS,
      6: FoldingKind.ANNOTATIONS,
      7: FoldingKind.ANNOTATIONS,
      8: FoldingKind.ANNOTATIONS,
    });
  }

  Future<void> test_assertInitializer() async {
    var content = '''
class C {/*1:INC*/
  C() : assert(/*2:INC*/
    true,
    ''
  /*2:INC:INVOCATION*/);
/*1:INC:CLASS_BODY*/}
''';
    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_assertStatement() async {
    var content = '''
void f() {/*1:INC*/
  assert(/*2:INC*/
    true,
    ''
  /*2:INC:INVOCATION*/);
/*1:INC:FUNCTION_BODY*/}
''';
    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_class() async {
    var content = '''
// Content before

class Person {/*1:INC*/
  Person() {/*2:INC*/
    print("Hello, world!");
  /*2:INC:FUNCTION_BODY*/}

  void sayHello() {/*3:INC*/
    print("Hello, world!");
  /*3:INC:FUNCTION_BODY*/}
/*1:INC:CLASS_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_comment_is_not_considered_file_header() async {
    var content = """
// This is not the file header/*1:EXC*/
// It's just a comment/*1:INC:COMMENT*/
void f() {}
""";

    // Since there are no region comment markers above
    // just check the length instead of the contents
    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_comment_multiline() async {
    var content = '''
void f() {
/*/*1:EXC*/
 * comment 1
 *//*1:EXC:COMMENT*/

/* this comment starts on the same line as delimeters/*2:EXC*/
 * second line
 *//*2:EXC:COMMENT*/
}
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, commentKinds);
  }

  Future<void> test_comment_singleFollowedByBlankLine() async {
    var content = '''
void f() {
// this is/*1:EXC*/
// a comment/*1:INC:COMMENT*/
/// this is not part of it
}
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, commentKinds);
  }

  Future<void> test_comment_singleFollowedByMulti() async {
    var content = '''
void f() {
  // this is/*1:EXC*/
  // a comment/*1:INC:COMMENT*/
  /* this is not part of it */
  String foo;
}
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, commentKinds);
  }

  Future<void> test_comment_singleFollowedByTripleSlash() async {
    var content = '''
void f() {
// this is/*1:EXC*/
// a comment/*1:INC:COMMENT*/
/// this is not part of it
}
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, commentKinds);
  }

  Future<void> test_constructor_invocations() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  return new Text(/*2:INC*/
    "Hello, world!",
  /*2:INC:INVOCATION*/);
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_file_header() async {
    var content = """
// Copyright some year by some people/*1:EXC*/
// See LICENCE etc./*1:INC:FILE_HEADER*/

// This is not the file header
// It's just a comment
void f() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, {FoldingKind.FILE_HEADER});
  }

  Future<void> test_file_header_does_not_include_block_comments() async {
    var content = """
/*
 * Copyright some year by some people
 * See LICENCE etc.
 */
/* This shouldn't be part of the file header */

void f() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, {FoldingKind.FILE_HEADER});
  }

  Future<void> test_file_header_with_no_function_comment() async {
    var content = '''
// Copyright some year by some people/*1:EXC*/
// See LICENCE etc./*1:INC:FILE_HEADER*/

void f() {}
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, {FoldingKind.FILE_HEADER});
  }

  Future<void> test_file_header_with_non_end_of_line_comment() async {
    var content = """
// Copyright some year by some people/*1:EXC*/
// See LICENCE etc./*1:INC:FILE_HEADER*/
/* This shouldn't be part of the file header */

void f() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, {FoldingKind.FILE_HEADER});
  }

  Future<void> test_file_header_with_script_prefix() async {
    var content = """
#! /usr/bin/dart
// Copyright some year by some people/*1:EXC*/
// See LICENCE etc./*1:INC:FILE_HEADER*/

// This is not the file header
// It's just a comment
void f() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content, {FoldingKind.FILE_HEADER});
  }

  Future<void> test_fileHeader_singleFollowedByBlank() async {
    var content = '''
// this is/*1:EXC*/
// a file header/*1:INC:FILE_HEADER*/

// this is not part of it
void f() {}
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_function() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  print("Hello, world!");
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_function_expression_invocation() async {
    var content = '''
// Content before

getFunc() => (String a, String b) {/*1:INC*/
  print(a);
/*1:INC:FUNCTION_BODY*/};

main2() {/*2:INC*/
  getFunc()(/*3:INC*/
    "one",
    "two"
  /*3:INC:INVOCATION*/);
/*2:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_function_with_dart_doc() async {
    var content = '''
// Content before

/// This is a doc comment/*1:EXC*/
/// that spans lines/*1:INC:DOCUMENTATION_COMMENT*/
void f() {/*2:INC*/
  print("Hello, world!");
/*2:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_invocations() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  print(/*2:INC*/
    "Hello, world!",
  /*2:INC:INVOCATION*/);
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_literal_list() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  final List<String> things = <String>[/*2:INC*/
    "one",
    "two"
  /*2:INC:LITERAL*/];
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_literal_map() async {
    var content = '''
// Content before

main2() {/*1:INC*/
  final Map<String, String> things = <String, String>{/*2:INC*/
    "one": "one",
    "two": "two"
    /*2:INC:LITERAL*/};
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_literal_record() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  final r = (/*2:INC*/
    "one",
    2,
    (/*3:INC*/
    'nested',
    3,
    'field record',
    /*3:INC:LITERAL*/),
  /*2:INC:LITERAL*/);
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_mixin() async {
    var content = '''
// Content before

mixin M {/*1:INC*/
  void m() {/*3:INC*/
    print("Got to m");
  /*3:INC:FUNCTION_BODY*/}
/*1:INC:CLASS_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_multiple_directive_types() async {
    var content = """
import/*1:INC*/ 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

export '../a.dart';/*1:EXC:DIRECTIVES*/

void f() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_multiple_import_directives() async {
    var content = """
import/*1:INC*/ 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

import '../a.dart';/*1:EXC:DIRECTIVES*/

void f() {}
""";

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_nested_function() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  doPrint() {/*2:INC*/
    print("Hello, world!");
  /*2:INC:FUNCTION_BODY*/}
  doPrint();
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_nested_invocations() async {
    var content = '''
// Content before

void f() {/*1:INC*/
  a(/*2:INC*/
    b(/*3:INC*/
      c(/*4:INC*/
        d()
      /*4:INC:INVOCATION*/),
    /*3:INC:INVOCATION*/),
  /*2:INC:INVOCATION*/);
/*1:INC:FUNCTION_BODY*/}

// Content after
''';

    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_parameters_function() async {
    var content = '''
foo(/*1:INC*/
  String aaaaa,
  String bbbbb, {
  String ccccc,
  }/*1:INC:PARAMETERS*/) {}
''';
    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_parameters_method() async {
    var content = '''
class C {/*1:INC*/
  C(/*2:INC*/
    String aaaaa,
    String bbbbb,
  /*2:INC:PARAMETERS*/) : super();
/*1:INC:CLASS_BODY*/}
''';
    final regions = await _computeRegions(content);
    _compareRegions(regions, content);
  }

  Future<void> test_single_import_directives() async {
    var content = """
import 'dart:async';

void f() {}
""";

    // Since there are no region comment markers above
    // just check the length instead of the contents
    final regions = await _computeRegions(content);
    expect(regions, hasLength(0));
  }

  /// Compares provided folding regions with expected
  /// regions extracted from the comments in the provided content.
  ///
  /// If [onlyKinds] is supplied only regions of that type will be compared.
  void _compareRegions(List<FoldingRegion> regions, String content,
      [Set<FoldingKind>? onlyKinds]) {
    // Find all numeric markers for region starts.
    final regex = RegExp(r'/\*(\d+):(INC|EXC)\*/');
    final expectedRegions = regex.allMatches(content);

    if (onlyKinds != null) {
      regions =
          regions.where((region) => onlyKinds.contains(region.kind)).toList();
    }

    // Check we didn't get more than expected, since the loop below only
    // checks for the presence of matches, not absence.
    expect(regions, hasLength(expectedRegions.length));

    // Go through each marker, find the expected region start/end and
    // ensure it's in the results.
    for (var m in expectedRegions) {
      final i = m.group(1);
      final inclusiveStart = m.group(2) == 'INC';
      // Find the end marker.
      final endMatch =
          RegExp('/\\*$i:(INC|EXC):(.+?)\\*/').firstMatch(content)!;

      final inclusiveEnd = endMatch.group(1) == 'INC';
      final expectedKindString = endMatch.group(2);
      final expectedKind = FoldingKind.VALUES.firstWhere(
          (f) => f.toString() == 'FoldingKind.$expectedKindString',
          orElse: () => throw Exception(
              'Annotated test code references $expectedKindString but '
              'this does not exist in FoldingKind'));

      final expectedStart = inclusiveStart ? m.start : m.end;
      final expectedLength =
          (inclusiveEnd ? endMatch.end : endMatch.start) - expectedStart;

      expect(regions,
          contains(FoldingRegion(expectedKind, expectedStart, expectedLength)));
    }
  }

  Future<List<FoldingRegion>> _computeRegions(String sourceContent) async {
    code = TestCode.parse(sourceContent);
    newFile(sourcePath, code.code);
    var result =
        await (await session).getResolvedUnit(sourcePath) as ResolvedUnitResult;
    var computer = DartUnitFoldingComputer(result.lineInfo, result.unit);
    regions = computer.compute();
    return regions;
  }
}
