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

  void assertSuggest(String completion) {
    expect(result.suggestions, isNotNull);
    for (var suggestion in result.suggestions) {
      if (suggestion.completion == completion) {
        return;
      }
    }
    failedCompletion('expected $completion');
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
    assertSuggest('foo');

    // There was an issue with cleaning up
    // Check that the second time it works too.
    await computeCompletion('a.^');
    assertSuggest('foo');
  }

  test_locals_block_codeWithClosure() async {
    addContextFile(r'''
main() {
  var items = <String>[];
  // context line
}
''');
    await computeCompletion('items.forEach((e) => e.^)');
    assertSuggest('toUpperCase');
  }
}
