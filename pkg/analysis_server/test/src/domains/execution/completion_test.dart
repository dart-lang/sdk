// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/domains/execution/completion.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RuntimeCompletionComputerTest);
  });
}

@reflectiveTest
class RuntimeCompletionComputerTest extends AbstractContextTest {
  String contextFile;
  int contextOffset;

  RuntimeCompletionResult result;

  void addContextFile(String content) {
    contextFile = convertPath('/test/lib/context.dart');
    addSource(contextFile, content);

    contextOffset = content.indexOf('// context line');
    expect(contextOffset, isNonNegative,
        reason: "Not found '// context line'.");
  }

  void assertNotSuggested(String completion) {
    CompletionSuggestion suggestion = getSuggest(completion);
    if (suggestion != null) {
      failedCompletion('unexpected $completion');
    }
  }

  void assertSuggested(String completion, {String returnType}) {
    CompletionSuggestion suggestion = getSuggest(completion);
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
    int codeOffset = code.indexOf('^');
    expect(codeOffset, isNonNegative);
    code = code.replaceAll('^', '');

    var computer = new RuntimeCompletionComputer(
        resourceProvider,
        fileContentOverlay,
        driver,
        code,
        codeOffset,
        contextFile,
        contextOffset,
        variables,
        expressions);
    result = await computer.compute();
  }

  void failedCompletion(String message) {
    var sb = new StringBuffer(message);
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

  test_locals_block() async {
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

  test_locals_block_codeWithClosure() async {
    addContextFile(r'''
main() {
  var items = <String>[];
  // context line
}
''');
    await computeCompletion('items.forEach((e) => e.^)');
    assertSuggested('toUpperCase');
  }

  test_locals_block_nested() async {
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

  test_locals_for() async {
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

  test_locals_forEach() async {
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

  test_parameters_constructor() async {
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

  test_parameters_function() async {
    addContextFile(r'''
void main(int a, double b) {
  // context line
}
''');
    await computeCompletion('^');
    assertSuggested('a', returnType: 'int');
    assertSuggested('b', returnType: 'double');
  }

  test_parameters_function_locals() async {
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

  test_parameters_function_nested() async {
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

  test_parameters_functionExpression() async {
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

  test_parameters_method() async {
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

  test_parameters_method_locals() async {
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
}
