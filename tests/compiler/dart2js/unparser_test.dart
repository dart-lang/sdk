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
}
