// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_testing/experiments/experiments.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DefinitionTest);
  });
}

@reflectiveTest
class DefinitionTest extends AbstractLspAnalysisServerTest {
  @override
  AnalysisServerOptions get serverOptions => AnalysisServerOptions()
    ..enabledExperiments = [
      ...super.serverOptions.enabledExperiments,
      ...experimentsForTests,
    ];

  Future<void> test_acrossFiles() async {
    var mainContents = '''
import 'referenced.dart';

void f() {
  fo^o();
}
''';

    var referencedContents = '''
/// Ensure the function is on a line that
/// does not exist in the mainContents file
/// to ensure we're translating offsets to line/col
/// using the correct file's LineInfo
/// ...
/// ...
/// ...
/// ...
/// ...
[!foo!]() {}
''';

    var referencedFilePath = join(projectFolderPath, 'lib', 'referenced.dart');
    var referencedFileUri = toUri(referencedFilePath);

    var mainCode = TestCode.parse(mainContents);
    var referencedCode = TestCode.parse(referencedContents);

    newFile(mainFilePath, mainCode.code);
    newFile(referencedFilePath, referencedCode.code);
    await initialize();
    var res = await getDefinitionAsLocation(
      mainFileUri,
      mainCode.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(referencedCode.range.range));
    expect(loc.uri, equals(referencedFileUri));
  }

