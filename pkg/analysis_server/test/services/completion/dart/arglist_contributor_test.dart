// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/arglist_contributor.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/suggestion_builder.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgListContributorTest);
  });
}

mixin ArgListContributorMixin on DartCompletionContributorTest {
  void assertNoOtherSuggestions(Iterable<CompletionSuggestion> expected) {
    for (var suggestion in suggestions) {
      if (!expected.contains(suggestion)) {
        failedCompletion('did not expect completion: '
            '${suggestion.completion}\n  $suggestion');
      }
    }
  }

  /// Assert that there is a suggestion with the given parameter [name] that has
  /// the given [completion], [selectionOffset] and [selectionLength].
  void assertSuggestArgumentAndCompletion(String name,
      {required String completion,
      required int selectionOffset,
      int selectionLength = 0}) {
    var suggestion = suggestions.firstWhere((s) => s.parameterName == name);
    expect(suggestion, isNotNull);
    expect(suggestion.completion, completion);
    expect(suggestion.selectionOffset, selectionOffset);
    expect(suggestion.selectionLength, selectionLength);
  }

  void assertSuggestArgumentList_params(
      List<String> expectedNames,
      List<String> expectedTypes,
      List<String>? actualNames,
      List<String>? actualTypes) {
    if (actualNames != null &&
        actualNames.length == expectedNames.length &&
        actualTypes != null &&
        actualTypes.length == expectedTypes.length) {
      var index = 0;
      while (index < expectedNames.length) {
        if (actualNames[index] != expectedNames[index] ||
            actualTypes[index] != expectedTypes[index]) {
          break;
        }
        ++index;
      }
      if (index == expectedNames.length) {
        return;
      }
    }
    var msg = StringBuffer();
    msg.writeln('Argument list not the same');
    msg.writeln('  Expected names: $expectedNames');
    msg.writeln('           found: $actualNames');
    msg.writeln('  Expected types: $expectedTypes');
    msg.writeln('           found: $actualTypes');
    fail(msg.toString());
  }

  /// Assert that the specified named argument suggestions with their types are
  /// the only suggestions.
  void assertSuggestArgumentsAndTypes(
      {required Map<String, String> namedArgumentsWithTypes,
      bool includeColon = true,
      bool includeComma = false}) {
    var expected = <CompletionSuggestion>[];
    namedArgumentsWithTypes.forEach((String name, String type) {
      var completion = includeColon ? '$name: ' : name;
      // Selection should be before any trailing commas.
      var selectionOffset = completion.length;
      if (includeComma) {
        completion = '$completion,';
      }
      expected.add(assertSuggest(completion,
          csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
          paramName: name,
          paramType: type,
          selectionOffset: selectionOffset));
    });
    assertNoOtherSuggestions(expected);
  }

  /// Assert that the specified suggestions are the only suggestions.
  void assertSuggestions(List<String> suggestions) {
    var expected = <CompletionSuggestion>[];
    for (var suggestion in suggestions) {
      // Selection offset should be before any trailing commas.
      var selectionOffset =
          suggestion.endsWith(',') ? suggestion.length - 1 : suggestion.length;
      expected.add(assertSuggest('$suggestion',
          csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
          selectionOffset: selectionOffset));
    }
    assertNoOtherSuggestions(expected);
  }

  @override
  DartCompletionContributor createContributor(
    DartCompletionRequest request,
    SuggestionBuilder builder,
  ) {
    return ArgListContributor(request, builder);
  }
}

