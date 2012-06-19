// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#import('parser_helper.dart');
#import("../../../lib/compiler/implementation/tree/tree.dart");

testUnparse(String statement) {
  Node node = parseStatement(statement);
  Expect.equals(statement, node.unparse());
}

testUnparseMember(String member) {
  Node node = parseMember(member);
  Expect.equals(member, node.unparse());
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

testIndexedOperatorDecl() {
  testUnparseMember('operator[](int i)=> null;');
}

main() {
  testGenericTypes();
  testForLoop();
  testEmptyList();
  testIndexedOperatorDecl();
}
