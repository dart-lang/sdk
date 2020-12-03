// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' as analyzer;
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_target.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../support/abstract_context.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ArgumentListCompletionTargetTest);
    defineReflectiveTests(CompletionTargetTest);
  });
}

@reflectiveTest
class ArgumentListCompletionTargetTest extends _Base {
  Future<void> test_Annotation_named() async {
    await createTarget('''
class Foo {
  const Foo({int a, String b});
}

@Foo(b: ^)
main() {}
''');
    assertTarget(
      '',
      'b: ',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo Function({int a, String b})',
      expectedParameter: 'b: String',
    );
  }

  Future<void> test_Annotation_positional() async {
    await createTarget('''
class Foo {
  const Foo(int a);
}

@Foo(^)
main() {}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo Function(int)',
      expectedParameter: 'a: int',
    );
  }

  Future<void> test_InstanceCreationExpression_explicitNew_unresolved() async {
    await createTarget('''
main() {
  new Foo(^)
}
''');
    assertTarget(')', '()', argIndex: 0);
  }

  Future<void>
      test_InstanceCreationExpression_generic_explicitTypeArgument() async {
    await createTarget('''
class Foo<T> {
  Foo(T a, T b);
}

main() {
  Foo<int>(^)
}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo<int> Function(int, int)',
      expectedParameter: 'a: int',
    );
  }

  Future<void>
      test_InstanceCreationExpression_generic_inferredTypeArgument() async {
    await createTarget('''
class Foo<T> {
  Foo(T a, T b);
}

main() {
  Foo(false, ^)
}
''');
    assertTarget(
      ')',
      '(false)',
      argIndex: 1,
      expectedExecutable: 'Foo.<init>: Foo<bool> Function(bool, bool)',
      expectedParameter: 'b: bool',
    );
  }

  Future<void> test_InstanceCreationExpression_named() async {
    await createTarget('''
class Foo {
  Foo({int a, String b, double c});
}

main() {
  Foo(b: ^)
}
''');
    assertTarget(
      '',
      'b: ',
      argIndex: 0,
      expectedExecutable:
          'Foo.<init>: Foo Function({int a, String b, double c})',
      expectedParameter: 'b: String',
    );
  }

  Future<void> test_InstanceCreationExpression_named_unresolved() async {
    await createTarget('''
class Foo {
  Foo({int a});
}

main() {
  Foo(b: ^)
}
''');
    assertTarget(
      '',
      'b: ',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo Function({int a})',
    );
  }

  Future<void> test_InstanceCreationExpression_namedConstructor() async {
    await createTarget('''
class Foo {
  Foo.named(int a, String b, double c);
}

main() {
  Foo.named(0, ^)
}
''');
    assertTarget(
      ')',
      '(0)',
      argIndex: 1,
      expectedExecutable: 'Foo.named: Foo Function(int, String, double)',
      expectedParameter: 'b: String',
    );
  }

  Future<void> test_InstanceCreationExpression_positional() async {
    await createTarget('''
class Foo {
  Foo(int a);
}

main() {
  Foo(^)
}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo Function(int)',
      expectedParameter: 'a: int',
    );
  }

  Future<void> test_InstanceCreationExpression_positional_isFunctional() async {
    await createTarget('''
class Foo {
  Foo(int Function(String) f);
}

main() {
  Foo(^)
}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo Function(int Function(String))',
      expectedParameter: 'f: int Function(String)',
      isFunctionalArgument: true,
    );
  }

