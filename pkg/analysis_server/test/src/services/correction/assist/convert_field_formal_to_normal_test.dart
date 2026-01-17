// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertFieldFormalToNormalTest);
  });
}

@reflectiveTest
class ConvertFieldFormalToNormalTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertFieldFormalToNormal;

  Future<void> test_optionalNamed_explicitType() async {
    await resolveTestCode('''
class C {
  num f;

  C({int this.^f = 0});
}
''');
    await assertHasAssist('''
class C {
  num f;

  C({int f = 0}) : f = f;
}
''');
  }

  Future<void> test_optionalNamed_implicitType() async {
    await resolveTestCode('''
class C {
  int f;

  C({this.^f = 0});
}
''');
    await assertHasAssist('''
class C {
  int f;

  C({int f = 0}) : f = f;
}
''');
  }

  Future<void> test_optionalPositional_explicitType() async {
    await resolveTestCode('''
class C {
  num f;

  C([int this.^f = 0]);
}
''');
    await assertHasAssist('''
class C {
  num f;

  C([int f = 0]) : f = f;
}
''');
  }

  Future<void> test_optionalPositional_implicitType() async {
    await resolveTestCode('''
class C {
  int f;

  C([this.^f = 0]);
}
''');
    await assertHasAssist('''
class C {
  int f;

  C([int f = 0]) : f = f;
}
''');
  }

  Future<void> test_position_first() async {
    await resolveTestCode('''
class C {
  int e;
  int f;
  int g;

  C(this.^e, this.f, this.g);
}
''');
    await assertHasAssist('''
class C {
  int e;
  int f;
  int g;

  C(int e, this.f, this.g) : e = e;
}
''');
  }

  Future<void> test_position_last() async {
    await resolveTestCode('''
class C {
  int e;
  int f;
  int g;

  C(this.e, this.f, this.^g);
}
''');
    await assertHasAssist('''
class C {
  int e;
  int f;
  int g;

  C(this.e, this.f, int g) : g = g;
}
''');
  }

  Future<void> test_position_last_beforeNamed() async {
    await resolveTestCode('''
class C {
  int e;
  int f;
  int g;

  C(this.e, this.^f, {this.g = 0});
}
''');
    await assertHasAssist('''
class C {
  int e;
  int f;
  int g;

  C(this.e, int f, {this.g = 0}) : f = f;
}
''');
  }

  Future<void> test_position_last_beforeOptional() async {
    await resolveTestCode('''
class C {
  int e;
  int f;
  int g;

  C(this.e, this.^f, [this.g = 0]);
}
''');
    await assertHasAssist('''
class C {
  int e;
  int f;
  int g;

  C(this.e, int f, [this.g = 0]) : f = f;
}
''');
  }

  Future<void> test_position_middle() async {
    await resolveTestCode('''
class C {
  int e;
  int f;
  int g;

  C(this.e, this.^f, this.g);
}
''');
    await assertHasAssist('''
class C {
  int e;
  int f;
  int g;

  C(this.e, int f, this.g) : f = f;
}
''');
  }

  Future<void> test_requiredNamed_explicitType() async {
    await resolveTestCode('''
class C {
  num f;

  C({required int this.^f});
}
''');
    await assertHasAssist('''
class C {
  num f;

  C({required int f}) : f = f;
}
''');
  }

  Future<void> test_requiredNamed_implicitType() async {
    await resolveTestCode('''
class C {
  int f;

  C({required this.^f});
}
''');
    await assertHasAssist('''
class C {
  int f;

  C({required int f}) : f = f;
}
''');
  }

  Future<void> test_requiredPositional_explicitType() async {
    await resolveTestCode('''
class C {
  num f;

  C(int this.^f);
}
''');
    await assertHasAssist('''
class C {
  num f;

  C(int f) : f = f;
}
''');
  }

  Future<void> test_requiredPositional_implicitType() async {
    await resolveTestCode('''
class C {
  int f;

  C(this.^f);
}
''');
    await assertHasAssist('''
class C {
  int f;

  C(int f) : f = f;
}
''');
  }

  Future<void> test_withExistingInitializer() async {
    await resolveTestCode('''
class C {
  int e;
  int f;
  int g;

  C(this.e, this.^f, int g) : g = g;
}
''');
    await assertHasAssist('''
class C {
  int e;
  int f;
  int g;

  C(this.e, int f, int g) : g = g, f = f;
}
''');
  }

  Future<void> test_withFunctionTypedField_functionTypedParameter() async {
    await resolveTestCode('''
class C {
  void Function() f;

  C({required this.f^()});
}
''');
    await assertNoAssist();
  }

  Future<void> test_withFunctionTypedField_normalParameter() async {
    await resolveTestCode('''
class C {
  void Function() f;

  C({required this.f^});
}
''');
    await assertHasAssist('''
class C {
  void Function() f;

  C({required void Function() f}) : f = f;
}
''');
  }

  Future<void> test_privateNamedParameter_optionalNamed() async {
    await resolveTestCode('''
class C {
  int? _foo;

  C({this._f^oo});
}
''');
    await assertHasAssist('''
class C {
  int? _foo;

  C({int? foo}) : _foo = foo;
}
''');
  }

  Future<void> test_privateNamedParameter_requiredNamed() async {
    await resolveTestCode('''
class C {
  int _foo;

  C({required this._f^oo});
}
''');
    await assertHasAssist('''
class C {
  int _foo;

  C({required int foo}) : _foo = foo;
}
''');
  }

  Future<void> test_privateNamedParameter_explicitType() async {
    await resolveTestCode('''
class C {
  num _foo;

  C({int this._f^oo = 0});
}
''');
    await assertHasAssist('''
class C {
  num _foo;

  C({int foo = 0}) : _foo = foo;
}
''');
  }

  Future<void> test_privateNamedParameter_withExistingInitializer() async {
    await resolveTestCode('''
class C {
  int _foo;
  int _bar;

  C({required this._f^oo, required int bar}) : _bar = bar;
}
''');
    await assertHasAssist('''
class C {
  int _foo;
  int _bar;

  C({required int foo, required int bar}) : _bar = bar, _foo = foo;
}
''');
  }

  Future<void> test_privateNamedParameter_disabled() async {
    await resolveTestCode('''
// @dart=3.10
class C {
  int? _foo;

  C({this._f^oo});
}
''');
    await assertHasAssist('''
// @dart=3.10
class C {
  int? _foo;

  C({int? _foo}) : _foo = _foo;
}
''');
  }
}
