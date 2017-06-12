// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library peg_tests;

import 'dart:core' hide Symbol;
import '../../peg/pegparser.dart';

testParens() {
  Grammar g = new Grammar();
  Symbol a = g['A'];

  a.def = ['(', MANY(a, min: 0), ')', (a) => a];

  check(g, a, "", null);
  check(g, a, "()", '[]');
  check(g, a, "(()())", '[[],[]]');
  check(g, a, "(()((()))())", '[[],[[[]]],[]]');
}

testBlockComment() {
  // Block comment in whitespace.

  Grammar g = new Grammar();
  Symbol blockComment = g['blockComment'];

  blockComment.def = [
    '/*',
    MANY(
        OR([
          blockComment,
          [NOT('*/'), CHAR()],
          [END, ERROR('EOF in block comment')]
        ]),
        min: 0),
    '*/'
  ];
  print(blockComment);

  var a = MANY(TEXT('x'));

  g.whitespace = OR([g.whitespace, blockComment]);

  check(g, a, "x /**/ x", '[x,x]');
  check(g, a, "x /*/**/*/ x", '[x,x]');
  check(g, a, "x /*/***/ x", 'EOF in block comment');
  check(g, a, "x /*/*/x**/**/ x", '[x,x]');

  check(
      g,
      a,
      r"""
/* Comment */
/* Following comment with /* nested comment*/ */
x
/* x in comment */
x /* outside comment */
""",
      '[x,x]');
}

testTEXT() {
  Grammar g = new Grammar();

  // TEXT grabs the parsed text,
  check(g, TEXT(LEX(MANY(OR(['1', 'a'])))), '  1a1  ', '1a1');

  // Without the lexical context, TEXT will grab intervening whitespace.
  check(g, TEXT(MANY(OR(['1', 'a']))), '  1a1  ', '1a1');
  check(g, TEXT(MANY(OR(['1', 'a']))), '  1  a 1  ', '1  a 1');

  // Custom processing of the TEXT substring.
  var binaryNumber = TEXT(LEX(MANY(OR(['0', '1']))), (str, start, end) {
    var r = 0;
    var zero = '0'.codeUnitAt(0);
    for (int i = start; i < end; i++) r = r * 2 + (str.codeUnitAt(i) - zero);
    return r;
  });

  check(g, binaryNumber, ' 10101 ', 21);
  check(g, binaryNumber, '1010111', 87);
  check(g, binaryNumber, '1010 111', null);
}

testOR() {
  // OR matches the first match.
  Grammar g = new Grammar();
  check(
      g,
      OR([
        ['a', NOT(END), () => 1],
        ['a', () => 2],
        ['a', () => 3]
      ]),
      'a',
      2);
}

testCODE() {
  Grammar g = new Grammar();
  var a = TEXT(LEX('thing', MANY(CHAR('bcd'))));

  check(g, a, 'bbb', 'bbb');
  check(g, a, 'ccc', 'ccc');
  check(g, a, 'ddd', 'ddd');
  check(g, a, 'bad', null); // a is outside range.
  check(g, a, 'bed', null); // e is outside range.
}

