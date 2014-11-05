// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'parser_helper.dart';
import 'mock_compiler.dart';
import 'package:compiler/src/tree/tree.dart';

testUnparse(String statement) {
  Node node = parseStatement(statement);
  Expect.equals(statement, unparse(node));
}

testUnparseMember(String member) {
  Node node = parseMember(member);
  Expect.equals(member, unparse(node));
}

testUnparseUnit(String code) {
  Node node = fullParseUnit(code);
  Expect.equals(code, unparse(node));
}

testUnparseTopLevelWithMetadata(String code) {
  testUnparseUnit(code);
  // TODO(ahe): Enable when supported.
  // testUnparseUnit('@foo $code');
}

testSignedConstants() {
  testUnparse('var x=-42;');
  testUnparse('var x=-.42;');
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
  testUnparse('var x=[] ;');
}

testClosure() {
  testUnparse('var x=(var x)=>x;');
}

testIndexedOperatorDecl() {
  testUnparseMember('operator[](int i)=>null;');
  testUnparseMember('operator[]=(int i,int j)=>null;');
}

testNativeMethods() {
  testUnparseMember('foo()native;');
  testUnparseMember('foo()native "bar";');
  testUnparseMember('foo()native "this.x = 41";');
}

testPrefixIncrements() {
  testUnparse(' ++i;');
  testUnparse(' ++a[i];');
  testUnparse(' ++a[ ++b[i]];');
}

testConstModifier() {
  testUnparse('foo([var a=const[] ]){}');
  testUnparse('foo([var a=const{}]){}');
  testUnparse('foo(){var a=const[] ;var b=const{};}');
  testUnparse('foo([var a=const[const{"a":const[1,2,3]}]]){}');
}

testSimpleObjectInstantiation() {
  testUnparse('main(){new Object();}');
}

testLibraryName() {
  testUnparseTopLevelWithMetadata('library com;');
  testUnparseTopLevelWithMetadata('library com.example;');
  testUnparseTopLevelWithMetadata('library com.example.dart;');
}

testImport() {
  testUnparseTopLevelWithMetadata('import "søhest";');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest;');
}

testExport() {
  testUnparseTopLevelWithMetadata('export "søhest";');
}

testPart() {
  testUnparseTopLevelWithMetadata('part "søhest";');
}

testPartOf() {
  testUnparseTopLevelWithMetadata('part of com;');
  testUnparseTopLevelWithMetadata('part of com.example;');
  testUnparseTopLevelWithMetadata('part of com.example.dart;');
}

testCombinators() {
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest show a;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest show hide;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest show show;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest show a,hide;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest show a,show;');

  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest hide a;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest hide hide;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest hide show;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest hide a,hide;');
  testUnparseTopLevelWithMetadata('import "søhest" as fiskehest hide a,show;');

  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show a hide a;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show hide hide hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show show hide show;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show a,hide hide a,hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show a,show hide a,show;');

  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide a show a;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide hide show hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide show show show;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide a,hide show a,hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide a,show show a,show;');

  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show a show a;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show hide show hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show show show show;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show a,hide show a,hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest show a,show show a,show;');

  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide a hide a;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide hide hide hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide show hide show;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide a,hide hide a,hide;');
  testUnparseTopLevelWithMetadata(
      'import "søhest" as fiskehest hide a,show hide a,show;');

  testUnparseTopLevelWithMetadata('export "søhest" show a;');
  testUnparseTopLevelWithMetadata('export "søhest" show hide;');
  testUnparseTopLevelWithMetadata('export "søhest" show show;');
  testUnparseTopLevelWithMetadata('export "søhest" show a,hide;');
  testUnparseTopLevelWithMetadata('export "søhest" show a,show;');

  testUnparseTopLevelWithMetadata('export "søhest" hide a;');
  testUnparseTopLevelWithMetadata('export "søhest" hide hide;');
  testUnparseTopLevelWithMetadata('export "søhest" hide show;');
  testUnparseTopLevelWithMetadata('export "søhest" hide a,hide;');
  testUnparseTopLevelWithMetadata('export "søhest" hide a,show;');

  testUnparseTopLevelWithMetadata('export "søhest" show a hide a;');
  testUnparseTopLevelWithMetadata('export "søhest" show hide hide hide;');
  testUnparseTopLevelWithMetadata('export "søhest" show show hide show;');
  testUnparseTopLevelWithMetadata('export "søhest" show a,hide hide a,hide;');
  testUnparseTopLevelWithMetadata('export "søhest" show a,show hide a,show;');

  testUnparseTopLevelWithMetadata('export "søhest" hide a show a;');
  testUnparseTopLevelWithMetadata('export "søhest" hide hide show hide;');
  testUnparseTopLevelWithMetadata('export "søhest" hide show show show;');
  testUnparseTopLevelWithMetadata('export "søhest" hide a,hide show a,hide;');
  testUnparseTopLevelWithMetadata('export "søhest" hide a,show show a,show;');

  testUnparseTopLevelWithMetadata('export "søhest" show a show a;');
  testUnparseTopLevelWithMetadata('export "søhest" show hide show hide;');
  testUnparseTopLevelWithMetadata('export "søhest" show show show show;');
  testUnparseTopLevelWithMetadata('export "søhest" show a,hide show a,hide;');
  testUnparseTopLevelWithMetadata('export "søhest" show a,show show a,show;');

  testUnparseTopLevelWithMetadata('export "søhest" hide a hide a;');
  testUnparseTopLevelWithMetadata('export "søhest" hide hide hide hide;');
  testUnparseTopLevelWithMetadata('export "søhest" hide show hide show;');
  testUnparseTopLevelWithMetadata('export "søhest" hide a,hide hide a,hide;');
  testUnparseTopLevelWithMetadata('export "søhest" hide a,show hide a,show;');
}

