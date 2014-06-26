// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import "package:async_helper/async_helper.dart";
import 'mock_compiler.dart';
import 'package:compiler/compiler.dart';
import 'package:compiler/implementation/dart2jslib.dart' as leg;
import 'package:compiler/implementation/dart_backend/dart_backend.dart';
import 'package:compiler/implementation/elements/elements.dart';
import 'package:compiler/implementation/tree/tree.dart';

const coreLib = r'''
library corelib;
class Object {
  Object();
}
class bool {}
class num {}
class int extends num {}
class double extends num {}
abstract class String {}
class Function {}
class List<T> {}
class Map<K,V> {}
class BoundClosure {}
class Closure {}
class Dynamic_ {}
class Null {}
class TypeError {}
class Type {}
class StackTrace {}
class LinkedHashMap {
  factory LinkedHashMap._empty() => null;
  factory LinkedHashMap._literal(elements) => null;
}
class Math {
  static double parseDouble(String s) => 1.0;
}
print(x) {}
identical(a, b) => true;
const proxy = 0;
''';

const corePatch = r'''
import 'dart:_js_helper';
import 'dart:_interceptors';
import 'dart:_isolate_helper';
import 'dart:_foreign_helper';
''';

const ioLib = r'''
library io;
class Platform {
  static int operatingSystem;
}
''';

const htmlLib = r'''
library html;
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
library js_helper;
class JSInvocationMirror {}
assertHelper(a) {}
class Closure {}
class BoundClosure {}
const patch = 0;
''';

const foreignLib = r'''
var JS;
''';

const isolateHelperLib = r'''
class _WorkerStub {
}
''';

