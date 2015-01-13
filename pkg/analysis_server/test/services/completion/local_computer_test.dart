// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.dart.local;

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/local_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(LocalComputerTest);
}

@ReflectiveTestCase()
class LocalComputerTest extends AbstractSelectorSuggestionTest {

  @override
  CompletionSuggestion assertSuggestLocalField(String name, String type,
      [int relevance = COMPLETION_RELEVANCE_DEFAULT]) {
    return assertSuggestField(name, type, relevance: relevance);
  }

  @override
  void setUpComputer() {
    computer = new LocalComputer();
  }

  test_break_ignores_outer_functions_using_closure() {
    addTestSource('''
void main() {
  foo: while (true) {
    var f = () {
      bar: while (true) { break ^ }
    };
  }
}
''');
    expect(computeFast(), isTrue);
    // Labels in outer functions are never accessible.
    assertSuggestLabel('bar');
    assertNotSuggested('foo');
  }

  test_break_ignores_outer_functions_using_local_function() {
    addTestSource('''
void main() {
  foo: while (true) {
    void f() {
      bar: while (true) { break ^ }
    };
  }
}
''');
    expect(computeFast(), isTrue);
    // Labels in outer functions are never accessible.
    assertSuggestLabel('bar');
    assertNotSuggested('foo');
  }

  test_break_ignores_toplevel_variables() {
    addTestSource('''
int x;
void main() {
  while (true) {
    break ^
  }
}
''');
    expect(computeFast(), isTrue);
    assertNotSuggested('x');
  }

  test_break_ignores_unrelated_statements() {
    addTestSource('''
void main() {
  foo: while (true) {}
  while (true) { break ^ }
  bar: while (true) {}
}
''');
    expect(computeFast(), isTrue);
    // The scope of the label defined by a labeled statement is just the
    // statement itself, so neither "foo" nor "bar" are in scope at the caret
    // position.
    assertNotSuggested('foo');
    assertNotSuggested('bar');
  }

  test_break_to_enclosing_loop() {
    addTestSource('''
void main() {
  foo: while (true) {
    bar: while (true) {
      break ^
    }
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
    assertSuggestLabel('bar');
  }

  test_continue_from_loop_to_switch() {
    addTestSource('''
void main() {
  switch (x) {
    foo: case 1:
      break;
    bar: case 2:
      while (true) {
        continue ^;
      }
      break;
    baz: case 3:
      break;
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
    assertSuggestLabel('bar');
    assertSuggestLabel('baz');
  }

  test_continue_from_switch_to_loop() {
    addTestSource('''
void main() {
  foo: while (true) {
    switch (x) {
      case 1:
        continue ^;
    }
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
  }

  test_continue_ignores_outer_functions_using_closure_with_loop() {
    addTestSource('''
void main() {
  foo: while (true) {
    var f = () {
      bar: while (true) { continue ^ }
    };
  }
}
''');
    expect(computeFast(), isTrue);
    // Labels in outer functions are never accessible.
    assertSuggestLabel('bar');
    assertNotSuggested('foo');
  }

  test_continue_ignores_outer_functions_using_closure_with_switch() {
    addTestSource('''
void main() {
  switch (x) {
    foo: case 1:
      var f = () {
        bar: while (true) { continue ^ }
      };
  }
}
''');
    expect(computeFast(), isTrue);
    // Labels in outer functions are never accessible.
    assertSuggestLabel('bar');
    assertNotSuggested('foo');
  }

  test_continue_ignores_outer_functions_using_local_function_with_loop() {
    addTestSource('''
void main() {
  foo: while (true) {
    void f() {
      bar: while (true) { continue ^ }
    };
  }
}
''');
    expect(computeFast(), isTrue);
    // Labels in outer functions are never accessible.
    assertSuggestLabel('bar');
    assertNotSuggested('foo');
  }

  test_continue_ignores_outer_functions_using_local_function_with_switch() {
    addTestSource('''
void main() {
  switch (x) {
    foo: case 1:
      void f() {
        bar: while (true) { continue ^ }
      };
  }
}
''');
    expect(computeFast(), isTrue);
    // Labels in outer functions are never accessible.
    assertSuggestLabel('bar');
    assertNotSuggested('foo');
  }

  test_continue_ignores_unrelated_statements() {
    addTestSource('''
void main() {
  foo: while (true) {}
  while (true) { continue ^ }
  bar: while (true) {}
}
''');
    expect(computeFast(), isTrue);
    // The scope of the label defined by a labeled statement is just the
    // statement itself, so neither "foo" nor "bar" are in scope at the caret
    // position.
    assertNotSuggested('foo');
    assertNotSuggested('bar');
  }

  test_continue_to_earlier_case() {
    addTestSource('''
void main() {
  switch (x) {
    foo: case 1:
      break;
    case 2:
      continue ^;
    case 3:
      break;
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
  }

  test_continue_to_enclosing_loop() {
    addTestSource('''
void main() {
  foo: while (true) {
    bar: while (true) {
      continue ^
    }
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
    assertSuggestLabel('bar');
  }

  test_continue_to_enclosing_switch() {
    addTestSource('''
void main() {
  switch (x) {
    foo: case 1:
      break;
    bar: case 2:
      switch (y) {
        case 1:
          continue ^;
      }
      break;
    baz: case 3:
      break;
  }
}
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
    assertSuggestLabel('bar');
    assertSuggestLabel('baz');
  }

  test_continue_to_later_case() {
    addTestSource('''
void main() {
  switch (x) {
    case 1:
      break;
    case 2:
      continue ^;
    foo: case 3:
      break;
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
  }

  test_continue_to_same_case() {
    addTestSource('''
void main() {
  switch (x) {
    case 1:
      break;
    foo: case 2:
      continue ^;
    case 3:
      break;
''');
    expect(computeFast(), isTrue);
    assertSuggestLabel('foo');
  }
}
