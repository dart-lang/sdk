// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer_plugin/src/utilities/change_builder/dart/syntactic_scope.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../../support/abstract_context.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotSyntacticScopeReferencedNamesCollectorTest);
    defineReflectiveTests(SyntacticScopeNamesCollectorTest);
  });
}

@reflectiveTest
class NotSyntacticScopeReferencedNamesCollectorTest
    extends AbstractContextTest {
  test_notSyntacticScopeNames() async {
    var path = convertPath('/home/test/lib/test.dart');

    newFile('/home/test/lib/a.dart', content: r'''
var N1;
''');

    newFile(path, content: r'''
import 'package:test/a.dart';

class A {
  var N2;
  
  void N3() {}
  
  get N4 => null;
  
  set N5(_) {}
}

var S1;

class B<S2> extends A {
  var S3;
  
  void S4() {}
  
  get S5 => null;
  
  set S6(_) {}
  
  void f<S7>(S8) {
    var S9;
    N1;
    N1 = 0;
    N2;
    N3;
    N4;
    N5 = 0;
    B;
    S1;
    S1 = 0;
    S2;
    S3;
    S4;
    S5;
    S6 = 0;
    S7;
    S8;
    S9;
  }
}
''');

    var resolvedUnit = await session.getResolvedUnit(path);
    var collector = NotSyntacticScopeReferencedNamesCollector(
      resolvedUnit.libraryElement,
      (<String>[]
            ..addAll(List.generate(20, (i) => 'N$i'))
            ..addAll(List.generate(20, (i) => 'S$i')))
          .toSet(),
    );
    resolvedUnit.unit.accept(collector);

    expect(
      collector.importedNames,
      containsPair('N1', Uri.parse('package:test/a.dart')),
    );

    expect(
      collector.inheritedNames,
      unorderedEquals(['N2', 'N3', 'N4', 'N5']),
    );
  }

  test_referencedNames() async {
    var path = convertPath('/home/test/lib/test.dart');
    newFile(path, content: r'''
class N1 {}

N2 N3<N4>(N5 N6, N7) {
  N7.N8(N9);
}
''');

    var resolvedUnit = await session.getResolvedUnit(path);
    var collector = NotSyntacticScopeReferencedNamesCollector(
      resolvedUnit.libraryElement,
      <String>[].toSet(),
    );
    resolvedUnit.unit.accept(collector);

    expect(
      collector.referencedNames,
      unorderedEquals(['N1', 'N2', 'N3', 'N4', 'N5', 'N6', 'N7', 'N8', 'N9']),
    );
  }
}

@reflectiveTest
class SyntacticScopeNamesCollectorTest extends AbstractContextTest {
  test_Block() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  N2 N3, N4;
  ^2
  {
    ^3
    var N5;
    ^4
  }
  ^5
  var N6;
  ^6
  {
    ^7
    var N7;
    ^8
  }
  ^9
}
''', expected: r'''
1: N3, N4, N6
2: N3, N4, N6
3: N3, N4, N5, N6
4: N3, N4, N5, N6
5: N3, N4, N6
6: N3, N4, N6
7: N3, N4, N6, N7
8: N3, N4, N6, N7
9: N3, N4, N6
''');
  }

  test_CatchClause() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  try {
    var N2;
    ^2
  } on N3 catch (N4, N5) {
    ^3
  } catch (N6) {
    ^4
  }
  ^5
}
''', expected: r'''
1: {}
2: N2
3: N4, N5
4: N6
5: {}
''');
  }

  test_ClassDeclaration() {
    _assertScopeNames(code: r'''
class N1<N2 ^1> extends ^2 N3<N4 ^3> with ^4 N5, N6 implements ^5 N7, N8 {
  ^6
  N9 N10, N11;
  
  N1.N12() {}
  
  N13 N14<N15>() {}
  
  ^7
}

class N16<N17> {
  ^8
}
''', expected: r'''
1: N2
2: N2
3: N2
4: N2
5: N2
6: N2, N10, N11, N14
7: N2, N10, N11, N14
8: N17
''');
  }

  test_ClassTypeAlias() {
    _assertScopeNames(code: r'''
class N1<N2 ^1> = N3<N4 ^2> with N5<N6 ^3> implements N7;
''', expected: r'''
1: N2
2: N2
3: N2
''');
  }

  test_CollectionForElement_ForEachPartsWithDeclaration() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  [
    0 ^1,
    for (var N2 in N3 ^2) {
      ^3
    },
    ^4
    for (var N4 in N5) {
      ^5
    },
    ^6
  ];
  ^7
}
''', expected: r'''
1: {}
2: {}
3: N2
4: {}
5: N4
6: {}
7: {}
''');
  }

  test_CollectionForElement_ForPartsWithDeclarations() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  [
    0 ^1,
    for (var N2 = 0 ^2; ^3; ^4) {
      ^5
    },
    ^6
    for (var N3 = 0 ^7; ^8; ^9) {
      ^10
    },
    ^11
  ];
  ^12
}
''', expected: r'''
1: {}
2: N2
3: N2
4: N2
5: N2
6: {}
7: N3
8: N3
9: N3
10: N3
11: {}
12: {}
''');
  }

  test_ConstructorDeclaration() {
    _assertScopeNames(code: r'''
class N1<N2> extends N3 {
  N1.N4(N5, this.N6, ^1) {
    ^2
  }
  ^3
}
''', expected: r'''
1: N2, N5, N6
2: N2, N5, N6
3: N2
''');
  }

  test_ForEachStatement_identifier() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N2 in N3 ^2) {
    ^3
  }
  ^4
}
''', expected: r'''
1: {}
2: {}
3: {}
4: {}
''');
  }

  test_ForEachStatement_iterable() {
    _assertScopeNames(code: r'''
