// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:async';
import "package:async_helper/async_helper.dart";
import '../mock_compiler.dart';
import '../mock_libraries.dart';
import 'package:compiler/compiler.dart';
import 'package:compiler/implementation/dart2jslib.dart' as leg;
import 'package:compiler/implementation/dart_backend/dart_backend.dart';
import 'package:compiler/implementation/elements/elements.dart';
import 'package:compiler/implementation/tree/tree.dart';

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

/**
 * Library name is assumed to be 'mylib' in 'mylib.dart' file.
 */
testDart2Dart(String mainSrc, {String librarySrc,
                               String expectedResult,
                               bool minify: false,
                               bool stripTypes: false}) {

  // If expectedResult is not provided, check that source string remains the
  // same.
  if (expectedResult == null) {
    Expect.equals(null, librarySrc);
    expectedResult = mainSrc;
  }

  fileUri(path) => new Uri(scheme: 'file', path: path);

  final scriptUri = fileUri('script.dart');
  final libUri = fileUri('mylib.dart');

  provider(uri) {
    if (uri == scriptUri) return new Future.value(mainSrc);
    if (uri.toString() == libUri.toString()) {
      return new Future.value(librarySrc);
    }
    if (uri.path.endsWith('/core.dart')) {
      return new Future.value(buildLibrarySource(DEFAULT_CORE_LIBRARY));
    } else if (uri.path.endsWith('/core_patch.dart')) {
      return new Future.value(DEFAULT_PATCH_CORE_SOURCE);
    } else if (uri.path.endsWith('/io.dart')) {
      return new Future.value(ioLib);
    } else if (uri.path.endsWith('/js_helper.dart')) {
      return new Future.value(buildLibrarySource(DEFAULT_JS_HELPER_LIBRARY));
    } else if (uri.path.endsWith('/html_dart2js.dart')) {
      // TODO(smok): The file should change to html_dartium at some point.
      return new Future.value(htmlLib);
    } else if (uri.path.endsWith('/foreign_helper.dart')) {
      return new Future.value(
          buildLibrarySource(DEFAULT_FOREIGN_HELPER_LIBRARY));
    } else if (uri.path.endsWith('/isolate_helper.dart')) {
      return new Future.value(
          buildLibrarySource(DEFAULT_ISOLATE_HELPER_LIBRARY));
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

  asyncTest(() {
    return compile(
        scriptUri,
        fileUri('libraryRoot/'),
        fileUri('packageRoot/'),
        provider,
        handler,
        options).then((s) {
      Expect.equals(expectedResult, s);
    });
  });
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
  testDart2Dart(src, expectedResult: '''
should_be_kept() {}
main() {
  should_be_kept();
}
''');
}
testTopLevelField() {
  testDart2Dart('''
final String x = "asd";
main() {
  x;
}
''');
}

testSimpleTopLevelClass() {
  testDart2Dart('''
main() {
  new A();
}
class A {
  A() {}
}
''');
}

testClassWithSynthesizedConstructor() {
  testDart2Dart('''
main() {
  new A();
}
class A {}
''');
}

testClassWithMethod() {
  testDart2Dart(r'''
main() {
  var a = new A();
  a.foo();
}
class A {
  void foo() {}
}
''');
}

testExtendsImplements() {
  testDart2Dart('''
main() {
  new B<Object>();
}
class A<T> {}
class B<T> extends A<T> {}
''');
}

testVariableDefinitions() {
  testDart2Dart('''
main() {
  var x, y;
  final String s = null;
}
''');
  testDart2Dart('''
main() {
  final int x = 0, y = 0;
  final String s = null;
}
''');
  testDart2Dart('''
foo(f, g) {}
main() {
  foo(1, 2);
}
''');
  testDart2Dart('''
foo(f(arg)) {}
main() {
  foo(main);
}
''');
  // A couple of static/finals inside a class.
  testDart2Dart('''
main() {
  A.a;
  A.b;
}
class A {
  static const String a = "5";
  static const String b = "4";
}
''');
  // Class member of typedef-ed function type.
  // Maybe typedef should be included in the result too, but it
  // works fine without it.
  testDart2Dart('''
typedef void foofunc(arg);
main() {
  new A((arg) {});
}
class A {
  A(foofunc this.handler);
  final foofunc handler;
}
''');
}

testGetSet() {
  // Top-level get/set.
  testDart2Dart('''
set foo(arg) {}
get foo {
  return 5;
}
main() {
  foo;
  foo = 5;
}
''');
  // Field get/set.
  testDart2Dart('''
main() {
  var a = new A();
  a.foo;
  a.foo = 5;
}
class A {
  set foo(a) {}
  get foo {
    return 5;
  }
}
''');
  // Typed get/set.
  testDart2Dart('''
String get foo {
  return "a";
}
main() {
  foo;
}
''');
}

testAbstractClass() {
  testDart2Dart('''
main() {
  A.foo;
}
abstract class A {
  static final num foo = 0;
}
''');
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
  var expectedResult = '''
globalfoo_A() {}
var globalVar_A;
var globalVarInitialized_A = 6;
var globalVarInitialized2_A = 7;
class A_A {
  A_A() {}
  A_A.fromFoo_A() {}
  static staticfoo_A() {}
  foo() {}
  static const field_A = 5;
}
globalfoo() {}
var globalVar;
var globalVarInitialized = 6;
var globalVarInitialized2 = 7;
class A {
  A() {}
  A.fromFoo() {}
  static staticfoo() {}
  foo() {}
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
  globalVar_A;
  globalVarInitialized_A;
  globalVarInitialized2_A;
  globalfoo_A();
  A_A.field_A;
  A_A.staticfoo_A();
  new A_A();
  new A_A.fromFoo_A();
  new A_A().foo();
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
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
  var expectedResult = '''
globalfoo() {}
class A {
  A() {}
  A.fromFoo() {}
  static staticfoo() {}
  foo() {}
  static const field = 5;
}
myglobalfoo() {}
class MyA {
  MyA() {}
  MyA.myfromFoo() {}
  static mystaticfoo() {}
  myfoo() {}
  static const myfield = 5;
}
main() {
  myglobalfoo();
  MyA.myfield;
  MyA.mystaticfoo();
  new MyA();
  new MyA.myfromFoo();
  new MyA().myfoo();
  globalfoo();
  A.field;
  A.staticfoo();
  new A();
  new A.fromFoo();
  new A().foo();
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
}

testConflictLibraryClassRename() {
  var librarySrc = '''
library mylib;

topfoo() {}

class A {
  foo() {}
}
''';
  var mainSrc = '''
import 'mylib.dart' as mylib;
topfoo() {
  var x = 5;
}
class A {
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
  var expectedResult = '''
topfoo_A() {}
class A {
  foo() {}
}
topfoo() {
  var x = 5;
}
class A_A {
  num foo() {}
  A_A.fromFoo() {}
  A myliba;
  List<A_A> mylist;
}
A getA() => null;
main() {
  var a = new A();
  a.foo();
  var b = new A_A.fromFoo();
  b.foo();
  var GREATVAR = b.myliba;
  b.mylist;
  a = getA();
  topfoo();
  topfoo_A();
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
}

testClassExtendsWithArgs() {
  testDart2Dart('''
main() {
  new B<Object>();
}
class A<T extends Object> {}
class B<T extends Object> extends A<T> {}
''');
}

testStaticInvocation() {
  testDart2Dart('''
main() {
  var x = double.parseDouble("1");
}
''');
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
  var expectedResult = '''
get topgetset_A => 5;
set topgetset_A(arg) {}
get topgetset => 6;
set topgetset(arg) {}
main() {
  topgetset;
  topgetset = 6;
  topgetset_A;
  topgetset_A = 5;
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
}

testFieldTypeOutput() {
  testDart2Dart('''
main() {
  new A().field;
}
class B {}
class A {
  B field;
}
''');
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
    FunctionExpression mainNode = mainElement.node;
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
  var expectedResult = '''
typedef void MyFunction_A<T_B extends num>(T_B arg);
class T_A {}
class B_A<T_B> {}
class A_A<T_B> extends B_A<T_B> {
  T_B f;
}
typedef void MyFunction<T_B extends num>(T_B arg);
class T {}
class B<T_B> {}
class A<T_B> extends B<T_B> {
  T_B f;
}
main() {
  MyFunction myf1;
  MyFunction_A myf2;
  new A<int>().f;
  new T();
  new A_A<int>().f;
  new T_A();
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
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
  var expectedResult = '''
class I_A {}
class A_A<T extends I_A> {}
class I {}
class A<T extends I> {}
main() {
  new A();
  new A_A();
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
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
  var expectedResult = '''
main_A() {}
main() {
  main_A();
}
''';
  testDart2Dart(mainSrc, librarySrc: librarySrc,
      expectedResult: expectedResult);
}

testStaticAccessIoLib() {
  var src = '''
import 'dart:io';

main() {
  Platform.operatingSystem;
}
''';
  var expectedResult = '''
import "dart:io";
main() {
  Platform.operatingSystem;
}
''';
  testDart2Dart(src, expectedResult: expectedResult);
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
  testDart2Dart(src, expectedResult: expectedResult, minify: true);
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
  testDart2Dart(src, expectedResult: expectedResult, minify: true);
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
  testDart2Dart(src, expectedResult: expectedResult, minify: true);
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
  var expectedResult = '''
foo( arg) {}
main() {
  var localvar;
  foo("5");
}
''';
  testDart2Dart(src, expectedResult: expectedResult, stripTypes: true);
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
  var expectedResult = '''
import "dart:html";
class A {
  static String get userAgent_A => window.navigator.userAgent;
}
main() {
  A.userAgent_A;
}
''';
  testDart2Dart(src, expectedResult: expectedResult);
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
  var expectedResult = """
print_A(x) {
  throw 'fisk';
}
main() {
  print('corelib');
  print_A('local');
}
""";
  testDart2Dart(src, expectedResult: expectedResult);
}

testUnresolvedNamedConstructor1() {
  var src = '''
class A {
}

main() {
  new A.named();
}
''';
  var expectedResult = """
main() {
  new Unresolved();
}
""";
  testDart2Dart(src, expectedResult: expectedResult);
}

testUnresolvedNamedConstructor2() {
  var src = '''
class A {
  A() {}
}

main() {
  new A();
  new A.named();
}
''';
  var expectedResult = """
class A {
  A() {}
}
main() {
  new A();
  new Unresolved();
}
""";
  testDart2Dart(src, expectedResult: expectedResult);
}

testUnresolvedNamedConstructor3() {
  var src = '''
class A {
  static method() {}
}

main() {
  A.method();
  new A.named();
}
''';
  var expectedResult = """
class A {
  static method() {}
}
main() {
  A.method();
  new Unresolved();
}
""";
  testDart2Dart(src, expectedResult: expectedResult);
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
  testUnresolvedNamedConstructor1();
  testUnresolvedNamedConstructor2();
  testUnresolvedNamedConstructor3();
}
