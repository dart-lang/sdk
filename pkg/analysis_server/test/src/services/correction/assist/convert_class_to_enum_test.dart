// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertClassToEnumTest);
  });
}

@reflectiveTest
class ConvertClassToEnumTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertClassToEnum;

  Future<void> test_documentationComments_mix() async {
    await resolveTestCode('''
class ^E {
  /// AAA
  static const E a = E._('a');
  static const E b = E._('b');

  /// CCC
  static const E c = E._('c');

  final String name;

  const E._(this.name);
}
''');
    await assertHasAssist('''
enum E {
  /// AAA
  a._('a'),
  b._('b'),

  /// CCC
  c._('c');

  final String name;

  const E._(this.name);
}
''');
  }

  Future<void> test_documentationComments_multiple() async {
    await resolveTestCode('''
class ^E {
  /// AAA
  static const E a = E._('a');

  /// BBB
  /// BBB
  static const E b = E._('b');

  /// Name.
  final String name;

  const E._(this.name);
}
''');
    await assertHasAssist('''
enum E {
  /// AAA
  a._('a'),

  /// BBB
  /// BBB
  b._('b');

  /// Name.
  final String name;

  const E._(this.name);
}
''');
  }

  Future<void> test_documentationComments_single() async {
    await resolveTestCode('''
class ^E {
  /// AAA
  static const E a = E._('a');

  /// Name.
  final String name;

  const E._(this.name);
}
''');
    await assertHasAssist('''
enum E {
  /// AAA
  a._('a');

  /// Name.
  final String name;

  const E._(this.name);
}
''');
  }

  Future<void> test_extends_object_privateClass() async {
    await resolveTestCode('''
class _^E extends Object {
  static const _E c = _E();

  const _E();
}
''');
    await assertHasAssist('''
enum _E {
  c
}
''');
  }

  Future<void> test_extends_object_publicClass() async {
    await resolveTestCode('''
class ^E extends Object {
  static const E c = E._();

  const E._();
}
''');
    await assertHasAssist('''
enum E {
  c._();

  const E._();
}
''');
  }

  Future<void> test_index_namedIndex_first_primaryConstructor() async {
    await resolveTestCode('''
class const ^_E(final int index, final String code) {
  static const _E c0 = _E(0, 'a');
  static const _E c1 = _E(1, 'b');
}
''');
    await assertHasAssist('''
enum _E(final String code) {
  c0('a'),
  c1('b')
}
''');
  }

  Future<void> test_index_namedIndex_first_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E(0, 'a');
  static const _E c1 = _E(1, 'b');

  final int index;

  final String code;

  const _E(this.index, this.code);
}
''');
    await assertHasAssist('''
enum _E {
  c0('a'),
  c1('b');

  final String code;

  const _E(this.code);
}
''');
  }

  Future<void> test_index_namedIndex_last_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E('a', 0);
  static const _E c1 = _E('b', 1);

  final String code;

  final int index;

  const _E(this.code, this.index);
}
''');
    await assertHasAssist('''
enum _E {
  c0('a'),
  c1('b');

  final String code;

  const _E(this.code);
}
''');
  }

  Future<void> test_index_namedIndex_middle_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E('a', 0, 'b');
  static const _E c1 = _E('c', 1, 'd');

  final String first;

  final int index;

  final String last;

  const _E(this.first, this.index, this.last);
}
''');
    await assertHasAssist('''
enum _E {
  c0('a', 'b'),
  c1('c', 'd');

  final String first;

  final String last;

  const _E(this.first, this.last);
}
''');
  }

  Future<void> test_index_namedIndex_only_outOfOrder() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E(1);
  static const _E c1 = _E(0);

  final int index;

  const _E(this.index);
}
''');
    await assertHasAssist('''
enum _E {
  c1,
  c0
}
''');
  }

  Future<void> test_index_namedIndex_only_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E(0);
  static const _E c1 = _E(1);

  final int index;

  const _E(this.index);
}
''');
    await assertHasAssist('''
enum _E {
  c0,
  c1
}
''');
  }

  @FailingTest(reason: 'To implement next.')
  Future<void>
  test_index_namedIndex_only_privateClass_primaryConstructor() async {
    // TODO(srawlins): Test with primary constructor with non-declaring index
    // parameter.
    // TODO(srawlins): Test with private primary constructor on a public class.
    await resolveTestCode('''
class const _^E(final int index) {
  static const _E c0 = _E(0);
  static const _E c1 = _E(1);
}
''');
    await assertHasAssist('''
enum _E {
  c0,
  c1
}
''');
  }

  Future<void> test_index_namedIndex_only_publicClass() async {
    await resolveTestCode('''
class ^E {
  static const E c0 = E._(0);
  static const E c1 = E._(1);

  final int index;

  const E._(this.index);
}
''');
    await assertHasAssist('''
enum E {
  c0._(),
  c1._();

