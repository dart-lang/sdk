// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/domains/execution/completion.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RuntimeCompletionComputerTest);
  });
}

@reflectiveTest
class RuntimeCompletionComputerTest extends AbstractContextTest {
  OverlayResourceProvider overlayResourceProvider;
  String contextFile;
  int contextOffset;

  RuntimeCompletionResult result;

  void addContextFile(String content) {
    contextFile = convertPath('/home/test/lib/context.dart');
    addSource(contextFile, content);

    contextOffset = content.indexOf('// context line');
    expect(contextOffset, isNonNegative,
        reason: "Not found '// context line'.");
  }

  void assertNotSuggested(String completion) {
    var suggestion = getSuggest(completion);
    if (suggestion != null) {
      failedCompletion('unexpected $completion');
    }
  }

  void assertSuggested(String completion, {String returnType}) {
    var suggestion = getSuggest(completion);
    if (suggestion == null) {
      failedCompletion('expected $completion');
    }
    if (returnType != null) {
      expect(suggestion.returnType, returnType);
    }
  }

  Future<void> computeCompletion(
    String code, {
    List<RuntimeCompletionVariable> variables,
    List<RuntimeCompletionExpression> expressions,
  }) async {
    var codeOffset = code.indexOf('^');
    expect(codeOffset, isNonNegative);
    code = code.replaceAll('^', '');

    var computer = RuntimeCompletionComputer(
        overlayResourceProvider,
        driverFor(contextFile),
        code,
        codeOffset,
        contextFile,
        contextOffset,
        variables,
        expressions);
    result = await computer.compute();
  }

  void failedCompletion(String message) {
    var sb = StringBuffer(message);
    if (result.suggestions != null) {
      sb.write('\n  found');
      result.suggestions.toList()
        ..sort((a, b) => a.completion.compareTo(b.completion))
        ..forEach((suggestion) {
          sb.write('\n    ${suggestion.completion} -> $suggestion');
        });
    }
    fail(sb.toString());
  }

  CompletionSuggestion getSuggest(String completion) {
    expect(result.suggestions, isNotNull);
    for (var suggestion in result.suggestions) {
      if (suggestion.completion == completion) {
        return suggestion;
      }
    }
    return null;
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_class_fields() async {
    addContextFile(r'''
class A {
  int a;
}
class B extends A {
  double b, c;
  void foo() {
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
    assertSuggested('c', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_class_methods() async {
    addContextFile(r'''
class A {
  int a() => null;
}
class B extends A {
  double b() => null;
  void foo() {
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_inPart() async {
    addSource('/home/test/lib/a.dart', r'''
part 'b.dart';
part 'context.dart';

int a;
''');
    addSource('/home/test/lib/b.dart', r'''
part of 'a.dart';

double b;
''');
    addContextFile(r'''
part of 'a.dart';

String c;

void main() {
  // context line
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
    assertSuggested('c', returnType: 'String');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_locals_block() async {
    addContextFile(r'''
class A {
  int foo;
}

void contextFunction() {
  var a = new A();
  // context line
}
''');
    await computeCompletion('a.^');
    assertSuggested('foo');

    // There was an issue with cleaning up
    // Check that the second time it works too.
    await computeCompletion('a.^');
    assertSuggested('foo');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_locals_block_codeWithClosure() async {
    addContextFile(r'''
main() {
  var items = <String>[];
  // context line
}
''');
    await computeCompletion('items.forEach((e) => e.^)');
    assertSuggested('toUpperCase');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_locals_block_nested() async {
    addContextFile(r'''
void main() {
  var a = 0;
  var b = 0.0;
  {
    var a = '';
    // context line
  }
  var c = 0;
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'String');
    assertSuggested('b', returnType: 'double');

    // "c" is defined after the context offset, so is not visible.
    assertNotSuggested('c');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_locals_for() async {
    addContextFile(r'''
void main(List<int> intItems, List<double> doubleItems) {
  for (var a = 0, b = 0.0; a < 5; a++) {
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_locals_forEach() async {
    addContextFile(r'''
void main(List<int> intItems, List<double> doubleItems) {
  for (var a in intItems) {
    for (var b in doubleItems) {
      // context line
    }
  }
}sosol
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_constructor() async {
    addContextFile(r'''
class C {
  C(int a, double b) {
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_function() async {
    addContextFile(r'''
void main(int a, double b) {
  // context line
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_function_locals() async {
    addContextFile(r'''
void main(int a, int b) {
  String a;
  double c;
  // context line
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'String');
    assertSuggested('b', returnType: 'int');
    assertSuggested('c', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_function_nested() async {
    addContextFile(r'''
void foo(int a, double b) {
  void bar(String a, bool c) {
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'String');
    assertSuggested('b', returnType: 'double');
    assertSuggested('c', returnType: 'bool');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_functionExpression() async {
    addContextFile(r'''
void main(List<int> intItems, List<double> doubleItems) {
  intItems.forEach((a) {
    doubleItems.forEach((b) {
      // context line
    });
  });
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_method() async {
    addContextFile(r'''
class C {
  void main(int a, double b) {
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_parameters_method_locals() async {
    addContextFile(r'''
class C {
  void main(int a, int b) {
    String a;
    double c;
    // context line
  }
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'String');
    assertSuggested('b', returnType: 'int');
    assertSuggested('c', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_syntheticImportPrefix() async {
    newFile('/test/lib/a.dart', content: 'class A {}');
    newFile('/test/lib/b.dart', content: 'class B {}');
    addContextFile(r'''
import 'a.dart';
impoty 'b.dart';
main() {
  var a = new A();
  var b = new B();
  // context line
}
''');
    await computeCompletion('^');
    for (var suggestion in result.suggestions) {
      expect(suggestion.completion, isNot(startsWith('__prefix')));
    }
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_topLevelFunctions() async {
    addContextFile(r'''
int a() => null;
double b() => null;
void main() {
  // context line
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  @FailingTest(reason: 'No support for OverlayResourceProvider')
  Future<void> test_topLevelVariables() async {
    addContextFile(r'''
int a;
double b;

void main() {
  // context line
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }
}
