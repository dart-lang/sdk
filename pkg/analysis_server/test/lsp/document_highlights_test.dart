// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../tool/lsp_spec/matchers.dart';
import '../utils/test_code_extensions.dart';
import 'server_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DocumentHighlightsTest);
  });
}

@reflectiveTest
class DocumentHighlightsTest extends AbstractLspAnalysisServerTest {
  Future<void> test_bound_topLevelVariable_wildcard() => _testMarkedContent('''
var /*[0*/^_/*0]*/ = 1;
void f() {
  var _ = 2;
  print(/*[1*/_/*1]*/);
}
''');

  Future<void> test_forInLoop() => _testMarkedContent('''
void f() {
  for (final /*[0*/x^/*0]*/ in []) {
    /*[1*/x/*1]*/;
  }
}
''');

  Future<void> test_functions() => _testMarkedContent('''
/*[0*/main/*0]*/() {
  /*[1*/mai^n/*1]*/();
}
''');

  Future<void> test_invalidLineByOne() async {
    // Test that requesting a line that's too high by one returns a valid
    // error response instead of throwing.
    const content = '// single line';

    await initialize();
    await openFile(mainFileUri, content);

    // Lines are zero-based so 1 is invalid.
    var pos = Position(line: 1, character: 0);
    var request = getDocumentHighlights(mainFileUri, pos);

    await expectLater(
      request,
      throwsA(isResponseError(ServerErrorCodes.InvalidFileLineCol)),
    );
  }

  Future<void> test_localVariable() => _testMarkedContent('''
void f() {
  var /*[0*/f^oo/*0]*/ = 1;
  print(/*[1*/foo/*1]*/);
  /*[2*/foo/*2]*/ = 2;
}
''');

  Future<void> test_macroGenerated() async {
    setDartTextDocumentContentProviderSupport();
    addMacros([declareInTypeMacro()]);

    const content = '''
import 'macros.dart';

@DeclareInType('void f() { f(); }')
class A {}
''';
    newFile(mainFilePath, content);
    await Future.wait([waitForAnalysisComplete(), initialize()]);

    // Fetch the content and locate the two references to `f` we will test.
    var generatedFile = await getDartTextDocumentContent(mainFileMacroUri);
    var generatedContent = generatedFile!.content!;
    var functionDefinitionOffset = generatedContent.indexOf('f() {');
    var functionCallOffset = generatedContent.indexOf('f();');
    var functionDefinitionPosition = positionFromOffset(
      functionDefinitionOffset,
      generatedContent,
    );
    var functionCallOffsetPosition = positionFromOffset(
      functionCallOffset,
      generatedContent,
    );

    // Request document highlights on one occurrence of `f`.
    var highlights = await getDocumentHighlights(
      mainFileMacroUri,
      functionDefinitionPosition,
    );

    // Ensure we got back both.
    expect(highlights, hasLength(2));
    expect(highlights![0].range.start, functionDefinitionPosition);
    expect(highlights[1].range.start, functionCallOffsetPosition);
  }

  Future<void> test_method_underscore() => _testMarkedContent('''
class C {
  /*[0*/_/*0]*/() {
    /*[1*/^_/*1]*/();
  }
}
''');

  Future<void> test_nonDartFile() async {
    await initialize();
    await openFile(pubspecFileUri, simplePubspecContent);

    var highlights = await getDocumentHighlights(pubspecFileUri, startOfDocPos);

    // Non-Dart files should return empty results, not errors.
    expect(highlights, isEmpty);
  }

  Future<void> test_noResult() => _testMarkedContent('''
void f() {
  // This one is in a ^ comment!
}
''');

  Future<void> test_onlySelf() => _testMarkedContent('''
void f() {
  /*[0*/prin^t/*0]*/('');
}
''');

  Future<void> test_onlySelf_wildcard() => _testMarkedContent('''
void f() {
  var /*[0*/^_/*0]*/ = '';
}
''');

  Future<void> test_pattern_object_destructure() => _testMarkedContent('''
void f() {
  final MapEntry(:/*[0*/key/*0]*/) = const MapEntry<String, int>('a', 1);
  
  if (const MapEntry('a', 1) case MapEntry(:final /*[1*/ke^y/*1]*/)) {
    /*[2*/key/*2]*/;
  }
}
''');

  Future<void> test_prefixed() => _testMarkedContent('''
import '' as p;

class /*[0*/A^/*0]*/ {}

p./*[1*/A/*1]*/? a;
''');

  Future<void> test_shadow_inner() => _testMarkedContent('''
void f() {
  var foo = 1;
  func() {
    var /*[0*/fo^o/*0]*/ = 2;
    print(/*[1*/foo/*1]*/);
  }
}
''');

  Future<void> test_shadow_outer() => _testMarkedContent('''
void f() {
  var /*[0*/foo/*0]*/ = 1;
  func() {
    var foo = 2;
    print(foo);
  }
  print(/*[1*/fo^o/*1]*/);
}
''');

  Future<void> test_topLevelVariable() => _testMarkedContent('''
String /*[0*/foo/*0]*/ = 'bar';
void f() {
  print(/*[1*/foo/*1]*/);
  /*[2*/fo^o/*2]*/ = '';
}
''');

  Future<void> test_topLevelVariable_underscore() => _testMarkedContent('''
String /*[0*/_/*0]*/ = 'bar';
void f() {
  print(/*[1*/_/*1]*/);
  /*[2*/^_/*2]*/ = '';
}
''');

  Future<void> test_typeAlias_class_declaration() => _testMarkedContent('''
class MyClass {}
mixin MyMixin {}
class /*[0*/MyAli^as/*0]*/ = MyClass with MyMixin;
/*[1*/MyAlias/*1]*/? a;
''');

  Future<void> test_typeAlias_class_reference() => _testMarkedContent('''
class MyClass {}
mixin MyMixin {}
class /*[0*/MyAlias/*0]*/ = MyClass with MyMixin;
/*[1*/MyAl^ias/*1]*/? a;
''');

  Future<void> test_typeAlias_function_declaration() => _testMarkedContent('''
typedef /*[0*/myFu^nc/*0]*/();
/*[1*/myFunc/*1]*/? f;
''');

  Future<void> test_typeAlias_function_reference() => _testMarkedContent('''
typedef /*[0*/myFunc/*0]*/();
/*[1*/myFun^c/*1]*/? f;
''');

  Future<void> test_typeAlias_generic_declaration() => _testMarkedContent('''
typedef /*[0*/TD^/*0]*/ = String;

/*[1*/TD/*1]*/? a;
''');

  Future<void> test_typeAlias_generic_reference() => _testMarkedContent('''
typedef /*[0*/TD/*0]*/ = String;

/*[1*/TD^/*1]*/? a;
''');

  /// Tests highlights in a Dart file using the provided content.
  ///
  /// The content should be marked up using the [TestCode] format.
  ///
  /// If the content does not include any ranges then the response is expected
  /// to be `null`.
  Future<void> _testMarkedContent(String content) async {
    var code = TestCode.parse(content);

    await initialize();
    await openFile(mainFileUri, code.code);

    var pos = code.position.position;
    var highlights = await getDocumentHighlights(mainFileUri, pos);

    if (code.ranges.isEmpty) {
      // When there are no ranges, we expect an empty result (not null) because
      // a null may cause an editor to fall back to a text search (VS Code
      // does) which can lead to confusing results.
      expect(highlights, isEmpty);
    } else {
      var highlightRanges = highlights!.map((h) => h.range).toList();
      expect(highlightRanges, equals(code.ranges.map((r) => r.range)));
    }
  }
}
