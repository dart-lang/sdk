// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/computer/computer_folding.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_context.dart';

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

  /// Expects no [FoldingRegion]s.
  ///
  /// If [onlyVerify] is provided, folding regions of other kinds are allowed.
  void expectNoRegions({Set<FoldingKind>? onlyVerify}) {
    expectRegions({}, onlyVerify: onlyVerify);
  }

  /// Expects to find a [FoldingRegion] for the code marked [index] with a
  /// [FoldingKind] of [kind].
  ///
  /// If [onlyVerify] is provided, only folding regions with matching kinds will
  /// be verified.
  void expectRegions(Map<int, FoldingKind> expected,
      {Set<FoldingKind>? onlyVerify}) {
    final expectedRegions = expected.entries.map((entry) {
      final range = code.ranges[entry.key].sourceRange;
      return FoldingRegion(entry.value, range.offset, range.length);
    }).toSet();

    final actualRegions = onlyVerify == null
        ? regions.toSet()
        : regions.where((region) => onlyVerify.contains(region.kind)).toSet();

    expect(actualRegions, expectedRegions);
  }

  @override
  void setUp() {
    super.setUp();
    sourcePath = convertPath('$testPackageLibPath/test.dart');
  }

  Future<void> test_annotations_class() async {
    var content = '''
@folded.classAnnotation1/*[0*/()
@foldedClassAnnotation2/*0]*/
class MyClass {}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.ANNOTATIONS,
    });
  }

  Future<void> test_annotations_class_constructor() async {
    var content = '''
class MyClass {
  @constructorAnnotation1/*[0*/
  @constructorAnnotation1/*0]*/
  MyClass() {}

  @constructorAnnotation1/*[1*/
  @constructorAnnotation1/*1]*/
  MyClass.named() {}
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.ANNOTATIONS,
      1: FoldingKind.ANNOTATIONS,
    }, onlyVerify: {
      FoldingKind.ANNOTATIONS
    });
  }

  Future<void> test_annotations_class_field() async {
    var content = '''
class MyClass {
  @fieldAnnotation1/*[0*/
  @fieldAnnotation2/*0]*/
  int myField;
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.ANNOTATIONS,
    }, onlyVerify: {
      FoldingKind.ANNOTATIONS
    });
  }

  Future<void> test_annotations_class_getterSetter() async {
    var content = '''
class MyClass {
  @getterAnnotation1/*[0*/
  @getterAnnotation2/*0]*/
  int get myThing => 1;

  @setterAnnotation1/*[1*/
  @setterAnnotation2/*1]*/
  void set myThing(int value) {}
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.ANNOTATIONS,
      1: FoldingKind.ANNOTATIONS,
    }, onlyVerify: {
      FoldingKind.ANNOTATIONS
    });
  }

  Future<void> test_annotations_class_method() async {
    var content = '''
class MyClass {
  @methodAnnotation1/*[0*/
  @methodAnnotation2/*0]*/
  void myMethod() {}
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.ANNOTATIONS,
    }, onlyVerify: {
      FoldingKind.ANNOTATIONS
    });
  }

  Future<void> test_annotations_multiline() async {
    var content = '''
@myMultilineAnnotation/*[0*/(
  "this",
  "is a test"
)/*0]*/
void f() {}
''';

    await _computeRegions(content);
    expectRegions(
      {
        0: FoldingKind.ANNOTATIONS,
      },
      onlyVerify: {
        FoldingKind.ANNOTATIONS,
      },
    );
  }

  Future<void> test_annotations_multiple() async {
    var content = '''
@multipleAnnotations1/*[0*/(
  /*[1*/"this",
  "is a test"
/*1]*/)
@multipleAnnotations2()
@multipleAnnotations3/*0]*/
main3() {}
''';

    await _computeRegions(content);
    expectRegions(
      {
        0: FoldingKind.ANNOTATIONS,
      },
      onlyVerify: {
        FoldingKind.ANNOTATIONS,
      },
    );
  }

  Future<void> test_annotations_singleLine() async {
    var content = '''
@noFoldNecessary
main2() {}

@noFoldsForSingleClassAnnotation
class MyClass {}
''';

    await _computeRegions(content);
    expectNoRegions();
  }

  Future<void> test_assertInitializer() async {
    var content = '''
class C/*[0*/ {
  C/*[1*/() : assert(
    /*[2*/true,
    ''
  /*2]*/);/*1]*/
}/*0]*/
''';
    await _computeRegions(content);
    expectRegions(
      {
        0: FoldingKind.CLASS_BODY,
        1: FoldingKind.FUNCTION_BODY,
        2: FoldingKind.INVOCATION,
      },
    );
  }

  Future<void> test_assertStatement() async {
    var content = '''
void f/*[0*/() {
  assert(/*[1*/
    true,
    ''
  /*1]*/);
}/*0]*/
''';
    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.INVOCATION,
    });
  }

  Future<void> test_class() async {
    var content = '''
// Content before

class Person/*[0*/ {
  Person/*[1*/() {
    print("Hello, world!");
  }/*1]*/

  void sayHello/*[2*/() {
    print("Hello, world!");
  }/*2]*/
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.CLASS_BODY,
      1: FoldingKind.FUNCTION_BODY,
      2: FoldingKind.FUNCTION_BODY,
    });
  }

  Future<void> test_comment_is_not_considered_file_header() async {
    var content = """
// This is not the file header/*[0*/
// It's just a comment/*0]*/
void f() {}
""";

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.COMMENT,
    });
  }

  Future<void> test_comment_multiline() async {
    var content = '''
/*/*[0*/
 * comment 1
 *//*0]*/

/* this comment starts on the same line as delimiters/*[1*/
 * second line
 *//*1]*/
void f() {}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.COMMENT,
      1: FoldingKind.COMMENT,
    });
  }

  Future<void> test_comment_singleFollowedByBlankLine() async {
    var content = '''
void f() {
// this is/*[0*/
// a comment/*0]*/
/// this is not part of it
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.COMMENT,
    }, onlyVerify: commentKinds);
  }

  Future<void> test_comment_singleFollowedByMulti() async {
    var content = '''
void f() {
  // this is/*[0*/
  // a comment/*0]*/
  /* this is not part of it */
  String foo;
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.COMMENT,
    }, onlyVerify: commentKinds);
  }

  Future<void> test_comment_singleFollowedByTripleSlash() async {
    var content = '''
void f() {
// this is/*[0*/
// a comment/*0]*/
/// this is not part of it
}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.COMMENT,
    }, onlyVerify: commentKinds);
  }

  Future<void> test_constructor_invocations() async {
    var content = '''
// Content before

final a = new Text(/*[0*/
  "Hello, world!",
/*0]*/);

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.INVOCATION,
    });
  }

  Future<void> test_file_header() async {
    var content = """
// Copyright some year by some people/*[0*/
// See LICENCE etc./*0]*/

// This is not the file header
// It's just a comment
void f() {}
""";

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FILE_HEADER,
    }, onlyVerify: {
      FoldingKind.FILE_HEADER
    });
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

    await _computeRegions(content);
    expectNoRegions(onlyVerify: {FoldingKind.FILE_HEADER});
  }

  Future<void> test_file_header_with_no_function_comment() async {
    var content = '''
// Copyright some year by some people/*[0*/
// See LICENCE etc./*0]*/

void f() {}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FILE_HEADER,
    });
  }

  Future<void> test_file_header_with_non_end_of_line_comment() async {
    var content = """
// Copyright some year by some people/*[0*/
// See LICENCE etc./*0]*/
/* This shouldn't be part of the file header */

void f() {}
""";

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FILE_HEADER,
    });
  }

  Future<void> test_file_header_with_script_prefix() async {
    var content = """
#! /usr/bin/dart
// Copyright some year by some people/*[0*/
// See LICENCE etc./*0]*/

// This is not the file header
// It's just a comment
void f() {}
""";

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FILE_HEADER,
    }, onlyVerify: {
      FoldingKind.FILE_HEADER
    });
  }

  Future<void> test_fileHeader_singleFollowedByBlank() async {
    var content = '''
// this is/*[0*/
// a file header/*0]*/

// this is not part of it
void f() {}
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FILE_HEADER,
    });
  }

  Future<void> test_function() async {
    var content = '''
// Content before

void f/*[0*/() {
  print("Hello, world!");
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
    });
  }

  Future<void> test_function_expression_invocation() async {
    var content = '''
// Content before

getFunc/*[0*/() => (String a, String b) {
  print(a);
};/*0]*/

main2/*[1*/() {
  getFunc()(/*[2*/
    "one",
    "two"
  /*2]*/);
}/*1]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.FUNCTION_BODY,
      2: FoldingKind.INVOCATION,
    });
  }

  Future<void> test_function_with_dart_doc() async {
    var content = '''
// Content before

/// This is a doc comment/*[0*/
/// that spans lines/*0]*/
void f/*[1*/() {
  print("Hello, world!");
}/*1]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.DOCUMENTATION_COMMENT,
      1: FoldingKind.FUNCTION_BODY,
    });
  }

  Future<void> test_invocations() async {
    var content = '''
// Content before

void f/*[0*/() {
  print(/*[1*/
    "Hello, world!",
  /*1]*/);
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.INVOCATION,
    });
  }

  Future<void> test_literal_list() async {
    var content = '''
// Content before

void f/*[0*/() {
  final List<String> things = <String>[/*[1*/
    "one",
    "two"
  /*1]*/];
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.LITERAL,
    });
  }

  Future<void> test_literal_map() async {
    var content = '''
// Content before

void f/*[0*/() {
  final Map<String, String> things = <String, String>{/*[1*/
    "one": "one",
    "two": "two"
    /*1]*/};
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.LITERAL,
    });
  }

  Future<void> test_literal_record() async {
    var content = '''
// Content before

void f/*[0*/() {
  final r = (/*[1*/
    "one",
    2,
    (/*[2*/
    'nested',
    3,
    'field record',
    /*2]*/),
  /*1]*/);
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.LITERAL,
      2: FoldingKind.LITERAL,
    });
  }

  Future<void> test_mixin() async {
    var content = '''
// Content before

mixin M/*[0*/ {
  void m/*[1*/() {
    print("Got to m");
  }/*1]*/
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.CLASS_BODY,
      1: FoldingKind.FUNCTION_BODY,
    });
  }

  Future<void> test_multiple_directive_types() async {
    var content = """
import/*[0*/ 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

export '../a.dart';/*0]*/

void f() {}
""";

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.DIRECTIVES,
    });
  }

  Future<void> test_multiple_import_directives() async {
    var content = """
import/*[0*/ 'dart:async';

// We can have comments
import 'package:a/b.dart';
import 'package:b/c.dart';

import '../a.dart';/*0]*/

void f() {}
""";

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.DIRECTIVES,
    });
  }

  Future<void> test_nested_function() async {
    var content = '''
// Content before

void f/*[0*/() {
  doPrint/*[1*/() {
    print("Hello, world!");
  }/*1]*/
  doPrint();
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.FUNCTION_BODY,
    });
  }

  Future<void> test_nested_invocations() async {
    var content = '''
// Content before

void f/*[0*/() {
  a(/*[1*/
    b(/*[2*/
      c(/*[3*/
        d()
      /*3]*/),
    /*2]*/),
  /*1]*/);
}/*0]*/

// Content after
''';

    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.INVOCATION,
      2: FoldingKind.INVOCATION,
      3: FoldingKind.INVOCATION,
    });
  }

  Future<void> test_parameters_function() async {
    var content = '''
foo/*[0*/(
  /*[1*/String aaaaa,
  String bbbbb, {
  String ccccc,
  }/*1]*/) {}/*0]*/
''';
    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.FUNCTION_BODY,
      1: FoldingKind.PARAMETERS,
    });
  }

  Future<void> test_parameters_method() async {
    var content = '''
class C/*[0*/ {
  C/*[1*/(
    /*[2*/String aaaaa,
    String bbbbb,
  /*2]*/) : super();/*1]*/
}/*0]*/
''';
    await _computeRegions(content);
    expectRegions({
      0: FoldingKind.CLASS_BODY,
      1: FoldingKind.FUNCTION_BODY,
      2: FoldingKind.PARAMETERS,
    });
  }

  Future<void> test_single_import_directives() async {
    var content = """
import 'dart:async';

void f() {}
""";

    await _computeRegions(content);
    expectNoRegions();
  }

  Future<void> _computeRegions(String sourceContent) async {
    code = TestCode.parse(sourceContent);
    final file = newFile(sourcePath, code.code);
    var result = await getResolvedUnit(file);
    var computer = DartUnitFoldingComputer(result.lineInfo, result.unit);
    regions = computer.compute();
  }
}