N1() {
  for (var N2 in (){ var N3; ^1 }()) {
    ^2
  }
  ^3
}
''', expected: r'''
1: N3
2: N2
3: {}
''');
  }

  test_ForEachStatement_loopVariable() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (var N2 in N3 ^2) {
    ^3
  }
  ^4
}
''', expected: r'''
1: {}
2: {}
3: N2
4: {}
''');
  }

  test_FormalParameter_functionTyped() {
    _assertScopeNames(code: r'''
N1 N2(N3 N4(N5 N6 ^1, N7), N8 ^2) {
  ^3
}
''', expected: r'''
1: N4, N6, N7, N8
2: N4, N8
3: N4, N8
''');
  }

  test_FormalParameter_nameOnly() {
    _assertScopeNames(code: r'''
N1 N2(^1N3^2) {
  ^3
}
''', expected: r'''
1: {}
2: {}
3: N3
''');
  }

  test_ForStatement2_ForEachPartsWithDeclaration() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (var N2 in N3 ^2) {
    ^3
  }
  ^4
}
''', expected: r'''
1: {}
2: {}
3: N2
4: {}
''');
  }

  test_ForStatement2_ForEachPartsWithIdentifier() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N2 in N3 ^2) {
    ^3
  }
  ^4
}
''', expected: r'''
1: {}
2: {}
3: {}
4: {}
''');
  }

  test_ForStatement2_ForPartsWithDeclarations_condition() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N1 N2; (){ var N3; ^2 }(); ^3) {
    ^4
  }
  ^5
}
''', expected: r'''
1: {}
2: N2, N3
3: N2
4: N2
5: {}
''');
  }

  test_ForStatement2_ForPartsWithDeclarations_updaters() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N1 N2; ^2; (){ var N3; ^3 }()) {
    ^4
  }
  ^5
}
''', expected: r'''
1: {}
2: N2
3: N2, N3
4: N2
5: {}
''');
  }

  test_ForStatement2_ForPartsWithDeclarations_variables() {
    _enableExperiments();
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N2 N3, N4 ^2; N5 ^3; N6 ^4) {
    ^5
  }
  ^6
}
''', expected: r'''
1: {}
2: N3, N4
3: N3, N4
4: N3, N4
5: N3, N4
6: {}
''');
  }

  test_ForStatement_condition() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N1 N2; (){ var N3; ^2 }(); ^3) {
    ^4
  }
  ^5
}
''', expected: r'''
1: {}
2: N2, N3
3: N2
4: N2
5: {}
''');
  }

  test_ForStatement_updaters() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N1 N2; ^2; (){ var N3; ^3 }()) {
    ^4
  }
  ^5
}
''', expected: r'''
1: {}
2: N2
3: N2, N3
4: N2
5: {}
''');
  }

  test_ForStatement_variables() {
    _assertScopeNames(code: r'''
