// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:uri');
#import('parser_helper.dart');
#import("../../../lib/compiler/compiler.dart");
#import("../../../lib/compiler/implementation/tree/tree.dart");

testUnparse(String statement) {
  Node node = parseStatement(statement);
  Expect.equals(statement, node.unparse());
}

testUnparseMember(String member) {
  Node node = parseMember(member);
  Expect.equals(member, node.unparse());
}

final coreLib = @'''
#library('corelib');
class Object {}
interface bool {}
interface num {}
interface int extends num {}
interface double extends num {}
interface String {}
interface Function {}
interface List {}
interface Closure {}
interface Dynamic {}
interface Null {}
assert() {}
''';

testDart2Dart(String src, [void continuation(String s)]) {
  fileUri(path) => new Uri(scheme: 'file', path: path);

  final scriptUri = fileUri('script.dart');

  provider(uri) {
    if (uri == scriptUri) return new Future.immediate(src);
    if (uri.path.endsWith('/core.dart')) return new Future.immediate(coreLib);
    return new Future.immediate('');
  }

  handler(uri, begin, end, message, kind) {
    if (kind === Diagnostic.ERROR || kind === Diagnostic.CRASH) {
      Expect.fail('$uri: $begin-$end: $message [$kind]');
    }
  }

  // If continuation is not provided, check that source string remains the same.
  if (continuation == null) {
    continuation = (s) => Expect.equals(src, s);
  }
  compile(
      scriptUri,
      fileUri('libraryRoot'),
      fileUri('packageRoot'),
      provider,
      handler,
      const ['--output-type=dart', '--unparse-validation']).then(continuation);
}

testGenericTypes() {
  testUnparse('var x=new List<List<int>>();');
  testUnparse('var x=new List<List<List<int>>>();');
  testUnparse('var x=new List<List<List<List<int>>>>();');
  testUnparse('var x=new List<List<List<List<List<int>>>>>();');
}

testForLoop() {
  testUnparse('for(;i<100;i++){}');
  testUnparse('for(i=0;i<100;i++){}');
}

testEmptyList() {
  testUnparse('var x= [];');
}

testClosure() {
  testUnparse('var x=(var x)=> x;');
}

testIndexedOperatorDecl() {
  testUnparseMember('operator[](int i)=> null;');
  testUnparseMember('operator[]=(int i, int j)=> null;');
}

testNativeMethods() {
  testUnparseMember('foo()native;');
  testUnparseMember('foo()native "bar";');
  testUnparseMember('foo()native "this.x = 41";');
}

testPrefixIncrements() {
  testUnparse('++i;');
  testUnparse('++a[i];');
  testUnparse('++a[++b[i]];');
}

testConstModifier() {
  testUnparse('foo([var a=const []]){}');
  testUnparse('foo([var a=const{}]){}');
  testUnparse('foo(){var a=const []; var b=const{};}');
  testUnparse('foo([var a=const [const{"a": const [1, 2, 3]}]]){}');
}

testSimpleFileUnparse() {
  final src = '''
should_be_dropped() {
}

should_be_kept() {
}

main() {
  should_be_kept();
}
''';
  testDart2Dart(src, (String s) {
    Expect.equals('should_be_kept(){}main(){should_be_kept();}', s);
  });
}

testTopLevelField() {
  testDart2Dart('final String x="asd";main(){x;}');
}

testSimpleObjectInstantiation() {
  testUnparse('main(){new Object();}');
}

testSimpleTopLevelClass() {
  testDart2Dart('main(){new A();}class A{A(){}}');
}

testClassWithSynthesizedConstructor() {
  testDart2Dart('main(){new A();}class A{}');
}

testClassWithMethod() {
  testDart2Dart('main(){var a=new A(); a.foo();}class A{void foo(){}}');
}

testVariableDefinitions() {
  testDart2Dart('main(){final var x, y; final String s;}');
  testDart2Dart('foo(f, g){}main(){foo(1, 2);}');
  testDart2Dart('foo(f(arg)){}main(){foo(main);}');
  // A couple of static/finals inside a class.
  testDart2Dart('main(){A.a; A.b;}class A{static final String a="5";'
      'static final String b="4";}');
}

testGetSet() {
  // Top-level get/set.
  testDart2Dart('get foo(){return 5;}set foo(arg){}main(){foo; foo=5;}');
  // Field get/set.
  testDart2Dart('main(){var a=new A(); a.foo; a.foo=5;}class A{set foo(a){}get foo(){return 5;}}');
  // Typed get/set.
  testDart2Dart('String get foo(){return "a";}main(){foo;}');
}

testFactoryConstructor() {
  testDart2Dart('main(){new A.fromFoo();}class A{A.fromFoo();}');
  // Now more complicated, with normal constructor and factory parameters.
  testDart2Dart('main(){new A.fromFoo(5);}'
      'class A{A(this.f);A.fromFoo(foo):this("f");final String f;}');
  // Now even more complicated, with interface and default factory.
  testDart2Dart('main(){new A.fromFoo(5); new I.fromFoo();}'
      'class IFactory{factory I.fromFoo()=> new A(5);}'
      'interface I default IFactory{I.fromFoo();}'
      'class A implements I{A(this.f);A.fromFoo(foo):this("f");final String f;}');
}

main() {
  testGenericTypes();
  testForLoop();
  testEmptyList();
  testClosure();
  testIndexedOperatorDecl();
  testNativeMethods();
  testPrefixIncrements();
  testConstModifier();
  testSimpleFileUnparse();
  testSimpleObjectInstantiation();
  testSimpleTopLevelClass();
  testClassWithSynthesizedConstructor();
  testClassWithMethod();
  testVariableDefinitions();
  testGetSet();
  testFactoryConstructor();
  testTopLevelField();
}
