// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/type_analyzer.dart';
import 'package:_fe_analyzer_shared/src/type_inference/type_operations.dart';
import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:test/test.dart';

main() {
  late _Harness h;

  setUp(() {
    h = _Harness();
  });

  test('Explicitly typed var', () {
    h.run(_VarPattern('int', 'x'), expectEntries: ['int x']);
  });

  test('Implicitly typed var', () {
    h.run(_VarPattern('double', 'y', isImplicitlyTyped: true),
        expectEntries: ['double y (implicit)']);
  });

  test('Multiple vars', () {
    h.run(_And([_VarPattern('int', 'x'), _VarPattern('int', 'y')]),
        expectEntries: ['int x', 'int y']);
  });

  test('Variable overlap', () {
    h.run(
        _And(
            [_VarPattern('int', 'x')..id = 1, _VarPattern('int', 'x')..id = 2]),
        expectErrors: [
          'matchVarOverlap(pattern: 2: int x, previousPattern: 1: int x)'
        ]);
  });

  group('Alternative:', () {
    test('Consistent', () {
      h.run(
          _Or([
            _VarPattern('int', 'x', expectNew: true),
            _VarPattern('int', 'x', expectNew: false)
          ]),
          expectEntries: ['int x']);
    });

    test('Does not bind unmentioned variables', () {
      // Even though the variable 'y' has already been seen at the time the
      // nested `_Or` is visited, it's important that the nested `_Or` not be
      // construed to bind the variable 'y'.  Otherwise the variable pattern for
      // `y` that follows would be incorrectly considered an error.
      h.run(_Or([
        _And([_VarPattern('int', 'x'), _VarPattern('int', 'y')]),
        _And([
          _Or([_VarPattern('int', 'x'), _VarPattern('int', 'x')]),
          _VarPattern('int', 'y')
        ])
      ]));
    });

    group('Missing var:', () {
      test('On left', () {
        h.run(_Or([_Empty(), _VarPattern('int', 'x')]),
            expectErrors: ['missingMatchVar((), x)']);
      });

      test('On right', () {
        h.run(_Or([_VarPattern('int', 'x'), _Empty()]),
            expectErrors: ['missingMatchVar((), x)']);
      });

      test('Middle of three', () {
        h.run(_Or([_VarPattern('int', 'x'), _Empty(), _VarPattern('int', 'x')]),
            expectErrors: ['missingMatchVar((), x)']);
      });
    });

    group('Inconsistent type:', () {
      test('Explicit', () {
        h.run(_Or([_VarPattern('int', 'x'), _VarPattern('double', 'x')]),
            expectErrors: [
              'inconsistentMatchVar(pattern: double x, type: double, '
                  'previousPattern: int x, previousType: int)'
            ]);
      });

      test('Implicit', () {
        h.run(
            _Or([
              _VarPattern('int', 'x', isImplicitlyTyped: true),
              _VarPattern('double', 'x', isImplicitlyTyped: true)
            ]),
            expectErrors: [
              'inconsistentMatchVar(pattern: double x (implicit), '
                  'type: double, previousPattern: int x (implicit), '
                  'previousType: int)'
            ]);
      });

      test('Third var', () {
        h.run(
            _Or([
              _VarPattern('int', 'x')..id = 1,
              _VarPattern('int', 'x')..id = 2,
              _VarPattern('double', 'x')
            ]),
            expectErrors: [
              'inconsistentMatchVar(pattern: double x, type: double, '
                  'previousPattern: 2: int x, previousType: int)'
            ]);
      });
    });

    group('Inconsistent explicitness:', () {
      test('Mismatch', () {
        h.run(
            _Or([
              _VarPattern('int', 'x'),
              _VarPattern('int', 'x', isImplicitlyTyped: true)
            ]),
            expectErrors: [
              'inconsistentMatchVarExplicitness(pattern: int x (implicit), '
                  'previousPattern: int x)'
            ]);
      });
    });
  });

  group('Recovery:', () {
    test('Overlap after missing', () {
      h.run(
          _And([
            _Or([_VarPattern('int', 'x')..id = 1, _Empty()]),
            _VarPattern('int', 'x')..id = 2
          ]),
          expectErrors: [
            'missingMatchVar((), x)',
            'matchVarOverlap(pattern: 2: int x, previousPattern: 1: int x)'
          ]);
    });

    test('Missing after overlap after missing', () {
      h.run(
          _Or([
            _And([
              _Or([_VarPattern('int', 'x')..id = 1, _Empty()..id = 2]),
              _VarPattern('int', 'x')..id = 3
            ]),
            _Empty()..id = 4
          ]),
          expectErrors: [
            'missingMatchVar(2: (), x)',
            'matchVarOverlap(pattern: 3: int x, previousPattern: 1: int x)',
            'missingMatchVar(4: (), x)'
          ]);
    });

    test('Each type compared to previous', () {
      h.run(
          _Or([
            _VarPattern('int', 'x'),
            _VarPattern('double', 'x')..id = 1,
            _VarPattern('double', 'x')..id = 2
          ]),
          expectErrors: [
            'inconsistentMatchVar(pattern: 1: double x, type: double, '
                'previousPattern: int x, previousType: int)'
          ]);
    });

    test('Each explicitness compared to previous', () {
      h.run(
          _Or([
            _VarPattern('int', 'x'),
            _VarPattern('int', 'x', isImplicitlyTyped: true)..id = 1,
            _VarPattern('int', 'x', isImplicitlyTyped: true)..id = 2
          ]),
          expectErrors: [
            'inconsistentMatchVarExplicitness(pattern: 1: int x (implicit), '
                'previousPattern: int x)'
          ]);
    });
  });
}

