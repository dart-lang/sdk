// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.completion.support;

import 'dart:collection';

import 'completion_test_support.dart';

main() {
  CompletionTestBuilder builder = new CompletionTestBuilder();
  builder.buildAll();
}

/**
 * A builder that builds the completion tests.
 */
class CompletionTestBuilder {
  void buildAll() {
    buildNumberedTests();
    buildCommentSnippetTests();
    buildCompletionTests();
    buildOtherTests();
    buildLibraryTests();
  }

  void buildCommentSnippetTests() {
    CompletionTestCase.buildTests('testCommentSnippets001', '''
class X {static final num MAX = 0;num yc,xc;mth() {xc = yc = MA!1X;x!2c.abs();num f = M!3AX;}}''',
        <String>["1+MAX", "2+xc", "3+MAX"]);

    CompletionTestCase.buildTests('testCommentSnippets002', '''
class Y {String x='hi';mth() {x.l!1ength;int n = 0;x!2.codeUnitAt(n!3);}}''',
        <String>["1+length", "2+x", "3+n"]);

    CompletionTestCase.buildTests('testCommentSnippets004', '''
class A {!1int x; !2mth() {!3int y = this.!5x!6;}}class B{}''',
        <String>["1+A", "2+B", "3+x", "3-y", "5+mth", "6+x"],
        failingTests: '3');

    CompletionTestCase.buildTests('testCommentSnippets005', '''
class Date { static Date JUN, JUL;}class X { m() { return Da!1te.JU!2L; }}''',
        <String>["1+Date", "2+JUN", "2+JUL"]);

    CompletionTestCase.buildTests('testCommentSnippets007', '''
class C {mth(Map x, !1) {}mtf(!2, Map x) {}m() {for (in!3t i=0; i<5; i++); A!4 x;}}class int{}class Arrays{}class bool{}''',
        <String>["1+bool", "2+bool", "3+int", "4+Arrays"], failingTests: '3');

    CompletionTestCase.buildTests('testCommentSnippets008', '''
class Date{}final num M = Dat!1''', <String>["1+Date"]);

    // space, char, eol are important
    CompletionTestCase.buildTests('testCommentSnippets009', '''
class Map{}class Maps{}class x extends!5 !2M!3 !4implements!6 !1\n{}''',
        <String>[
            "1+Map",
            "2+Maps",
            "3+Maps",
            "4-Maps",
            "4+implements",
            "5-Maps",
            "6-Map",
            "6+implements"],
        failingTests: '46');

    // space, char, eol are important
    CompletionTestCase.buildTests('testCommentSnippets010', '''
class Map{}class x implements !1{}''', <String>["1+Map"], failingTests: '1');

    // space, char, eol are important
    CompletionTestCase.buildTests('testCommentSnippets011', '''
class Map{}class x implements M!1{}''', <String>["1+Map"], failingTests: '1');

    // space, char, eol are important
    CompletionTestCase.buildTests('testCommentSnippets012', '''
class Map{}class x implements M!1\n{}''', <String>["1+Map"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets013', '''
class num{}class x !2{!1}!3''',
        <String>["1+num", "2-num", "3-num"],
        failingTests: '1');

    // trailing space is important
    CompletionTestCase.buildTests('testCommentSnippets014', '''
class num{}typedef n!1 ;''', <String>["1+num"]);

    CompletionTestCase.buildTests('testCommentSnippets015', '''
class D {f(){} g(){f!1(f!2);}}''', <String>["1+f", "2+f"]);

    CompletionTestCase.buildTests('testCommentSnippets016', '''
class F {m() { m(); !1}}''', <String>["1+m"]);

    CompletionTestCase.buildTests('testCommentSnippets017', '''
class F {var x = !1false;}''', <String>["1+true"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets018', '''
class Map{}class Arrays{}class C{ m(!1){} n(!2 x, q)''',
        <String>["1+Map", "1-void", "1-null", "2+Arrays", "2-void", "2-null"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets019', '''
class A{m(){Object x;x.!1/**/clear()''',
        <String>["1+toString"]);

    CompletionTestCase.buildTests('testCommentSnippets020', '''
classMap{}class tst {var newt;void newf(){}test() {var newz;new!1/**/;}}''',
        <String>["1+newt", "1+newf", "1+newz", "1-Map"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets021', '''
class Map{}class tst {var newt;void newf(){}test() {var newz;new !1/**/;}}''',
        <String>["1+Map", "1-newt"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets022', '''
class Map{}class F{m(){new !1;}}''', <String>["1+Map"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets022a', '''
class Map{}class F{m(){new !1''', <String>["1+Map"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets022b', '''
class Map{factory Map.qq(){return null;}}class F{m(){new Map.!1qq();}}''',
        <String>["1+qq"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets023', '''
class X {X c; X(this.!1c!3) : super() {c.!2}}''',
        <String>["1+c", "2+c", "3+c"]);

    CompletionTestCase.buildTests('testCommentSnippets024', '''
class q {m(Map q){var x;m(!1)}n(){var x;n(!2)}}''', <String>["1+x", "2+x"]);

    CompletionTestCase.buildTests('testCommentSnippets025', '''
class q {num m() {var q; num x=!1 q!3 + !2/**/;}}''',
        <String>["1+q", "2+q", "3+q"],
        failingTests: '123');

    CompletionTestCase.buildTests('testCommentSnippets026', '''
class List{}class a implements !1{}''', <String>["1+List"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets027', '''
class String{}class List{}class test <X extends !1String!2> {}''',
        <String>["1+List", "2+String", "2-List"],
        failingTests: '12');

    CompletionTestCase.buildTests('testCommentSnippets028', '''
class String{}class List{}class DateTime{}typedef T Y<T extends !1>(List input);''',
        <String>["1+DateTime", "1+String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets029', '''
interface A<X> default B<X extends !1List!2> {}''',
        <String>["1+DateTime", "2+List"]);

    CompletionTestCase.buildTests('testCommentSnippets030', '''
class Bar<T extends Foo> {const Bar(!1T!2 k);T!3 m(T!4 a, T!5 b){}final T!6 f = null;}''',
        <String>["1+T", "2+T", "3+T", "4+T", "5+T", "6+T"],
        failingTests: '123456');

    CompletionTestCase.buildTests('testCommentSnippets031', '''
class Bar<T extends Foo> {m(x){if (x is !1) return;if (x is!!!2)}}''',
        <String>["1+Bar", "1+T", "2+T", "2+Bar"],
        failingTests: '12');

    CompletionTestCase.buildTests('testCommentSnippets032', '''
class Fit{}class Bar<T extends Fooa> {const F!1ara();}''',
        <String>["1+Fit", "1+Fara", "1-Bar"]);

    // Type propagation
    CompletionTestCase.buildTests('testCommentSnippets033', '''
class List{add(){}length(){}}t1() {var x;if (x is List) {x.!1add(3);}}''',
        <String>["1+add", "1+length"]);

    // Type propagation
    CompletionTestCase.buildTests('testCommentSnippets035', '''
class List{clear(){}length(){}}t3() {var x=new List(), y=x.!1length();x.!2clear();}''',
        <String>["1+length", "2+clear"]);

    CompletionTestCase.buildTests('testCommentSnippets036', '''
class List{}t3() {var x=new List!1}''', <String>["1+List"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets037', '''
class List{factory List.from(){}}t3() {var x=new List.!1}''',
        <String>["1+from"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets038', '''
f(){int xa; String s = '\$x!1';}''', <String>["1+xa"]);

    CompletionTestCase.buildTests('testCommentSnippets038a', '''
int xa; String s = '\$x!1\'''', <String>["1+xa"]);

    CompletionTestCase.buildTests('testCommentSnippets039', '''
f(){int xa; String s = '\$!1';}''', <String>["1+xa"]);

    CompletionTestCase.buildTests('testCommentSnippets039a', '''
int xa; String s = '\$!1\'''', <String>["1+xa"]);

    CompletionTestCase.buildTests('testCommentSnippets040', '''
class List{add(){}}class Map{}class X{m(){List list; list.!1 Map map;}}''',
        <String>["1+add"]);

    CompletionTestCase.buildTests('testCommentSnippets041', '''
class List{add(){}length(){}}class X{m(){List list; list.!1 zox();}}''',
        <String>["1+add"]);

    CompletionTestCase.buildTests('testCommentSnippets042', '''
class DateTime{static const int WED=3;int get day;}fd(){DateTime d=new DateTime.now();d.!1WED!2;}''',
        <String>["1+day", "2-WED"]);

    CompletionTestCase.buildTests('testCommentSnippets043', '''
class L{var k;void.!1}''', <String>["1-k"]);

    CompletionTestCase.buildTests('testCommentSnippets044', '''
class List{}class XXX {XXX.fisk();}main() {main(); new !1}}''',
        <String>["1+List", "1+XXX.fisk"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets047', '''
f(){int x;int y=!1;}''', <String>["1+x"]);

    CompletionTestCase.buildTests('testCommentSnippets048', '''
import 'dart:convert' as json;f() {var x=new js!1}''',
        <String>["1+json"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets049', '''
import 'dart:convert' as json;
import 'dart:convert' as jxx;
class JsonParserX{}
f1() {var x=new !2j!1s!3}''',
        <String>[
            "1+json",
            "1+jxx",
            "2+json",
            "2+jxx",
            "2-JsonParser",
            "3+json",
            "3-jxx"],
        failingTests: '123');

    CompletionTestCase.buildTests('testCommentSnippets050', '''
class xdr {
  xdr();
  const xdr.a(a,b,c);
  xdr.b();
  f() => 3;
}
class xa{}
k() {
  new x!1dr().f();
  const x!2dr.!3a(1, 2, 3);
}''',
        <String>[
            "1+xdr",
            "1+xa",
            "1+xdr.a",
            "1+xdr.b",
            "2-xa",
            "2-xdr",
            "2+xdr.a",
            "2-xdr.b",
            "3-b",
            "3+a"],
        failingTests: '123');

    // Type propagation.
    CompletionTestCase.buildTests('testCommentSnippets051', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  var v;
  if (v is String) {
    v.!1length;
    v.!2getKeys;
  }
}''', <String>["1+length", "2-getKeys"], failingTests: '1');

    // Type propagation.
    CompletionTestCase.buildTests('testCommentSnippets052', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  List<String> values = ['a','b','c'];
  for (var v in values) {
    v.!1toUpperCase;
    v.!2getKeys;
  }
}''', <String>["1+toUpperCase", "2-getKeys"], failingTests: '1');

    // Type propagation.
    CompletionTestCase.buildTests('testCommentSnippets053', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  var v;
  while (v is String) {
    v.!1toUpperCase;
    v.!2getKeys;
  }
}''', <String>["1+toUpperCase", "2-getKeys"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets054', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  var v;
  for (; v is String; v.!1isEmpty) {
    v.!2toUpperCase;
    v.!3getKeys;
  }
}''', <String>["1+isEmpty", "2+toUpperCase", "3-getKeys"], failingTests: '12');

    CompletionTestCase.buildTests('testCommentSnippets055', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r() {
  String v;
  if (v is Object) {
    v.!1toUpperCase;
  }
}''', <String>["1+toUpperCase"]);

    // Type propagation.
    CompletionTestCase.buildTests('testCommentSnippets056', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void f(var v) {
  if (v is!! String) {
    return;
  }
  v.!1toUpperCase;
}''', <String>["1+toUpperCase"], failingTests: '1');

    // Type propagation.
    CompletionTestCase.buildTests('testCommentSnippets057', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void f(var v) {
  if ((v as String).length == 0) {
    v.!1toUpperCase;
  }
}''', <String>["1+toUpperCase"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets058', '''
typedef vo!2id callback(int k);
void x(callback q){}
void r() {
  callback v;
  x(!1);
}''', <String>["1+v", "2+void"], failingTests: '2');

    CompletionTestCase.buildTests('testCommentSnippets059', '''
f(){((int x) => x+4).!1call(1);}''', <String>["1-call"]);

    CompletionTestCase.buildTests('testCommentSnippets060', '''
class Map{}
abstract class MM extends Map{factory MM() => new Map();}
class Z {
  MM x;
  f() {
    x!1
  }
}''', <String>["1+x", "1-x[]"]);

    CompletionTestCase.buildTests('testCommentSnippets061', '''
class A{m(){!1f(3);!2}}n(){!3f(3);!4}f(x)=>x*3;''',
        <String>["1+f", "1+n", "2+f", "2+n", "3+f", "3+n", "4+f", "4+n"]);

    // Type propagation.
    CompletionTestCase.buildTests('testCommentSnippets063', '''
class String{int length(){} String toUpperCase(){} bool isEmpty(){}}class Map{getKeys(){}}
void r(var v) {
  v.!1toUpperCase;
  assert(v is String);
  v.!2toUpperCase;
}''', <String>["1-toUpperCase", "2+toUpperCase"], failingTests: '2');

    CompletionTestCase.buildTests('testCommentSnippets064', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.!9h()..!1a()..!2b().!7g();
    x.!8j..!3b()..!4c..!6c..!5a();
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''',
        <String>[
            "1+a",
            "2+b",
            "1-g",
            "2-h",
            "3+b",
            "4+c",
            "5+a",
            "6+c",
            "7+g",
            "8+j",
            "9+h"]);

    CompletionTestCase.buildTests('testCommentSnippets065', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..!1;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''', <String>["1+a"]);

    CompletionTestCase.buildTests('testCommentSnippets066', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..!1;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''', <String>["1+b"]);

    CompletionTestCase.buildTests('testCommentSnippets067', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.h()..a()..c..!1;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''', <String>["1+b"]);

    CompletionTestCase.buildTests('testCommentSnippets068', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.j..b()..c..!1;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''', <String>["1+c"]);

    CompletionTestCase.buildTests('testCommentSnippets069', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.j..b()..!1;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''', <String>["1+c"]);

    CompletionTestCase.buildTests('testCommentSnippets070', '''
class Spline {
  Line c;
  Spline a() {
    return this;
  }
  Line b() {
    return null;
  }
  Spline f() {
    Line x = new Line();
    x.j..!1;
  }
}
class Line {
  Spline j;
  Line g() {
    return this;
  }
  Spline h() {
    return null;
  }
}''', <String>["1+b"]);

    CompletionTestCase.buildTests('testCommentSnippets072', '''
class X {
  int _p;
  set p(int x) => _p = x;
}
f() {
  X x = new X();
  x.!1p = 3;
}''', <String>["1+p"]);

    CompletionTestCase.buildTests('testCommentSnippets073', '''
class X {
  m() {
    JSON.stri!1;
    X f = null;
  }
}
class JSON {
  static stringify() {}
}''', <String>["1+stringify"]);

    CompletionTestCase.buildTests('testCommentSnippets074', '''
class X {
  m() {
    _x!1
  }
  _x1(){}
}''', <String>["1+_x1"]);

    CompletionTestCase.buildTests('testCommentSnippets075', '''
p(x)=>0;var E;f(q)=>!1p(!2E);''', <String>["1+p", "2+E"]);

    CompletionTestCase.buildTests('testCommentSnippets076', '''
class Map<K,V>{}class List<E>{}class int{}main() {var m=new Map<Lis!1t<Map<int,in!2t>>,List<!3int>>();}''',
        <String>["1+List", "2+int", "3+int"],
        failingTests: '123');

    CompletionTestCase.buildTests('testCommentSnippets076a', '''
class Map<K,V>{}class List<E>{}class int{}main() {var m=new Map<Lis!1t<Map<int,in!2t>>,List<!3>>();}''',
        <String>["1+List", "2+int", "3+int"],
        failingTests: '123');

    CompletionTestCase.buildTests('testCommentSnippets077', '''
class FileMode {
  static const READ = const FileMode._internal(0);
  static const WRITE = const FileMode._internal(1);
  static const APPEND = const FileMode._internal(2);
  const FileMode._internal(int this._mode);
  factory FileMode._internal1(int this._mode);
  factory FileMode(_mode);
  final int _mode;
}
class File {
  factory File(String path) => null;
  factory File.fromPath(Path path) => null;
}
f() => new Fil!1''',
        <String>[
            "1+File",
            "1+File.fromPath",
            "1+FileMode",
            "1+FileMode._internal1",
            "1+FileMode._internal"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets078', '''
class Map{static from()=>null;clear(){}}void main() { Map.!1 }''',
        <String>["1+from", "1-clear"]); // static method, instance method

    CompletionTestCase.buildTests('testCommentSnippets079', '''
class Map{static from()=>null;clear(){}}void main() { Map s; s.!1 }''',
        <String>["1-from", "1+clear"]); // static method, instance method

    CompletionTestCase.buildTests('testCommentSnippets080', '''
class RuntimeError{var message;}void main() { RuntimeError.!1 }''',
        <String>["1-message"]); // field

    CompletionTestCase.buildTests('testCommentSnippets081', '''
class Foo {this.!1}''', <String>["1-Object"]);

    CompletionTestCase.buildTests('testCommentSnippets082', '''
        class HttpRequest {}
        class HttpResponse {}
        main() {
          var v = (HttpRequest req, HttpResp!1)
        }''', <String>["1+HttpResponse"]);

    CompletionTestCase.buildTests('testCommentSnippets083', '''
main() {(.!1)}''', <String>["1-toString"]);

    CompletionTestCase.buildTests('testCommentSnippets083a', '''
main() { .!1 }''', <String>["1-toString"]);

    CompletionTestCase.buildTests('testCommentSnippets083b', '''
main() { null.!1 }''', <String>["1+toString"], failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets084', '''
class List{}class Map{}typedef X = !1Lis!2t with !3Ma!4p;''',
        <String>["1+Map", "2+List", "2-Map", "3+List", "4+Map", "4-List"],
        failingTests: '1234');

    CompletionTestCase.buildTests('testCommentSnippets085', '''
class List{}class Map{}class Z extends List with !1Ma!2p {}''',
        <String>["1+List", "1+Map", "2+Map", "2-List"],
        failingTests: '12');

    CompletionTestCase.buildTests('testCommentSnippets086', '''
class Q{f(){xy() {!2};x!1y();}}''',
        <String>["1+xy", "2+f", "2-xy"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets087', '''
class Map{}class Q extends Object with !1Map {}''',
        <String>["1+Map", "1-HashMap"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCommentSnippets088', '''
class A {
  int f;
  B m(){}
}
class B extends A {
  num f;
  A m(){}
}
class Z {
  B q;
  f() {q.!1}
}''', <String>["1+f", "1+m"]); // f->num, m()->A

    CompletionTestCase.buildTests('testCommentSnippets089', '''
class Q {
  fqe() {
    xya() {
      xyb() {
        !1
      }
      !3 xyb();
    };
    xza() {
      !2
    }
    xya();
    !4 xza();
  }
  fqi() {
    !5
  }
}''',
        <String>[
            "1+fqe",
            "1+fqi",
            "1+Q",
            "1-xya",
            "1-xyb",
            "1-xza",
            "2+fqe",
            "2+fqi",
            "2+Q",
            "2-xya",
            "2-xyb",
            "2-xza",
            "3+fqe",
            "3+fqi",
            "3+Q",
            "3-xya",
            "3+xyb",
            "3-xza",
            "4+fqe",
            "4+fqi",
            "4+Q",
            "4+xya",
            "4-xyb",
            "4+xza",
            "5+fqe",
            "5+fqi",
            "5+Q",
            "5-xya",
            "5-xyb",
            "5-xza"],
        failingTests: '34');

    CompletionTestCase.buildTests('testCommentSnippets090', '''
class X { f() { var a = 'x'; a.!1 }}''',
        <String>["1+length"],
        failingTests: '1');
  }

  void buildCompletionTests() {
    CompletionTestCase.buildTests('testCompletion_alias_field', '''
typedef int fnint(int k); fn!1int x;''', <String>["1+fnint"]);

    CompletionTestCase.buildTests('testCompletion_annotation_argumentList', '''
class AAA {",
  const AAA({int aaa, int bbb});",
}",
",
@AAA(!1)
main() {
}''',
        <String>["1+AAA" /*":" + ProposalKind.ARGUMENT_LIST*/, "1+aaa", "1+bbb"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_annotation_topLevelVar', '''
const fooConst = null;
final fooNotConst = null;
const bar = null;

@foo!1
main() {
}''', <String>["1+fooConst", "1-fooNotConst", "1-bar"]);

    CompletionTestCase.buildTests('testCompletion_annotation_type', '''
class AAA {
  const AAA({int a, int b});
  const AAA.nnn(int c, int d);
}
@AAA!1
main() {
}''',
        <String>[
            "1+AAA" /*":" + ProposalKind.CONSTRUCTOR*/,
            "1+AAA.nnn" /*":" + ProposalKind.CONSTRUCTOR*/],
        failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_annotation_type_inClass_withoutMember',
        '''
class AAA {
  const AAA();
}

class C {
  @A!1
}''', <String>["1+AAA" /*":" + ProposalKind.CONSTRUCTOR*/]);

    CompletionTestCase.buildTests('testCompletion_argument_typeName', '''
class Enum {
  static Enum FOO = new Enum();
}
f(Enum e) {}
main() {
  f(En!1);
}''', <String>["1+Enum"]);

    CompletionTestCase.buildTests('testCompletion_arguments_ignoreEmpty', '''
class A {
  test() {}
}
main(A a) {
  a.test(!1);
}''', <String>["1-test"]);

    CompletionTestCase.buildTests('testCompletion_as_asIdentifierPrefix', '''
main(p) {
  var asVisible;
  var v = as!1;
}''', <String>["1+asVisible"]);

    CompletionTestCase.buildTests(
        'testCompletion_as_asPrefixedIdentifierStart',
        '''
class A {
  var asVisible;
}

main(A p) {
  var v = p.as!1;
}''', <String>["1+asVisible"]);

    CompletionTestCase.buildTests('testCompletion_as_incompleteStatement', '''
class MyClass {}
main(p) {
  var justSomeVar;
  var v = p as !1
}''', <String>["1+MyClass", "1-justSomeVar"]);

    CompletionTestCase.buildTests('testCompletion_cascade', '''
class A {
  aaa() {}
}


main(A a) {
  a..!1 aaa();
}''', <String>["1+aaa", "1-main"]);

    CompletionTestCase.buildTests('testCompletion_combinator_afterComma', '''
"import 'dart:math' show cos, !1;''',
        <String>["1+PI", "1+sin", "1+Random", "1-String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_combinator_ended', '''
import 'dart:math' show !1;"''',
        <String>["1+PI", "1+sin", "1+Random", "1-String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_combinator_export', '''
export 'dart:math' show !1;"''',
        <String>["1+PI", "1+sin", "1+Random", "1-String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_combinator_hide', '''
import 'dart:math' hide !1;"''',
        <String>["1+PI", "1+sin", "1+Random", "1-String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_combinator_notEnded', '''
import 'dart:math' show !1"''',
        <String>["1+PI", "1+sin", "1+Random", "1-String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_combinator_usePrefix', '''
import 'dart:math' show s!1"''',
        <String>["1+sin", "1+sqrt", "1-cos", "1-String"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_constructor_field', '''
class X { X(this.field); int f!1ield;}''', <String>["1+field"]);

    CompletionTestCase.buildTests(
        'testCompletion_constructorArguments_showOnlyCurrent',
        '''
class A {
  A.first(int p);
  A.second(double p);
}
main() {
  new A.first(!1);
}''', <String>["1+A.first", "1-A.second"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_constructorArguments_whenPrefixedType',
        '''
import 'dart:math' as m;
main() {
  new m.Random(!1);
}''', <String>["1+Random:ARGUMENT_LIST"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_dartDoc_reference_forClass',
        '''
/**
 * [int!1]
 * [method!2]
 */
class AAA {
  methodA() {}
}''', <String>["1+int", "1-method", "2+methodA", "2-int"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_dartDoc_reference_forConstructor',
        '''
class A {
  /**
   * [aa!1]
   * [int!2]
   * [method!3]
   */
  A.named(aaa, bbb) {}
  methodA() {}
}''',
        <String>["1+aaa", "1-bbb", "2+int", "2-double", "3+methodA"],
        failingTests: '12');

    CompletionTestCase.buildTests(
        'testCompletion_dartDoc_reference_forFunction',
        '''
/**
 * [aa!1]
 * [int!2]
 * [function!3]
 */
functionA(aaa, bbb) {}
functionB() {}''',
        <String>[
            "1+aaa",
            "1-bbb",
            "2+int",
            "2-double",
            "3+functionA",
            "3+functionB",
            "3-int"],
        failingTests: '12');

    CompletionTestCase.buildTests(
        'testCompletion_dartDoc_reference_forFunctionTypeAlias',
        '''
/**
 * [aa!1]
 * [int!2]
 * [Function!3]
 */
typedef FunctionA(aaa, bbb) {}
typedef FunctionB() {}''',
        <String>[
            "1+aaa",
            "1-bbb",
            "2+int",
            "2-double",
            "3+FunctionA",
            "3+FunctionB",
            "3-int"],
        failingTests: '12');

    CompletionTestCase.buildTests(
        'testCompletion_dartDoc_reference_forMethod',
        '''
class A {
  /**
   * [aa!1]
   * [int!2]
   * [method!3]
   */
  methodA(aaa, bbb) {}
  methodB() {}
}''',
        <String>[
            "1+aaa",
            "1-bbb",
            "2+int",
            "2-double",
            "3+methodA",
            "3+methodB",
            "3-int"],
        failingTests: '2');

    CompletionTestCase.buildTests(
        'testCompletion_dartDoc_reference_incomplete',
        '''
/**
 * [doubl!1 some text
 * other text
 */
class A {}
/**
 * [!2 some text
 * other text
 */
class B {}
/**
 * [!3] some text
 */
class C {}''',
        <String>["1+double", "1-int", "2+int", "2+String", "3+int", "3+String"],
        failingTests: '123');

    CompletionTestCase.buildTests('testCompletion_double_inFractionPart', '''
main() {
  1.0!1
}''', <String>["1-abs", "1-main"]);

    CompletionTestCase.buildTests('testCompletion_enum', '''
enum MyEnum {A, B, C}
main() {
  MyEnum.!1;
}''', <String>["1+values", "1+A", "1+B", "1+C"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_exactPrefix_hasHigherRelevance',
        '''
var STR;
main(p) {
  var str;
  str!1;
  STR!2;
  Str!3;
}''',
        <String>[
            "1+str" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 1)*/,
            "1+STR" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 0)*/,
            "2+STR" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 1)*/,
            "2+str" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 0)*/,
            "3+String" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 1)*/,
            "3+STR" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 0)*/,
            "3+str" /*",rel=" + (CompletionProposal.RELEVANCE_DEFAULT + 0)*/]);

    CompletionTestCase.buildTests('testCompletion_export_dart', '''
import 'dart:math
import 'dart:_chrome
import 'dart:_collection.dev
export 'dart:!1''',
        <String>[
            "1+dart:core",
            "1+dart:math",
            "1-dart:_chrome",
            "1-dart:_collection.dev"],
        failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_export_noStringLiteral_noSemicolon',
        '''
import !1

class A {}''', <String>["1+'dart:!';", "1+'package:!';"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_forStmt_vars', '''
class int{}class Foo { mth() { for (in!1t i = 0; i!2 < 5; i!3++); }}''',
        <String>["1+int", "2+i", "3+i"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_function', '''
class String{}class Foo { int boo = 7; mth() { PNGS.sort((String a, Str!1) => a.compareTo(b)); }}''',
        <String>["1+String"]);

    CompletionTestCase.buildTests('testCompletion_function_partial', '''
class String{}class Foo { int boo = 7; mth() { PNGS.sort((String a, Str!1)); }}''',
        <String>["1+String"],
        failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_functionTypeParameter_namedArgument',
        '''
typedef FFF(a, b, {x1, x2, y});
main(FFF fff) {
  fff(1, 2, !1)!2;
}''', <String>["1+x1", "2-x2"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_ifStmt_field1', '''
class Foo { int myField = 7; mth() { if (!1) {}}}''', <String>["1+myField"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_field1a', '''
class Foo { int myField = 7; mth() { if (!1) }}''', <String>["1+myField"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_field2', '''
class Foo { int myField = 7; mth() { if (m!1) {}}}''', <String>["1+myField"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_field2a', '''
class Foo { int myField = 7; mth() { if (m!1) }}''', <String>["1+myField"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_field2b', '''
class Foo { myField = 7; mth() { if (m!1) {}}}''', <String>["1+myField"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_localVar', '''
class Foo { mth() { int value = 7; if (v!1) {}}}''', <String>["1+value"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_localVara', '''
class Foo { mth() { value = 7; if (v!1) {}}}''', <String>["1-value"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_topLevelVar', '''
int topValue = 7; class Foo { mth() { if (t!1) {}}}''', <String>["1+topValue"]);

    CompletionTestCase.buildTests('testCompletion_ifStmt_topLevelVara', '''
topValue = 7; class Foo { mth() { if (t!1) {}}}''', <String>["1+topValue"]);

    CompletionTestCase.buildTests(
        'testCompletion_ifStmt_unionType_nonStrict',
        '''
class A { a() => null; x() => null}
class B { a() => null; y() => null}
void main() {
  var x;
  var c;
  if(c) {
    x = new A();
  } else {
    x = new B();
  }
  x.!1;
}''', <String>["1+a", "1+x", "1+y"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_ifStmt_unionType_strict', '''
class A { a() => null; x() => null}
class B { a() => null; y() => null}
void main() {
  var x;
  var c;
  if(c) {
    x = new A();
  } else {
    x = new B();
  }
  x.!1;
}''', <String>["1+a", "1-x", "1-y"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_import', '''
import '!1';''', <String>["1+dart:!", "1+package:!"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_import_dart', '''
import 'dart:math
import 'dart:_chrome
import 'dart:_collection.dev
import 'dart:!1''',
        <String>[
            "1+dart:core",
            "1+dart:math",
            "1-dart:_chrome",
            "1-dart:_collection.dev"],
        failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_import_hasStringLiteral_noSemicolon',
        '''
import '!1'

class A {}''', <String>["1+dart:!", "1+package:!"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_import_noSpace', '''
import!1''', <String>["1+ 'dart:!';", "1+ 'package:!';"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_import_noStringLiteral', '''
import !1;''', <String>["1+'dart:!'", "1+'package:!'"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_import_noStringLiteral_noSemicolon',
        '''
import !1

class A {}''', <String>["1+'dart:!';", "1+'package:!';"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_incompleteClassMember', '''
class A {
  Str!1
  final f = null;
}''', <String>["1+String", "1-bool"]);

    CompletionTestCase.buildTests(
        'testCompletion_incompleteClosure_parameterType',
        '''
f1(cb(String s)) {}
f2(String s) {}
main() {
  f1((Str!1));
  f2((Str!2));
}''', <String>["1+String", "1-bool", "2+String", "2-bool"]);

    CompletionTestCase.buildTests('testCompletion_inPeriodPeriod', '''
main(String str) {
  1 < str.!1.length;
  1 + str.!2.length;
  1 + 2 * str.!3.length;
}''',
        <String>["1+codeUnits", "2+codeUnits", "3+codeUnits"],
        failingTests: '123');

    // no checks, but no exceptions
    CompletionTestCase.buildTests(
        'testCompletion_instanceCreation_unresolved',
        '''
class A {
}
main() {
  new NoSuchClass(!1);
  new A.noSuchConstructor(!2);
}''', <String>["1+int", "2+int"]);

    CompletionTestCase.buildTests('testCompletion_import_lib', '''
import '!1''', <String>["1+my_lib.dart"], extraFiles: <String, String>{
      "/my_lib.dart": ""
    }, failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_is', '''
class MyClass {}
main(p) {
  var isVariable;
  if (p is MyCla!1) {}
  var v1 = p is MyCla!2;
  var v2 = p is !3;
  var v2 = p is!4;
}''',
        <String>["1+MyClass", "2+MyClass", "3+MyClass", "3-v1", "4+is", "4-isVariable"],
        failingTests: '4');

    CompletionTestCase.buildTests('testCompletion_is_asIdentifierStart', '''
main(p) {
  var isVisible;
  var v1 = is!1;
  var v2 = is!2
}''', <String>["1+isVisible", "2+isVisible"]);

    CompletionTestCase.buildTests(
        'testCompletion_is_asPrefixedIdentifierStart',
        '''
class A {
  var isVisible;
}

main(A p) {
  var v1 = p.is!1;
  var v2 = p.is!2
}''', <String>["1+isVisible", "2+isVisible"]);

    CompletionTestCase.buildTests('testCompletion_is_incompleteStatement1', '''
class MyClass {}
main(p) {
  var justSomeVar;
  var v = p is !1
}''', <String>["1+MyClass", "1-justSomeVar"]);

    CompletionTestCase.buildTests('testCompletion_is_incompleteStatement2', '''
class MyClass {}
main(p) {
  var isVariable;
  var v = p is!1
}''', <String>["1+is", "1-isVariable"], failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_keyword_in', '''
class Foo { int input = 7; mth() { if (in!1) {}}}''', <String>["1+input"]);

    CompletionTestCase.buildTests(
        'testCompletion_keyword_syntheticIdentifier',
        '''
main() {
  var caseVar;
  var otherVar;
  var v = case!1
}''', <String>["1+caseVar", "1-otherVar"]);

    CompletionTestCase.buildTests('testCompletion_libraryIdentifier_atEOF', '''
library int.!1''', <String>["1-parse", "1-bool"]);

    CompletionTestCase.buildTests('testCompletion_libraryIdentifier_notEOF', '''
library int.!1''', <String>["1-parse", "1-bool"]);

    CompletionTestCase.buildTests(
        'testCompletion_methodRef_asArg_incompatibleFunctionType',
        '''
foo( f(int p) ) {}
class Functions {
  static myFuncInt(int p) {}
  static myFuncDouble(double p) {}
}
bar(p) {}
main(p) {
  foo( Functions.!1; );
}''',
        <String>[
            "1+myFuncInt" /*":" + ProposalKind.METHOD_NAME*/,
            "1-myFuncDouble" /*":" + ProposalKind.METHOD_NAME*/]);

    CompletionTestCase.buildTests(
        'testCompletion_methodRef_asArg_notFunctionType',
        '''
foo( f(int p) ) {}
class Functions {
  static myFunc(int p) {}
}
bar(p) {}
main(p) {
  foo( (int p) => Functions.!1; );
}''',
        <String>[
            "1+myFunc" /*":" + ProposalKind.METHOD*/,
            "1-myFunc" /*":" + ProposalKind.METHOD_NAME*/]);

    CompletionTestCase.buildTests(
        'testCompletion_methodRef_asArg_ofFunctionType',
        '''
foo( f(int p) ) {}
class Functions {
  static int myFunc(int p) {}
}
main(p) {
  foo(Functions.!1);
}''',
        <String>[
            "1+myFunc" /*":" + ProposalKind.METHOD*/,
            "1+myFunc" /*":" + ProposalKind.METHOD_NAME*/]);

    CompletionTestCase.buildTests(
        'testCompletion_namedArgument_alreadyUsed',
        '''
func({foo}) {} main() { func(foo: 0, fo!1); }''', <String>["1-foo"]);

    CompletionTestCase.buildTests(
        'testCompletion_namedArgument_constructor',
        '''
class A {A({foo, bar}) {}} main() { new A(fo!1); }''',
        <String>["1+foo", "1-bar"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_namedArgument_empty', '''
func({foo, bar}) {} main() { func(!1); }''',
        <String>[
            "1+foo" /*":" + ProposalKind.NAMED_ARGUMENT*/,
            "1-foo" /*":" + ProposalKind.OPTIONAL_ARGUMENT*/],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_namedArgument_function', '''
func({foo, bar}) {} main() { func(fo!1); }''',
        <String>["1+foo", "1-bar"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_namedArgument_notNamed', '''
func([foo]) {} main() { func(fo!1); }''', <String>["1-foo"]);

    CompletionTestCase.buildTests(
        'testCompletion_namedArgument_unresolvedFunction',
        '''
main() { func(fo!1); }''', <String>["1-foo"]);

    CompletionTestCase.buildTests('testCompletion_newMemberType1', '''
class Collection{}class List extends Collection{}class Foo { !1 }''',
        <String>["1+Collection", "1+List"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_newMemberType2', '''
class Collection{}class List extends Collection{}class Foo {!1}''',
        <String>["1+Collection", "1+List"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_newMemberType3', '''
class Collection{}class List extends Collection{}class Foo {L!1}''',
        <String>["1-Collection", "1+List"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_newMemberType4', '''
class Collection{}class List extends Collection{}class Foo {C!1}''',
        <String>["1+Collection", "1-List"]);

    CompletionTestCase.buildTests(
        'testCompletion_positionalArgument_constructor',
        '''
class A {
  A([foo, bar]);
}
main() {
  new A(!1);
  new A(0, !2);
}''',
        <String>[
            "1+foo" /*":" + ProposalKind.OPTIONAL_ARGUMENT*/,
            "1-bar",
            "2-foo",
            "2+bar" /*":"
        + ProposalKind.OPTIONAL_ARGUMENT*/], failingTests: '12');

    CompletionTestCase.buildTests(
        'testCompletion_positionalArgument_function',
        '''
func([foo, bar]) {}
main() {
  func(!1);
  func(0, !2);
}''',
        <String>[
            "1+foo" /*":" + ProposalKind.OPTIONAL_ARGUMENT*/,
            "1-bar",
            "2-foo",
            "2+bar" /*":"
        + ProposalKind.OPTIONAL_ARGUMENT*/], failingTests: '12');

    CompletionTestCase.buildTests('testCompletion_preferStaticType', '''
class A {
  foo() {}
}
class B extends A {
  bar() {}
}
main() {
  A v = new B();
  v.!1
}''',
        <String>[
            "1+foo",
            "1-bar,potential=false,declaringType=B",
            "1+bar,potential=true,declaringType=B"],
        failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_privateElement_sameLibrary_constructor',
        '''
class A {
  A._c();
  A.c();
}
main() {
  new A.!1
}''', <String>["1+_c", "1+c"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_privateElement_sameLibrary_member',
        '''
class A {
  _m() {}
  m() {}
}
main(A a) {
  a.!1
}''', <String>["1+_m", "1+m"]);

    CompletionTestCase.buildTests(
        'testCompletion_propertyAccess_whenClassTarget',
        '''
class A {
  static int FIELD;
  int field;
}
main() {
  A.!1
}''', <String>["1+FIELD", "1-field"]);

    CompletionTestCase.buildTests(
        'testCompletion_propertyAccess_whenClassTarget_excludeSuper',
        '''
class A {
  static int FIELD_A;
  static int methodA() {}
}
class B extends A {
  static int FIELD_B;
  static int methodB() {}
}
main() {
  B.!1;
}''', <String>["1+FIELD_B", "1-FIELD_A", "1+methodB", "1-methodA"]);

    CompletionTestCase.buildTests(
        'testCompletion_propertyAccess_whenInstanceTarget',
        '''
class A {
  static int FIELD;
  int fieldA;
}
class B {
  A a;
}
class C extends A {
  int fieldC;
}
main(B b, C c) {
  b.a.!1;
  c.!2;
}''', <String>["1-FIELD", "1+fieldA", "2+fieldC", "2+fieldA"]);

    CompletionTestCase.buildTests(
        'testCompletion_return_withIdentifierPrefix',
        '''
f() { var vvv = 42; return v!1 }''', <String>["1+vvv"]);

    CompletionTestCase.buildTests('testCompletion_return_withoutExpression', '''
f() { var vvv = 42; return !1 }''', <String>["1+vvv"]);

    CompletionTestCase.buildTests('testCompletion_staticField1', '''
class num{}class Sunflower {static final n!2um MAX_D = 300;nu!3m xc, yc;Sun!4flower() {x!Xc = y!Yc = MA!1 }}''',
        <String>["1+MAX_D", "X+xc", "Y+yc", "2+num", "3+num", "4+Sunflower"],
        failingTests: '23');

    CompletionTestCase.buildTests('testCompletion_super_superType', '''
class A {
  var fa;
  ma() {}
}
class B extends A {
  var fb;
  mb() {}
  main() {
    super.!1
  }
}''', <String>["1+fa", "1-fb", "1+ma", "1-mb"]);

    CompletionTestCase.buildTests(
        'testCompletion_superConstructorInvocation_noNamePrefix',
        '''
class A {
  A.fooA();
  A.fooB();
  A.bar();
}
class B extends A {
  B() : super.!1
}''', <String>["1+fooA", "1+fooB", "1+bar"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_superConstructorInvocation_withNamePrefix',
        '''
class A {
  A.fooA();
  A.fooB();
  A.bar();
}
class B extends A {
  B() : super.f!1
}''', <String>["1+fooA", "1+fooB", "1-bar"], failingTests: '1');

    CompletionTestCase.buildTests(
        'testCompletion_this_bad_inConstructorInitializer',
        '''
class A {
  var f;
  A() : f = this.!1;
}''', <String>["1-toString"]);

    CompletionTestCase.buildTests(
        'testCompletion_this_bad_inFieldDeclaration',
        '''
class A {
  var f = this.!1;
}''', <String>["1-toString"]);

    CompletionTestCase.buildTests('testCompletion_this_bad_inStaticMethod', '''
class A {
  static m() {
    this.!1;
  }
}''', <String>["1-toString"]);

    CompletionTestCase.buildTests(
        'testCompletion_this_bad_inTopLevelFunction',
        '''
main() {
  this.!1;
}''', <String>["1-toString"]);

    CompletionTestCase.buildTests(
        'testCompletion_this_bad_inTopLevelVariableDeclaration',
        '''
var v = this.!1;''', <String>["1-toString"]);

    CompletionTestCase.buildTests(
        'testCompletion_this_OK_inConstructorBody',
        '''
class A {
  var f;
  m() {}
  A() {
    this.!1;
  }
}''', <String>["1+f", "1+m"]);

    CompletionTestCase.buildTests('testCompletion_this_OK_localAndSuper', '''
class A {
  var fa;
  ma() {}
}
class B extends A {
  var fb;
  mb() {}
  main() {
    this.!1
  }
}''', <String>["1+fa", "1+fb", "1+ma", "1+mb"]);

    CompletionTestCase.buildTests('testCompletion_topLevelField_init2', '''
class DateTime{static var JUN;}final num M = Dat!1eTime.JUN;''',
        <String>["1+DateTime", "1-void"],
        failingTests: '1');

    CompletionTestCase.buildTests('testCompletion_while', '''
class Foo { int boo = 7; mth() { while (b!1) {} }}''', <String>["1+boo"]);
  }

  void buildLibraryTests() {
    Map<String, String> sources = new HashMap<String, String>();

    CompletionTestCase.buildTests('test_export_ignoreIfThisLibraryExports', '''
export 'dart:math';
libFunction() {};
main() {
  !1
}''', <String>["1-cos", "1+libFunction"]);

    sources.clear();
    sources["/lib.dart"] = '''
library lib;
export 'dart:math' hide sin;
libFunction() {};''';
    CompletionTestCase.buildTests(
        'test_export_showIfImportLibraryWithExport',
        '''
import 'lib.dart' as p;
main() {
  p.!1
}''',
        <String>["1+cos", "1-sin", "1+libFunction"],
        extraFiles: sources,
        failingTests: '1');

    CompletionTestCase.buildTests('test_importPrefix_hideCombinator', '''
import 'dart:math' as math hide PI;
main() {
  math.!1
}''', <String>["1-PI", "1+LN10"], failingTests: '1');

    CompletionTestCase.buildTests('test_importPrefix_showCombinator', '''
import 'dart:math' as math show PI;
main() {
  math.!1
}''', <String>["1+PI", "1-LN10"]);

    sources.clear();
    sources["/lib.dart"] = '''
library lib
class _A 
  foo() {}

class A extends _A {
}''';
    CompletionTestCase.buildTests('test_memberOfPrivateClass_otherLibrary', '''
import 'lib.dart';
main(A a) {
  a.!1
}''', <String>["1+foo"], extraFiles: sources, failingTests: '1');

    sources.clear();
    sources["/lib.dart"] = '''
library lib;
class A {
  A.c();
  A._c();
}''';
    CompletionTestCase.buildTests(
        'test_noPrivateElement_otherLibrary_constructor',
        '''
import 'lib.dart';
main() {
  new A.!1
}''', <String>["1-_c", "1+c"], failingTests: '1');

    sources.clear();
    sources["/lib.dart"] = '''
library lib;
class A {
  var f;
  var _f;
}''';
    CompletionTestCase.buildTests(
        'test_noPrivateElement_otherLibrary_member',
        '''
              import 'lib.dart';
              main(A a) {
                a.!1
              }''',
        <String>["1-_f", "1+f"],
        extraFiles: sources,
        failingTests: '1');

    sources.clear();
    sources["/firth.dart"] = '''
library firth;
class SerializationException {
  const SerializationException();
}''';
    CompletionTestCase.buildTests('test001', '''
import 'firth.dart';
main() {
throw new Seria!1lizationException();}''',
        <String>["1+SerializationException"],
        extraFiles: sources,
        failingTests: '1');

    // Type propagation.
    // TODO Include corelib analysis (this works in the editor)
    CompletionTestCase.buildTests(
        'test002',
        '''t2() {var q=[0],z=q.!1length;q.!2clear();}''',
        <String>["1+length", "1+isEmpty", "2+clear"],
        failingTests: '12');

    // TODO Include corelib analysis
    CompletionTestCase.buildTests(
        'test003',
        '''class X{var q; f() {q.!1a!2}}''',
        <String>["1+end", "2+abs", "2-end"],
        failingTests: '12');

    // TODO Include corelib analysis
    // Resolving dart:html takes between 2.5s and 30s; json, about 0.12s
    CompletionTestCase.buildTests('test004', '''
            library foo;
            import 'dart:convert' as json;
            class JsonParserX{}
            f1() {var x=new json.!1}
            f2() {var x=new json.JsonPa!2}
            f3() {var x=new json.JsonParser!3}''',
        <String>[
            "1+JsonParser",
            "1-JsonParserX",
            "2+JsonParser",
            "2-JsonParserX",
            "3+JsonParser",
            "3-JsonParserX"],
        failingTests: '123');

    // TODO Enable after type propagation is implemented. Not yet.
    // TODO Include corelib analysis
    CompletionTestCase.buildTests(
        'test005',
        '''var PHI;main(){PHI=5.3;PHI.abs().!1 Object x;}''',
        <String>["1+abs"],
        failingTests: '1');

    // Exercise import and export handling.
    // Libraries are defined in partial order of increasing dependency.
    sources.clear();
    sources["/exp2a.dart"] = '''
library exp2a;
e2a() {}''';
    sources["/exp1b.dart"] = '''
library exp1b;",
e1b() {}''';
    sources["/exp1a.dart"] = '''
library exp1a;",
export 'exp1b.dart';",
e1a() {}''';
    sources["/imp1.dart"] = '''
library imp1;
export 'exp1a.dart';
i1() {}''';
    sources["/imp2.dart"] = '''
library imp2;
export 'exp2a.dart';
i2() {}''';
    CompletionTestCase.buildTests('test006', '''
import 'imp1.dart';
import 'imp2.dart';
main() {!1
  i1();
  i2();
  e1a();
  e1b();
  e2a();
}''',
        <String>["1+i1", "1+i2", "1+e1a", "1+e2a", "1+e1b"],
        extraFiles: sources,
        failingTests: '1');

    // Exercise import and export handling.
    // Libraries are defined in partial order of increasing dependency.
    sources.clear();
    sources["/l1.dart"] = '''
library l1;
var _l1t; var l1t;''';
    CompletionTestCase.buildTests('test007', '''
import 'l1.dart';
main() {
  var x = l!1
  var y = _!2
}''',
        <String>["1+l1t", "1-_l1t", "2-_l1t"],
        extraFiles: sources,
        failingTests: '1');

    // Check private library exclusion
    sources.clear();
    sources["/public.dart"] = '''
library public;
class NonPrivate {
  void publicMethod() {
  }
}''';
    sources["/private.dart"] = '''
library _private;
import 'public.dart';
class Private extends NonPrivate {
  void privateMethod() {
  }
}''';
    CompletionTestCase.buildTests('test008', '''
import 'private.dart';
import 'public.dart';
class Test {
  void test() {
    NonPrivate x = new NonPrivate();
    x.!1 //publicMethod but not privateMethod should appear
  }
}''',
        <String>["1-privateMethod", "1+publicMethod"],
        extraFiles: sources,
        failingTests: '1');

    // Exercise library prefixes.
    sources.clear();
    sources["/lib.dart"] = '''
library lib;
int X = 1;
void m(){}
class Y {}''';
    CompletionTestCase.buildTests('test009', '''
import 'lib.dart' as Q;
void a() {
  var x = Q.!1
}
void b() {
  var x = [Q.!2]
}
void c() {
  var x = new List([Q.!3])
}
void d() {
  new Q.!4
}''',
        <String>[
            "1+X",
            "1+m",
            "1+Y",
            "2+X",
            "2+m",
            "2+Y",
            "3+X",
            "3+m",
            "3+Y",
            "4+Y",
            "4-m",
            "4-X"],
        extraFiles: sources,
        failingTests: '1234');
  }

  void buildNumberedTests() {
    CompletionTestCase.buildTests('test001', '''
void r1(var v) {
  v.!1toString!2().!3hash!4Code
}''',
        <String>[
            "1+toString",
            "1-==",
            "2+toString",
            "3+hashCode",
            "3+toString",
            "4+hashCode",
            "4-toString"],
        failingTests: '34');

    CompletionTestCase.buildTests('test002', '''
void r2(var vim) {
  v!1.toString()
}''', <String>["1+vim"]);

    CompletionTestCase.buildTests('test003', '''
class A {
  int a() => 3;
  int b() => this.!1a();
}''', <String>["1+a"]);

    CompletionTestCase.buildTests('test004', '''
class A {
  int x;
  A() : this.!1x = 1;
  A.b() : this();
  A.c() : this.!2b();
  g() => new A.!3c();
}''', <String>["1+x", "2+b", "3+c"], failingTests: '23');

    CompletionTestCase.buildTests('test005', '''
class A {}
void rr(var vim) {
  var !1vq = v!2.toString();
  var vf;
  v!3.toString();
}''',
        <String>[
            "1-A",
            "1-vim",
            "1+vq",
            "1-vf",
            "1-this",
            "1-void",
            "1-null",
            "1-false",
            "2-A",
            "2+vim",
            "2-vf",
            "2-vq",
            "2-this",
            "2-void",
            "2-null",
            "2-false",
            "3+vf",
            "3+vq",
            "3+vim",
            "3-A"],
        failingTests: '1');

    CompletionTestCase.buildTests('test006', '''
void r2(var vim, {va: 2, b: 3}) {
  v!1.toString()
}''', <String>["1+va", "1-b"]);

    CompletionTestCase.buildTests('test007', '''
void r2(var vim, [va: 2, b: 3]) {
  v!1.toString()
}''', <String>["1+va", "1-b"]);

    // keywords
    CompletionTestCase.buildTests('test008', '''
!1class Aclass {}
class Bclass !2extends!3 !4Aclass {}
!5typedef Ctype = !6Bclass with !7Aclass;
class Dclass extends !8Ctype {}
!9abstract class Eclass implements Dclass,!C Ctype, Bclass {}
class Fclass extends Bclass !Awith !B Eclass {}''',
        <String>[
            "1+class",
            "1-implements",
            "1-extends",
            "1-with",
            "2+extends",
            "3+extends",
            "4+Aclass",
            "4-Bclass",
            "5+typedef",
            "6+Bclass",
            "6-Ctype",
            "7+Aclass",
            "7-Bclass",
            "8+Ctype",
            "9+abstract",
            "A+with",
            "B+Eclass",
            "B-Dclass",
            "B-Ctype",
            "C+Bclass",
            "C-Eclass"],
        failingTests: '12359A');

    // keywords
    CompletionTestCase.buildTests('test009', '''
class num{}
typedef !1dy!2namic TestFn1();
typedef !3vo!4id TestFn2();
typ!7edef !5n!6''',
        <String>[
            "1+void",
            "1+TestFn2",
            "2+dynamic",
            "2-void",
            "3+dynamic",
            "4+void",
            "4-dynamic",
            "5+TestFn2",
            "6+num",
            "7+typedef"],
        failingTests: '12347');

    CompletionTestCase.buildTests('test010', '''
class String{}class List{}
class test !8<!1t !2 !3extends String,!4 List,!5 !6>!7 {}
class tezetst !9<!BString,!C !DList>!A {}''',
        <String>[
            "1+String",
            "1+List",
            "1-test",
            "2-String",
            "2-test",
            "3+extends",
            "4+tezetst",
            "4-test",
            "5+String",
            "6+List",
            "7-List",
            "8-List",
            "9-String",
            "A-String",
            "B+String",
            "C+List",
            "C-tezetst",
            "D+List",
            "D+test"],
        failingTests: '3');

    // name generation with conflicts
    CompletionTestCase.buildTests(
        'test011',
        '''r2(var object, Object object1, Object !1);''',
        <String>["1+object2"],
        failingTests: '1');

    // reserved words
    CompletionTestCase.buildTests('test012', '''
class X {
  f() {
    g(!1var!2 z) {!3true.!4toString();};
  }
}''',
        <String>[
            "1+var",
            "1+dynamic",
            "1-f",
            "2+var",
            "2-dynamic",
            "3+false",
            "3+true",
            "4+toString"],
        failingTests: '123');

    // conditions & operators
    CompletionTestCase.buildTests('test013', '''
class Q {
  bool x;
  List zs;
  int k;
  var a;
  mth() {
    while (!1x !9);
    do{} while(!2x !8);
    for(z in !3zs) {}
    switch(!4k) {case 1:{!0}}
    try {
    } on !5Object catch(a){}
    if (!7x !6) {} else {};
  }
}''',
        <String>[
            "1+x",
            "2+x",
            "3+zs",
            "4+k",
            "5+Q",
            "5-a",
            "6+==",
            "7+x",
            "8+==",
            "9+==",
            "0+k"],
        failingTests: '689');

    // keywords
    CompletionTestCase.buildTests('test014', '''
class Q {
  bool x;
  List zs;
  int k;
  !Dvar a;
  !Evoid mth() {
    !1while (z) { !Gcontinue; };
    !2do{ !Hbreak; } !3while(x);
    !4for(z !5in zs) {}
    !6for (int i; i < 3; i++);
    !7switch(k) {!8case 1:{} !9default:{}}
    !Atry {
    } !Bon Object !Ccatch(a){}
    !Fassert true;
    !Jif (x) {} !Kelse {};
    !Lreturn;
  }
}''',
        <String>[
            "1+while",
            "2+do",
            "3+while",
            "4+for",
            "5+in",
            "6+for",
            "7+switch",
            "8+case",
            "9+default",
            "A+try",
            "B+on",
            "C+catch",
            "D+var",
            "E+void",
            "F+assert",
            "G+continue",
            "H+break",
            "J+if",
            "K+else",
            "L+return"],
        failingTests: '123456789ABCDEFGHJKL');

    // operators in function
    CompletionTestCase.buildTests(
        'test015',
        '''f(a,b,c) => a + b * c !1;''',
        <String>["1+=="],
        failingTests: '1');

    // operators in return
    CompletionTestCase.buildTests(
        'test016',
        '''class X {dynamic f(a,b,c) {return a + b * c !1;}}''',
        <String>["1+=="],
        failingTests: '1');

    // keywords
    CompletionTestCase.buildTests('test017', '''
!1library foo;
!2import 'x' !5as r;
!3export '!8uri' !6hide Q !7show X;
!4part 'x';''',
        <String>[
            "1+library",
            "2+import",
            "3+export",
            "4+part",
            "5+as",
            "6+hide",
            "7+show",
            "8-null"],
        failingTests: '1234567');

    // The following test is disabled because it prevents the Dart VM from
    // exiting, for some unknown reason.  TODO(paulberry): fix this.
//    // keywords
//    CompletionTestCase.buildTests(
//        'test018',
//        '''!1part !2of foo;''',
//        <String>["1+part", "2+of"],
//        failingTests: '12');

    CompletionTestCase.buildTests('test019', '''
var truefalse = 0;
var falsetrue = 1;
main() {
  var foo = true!1
}''', <String>["1+true", "1+truefalse", "1-falsetrue"], failingTests: '1');

    CompletionTestCase.buildTests(
        'test020',
        '''var x = null.!1''',
        <String>["1+toString"],
        failingTests: '1');

    CompletionTestCase.buildTests(
        'test021',
        '''var x = .!1''',
        <String>["1-toString"]);

    CompletionTestCase.buildTests(
        'test022',
        '''var x = .!1;''',
        <String>["1-toString"]);

    CompletionTestCase.buildTests('test023', '''
class Map{getKeys(){}}
class X {
  static x1(Map m) {
    m.!1getKeys;
  }
  x2(Map m) {
    m.!2getKeys;
  }
}''', <String>["1+getKeys", "2+getKeys"]);

// Note lack of semicolon following completion location
    CompletionTestCase.buildTests('test024', '''
class List{factory List.from(Iterable other) {}}
class F {
  f() {
    new List.!1
  }
}''', <String>["1+from"], failingTests: '1');

    CompletionTestCase.buildTests('test025', '''
class R {
  static R _m;
  static R m;
  f() {
    var a = !1m;
    var b = _!2m;
    var c = !3g();
  }
  static g() {
    var a = !4m;
    var b = _!5m;
    var c = !6g();
  }
}
class T {
  f() {
    R x;
    x.!7g();
    x.!8m;
    x._!9m;
  }
  static g() {
    var q = R._!Am;
    var g = R.!Bm;
    var h = R.!Cg();
  }
  h() {
    var q = R._!Dm;
    var g = R.!Em;
    var h = R.!Fg();
  }
}''',
        <String>[
            "1+m",
            "2+_m",
            "3+g",
            "4+m",
            "5+_m",
            "6+g",
            "7-g",
            "8-m",
            "9-_m",
            "A+_m",
            "B+m",
            "C+g",
            "D+_m",
            "E+m",
            "F+g"]);

    CompletionTestCase.buildTests(
        'test026',
        '''var aBcD; var x=ab!1''',
        <String>["1+aBcD"]);

    CompletionTestCase.buildTests(
        'test027',
        '''m(){try{}catch(eeee,ssss){s!1}''',
        <String>["1+ssss"]);

    CompletionTestCase.buildTests(
        'test028',
        '''m(){var isX=3;if(is!1)''',
        <String>["1+isX"]);

    CompletionTestCase.buildTests(
        'test029',
        '''m(){[1].forEach((x)=>!1x);}''',
        <String>["1+x"]);

    CompletionTestCase.buildTests(
        'test030',
        '''n(){[1].forEach((x){!1});}''',
        <String>["1+x"]);

    CompletionTestCase.buildTests(
        'test031',
        '''class Caster {} m() {try {} on Cas!1ter catch (CastBlock) {!2}}''',
        <String>["1+Caster", "1-CastBlock", "2+Caster", "2+CastBlock"]);

    CompletionTestCase.buildTests('test032', '''
const ONE = 1;
const ICHI = 10;
const UKSI = 100;
const EIN = 1000;
m() {
  int x;
  switch (x) {
    case !3ICHI:
    case UKSI:
    case EIN!2:
    case ONE!1: return;
    default: return;
  }
}''',
        <String>[
            "1+ONE",
            "1-UKSI",
            "2+EIN",
            "2-ICHI",
            "3+ICHI",
            "3+UKSI",
            "3+EIN",
            "3+ONE"]);

    CompletionTestCase.buildTests(
        'test033',
        '''class A{}class B extends A{b(){}}class C implements A {c(){}}class X{x(){A f;f.!1}}''',
        <String>["1+b", "1-c"],
        failingTests: '1');

    // TODO(scheglov) decide what to do with Type for untyped field (not
    // supported by the new store)
    // test analysis of untyped fields and top-level vars
    CompletionTestCase.buildTests('test034', '''
var topvar;
class Top {top(){}}
class Left extends Top {left(){}}
class Right extends Top {right(){}}
t1() {
  topvar = new Left();
}
t2() {
  topvar = new Right();
}
class A {
  var field;
  a() {
    field = new Left();
  }
  b() {
    field = new Right();
  }
  test() {
    topvar.!1top();
    field.!2top();
  }
}''', <String>["1+top", "2+top"], failingTests: '12');

    // test analysis of untyped fields and top-level vars
    CompletionTestCase.buildTests(
        'test035',
        '''class Y {final x='hi';mth() {x.!1length;}}''',
        <String>["1+length"],
        failingTests: '1');

    // TODO(scheglov) decide what to do with Type for untyped field (not
    // supported by the new store)
    // test analysis of untyped fields and top-level vars
    CompletionTestCase.buildTests('test036', '''
class A1 {
  var field;
  A1() : field = 0;
  q() {
    A1 a = new A1();
    a.field.!1
  }
}
main() {
  A1 a = new A1();
  a.field.!2
}''', <String>["1+round", "2+round"], failingTests: '12');

    CompletionTestCase.buildTests('test037', '''
class HttpServer{}
class HttpClient{}
main() {
  new HtS!1
}''', <String>["1+HttpServer", "1-HttpClient"]);

    CompletionTestCase.buildTests('test038', '''
class X {
  x(){}
}
class Y {
  y(){}
}
class A<Z extends X> {
  Y ay;
  Z az;
  A(this.ay, this.az) {
    ay.!1y;
    az.!2x;
  }
}''', <String>["1+y", "1-x", "2+x", "2-y"], failingTests: '2');

    // test analysis of untyped fields and top-level vars
    CompletionTestCase.buildTests(
        'test039',
        '''class X{}var x = null as !1X;''',
        <String>["1+X", "1-void"]);

    // test arg lists with named params
    CompletionTestCase.buildTests(
        'test040',
        '''m(){f(a, b, {x1, x2, y}) {};f(1, 2, !1)!2;}''',
        <String>["1+x1", "2-x2"],
        failingTests: '1');

    // test arg lists with named params
    CompletionTestCase.buildTests(
        'test041',
        '''m(){f(a, b, {x1, x2, y}) {};f(1, 2, !1''',
        <String>["1+x1", "1+x2", "1+y"],
        failingTests: '1');

    // test arg lists with named params
    CompletionTestCase.buildTests(
        'test042',
        '''m(){f(a, b, {x1, x2, y}) {};f(1, 2, !1;!2''',
        <String>["1+x1", "1+x2", "2-y"],
        failingTests: '1');
  }

  void buildOtherTests() {
    CompletionTestCase.buildTests(
        'test_classMembers_inGetter',
        '''class A { var fff; get z {ff!1}}''',
        <String>["1+fff"]);

    CompletionTestCase.buildTests(
        'testSingle',
        '''class A {int x; !2mth() {int y = this.x;}}class B{}''',
        <String>["2+B"]);
  }
}