  Future<void> test_atDeclaration_catchClauseParameter_error() async {
    var contents = '''
void foo() {
  try {} catch ([!^e!], s) {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_catchClauseParameter_stack() async {
    var contents = '''
void foo() {
  try {} catch (e, [!^s!]) {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_class() async {
    var contents = '''
class [!^A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructor_named() async {
    var contents = '''
class A {
  A.[!^named!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructor_named_factoryKeyword() async {
    var contents = '''
class A {
  ^factory [!named!]() => throw 0;
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructor_named_name() async {
    var contents = '''
class A {
  new [!na^med!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructor_named_newKeyword() async {
    var contents = '''
class A {
  ^new [!named!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructor_named_typeName() async {
    var contents = '''
class [!A!] {
  ^A.named() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_defaultConstructor() async {
    var contents = '''
class A {
  [!^A!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_defaultConstructor_factoryKeyword() async {
    var contents = '''
class A {
  [!^factory!]() => throw 0;
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_defaultConstructor_newKeyword() async {
    var contents = '''
class A {
  [!^new!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_enum() async {
    var contents = '''
enum [!^E!] { one }
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_extension() async {
    var contents = '''
extension [!^E!] on String {}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_extensionType() async {
    var contents = '''
extension type [!^E!](int it) {}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_function() async {
    var contents = '''
void [!^f!]() {}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_importPrefix() async {
    var contents = '''
import 'dart:math' as [!^math!];
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_method() async {
    var contents = '''
class A {
  void [!^f!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_mixin() async {
    var contents = '''
mixin [!^M!] {}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_primaryConstructor() async {
    var contents = '''
class [!^A!]();
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_primaryConstructor_parameter() async {
    var contents = '''
class A(final int [!^b!]);
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_typeAlias_functionType() async {
    var contents = '''
typedef void [!^F!]();
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_typeAlias_generic() async {
    var contents = '''
typedef [!^F!] = void Function();
''';

    await testContents(contents);
  }

  Future<void> test_catchClauseParameter_error() async {
    var contents = '''
void foo() {
  try {} catch ([!e!], s) {
    print(e^);
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_catchClauseParameter_stack() async {
    var contents = '''
void foo() {
  try {} catch (e, [!s!]) {
    print(s^);
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_closure_parameter() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
void f(void Function(int) _) {}

void g() => f((/*[0*/variable/*0]*/) {
  print(/*[1*/^variable/*1]*/);
});
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.first;
    expect(loc.originSelectionRange, equals(code.ranges.last.range));
    expect(loc.targetRange, equals(code.ranges.first.range));
    expect(loc.targetSelectionRange, equals(code.ranges.first.range));
  }

  Future<void> test_comment_adjacentReference() async {
    /// Computing Dart navigation locates a node at the provided offset then
    /// returns all navigation regions inside it. This test ensures we filter
    /// out any regions that are in the same target node (the comment) but do
    /// not span the requested offset.
    var contents = '''
/// Te^st
///
/// References [String].
void f() {}
''';
    var code = TestCode.parse(contents);

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocation(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(0));
  }

  Future<void> test_comment_enumMember_qualified() async {
    var contents = '''
/// [A.o^ne].
enum A {
  [!one!],
}
''';

    await testContents(contents);
  }

  Future<void> test_comment_extensionMember() async {
    var contents = '''
/// [myFi^eld]
extension on String {
  String get [!myField!] => '';
}
''';

    await testContents(contents);
  }

  Future<void> test_comment_extensionMember_qualified() async {
    var contents = '''
/// [StringExtension.myFi^eld]
extension StringExtension on String {
  String get [!myField!] => '';
}
''';

    await testContents(contents);
  }

  Future<void> test_comment_importPrefix() async {
    var contents = '''
/// This is a comment for [^math]
import 'dart:math' as [!math!];
''';

    await testContents(contents);
  }

  Future<void> test_comment_instanceMember_qualified() async {
    var contents = '''
/// [A.myFi^eld].
class A {
  final String [!myField!] = '';
}
''';

    await testContents(contents);
  }

  Future<void> test_comment_instanceMember_qualified_inherited() async {
    var contents = '''
class A {
  final String [!myField!] = '';
}
/// [B.myFi^eld].
class B extends A {}
''';

    await testContents(contents);
  }

  Future<void> test_comment_namedConstructor_qualified() async {
    var contents = '''
/// [A.nam^ed].
class A {
  A.[!named!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_comment_staticMember_qualified() async {
    var contents = '''
/// [A.myStaticFi^eld].
class A {
  static final String [!myStaticField!] = '';
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor() async {
    var contents = '''
f() {
  final a = A^();
}

class A {
  [!A!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_factory() async {
    var contents = '''
f() {
  final a = A.ne^w();
}

class A {
  [!factory!]() => throw 0;
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_named() async {
    var contents = '''
f() {
  final a = A.named^();
}

class A {
  A.[!named!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_named_factory() async {
    var contents = '''
f() {
  final a = A.nam^ed();
}

class A {
  factory [!named!]() => throw 0;
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_named_new() async {
    var contents = '''
f() {
  final a = A.nam^ed();
}

class A {
  new [!named!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_named_typeName() async {
    var contents = '''
f() {
  final a = A^.named();
}

class [!A!] {
  A.named();
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_new() async {
    var contents = '''
f() {
  final a = A.ne^w();
}

class A {
  [!new!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_redirectingSuper_wildcards() async {
    var contents = '''
class A {
  final int x, y;
  A(this.[!x!], [this.y = 0]);
}

class C extends A {
  final int c;
  C(this.c, super.^_);
}
''';

    await testContents(contents);
  }

  Future<void> test_constructor_thisReference_wildcards() async {
    var contents = '''
class A {
  final int [!_!];
  A(this.^_);
}
''';

    await testContents(contents);
  }

  Future<void> test_directive_export() async {
    await verifyDirective(source: "export 'destin^ation.dart';");
  }

  Future<void> test_directive_import() async {
    await verifyDirective(source: "import 'desti^nation.dart';");
  }

  Future<void> test_directive_part() async {
    await verifyDirective(
      source: "part 'desti^nation.dart';",
      destination: "part of 'source.dart';",
    );
  }

  Future<void> test_directive_partOf() async {
    await verifyDirective(
      source: "part of 'destin^ation.dart';",
      destination: "part 'source.dart';",
    );
  }

  Future<void> test_dotShorthand_constructor_named() async {
    var contents = '''
f() {
  A a = .nam^ed();
}

class A {
  A.[!named!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_dotShorthand_constructor_unnamed() async {
    var contents = '''
f() {
  A a = .ne^w();
}

class A {
  [!A!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_dotShorthand_enum() async {
    var contents = '''
enum A {
  [!one!],
}

f() {
  A a = .on^e;
}
''';

    await testContents(contents);
  }

  Future<void> test_dotShorthand_extensionType() async {
    var contents = '''
f() {
  A a = .fie^ld;
}

extension type A(int x) {
  static A get [!field!] => A(1);
}
''';

    await testContents(contents);
  }

  Future<void> test_dotShorthand_field() async {
    var contents = '''
f() {
  A a = .fie^ld;
}

class A {
  static A [!field!] = A();
}
''';

    await testContents(contents);
  }

  Future<void> test_dotShorthand_method() async {
    var contents = '''
f() {
  A a = .meth^od();
}

class A {
  static A [!method!]() => A();
}
''';

    await testContents(contents);
  }

  Future<void> test_field_underscore() async {
    var contents = '''
class A {
  int [!_!] = 1;
  int f() => _^;
}
''';

    await testContents(contents);
  }

  Future<void> test_fieldFormalParam() async {
    var contents = '''
class A {
  final String [!a!];
  A(this.^a);
}
''';

    await testContents(contents);
  }

  Future<void> test_fromPlugins() async {
    var pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    var pluginAnalyzedFileUri = pathContext.toUri(pluginAnalyzedFilePath);
    var pluginResult = plugin.AnalysisGetNavigationResult(
      [pluginAnalyzedFilePath],
      [NavigationTarget(ElementKind.CLASS, 0, 0, 5, 0, 0)],
      [
        NavigationRegion(0, 5, [0]),
      ],
    );
    configureTestPlugin(respondWith: pluginResult);

    newFile(pluginAnalyzedFilePath, '');
    await initialize();
    var res = await getDefinitionAsLocation(
      pluginAnalyzedFileUri,
      lsp.Position(line: 0, character: 0),
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(
      loc.range,
      equals(
        lsp.Range(
          start: lsp.Position(line: 0, character: 0),
          end: lsp.Position(line: 0, character: 5),
        ),
      ),
    );
    expect(loc.uri, equals(pluginAnalyzedFileUri));
  }

  Future<void> test_function() async {
    var contents = '''
[!foo!]() {
  fo^o();
}
''';

    await testContents(contents);
  }

  Future<void> test_function_inNullAwareElement_inList() async {
    var contents = '''
bool? [!foo!]() => null;

bar() {
  return [?fo^o()];
}
''';

    await testContents(contents);
  }

  Future<void> test_function_inNullAwareElement_inSet() async {
    var contents = '''
bool? [!foo!]() => null;

bar() {
  return {?fo^o()};
}
''';

    await testContents(contents);
  }

  Future<void> test_function_inNullAwareKey_inMap() async {
    var contents = '''
bool? [!foo!]() => null;

bar() {
  return {?fo^o(): "value"};
}
''';

    await testContents(contents);
  }

  Future<void> test_function_inNullAwareValue_inMap() async {
    var contents = '''
bool? [!foo!]() => null;

bar() {
  return {"key": ?fo^o()};
}
''';

    await testContents(contents);
  }

  Future<void> test_functionInPattern() async {
    var contents = '''
bool [!greater!](int x, int y) => x > y;

foo(Object pair) {
  switch (pair) {
    case (int a, int b) when g^reater(a,b):
      break;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_functionTypeCall_nothing() async {
    // https://github.com/dart-lang/sdk/issues/61319
    var contents = '''
void f() {
  f.cal^l();
}
''';
    await testContents(contents, expectNoResults: true);
  }

  Future<void> test_importPrefix() async {
    var contents = '''
import 'dart:math' as [!math!];

^math.Random? r;
''';

    await testContents(contents);
  }

  Future<void> test_importPrefix_multiple() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
import 'dart:math' as /*[0*/math/*0]*/;
import 'dart:async' as /*[1*/math/*1]*/;

/*[2*/^math/*2]*/.Random? r;
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(2));
    for (var (index, loc) in res.indexed) {
      expect(loc.originSelectionRange, equals(code.ranges.last.range));
      expect(loc.targetRange, equals(code.ranges[index].range));
      expect(loc.targetSelectionRange, equals(code.ranges[index].range));
    }
  }

  Future<void> test_importPrefix_multiple_alone() async {
    var code = TestCode.parse('''
import 'dart:math' as /*[0*/math/*0]*/;
import 'dart:async' as /*[1*/math/*1]*/;

void foo() {
  // ignore: prefix_identifier_not_followed_by_dot
  /*[2*/^math/*2]*/;
}
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocation(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(2));
    for (var (index, loc) in res.indexed) {
      expect(loc.range, equals(code.ranges[index].range));
    }
  }

  Future<void> test_importPrefix_multiple_comment() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
import 'dart:math' as /*[0*/math/*0]*/;
import 'dart:async' as /*[1*/math/*1]*/;

/// This is a comment that talks about [/*[2*/^math/*2]*/].
math.Random? r;
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(2));
    for (var (index, loc) in res.indexed) {
      expect(loc.originSelectionRange, equals(code.ranges.last.range));
      expect(loc.targetRange, equals(code.ranges[index].range));
      expect(loc.targetSelectionRange, equals(code.ranges[index].range));
    }
  }

  Future<void> test_keywordNavigation_break_toDo() async {
    var contents = '''
void f() {
  [!do!] {
    if (true) br^eak;
  } while (true);
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_break_toFor() async {
    var contents = '''
void f() {
  [!for!] (;;) {
    if (true) br^eak;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_break_toSwitch() async {
    var contents = '''
void f(int x) {
  [!switch!] (x) {
    case 1:
      br^eak;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_break_toWhile() async {
    var contents = '''
void f() {
  [!while!] (true) {
    if (true) br^eak;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_break_withLabel() async {
    var contents = '''
void f() {
  outer:
  [!do!] {
    do {
      if (true) br^eak outer;
    } while (true);
  } while (true);
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_continue_toFor() async {
    var contents = '''
void f() {
  [!for!] (;;) {
    if (true) cont^inue;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_continue_toFor_insideSwitch() async {
    var contents = '''
void f() {
  [!for!] (;;) {
    switch (true) {
      case _: cont^inue;
    }
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_continue_toWhile() async {
    var contents = '''
void f() {
  [!while!] (true) {
    if (true) cont^inue;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_nestedLoop() async {
    var contents = '''
void f() {
  for (;;) {
    [!while!] (true) {
      if (true) br^eak;
    }
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_noTarget() async {
    failTestOnErrorDiagnostic = false;

    var contents = '''
void f() {
  br^eak; // no loop
}
''';
    await testContents(contents, expectNoResults: true);
  }

  Future<void> test_keywordNavigation_return_toClosure() async {
    var contents = '''
int foo() {
  return [1].firstWhere([!(!]i) {
    ret^urn true;
  });
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_return_toConstructor_named() async {
    var contents = '''
class MyClass {
  MyClass.[!fooConstructor!]() {
    ret^urn;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_return_toConstructor_unnamed() async {
    var contents = '''
class MyClass {
  [!MyClass!]() {
    ret^urn;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_return_toFunction() async {
    var contents = '''
int [!foo!]() {
  if (true) ret^urn 42;
  return 0;
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_return_toGetter() async {
    var contents = '''
class C {
  int get [!value!] {
    if (true) ret^urn 42;
    return 0;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_keywordNavigation_yield_toFunction() async {
    var contents = '''
Iterable<int> [!generator!]() sync* {
  yi^eld 1;
  yield 2;
}
''';

    await testContents(contents);
  }

  Future<void> test_label() async {
    var contents = '''
f() {
  [!lbl!]:
  for (;;) {
    break lb^l;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_locationLink_class() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
final a = /*[0*/MyCl^ass/*0]*/();

/*[1*/class /*[2*/MyClass/*2]*/ {}/*1]*/
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(code.ranges[0].range));
    expect(loc.targetRange, equals(code.ranges[1].range));
    expect(loc.targetSelectionRange, equals(code.ranges[2].range));
  }

  Future<void> test_locationLink_extensionType_primaryConstructor() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
final a = /*[0*/MyExtens^ionType/*0]*/(1);

/*[1*/extension type /*[2*/MyExtensionType/*2]*/(int a) implements int {}/*1]*/
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(code.ranges[0].range));
    expect(loc.targetRange, equals(code.ranges[1].range));
    expect(loc.targetSelectionRange, equals(code.ranges[2].range));
  }

  Future<void>
  test_locationLink_extensionType_primaryConstructor_named() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
final a = MyExtensionType./*[0*/na^med/*0]*/(1);

/*[1*/extension type MyExtensionType./*[2*/named/*2]*/(int a) implements int {}/*1]*/
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(code.ranges[0].range));
    expect(loc.targetRange, equals(code.ranges[1].range));
    expect(loc.targetSelectionRange, equals(code.ranges[2].range));
  }

  Future<void> test_locationLink_field() async {
    setLocationLinkSupport();

    var mainContents = '''
import 'referenced.dart';

void f() {
  Icons().[!ad^d!];
}
''';

    var referencedContents = '''
void unrelatedFunction() {}

class Icons {
  /// `targetRange` should not include the dartDoc but should include the
  /// full field body. `targetSelectionRange` will be just the name.
  [!String add = "Test"!];
}

void otherUnrelatedFunction() {}
''';

    var referencedFilePath = join(projectFolderPath, 'lib', 'referenced.dart');
    var referencedFileUri = toUri(referencedFilePath);

    var mainCode = TestCode.parse(mainContents);
    var referencedCode = TestCode.parse(referencedContents);

    newFile(mainFilePath, mainCode.code);
    newFile(referencedFilePath, referencedCode.code);
    await initialize();
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      mainCode.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(mainCode.range.range));
    expect(loc.targetUri, equals(referencedFileUri));
    expect(loc.targetRange, equals(referencedCode.range.range));
    expect(
      loc.targetSelectionRange,
      equals(rangeOfString(referencedCode, 'add')),
    );
  }

  Future<void> test_locationLink_function() async {
    setLocationLinkSupport();

    var mainContents = '''
import 'referenced.dart';

void f() {
  [!fo^o!]();
}
''';

    var referencedContents = '''
void unrelatedFunction() {}

/// `targetRange` should not include the dartDoc but should include the full
/// function body. `targetSelectionRange` will be just the name.
[!void foo() {
  // Contents of function
}!]

void otherUnrelatedFunction() {}
''';

    var referencedFilePath = join(projectFolderPath, 'lib', 'referenced.dart');
    var referencedFileUri = toUri(referencedFilePath);

    var mainCode = TestCode.parse(mainContents);
    var referencedCode = TestCode.parse(referencedContents);

    newFile(mainFilePath, mainCode.code);
    newFile(referencedFilePath, referencedCode.code);
    await initialize();
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      mainCode.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(mainCode.range.range));
    expect(loc.targetUri, equals(referencedFileUri));
    expect(loc.targetRange, equals(referencedCode.range.range));
    expect(
      loc.targetSelectionRange,
      equals(rangeOfString(referencedCode, 'foo')),
    );
  }

  /// Verify that for a variable declaration list with multiple variables,
  /// we use only this variables range so that other variables are not visible
  /// in the preview.
  Future<void> test_locationLink_variableDeclaration_multiple() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
var y=1, /*[0*//*[1*/x/*1]*/ = "Test"/*0]*/;

void f() {
  /*[2*/x/*2]*/^;
}
''');

    newFile(mainFilePath, code.code);
    await initialize();
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.targetUri, mainFileUri);
    expect(loc.targetRange, code.ranges[0].range);
    expect(loc.targetSelectionRange, code.ranges[1].range);
    expect(loc.originSelectionRange, code.ranges[2].range);
  }

  /// Verify that for a variable declaration list with only a single variable,
  /// we expand the range to the variable declaration list so that the keyword
  /// or type show up in the preview.
  Future<void> test_locationLink_variableDeclaration_single() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
/*[0*/var /*[1*/x/*1]*/ = "Test"/*0]*/;

void f() {
  /*[2*/x/*2]*/^;
}
''');

    newFile(mainFilePath, code.code);
    await initialize();
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.targetUri, mainFileUri);
    expect(loc.targetRange, code.ranges[0].range);
    expect(loc.targetSelectionRange, code.ranges[1].range);
    expect(loc.originSelectionRange, code.ranges[2].range);
  }

  Future<void> test_method_underscore() async {
    var contents = '''
class A {
  int [!_!]() => 1;
  int f() => _^();
}
''';

    await testContents(contents);
  }

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    var res = await getDefinitionAsLocation(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_part() async {
    setLocationLinkSupport();

    var mainContents = '''
import 'lib.dart';

void f() {
  Icons().[!ad^d!];
}
''';

    var libContents = '''
part 'part.dart';
''';

    var partContents = '''
part of 'lib.dart';

void unrelatedFunction() {}

class Icons {
  /// `targetRange` should not include the dartDoc but should include the full
  /// function body. `targetSelectionRange` will be just the name.
  [!String add = "Test"!];
}

void otherUnrelatedFunction() {}
''';

    var libFilePath = join(projectFolderPath, 'lib', 'lib.dart');
    var partFilePath = join(projectFolderPath, 'lib', 'part.dart');
    var partFileUri = toUri(partFilePath);

    var mainCode = TestCode.parse(mainContents);
    var libCode = TestCode.parse(libContents);
    var partCode = TestCode.parse(partContents);

    newFile(mainFilePath, mainCode.code);
    newFile(libFilePath, libCode.code);
    newFile(partFilePath, partCode.code);
    await initialize();
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      mainCode.position.position,
    );

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(mainCode.range.range));
    expect(loc.targetUri, equals(partFileUri));
    expect(loc.targetRange, equals(partCode.range.range));
    expect(loc.targetSelectionRange, equals(rangeOfString(partCode, 'add')));
  }

  Future<void> test_patternVariable_ifCase_logicalOr() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
void f(Object? x) {
  if (x case int /*[0*//*0*/test/*0]*/ || [int /*[1*/test/*1]*/] when test > 0) {
    /*[2*//*1*/test/*2]*/ = 1;
  }
}
''', positionShorthand: false);

    await initialize();
    await openFile(mainFileUri, code.code);

    // Selecting on the first declaration of `test`
    var res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.positions.first.position,
    );
    expect(res, hasLength(2));
    for (var (index, loc) in res.indexed) {
      expect(loc.originSelectionRange, equals(code.ranges.first.range));
      expect(loc.targetRange, equals(code.ranges[index].range));
      expect(loc.targetSelectionRange, equals(code.ranges[index].range));
    }

    // Selecting on the assignment of `test = 1`
    res = await getDefinitionAsLocationLinks(
      mainFileUri,
      code.positions.last.position,
    );
    expect(res, hasLength(2));
    for (var (index, loc) in res.indexed) {
      expect(loc.originSelectionRange, equals(code.ranges.last.range));
      expect(loc.targetRange, equals(code.ranges[index].range));
      expect(loc.targetSelectionRange, equals(code.ranges[index].range));
    }
  }

  Future<void> test_primaryConstructor() async {
    var contents = '''
final a = A^();

class [!A!]();
''';

    await testContents(contents);
  }

  Future<void> test_primaryConstructor_body_declaringParameter() async {
    var contents = '''
class A(final int [!i!]) {
  this {
    ^i;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_primaryConstructor_body_parameter() async {
    var contents = '''
class A(int [!i!]) {
  this {
    ^i;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_primaryConstructor_parameterList_typeName() async {
    var contents = '''
class [!B!] {}

class A(final ^B b);
''';

    await testContents(contents);
  }

  Future<void> test_sameLine() async {
    var contents = '''
int plusOne(int [!value!]) => 1 + val^ue;
''';

    await testContents(contents);
  }

  Future<void> test_superFormalParam() async {
    var contents = '''
class A {
  A({required int [!a!]});
}
class B extends A {
  B({required super.^a}) : assert(a > 0);
}
''';

    await testContents(contents);
  }

  Future<void> test_topLevelVariable_underscore() async {
    var contents = '''
int [!_!] = 0;
int f = ^_;
''';

    await testContents(contents);
  }

  Future<void> test_type() async {
    var contents = '''
f() {
  final a = A^;
}

class [!A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_type_generic_end() async {
    var contents = '''
f() {
  final a = A^<String>();
}

class [!A!]<T> {}
''';

    await testContents(contents);
  }

  Future<void> test_type_inNullAwareElement_inList() async {
    var contents = '''
f() {
  final a = [?A^];
}

class [!A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_type_inNullAwareElement_inSet() async {
    var contents = '''
f() {
  final a = {?A^};
}

class [!A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_type_inNullAwareKey_inMap() async {
    var contents = '''
f() {
  final a = {?A^, "value"};
}

class [!A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_type_inNullAwareValue_inMap() async {
    var contents = '''
f() {
  final a = {"key": ?A^};
}

class [!A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_unexisting_implicit_new_constructor() async {
    var contents = '''
class [!A!] {
  A.constructor();
}

void f() {
  // ignore: new_with_undefined_constructor_default
  A^();
}
''';

    await testContents(contents);
  }

  Future<void> test_unopenFile() async {
    var contents = '''
[!foo!]() {
  fo^o();
}
''';
    var code = TestCode.parse(contents);

    newFile(mainFilePath, code.code);
    await testContents(contents, inOpenFile: false);
  }

  Future<void> test_variableInPattern() async {
    var contents = '''
foo() {
  var m = <String, int>{};
  const [!str!] = 'h';
  if (m case {'d':3, s^tr:4, }){}
}
''';

    await testContents(contents);
  }

  Future<void> test_varKeyword() async {
    var contents = '''
va^r a = MyClass();

class [!MyClass!] {}
''';

    await testContents(contents);
  }

  /// Expects definitions at the location of `^` in [contents] will navigate to
  /// the range in `[!` brackets `!]` in `[contents].
  Future<void> testContents(
    String contents, {
    bool inOpenFile = true,
    bool expectNoResults = false,
  }) async {
    var code = TestCode.parse(contents);
    await initialize();
    if (inOpenFile) {
      await openFile(mainFileUri, code.code);
    }
    var res = await getDefinitionAsLocation(
      mainFileUri,
      code.position.position,
    );

    if (expectNoResults) {
      expect(
        code.ranges,
        isEmpty,
        reason: 'TestCode should not contain ranges if expectNoResults=true',
      );
      expect(res, isEmpty);
      return;
    }

    expect(code.ranges, hasLength(1));
    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(code.range.range));
    expect(loc.uri, equals(mainFileUri));
  }

  /// Verifies that invoking Definition at `^` in [source] (which will be
  /// written into `source.dart`) navigate to `destination.dart` (with the
  /// content [destination]).
  Future<void> verifyDirective({
    required String source,
    String destination = '',
  }) async {
    var destinationCode = TestCode.parse(destination);
    var sourceCode = TestCode.parse(source);

    var sourceFilePath = join(projectFolderPath, 'lib', 'source.dart');
    var sourceFileUri = toUri(sourceFilePath);
    var destinationFilePath = join(
      projectFolderPath,
      'lib',
      'destination.dart',
    );
    var destinationFileUri = toUri(destinationFilePath);

    newFile(sourceFilePath, sourceCode.code);
    newFile(destinationFilePath, destinationCode.code);
    await initialize();
    var res = await getDefinitionAsLocation(
      sourceFileUri,
      sourceCode.position.position,
    );

    expect(res.single.uri, equals(destinationFileUri));
  }
}
