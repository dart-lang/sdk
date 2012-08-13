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
class Math {
  static double parseDouble(String s) => 1.0;
}
''';

testDart2Dart(String src, [void continuation(String s)]) {
  // If continuation is not provided, check that source string remains the same.
  if (continuation === null) {
    continuation = (s) { Expect.equals(src, s); };
  }
  testDart2DartWithLibrary(src, '', continuation);
}

/**
 * Library name is assumed to be 'mylib' in 'mylib.dart' file.
 */
testDart2DartWithLibrary(
    String srcMain, String srcLibrary, [void continuation(String s)]) {
  fileUri(path) => new Uri.fromComponents(scheme: 'file', path: path);

  final scriptUri = fileUri('script.dart');
  final libUri = fileUri('mylib.dart');

  provider(uri) {
    if (uri == scriptUri) return new Future.immediate(srcMain);
    if (uri.toString() == libUri.toString()) {
      return new Future.immediate(srcLibrary);
    }
    if (uri.path.endsWith('/core.dart')) return new Future.immediate(coreLib);
    return new Future.immediate('');
  }

  handler(uri, begin, end, message, kind) {
    if (kind === Diagnostic.ERROR || kind === Diagnostic.CRASH) {
      Expect.fail('$uri: $begin-$end: $message [$kind]');
    }
  }

  compile(
      scriptUri,
      fileUri('libraryRoot'),
      fileUri('packageRoot'),
      provider,
      handler,
      const ['--output-type=dart', '--unparse-validation']).then(continuation);
}

testSignedConstants() {
  testUnparse('var x=+42;');
  testUnparse('var x=+.42;');
  testUnparse('var x=-42;');
  testUnparse('var x=-.42;');
  testUnparse('var x=+0;');
  testUnparse('var x=+0.0;');
  testUnparse('var x=+.0;');
  testUnparse('var x=-0;');
  testUnparse('var x=-0.0;');
  testUnparse('var x=-.0;');
}

testGenericTypes() {
  testUnparse('var x=new List<List<int>>();');
  testUnparse('var x=new List<List<List<int>>>();');
  testUnparse('var x=new List<List<List<List<int>>>>();');
  testUnparse('var x=new List<List<List<List<List<int>>>>>();');
}

testForLoop() {
  testUnparse('for(;i<100;i++ ){}');
  testUnparse('for(i=0;i<100;i++ ){}');
}

testEmptyList() {
  testUnparse('var x=[];');
}

testClosure() {
  testUnparse('var x=(var x)=> x;');
}

testIndexedOperatorDecl() {
  testUnparseMember('operator[](int i)=> null;');
  testUnparseMember('operator[]=(int i,int j)=> null;');
}

testNativeMethods() {
  testUnparseMember('foo()native;');
  testUnparseMember('foo()native "bar";');
  testUnparseMember('foo()native "this.x = 41";');
}

testPrefixIncrements() {
  testUnparse(' ++i;');
  testUnparse('++a[i];');
  testUnparse('++a[++b[i]];');
}

testConstModifier() {
  testUnparse('foo([var a=const []]){}');
  testUnparse('foo([var a=const{}]){}');
  testUnparse('foo(){var a=const []; var b=const{};}');
  testUnparse('foo([var a=const [const{"a": const [1,2,3]}]]){}');
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

testExtendsImplements() {
  testDart2Dart('main(){new B<Object>();}'
      'class A<T>{}class B<T> extends A<T>{}');
}

testVariableDefinitions() {
  testDart2Dart('main(){final var x,y; final String s;}');
  testDart2Dart('foo(f,g){}main(){foo(1,2);}');
  testDart2Dart('foo(f(arg)){}main(){foo(main);}');
  // A couple of static/finals inside a class.
  testDart2Dart('main(){A.a; A.b;}class A{static final String a="5";'
      'static final String b="4";}');
  // Class member of typedef-ed function type.
  // Maybe typedef should be included in the result too, but it
  // works fine without it.
  testDart2Dart(
    'main(){new A((arg){});}typedef void foofunc(arg);'
    'class A{A(foofunc this.handler);final foofunc handler;}');
}

testGetSet() {
  // Top-level get/set.
  testDart2Dart('get foo(){return 5;}set foo(arg){}main(){foo; foo=5;}');
  // Field get/set.
  testDart2Dart('main(){var a=new A(); a.foo; a.foo=5;}'
      'class A{set foo(a){}get foo(){return 5;}}');
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
      'class A implements I{A(this.f);A.fromFoo(foo):this("f");'
      'final String f;}');
}

testAbstractClass() {
  testDart2Dart('main(){A.foo;}abstract class A{final static num foo;}');
}

testConflictSendsRename() {
  // Various Send-s to current library and external library. Verify that
  // everything is renamed correctly in conflicting class names and global
  // functions.
  var librarySrc = '''
#library("mylib.dart");

globalfoo() {}

class A {
  A(){}
  A.fromFoo(){}
  static staticfoo(){}
  foo(){}
  static final field = 5;
}
''';
  var mainSrc = '''
#import("mylib.dart", prefix: "mylib");

globalfoo() {}

class A {
  A(){}
  A.fromFoo(){}
  static staticfoo(){}
  foo(){}
  static final field = 5;
}