@reflectiveTest
class ArgListContributorTest extends DartCompletionContributorTest
    with ArgListContributorMixin {
  Future<void> test_closure_namedArgument() async {
    addTestSource(r'''
void f({void Function(int a, String b) closure}) {}

void main() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ,',
      selectionOffset: 10,
    );

    assertSuggest(
      '''
(a, b) {
${' ' * 4}
${' ' * 2}},''',
      selectionOffset: 13,
    );
  }

  Future<void> test_closure_namedArgument_hasComma() async {
    addTestSource(r'''
void f({void Function(int a, String b) closure}) {}

void main() {
  f(
    closure: ^,
  );
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b) => ',
      selectionOffset: 10,
    );

    assertSuggest(
      '''
(a, b) {
${' ' * 6}
${' ' * 4}}''',
      selectionOffset: 15,
    );
  }

  Future<void> test_closure_namedArgument_parameters_optionalNamed() async {
    addTestSource(r'''
void f({void Function(int a, {int b, int c}) closure}) {}

void main() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, {b, c}) => ,',
      selectionOffset: 15,
    );
  }

  Future<void>
      test_closure_namedArgument_parameters_optionalPositional() async {
    addTestSource(r'''
void f({void Function(int a, [int b, int c]) closure]) {}

void main() {
  f(closure: ^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, [b, c]) => ,',
      selectionOffset: 15,
    );
  }

  /// todo (pq): implement positional functional parameters
  @failingTest
  Future<void> test_closure_positionalArgument() async {
    addTestSource(r'''
void f(void Function(int a, int b) closure) {}

void main() {
  f(^);
}
''');
    await computeSuggestions();

    assertSuggest(
      '(a, b, c) => ,',
      selectionOffset: 13,
    );
  }

  Future<void> test_fieldFormal_documentation() async {
    var content = '''
class A {
  /// aaa
  ///
  /// bbb
  /// ccc
  int fff;
  A({this.fff});
}
main() {
  new A(^);
}
''';
    addTestSource(content);
    await computeSuggestions();
    expect(suggestions, hasLength(1));

    var suggestion = suggestions[0];
    expect(suggestion.docSummary, 'aaa');
    expect(suggestion.docComplete, 'aaa\n\nbbb\nccc');

    var element = suggestion.element!;
    expect(element.kind, ElementKind.PARAMETER);
    expect(element.name, 'fff');
    expect(element.location!.offset, content.indexOf('fff})'));
  }

  Future<void> test_fieldFormal_noDocumentation() async {
    var content = '''
class A {
  int fff;
  A({this.fff});
}
main() {
  new A(^);
}
''';
    addTestSource(content);
    await computeSuggestions();
    expect(suggestions, hasLength(1));

    var suggestion = suggestions[0];
    expect(suggestion.docSummary, isNull);
    expect(suggestion.docComplete, isNull);

    var element = suggestion.element!;
    expect(element.kind, ElementKind.PARAMETER);
    expect(element.name, 'fff');
    expect(element.location!.offset, content.indexOf('fff})'));
  }

  Future<void> test_flutter_InstanceCreationExpression_0() async {
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/widgets.dart';

build() => new Row(
    ^
  );
''');

    await computeSuggestions();

    assertSuggest('children: [],',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null,
        selectionOffset: 11,
        defaultArgumentListTextRanges: null);
  }

  Future<void> test_flutter_InstanceCreationExpression_01() async {
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

  build() => new Scaffold(
        appBar: new AppBar(
          ^
        ),
  );
''');

    await computeSuggestions();

    assertSuggest('backgroundColor: ,',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null, // No default values.
        selectionOffset: 17);
  }

  Future<void> test_flutter_InstanceCreationExpression_1() async {
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

build() => new Row(
    key: null,
    ^
  );
''');

    await computeSuggestions();

    assertSuggest('children: [],',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null,
        selectionOffset: 11,
        defaultArgumentListTextRanges: null);
  }

  Future<void> test_flutter_InstanceCreationExpression_2() async {
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

build() => new Row(
    ^
    key: null,
  );
''');

    await computeSuggestions();

    assertSuggest('children: [],',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null,
        selectionOffset: 11,
        defaultArgumentListTextRanges: null);
  }

  Future<void>
      test_flutter_InstanceCreationExpression_children_dynamic() async {
    // Ensure we don't generate unneeded <dynamic> param if a future API doesn't
    // type it's children.
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

build() => new Container(
    child: new DynamicRow(^);
  );

class DynamicRow extends Widget {
  DynamicRow({List children: null});
}
''');

    await computeSuggestions();

    assertSuggest('children: [],',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null,
        selectionOffset: 11,
        defaultArgumentListTextRanges: null);
  }

  Future<void> test_flutter_InstanceCreationExpression_children_Map() async {
    // Ensure we don't generate Map params for a future API
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

build() => new Container(
    child: new MapRow(^);
  );

class MapRow extends Widget {
  MapRow({Map<Object, Object> children: null});
}
''');

    await computeSuggestions();

    assertSuggest('children: ,',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        selectionOffset: 10,
        defaultArgListString: null);
  }

  Future<void> test_flutter_InstanceCreationExpression_slivers() async {
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

build() => new CustomScrollView(
    ^
  );

class CustomScrollView extends Widget {
  CustomScrollView({List<Widget> slivers});
}
''');

    await computeSuggestions();

    assertSuggest('slivers: [],',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null,
        selectionOffset: 10,
        defaultArgumentListTextRanges: null);
  }

  Future<void> test_flutter_MethodExpression_children() async {
    // Ensure we don't generate params for a method call
    // TODO(brianwilkerson) This test has been changed so that it no longer has
    // anything to do with Flutter (by moving the declaration of `foo` out of
    // the 'material' library). Determine whether the test is still valid.
    writeTestPackageConfig(flutter: true);

    addTestSource('''
import 'package:flutter/material.dart';

main() {
  foo(^);
}

foo({String children}) {}
''');

    await computeSuggestions();

    assertSuggest('children: ',
        csKind: CompletionSuggestionKind.NAMED_ARGUMENT,
        defaultArgListString: null);
  }

  Future<void> test_named_01() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(^)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool', 'two': 'int'},
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_02() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(o^)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool', 'two': 'int'},
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_03() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(^o,)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool', 'two': 'int'},
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_04() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(^ two: 2)',
      check: () {
        assertSuggestArgumentsAndTypes(
            namedArgumentsWithTypes: {'one': 'bool'}, includeComma: true);
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ,', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_05() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(o^ two: 2)',
      check: () {
        assertSuggestArgumentsAndTypes(
            namedArgumentsWithTypes: {'one': 'bool'}, includeComma: true);
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ,', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_06() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(^two: 2)',
      check: () {
        assertSuggestions(['one: ,']);
      },
    );
  }

  Future<void> test_named_07() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(^, two: 2)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool'},
          includeComma: false,
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_08() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(o^, two: 2)',
      check: () {
        assertSuggestArgumentsAndTypes(
            namedArgumentsWithTypes: {'one': 'bool'}, includeComma: false);
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_09() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(^ , two: 2)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool'},
        );
      },
    );
  }

  Future<void> test_named_10() async {
    await _tryParametersArguments(
      parameters: '(int one, {bool two, int three})',
      arguments: '(1, ^, three: 3)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'two': 'bool'},
        );
      },
    );
  }

  Future<void> test_named_11() async {
    await _tryParametersArguments(
      parameters: '(int one, {bool two, int three})',
      arguments: '(1, ^ three: 3)',
      check: () {
        assertSuggestions(['two: ,']);
      },
    );
  }

  Future<void> test_named_12() async {
    await _tryParametersArguments(
      parameters: '(int one, {bool two, int three})',
      arguments: '(1, ^three: 3)',
      check: () {
        assertSuggestions(['two: ,']);
      },
    );
  }

  @failingTest
  Future<void> test_named_13() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(two: 2^)',
      check: () {
        assertSuggestions([', one: ']);
      },
    );
  }

  @failingTest
  Future<void> test_named_14() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(two: 2 ^)',
      check: () {
        assertSuggestions([', one: ']);
      },
    );
  }

  Future<void> test_named_15() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(two: 2, ^)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool'},
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_16() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(two: 2, o^)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool'},
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_17() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(two: 2, o^,)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool'},
        );
        assertSuggestArgumentAndCompletion('one',
            completion: 'one: ', selectionOffset: 5);
      },
    );
  }

  Future<void> test_named_18() async {
    await _tryParametersArguments(
      parameters: '(int one, int two, int three, {int four, int five})',
      arguments: '(1, ^, 3)',
      check: () {
        assertSuggestions(['four: ', 'five: ']);
      },
    );
  }

  Future<void> test_named_19() async {
    await _tryParametersArguments(
      languageVersion: '2.15',
      parameters: '(int one, int two, int three, {int four, int five})',
      arguments: '(1, ^, 3)',
      check: () {
        assertNoSuggestions();
      },
    );
  }

  Future<void> test_named_20() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(o^: false)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'one': 'bool', 'two': 'int'},
          includeColon: false,
        );
      },
    );
  }

  Future<void> test_named_21() async {
    await _tryParametersArguments(
      parameters: '(bool one, {int two, double three})',
      arguments: '(false, ^t: 2)',
      check: () {
        assertSuggestions(['two: ,', 'three: ,']);
      },
    );
  }

  Future<void> test_named_22() async {
    await _tryParametersArguments(
      parameters: '(bool one, {int two, double three})',
      arguments: '(false, ^: 2)',
      check: () {
        assertSuggestArgumentsAndTypes(
          namedArgumentsWithTypes: {'two': 'int', 'three': 'double'},
        );
      },
    );
  }

  Future<void> test_named_23() async {
    await _tryParametersArguments(
      parameters: '({bool one, int two})',
      arguments: '(one: ^)',
      check: () {
        assertNoSuggestions();
      },
    );
  }

  Future<void> _tryParametersArguments({
    String? languageVersion,
    required String parameters,
    required String arguments,
    required void Function() check,
  }) async {
    var languageVersionLine = languageVersion != null
        ? '// @dart = $languageVersion'
        : '// no language version override';

    // Annotation, local class.
    addTestSource2('''
$languageVersionLine
class A {
  const A$parameters;
}
@A$arguments
void f() {}
''');
    await computeSuggestions();
    check();

    // Annotation, imported class.
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  const A$parameters;
}
''');
    addTestSource2('''
$languageVersionLine
import 'a.dart';
@A$arguments
void f() {}
''');
    await computeSuggestions();
    check();

    // Annotation, imported class, prefixed.
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  const A$parameters;
}
''');
    addTestSource2('''
