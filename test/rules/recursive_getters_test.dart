// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveGettersTest);
  });
}

@reflectiveTest
class RecursiveGettersTest extends LintRuleTest {
  @override
  String get lintRule => 'recursive_getters';

  /// https://github.com/dart-lang/linter/issues/3706
  test_constList_expressionFunctionBody() async {
    var listContents = StringBuffer();
    for (var i = 0; i < 100000; ++i) {
      listContents.write('"foo", ');
    }
    await assertNoDiagnostics('''
List<String> get strings => const <String>[$listContents];
''');
  }

  test_constMap_expressionFunctionBody() async {
    var mapContents = StringBuffer();
    for (var i = 0; i < 100000; ++i) {
      mapContents.write('$i : "foo", ');
    }
    await assertNoDiagnostics('''
Map<int, String> get strings => const <int, String>{$mapContents};
''');
  }

  /// https://github.com/dart-lang/linter/issues/3706
  test_constSet_expressionFunctionBody() async {
    var setContents = StringBuffer();
    for (var i = 0; i < 100000; ++i) {
      setContents.write('"foo$i", ');
    }
    await assertNoDiagnostics('''
Set<String> get strings => const <String>{$setContents};
''');
  }

  test_instanceGetter_blockBody_nonRecursive() async {
    await assertNoDiagnostics(r'''
class C {
  int _f = 0;
  int get f {
    return _f;
  }
}
''');
  }

  test_instanceGetter_blockBody_recursiveWithImplicitThis() async {
    await assertDiagnostics(r'''
class C {
  int get f {
    return f;
  }
}
''', [
      lint(35, 1),
    ]);
  }

  test_instanceGetter_expressionBody_innerRecursiveCall() async {
    await assertDiagnostics(r'''
class C {
  int get f => p(f);
}
int p(int arg) => 0;
''', [
      lint(27, 1),
    ]);
  }

  test_instanceGetter_expressionBody_nonRecursive() async {
    await assertNoDiagnostics(r'''
class C {
  int _f = 0;
  int get f => _f;
}
''');
  }

  test_instanceGetter_expressionBody_recursiveWithExplicitThis() async {
    await assertDiagnostics(r'''
class C {
  int get f => this.f;
}
''', [
      lint(30, 1),
    ]);
  }

  test_instanceGetter_expressionBody_recursiveWithImplicitThis() async {
    await assertDiagnostics(r'''
class C {
  int get f => f;
}
''', [
      lint(25, 1),
    ]);
  }

  test_instanceGetter_recursiveCallOnOtherInstance() async {
    await assertNoDiagnostics(r'''
class C {
  C? _parent;
  C? get ancestor => _parent?.ancestor;
}
''');
  }

  test_method_recursive() async {
    await assertNoDiagnostics(r'''
class C {
  int m() => m();
}
''');
  }

  /// https://github.com/dart-lang/linter/issues/586
  test_nestedReference() async {
    await assertNoDiagnostics(r'''
class Nested {
  final Nested _parent;
  Nested(this._parent);
  Nested get ancestor => _parent.ancestor;
}
''');
  }

  test_nestedReference_property() async {
    await assertNoDiagnostics(r'''
class Nested {
  final Nested target;
  Nested(this.target);
  bool get isFoo {
    var self = this;
    return self.target.isFoo;
  }
}
''');
  }

  test_referenceInListLiteral() async {
    await assertDiagnostics(r'''
class C {
  List<int> get f => [1, 2, ...f];
}
''', [
      lint(41, 1),
    ]);
  }

  test_referenceInMapLiteral() async {
    await assertDiagnostics(r'''
class C {
  Map<int, int> get f => {}..addAll(f);
}
''', [
      lint(46, 1),
    ]);
  }

  test_referenceInMethodCall() async {
    await assertDiagnostics(r'''
class C {
  int get f {
    print(f);
    return 0;
  }
}
''', [
      lint(34, 1),
    ]);
  }

  test_simpleGetter() async {
    await assertDiagnostics(r'''
class C {
  int get f => f;
}
''', [
      lint(25, 1),
    ]);
  }

  test_simpleGetter_thisPrefix() async {
    await assertDiagnostics(r'''
class C {
  int get f => this.f;
}
''', [
      lint(30, 1),
    ]);
  }

  test_staticMemberReference() async {
    await assertNoDiagnostics(r'''
class C {
  static final c = C();
  int get f => c.f;
}
''');
  }

  test_topLevelGetter_blockBody_nonRecursive() async {
    await assertNoDiagnostics(r'''
int _f = 1;
int get f {
  return _f;
}
''');
  }

  test_topLevelGetter_blockBody_recursiveCall() async {
    await assertDiagnostics(r'''
int get f {
  return f;
}
''', [
      lint(21, 1),
    ]);
  }

  test_topLevelGetter_expressionBody_nonRecursive() async {
    await assertNoDiagnostics(r'''
int _f = 1;
int get f => _f;
''');
  }

  test_topLevelGetter_expressionBody_recursiveCall() async {
    await assertDiagnostics(r'''
int get f => f;
''', [
      lint(13, 1),
    ]);
  }

  test_topLevelGetter_innerRecursiveCall() async {
    await assertDiagnostics(r'''
int? _f = 1;
int get f => _f == null ? 0 : f;
''', [
      lint(43, 1),
    ]);
  }
}