class _And extends _Node {
  final List<_Node> _nodes;

  _And(this._nodes);

  @override
  String _toDebugString() => '(${_nodes.join(' & ')})';

  @override
  void _visit(_Harness h) {
    for (var node in _nodes) {
      node._visit(h);
    }
  }
}

class _Empty extends _Node {
  @override
  String _toDebugString() => '()';

  @override
  void _visit(_Harness h) {}
}

class _Errors
    implements TypeAnalyzerErrors<_Node, Never, Never, String, String> {
  final List<String> _errors = [];

  @override
  void inconsistentMatchVar(
      {required _Node pattern,
      required String type,
      required _Node previousPattern,
      required String previousType}) {
    _errors.add('inconsistentMatchVar(pattern: $pattern, type: $type, '
        'previousPattern: $previousPattern, previousType: $previousType)');
  }

  @override
  void inconsistentMatchVarExplicitness(
      {required _Node pattern, required _Node previousPattern}) {
    _errors.add('inconsistentMatchVarExplicitness(pattern: $pattern, '
        'previousPattern: $previousPattern)');
  }

  @override
  void matchVarOverlap(
      {required _Node pattern, required _Node previousPattern}) {
    _errors.add('matchVarOverlap(pattern: $pattern, '
        'previousPattern: $previousPattern)');
  }

  @override
  void missingMatchVar(_Node alternative, String variable) {
    _errors.add('missingMatchVar($alternative, $variable)');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw 'Unexpected error ${invocation.memberName}';
  }
}

class _Harness implements VariableBindingCallbacks<_Node, String, String> {
  late final _bindings = VariableBindings<_Node, String, String>(this);

  @override
  final _Errors errors = _Errors();

  @override
  final TypeOperations2<String> typeOperations = _TypeOperations();

  @override
  final TypeAnalyzerOptions options =
      TypeAnalyzerOptions(nullSafetyEnabled: true, patternsEnabled: true);

  void run(_Node node,
      {List<String>? expectEntries, List<String> expectErrors = const []}) {
    node._visit(this);
    if (expectEntries != null) {
      var entryStrings = [
        for (var entry in _bindings.entries.toList())
          [
            entry.staticType,
            entry.variable,
            if (entry.isImplicitlyTyped) '(implicit)'
          ].join(' ')
      ];
      expect(entryStrings, expectEntries);
    }
    expect(errors._errors, expectErrors);
  }
}

abstract class _Node {
  int? id;

  @override
  String toString() {
    var debugString = _toDebugString();
    if (id != null) {
      return '$id: $debugString';
    } else {
      return debugString;
    }
  }

  String _toDebugString();

  void _visit(_Harness h);
}

class _Or extends _Node {
  final List<_Node> _alternatives;

  _Or(this._alternatives);

  @override
  String _toDebugString() => '(${_alternatives.join(' | ')})';

  @override
  void _visit(_Harness h) {
    h._bindings.startAlternatives();
    for (var node in _alternatives) {
      h._bindings.startAlternative(node);
      node._visit(h);
      h._bindings.finishAlternative();
    }
    h._bindings.finishAlternatives();
  }
}

class _TypeOperations implements TypeOperations2<String> {
  @override
  bool isSameType(String type1, String type2) => type1 == type2;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _VarPattern extends _Node {
  final String staticType;
  final String variable;
  final bool isImplicitlyTyped;
  final bool? expectNew;

  _VarPattern(this.staticType, this.variable,
      {this.isImplicitlyTyped = false, this.expectNew});

  @override
  String _toDebugString() => [
        staticType,
        variable,
        if (isImplicitlyTyped) '(implicit)',
        if (expectNew != null) '(expectNew: $expectNew)'
      ].join(' ');

  @override
  void _visit(_Harness h) {
    var isNew = h._bindings.add(this, variable,
        staticType: staticType, isImplicitlyTyped: isImplicitlyTyped);
    if (expectNew != null) {
      expect(isNew, expectNew);
    }
  }
}