$languageVersionLine
import 'a.dart' as p;
@p.A$arguments
void f() {}
''');
    await computeSuggestions();
    check();

    // Function expression invocation.
    addTestSource2('''
$languageVersionLine
import 'a.dart';
void f$parameters() {}
var v = (f)$arguments;
''');
    await computeSuggestions();
    check();

    // Instance creation, local class, generative.
    addTestSource2('''
$languageVersionLine
class A {
  A$parameters;
}
var v = A$arguments;
''');
    await computeSuggestions();
    check();

    // Instance creation, imported class, generative.
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  A$parameters;
}
''');
    addTestSource2('''
$languageVersionLine
import 'a.dart';
var v = A$arguments;
''');
    await computeSuggestions();
    check();

    // Instance creation, imported class, factory.
    newFile('$testPackageLibPath/a.dart', content: '''
class A {
  factory A$parameters => throw 0;
}
''');
    addTestSource2('''
$languageVersionLine
import 'a.dart';
var v = A$arguments;
''');
    await computeSuggestions();
    check();

    // Method invocation, local method.
    addTestSource2('''
$languageVersionLine
class A {
  void foo$parameters() {}
}
var v = A().foo$arguments;
''');
    await computeSuggestions();
    check();

    // Method invocation, local function.
    addTestSource2('''
$languageVersionLine
void f$parameters() {}
var v = f$arguments;
''');
    await computeSuggestions();
    check();

    // Method invocation, imported function.
    newFile('$testPackageLibPath/a.dart', content: '''
void f$parameters() {}
''');
    addTestSource2('''
$languageVersionLine
import 'a.dart';
var v = f$arguments;
''');
    await computeSuggestions();
    check();

    // Super constructor invocation.
    addTestSource2('''
$languageVersionLine
class A {
  A$parameters;
}
class B extends A {
  B() : super$arguments;
}
''');
    await computeSuggestions();
    check();

    // This constructor invocation.
    addTestSource2('''
$languageVersionLine
class A {
  A$parameters;
  A.named() : this$arguments;
}
''');
    await computeSuggestions();
    check();

    // Invalid: getter invocation.
    // Parameters not used. Check not used.
    addTestSource2('''
$languageVersionLine
int get foo => 0;
var v = foo$arguments;
''');
    await computeSuggestions();
    assertNoSuggestions();
  }
}