  Future<void> test_InstanceCreationExpression_positional_noParameter0() async {
    await createTarget('''
class Foo {}

main() {
  Foo(^)
}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'Foo.<init>: Foo Function()',
    );
  }

  Future<void> test_InstanceCreationExpression_positional_noParameter1() async {
    await createTarget('''
class Foo {}

main() {
  Foo(a, ^)
}
''');
    assertTarget(
      ')',
      '(a)',
      argIndex: 1,
      expectedExecutable: 'Foo.<init>: Foo Function()',
    );
  }

  Future<void> test_MethodInvocation_named() async {
    await createTarget('''
int foo({int a, String b, double c}) {}

main() {
  foo(b: ^)
}
''');
    assertTarget(
      '',
      'b: ',
      argIndex: 0,
      expectedExecutable: 'foo: int Function({int a, String b, double c})',
      expectedParameter: 'b: String',
    );
  }

  Future<void> test_MethodInvocation_named_isFunctional() async {
    await createTarget('''
int foo({int Function(String) f}) {}

main() {
  foo(f: ^)
}
''');
    assertTarget(
      '',
      'f: ',
      argIndex: 0,
      expectedExecutable: 'foo: int Function({int Function(String) f})',
      expectedParameter: 'f: int Function(String)',
      isFunctionalArgument: true,
    );
  }

  Future<void> test_MethodInvocation_named_unresolved() async {
    await createTarget('''
int foo({int a}) {}

main() {
  foo(b: ^)
}
''');
    assertTarget(
      '',
      'b: ',
      argIndex: 0,
      expectedExecutable: 'foo: int Function({int a})',
    );
  }

  Future<void> test_MethodInvocation_positional2() async {
    await createTarget('''
int foo(int a, String b) {}

main() {
  foo(0, ^)
}
''');
    assertTarget(
      ')',
      '(0)',
      argIndex: 1,
      expectedExecutable: 'foo: int Function(int, String)',
      expectedParameter: 'b: String',
    );
  }

  Future<void> test_MethodInvocation_positional_isFunctional() async {
    await createTarget('''
int foo(int Function(String) f) {}

main() {
  foo(^)
}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'foo: int Function(int Function(String))',
      expectedParameter: 'f: int Function(String)',
      isFunctionalArgument: true,
    );
  }

  Future<void> test_MethodInvocation_positional_isFunctional2() async {
    await createTarget('''
class C {
  int foo(int Function(String) f) {}
}

main(C c) {
  c.foo(^)
}
''');
    assertTarget(
      ')',
      '()',
      argIndex: 0,
      expectedExecutable: 'C.foo: int Function(int Function(String))',
      expectedParameter: 'f: int Function(String)',
      isFunctionalArgument: true,
    );
  }

  Future<void> test_MethodInvocation_positional_withPrefix() async {
    await createTarget('''
int foo(int a, String b) {}

main() {
  foo(n^)
}
''');
    assertTarget(
      'n',
      '(n)',
      argIndex: 0,
      expectedExecutable: 'foo: int Function(int, String)',
      expectedParameter: 'a: int',
    );
  }

  Future<void> test_MethodInvocation_positional_withPrefix2() async {
    await createTarget('''
int foo(int a, String b) {}

main() {
  foo((n)^)
}
''');
    assertTarget(
      ')',
      '((n))',
      argIndex: 0,
      expectedExecutable: 'foo: int Function(int, String)',
      expectedParameter: 'a: int',
    );
  }

  Future<void> test_MethodInvocation_positional_withSuffix() async {
    await createTarget('''
int foo(int a, String b) {}

main() {
  foo(^n)
}
''');
    assertTarget(
      'n',
      '(n)',
      argIndex: 0,
      expectedExecutable: 'foo: int Function(int, String)',
      expectedParameter: 'a: int',
    );
  }

  Future<void> test_MethodInvocation_unresolved() async {
    await createTarget('''
main() {
  foo(^)
}
''');
    assertTarget(')', '()', argIndex: 0);
  }

  Future<void> test_not_ListLiteral() async {
    await createTarget('''
main() {
  print([^]);
}
''');
    expect(target.argIndex, isNull);
    expect(target.executableElement, isNull);
    expect(target.parameterElement, isNull);
  }
}

@reflectiveTest
class CompletionTargetTest extends _Base {
  Future<void> test_AsExpression_identifier() async {
    // SimpleIdentifier  TypeName  AsExpression
    await createTarget(
        'class A {var b; X _c; foo() {var a; (a^ as String).foo();}');
    assertTarget('a as String', '(a as String)');
  }

  Future<void> test_AsExpression_keyword() async {
    // SimpleIdentifier  TypeName  AsExpression
    await createTarget(
        'class A {var b; X _c; foo() {var a; (a ^as String).foo();}');
    assertTarget('as', 'a as String');
  }

  Future<void> test_AsExpression_keyword2() async {
    // SimpleIdentifier  TypeName  AsExpression
    await createTarget(
        'class A {var b; X _c; foo() {var a; (a a^s String).foo();}');
    assertTarget('as', 'a as String');
  }

  Future<void> test_AsExpression_keyword3() async {
    // SimpleIdentifier  TypeName  AsExpression
    await createTarget(
        'class A {var b; X _c; foo() {var a; (a as^ String).foo();}');
    assertTarget('as', 'a as String');
  }

  Future<void> test_AsExpression_type() async {
    // SimpleIdentifier  TypeName  AsExpression
    await createTarget(
        'class A {var b; X _c; foo() {var a; (a as ^String).foo();}');
    assertTarget('String', 'a as String');
  }

  Future<void> test_Block() async {
    // Block
    await createTarget('main() {^}');
    assertTarget('}', '{}');
  }

