// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:uri';
import 'parser_helper.dart';
import 'mock_compiler.dart';
import '../../../sdk/lib/_internal/compiler/compiler.dart';
import '../../../sdk/lib/_internal/compiler/implementation/dart2jslib.dart' as leg;
import '../../../sdk/lib/_internal/compiler/implementation/dart_backend/dart_backend.dart';
import '../../../sdk/lib/_internal/compiler/implementation/elements/elements.dart';
import '../../../sdk/lib/_internal/compiler/implementation/tree/tree.dart';

const coreLib = r'''
#library('corelib');
class Object {}
interface bool {}
interface num {}
interface int extends num {}
interface double extends num {}
interface String {}
interface Function {}
interface List {}
interface Map {}
interface Closure {}
interface Dynamic_ {}
interface Null {}
interface TypeError {}
class Type {}
class Math {
  static double parseDouble(String s) => 1.0;
}
print(x) {}
''';

const ioLib = r'''
#library('io');
class Platform {
  static int operatingSystem;
}
''';

const htmlLib = r'''
#library('html');
Window __window;
Window get window => __window;
abstract class Window {
  Navigator get navigator;
}
abstract class Navigator {
  String get userAgent;
}
''';

const helperLib = r'''
#library('js_helper');
class JSInvocationMirror {}
''';

testDart2Dart(String src, {void continuation(String s), bool minify: false,
    bool stripTypes: false}) {
  // If continuation is not provided, check that source string remains the same.
  if (continuation === null) {
    continuation = (s) { Expect.equals(src, s); };
  }
  testDart2DartWithLibrary(src, '', continuation: continuation, minify: minify,
      stripTypes: stripTypes);
}

/**
 * Library name is assumed to be 'mylib' in 'mylib.dart' file.
 */
testDart2DartWithLibrary(
    String srcMain, String srcLibrary,
    {void continuation(String s), bool minify: false,
    bool stripTypes: false}) {
  fileUri(path) => new Uri.fromComponents(scheme: 'file', path: path);

  final scriptUri = fileUri('script.dart');
  final libUri = fileUri('mylib.dart');

  provider(uri) {
    if (uri == scriptUri) return new Future.immediate(srcMain);
    if (uri.toString() == libUri.toString()) {
      return new Future.immediate(srcLibrary);
    }
    if (uri.path.endsWith('/core.dart')) return new Future.immediate(coreLib);
    if (uri.path.endsWith('/io.dart')) return new Future.immediate(ioLib);
    if (uri.path.endsWith('/js_helper.dart')) return new Future.immediate(helperLib);
    // TODO(smok): The file should change to html_dartium at some point.
    if (uri.path.endsWith('/html_dart2js.dart')) return new Future.immediate(htmlLib);
    return new Future.immediate('');
  }

  handler(uri, begin, end, message, kind) {
    if (kind === Diagnostic.ERROR || kind === Diagnostic.CRASH) {
      Expect.fail('$uri: $begin-$end: $message [$kind]');
    }
  }

  final options = <String>['--output-type=dart'];
  if (minify) options.add('--minify');
  if (stripTypes) options.add('--force-strip=types');

  compile(
      scriptUri,
      fileUri('libraryRoot'),
      fileUri('packageRoot'),
      provider,
      handler,
      options).then(continuation);
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
  testDart2Dart(src, continuation: (String s) {
    Expect.equals('should_be_kept(){}main(){should_be_kept();}', s);
  });
}

testTopLevelField() {
  testDart2Dart('final String x="asd";main(){x;}');
}

testSimpleTopLevelClass() {
  testDart2Dart('main(){new A();}class A{A(){}}');
}

testClassWithSynthesizedConstructor() {
  testDart2Dart('main(){new A();}class A{}');
}

testClassWithMethod() {
  testDart2Dart('main(){var a=new A();a.foo();}class A{void foo(){}}');
}

testExtendsImplements() {
  testDart2Dart('main(){new B<Object>();}'
      'class A<T>{}class B<T> extends A<T>{}');
}