main() {
  globalfoo();
  A.field;
  A.staticfoo();
  new A();
  new A.fromFoo();
  new A().foo();

  mylib.globalfoo();
  mylib.A.field;
  mylib.A.staticfoo();
  new mylib.A();
  new mylib.A.fromFoo();
  new mylib.A().foo();
}
''';
  var expectedResult = @'globalfoo(){}'
      @'p_globalfoo(){}'
      @'main(){p_globalfoo(); A.field; A.staticfoo(); new A(); '
          @'new A.fromFoo(); new A().foo(); globalfoo(); p_A.field; '
          @'p_A.staticfoo(); new p_A(); new p_A.fromFoo(); new p_A().foo();}'
      @'class A{A(){}A.fromFoo(){}foo(){}static staticfoo(){}'
          @'static final field=5;}'
      @'class p_A{p_A(){}p_A.fromFoo(){}foo(){}static staticfoo(){}'
          @'static final field=5;}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      (String result) { Expect.equals(expectedResult, result); });
}

testNoConflictSendsRename() {
  // Various Send-s to current library and external library. Nothing should be
  // renamed here, only library prefixes must be cut.
  var librarySrc = '''
#library("mylib.dart");

globalfoo() {}

class A {
  A(){}
  A.fromFoo(){}
  static staticfoo(){}
  foo(){}
  static final field = 5;
}
''';
  var mainSrc = '''
#import("mylib.dart", prefix: "mylib");

myglobalfoo() {}

class MyA {
  MyA(){}
  MyA.myfromFoo(){}
  static mystaticfoo(){}
  myfoo(){}
  static final myfield = 5;
}

main() {
  myglobalfoo();
  MyA.myfield;
  MyA.mystaticfoo();
  new MyA();
  new MyA.myfromFoo();
  new MyA().myfoo();

  mylib.globalfoo();
  mylib.A.field;
  mylib.A.staticfoo();
  new mylib.A();
  new mylib.A.fromFoo();
  new mylib.A().foo();
}
''';
  var expectedResult = 'myglobalfoo(){}'
      'globalfoo(){}'
      'main(){myglobalfoo(); MyA.myfield; MyA.mystaticfoo(); new MyA(); '
          'new MyA.myfromFoo(); new MyA().myfoo(); globalfoo(); A.field; '
          'A.staticfoo(); new A(); new A.fromFoo(); new A().foo();}'
      'class MyA{MyA(){}MyA.myfromFoo(){}myfoo(){}'
          'static final myfield=5;static mystaticfoo(){}}'
      'class A{A(){}A.fromFoo(){}foo(){}'
          'static staticfoo(){}static final field=5;}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      (String result) { Expect.equals(expectedResult, result); });
}

testConflictLibraryClassRename() {
  var librarySrc = '''
#library('mylib');

topfoo() {}

class A {
  foo(){}
}
''';
  var mainSrc = '''
#import('mylib.dart', prefix: 'mylib');


topfoo() {var x = 5;}

class A{
  num foo() {}
  A.fromFoo() {}
  mylib.A myliba;
  List<A> mylist;
}

mylib.A getA() => null;

main() {
  var a = new mylib.A();
  a.foo();
  var b = new A.fromFoo();
  b.foo();
  var GREATVAR = b.myliba;
  b.mylist;
  a = getA();
  topfoo();
  mylib.topfoo();
}
''';
  var expectedResult = @'topfoo(){}p_topfoo(){var x=5;}A getA()=> null;'
      @'main(){var a=new A(); a.foo(); var b=new p_A.fromFoo(); b.foo(); '
          @'var GREATVAR=b.myliba; b.mylist; a=getA(); p_topfoo(); topfoo();}'
      @'class p_A{p_A.fromFoo(){}List<p_A> mylist;num foo(){}A myliba;}'
      @'class A{foo(){}}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      (String result) { Expect.equals(expectedResult, result); });
}

testDefaultClassWithArgs() {
  testDart2Dart('main(){var result=new IA<String>();}'
      'interface IA<T> default A<T extends Object>{IA();}'
      'class A<T extends Object> implements IA<T>{factory A(){}}');
}

testClassExtendsWithArgs() {
  testDart2Dart('main(){new B<Object>();}'
    'class A<T extends Object>{}'
    'class B<T extends Object> extends A<T>{}');
}

testStaticInvocation() {
  testDart2Dart('main(){var x=Math.parseDouble("1");}');
}

main() {
  testSignedConstants();
  testGenericTypes();
  testForLoop();
  testEmptyList();
  testClosure();
  testIndexedOperatorDecl();
  testNativeMethods();
  testPrefixIncrements();
  testConstModifier();
  testSimpleFileUnparse();
  testTopLevelField();
  testSimpleObjectInstantiation();
  testSimpleTopLevelClass();
  testClassWithSynthesizedConstructor();
  testClassWithMethod();
  testExtendsImplements();
  testVariableDefinitions();
  testGetSet();
  testFactoryConstructor();
  testAbstractClass();
  testConflictSendsRename();
  testNoConflictSendsRename();
  testConflictLibraryClassRename();
  testDefaultClassWithArgs();
  testClassExtendsWithArgs();
  testStaticInvocation();
}
