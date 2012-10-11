// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('dart:uri');
#import('parser_helper.dart');
#import('mock_compiler.dart');
#import("../../../lib/compiler/implementation/tree/tree.dart");

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

testRedirectingFactoryConstructors() {
  testUnparseMember("factory Foo() = Bar;");
  testUnparseMember("factory Foo() = Bar.baz;");
  testUnparseMember("factory Foo() = Bar<T>;");
  testUnparseMember("factory Foo() = Bar<T>.baz;");
  testUnparseMember("factory Foo() = prefix.Bar;");
  testUnparseMember("factory Foo() = prefix.Bar.baz;");
  testUnparseMember("factory Foo() = prefix.Bar<T>;");
  testUnparseMember("factory Foo() = prefix.Bar<T>.baz;");
  testUnparseMember("const factory Foo() = Bar;");
  testUnparseMember("const factory Foo() = Bar.baz;");
  testUnparseMember("const factory Foo() = Bar<T>;");
  testUnparseMember("const factory Foo() = Bar<T>.baz;");
  testUnparseMember("const factory Foo() = prefix.Bar;");
  testUnparseMember("const factory Foo() = prefix.Bar.baz;");
  testUnparseMember("const factory Foo() = prefix.Bar<T>;");
  testUnparseMember("const factory Foo() = prefix.Bar<T>.baz;");
  testUnparseMember("external factory Foo() = Bar;");
  testUnparseMember("external factory Foo() = Bar.baz;");
  testUnparseMember("external factory Foo() = Bar<T>;");
  testUnparseMember("external factory Foo() = Bar<T>.baz;");
  testUnparseMember("external factory Foo() = prefix.Bar;");
  testUnparseMember("external factory Foo() = prefix.Bar.baz;");
  testUnparseMember("external factory Foo() = prefix.Bar<T>;");
  testUnparseMember("external factory Foo() = prefix.Bar<T>.baz;");
  testUnparseMember("external const factory Foo() = Bar;");
  testUnparseMember("external const factory Foo() = Bar.baz;");
  testUnparseMember("external const factory Foo() = Bar<T>;");
  testUnparseMember("external const factory Foo() = Bar<T>.baz;");
  testUnparseMember("external const factory Foo() = prefix.Bar;");
  testUnparseMember("external const factory Foo() = prefix.Bar.baz;");
  testUnparseMember("external const factory Foo() = prefix.Bar<T>;");
  testUnparseMember("external const factory Foo() = prefix.Bar<T>.baz;");
}

testClassDeclarations() {
  testUnparseTopLevelWithMetadata('class Foo{}');
  testUnparseTopLevelWithMetadata('abstract class Foo{}');
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
  testRedirectingFactoryConstructors();
  testClassDeclarations();
}
