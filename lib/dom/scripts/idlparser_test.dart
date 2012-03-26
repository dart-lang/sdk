// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('idlparser_test');
#import('../../../utils/peg/pegparser.dart');
#source('idlparser.dart');
#source('idlrenderer.dart');

main() {
  IDLParser parser = new IDLParser(FREMONTCUT_SYNTAX);
  Grammar g = parser.grammar;

  var Type = g['Type'];

  show(g, Type, 'int');
  show(g, Type, 'int ?');
  show(g, Type, 'sequence<int?> ?');
  show(g, Type, 'unsigned long long?');
  show(g, Type, 'unsignedlonglong?');


  var MaybeAnnotations = g['MaybeAnnotations'];

  show(g, MaybeAnnotations, '');
  show(g, MaybeAnnotations, '@Foo');
  show(g, MaybeAnnotations, '@Foo @Bar');
  show(g, MaybeAnnotations, '@Foo(A,B=1) @Bar');

  var MaybeExtAttrs = g['MaybeExtAttrs'];
  print(MaybeExtAttrs);

  show(g, MaybeExtAttrs, '');
  show(g, MaybeExtAttrs, '[A]');

  var Module = g['Module'];

  show(g, Module, 'module Harry { const int bob = 30;};');
  show(g, Module, """
module Harry { [X,Y,Z=99] const int bob = 30; typedef x y;

  interface Thing : SuperA, @Friendly SuperB {

    [Nice] const unsigned long long kFoo = 12345;
    [A,B,C,D,E] attribute int attr1;
    [F=f(int a),K=99,DartName=Bert] int smudge(int a, int b, double x);

    [X,Y,Z] int xyz([U,V] optional in optional int z);
    [P,Q,R] int pqr();
    int op1();
    @Smurf @Beans(B=1,C,A=2) int op2();

    snippet { yadda
              yadda
    };
  };

//[A] const unsigned long long dweeb = 0xff;

};
""");
}



show(grammar, rule, input) {
  print('show: "$input"');
  var ast;
  try {
    ast = grammar.parse(rule, input);
  } catch (var exception) {
    if (exception is ParseError)
      ast = exception;
    else
      throw;
  }
  print('${printList(ast)}');
  print(render(ast));
}

void check(grammar, rule, input, expected) {
  // If [expected] is String then the result is coerced to string.
  // If [expected] is !String, the result is compared directly.
  print('check: "$input"');
  var ast;
  try {
    ast = grammar.parse(rule, input);
  } catch (var exception) {
    ast = exception;
  }

  var formatted = ast;
  if (expected is String)
    formatted = printList(ast);

  Expect.equals(expected, formatted, "parse: $input");
}

// Prints the list in [1,2,3] notation, including nested lists.
void printList(item) {
  if (item is List) {
    StringBuffer sb = new StringBuffer();
    sb.add('[');
    var sep = '';
    for (var x in item) {
      sb.add(sep);
      sb.add(printList(x));
      sep = ',';
    }
    sb.add(']');
    return sb.toString();
  }
  if (item == null)
    return 'null';
  return item.toString();
}
