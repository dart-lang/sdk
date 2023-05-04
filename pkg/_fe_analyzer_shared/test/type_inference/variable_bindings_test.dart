// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:test/test.dart';

main() {
  late _Harness h;

  setUp(() {
    h = _Harness();
  });

  group('Duplicate variable', () {
    test('In logical-and', () {
      h.runPattern(
        _And(
          _VarPattern('x', 1),
          _VarPattern('x', 2),
        ),
        expectedVariables: {'x: 1'},
        expectErrors: [
          'duplicateVariablePattern(name: x, original: 1, duplicate: 2)'
        ],
      );
    });
  });

  group('Logical-or:', () {
    group('Variable should be present in both branches:', () {
      test('Both have', () {
        h.runPattern(
          _Or(
            _VarPattern('x', 1),
            _VarPattern('x', 2),
          ),
          expectedVariables: {'x: [1, 2]'},
        );
      });
      test('Left has', () {
        h.runPattern(
          _Or(
            _VarPattern('x', 1),
            _Empty(),
            id: 2,
          ),
          expectedVariables: {'x: notConsistent:logicalOr [1]'},
          expectErrors: [
            'logicalOrPatternBranchMissingVariable(node: 2, '
                'hasInLeft: true, name: x, variable: 1)'
          ],
        );
      });
      test('Right has', () {
        h.runPattern(
          _Or(
            _Empty(),
            _VarPattern('x', 1),
            id: 2,
          ),
          expectedVariables: {'x: notConsistent:logicalOr [1]'},
          expectErrors: [
            'logicalOrPatternBranchMissingVariable(node: 2, '
                'hasInLeft: false, name: x, variable: 1)'
          ],
        );
      });
    });
  });

  group('Switch statement:', () {
    test('Both have', () {
      h.runSwitchStatementSharedBody(
        sharedCaseScopeKey: 0,
        casePatterns: [
          _VarPattern('x', 1),
          _VarPattern('x', 2),
        ],
        expectedVariables: {'x: [1, 2]'},
      );
    });
    test('First has', () {
      h.runSwitchStatementSharedBody(
        sharedCaseScopeKey: 0,
        casePatterns: [
          _VarPattern('x', 1),
          _Empty(),
        ],
        expectedVariables: {'x: notConsistent:sharedCaseAbsent [1]'},
      );
    });
    test('Second has', () {
      h.runSwitchStatementSharedBody(
        sharedCaseScopeKey: 0,
        casePatterns: [
          _Empty(),
          _VarPattern('x', 1),
        ],
        expectedVariables: {'x: notConsistent:sharedCaseAbsent [1]'},
      );
    });
    test('Partial intersection', () {
      h.runSwitchStatementSharedBody(
        sharedCaseScopeKey: 0,
        casePatterns: [
          _And(
            _VarPattern('x', 1),
            _VarPattern('y', 2),
          ),
          _VarPattern('x', 3),
        ],
        expectedVariables: {
          'x: [1, 3]',
          'y: notConsistent:sharedCaseAbsent [2]',
        },
      );
    });
    group('Has default', () {
      test('First', () {
        h.runSwitchStatementSharedBody(
          sharedCaseScopeKey: 0,
          casePatterns: [
            _VarPattern('x', 1),
          ],
          hasDefaultFirst: true, // does not happen normally
          expectedVariables: {'x: notConsistent:sharedCaseHasLabel [1]'},
        );
      });
      test('Last', () {
        h.runSwitchStatementSharedBody(
          sharedCaseScopeKey: 0,
          casePatterns: [
            _VarPattern('x', 1),
          ],
          hasDefaultLast: true,
          expectedVariables: {'x: notConsistent:sharedCaseHasLabel [1]'},
        );
      });
    });
    group('With logical-or', () {
      test('Both have', () {
        h.runSwitchStatementSharedBody(
          sharedCaseScopeKey: 0,
          casePatterns: [
            _Or(
              _VarPattern('x', 1),
              _VarPattern('x', 2),
            ),
            _VarPattern('x', 3),
          ],
          expectedVariables: {'x: [[1, 2], 3]'},
        );
      });
      test('Both have, inconsistent', () {
        h.runSwitchStatementSharedBody(
          sharedCaseScopeKey: 0,
          casePatterns: [
            _Or(
              _VarPattern('x', 1),
              _Empty(),
            ),
            _VarPattern('x', 2),
          ],
          expectedVariables: {
            'x: notConsistent:logicalOr [notConsistent:logicalOr [1], 2]',
          },
          expectErrors: [
            'logicalOrPatternBranchMissingVariable(node: null, '
                'hasInLeft: true, name: x, variable: 1)',
          ],
        );
      });
      test('First has', () {
        h.runSwitchStatementSharedBody(
          sharedCaseScopeKey: 0,
          casePatterns: [
            _Or(
              _VarPattern('x', 1),
              _VarPattern('x', 2),
            ),
            _Empty(),
          ],
          expectedVariables: {'x: notConsistent:sharedCaseAbsent [[1, 2]]'},
        );
      });
      test('Second has', () {
        h.runSwitchStatementSharedBody(
          sharedCaseScopeKey: 0,
          casePatterns: [
            _Empty(),
            _Or(
              _VarPattern('x', 1),
              _VarPattern('x', 2),
            ),
          ],
          expectedVariables: {'x: notConsistent:sharedCaseAbsent [[1, 2]]'},
        );
      });
    });
  });
}