testDeferredImport() {
  testUnparseTopLevelWithMetadata('import "lib.dart" as a;');
  testUnparseTopLevelWithMetadata('import "lib.dart" deferred as a;');
  testUnparseTopLevelWithMetadata('import "lib.dart" deferred as a show b;');
  testUnparseTopLevelWithMetadata('import "lib.dart" deferred as a hide b;');
}

testUnparseMemberAndAsMemberOfFoo(String code) {
  testUnparseMember(code);
  testUnparseTopLevelWithMetadata('class Foo{$code}');
}

testRedirectingFactoryConstructors() {
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=Bar;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=prefix.Bar;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=prefix.Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=prefix.Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=prefix.Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo("factory Foo()=prefix.Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "factory Foo()=prefix.Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=Bar;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "const factory Foo()=Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=prefix.Bar;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=prefix.Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=prefix.Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "const factory Foo()=prefix.Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo("const factory Foo()=prefix.Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "const factory Foo()=prefix.Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=Bar;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "external factory Foo()=Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=prefix.Bar;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=prefix.Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("external factory Foo()=prefix.Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "external factory Foo()=prefix.Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "external factory Foo()=prefix.Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "external factory Foo()=prefix.Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo("external const factory Foo()=Bar;");
  testUnparseMemberAndAsMemberOfFoo("external const factory Foo()=Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo("external const factory Foo()=Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=Bar<List<T>,T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=prefix.Bar;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=prefix.Bar.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=prefix.Bar<T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=prefix.Bar<List<T>,T>;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=prefix.Bar<T>.baz;");
  testUnparseMemberAndAsMemberOfFoo(
      "external const factory Foo()=prefix.Bar<List<T>,T>.baz;");
}

testClassDeclarations() {
  testUnparseTopLevelWithMetadata('class Foo{}');
  testUnparseTopLevelWithMetadata('abstract class Foo{}');
  testUnparseTopLevelWithMetadata('class Fisk{operator-(x){}}');
}

testMixinApplications() {
  testUnparseTopLevelWithMetadata('class C = S with M;');
  testUnparseTopLevelWithMetadata('class C = S with M1,M2;');
  testUnparseTopLevelWithMetadata('class C = S with M1,M2,M3;');

  testUnparseTopLevelWithMetadata('class C<A> = S with M;');
  testUnparseTopLevelWithMetadata('class C<A,B> = S with M;');

  testUnparseTopLevelWithMetadata('class C = S<A> with M;');
  testUnparseTopLevelWithMetadata('class C = S<A,B> with M;');

  testUnparseTopLevelWithMetadata('class C = S with M<A>;');
  testUnparseTopLevelWithMetadata('class C = S with M<A,B>;');
  testUnparseTopLevelWithMetadata('class C = S with M1<A>,M2;');
  testUnparseTopLevelWithMetadata('class C = S with M1,M2<A,B>;');

  testUnparseTopLevelWithMetadata('abstract class C = S with M;');
  testUnparseTopLevelWithMetadata('abstract class C<A> = S<A> with M<A>;');
}

testUnparseParameters(List<String> variableDeclarations) {
  var sb = new StringBuffer();
  sb.write('Constructor(');
  int index = 0;
  for (String variableDeclaration in variableDeclarations) {
    if (index != 0) {
      sb.write(', ');
    }
    sb.write(variableDeclaration);
    index++;
  }
  sb.write(');');

  FunctionExpression node = parseMember(sb.toString());
  index = 0;
  for (VariableDefinitions parameter in node.parameters.nodes) {
    Expect.equals(variableDeclarations[index], unparse(parameter));
    index++;
  }

}

testParameters() {
  testUnparseParameters(
      ["foo", "bar=0", "int baz", "int boz=0"]);
  testUnparseParameters(
      ["this.foo", "this.bar=0", "int this.baz", "int this.boz=0"]);
  testUnparseParameters(
      ["foo()", "void bar()", "int baz(a)", "int boz(int a,int b)=null"]);
  testUnparseParameters(
      ["this.foo()",
       //"void this.bar()", // Commented out due to Issue 7852
       //"int this.baz(a)", // Commented out due to Issue 7852
       //"int this.boz(int a,int b)=null" // Commented out due to Issue 7852
       ]);
  testUnparseParameters(
      ["@a foo", "@b @c bar=0", "@D(0) int baz", "@E([f],{g:h}) int boz=0"]);
}

testSymbolLiterals() {
  testUnparse("#+;");
  testUnparse("#-;");
  testUnparse("#*;");
  testUnparse("#/;");
  testUnparse("#~/;");
  testUnparse("#%;");
  testUnparse("#<;");
  testUnparse("#<=;");
  testUnparse("#>;");
  testUnparse("#>=;");
  testUnparse("#==;");
  testUnparse("#&;");
  testUnparse("#|;");
  testUnparse("#^;");

  testUnparse("#a;");
  testUnparse("#a.b;");
  testUnparse("#a.b.c;");
  testUnparse("#aa.bb.cc.dd;");
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
  testSimpleObjectInstantiation();
  testLibraryName();
  testImport();
  testExport();
  testPart();
  testPartOf();
  testCombinators();
  testDeferredImport();
  testRedirectingFactoryConstructors();
  testClassDeclarations();
  testMixinApplications();
  testParameters();
  testSymbolLiterals();
}