testVariableDefinitions() {
  testDart2Dart('main(){final var x,y;final String s;}');
  testDart2Dart('foo(f,g){}main(){foo(1,2);}');
  testDart2Dart('foo(f(arg)){}main(){foo(main);}');
  // A couple of static/finals inside a class.
  testDart2Dart('main(){A.a;A.b;}class A{static const String a="5";'
      'static const String b="4";}');
  // Class member of typedef-ed function type.
  // Maybe typedef should be included in the result too, but it
  // works fine without it.
  testDart2Dart(
    'typedef void foofunc(arg);main(){new A((arg){});}'
    'class A{A(foofunc this.handler);final foofunc handler;}');
}

testGetSet() {
  // Top-level get/set.
  testDart2Dart('set foo(arg){}get foo{return 5;}main(){foo;foo=5;}');
  // Field get/set.
  testDart2Dart('main(){var a=new A();a.foo;a.foo=5;}'
      'class A{set foo(a){}get foo{return 5;}}');
  // Typed get/set.
  testDart2Dart('String get foo{return "a";}main(){foo;}');
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
var globalVar;
var globalVarInitialized = 6, globalVarInitialized2 = 7;

class A {
  A(){}
  A.fromFoo(){}
  static staticfoo(){}
  foo(){}
  static const field = 5;
}
''';
  var mainSrc = '''
#import("mylib.dart", prefix: "mylib");

globalfoo() {}
var globalVar;
var globalVarInitialized = 6, globalVarInitialized2 = 7;

class A {
  A(){}
  A.fromFoo(){}
  static staticfoo(){}
  foo(){}
  static const field = 5;
}

main() {
  globalVar;
  globalVarInitialized;
  globalVarInitialized2;
  globalfoo();
  A.field;
  A.staticfoo();
  new A();
  new A.fromFoo();
  new A().foo();

  mylib.globalVar;
  mylib.globalVarInitialized;
  mylib.globalVarInitialized2;
  mylib.globalfoo();
  mylib.A.field;
  mylib.A.staticfoo();
  new mylib.A();
  new mylib.A.fromFoo();
  new mylib.A().foo();
}
''';
  var expectedResult =
      'globalfoo(){}var globalVar;'
      'var globalVarInitialized=6,globalVarInitialized2=7;'
      'class A{A(){}A.fromFoo(){}static staticfoo(){}foo(){}'
          'static const field=5;}'
      'p_globalfoo(){}'
      'var p_globalVar;var p_globalVarInitialized=6,p_globalVarInitialized2=7;'
      'class p_A{p_A(){}p_A.p_fromFoo(){}static p_staticfoo(){}foo(){}'
          'static const p_field=5;}'
      'main(){p_globalVar;p_globalVarInitialized;'
         'p_globalVarInitialized2;p_globalfoo();'
         'p_A.p_field;p_A.p_staticfoo();'
         'new p_A();new p_A.p_fromFoo();new p_A().foo();'
         'globalVar;globalVarInitialized;globalVarInitialized2;globalfoo();'
         'A.field;A.staticfoo();'
         'new A();new A.fromFoo();new A().foo();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
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
  static const field = 5;
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
  static const myfield = 5;
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
  var expectedResult =
      'globalfoo(){}'
      'class A{A(){}A.fromFoo(){}static staticfoo(){}foo(){}'
          'static const field=5;}'
      'myglobalfoo(){}'
      'class MyA{MyA(){}MyA.myfromFoo(){}static mystaticfoo(){}myfoo(){}'
          'static const myfield=5;}'
      'main(){myglobalfoo();MyA.myfield;MyA.mystaticfoo();new MyA();'
          'new MyA.myfromFoo();new MyA().myfoo();globalfoo();A.field;'
          'A.staticfoo();new A();new A.fromFoo();new A().foo();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
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
  var expectedResult =
    'topfoo(){}'
    'class A{foo(){}}'
    'p_topfoo(){var x=5;}'
    'class p_A{num foo(){}p_A.fromFoo(){}A myliba;List<p_A> mylist;}'
    'A getA()=>null;'
    'main(){var a=new A();a.foo();var b=new p_A.fromFoo();b.foo();'
        'var GREATVAR=b.myliba;b.mylist;a=getA();p_topfoo();topfoo();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
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

testLibraryGetSet() {
  var librarySrc = '''
#library('mylib');

get topgetset => 5;
set topgetset(arg) {}
''';
  var mainSrc = '''
#import('mylib.dart', prefix: 'mylib');

get topgetset => 6;
set topgetset(arg) {}

main() {
  topgetset;
  topgetset = 6;

  mylib.topgetset;
  mylib.topgetset = 5;
}
''';
  var expectedResult =
    'get topgetset=>5;'
    'set topgetset(arg){}'
    'get p_topgetset=>6;'
    'set p_topgetset(arg){}'
    'main(){p_topgetset;p_topgetset=6;topgetset;topgetset=5;}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testFieldTypeOutput() {
  testDart2Dart('main(){new A().field;}class B{}class A{B field;}');
}

class DynoMap implements Map<Element, ElementAst> {
  final compiler;
  DynoMap(this.compiler);

  get resolvedElements => compiler.enqueuer.resolution.resolvedElements;
  ElementAst operator[](Element element) =>
      new ElementAst(element.parseNode(compiler), resolvedElements[element]);
}

PlaceholderCollector collectPlaceholders(compiler, element) =>
  new PlaceholderCollector(compiler, new Set<String>(), new DynoMap(compiler))
      ..collect(element);

testLocalFunctionPlaceholder() {
  var src = '''
main() {
  function localfoo() {}
  localfoo();
}
''';
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript(src);
  FunctionElement mainElement = compiler.mainApp.find(leg.Compiler.MAIN);
  compiler.processQueue(compiler.enqueuer.resolution, mainElement);
  PlaceholderCollector collector = collectPlaceholders(compiler, mainElement);
  FunctionExpression mainNode = mainElement.parseNode(compiler);
  FunctionExpression fooNode = mainNode.body.statements.nodes.head.function;
  LocalPlaceholder fooPlaceholder =
      collector.functionScopes[mainElement].localPlaceholders.iterator().next();
  Expect.isTrue(fooPlaceholder.nodes.contains(fooNode.name));
}

testDefaultClassNamePlaceholder() {
  var src = '''
interface I default C{
  I();
}

class C {
  I() {}
}

main() {
  new I();
}
''';
  MockCompiler compiler = new MockCompiler();
  compiler.parseScript(src);
  ClassElement interfaceElement = compiler.mainApp.find(buildSourceString('I'));
  interfaceElement.ensureResolved(compiler);
  PlaceholderCollector collector =
      collectPlaceholders(compiler, interfaceElement);
  ClassNode interfaceNode = interfaceElement.parseNode(compiler);
  Node defaultTypeNode = interfaceNode.defaultClause.typeName;
  ClassElement classElement = compiler.mainApp.find(buildSourceString('C'));
  // Check that 'C' in default clause of I gets into placeholders.
  Expect.isTrue(collector.elementNodes[classElement].contains(defaultTypeNode));
}

testTypeVariablesAreRenamed() {
  // Somewhat a hack: we require all the references of the identifier
  // to be renamed in the same way for the whole library. Hence
  // if we have a class and type variable with the same name, they
  // both should be renamed.
  var librarySrc = '''
#library('mylib');
typedef void MyFunction<T extends num>(T arg);
class T {}
class B<T> {}
class A<T> extends B<T> { T f; }
''';
  var mainSrc = '''
#import('mylib.dart', prefix: 'mylib');
typedef void MyFunction<T extends num>(T arg);
class T {}
class B<T> {}
class A<T> extends B<T> { T f; }

main() {
  MyFunction myf1;
  mylib.MyFunction myf2;
  new A<int>().f;
  new T();

  new mylib.A<int>().f;
  new mylib.T();
}
''';
  var expectedResult =
    'typedef void MyFunction<T extends num>(T arg);'
    'class T{}'
    'class B<T>{}'
    'class A<T> extends B<T>{T f;}'
    'typedef void p_MyFunction<p_T extends num>(p_T arg);'
    'class p_T{}'
    'class p_B<p_T>{}'
    'class p_A<p_T> extends p_B<p_T>{p_T f;}'
    'main(){p_MyFunction myf1;MyFunction myf2;new p_A<int>().f;'
        'new p_T();new A<int>().f;new T();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testClassTypeArgumentBound() {
  var librarySrc = '''
#library('mylib');

interface I {}
class A<T extends I> {}

''';
  var mainSrc = '''
#import('mylib.dart', prefix: 'mylib');

interface I {}
class A<T extends I> {}

main() {
  new A();
  new mylib.A();
}
''';
  var expectedResult =
    'interface I{}'
    'class A<T extends I>{}'
    'interface p_I{}'
    'class p_A<p_T extends p_I>{}'
    'main(){new p_A();new A();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testDoubleMains() {
  var librarySrc = '''
#library('mylib');
main() {}
''';
  var mainSrc = '''
#import('mylib.dart', prefix: 'mylib');
main() {
  mylib.main();
}
''';
  var expectedResult =
    'p_main(){}'
    'main(){p_main();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testStaticAccessIoLib() {
  var src = '''
#import('dart:io');

main() {
  Platform.operatingSystem;
}
''';
  var expectedResult = 'import "dart:io" as p;'
      'main(){p.Platform.operatingSystem;}';
  testDart2Dart(src,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testMinification() {
  var src = '''
class ClassWithVeryVeryLongName {}
main() {
  new ClassWithVeryVeryLongName();
}
''';
  var expectedResult =
      'class A{}'
      'main(){new A();}';
  testDart2Dart(src, continuation:
      (String result) { Expect.equals(expectedResult, result); }, minify: true);
}

testClosureLocalsMinified() {
  var src = '''
main() {
  var a = 7;
  void foo1(a,b) {
    void foo2(c,d) {
       var E = a;
    }
    foo2(b, a);
  }
  foo1(a, 8);
}
''';
  var expectedResult =
      'main(){var A=7; B(A,C){ D(E,F){var G=A;}D(C,A);}B(A,8);}';
  testDart2Dart(src, continuation:
      (String result) { Expect.equals(expectedResult, result); }, minify: true);
}

testParametersMinified() {
  var src = '''
class A {
  var a;
  static foo(arg1) {
    // Should not rename arg1 to a.
    arg1 = 5;
  }
}

fooglobal(arg,[optionalarg = 7]) {
  arg = 6;
}

main() {
  new A().a;
  A.foo(8);
  fooglobal(8);
}
''';
  var expectedResult =
      'class B{var E;static C(A){A=5;}}D(A,[optionalarg=7]){A=6;}'
      'main(){new B().E;B.C(8);D(8);}';
  testDart2Dart(src, continuation:
      (String result) { Expect.equals(expectedResult, result); }, minify: true);
}

testDeclarationTypePlaceholders() {
  var src = '''
String globalfield;
const String globalconstfield;

void foo(String arg) {}

main() {
  String localvar;
  foo("5");
}
''';
  var expectedResult =
      ' foo( arg){}main(){var localvar;foo("5");}';
  testDart2Dart(src,
      continuation: (String result) { Expect.equals(expectedResult, result); },
      stripTypes: true);
}

testPlatformLibraryMemberNamesAreFixed() {
  var src = '''
#import('dart:html');

class A {
  static String get userAgent => window.navigator.userAgent;
}

main() {
  A.userAgent;
}
''';
  var expectedResult = 'import "dart:html" as p;'
      'class A{static String get p_userAgent=>p.window.navigator.userAgent;}'
      'main(){A.p_userAgent;}';
  testDart2Dart(src,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testConflictsWithCoreLib() {
  var src = '''
import 'dart:core' as fisk;

print(x) { throw 'fisk'; }

main() {
  fisk.print('corelib');
  print('local');
}
''';
  var expectedResult = "p_print(x){throw 'fisk';}"
      "main(){print('corelib');p_print('local');}";
  testDart2Dart(src,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

main() {
  testSimpleFileUnparse();
  testTopLevelField();
  testSimpleTopLevelClass();
  testClassWithSynthesizedConstructor();
  testClassWithMethod();
  testExtendsImplements();
  testVariableDefinitions();
  testGetSet();
  testAbstractClass();
  testConflictSendsRename();
  testNoConflictSendsRename();
  testConflictLibraryClassRename();
  testDefaultClassWithArgs();
  testClassExtendsWithArgs();
  testStaticInvocation();
  testLibraryGetSet();
  testFieldTypeOutput();
  testDefaultClassNamePlaceholder();
  testTypeVariablesAreRenamed();
  testClassTypeArgumentBound();
  testDoubleMains();
  testStaticAccessIoLib();
  testLocalFunctionPlaceholder();
  testMinification();
  testClosureLocalsMinified();
  testParametersMinified();
  testDeclarationTypePlaceholders();
  testPlatformLibraryMemberNamesAreFixed();
  testConflictsWithCoreLib();
}
