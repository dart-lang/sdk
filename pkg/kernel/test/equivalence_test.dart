// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/src/equivalence.dart';

final Component component1 = createComponent();
final Component component2 = createComponent();

List<Test> tests = [
  Test(IntLiteral(0), IntLiteral(0)),
  Test(IntLiteral(42), IntLiteral(42)),
  Test(IntLiteral(0), IntLiteral(42), inequivalence: '''
Values 0 and 42 are not equivalent
.root
 IntLiteral.value
'''),
  Test(StringLiteral('0'), StringLiteral('0')),
  Test(StringLiteral('42'), StringLiteral('42')),
  Test(StringLiteral('0'), StringLiteral('42'), inequivalence: '''
Values 0 and 42 are not equivalent
.root
 StringLiteral.value
'''),
  Test(IntLiteral(0), IntLiteral(42), strategy: const IgnoreIntLiteralValue()),
  Test(StringLiteral('0'), StringLiteral('42'),
      strategy: const IgnoreIntLiteralValue(), inequivalence: '''
Values 0 and 42 are not equivalent
.root
 StringLiteral.value
'''),
  Test(IntLiteral(0), StringLiteral('0'), inequivalence: '''
Inequivalent nodes
1: IntLiteral(0)
2: StringLiteral("0")
.root
'''),
  Test(Not(Not(Not(BoolLiteral(true)))), Not(Not(Not(BoolLiteral(true))))),
  Test(Not(Not(BoolLiteral(true))), Not(Not(Not(BoolLiteral(true)))),
      inequivalence: '''
Inequivalent nodes
1: BoolLiteral(true)
2: Not(!true)
.root
 Not.operand
  Not.operand
'''),
  Test(Not(Not(Not(BoolLiteral(true)))), Not(Not(BoolLiteral(true))),
      inequivalence: '''
Inequivalent nodes
1: Not(!true)
2: BoolLiteral(true)
.root
 Not.operand
  Not.operand
'''),
  Test(Not(Not(Not(BoolLiteral(true)))), Not(Not(Not(BoolLiteral(false)))),
      inequivalence: '''
Values true and false are not equivalent
.root
 Not.operand
  Not.operand
   Not.operand
    BoolLiteral.value
'''),
  Test(component1, component2),
  Test(component1.libraries[0], component2.libraries[0]),
  Test(component1.libraries[0], component2.libraries[1], inequivalence: '''
Inequivalent nodes
1: library import://uri1
2: library import://uri2
.root
'''),
  Test(component1.libraries[1], component2.libraries[2], inequivalence: '''
Inequivalent nodes
1: library import://uri2
2: library import://uri3
.root
'''),
  Test(component1.libraries[1], component2.libraries[3], inequivalence: '''
Values file://uri2/ and file://uri3/ are not equivalent
.root
 Library(library import://uri2).fileUri
'''),
  Test(component1.libraries[0].procedures[0],
      component2.libraries[0].procedures[1],
      inequivalence: '''
Inequivalent nodes
1: foo
2: bar
.root
'''),
  // TODO(johnniwinther): Improve message for inequivalent references with the
  // same simple name.
  Test(component1.libraries[0].procedures[0],
      component2.libraries[2].procedures[0],
      inequivalence: '''
Inequivalent nodes
1: foo
2: foo
.root
'''),
  Test(StaticTearOff.byReference(Reference()),
      StaticTearOff.byReference(Reference())),
  Test(
      StaticTearOff.byReference(
          component1.libraries[0].procedures[0].reference),
      StaticTearOff.byReference(
          component2.libraries[0].procedures[0].reference)),
  // TODO(johnniwinther): Improve message for inequivalent references with the
  // same simple name.
  Test(
      StaticTearOff.byReference(
          component1.libraries[0].procedures[0].reference),
      StaticTearOff.byReference(
          component2.libraries[2].procedures[0].reference),
      inequivalence: '''
Inequivalent references:
1: Reference to foo
2: Reference to foo
.root
 StaticTearOff.targetReference
'''),
];

void main() {
  for (Test test in tests) {
    EquivalenceResult result =
        checkEquivalence(test.a, test.b, strategy: test.strategy);
    if (test.isEquivalent) {
      Expect.equals(result.isEquivalent, test.isEquivalent,
          'Unexpected result for\n${test.a}\n${test.b}:\n$result');
    } else if (result.isEquivalent) {
      Expect.equals(
          result.isEquivalent,
          test.isEquivalent,
          'Unexpected equivalence for\n${test.a}\n${test.b}:\n'
          'Expected ${test.inequivalence}');
    } else {
      Expect.stringEquals(
          result.toString(),
          test.inequivalence!,
          'Unexpected inequivalence result for\n${test.a}\n${test.b}:\n'
          'Expected:\n---\n${test.inequivalence}\n---\n'
          'Actual:\n---\n${result}\n---');
    }
  }
}

class Test {
  final Node a;
  final Node b;
  final String? inequivalence;
  final EquivalenceStrategy strategy;

  Test(this.a, this.b,
      {this.inequivalence, this.strategy = const EquivalenceStrategy()});

  bool get isEquivalent => inequivalence == null;
}

class IgnoreIntLiteralValue extends EquivalenceStrategy {
  const IgnoreIntLiteralValue();

  @override
  bool checkIntLiteral_value(
          EquivalenceVisitor visitor, IntLiteral a, IntLiteral b) =>
      true;
}

Component createComponent() {
  Component component = new Component();
  Uri fileUri1 = Uri.parse('file://uri1');
  Uri fileUri2 = Uri.parse('file://uri2');
  Uri fileUri3 = Uri.parse('file://uri3');
  Uri importUri1 = Uri.parse('import://uri1');
  Uri importUri2 = Uri.parse('import://uri2');
  Uri importUri3 = Uri.parse('import://uri3');
  Library library1 = new Library(importUri1, fileUri: fileUri1);
  component.libraries.add(library1);
  Procedure procedure1foo = new Procedure(
      new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: fileUri1);
  library1.addProcedure(procedure1foo);
  Procedure procedure1bar = new Procedure(
      new Name('bar'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: fileUri1);
  library1.addProcedure(procedure1bar);

  Library library2 = new Library(importUri2, fileUri: fileUri2);
  component.libraries.add(library2);

  Library library3 = new Library(importUri3, fileUri: fileUri2);
  component.libraries.add(library3);
  Procedure procedure3foo = new Procedure(
      new Name('foo'), ProcedureKind.Method, new FunctionNode(null),
      fileUri: fileUri1);
  library3.addProcedure(procedure3foo);

  Library library4 = new Library(importUri2, fileUri: fileUri3);
  component.libraries.add(library4);

  return component;
}
