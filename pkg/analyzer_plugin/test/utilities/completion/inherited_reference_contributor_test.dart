// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/package_config_file_builder.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/inherited_reference_contributor.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'completion_contributor_util.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InheritedReferenceContributorTest);
  });
}

@reflectiveTest
class InheritedReferenceContributorTest extends DartCompletionContributorTest {
  @override
  bool get isNullExpectedReturnTypeConsideredDynamic => false;

  @override
  CompletionContributor createContributor() {
    return InheritedReferenceContributor();
  }

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      config: PackageConfigFileBuilder(),
      meta: true,
    );
  }

  /// Sanity check. Permutations tested in local_ref_contributor.
  Future<void> test_ArgDefaults_inherited_method_with_required_named() async {
    resolveSource('/home/test/lib/b.dart', '''
import 'package:meta/meta.dart';

lib libB;
class A {
   bool foo(int bar, {bool boo, @required int baz}) => false;
}''');
    addTestSource('''
import 'b.dart';
class B extends A {
  b() => f^
}
''');
    await computeSuggestions();

    assertSuggestMethod('foo', 'A', 'bool',
        defaultArgListString: 'bar, baz: baz');
  }

  Future<void> test_AwaitExpression_inherited() async {
    // SimpleIdentifier  AwaitExpression  ExpressionStatement
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A {
  Future y() async {return 0;}
}''');
    addTestSource('''
import 'b.dart';
class B extends A {
  Future a() async {return 0;}
  foo() async {await ^}
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('a');
    assertNotSuggested('foo');
    assertNotSuggested('B');
    assertNotSuggested('A');
    assertNotSuggested('Object');
    assertSuggestMethod('y', 'A', 'Future<dynamic>');
  }

  Future<void> test_Block_inherited_imported() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    resolveSource('/home/test/lib/b.dart', '''
      lib B;
      class F { var f1; f2() { } get f3 => 0; set f4(fx) { } var _pf; }
      class E extends F { var e1; e2() { } }
      class I { int i1; i2() { } }
      class M { var m1; int m2() { } }''');
    addTestSource('''
      import 'b.dart';
      class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('e1', null);
    assertSuggestField('f1', null);
    assertSuggestField('i1', 'int');
    assertSuggestField('m1', null);
    assertSuggestGetter('f3', null);
    assertSuggestSetter('f4');
    assertSuggestMethod('e2', 'E', null);
    assertSuggestMethod('f2', 'F', null);
    assertSuggestMethod('i2', 'I', null);
    assertSuggestMethod('m2', 'M', 'int');
    assertNotSuggested('==');
  }

  Future<void> test_Block_inherited_local() async {
    // Block  BlockFunctionBody  MethodDeclaration  ClassDeclaration
    addTestSource('''
class F { var f1; f2() { } get f3 => 0; set f4(fx) { } }
class E extends F { var e1; e2() { } }
class I { int i1; i2() { } }
class M { var m1; int m2() { } }
class A extends E implements I with M {a() {^}}''');
    await computeSuggestions();

    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertSuggestField('e1', null);
    assertSuggestField('f1', null);
    assertSuggestField('i1', 'int');
    assertSuggestField('m1', null);
    assertSuggestGetter('f3', null);
    assertSuggestSetter('f4');
    assertSuggestMethod('e2', 'E', null);
    assertSuggestMethod('f2', 'F', null);
    assertSuggestMethod('i2', 'I', null);
    assertSuggestMethod('m2', 'M', 'int');
  }

  Future<void> test_inherited() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import 'b.dart';
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
  foo() {^}
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('B');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('foo');
    assertNotSuggested('A');
    assertSuggestField('x', 'int');
    assertSuggestMethod('y', 'A1', 'int');
    assertSuggestField('x1', 'int');
    assertSuggestMethod('y1', 'A1', 'int');
    assertSuggestField('x2', 'int');
    assertSuggestMethod('y2', 'A2', 'int');
  }

  Future<void> test_method_in_class() async {
    addTestSource('''
class A {
  void m(x, int y) {}
  main() {^}
}
''');
    await computeSuggestions();
    assertNotSuggested('m');
  }

  Future<void> test_method_parameters_mixed_required_and_named() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m(x, {int y}) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_mixed_required_and_named_local() async {
    addTestSource('''
class A {
  void m(x, {int y}) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_mixed_required_and_positional() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m(x, [int y]) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void>
      test_method_parameters_mixed_required_and_positional_local() async {
    addTestSource('''
class A {
  void m(x, [int y]) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 1);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_named() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m({x, int y}) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_named_local() async {
    addTestSource('''
class A {
  void m({x, int y}) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, true);
  }

  Future<void> test_method_parameters_none() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m() {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, isEmpty);
    expect(suggestion.parameterTypes, isEmpty);
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_none_local() async {
    addTestSource('''
class A {
  void m() {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, isEmpty);
    expect(suggestion.parameterTypes, isEmpty);
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_positional() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m([x, int y]) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_positional_local() async {
    addTestSource('''
class A {
  void m([x, int y]) {}
}
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 0);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_method_parameters_required() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  void m(x, int y) {}
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestMethod('m', 'A', 'void');
    expect(suggestion.parameterNames, hasLength(2));
    expect(suggestion.parameterNames[0], 'x');
    expect(suggestion.parameterTypes[0], 'dynamic');
    expect(suggestion.parameterNames[1], 'y');
    expect(suggestion.parameterTypes[1], 'int');
    expect(suggestion.requiredParameterCount, 2);
    expect(suggestion.hasNamedParameters, false);
  }

  Future<void> test_mixin_ordering() async {
    resolveSource('/home/test/lib/a.dart', '''
class B {}
class M1 {
  void m() {}
}
class M2 {
  void m() {}
}
''');
    addTestSource('''
import 'a.dart';
class C extends B with M1, M2 {
  void f() {
    ^
  }
}
''');
    await computeSuggestions();
    assertSuggestMethod('m', 'M1', 'void');
  }

  Future<void> test_no_parameters_field() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  int x;
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestField('x', 'int');
    assertHasNoParameterInfo(suggestion);
  }

  Future<void> test_no_parameters_getter() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  int get x => null;
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestGetter('x', 'int');
    assertHasNoParameterInfo(suggestion);
  }

  Future<void> test_no_parameters_setter() async {
    resolveSource('/home/test/lib/a.dart', '''
class A {
  set x(int value) {};
}
''');
    addTestSource('''
import 'a.dart';
class B extends A {
  main() {^}
}
''');
    await computeSuggestions();
    var suggestion = assertSuggestSetter('x');
    assertHasNoParameterInfo(suggestion);
  }

  Future<void> test_outside_class() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import 'b.dart';
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
}
foo() {^}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('B');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('foo');
    assertNotSuggested('A');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('x1');
    assertNotSuggested('y1');
    assertNotSuggested('x2');
    assertNotSuggested('y2');
  }

  Future<void> test_static_field() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import 'b.dart';
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
  static foo = ^
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('B');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('foo');
    assertNotSuggested('A');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('x1');
    assertNotSuggested('y1');
    assertNotSuggested('x2');
    assertNotSuggested('y2');
  }

  Future<void> test_static_method() async {
    resolveSource('/home/test/lib/b.dart', '''
lib libB;
class A2 {
  int x;
  int y() {return 0;}
  int x2;
  int y2() {return 0;}
}''');
    addTestSource('''
import 'b.dart';
class A1 {
  int x;
  int y() {return 0;}
  int x1;
  int y1() {return 0;}
}
class B extends A1 with A2 {
  int a;
  int b() {return 0;}
  static foo() {^}
}
''');

    await computeSuggestions();
    expect(replacementOffset, completionOffset);
    expect(replacementLength, 0);
    assertNotSuggested('Object');
    assertNotSuggested('B');
    assertNotSuggested('a');
    assertNotSuggested('b');
    assertNotSuggested('foo');
    assertNotSuggested('A');
    assertNotSuggested('x');
    assertNotSuggested('y');
    assertNotSuggested('x1');
    assertNotSuggested('y1');
    assertNotSuggested('x2');
    assertNotSuggested('y2');
  }
}