testC() {
  // Curried tree builders.
  binary(operation) => (second) => (first) => [operation, first, second];
  unary(operation) => () => (first) => [operation, first];
  reform(a, fns) {
    var r = a;
    for (var fn in fns) r = fn(r);
    return r;
  }

  Grammar g = new Grammar();

  Symbol expression = g['expression'];
  Symbol postfix_e = g['postfix_e'];
  Symbol unary_e = g['unary_e'];
  Symbol cast_e = g['cast_e'];
  Symbol mult_e = g['mult_e'];
  Symbol add_e = g['add_e'];
  Symbol shift_e = g['shift_e'];
  Symbol relational_e = g['relational_e'];
  Symbol equality_e = g['equality_e'];
  Symbol cond_e = g['cond_e'];
  Symbol assignment_e = g['assignment_e'];

  // Lexical elements.
  var idStartChar =
      CHAR(r"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz");
  var idNextChar =
      CHAR(r"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789$_");

  var id = TEXT(LEX('identifier', [idStartChar, MANY(idNextChar, min: 0)]));

  var lit = TEXT(LEX('literal', MANY(CHAR('0123456789'))));

  var type_name = id;

  // Expression grammar.
  var primary_e = OR([
    id,
    lit,
    ['(', expression, ')', (e) => e]
  ]);

  var postfixes = OR([
    ['(', MANY(assignment_e, separator: ',', min: 0), ')', binary('apply')],
    ['++', unary('postinc')],
    ['--', unary('postdec')],
    ['.', id, binary('field')],
    ['->', id, binary('ptr')],
  ]);

  postfix_e.def = [primary_e, MANY(postfixes, min: 0), reform];

  var unary_op = OR([
    ['&', () => 'address'],
    ['*', () => 'indir'],
    ['!', () => 'not'],
    ['~', () => 'not'],
    ['-', () => 'negate'],
    ['+', () => 'uplus'],
  ]);
  var sizeof = LEX('sizeof', ['sizeof', NOT(idNextChar)]);

  Symbol unary_e_plain = g['unary_e_plain'];
  unary_e_plain.def = OR([
    [
      '++', unary_e, (e) => ['preinc', e] //
    ],
    [
      '--', unary_e, (e) => ['predec', e] //
    ],
    [
      unary_op, cast_e, (o, e) => [o, e] //
    ],
    [
      sizeof, unary_e, (e) => ['sizeof-expr', e] //
    ],
    [
      sizeof, '(', type_name, ')', (t) => ['sizeof-type', t] //
    ],
    postfix_e
  ]);

  unary_e.def = MEMO(unary_e_plain);
  //unary_e.def = unary_e_plain;

  cast_e.def = OR([
    [
      '(', type_name, ')', cast_e, (t, e) => ['cast', t, e] //
    ],
    unary_e,
  ]);

  var mult_ops = OR([
    ['*', cast_e, binary('mult')],
    ['/', cast_e, binary('div')],
    ['%', cast_e, binary('rem')],
  ]);
  mult_e.def = [cast_e, MANY(mult_ops, min: 0), reform];

  var add_ops = OR([
    ['+', mult_e, binary('add')],
    ['-', mult_e, binary('sub')],
  ]);
  add_e.def = [mult_e, MANY(add_ops, min: 0), reform];

  var shift_ops = OR([
    ['>>', add_e, binary('shl')],
    ['<<', add_e, binary('shr')],
  ]);
  shift_e.def = [add_e, MANY(shift_ops, min: 0), reform];

  var relational_ops = OR([
    ['<=', shift_e, binary('le')],
    ['>=', shift_e, binary('ge')],
    ['<', shift_e, binary('lt')],
    ['>', shift_e, binary('gt')],
  ]);
  relational_e.def = [shift_e, MANY(relational_ops, min: 0), reform];

  var equality_ops = OR([
    ['==', shift_e, binary('eq')],
    ['!=', shift_e, binary('ne')],
  ]);
  equality_e.def = [relational_e, MANY(equality_ops, min: 0), reform];

  var bit_and_op = LEX('&', ['&', NOT('&')]); // Don't see '&&' and '&', '&'
  var bit_or_op = LEX('|', ['|', NOT('|')]);

  var and_e = [
    equality_e,
    MANY([bit_and_op, equality_e, binary('bitand')], min: 0),
    reform
  ];
  var xor_e = [
    and_e,
    MANY(['^', and_e, binary('bitxor')], min: 0),
    reform
  ];
  var or_e = [
    xor_e,
    MANY([bit_or_op, xor_e, binary('bitor')], min: 0),
    reform
  ];

  var log_and_e = [
    or_e,
    MANY(['&&', or_e, binary('and')], min: 0),
    reform
  ];

  var log_or_e = [
    log_and_e,
    MANY(['||', log_and_e, binary('or')], min: 0),
    reform
  ];

  //cond_e.def = OR([ [log_or_e, '?', expression, ':', cond_e,
  //                   (p,a,b) => ['cond', p, a, b]],
  //                  log_or_e]);
  // Alternate version avoids reparsing log_or_e.
  cond_e.def = [
    log_or_e,
    MAYBE(['?', expression, ':', cond_e]),
    (p, r) => r == null || r == false ? p : ['cond', p, r[0], r[1]]
  ];

  var assign_op = OR([
    ['*=', () => 'mulassign'],
    ['=', () => 'assign']
  ]);

  // TODO: Figure out how not to re-parse a unary_e.
  // Order matters - cond_e can't go first since cond_e will succeed on, e.g. 'a'.
  assignment_e.def = OR([
    [
      unary_e,
      assign_op,
      assignment_e,
      (u, op, a) => [op, u, a]
    ],
    cond_e
  ]);

  expression.def = [
    assignment_e,
    MANY([',', assignment_e, binary('comma')], min: 0),
    reform
  ];

  show(g, expression, 'a');
  check(g, expression, 'a', 'a');
  check(g, expression, '(a)', 'a');
  check(g, expression, '  (  ( a ) ) ', 'a');

  check(g, expression, 'a(~1,2)', '[apply,a,[[not,1],2]]');
  check(g, expression, 'a(1)(x,2)', '[apply,[apply,a,[1]],[x,2]]');
  check(g, expression, 'a(1,2())', '[apply,a,[1,[apply,2,[]]]]');

  check(g, expression, '++a++', '[preinc,[postinc,a]]');
  check(g, expression, 'a++++b', null);
  check(g, expression, 'a++ ++b', null);
  check(g, expression, 'a+ +++b', '[add,a,[preinc,[uplus,b]]]');
  check(g, expression, 'a+ + ++b', '[add,a,[uplus,[preinc,b]]]');
  check(g, expression, 'a+ + + +b', '[add,a,[uplus,[uplus,[uplus,b]]]]');
  check(g, expression, 'a+ ++ +b', '[add,a,[preinc,[uplus,b]]]');
  check(g, expression, 'a++ + +b', '[add,[postinc,a],[uplus,b]]');
  check(g, expression, 'a+++ +b', '[add,[postinc,a],[uplus,b]]');

  check(g, expression, '((T)f)(x)', '[apply,[cast,T,f],[x]]');
  check(g, expression, '(T)f(x)', '[cast,T,[apply,f,[x]]]');

  check(g, expression, 'a++*++b', '[mult,[postinc,a],[preinc,b]]');

  check(g, expression, 'a<<1>>++b', '[shl,[shr,a,1],[preinc,b]]');

  check(g, expression, 'a<1&&b', '[and,[lt,a,1],b]');

  check(g, expression, 'a<1 & &b', '[bitand,[lt,a,1],[address,b]]');
  check(g, expression, 'a ? b ? c : d : e ? f : g',
      '[cond,a,[cond,b,c,d],[cond,e,f,g]]');

  check(g, expression, 'a,b,c', '[comma,[comma,a,b],c]');
  check(g, expression, 'a=1,b,c', '[comma,[comma,[assign,a,1],b],c]');

  check(g, expression, '((((((((((((a))))))))))))=1,b,c',
      '[comma,[comma,[assign,a,1],b],c]');

  check(g, expression, 'sizeof a', '[sizeof-expr,a]');
  check(g, expression, 'sizeofa', 'sizeofa');
  check(g, expression, 'sizeof (a)', '[sizeof-expr,a]');
}

