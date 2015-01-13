// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.completion.invocation;


import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/completion/dart_completion_manager.dart';
import 'package:analysis_server/src/services/completion/invocation_computer.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'completion_test_util.dart';

main() {
  groupSep = ' | ';
  runReflectiveTests(InvocationComputerTest);
}

@ReflectiveTestCase()
class InvocationComputerTest extends AbstractSelectorSuggestionTest {

  @override
  CompletionSuggestion assertSuggestInvocationField(String name, String type,
      {int relevance: COMPLETION_RELEVANCE_DEFAULT, bool isDeprecated: false}) {
    return assertSuggestField(
        name,
        type,
        relevance: relevance,
        isDeprecated: isDeprecated);
  }

  @override
  void setUpComputer() {
    computer = new InvocationComputer();
  }

  test_method_parameters_mixed_required_and_named() {
    addTestSource('''
class C {
  void m(x, {int y}) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_method_parameters_mixed_required_and_positional() {
    addTestSource('''
class C {
  void m(x, [int y]) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 1);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_named() {
    addTestSource('''
class C {
  void m({x, int y}) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, true);
    });
  }

  test_method_parameters_none() {
    addTestSource('''
class C {
  void m() {}
}
void main() {new C().^}''');
    computeFast();
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, isEmpty);
      expect(suggestion.parameterTypes, isEmpty);
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_positional() {
    addTestSource('''
class C {
  void m([x, int y]) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 0);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_method_parameters_required() {
    addTestSource('''
class C {
  void m(x, int y) {}
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestMethod('m', 'C', 'void');
      expect(suggestion.parameterNames, hasLength(2));
      expect(suggestion.parameterNames[0], 'x');
      expect(suggestion.parameterTypes[0], 'dynamic');
      expect(suggestion.parameterNames[1], 'y');
      expect(suggestion.parameterTypes[1], 'int');
      expect(suggestion.requiredParameterCount, 2);
      expect(suggestion.hasNamedParameters, false);
    });
  }

  test_no_parameters_field() {
    addTestSource('''
class C {
  int x;
}
void main() {new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestField('x', 'int');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_no_parameters_getter() {
    addTestSource('''
class C {
  int get x => null;
}
void main() {int y = new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestGetter('x', 'int');
      assertHasNoParameterInfo(suggestion);
    });
  }

  test_no_parameters_setter() {
    addTestSource('''
class C {
  set x(int value) {};
}
void main() {int y = new C().^}''');
    return computeFull((bool result) {
      CompletionSuggestion suggestion = assertSuggestSetter('x');
      assertHasNoParameterInfo(suggestion);
    });
  }
}
