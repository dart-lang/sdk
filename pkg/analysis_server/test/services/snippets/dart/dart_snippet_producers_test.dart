// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/snippets/dart/dart_snippet_producers.dart';
import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';
import 'test_support.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartIfElseSnippetProducerTest);
    defineReflectiveTests(DartIfSnippetProducerTest);
    defineReflectiveTests(DartMainFunctionSnippetProducerTest);
    defineReflectiveTests(DartSwitchSnippetProducerTest);
    defineReflectiveTests(DartTryCatchSnippetProducerTest);
  });
}

@reflectiveTest
class DartIfElseSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartIfElseSnippetProducer.newInstance;

  @override
  String get label => DartIfElseSnippetProducer.label;

  @override
  String get prefix => DartIfElseSnippetProducer.prefix;

  Future<void> test_ifElse() async {
    var code = r'''
void f() {
  if^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  if () {
    
  } else {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 25);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 17},
        ],
        'length': 0,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_ifElse_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    if^
  }
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  if (true) {
    if () {
      
    } else {
      
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 43);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 33},
        ],
        'length': 0,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class DartIfSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartIfSnippetProducer.newInstance;

  @override
  String get label => DartIfSnippetProducer.label;

  @override
  String get prefix => DartIfSnippetProducer.prefix;

  Future<void> test_if() async {
    var code = r'''
void f() {
  if^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  if () {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 25);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 17},
        ],
        'length': 0,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_if_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    if^
  }
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  if (true) {
    if () {
      
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 43);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 33},
        ],
        'length': 0,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class DartMainFunctionSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartMainFunctionSnippetProducer.newInstance;

  @override
  String get label => DartMainFunctionSnippetProducer.label;

  @override
  String get prefix => DartMainFunctionSnippetProducer.prefix;

  Future<void> test_noParams_testFolder() => testInFile(
        convertPath('$testPackageLibPath/test/foo_test.dart'),
        expectArgsParameter: false,
      );

  Future<void> test_params_binFolder() => testInFile(
        convertPath('$testPackageLibPath/bin/main.dart'),
        expectArgsParameter: true,
      );

  Future<void> test_params_projectRoot() => testInFile(
        convertPath('$testPackageRootPath/foo.dart'),
        expectArgsParameter: true,
      );

  Future<void> test_params_toolFolder() => testInFile(
        convertPath('$testPackageLibPath/tool/tool.dart'),
        expectArgsParameter: true,
      );

  Future<void> test_typedPrefix() => testInFile(
        testFile,
        code: '$prefix^',
        expectArgsParameter: true,
      );

  Future<void> testInFile(
    String file, {
    String code = '^',
    required bool expectArgsParameter,
  }) async {
    testFile = file;
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    final expectedParams = expectArgsParameter ? 'List<String> args' : '';
    expect(code, '''
void main($expectedParams) {
  
}''');
    expect(snippet.change.selection!.file, file);
    expect(snippet.change.selection!.offset, 16 + expectedParams.length);
    expect(snippet.change.linkedEditGroups, isEmpty);
  }
}

abstract class DartSnippetProducerTest extends AbstractSingleUnitTest {
  SnippetProducerGenerator get generator;
  String get label;
  String get prefix;

  /// Override the package root because it usually contains /test/ and some
  /// snippets behave differently for test files.
  @override
  String get testPackageRootPath => '$workspaceRootPath/my_package';

  @override
  bool get verifyNoTestUnitErrors => false;

  Future<void> expectNotValidSnippet(
    String code,
  ) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isFalse);
  }

  Future<Snippet> expectValidSnippet(String code) async {
    await resolveTestCode(withoutMarkers(code));
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: offsetFromMarker(code),
    );

    final producer = generator(request);
    expect(await producer.isValid(), isTrue);
    return producer.compute();
  }
}

@reflectiveTest
class DartSwitchSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartSwitchSnippetProducer.newInstance;

  @override
  String get label => DartSwitchSnippetProducer.label;

  @override
  String get prefix => DartSwitchSnippetProducer.prefix;

  Future<void> test_switch() async {
    var code = r'''
void f() {
  sw^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  switch () {
    case :
      
      break;
    default:
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 42);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      // expression
      {
        'positions': [
          {'file': testFile, 'offset': 21},
        ],
        'length': 0,
        'suggestions': []
      },
      // value
      {
        'positions': [
          {'file': testFile, 'offset': 34},
        ],
        'length': 0,
        'suggestions': []
      },
    ]);
  }

  Future<void> test_switch_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    sw^
  }
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  if (true) {
    switch () {
      case :
        
        break;
      default:
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 62);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      // expression
      {
        'positions': [
          {'file': testFile, 'offset': 37},
        ],
        'length': 0,
        'suggestions': []
      },
      // value
      {
        'positions': [
          {'file': testFile, 'offset': 52},
        ],
        'length': 0,
        'suggestions': []
      },
    ]);
  }
}

@reflectiveTest
class DartTryCatchSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartTryCatchSnippetProducer.newInstance;

  @override
  String get label => DartTryCatchSnippetProducer.label;

  @override
  String get prefix => DartTryCatchSnippetProducer.prefix;

  Future<void> test_tryCatch() async {
    var code = r'''
void f() {
  tr^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  try {
    
  } catch (e) {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 23);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 35},
        ],
        'length': 1,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_tryCatch_indentedInsideBlock() async {
    var code = r'''
void f() {
  if (true) {
    tr^
  }
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    snippet.change.edits
        .forEach((edit) => code = SourceEdit.applySequence(code, edit.edits));
    expect(code, '''
void f() {
  if (true) {
    try {
      
    } catch (e) {
      
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 41);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 55},
        ],
        'length': 1,
        'suggestions': []
      }
    ]);
  }
}
