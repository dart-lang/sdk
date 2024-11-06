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
    var otherContent = '''
import 'main.dart';

void f() {
  [!foo!]();
}
''';

    var mainContent = '''
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
    var otherContent = '''
import 'main.dart';

void f() {
  [!foo!]();
}
''';

    var mainContent = '''
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

    await _checkRanges(mainContent, otherContent: otherContent);
  }

  Future<void> test_field_decalaration_getterSetter() async {
    var content = '''
class MyClass {
  String field^ = '';
}

void f() {
  MyClass()./*[0*/field/*0]*/ = '';
  print(MyClass()./*[1*/field/*1]*/);
  
  var myInstance = MyClass();
  myInstance./*[2*/field/*2]*/ = '';
  print(myInstance./*[3*/field/*3]*/);
  myInstance./*[4*/field/*4]*/ += myInstance./*[5*/field/*5]*/;
}
''';

    await _checkRanges(content);
  }

  Future<void> test_field_decalaration_initializingFormal() async {
    // References on the field should find the initializing formal, the
    // reference to the getter and the constructor argument.
    var content = '''
class AAA {
  final String? aa^a;
  const AAA({this./*[0*/aaa/*0]*/});
}

class BBB extends AAA {
  BBB({super./*[1*/aaa/*1]*/});
}

final a = AAA(/*[2*/aaa/*2]*/: '')./*[3*/aaa/*3]*/;
''';

    await _checkRanges(content);
  }

  Future<void> test_forEachElement_blockBody() async {
    var content = '''
void f(List<int> values) {
  [for (final val^ue in values) [!value!] * 2];
}
''';

    await _checkRanges(content);
  }

  Future<void> test_forEachElement_expressionBody() async {
    var content = '''
Object f() => [for (final val^ue in []) [!value!] * 2];
''';

    await _checkRanges(content);
  }

  Future<void> test_forEachElement_topLevel() async {
    var content = '''
final a = [for (final val^ue in []) [!value!] * 2];
''';

    await _checkRanges(content);
  }

  Future<void> test_function_startOfParameterList() async {
    var content = '''
foo^() {
  [!foo!]();
}
''';

    await _checkRanges(content);
  }

  Future<void> test_function_startOfTypeParameterList() async {
    var content = '''
foo^<T>() {
  [!foo!]();
}
''';

    await _checkRanges(content);
  }

  Future<void> test_getter_decalaration_getterSetter() async {
    var content = '''
class MyClass {
  String get field^ => '';
  set field(String _) {}
}

void f() {
  MyClass()./*[0*/field/*0]*/ = '';
  print(MyClass()./*[1*/field/*1]*/);
  
  var myInstance = MyClass();
  myInstance./*[2*/field/*2]*/ = '';
  print(myInstance./*[3*/field/*3]*/);
  myInstance./*[4*/field/*4]*/ += myInstance./*[5*/field/*5]*/;
}
''';

    await _checkRanges(content);
  }

  Future<void> test_getter_invocation_getterSetter() async {
    var content = '''
class MyClass {
  String get field => '';
  set field(String _) {}
}

void f() {
  MyClass()./*[0*/field/*0]*/ = '';
  print(MyClass()./*[1*/fi^eld/*1]*/);
  
  var myInstance = MyClass();
  myInstance./*[2*/field/*2]*/ = '';
  print(myInstance./*[3*/field/*3]*/);
  myInstance./*[4*/field/*4]*/ += myInstance./*[5*/field/*5]*/;
}
''';

    await _checkRanges(content);
  }

  Future<void> test_import_prefix() async {
    var content = '''
imp^ort 'dart:async' as async;

/*[0*/async./*0]*/Future<String>? f() {}
/*[1*/async./*1]*/Future<String>? g() {}
''';

    await _checkRanges(content);
  }

  Future<void> test_initializingFormal_argument_withDeclaration() async {
    // Find references on an initializing formal argument should include
    // all references to the field too.
    var content = '''
class AAA {
  String? /*[0*/aaa/*0]*/;
  AAA({this./*[1*/aaa/*1]*/});
}

void f() {
  final a = AAA(/*[2*/a^aa/*2]*/: '');
  var x = a./*[3*/aaa/*3]*/;
  a./*[4*/aaa/*4]*/ = '';
}
''';

    await _checkRanges(content, includeDeclarations: true);
  }

  Future<void> test_initializingFormal_argument_withoutDeclaration() async {
    // Find references on an initializing formal argument should include
    // all references to the field too. The field is not included
    // because we didn't request the declaration.
    var content = '''
class AAA {
  String? aaa;
  AAA({this./*[0*/aaa/*0]*/});
}

void f() {
  final a = AAA(/*[1*/a^aa/*1]*/: '');
  var x = a./*[2*/aaa/*2]*/;
  a./*[3*/aaa/*3]*/ = '';
}
''';

    await _checkRanges(content);
  }

  Future<void> test_initializingFormal_parameter_withDeclaration() async {
    // Find references on an initializing formal parameter should include
    // all references to the field too.
    var content = '''
class AAA {
  String? /*[0*/aaa/*0]*/;
  AAA({this./*[1*/aa^a/*1]*/});
}

void f() {
  final a = AAA(/*[2*/aaa/*2]*/: '');
  var x = a./*[3*/aaa/*3]*/;
  a./*[4*/aaa/*4]*/ = '';
}
''';

    await _checkRanges(content, includeDeclarations: true);
  }

  Future<void> test_initializingFormal_parameter_withoutDeclaration() async {
    // Find references on an initializing formal parameter should include
    // all references to the field too. The field is not included
    // because we didn't request the declaration.
    var content = '''
class AAA {
  String? aaa;
  AAA({this./*[0*/aa^a/*0]*/});
}

class BBB extends AAA {
  BBB({super./*[1*/aaa/*1]*/});
}

void f() {
  final a = AAA(/*[2*/aaa/*2]*/: '');
  var x = a./*[3*/aaa/*3]*/;
  a./*[4*/aaa/*4]*/ = '';
}
''';

    await _checkRanges(content);
  }

  Future<void> test_method_startOfParameterList() async {
    var content = '''
class A {
  foo^() {
    [!foo!]();
  }
}
''';

    await _checkRanges(content);
  }

  Future<void> test_method_startOfTypeParameterList() async {
    var content = '''
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

    var res = await getReferences(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_pattern_object_withDeclaration() async {
    var content = '''
class A {
  int get i => 0;
}

int f(Object o) {
  switch (o) {
    case A(:var /*[0*/^i/*0]*/):
      return /*[1*/i/*1]*/;
  }
  return 0;
}
''';

    await _checkRanges(content, includeDeclarations: true);
  }

  Future<void> test_pattern_object_withoutDeclaration() async {
    var content = '''
class A {
  int get i => 0;
}

int f(Object o) {
  switch (o) {
    case A(:var ^i):
      return [!i!];
  }
  return 0;
}
''';

    await _checkRanges(content);
  }

  Future<void> test_setter_decalaration_getterSetter() async {
    var content = '''
class MyClass {
  String get field => '';
  set fie^ld(String _) {}
}

void f() {
  MyClass()./*[0*/field/*0]*/ = '';
  print(MyClass()./*[1*/field/*1]*/);
  
  var myInstance = MyClass();
  myInstance./*[2*/field/*2]*/ = '';
  print(myInstance./*[3*/field/*3]*/);
  myInstance./*[4*/field/*4]*/ += myInstance./*[5*/field/*5]*/;
}
''';

    await _checkRanges(content);
  }

  Future<void> test_setter_invocation_getterSetter() async {
    var content = '''
class MyClass {
  String get field => '';
  set field(String _) {}
}

void f() {
  MyClass()./*[0*/fie^ld/*0]*/ = '';
  print(MyClass()./*[1*/field/*1]*/);
  
  var myInstance = MyClass();
  myInstance./*[2*/field/*2]*/ = '';
  print(myInstance./*[3*/field/*3]*/);
  myInstance./*[4*/field/*4]*/ += myInstance./*[5*/field/*5]*/;
}
''';

    await _checkRanges(content);
  }

  Future<void> test_singleFile_withoutDeclaration() async {
    var content = '''
f^oo() {
  [!foo!]();
}
''';

    await _checkRanges(content);
  }

  Future<void> test_type() async {
    var content = '''
class A^aa<T> {}

[!Aaa!]<String>? a;
''';

    await _checkRanges(content);
  }

  Future<void> test_type_generic_end() async {
    var content = '''
class Aaa^<T> {}

[!Aaa!]<String>? a;
''';

    await _checkRanges(content);
  }

  Future<void> test_unopenFile() async {
    var code = TestCode.parse('''
    f^oo() {
      [!foo!]();
    }
    ''');

    newFile(mainFilePath, code.code);
    await initialize();
    var res = await getReferences(mainFileUri, code.position.position);

    var expected = [
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
    var mainCode = TestCode.parse(mainContent);
    var otherCode = otherContent != null ? TestCode.parse(otherContent) : null;
    var otherFileUri = toUri(join(projectFolderPath, 'lib', 'other.dart'));

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    if (otherCode != null) {
      await openFile(otherFileUri, otherCode.code);
    }
    var res = await getReferences(
      mainFileUri,
      mainCode.position.position,
      includeDeclarations: includeDeclarations,
    );

    var expected = [
      for (final range in mainCode.ranges)
        Location(uri: mainFileUri, range: range.range),
      if (otherCode != null)
        for (final range in otherCode.ranges)
          Location(uri: otherFileUri, range: range.range),
    ];

    // Checking sets produces a better failure message than lists
    // (it'll show which item is missing instead of just saying
    // the lengths are different), so check that first.
    expect(res.toSet(), expected.toSet());
    // But also check the list in case there were unexpected duplicates.
    expect(res, unorderedEquals(expected));
  }
}
