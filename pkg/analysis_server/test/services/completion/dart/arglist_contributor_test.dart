// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/provisional/completion/dart/completion_dart.dart';
import 'package:analysis_server/src/services/completion/dart/arglist_contributor.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_context.dart';
import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgListContributorTest);
    defineReflectiveTests(ArgListContributorWithNullSafetyTest);
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
      {String completion, int selectionOffset, int selectionLength = 0}) {
    var suggestion = suggestions.firstWhere((s) => s.parameterName == name);
    expect(suggestion, isNotNull);
    expect(suggestion.completion, completion);
    expect(suggestion.selectionOffset, selectionOffset);
    expect(suggestion.selectionLength, selectionLength);
  }

  void assertSuggestArgumentList_params(
      List<String> expectedNames,
      List<String> expectedTypes,
      List<String> actualNames,
      List<String> actualTypes) {
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
      {Map<String, String> namedArgumentsWithTypes,
      List<int> requiredParamIndices = const <int>[],
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
  DartCompletionContributor createContributor() {
    return ArgListContributor();
  }
}

@reflectiveTest
class ArgListContributorTest extends DartCompletionContributorTest
    with ArgListContributorMixin {
  Future<void> test_Annotation_imported_constructor_named_param() async {
    addSource('/home/test/lib/a.dart', '''
library libA; class A { const A({int one, String two: 'defaultValue'}); }''');
    addTestSource('import "a.dart"; @A(^) main() { }');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  Future<void> test_Annotation_importedConstructor_prefixed() async {
    addSource('/home/test/lib/a.dart', '''
class A {
  const A({int value});
}
''');
    addTestSource('''
import "a.dart" as p;
@p.A(^)
main() {}
''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'value': 'int'});
  }

  Future<void> test_Annotation_local_constructor_named_param() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^) main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  @failingTest
  Future<void> test_Annotation_local_constructor_named_param_10() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(two: '2' ^) main() { }''');
    await computeSuggestions();
    assertSuggestions([', one: ']);
  }

  Future<void> test_Annotation_local_constructor_named_param_11() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(two: '2', ^) main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_Annotation_local_constructor_named_param_2() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^ two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  Future<void> test_Annotation_local_constructor_named_param_3() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  Future<void> test_Annotation_local_constructor_named_param_4() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^, two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_Annotation_local_constructor_named_param_5() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(^ , two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_Annotation_local_constructor_named_param_6() async {
    addTestSource('''
class A { const A(int zero, {int one, String two: 'defaultValue'}); }
@A(0, ^, two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_Annotation_local_constructor_named_param_7() async {
    addTestSource('''
class A { const A(int zero, {int one, String two: 'defaultValue'}); }
@A(0, ^ two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  Future<void> test_Annotation_local_constructor_named_param_8() async {
    addTestSource('''
class A { const A(int zero, {int one, String two: 'defaultValue'}); }
@A(0, ^two: '2') main() { }''');
    await computeSuggestions();
    assertSuggestions(['one: ,']);
  }

  @failingTest
  Future<void> test_Annotation_local_constructor_named_param_9() async {
    addTestSource('''
class A { const A({int one, String two: 'defaultValue'}); }
@A(two: '2'^) main() { }''');
    await computeSuggestions();
    assertSuggestions([', one: ']);
  }

  Future<void> test_Annotation_local_constructor_named_param_negative() async {
    addTestSource('''
class A { const A(int one, int two, int three, {int four, String five:
  'defaultValue'}); }
@A(1, ^, 3) main() { }''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_closureFunction_namedParameter() async {
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

  Future<void>
      test_ArgumentList_closureFunction_namedParameter_hasComma() async {
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

  /// todo (pq): implement positional functional parameters
  @failingTest
  Future<void> test_ArgumentList_closureFunction_positionalParameter() async {
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

  Future<void> test_ArgumentList_closureMethod_namedParameter() async {
    addTestSource(r'''
class C {
  void f({void Function(int a, String b) closure}) {}

  void main() {
    f(closure: ^);
  }
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
${' ' * 6}
${' ' * 4}},''',
      selectionOffset: 15,
    );
  }

  Future<void> test_ArgumentList_closureParam() async {
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

  Future<void> test_ArgumentList_closureParameterOptionalNamed() async {
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

  Future<void> test_ArgumentList_closureParameterOptionalPositional() async {
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

  Future<void> test_ArgumentList_Flutter_InstanceCreationExpression_0() async {
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

  Future<void> test_ArgumentList_Flutter_InstanceCreationExpression_01() async {
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

  Future<void> test_ArgumentList_Flutter_InstanceCreationExpression_1() async {
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

  Future<void> test_ArgumentList_Flutter_InstanceCreationExpression_2() async {
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
      test_ArgumentList_Flutter_InstanceCreationExpression_children_dynamic() async {
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

  Future<void>
      test_ArgumentList_Flutter_InstanceCreationExpression_children_Map() async {
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

  Future<void>
      test_ArgumentList_Flutter_InstanceCreationExpression_slivers() async {
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

  Future<void> test_ArgumentList_Flutter_MethodExpression_children() async {
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

  Future<void> test_ArgumentList_getter() async {
    addTestSource('class A {int get foo => 7; main() {foo(^)}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_constructor_named_param() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement
    addSource('/home/test/lib/a.dart', 'library libA; class A{A({int one}); }');
    addTestSource('import "a.dart"; main() { new A(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_ArgumentList_imported_constructor_named_param2() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement
    addSource(
        '/home/test/lib/a.dart', 'library libA; class A{A.foo({int one}); }');
    addTestSource('import "a.dart"; main() { new A.foo(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void>
      test_ArgumentList_imported_constructor_named_typed_param() async {
    // ArgumentList  InstanceCreationExpression  VariableDeclaration
    addSource('/home/test/lib/a.dart',
        'library libA; class A { A({int i, String s, d}) {} }}');
    addTestSource('import "a.dart"; main() { var a = new A(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'i': 'int', 's': 'String', 'd': 'dynamic'});
  }

  Future<void> test_ArgumentList_imported_factory_named_param() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement
    addSource('/home/test/lib/a.dart',
        'library libA; class A{factory A({int one}) => throw 0;}');
    addTestSource('import "a.dart"; main() { new A(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_ArgumentList_imported_factory_named_param2() async {
    // ArgumentList  InstanceCreationExpression  ExpressionStatement
    addSource('/home/test/lib/a.dart',
        'library libA; abstract class A{factory A.foo({int one});}');
    addTestSource('import "a.dart"; main() { new A.foo(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
  }

  Future<void> test_ArgumentList_imported_factory_named_typed_param() async {
    // ArgumentList  InstanceCreationExpression  VariableDeclaration
    addSource('/home/test/lib/a.dart',
        'library libA; class A {factory A({int i, String s, d}) {} }}');
    addTestSource('import "a.dart"; main() { var a = new A(^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'i': 'int', 's': 'String', 'd': 'dynamic'});
  }

  Future<void> test_ArgumentList_imported_function_0() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect() { }
      void baz() { }''');
    addTestSource('''
      import 'a.dart'
      class B { }
      String bar() => true;
      void main() {expect(a^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_function_3a() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import 'a.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_function_3b() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import 'a.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', ^x)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_function_3c() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import 'a.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', x^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_function_3d() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
      library A;
      bool hasLength(int expected) { }
      expect(String arg1, int arg2, {bool arg3}) { }
      void baz() { }''');
    addTestSource('''
      import 'a.dart'
      class B { }
      String bar() => true;
      void main() {expect('hello', x ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_function_named_param() async {
    //
    addTestSource('main() { int.parse("16", ^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'radix': 'int',
      'onError': 'int Function(String)'
    });
  }

  Future<void> test_ArgumentList_imported_function_named_param1() async {
    //
    addTestSource('main() { int.parse("16", r^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'radix': 'int',
      'onError': 'int Function(String)'
    });
  }

  Future<void> test_ArgumentList_imported_function_named_param2() async {
    //
    addTestSource('main() { int.parse("16", radix: 7, ^);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'onError': 'int Function(String)'});
  }

  Future<void> test_ArgumentList_imported_function_named_param2a() async {
    //
    addTestSource('main() { int.parse("16", radix: ^);}');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_imported_function_named_param_label1() async {
    //
    addTestSource('main() { int.parse("16", r^: 16);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'radix': 'int',
      'onError': 'int Function(String)'
    }, includeColon: false);
  }

  Future<void> test_ArgumentList_imported_function_named_param_label2() async {
    //
    addTestSource('main() { int.parse("16", ^r: 16);}');
    await computeSuggestions();
    assertSuggestions(['radix: ,', 'onError: ,']);
  }

  Future<void> test_ArgumentList_imported_function_named_param_label3() async {
    //
    addTestSource('main() { int.parse("16", ^: 16);}');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'radix': 'int',
      'onError': 'int Function(String)'
    });
  }

  Future<void>
      test_ArgumentList_local_constructor_named_fieldFormal_documentation() async {
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

    var element = suggestion.element;
    expect(element, isNotNull);
    expect(element.kind, ElementKind.PARAMETER);
    expect(element.name, 'fff');
    expect(element.location.offset, content.indexOf('fff})'));
  }

  Future<void>
      test_ArgumentList_local_constructor_named_fieldFormal_noDocumentation() async {
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

    var element = suggestion.element;
    expect(element, isNotNull);
    expect(element.kind, ElementKind.PARAMETER);
    expect(element.name, 'fff');
    expect(element.location.offset, content.indexOf('fff})'));
  }

  Future<void> test_ArgumentList_local_constructor_named_param() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(^);}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_1() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(o^);}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_2() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(^o,);}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_3() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(two: 'foo', ^);}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_4() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(two: 'foo', o^);}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_5() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(two: 'foo', o^,);}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {'one': 'int'});
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_6() async {
    //
    addTestSource('''
class A { A.foo({int one, String two: 'defaultValue'}) { } }
main() { new A.foo(^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'});
  }

  Future<void>
      test_ArgumentList_local_constructor_named_param_prefixed_prepend() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(o^ two: 'foo');}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int'}, includeComma: true);
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ,', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_named_param_prepend() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(^ two: 'foo');}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int'}, includeComma: true);
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ,', selectionOffset: 5);
  }

  Future<void>
      test_ArgumentList_local_constructor_named_param_prepend_1() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(o^, two: 'foo');}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int'}, includeComma: false);
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void>
      test_ArgumentList_local_constructor_named_param_prepend_2() async {
    //
    addTestSource('''
class A { A({int one, String two: 'defaultValue'}) { } }
main() { new A(^, two: 'foo');}''');
    await computeSuggestions();

    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int'}, includeComma: false);
    assertSuggestArgumentAndCompletion('one',
        completion: 'one: ', selectionOffset: 5);
  }

  Future<void> test_ArgumentList_local_constructor_required_param_0() async {
    writeTestPackageConfig(meta: true);
    addTestSource('''
import 'package:meta/meta.dart';
class A { A({int one, @required String two: 'defaultValue'}) { } }
main() { new A(^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'one': 'int', 'two': 'String'},
        requiredParamIndices: [1]);
  }

  Future<void> test_ArgumentList_local_function_3a() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_local_function_3b() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', ^x)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_local_function_3c() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', x^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_local_function_3d() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addTestSource('''
      expect(arg1, int arg2, {bool arg3}) { }
      class B { }
      String bar() => true;
      void main() {expect('hello', x ^)}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_local_function_named_param() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", ^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'radix': 'int',
      'onError': 'int Function(String)'
    });
  }

  Future<void> test_ArgumentList_local_function_named_param1() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", r^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'radix': 'int',
      'onError': 'int Function(String)'
    });
  }

  Future<void> test_ArgumentList_local_function_named_param2() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", radix: 7, ^);}''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'onError': 'int Function(String)'});
  }

  Future<void> test_ArgumentList_local_function_named_param2a() async {
    //
    addTestSource('''
f(v,{int radix, int onError(String s)}){}
main() { f("16", radix: ^);}''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_ArgumentList_local_method_0() async {
    // ArgumentList  MethodInvocation  ExpressionStatement  Block
    addSource('/home/test/lib/a.dart', '''
      library A;
      bool hasLength(int expected) { }
      void baz() { }''');
    addTestSource('''
      import 'a.dart'
      class B {
        expect() { }
        void foo() {expect(^)}}
      String bar() => true;''');
    await computeSuggestions();
    assertNoSuggestions();
  }

  Future<void> test_superConstructorInvocation() async {
    addTestSource('''
class A {
  final bool field1;
  final int field2;
  A({this.field1, this.field2});
}
class B extends A {
  B() : super(^);
}
''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(
        namedArgumentsWithTypes: {'field1': 'bool', 'field2': 'int'});
  }
}

@reflectiveTest
class ArgListContributorWithNullSafetyTest extends DartCompletionContributorTest
    with WithNullSafetyMixin, ArgListContributorMixin {
  Future<void> test_ArgumentList_nnbd_function_named_param() async {
    addTestSource(r'''
f({int? nullable, int nonnullable}) {}
main() { f(^);}');
''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'nullable': 'int?',
      'nonnullable': 'int',
    });
  }

  Future<void> test_ArgumentList_nnbd_function_named_param_imported() async {
    addSource('/home/test/lib/a.dart', '''
f({int? nullable, int nonnullable}) {}''');
    createAnalysisOptionsFile(experiments: [EnableString.non_nullable]);
    addTestSource(r'''
import "a.dart";
main() { f(^);}');
''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'nullable': 'int?',
      'nonnullable': 'int',
    });
  }

  Future<void> test_ArgumentList_nnbd_function_named_param_legacy() async {
    addSource('/home/test/lib/a.dart', '''
// @dart = 2.8
f({int named}) {}''');
    addTestSource(r'''
import "a.dart";
main() { f(^);}');
''');
    await computeSuggestions();
    assertSuggestArgumentsAndTypes(namedArgumentsWithTypes: {
      'named': 'int*',
    });
  }
}
