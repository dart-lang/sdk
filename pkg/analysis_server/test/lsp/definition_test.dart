// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart' as plugin;
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
  Future<void> test_acrossFiles() async {
    final mainContents = '''
    import 'referenced.dart';

    void f() {
      fo^o();
    }
    ''';

    final referencedContents = '''
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

    final referencedFileUri =
        toUri(join(projectFolderPath, 'lib', 'referenced.dart'));

    final mainCode = TestCode.parse(mainContents);
    final referencedCode = TestCode.parse(referencedContents);

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    await openFile(referencedFileUri, referencedCode.code);
    final res =
        await getDefinitionAsLocation(mainFileUri, mainCode.position.position);

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(referencedCode.range.range));
    expect(loc.uri, equals(referencedFileUri));
  }

  Future<void> test_atDeclaration_class() async {
    final contents = '''
class [!^A!] {}
    ''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructorNamed() async {
    final contents = '''
class A {
  A.[!^named!]() {}
}
    ''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_constructorNamed_typeName() async {
    final contents = '''
class [!A!] {
  ^A.named() {}
}
    ''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_defaultConstructor() async {
    final contents = '''
class A {
  [!^A!]() {}
}
    ''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_function() async {
    final contents = '''
void [!^f!]() {}
    ''';

    await testContents(contents);
  }

  Future<void> test_atDeclaration_method() async {
    final contents = '''
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
    final contents = '''
    /// Te^st
    ///
    /// References [String].
    void f() {}
    ''';
    final code = TestCode.parse(contents);

    await initialize();
    await openFile(mainFileUri, code.code);
    final res =
        await getDefinitionAsLocation(mainFileUri, code.position.position);

    expect(res, hasLength(0));
  }

  Future<void> test_comment_enumMember_qualified() async {
    final contents = '''
      /// [A.o^ne].
      enum A {
        [!one!],
      }
    ''';

    await testContents(contents);
  }

  Future<void> test_comment_extensionMember() async {
    final contents = '''
      /// [myFi^eld]
      extension on String {
        String get [!myField!] => '';
      }
    ''';

    await testContents(contents);
  }

  Future<void> test_comment_extensionMember_qualified() async {
    final contents = '''
      /// [StringExtension.myFi^eld]
      extension StringExtension on String {
        String get [!myField!] => '';
      }
    ''';

    await testContents(contents);
  }

  Future<void> test_comment_instanceMember_qualified() async {
    final contents = '''
      /// [A.myFi^eld].
      class A {
        final String [!myField!] = '';
      }
    ''';

    await testContents(contents);
  }

  Future<void> test_comment_instanceMember_qualified_inherited() async {
    final contents = '''
      class A {
        final String [!myField!] = '';
      }
      /// [B.myFi^eld].
      class B extends A {}
    ''';

    await testContents(contents);
  }

  Future<void> test_comment_namedConstructor_qualified() async {
    final contents = '''
      /// [A.nam^ed].
      class A {
        A.[!named!]();
      }
    ''';

    await testContents(contents);
  }

  Future<void> test_comment_staticMember_qualified() async {
    final contents = '''
      /// [A.myStaticFi^eld].
      class A {
        static final String [!myStaticField!] = '';
      }
    ''';

    await testContents(contents);
  }

  Future<void> test_constructor() async {
    final contents = '''
f() {
  final a = A^();
}

class A {
  [!A!]();
}
''';

    await testContents(contents);
  }

  Future<void> test_constructorNamed() async {
    final contents = '''
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
    final contents = '''
f() {
  final a = A^.named();
}

class [!A!] {
  A.named();
}
''';

    await testContents(contents);
  }

  Future<void> test_fieldFormalParam() async {
    final contents = '''
class A {
  final String [!a!];
  A(this.^a});
}
''';

    await testContents(contents);
  }

  Future<void> test_fromPlugins() async {
    if (!AnalysisServer.supportsPlugins) return;
    final pluginAnalyzedFilePath = join(projectFolderPath, 'lib', 'foo.foo');
    final pluginAnalyzedFileUri = pathContext.toUri(pluginAnalyzedFilePath);
    final pluginResult = plugin.AnalysisGetNavigationResult(
      [pluginAnalyzedFilePath],
      [NavigationTarget(ElementKind.CLASS, 0, 0, 5, 0, 0)],
      [
        NavigationRegion(0, 5, [0])
      ],
    );
    configureTestPlugin(respondWith: pluginResult);

    newFile(pluginAnalyzedFilePath, '');
    await initialize();
    final res = await getDefinitionAsLocation(
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
    final contents = '''
[!foo!]() {
  fo^o();
}
''';

    await testContents(contents);
  }

  Future<void> test_functionInPattern() async {
    final contents = '''
bool [!greater!](int x, int y) => x > y;

foo(int m) {
  switch (pair) {
    case (int a, int b) when g^reater(a,b):
      break;
  }
}
''';

    await testContents(contents);
  }

  Future<void> test_locationLink_field() async {
    setLocationLinkSupport();

    final mainContents = '''
    import 'referenced.dart';

    void f() {
      Icons.[!ad^d!]();
    }
    ''';

    final referencedContents = '''
    void unrelatedFunction() {}

    class Icons {
      /// `targetRange` should not include the dartDoc but should include the full
      /// function body. `targetSelectionRange` will be just the name.
      [!String add = "Test"!];
    }

    void otherUnrelatedFunction() {}
    ''';

    final referencedFileUri =
        toUri(join(projectFolderPath, 'lib', 'referenced.dart'));

    final mainCode = TestCode.parse(mainContents);
    final referencedCode = TestCode.parse(referencedContents);

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    await openFile(referencedFileUri, referencedCode.code);
    final res = await getDefinitionAsLocationLinks(
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

    final mainContents = '''
    import 'referenced.dart';

    void f() {
      [!fo^o!]();
    }
    ''';

    final referencedContents = '''
    void unrelatedFunction() {}

    /// `targetRange` should not include the dartDoc but should include the full
    /// function body. `targetSelectionRange` will be just the name.
    [!void foo() {
      // Contents of function
    }!]

    void otherUnrelatedFunction() {}
    ''';

    final referencedFileUri =
        toUri(join(projectFolderPath, 'lib', 'referenced.dart'));

    final mainCode = TestCode.parse(mainContents);
    final referencedCode = TestCode.parse(referencedContents);

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    await openFile(referencedFileUri, referencedCode.code);
    final res = await getDefinitionAsLocationLinks(
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

  Future<void> test_nonDartFile() async {
    newFile(pubspecFilePath, simplePubspecContent);
    await initialize();

    final res = await getDefinitionAsLocation(pubspecFileUri, startOfDocPos);
    expect(res, isEmpty);
  }

  Future<void> test_part() async {
    setLocationLinkSupport();

    final mainContents = '''
    import 'lib.dart';

    void f() {
      Icons.[!ad^d!]();
    }
    ''';

    final libContents = '''
    part 'part.dart';
    ''';

    final partContents = '''
    part of 'lib.dart';

    void unrelatedFunction() {}

    class Icons {
      /// `targetRange` should not include the dartDoc but should include the full
      /// function body. `targetSelectionRange` will be just the name.
      [!String add = "Test"!];
    }

    void otherUnrelatedFunction() {}
    ''';

    final libFileUri = toUri(join(projectFolderPath, 'lib', 'lib.dart'));
    final partFileUri = toUri(join(projectFolderPath, 'lib', 'part.dart'));

    final mainCode = TestCode.parse(mainContents);
    final libCode = TestCode.parse(libContents);
    final partCode = TestCode.parse(partContents);

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    await openFile(libFileUri, libCode.code);
    await openFile(partFileUri, partCode.code);
    final res = await getDefinitionAsLocationLinks(
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

  Future<void> test_partFilename() async {
    final mainContents = '''
part 'pa^rt.dart';
    ''';

    final partContents = '''
part of 'main.dart';
    ''';

    final partFileUri = toUri(join(projectFolderPath, 'lib', 'part.dart'));

    final mainCode = TestCode.parse(mainContents);
    final partCode = TestCode.parse(partContents);

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    await openFile(partFileUri, partCode.code);
    final res =
        await getDefinitionAsLocation(mainFileUri, mainCode.position.position);

    expect(res.single.uri, equals(partFileUri));
  }

  Future<void> test_partOfFilename() async {
    final mainContents = '''
part 'part.dart';
    ''';

    final partContents = '''
part of 'ma^in.dart';
    ''';

    final partFileUri = toUri(join(projectFolderPath, 'lib', 'part.dart'));

    final mainCode = TestCode.parse(mainContents);
    final partCode = TestCode.parse(partContents);

    await initialize();
    await openFile(mainFileUri, mainCode.code);
    await openFile(partFileUri, partCode.code);
    final res =
        await getDefinitionAsLocation(partFileUri, partCode.position.position);

    expect(res.single.uri, equals(mainFileUri));
  }

  Future<void> test_sameLine() async {
    final contents = '''
int plusOne(int [!value!]) => 1 + val^ue;
''';

    await testContents(contents);
  }

  Future<void> test_superFormalParam() async {
    final contents = '''
class A {
  A({required int [!a!]});
}
class B extends A {
  B({required super.^a}) : assert(a > 0);
}
''';

    await testContents(contents);
  }

  Future<void> test_type() async {
    final contents = '''
f() {
  final a = A^;
}

class [!A!] {}
''';

    await testContents(contents);
  }

  Future<void> test_type_generic_end() async {
    final contents = '''
f() {
  final a = A^<String>();
}

class [!A!]<T> {}
''';

    await testContents(contents);
  }

  Future<void> test_unopenFile() async {
    final contents = '''
[!foo!]() {
  fo^o();
}
''';
    final code = TestCode.parse(contents);

    newFile(mainFilePath, code.code);
    await testContents(contents, inOpenFile: false);
  }

  Future<void> test_variableInPattern() async {
    final contents = '''
foo() {
  var m = <String,int>{};
  const [!str!] = 'h';
  if (m case {'d':3, s^tr:4, ... }){}
}
''';

    await testContents(contents);
  }

  Future<void> test_varKeyword() async {
    final contents = '''
    va^r a = MyClass();

    class [!MyClass!] {}
    ''';

    await testContents(contents);
  }

  /// Expects definitions at the location of `^` in [contents] will navigate to
  /// the range in `[!` brackets `!]` in `[contents].
  Future<void> testContents(String contents, {bool inOpenFile = true}) async {
    final code = TestCode.parse(contents);
    await initialize();
    if (inOpenFile) {
      await openFile(mainFileUri, code.code);
    }
    final res =
        await getDefinitionAsLocation(mainFileUri, code.position.position);

    expect(res, hasLength(1));
    var loc = res.single;
    expect(loc.range, equals(code.range.range));
    expect(loc.uri, equals(mainFileUri));
  }
}
