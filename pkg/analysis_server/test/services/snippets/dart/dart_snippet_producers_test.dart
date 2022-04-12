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
    defineReflectiveTests(DartDoWhileLoopSnippetProducerTest);
    defineReflectiveTests(DartForInLoopSnippetProducerTest);
    defineReflectiveTests(DartForLoopSnippetProducerTest);
    defineReflectiveTests(DartIfElseSnippetProducerTest);
    defineReflectiveTests(DartIfSnippetProducerTest);
    defineReflectiveTests(DartMainFunctionSnippetProducerTest);
    defineReflectiveTests(DartSwitchSnippetProducerTest);
    defineReflectiveTests(DartTryCatchSnippetProducerTest);
    defineReflectiveTests(DartWhileLoopSnippetProducerTest);
    defineReflectiveTests(DartClassSnippetProducerTest);
    defineReflectiveTests(DartTestBlockSnippetProducerTest);
    defineReflectiveTests(DartTestGroupBlockSnippetProducerTest);
  });
}

@reflectiveTest
class DartClassSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartClassSnippetProducer.newInstance;

  @override
  String get label => DartClassSnippetProducer.label;

  @override
  String get prefix => DartClassSnippetProducer.prefix;

  Future<void> test_class() async {
    var code = r'''
class A {}
  
^

class B {}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
class A {}
  
class ClassName {
  
}

class B {}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 34);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 20},
        ],
        'length': 9,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class DartDoWhileLoopSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartDoWhileLoopSnippetProducer.newInstance;

  @override
  String get label => DartDoWhileLoopSnippetProducer.label;

  @override
  String get prefix => DartDoWhileLoopSnippetProducer.prefix;

  Future<void> test_do() async {
    var code = r'''
void f() {
  do^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  do {
    
  } while (condition);
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 22);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 34},
        ],
        'length': 9,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class DartForInLoopSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartForInLoopSnippetProducer.newInstance;

  @override
  String get label => DartForInLoopSnippetProducer.label;

  @override
  String get prefix => DartForInLoopSnippetProducer.prefix;

  Future<void> test_for() async {
    var code = r'''
void f() {
  forin^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  for (var element in collection) {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 51);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 22},
        ],
        'length': 7,
        'suggestions': []
      },
      {
        'positions': [
          {'file': testFile, 'offset': 33},
        ],
        'length': 10,
        'suggestions': []
      }
    ]);
  }
}

@reflectiveTest
class DartForLoopSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartForLoopSnippetProducer.newInstance;

  @override
  String get label => DartForLoopSnippetProducer.label;

  @override
  String get prefix => DartForLoopSnippetProducer.prefix;

  Future<void> test_for() async {
    var code = r'''
void f() {
  for^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  for (var i = 0; i < count; i++) {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 51);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 33},
        ],
        'length': 5,
        'suggestions': []
      }
    ]);
  }
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  if (condition) {
    
  } else {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 34);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 17},
        ],
        'length': 9,
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  if (true) {
    if (condition) {
      
    } else {
      
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 52);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 33},
        ],
        'length': 9,
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  if (condition) {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 34);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 17},
        ],
        'length': 9,
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  if (true) {
    if (condition) {
      
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 52);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 33},
        ],
        'length': 9,
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  switch (expression) {
    case value:
      
      break;
    default:
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 57);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      // expression
      {
        'positions': [
          {'file': testFile, 'offset': 21},
        ],
        'length': 10,
        'suggestions': []
      },
      // value
      {
        'positions': [
          {'file': testFile, 'offset': 44},
        ],
        'length': 5,
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  if (true) {
    switch (expression) {
      case value:
        
        break;
      default:
    }
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 77);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      // expression
      {
        'positions': [
          {'file': testFile, 'offset': 37},
        ],
        'length': 10,
        'suggestions': []
      },
      // value
      {
        'positions': [
          {'file': testFile, 'offset': 62},
        ],
        'length': 5,
        'suggestions': []
      },
    ]);
  }
}

@reflectiveTest
class DartTestBlockSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartTestBlockSnippetProducer.newInstance;

  @override
  String get label => DartTestBlockSnippetProducer.label;

  @override
  String get prefix => DartTestBlockSnippetProducer.prefix;

  Future<void> test_inTestFile() async {
    testFile = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
void f() {
  test^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  test('test name', () {
    
  });
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 40);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 19},
        ],
        'length': 9,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_notTestFile() async {
    var code = r'''
void f() {
  test^
}''';
    await expectNotValidSnippet(code);
  }
}

@reflectiveTest
class DartTestGroupBlockSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartTestGroupBlockSnippetProducer.newInstance;

  @override
  String get label => DartTestGroupBlockSnippetProducer.label;

  @override
  String get prefix => DartTestGroupBlockSnippetProducer.prefix;

  Future<void> test_inTestFile() async {
    testFile = convertPath('$testPackageLibPath/test/foo_test.dart');
    var code = r'''
void f() {
  group^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  group('group name', () {
    
  });
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 42);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 20},
        ],
        'length': 10,
        'suggestions': []
      }
    ]);
  }

  Future<void> test_notTestFile() async {
    var code = r'''
void f() {
  group^
}''';
    await expectNotValidSnippet(code);
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
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
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
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

@reflectiveTest
class DartWhileLoopSnippetProducerTest extends DartSnippetProducerTest {
  @override
  final generator = DartWhileLoopSnippetProducer.newInstance;

  @override
  String get label => DartWhileLoopSnippetProducer.label;

  @override
  String get prefix => DartWhileLoopSnippetProducer.prefix;

  Future<void> test_while() async {
    var code = r'''
void f() {
  while^
}''';
    final snippet = await expectValidSnippet(code);
    expect(snippet.prefix, prefix);
    expect(snippet.label, label);
    expect(snippet.change.edits, hasLength(1));
    code = withoutMarkers(code);
    for (var edit in snippet.change.edits) {
      code = SourceEdit.applySequence(code, edit.edits);
    }
    expect(code, '''
void f() {
  while (condition) {
    
  }
}''');
    expect(snippet.change.selection!.file, testFile);
    expect(snippet.change.selection!.offset, 37);
    expect(snippet.change.linkedEditGroups.map((group) => group.toJson()), [
      {
        'positions': [
          {'file': testFile, 'offset': 20},
        ],
        'length': 9,
        'suggestions': []
      }
    ]);
  }
}