class _And extends _Node {
  final _Node left;
  final _Node right;

  _And(this.left, this.right);

  @override
  void _visit(_Harness h) {
    left._visit(h);
    right._visit(h);
  }
}

class _Empty extends _Node {
  _Empty();

  @override
  void _visit(_Harness h) {}
}

class _Errors implements VariableBinderErrors<_Node, _VariableElement> {
  final List<String> _errors = [];

  @override
  void duplicateVariablePattern({
    required String name,
    required _VariableElement original,
    required _VariableElement duplicate,
  }) {
    _errors.add('duplicateVariablePattern(name: $name, '
        'original: $original, duplicate: $duplicate)');
  }

  @override
  void logicalOrPatternBranchMissingVariable({
    required _Node node,
    required bool hasInLeft,
    required String name,
    required _VariableElement variable,
  }) {
    _errors.add('logicalOrPatternBranchMissingVariable(node: $node, '
        'hasInLeft: $hasInLeft, name: $name, variable: $variable)');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'Unexpected error ${invocation.memberName}';
  }
}

class _Harness {
  final _Errors errors = _Errors();
  late final _binder = _VariableBinder(errors: errors);

  void runPattern(
    _Node node, {
    List<String> expectErrors = const [],
    required Set<String> expectedVariables,
  }) {
    _binder.casePatternStart();
    node._visit(this);
    var variables = _binder.casePatternFinish();
    _binder.finish();
    _assertVariables(variables, expectedVariables);
    expect(errors._errors, expectErrors);
  }

  void runSwitchStatementSharedBody({
    required Object sharedCaseScopeKey,
    required List<_Node> casePatterns,
    bool hasDefaultFirst = false,
    bool hasDefaultLast = false,
    List<String> expectErrors = const [],
    required Set<String> expectedVariables,
  }) {
    assert(!(hasDefaultFirst && hasDefaultLast));
    _binder.switchStatementSharedCaseScopeStart(sharedCaseScopeKey);
    if (hasDefaultFirst) {
      _binder.switchStatementSharedCaseScopeEmpty(sharedCaseScopeKey);
    }
    for (var casePattern in casePatterns) {
      _binder.casePatternStart();
      casePattern._visit(this);
      _binder.casePatternFinish(
        sharedCaseScopeKey: sharedCaseScopeKey,
      );
    }
    if (hasDefaultLast) {
      _binder.switchStatementSharedCaseScopeEmpty(sharedCaseScopeKey);
    }
    var variables =
        _binder.switchStatementSharedCaseScopeFinish(sharedCaseScopeKey);
    _binder.finish();
    _assertVariables(variables, expectedVariables);
    expect(errors._errors, expectErrors);
  }

  void _assertVariables(
    Map<String, _VariableElement> variables,
    Set<String> expected,
  ) {
    expect(
      variables.entries.map((e) => '${e.key}: ${e.value}').toSet(),
      expected,
    );
  }
}

abstract class _Node {
  int? id;

  _Node({this.id});

  @override
  String toString() => '$id';

  void _visit(_Harness h) {}
}

class _Or extends _Node {
  final _Node left;
  final _Node right;

  _Or(this.left, this.right, {super.id});

  @override
  void _visit(_Harness h) {
    h._binder.logicalOrPatternStart();
    left._visit(h);
    h._binder.logicalOrPatternFinishLeft();
    right._visit(h);
    h._binder.logicalOrPatternFinish(this);
  }
}

class _VariableBindElement extends _VariableElement {
  final String id;

  _VariableBindElement(this.id);

  @override
  String toString() => id;
}

class _VariableBinder extends VariableBinder<_Node, _VariableElement> {
  _VariableBinder({
    required super.errors,
  });

  @override
  _VariableElement joinPatternVariables({
    required Object? key,
    required List<_VariableElement> components,
    required JoinedPatternVariableInconsistency inconsistency,
  }) {
    return _VariableJoinElement(
      components: [
        for (var variable in components)
          if (key is _Or && variable is _VariableJoinElement)
            ...variable.components
          else
            variable
      ],
      inconsistency: inconsistency.maxWithAll(
        components.map((e) => e.inconsistency),
      ),
    );
  }
}

class _VariableElement {
  JoinedPatternVariableInconsistency get inconsistency {
    return JoinedPatternVariableInconsistency.none;
  }
}

class _VariableJoinElement extends _VariableElement {
  final List<_VariableElement> components;

  @override
  final JoinedPatternVariableInconsistency inconsistency;

  _VariableJoinElement({
    required this.components,
    required this.inconsistency,
  });

  @override
  String toString() {
    return [
      if (inconsistency != JoinedPatternVariableInconsistency.none)
        'notConsistent:${inconsistency.name}',
      components,
    ].join(' ');
  }
}

class _VarPattern extends _Node {
  final String name;
  final _VariableBindElement element;

  _VarPattern(this.name, int id)
      : element = _VariableBindElement('$id'),
        super(id: id);

  @override
  void _visit(_Harness h) {
    h._binder.add(name, element);
  }
}