  const E._();
}
''');
  }

  Future<void> test_index_notNamedIndex_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E(0);
  static const _E c1 = _E(1);

  final int value;

  const _E(this.value);
}
''');
    await assertHasAssist('''
enum _E {
  c0(0),
  c1(1);

  final int value;

  const _E(this.value);
}
''');
  }

  Future<void> test_index_notNamedIndex_publicClass() async {
    await resolveTestCode('''
class ^E {
  static const E c0 = E._(0);
  static const E c1 = E._(1);

  final int value;

  const E._(this.value);
}
''');
    await assertHasAssist('''
enum E {
  c0._(0),
  c1._(1);

  final int value;

  const E._(this.value);
}
''');
  }

  Future<void> test_invalid_abstractClass() async {
    await resolveTestCode('''
abstract class ^E {}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_base() async {
    await resolveTestCode('''
base class ^E {
  final int index;

  static const E c0 = E(0);
  const E(this.index);
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_constructorUsedInConstructor() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  // ignore: unused_element_parameter, recursive_constant_constructor
  const _E({_E e = const _E()});
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_constructorUsedOutsideClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();
}
_E get e => _E();
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_extended() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();
}
class F extends _E  {}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_extends_notObject() async {
    await resolveTestCode('''
class ^E extends C {
  static const E c = E._();

  const E._();
}
class C {
  const C();
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_factoryConstructor_all() async {
    await resolveTestCode('''
class _^E {
  static _E c = _E();

  factory _E() => c;
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_factoryConstructor_some() async {
    // We could arguably support this case by only converting the static fields
    // that are initialized by a generative constructor.
    await resolveTestCode('''
class _^E {
  static _E c0 = _E._();
  static _E c1 = _E();

  factory _E() => c0;
  const _E._();
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_final() async {
    await resolveTestCode('''
final class ^E {
  static const E c = E();

  const E();
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_hasPart() async {
    // Change this test if the assist becomes able to look for references to the
    // class and its constructors in part files.
    newFile('$testPackageLibPath/a.dart', '''
part of 'test.dart';
''');
    await resolveTestCode('''
part 'a.dart';

class ^E {
  static const E c = E._();

  const E._();
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_implemented() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();
}
class F implements _E  {}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_indexFieldNotSequential() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E(0);
  static const _E c1 = _E(3);

  final int index;

  const _E(this.index);
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_multipleConstantsInSameFieldDeclaration() async {
    // Change this test if support is added to cover cases where multiple
    // constants are defined in a single field declaration.
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E('a'), c1 = _E('b');

  final String s;

  const _E(this.s);
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_nonConstConstructor() async {
    await resolveTestCode('''
class _^E {
  static _E c = _E();

  _E();
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_nonConstPrimaryConstructor() async {
    await resolveTestCode('''
class _^E() {
  static _E c = _E();
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_overrides_equal() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();

  @override
  int get hashCode => 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_overrides_hashCode() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();

  @override
  bool operator ==(Object other) => true;
}
''');
    await assertNoAssist();
  }

  Future<void> test_invalid_sealed() async {
    await resolveTestCode('''
sealed class ^E {
  final int index;

  const E._(this.index);
}
''');
    await assertNoAssist();
  }

  Future<void> test_minimal_primaryConstructor() async {
    await resolveTestCode('''
class const ^E._() {
  static const E c = E._();
}
''');
    await assertHasAssist('''
enum E._() {
  c._()
}
''');
  }

  Future<void> test_minimal_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();
}
''');
    await assertHasAssist('''
enum _E {
  c
}
''');
  }

  Future<void> test_minimal_publicClass() async {
    await resolveTestCode('''
class ^E {
  static const E c = E._();

  const E._();
}
''');
    await assertHasAssist('''
enum E {
  c._();

  const E._();
}
''');
  }

  Future<void> test_noIndex_int_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E(2);
  static const _E c1 = _E(4);

  final int count;

  const _E(this.count);
}
''');
    await assertHasAssist('''
enum _E {
  c0(2),
  c1(4);

  final int count;

  const _E(this.count);
}
''');
  }

  Future<void> test_noIndex_int_publicClass() async {
    await resolveTestCode('''
class ^E {
  static const E c0 = E._(2);
  static const E c1 = E._(4);

  final int count;

  const E._(this.count);
}
''');
    await assertHasAssist('''
enum E {
  c0._(2),
  c1._(4);

  final int count;

  const E._(this.count);
}
''');
  }

  Future<void> test_noIndex_notInt_primaryClass() async {
    await resolveTestCode('''
class const ^E._(final String name) {
  static const E c0 = E._('c0');
  static const E c1 = E._('c1');
}
''');
    await assertHasAssist('''
enum E._(final String name) {
  c0._('c0'),
  c1._('c1')
}
''');
  }

  Future<void> test_noIndex_notInt_privateClass() async {
    await resolveTestCode('''
class _^E {
  static const _E c0 = _E('c0');
  static const _E c1 = _E('c1');

  final String name;

  const _E(this.name);
}
''');
    await assertHasAssist('''
enum _E {
  c0('c0'),
  c1('c1');

  final String name;

  const _E(this.name);
}
''');
  }

  Future<void> test_noIndex_notInt_publicClass() async {
    await resolveTestCode('''
class ^E {
  static const E c0 = E._('c0');
  static const E c1 = E._('c1');

  final String name;

  const E._(this.name);
}
''');
    await assertHasAssist('''
enum E {
  c0._('c0'),
  c1._('c1');

  final String name;

  const E._(this.name);
}
''');
  }

  Future<void> test_withReferencedFactoryConstructor() async {
    await resolveTestCode('''
class _^E {
  static const _E c = _E();

  const _E();

  factory _E.withValue(int x) => c;
}

_E e = _E.withValue(0);
''');
    await assertHasAssist('''
enum _E {
  c;

  const _E();

  factory _E.withValue(int x) => c;
}

_E e = _E.withValue(0);
''');
  }
}
