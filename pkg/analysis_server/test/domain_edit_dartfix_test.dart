// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/edit/edit_dartfix.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:linter/src/rules.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EditDartfixDomainHandlerTest);
  });
}

@reflectiveTest
class EditDartfixDomainHandlerTest extends AbstractAnalysisTest {
  int requestId = 30;
  String libPath;

  String get nextRequestId => (++requestId).toString();

  void expectEdits(List<SourceFileEdit> fileEdits, String expectedSource) {
    expect(fileEdits, hasLength(1));
    expect(fileEdits[0].file, testFile);
    List<SourceEdit> edits = fileEdits[0].edits;
    String source = testCode;
    for (SourceEdit edit in edits) {
      source = edit.apply(source);
    }
    expect(source, expectedSource);
  }

  void expectSuggestion(DartFixSuggestion suggestion, String partialText,
      int offset, int length) {
    expect(suggestion.description, contains(partialText));
    expect(suggestion.location.offset, offset);
    expect(suggestion.location.length, length);
  }

  Future<EditDartfixResult> performFix({List<String> includedFixes}) async {
    final id = nextRequestId;
    final params = new EditDartfixParams([projectPath]);
    params.includedFixes = includedFixes;
    final request = new Request(id, 'edit.dartfix', params.toJson());

    final response = await new EditDartFix(server, request).compute();
    expect(response.id, id);

    return EditDartfixResult.fromResponse(response);
  }

  @override
  void setUp() {
    super.setUp();
    registerLintRules();
    libPath = resourceProvider.convertPath('/project/lib');
    testFile = resourceProvider.convertPath('/project/lib/fileToBeFixed.dart');
  }

  test_dartfix_convertClassToMixin() async {
    createProject();
    addTestFile('''
class A {}
class B extends A {}
class C with B {}
    ''');
    EditDartfixResult result = await performFix();
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'mixin', 17, 1);
    expectEdits(result.edits, '''
class A {}
mixin B implements A {}
class C with B {}
    ''');
  }

  test_dartfix_convertToIntLiteral() async {
    createProject();
    addTestFile('''
const double myDouble = 42.0;
    ''');
    EditDartfixResult result = await performFix();
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 24, 4);
    expectEdits(result.edits, '''
const double myDouble = 42;
    ''');
  }

  test_dartfix_moveTypeArgumentToClass() async {
    createProject();
    addTestFile('''
class A<T> { A.from(Object obj) { } }
main() {
  print(new A.from<String>([]));
}
    ''');
    EditDartfixResult result = await performFix();
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'type arguments', 65, 8);
    expectEdits(result.edits, '''
class A<T> { A.from(Object obj) { } }
main() {
  print(new A<String>.from([]));
}
    ''');
  }

  test_dartfix_non_nullable() async {
    // Add analysis options to enable non-nullable analysis
    newFile('/project/analysis_options.yaml', content: '''
analyzer:
  enable-experiment:
    - non-nullable
''');

    createProject();
    addTestFile('''
main() {
  functionWithNullableParam(new List<String>(1));
  functionWithNullableParam(null);
}

class C1 {}
class C2 {}
class C extends C1 with M1 implements C2 {}

mixin M1 {}
mixin M on M1 implements C1 {}

Object obj;

void functionWithNullableParam(String object) {
  if (object == null) {
    print('object is null');
  } else {
    print('object is not-null');
  }
  String str = null;
  List<Object> list = null;
  list = <Object>[];
  list.add(str);
  list.add(obj);
}
''');
    EditDartfixResult result = await performFix(includedFixes: [nonNullable]);
    expect(result.suggestions, hasLength(1));
    expect(result.hasErrors, isFalse);
    expectSuggestion(result.suggestions[0], 'non-nullable', 46, 6);
    expectEdits(result.edits, '''
main() {
  functionWithNullableParam(new List<String?>(1));
  functionWithNullableParam(null);
}

class C1 {}
class C2 {}
class C extends C1 with M1 implements C2 {}

mixin M1 {}
mixin M on M1 implements C1 {}

Object? obj;

void functionWithNullableParam(String? object) {
  if (object == null) {
    print('object is null');
  } else {
    print('object is not-null');
  }
  String? str = null;
  List<Object?>? list = null;
  list = <Object?>[];
  list.add(str);
  list.add(obj);
}
''');
  }

  test_dartfix_excludedSource() async {
    // Add analysis options to exclude the lib directory then reanalyze
    newFile('/project/analysis_options.yaml', content: '''
analyzer:
  exclude:
    - lib/**
''');

    createProject();
    addTestFile('''
const double myDouble = 42.0;
    ''');

    // Assert no suggestions now that source has been excluded
    final result = await performFix();
    expect(result.suggestions, hasLength(0));
    expect(result.edits, hasLength(0));
  }

  test_dartfix_partFile() async {
    createProject();
    newFile('/project/lib/lib.dart', content: '''
library lib2;
part 'fileToBeFixed.dart';
    ''');
    addTestFile('''
part of lib2;
const double myDouble = 42.0;
    ''');

    // Assert dartfix suggestions
    EditDartfixResult result = await performFix();
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 38, 4);
    expectEdits(result.edits, '''
part of lib2;
const double myDouble = 42;
    ''');
  }

  test_dartfix_partFile_loose() async {
    createProject();
    addTestFile('''
part of lib2;
const double myDouble = 42.0;
    ''');

    // Assert dartfix suggestions
    EditDartfixResult result = await performFix();
    expect(result.suggestions, hasLength(1));
    expectSuggestion(result.suggestions[0], 'int literal', 38, 4);
    expectEdits(result.edits, '''
part of lib2;
const double myDouble = 42;
    ''');
  }
}
