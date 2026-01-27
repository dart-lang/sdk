// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BindToFieldTest);
  });
}

@reflectiveTest
class BindToFieldTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.bindAllToFields;

  Future<void> test_private_named_and_positional() async {
    // This code is erroneous, but we still want to allow the assist since it
    // will fix the error.
    await resolveTestCode(
      '''
class A {
  A(int ^_i, {String? _s});
}
''',
      ignore: [diag.privateNamedNonFieldParameter],
    );
    await assertHasAssist('''
class A {
  int _i;

  String? _s;

  A(this._i, {this._s});
}
''');
  }

  Future<void> test_typed_multiple_constructor_parameters() async {
    await resolveTestCode('''
class A {
  A(int ^i, String s);
}
''');
    await assertHasAssist('''
class A {
  int i;

  String s;

  A(this.i, this.s);
}
''');
  }

  Future<void> test_typed_super_default_mixed() async {
    await resolveTestCode('''
class A extends B {
  A([super.^i = 42, int k = 4]);
}

class B {
  B(int i);
}
''');
    await assertHasAssist('''
class A extends B {
  int k;

  A([super.^i = 42, this.k = 4]);
}

class B {
  B(int i);
}
''');
  }

  Future<void> test_with_existing_fields() async {
    await resolveTestCode('''
class Foo {
  const Foo({
    this.a,
    bool ^b = false,
  });

  final String? a;
}
''');
    await assertHasAssist('''
class Foo {
  const Foo({
    this.a,
    this.b = false,
  });

  final String? a;

  final bool b;
}
''');
  }

  Future<void> test_with_existing_fields_and_mixed_parameters() async {
    await resolveTestCode('''
class Foo {
  const Foo(int i, {
    this.a,
    bool ^b = false,
  });

  final String? a;
}
''');
    await assertHasAssist('''
class Foo {
  const Foo(this.i, {
    this.a,
    this.b = false,
  });

  final String? a;

  final int i;

  final bool b;
}
''');
  }

  Future<void> test_with_existing_fields_and_super_parameters() async {
    await resolveTestCode('''
class Foo extends B {
  const Foo(int i, {
    required super.a,
    bool ^b = false,
  });
}

class B {
  const B({required int a});
}
''');
    await assertHasAssist('''
class Foo extends B {
  final int i;

  final bool b;

  const Foo(this.i, {
    required super.a,
    this.b = false,
  });
}

class B {
  const B({required int a});
}
''');
  }

  Future<void> test_with_two_parameters() async {
    await resolveTestCode('''
class Foo {
  Foo({required int foo, required int^ foobar});
}
''');
    await assertHasAssist('''
class Foo {
  int foo;

  int foobar;

  Foo({required this.foo, required this.foobar});
}
''');
  }
}
