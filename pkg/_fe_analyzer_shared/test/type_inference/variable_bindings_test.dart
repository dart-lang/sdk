// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/type_inference/variable_bindings.dart';
import 'package:test/test.dart';

main() {
  late _Harness h;

  setUp(() {
    h = _Harness();
  });

  test('Variable overlap', () {
    h.run(_And([_VarPattern('x')..id = 1, _VarPattern('x')..id = 2]),
        expectErrors: [
          'matchVarOverlap(pattern: 2: x, previousPattern: 1: x)'
        ]);
  });

  group('Alternative:', () {
    test('Consistent', () {
      h.run(_Or([
        _VarPattern('x', expectNew: true),
        _VarPattern('x', expectNew: false)
      ]));
    });

    test('Does not bind unmentioned variables', () {
      // Even though the variable 'y' has already been seen at the time the
      // nested `_Or` is visited, it's important that the nested `_Or` not be
      // construed to bind the variable 'y'.  Otherwise the variable pattern for
      // `y` that follows would be incorrectly considered an error.
      h.run(_Or([
        _And([_VarPattern('x'), _VarPattern('y')]),
        _And([
          _Or([_VarPattern('x'), _VarPattern('x')]),
          _VarPattern('y')
        ])
      ]));
    });

    group('Missing var:', () {
      test('On left', () {
        h.run(_Or([_Empty(), _VarPattern('x')]),
            expectErrors: ['missingMatchVar((), x)']);
      });

      test('On right', () {
        h.run(_Or([_VarPattern('x'), _Empty()]),
            expectErrors: ['missingMatchVar((), x)']);
      });

      test('Middle of three', () {
        h.run(_Or([_VarPattern('x'), _Empty(), _VarPattern('x')]),
            expectErrors: ['missingMatchVar((), x)']);
      });
    });
  });

  group('Recovery:', () {
    test('Overlap after missing', () {
      h.run(
          _And([
            _Or([_VarPattern('x')..id = 1, _Empty()]),
            _VarPattern('x')..id = 2
          ]),
          expectErrors: [
            'missingMatchVar((), x)',
            'matchVarOverlap(pattern: 2: x, previousPattern: 1: x)'
          ]);
    });

    test('Missing after overlap after missing', () {
      h.run(
          _Or([
            _And([
              _Or([_VarPattern('x')..id = 1, _Empty()..id = 2]),
              _VarPattern('x')..id = 3
            ]),
            _Empty()..id = 4
          ]),
          expectErrors: [
            'missingMatchVar(2: (), x)',
            'matchVarOverlap(pattern: 3: x, previousPattern: 1: x)',
            'missingMatchVar(4: (), x)'
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

class _Errors implements VariableBinderErrors<_Node, Never> {
  final List<String> _errors = [];

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
  late final _binder = VariableBinder<_Node, String, String>(this);

  @override
  final _Errors errors = _Errors();

  void run(_Node node, {List<String> expectErrors = const []}) {
    node._visit(this);
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
    h._binder.startAlternatives();
    for (var node in _alternatives) {
      h._binder.startAlternative(node);
      node._visit(h);
      h._binder.finishAlternative();
    }
    h._binder.finishAlternatives();
  }
}

class _VarPattern extends _Node {
  final String variable;
  final bool? expectNew;

  _VarPattern(this.variable, {this.expectNew});

  @override
  String _toDebugString() =>
      [variable, if (expectNew != null) '(expectNew: $expectNew)'].join(' ');

  @override
  void _visit(_Harness h) {
    var isNew = h._binder.add(this, variable);
    if (expectNew != null) {
      expect(isNew, expectNew);
    }
  }
}