testDart2Dart(String src, {void continuation(String s), bool minify: false,
    bool stripTypes: false}) {
  // If continuation is not provided, check that source string remains the same.
  if (continuation == null) {
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
  fileUri(path) => new Uri(scheme: 'file', path: path);

  final scriptUri = fileUri('script.dart');
  final libUri = fileUri('mylib.dart');

  provider(uri) {
    if (uri == scriptUri) return new Future.value(srcMain);
    if (uri.toString() == libUri.toString()) {
      return new Future.value(srcLibrary);
    }
    if (uri.path.endsWith('/core.dart')) {
      return new Future.value(coreLib);
    } else if (uri.path.endsWith('/core_patch.dart')) {
      return new Future.value(corePatch);
    } else if (uri.path.endsWith('/io.dart')) {
      return new Future.value(ioLib);
    } else if (uri.path.endsWith('/js_helper.dart')) {
      return new Future.value(helperLib);
    } else if (uri.path.endsWith('/html_dart2js.dart')) {
      // TODO(smok): The file should change to html_dartium at some point.
      return new Future.value(htmlLib);
    } else if (uri.path.endsWith('/foreign_helper.dart')) {
      return new Future.value(foreignLib);
    } else if (uri.path.endsWith('/isolate_helper.dart')) {
      return new Future.value(isolateHelperLib);
    }
    return new Future.value('');
  }

  handler(uri, begin, end, message, kind) {
    if (identical(kind, Diagnostic.ERROR) || identical(kind, Diagnostic.CRASH)) {
      Expect.fail('$uri: $begin-$end: $message [$kind]');
    }
  }

  final options = <String>['--output-type=dart'];
  // Some tests below are using dart:io.
  options.add('--categories=Client,Server');
  if (minify) options.add('--minify');
  if (stripTypes) options.add('--force-strip=types');

  asyncTest(() => compile(
      scriptUri,
      fileUri('libraryRoot/'),
      fileUri('packageRoot/'),
      provider,
      handler,
      options).then(continuation));
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
  testDart2Dart(r'main(){var a=new A();a.foo();}class A{void foo(){}}');
}

testExtendsImplements() {
  testDart2Dart('main(){new B<Object>();}'
      'class A<T>{}class B<T> extends A<T>{}');
}

testVariableDefinitions() {
  testDart2Dart('main(){var x,y;final String s=null;}');
  testDart2Dart('main(){final int x=0,y=0;final String s=null;}');
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
  testDart2Dart('main(){A.foo;}abstract class A{static final num foo=0;}');
}

testConflictSendsRename() {
  // Various Send-s to current library and external library. Verify that
  // everything is renamed correctly in conflicting class names and global
  // functions.
  var librarySrc = '''
library mylib;

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
import 'mylib.dart' as mylib;

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
      'var globalVarInitialized=6;var globalVarInitialized2=7;'
      'class A{A(){}A.fromFoo(){}static staticfoo(){}foo(){}'
          'static const field=5;}'
      'A_globalfoo(){}'
      'var A_globalVar;var A_globalVarInitialized=6;'
          'var A_globalVarInitialized2=7;'
      'class A_A{A_A(){}A_A.A_fromFoo(){}static A_staticfoo(){}foo(){}'
          'static const A_field=5;}'
      'main(){A_globalVar;A_globalVarInitialized;'
         'A_globalVarInitialized2;A_globalfoo();'
         'A_A.A_field;A_A.A_staticfoo();'
         'new A_A();new A_A.A_fromFoo();new A_A().foo();'
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
library mylib;

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
import 'mylib.dart' as mylib;

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
library mylib;

topfoo() {}

class A {
  foo(){}
}
''';
  var mainSrc = '''
import 'mylib.dart' as mylib;


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
    'A_topfoo(){var x=5;}'
    'class A_A{num foo(){}A_A.fromFoo(){}A myliba;List<A_A> mylist;}'
    'A getA()=>null;'
    'main(){var a=new A();a.foo();var b=new A_A.fromFoo();b.foo();'
        'var GREATVAR=b.myliba;b.mylist;a=getA();A_topfoo();topfoo();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
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
library mylib;

get topgetset => 5;
set topgetset(arg) {}
''';
  var mainSrc = '''
import 'mylib.dart' as mylib;

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
    'get A_topgetset=>6;'
    'set A_topgetset(arg){}'
    'main(){A_topgetset;A_topgetset=6;topgetset;topgetset=5;}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testFieldTypeOutput() {
  testDart2Dart('main(){new A().field;}class B{}class A{B field;}');
}

class DynoMap implements Map<Element, ElementAst> {
  final compiler;
  DynoMap(this.compiler);

  ElementAst operator[](Element element) => new ElementAst(element);

  noSuchMethod(Invocation invocation) => throw 'unimplemented method';
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
  MockCompiler compiler = new MockCompiler.internal(emitJavaScript: false);
  asyncTest(() => compiler.init().then((_) {
    assert(compiler.backend is DartBackend);
    compiler.parseScript(src);
    FunctionElement mainElement = compiler.mainApp.find(leg.Compiler.MAIN);
    compiler.processQueue(compiler.enqueuer.resolution, mainElement);
    PlaceholderCollector collector = collectPlaceholders(compiler, mainElement);
    FunctionExpression mainNode = mainElement.parseNode(compiler);
    Block body = mainNode.body;
    FunctionDeclaration functionDeclaration = body.statements.nodes.head;
    FunctionExpression fooNode = functionDeclaration.function;
    LocalPlaceholder fooPlaceholder =
        collector.functionScopes[mainElement].localPlaceholders.first;
    Expect.isTrue(fooPlaceholder.nodes.contains(fooNode.name));
  }));
}

testTypeVariablesAreRenamed() {
  // Somewhat a hack: we require all the references of the identifier
  // to be renamed in the same way for the whole library. Hence
  // if we have a class and type variable with the same name, they
  // both should be renamed.
  var librarySrc = '''
library mylib;
typedef void MyFunction<T extends num>(T arg);
class T {}
class B<T> {}
class A<T> extends B<T> { T f; }
''';
  var mainSrc = '''
import 'mylib.dart' as mylib;
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
    'typedef void A_MyFunction<A_T extends num>(A_T arg);'
    'class A_T{}'
    'class A_B<A_T>{}'
    'class A_A<A_T> extends A_B<A_T>{A_T f;}'
    'main(){A_MyFunction myf1;MyFunction myf2;new A_A<int>().f;'
        'new A_T();new A<int>().f;new T();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testClassTypeArgumentBound() {
  var librarySrc = '''
library mylib;

class I {}
class A<T extends I> {}

''';
  var mainSrc = '''
import 'mylib.dart' as mylib;

class I {}
class A<T extends I> {}

main() {
  new A();
  new mylib.A();
}
''';
  var expectedResult =
    'class I{}'
    'class A<T extends I>{}'
    'class A_I{}'
    'class A_A<A_T extends A_I>{}'
    'main(){new A_A();new A();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testDoubleMains() {
  var librarySrc = '''
library mylib;
main() {}
''';
  var mainSrc = '''
import 'mylib.dart' as mylib;
main() {
  mylib.main();
}
''';
  var expectedResult =
    'A_main(){}'
    'main(){A_main();}';
  testDart2DartWithLibrary(mainSrc, librarySrc,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testStaticAccessIoLib() {
  var src = '''
import 'dart:io';

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

fooglobal(arg,{optionalarg: 7}) {
  arg = 6;
}

main() {
  new A().a;
  A.foo(8);
  fooglobal(8);
}
''';
  var expectedResult =
      'class B{var E;static C(A){A=5;}}D(A,{optionalarg: 7}){A=6;}'
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
import 'dart:html';

class A {
  static String get userAgent => window.navigator.userAgent;
}

main() {
  A.userAgent;
}
''';
  var expectedResult = 'import "dart:html" as p;'
      'class A{static String get A_userAgent=>p.window.navigator.userAgent;}'
      'main(){A.A_userAgent;}';
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
  var expectedResult = "A_print(x){throw 'fisk';}"
      "main(){print('corelib');A_print('local');}";
  testDart2Dart(src,
      continuation: (String result) { Expect.equals(expectedResult, result); });
}

testUnresolvedNamedConstructor() {
  var src = '''
class A {
  A() {}
}

main() {
  new A();
  new A.named();
}
''';
  var expectedResult = "class A{A(){}}main(){new A();new A_Unresolved();}";
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
  testClassExtendsWithArgs();
  testStaticInvocation();
  testLibraryGetSet();
  testFieldTypeOutput();
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
  testUnresolvedNamedConstructor();
}
