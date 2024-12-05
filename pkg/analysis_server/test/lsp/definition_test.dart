// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/legacy_analysis_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
import 'package:analyzer_utilities/test/experiments/experiments.dart';
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
    var res =
        await getDefinitionAsLocation(mainFileUri, mainCode.position.position);

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(referencedCode.range.range));
    expect(loc.uri, equals(referencedFileUri));
  }

  Future<void> test_atDeclaration_class() async {
    var contents = '''
class [!^A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructorNamed() async {
    var contents = '''
class A {
  A.[!^named!]() {}
}
''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructorNamed_typeName() async {
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

  Future<void> test_atDeclaration_function() async {
    var contents = '''
void [!^f!]() {}
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
    var res =
        await getDefinitionAsLocation(mainFileUri, code.position.position);

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

  Future<void> test_constructorNamed() async {
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

  Future<void> test_constructorNamed_typeName() async {
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

  Future<void> test_directive_export() async {
    await verifyDirective(
      source: "export 'destin^ation.dart';",
    );
  }

  Future<void> test_directive_import() async {
    await verifyDirective(
      source: "import 'desti^nation.dart';",
    );
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
    if (!AnalysisServer.supportsPlugins) return;
    var pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    var pluginAnalyzedFileUri = pathContext.toUri(pluginAnalyzedFilePath);
    var pluginResult = plugin.AnalysisGetNavigationResult(
      [pluginAnalyzedFilePath],
      [NavigationTarget(ElementKind.CLASS, 0, 0, 5, 0, 0)],
      [
        NavigationRegion(0, 5, [0])
      ],
    );
    configureTestPlugin(respondWith: pluginResult);

    newFile(pluginAnalyzedFilePath, '');
    await initialize();
    var res = await getDefinitionAsLocation(
        pluginAnalyzedFileUri, lsp.Position(line: 0, character: 0));

    expect(res, hasLength(1));
    var loc = res.single;
    expect(
        loc.range,
        equals(lsp.Range(
            start: lsp.Position(line: 0, character: 0),
            end: lsp.Position(line: 0, character: 5))));
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

  Future<void> test_locationLink_class() async {
    setLocationLinkSupport();

    var code = TestCode.parse('''
final a = /*[0*/MyCl^ass/*0]*/();

/*[1*/class /*[2*/MyClass/*2]*/ {}/*1]*/
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var res =
        await getDefinitionAsLocationLinks(mainFileUri, code.position.position);

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
    var res =
        await getDefinitionAsLocationLinks(mainFileUri, code.position.position);

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
    var res =
        await getDefinitionAsLocationLinks(mainFileUri, code.position.position);

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
        mainFileUri, mainCode.position.position);

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
        mainFileUri, mainCode.position.position);

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
    var res =
        await getDefinitionAsLocationLinks(mainFileUri, code.position.position);

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
    var res =
        await getDefinitionAsLocationLinks(mainFileUri, code.position.position);

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.targetUri, mainFileUri);
    expect(loc.targetRange, code.ranges[0].range);
    expect(loc.targetSelectionRange, code.ranges[1].range);
    expect(loc.originSelectionRange, code.ranges[2].range);
  }

  Future<void> test_macro_macroGeneratedFileToUserFile() async {
    addMacros([declareInTypeMacro()]);

    setLocationLinkSupport(); // To verify the full set of ranges.
    setDartTextDocumentContentProviderSupport();

    var code = TestCode.parse('''
import 'macros.dart';

@DeclareInType('  void foo() { bar(); }')
class A {
  /*[0*/void /*[1*/bar/*1]*/() {}/*0]*/
}
''');

    await initialize();
    await Future.wait([
      openFile(mainFileUri, code.code),
      waitForAnalysisComplete(),
    ]);

    // Find the location of the call to bar() in the macro file so we can
    // invoke Definition on it.
    var macroResponse = await getDartTextDocumentContent(mainFileMacroUri);
    var macroContent = macroResponse!.content!;
    var barInvocationRange = rangeOfStringInString(macroContent, 'bar');

    // Invoke Definition in the macro file at the location of the call back to
    // the main file.
    var locations = await getDefinitionAsLocationLinks(
        mainFileMacroUri, barInvocationRange.start);
    var location = locations.single;

    // Check the origin selection range covers the text we'd expected in the
    // generated file.
    expect(
        getTextForRange(macroContent, location.originSelectionRange!), 'bar');

    // And the target matches our original file.
    expect(location.targetUri, mainFileUri);
    expect(location.targetRange, code.ranges[0].range);
    expect(location.targetSelectionRange, code.ranges[1].range);
  }

  Future<void> test_macro_userFileToMacroGeneratedFile() async {
    addMacros([declareInTypeMacro()]);

    // TODO(dantup): Consider making LocationLink the default for tests (with
    //  some specific tests for Location) because  it's what VS Code uses and
    //  has more fields to verify.
    setLocationLinkSupport(); // To verify the full set of ranges.
    setDartTextDocumentContentProviderSupport();

    var code = TestCode.parse('''
import 'macros.dart';

f() {
  A().[!foo^!]();
}

@DeclareInType('void foo() {}')
class A {}
''');

    await initialize();
    await openFile(mainFileUri, code.code);
    var locations =
        await getDefinitionAsLocationLinks(mainFileUri, code.position.position);
    var location = locations.single;

    expect(location.originSelectionRange, code.range.range);
    expect(location.targetUri, mainFileMacroUri);

    // To verify the other ranges, fetch the content for the file and check
    // those substrings are as expected.
    var macroResponse = await getDartTextDocumentContent(location.targetUri);
    var macroContent = macroResponse!.content!;
    expect(
        getTextForRange(macroContent, location.targetRange), 'void foo() {}');
    expect(getTextForRange(macroContent, location.targetSelectionRange), 'foo');
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
        mainFileUri, mainCode.position.position);

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.originSelectionRange, equals(mainCode.range.range));
    expect(loc.targetUri, equals(partFileUri));
    expect(loc.targetRange, equals(partCode.range.range));
    expect(
      loc.targetSelectionRange,
      equals(rangeOfString(partCode, 'add')),
    );
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
  Future<void> testContents(String contents, {bool inOpenFile = true}) async {
    var code = TestCode.parse(contents);
    await initialize();
    if (inOpenFile) {
      await openFile(mainFileUri, code.code);
    }
    var res =
        await getDefinitionAsLocation(mainFileUri, code.position.position);

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
    var destinationFilePath =
        join(projectFolderPath, 'lib', 'destination.dart');
    var destinationFileUri = toUri(destinationFilePath);

    newFile(sourceFilePath, sourceCode.code);
    newFile(destinationFilePath, destinationCode.code);
    await initialize();
    var res = await getDefinitionAsLocation(
        sourceFileUri, sourceCode.position.position);

    expect(res.single.uri, equals(destinationFileUri));
  }
}