  Future<void> test_Block_keyword() async {
    await createTarget(
        'class C { static C get instance => null; } main() {C.in^}');
    assertTarget('in', 'C.in');
  }

  Future<void> test_Block_keyword2() async {
    await createTarget(
        'class C { static C get instance => null; } main() {C.i^n}');
    assertTarget('in', 'C.in');
  }

  Future<void> test_FormalParameter_partialType() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    await createTarget('foo(b.^ f) { }');
    assertTarget('f', 'b.f');
  }

  Future<void> test_FormalParameter_partialType2() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    await createTarget('foo(b.z^ f) { }');
    assertTarget('z', 'b.z');
  }

  Future<void> test_FormalParameter_partialType3() async {
    // SimpleIdentifier  PrefixedIdentifier  TypeName
    await createTarget('foo(b.^) { }');
    assertTarget('', 'b.');
  }

  Future<void> test_FormalParameterList() async {
    // Token  FormalParameterList  FunctionExpression
    await createTarget('foo(^) { }');
    assertTarget(')', '()');
  }

  Future<void> test_FunctionDeclaration_inLineComment() async {
    // Comment  CompilationUnit
    await createTarget('''
      // normal comment ^
      zoo(z) { } String name;''');
    assertTarget('// normal comment ', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_inLineComment2() async {
    // Comment  CompilationUnit
    await createTarget('''
      // normal ^comment
      zoo(z) { } String name;''');
    assertTarget('// normal comment', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_inLineComment3() async {
    // Comment  CompilationUnit
    await createTarget('''
      // normal comment ^
      // normal comment 2
      zoo(z) { } String name;''');
    assertTarget('// normal comment ', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_inLineComment4() async {
    // Comment  CompilationUnit
    await createTarget('''
      // normal comment
      // normal comment 2^
      zoo(z) { } String name;''');
    assertTarget('// normal comment 2', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_inLineDocComment() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await createTarget('''
      /// some dartdoc ^
      zoo(z) { } String name;''');
    assertTarget('/// some dartdoc ', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_FunctionDeclaration_inLineDocComment2() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await createTarget('''
      /// some ^dartdoc
      zoo(z) { } String name;''');
    assertTarget('/// some dartdoc', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_FunctionDeclaration_inStarComment() async {
    // Comment  CompilationUnit
    await createTarget('/* ^ */ zoo(z) {} String name;');
    assertTarget('/*  */', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_inStarComment2() async {
    // Comment  CompilationUnit
    await createTarget('/*  *^/ zoo(z) {} String name;');
    assertTarget('/*  */', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_inStarDocComment() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await createTarget('/** ^ */ zoo(z) { } String name;');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_FunctionDeclaration_inStarDocComment2() async {
    // Comment  FunctionDeclaration  CompilationUnit
    await createTarget('/**  *^/ zoo(z) { } String name;');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_FunctionDeclaration_returnType() async {
    // CompilationUnit
    await createTarget('^ zoo(z) { } String name;');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_returnType_afterLineComment() async {
    // FunctionDeclaration  CompilationUnit
    await createTarget('''
      // normal comment
      ^ zoo(z) {} String name;''');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_returnType_afterLineComment2() async {
    // FunctionDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    await createTarget('''
// normal comment
^ zoo(z) {} String name;''');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_returnType_afterLineDocComment() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    await createTarget('''
      /// some dartdoc
      ^ zoo(z) { } String name; ''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void>
      test_FunctionDeclaration_returnType_afterLineDocComment2() async {
    // SimpleIdentifier  FunctionDeclaration  CompilationUnit
    await createTarget('''
/// some dartdoc
^ zoo(z) { } String name;''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void> test_FunctionDeclaration_returnType_afterStarComment() async {
    // CompilationUnit
    await createTarget('/* */ ^ zoo(z) { } String name;');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_returnType_afterStarComment2() async {
    // CompilationUnit
    await createTarget('/* */^ zoo(z) { } String name;');
    assertTarget('zoo(z) {}', 'zoo(z) {} String name;');
  }

  Future<void> test_FunctionDeclaration_returnType_afterStarDocComment() async {
    // FunctionDeclaration  CompilationUnit
    await createTarget('/** */ ^ zoo(z) { } String name;');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void>
      test_FunctionDeclaration_returnType_afterStarDocComment2() async {
    // FunctionDeclaration  CompilationUnit
    await createTarget('/** */^ zoo(z) { } String name;');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void> test_IfStatement_droppedToken() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('main() { if (v i^) }');
    assertTarget(')', 'if (v) ;', droppedToken: 'i');
  }

  Future<void> test_InstanceCreationExpression_identifier() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    await createTarget('class C {foo(){var f; {var x;} new ^C();}}');
    assertTarget('C', 'new C()');
  }

  Future<void> test_InstanceCreationExpression_keyword() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    await createTarget('class C {foo(){var f; {var x;} new^ }}');
    assertTarget('new ();', '{var f; {var x;} new ();}');
  }

  Future<void> test_InstanceCreationExpression_keyword2() async {
    // InstanceCreationExpression  ExpressionStatement  Block
    await createTarget('class C {foo(){var f; {var x;} new^ C();}}');
    assertTarget('new C();', '{var f; {var x;} new C();}');
  }

  Future<void> test_MapLiteral_empty() async {
    // MapLiteral  VariableDeclaration
    await createTarget('foo = {^');
    // fasta scanner inserts synthetic closing '}'
    assertTarget('}', '{}');
  }

  Future<void> test_MapLiteral_expression() async {
    super.setUp();
    final experimentStatus = (driverFor(testPackageRootPath).analysisOptions
            as analyzer.AnalysisOptionsImpl)
        .experimentStatus;
    if (experimentStatus.control_flow_collections ||
        experimentStatus.spread_collections) {
      // SimpleIdentifier  MapLiteral  VariableDeclaration
      await createTarget('foo = {1: 2, T^');
      assertTarget('T', '{1 : 2, T}');
    } else {
      // TODO(b/35569): remove this branch of test behavior

      // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
      await createTarget('foo = {1: 2, T^');
      assertTarget('T : ', '{1 : 2, T : }');
    }
  }

  Future<void> test_MapLiteralEntry() async {
    // SimpleIdentifier  MapLiteralEntry  MapLiteral  VariableDeclaration
    await createTarget('foo = {7:T^};');
    assertTarget('T', '7 : T');
  }

  Future<void> test_MethodDeclaration_inLineComment() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        // normal comment ^
        zoo(z) { } String name; }''');
    assertTarget('// normal comment ', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_inLineComment2() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        // normal ^comment
        zoo(z) { } String name; }''');
    assertTarget('// normal comment', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_inLineComment3() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        // normal comment ^
        // normal comment 2
        zoo(z) { } String name; }''');
    assertTarget('// normal comment ', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_inLineComment4() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        // normal comment
        // normal comment 2^
        zoo(z) { } String name; }''');
    assertTarget('// normal comment 2', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_inLineDocComment() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        /// some dartdoc ^
        zoo(z) { } String name; }''');
    assertTarget('/// some dartdoc ', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_inLineDocComment2() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        /// some ^dartdoc
        zoo(z) { } String name; }''');
    assertTarget('/// some dartdoc', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_inStarComment() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/* ^ */ zoo(z) {} String name;}');
    assertTarget('/*  */', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_inStarComment2() async {
    // Comment  ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/*  *^/ zoo(z) {} String name;}');
    assertTarget('/*  */', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_inStarDocComment() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/** ^ */ zoo(z) { } String name; }');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_inStarDocComment2() async {
    // Comment  MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/**  *^/ zoo(z) { } String name; }');
    assertTarget('/**  */', '');
    expect(target.containingNode is Comment, isTrue);
    expect(target.containingNode.parent.toSource(), 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_returnType() async {
    // ClassDeclaration  CompilationUnit
    await createTarget('class C2 {^ zoo(z) { } String name; }');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_returnType_afterLineComment() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        // normal comment
        ^ zoo(z) {} String name;}''');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_returnType_afterLineComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    // TOD(danrubel) left align all test source
    await createTarget('''
class C2 {
  // normal comment
^ zoo(z) {} String name;}''');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_returnType_afterLineDocComment() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('''
      class C2 {
        /// some dartdoc
        ^ zoo(z) { } String name; }''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_returnType_afterLineDocComment2() async {
    // SimpleIdentifier  MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('''
class C2 {
  /// some dartdoc
^ zoo(z) { } String name; }''');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_returnType_afterStarComment() async {
    // ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/* */ ^ zoo(z) { } String name; }');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_returnType_afterStarComment2() async {
    // ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/* */^ zoo(z) { } String name; }');
    assertTarget('zoo(z) {}', 'class C2 {zoo(z) {} String name;}');
  }

  Future<void> test_MethodDeclaration_returnType_afterStarDocComment() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/** */ ^ zoo(z) { } String name; }');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void> test_MethodDeclaration_returnType_afterStarDocComment2() async {
    // MethodDeclaration  ClassDeclaration  CompilationUnit
    await createTarget('class C2 {/** */^ zoo(z) { } String name; }');
    assertTarget('zoo', 'zoo(z) {}');
  }

  Future<void> test_SwitchStatement_c() async {
    // Token('c') SwitchStatement
    await createTarget('main() { switch(x) {c^} }');
    assertTarget('}', 'switch (x) {}', droppedToken: 'c');
  }

  Future<void> test_SwitchStatement_c2() async {
    // Token('c') SwitchStatement
    await createTarget('main() { switch(x) { c^ } }');
    assertTarget('}', 'switch (x) {}', droppedToken: 'c');
  }

  Future<void> test_SwitchStatement_empty() async {
    // SwitchStatement
    await createTarget('main() { switch(x) {^} }');
    assertTarget('}', 'switch (x) {}');
  }

  Future<void> test_SwitchStatement_empty2() async {
    // SwitchStatement
    await createTarget('main() { switch(x) { ^ } }');
    assertTarget('}', 'switch (x) {}');
  }

  Future<void> test_TypeArgumentList() async {
    // TypeName  TypeArgumentList  TypeName
    await createTarget('main() { C<^> c; }');
    assertTarget('', '<>');
  }

  Future<void> test_TypeArgumentList2() async {
    // TypeName  TypeArgumentList  TypeName
    await createTarget('main() { C<C^> c; }');
    assertTarget('C', '<C>');
  }

  Future<void> test_VariableDeclaration_lhs_identifier_after() async {
    // VariableDeclaration  VariableDeclarationList
    await createTarget('main() {int b^ = 1;}');
    assertTarget('b = 1', 'int b = 1');
  }

  Future<void> test_VariableDeclaration_lhs_identifier_before() async {
    // VariableDeclaration  VariableDeclarationList
    await createTarget('main() {int ^b = 1;}');
    assertTarget('b = 1', 'int b = 1');
  }
}

class _Base extends AbstractContextTest {
  int offset;
  CompletionTarget target;
  FindElement findElement;

  void assertTarget(
    String entityText,
    String nodeText, {
    int argIndex,
    String droppedToken,
    bool isFunctionalArgument = false,
    String expectedExecutable,
    String expectedParameter,
  }) {
    expect(
      target.entity.toString(),
      entityText,
      reason: 'entity',
    );

    expect(
      target.containingNode.toString(),
      nodeText,
      reason: 'containingNode',
    );

    expect(
      target.argIndex,
      argIndex,
      reason: 'argIndex',
    );

    expect(
      target.droppedToken?.toString(),
      droppedToken ?? isNull,
      reason: 'droppedToken',
    );

    var actualExecutable = target.executableElement;
    if (expectedExecutable == null) {
      expect(actualExecutable, isNull);
    } else {
      expect(_executableStr(actualExecutable), expectedExecutable);
    }

    var actualParameter = target.parameterElement;
    if (expectedParameter == null) {
      expect(actualParameter, isNull);
    } else {
      expect(_parameterStr(actualParameter), expectedParameter);
    }

    expect(target.isFunctionalArgument(), isFunctionalArgument);
  }

  Future<void> createTarget(String content) async {
    expect(offset, isNull, reason: 'Call createTarget exactly once');

    offset = content.indexOf('^');
    expect(offset, isNot(equals(-1)), reason: 'missing ^');

    var nextOffset = content.indexOf('^', offset + 1);
    expect(nextOffset, equals(-1), reason: 'too many ^');

    content = content.substring(0, offset) + content.substring(offset + 1);

    var path = convertPath('/home/test/lib/test.dart');
    newFile(path, content: content);

    var result = await resolveFile(path);
    findElement = FindElement(result.unit);

    target = CompletionTarget.forOffset(result.unit, offset);
  }

  static String _executableNameStr(ExecutableElement executable) {
    var executableEnclosing = executable.enclosingElement;
    if (executableEnclosing is CompilationUnitElement) {
      return executable.name;
    } else if (executable is ConstructorElement) {
      if (executable.name == '') {
        return '${executableEnclosing.name}.<init>';
      } else {
        return '${executableEnclosing.name}.${executable.name}';
      }
    } else if (executable is MethodElement) {
      return '${executableEnclosing.name}.${executable.name}';
    }
    fail('Unexpected element: $executable');
  }

  static String _executableStr(ExecutableElement element) {
    var executableStr = _executableNameStr(element);
    var typeStr = element.type.getDisplayString(withNullability: false);
    return '$executableStr: $typeStr';
  }

  static String _parameterStr(ParameterElement element) {
    var typeStr = element.type.getDisplayString(withNullability: false);
    return '${element.name}: $typeStr';
  }
}
