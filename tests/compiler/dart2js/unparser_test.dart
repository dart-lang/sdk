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
interface Object {}
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
''';

testDart2Dart(String src, void continuation(String s)) {
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
}

testNativeMethods() {
  testUnparseMember('foo()native;');
  testUnparseMember('foo()native "bar";');
  testUnparseMember('foo()native "this.x = 41";');
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

main() {
  testGenericTypes();
  testForLoop();
  testEmptyList();
  testClosure();
  testIndexedOperatorDecl();
  testNativeMethods();
  testSimpleFileUnparse();
}