N1() {
  ^1
  for (N2 N3, N4 ^2; N5 ^3; N6 ^4) {
    ^5
  }
  ^6
}
''', expected: r'''
1: {}
2: N3, N4
3: N3, N4
4: N3, N4
5: N3, N4
6: {}
''');
  }

  test_FunctionDeclaration() {
    _assertScopeNames(code: r'''
N1 N2<N3 extends N4 ^1>(N5 N6 ^2, [N7 N8 = N9, N10]) {
  ^3
}
''', expected: r'''
1: N3
2: N3, N6, N8, N10
3: N3, N6, N8, N10
''');
  }

  test_FunctionTypeAlias() {
    _assertScopeNames(code: r'''
typedef N1 N2<N3 ^1>(N3 N4, N5 ^2);
''', expected: r'''
1: N3
2: N3, N4, N5
''');
  }

  test_GenericFunctionType() {
    _assertScopeNames(code: r'''
N1 Function<N2 ^1>(N3, N4 N5 ^2) N6;
''', expected: r'''
1: N2
2: N2, N5
''');
  }

  test_GenericTypeAlias() {
    _assertScopeNames(code: r'''
typedef N1<N2 ^1> = Function<N3 ^2>(N4 N5, N6 ^3);
''', expected: r'''
1: N2
2: N2, N3
3: N2, N3, N5
''');
  }

  test_MethodDeclaration() {
    _assertScopeNames(code: r'''
class N1<N2> {
  N3 N4, N5;
  
  ^1
  
  N6 ^2 N7<N8 ^3>(N9 N10, N11 ^4) {
    ^5
  }
}
''', expected: r'''
1: N2, N4, N5, N7
2: N2, N4, N5, N7, N8
3: N2, N4, N5, N7, N8
4: N2, N4, N5, N7, N8, N10, N11
5: N2, N4, N5, N7, N8, N10, N11
''');
  }

  test_MixinDeclaration() {
    _assertScopeNames(code: r'''
mixin N1<N2> on N3, N4 ^1 implements N5 ^2 {
  ^3
  N6 N7, N8;
  ^4
  
  N9(N10 ^5) {
    ^6
  }
  
  ^7
}
''', expected: r'''
1: N2
2: N2
3: N2, N7, N8, N9
4: N2, N7, N8, N9
5: N2, N7, N8, N9, N10
6: N2, N7, N8, N9, N10
7: N2, N7, N8, N9
''');
  }

  void _assertScopeNames({String code, String expected}) {
    var matches = RegExp(r'\^\d{1,2}').allMatches(code).toList();

    var matchOffsets = <String, int>{};
    var delta = 0;
    for (var match in matches) {
      var newStart = match.start - delta;
      var newEnd = match.end - delta;
      matchOffsets[code.substring(newStart + 1, newEnd)] = newStart;
      delta += match.end - match.start;
      code = code.substring(0, newStart) + code.substring(newEnd);
    }

    var path = convertPath('/home/test/lib/a.dart');
    newFile(path, content: code);

    var parsedResult = session.getParsedUnit(path);
    expect(parsedResult.errors, isEmpty);

    var unit = parsedResult.unit;
    var buffer = StringBuffer();
    for (var offsetName in matchOffsets.keys) {
      var offset = matchOffsets[offsetName];
      var nameSet = Set<String>();

      unit.accept(SyntacticScopeNamesCollector(nameSet, offset));

      var nameList = nameSet.toList();
      nameList.sort((a, b) {
        expect(a.startsWith('N'), isTrue);
        expect(b.startsWith('N'), isTrue);
        return int.parse(a.substring(1)) - int.parse(b.substring(1));
      });

      buffer.write('$offsetName: ');
      if (nameList.isEmpty) {
        buffer.writeln('{}');
      } else {
        buffer.writeln(nameList.join(', '));
      }
    }

    var actual = buffer.toString();
    if (actual != expected) {
      print(actual);
    }
    expect(actual, expected);
  }

  void _enableExperiments() {
    createAnalysisOptionsFile(
      experiments: [
        EnableString.control_flow_collections,
        EnableString.spread_collections,
      ],
    );
  }
}