show(grammar, rule, input) {
  print('show: "$input"');
  var ast;
  try {
    ast = grammar.parse(rule, input);
  } catch (exception) {
    if (exception is ParseError)
      ast = exception;
    else
      rethrow;
  }
  print('${printList(ast)}');
}

void check(grammar, rule, input, expected) {
  // If [expected] is String then the result is coerced to string.
  // If [expected] is !String, the result is compared directly.
  print('check: "$input"');
  var ast;
  try {
    ast = grammar.parse(rule, input);
  } catch (exception) {
    ast = exception;
  }

  var formatted = ast;
  if (expected is String) formatted = printList(ast);

  //Expect.equals(expected, formatted, "parse: $input");
  if (expected != formatted) {
    throw new ArgumentError("parse: $input"
        "\n  expected: $expected"
        "\n     found: $formatted");
  }
}

// Prints the list in [1,2,3] notation, including nested lists.
printList(item) {
  if (item is List) {
    StringBuffer sb = new StringBuffer();
    sb.write('[');
    var sep = '';
    for (var x in item) {
      sb.write(sep);
      sb.write(printList(x));
      sep = ',';
    }
    sb.write(']');
    return sb.toString();
  }
  if (item == null) return 'null';
  return item.toString();
}

main() {
  testCODE();
  testParens();
  testOR();
  testTEXT();
  testBlockComment();
  testC();
}
