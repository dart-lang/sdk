// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveThisAliasBulkTest);
    defineReflectiveTests(RemoveThisAliasInFileTest);
    defineReflectiveTests(RemoveThisAliasTest);
  });
}

@reflectiveTest
class RemoveThisAliasBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_this_alias;

  Future<void> test_bulk() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.b();
    }
  }

  void c() {
    var self2 = this;
    if (self2 is B) {
      self2.b();
    }
  }
}

class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      b();
    }
  }

  void c() {
    if (this is B) {
      b();
    }
  }
}

class B extends A {
  void b() {}
}
''');
  }
}

@reflectiveTest
class RemoveThisAliasInFileTest extends FixInFileProcessorTest {
  Future<void> test_file() async {
    createAnalysisOptionsFile(
      experimentalFeatures: experimentalFeatures,
      lints: [LintNames.unnecessary_this_alias],
    );
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.b();
    }
  }

  void c() {
    var self2 = this;
    if (self2 is B) {
      self2.b();
    }
  }
}

class B extends A {
  void b() {}
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
class A {
  void a() {
    if (this is B) {
      b();
    }
  }

  void c() {
    if (this is B) {
      b();
    }
  }
}

class B extends A {
  void b() {}
}
''');
  }
}

@reflectiveTest
class RemoveThisAliasTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeThisAlias;

  @override
  String get lintCode => LintNames.unnecessary_this_alias;

  Future<void> test_declaration_inList_first() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this, x = 1;
    if (self is B) {
      self.b();
    }
    print(x);
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    var x = 1;
    if (this is B) {
      b();
    }
    print(x);
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_declaration_inList_last() async {
    await resolveTestCode('''
class A {
  void a() {
    var x = 1, self = this;
    if (self is B) {
      self.b();
    }
    print(x);
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    var x = 1;
    if (this is B) {
      b();
    }
    print(x);
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_declaration_inList_middle() async {
    await resolveTestCode('''
class A {
  void a() {
    var x = 1, self = this, y = 2;
    if (self is B) {
      self.b();
    }
    print(x);
    print(y);
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    var x = 1, y = 2;
    if (this is B) {
      b();
    }
    print(x);
    print(y);
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_declaration_parenthesized() async {
    await resolveTestCode('''
class C {
  void m() {
    var self = (this);
    if (self is D) {}
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  void m() {
    if (this is D) {}
  }
}
class D extends C {}
''');
  }

  Future<void> test_declaration_single() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_promotion_as() async {
    await resolveTestCode('''
class C {
  void m() {
    var self = this;
    (self as D).foo();
  }
}
class D extends C {
  void foo() {}
}
''');
    await assertHasFix('''
class C {
  void m() {
    (this as D).foo();
  }
}
class D extends C {
  void foo() {}
}
''');
  }

  Future<void> test_promotion_as_isolated() async {
    await resolveTestCode('''
class C {
  D m() {
    var self = this;
    return self as D;
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  D m() {
    return this as D;
  }
}
class D extends C {}
''');
  }

  Future<void> test_promotion_bang() async {
    await resolveTestCode('''
class C {}
extension E on C? {
  void m() {
    var self = this;
    print(self!);
  }
}
''');
    await assertHasFix('''
class C {}
extension E on C? {
  void m() {
    print(this!);
  }
}
''');
  }

  Future<void> test_promotion_bangEqNull() async {
    await resolveTestCode('''
class C {}
extension E on C? {
  void m() {
    var self = this;
    if (self != null) {}
  }
}
''');
    await assertHasFix('''
class C {}
extension E on C? {
  void m() {
    if (this != null) {}
  }
}
''');
  }

  Future<void> test_promotion_eqEqNull() async {
    await resolveTestCode('''
class C {}
extension E on C? {
  void m() {
    var self = this;
    if (self == null) {}
  }
}
''');
    await assertHasFix('''
class C {}
extension E on C? {
  void m() {
    if (this == null) {}
  }
}
''');
  }

  Future<void> test_promotion_ifCase() async {
    await resolveTestCode('''
class C {
  void m() {
    var self = this;
    if (self case D _) {}
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  void m() {
    if (this case D _) {}
  }
}
class D extends C {}
''');
  }

  Future<void> test_promotion_is() async {
    await resolveTestCode('''
class C {
  void m() {
    var self = this;
    if (self is D) {}
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  void m() {
    if (this is D) {}
  }
}
class D extends C {}
''');
  }

  Future<void> test_promotion_isNot() async {
    await resolveTestCode('''
class C {
  void m() {
    var self = this;
    if (self is! D) {}
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  void m() {
    if (this is! D) {}
  }
}
class D extends C {}
''');
  }

  Future<void> test_promotion_nullAware_cascade() async {
    await resolveTestCode('''
class C {
  void m() {}
}
extension E on C? {
  void m() {
    var self = this;
    self?..m();
  }
}
''');
    await assertHasFix('''
class C {
  void m() {}
}
extension E on C? {
  void m() {
    this?..m();
  }
}
''');
  }

  Future<void> test_promotion_nullAware_indexAccess() async {
    await resolveTestCode('''
class C {
  operator [](int index) {}
}
extension E on C? {
  void m() {
    var self = this;
    self?[0];
  }
}
''');
    await assertHasFix('''
class C {
  operator [](int index) {}
}
extension E on C? {
  void m() {
    this?[0];
  }
}
''');
  }

  Future<void> test_promotion_nullAware_methodInvocation() async {
    await resolveTestCode('''
class C {
  void m() {}
}
extension E on C? {
  void m() {
    var self = this;
    self?.m();
  }
}
''');
    await assertHasFix('''
class C {
  void m() {}
}
extension E on C? {
  void m() {
    this?.m();
  }
}
''');
  }

  Future<void> test_promotion_nullAware_propertyAccess_read() async {
    await resolveTestCode('''
class C {
  int get x => 0;
}
extension E on C? {
  void m() {
    var self = this;
    print(self?.x);
  }
}
''');
    await assertHasFix('''
class C {
  int get x => 0;
}
extension E on C? {
  void m() {
    print(this?.x);
  }
}
''');
  }

  Future<void> test_promotion_nullAware_propertyAccess_write() async {
    await resolveTestCode('''
class C(var int x, var int y);
extension E on C? {
  void m() {
    var self = this;
    self?.x = self.y;
  }
}
''');
    await assertHasFix('''
class C(var int x, var int y);
extension E on C? {
  void m() {
    this?.x = y;
  }
}
''');
  }

  Future<void> test_promotion_nullBangEq() async {
    await resolveTestCode('''
class C {}
extension E on C? {
  void m() {
    var self = this;
    if (null != self) {}
  }
}
''');
    await assertHasFix('''
class C {}
extension E on C? {
  void m() {
    if (null != this) {}
  }
}
''');
  }

  Future<void> test_promotion_nullEqEq() async {
    await resolveTestCode('''
class C {}
extension E on C? {
  void m() {
    var self = this;
    if (null == self) {}
  }
}
''');
    await assertHasFix('''
class C {}
extension E on C? {
  void m() {
    if (null == this) {}
  }
}
''');
  }

  Future<void> test_promotion_parenthesized() async {
    await resolveTestCode('''
class C {}
extension E on C? {
  void m() {
    var self = this;
    if ((self) == null) {}
  }
}
''');
    await assertHasFix('''
class C {}
extension E on C? {
  void m() {
    if ((this) == null) {}
  }
}
''');
  }

  Future<void> test_promotion_switch() async {
    await resolveTestCode('''
class C {
  void m() {
    var self = this;
    switch (self) {
      case D _:
    }
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  void m() {
    switch (this) {
      case D _:
    }
  }
}
class D extends C {}
''');
  }

  Future<void> test_promotion_switchExpr() async {
    await resolveTestCode('''
class C {
  int m(C self) {
    var x = this;
    return switch (x) {
      D _ => 1,
      _ => 2,
    };
  }
}
class D extends C {}
''');
    await assertHasFix('''
class C {
  int m(C self) {
    return switch (this) {
      D _ => 1,
      _ => 2,
    };
  }
}
class D extends C {}
''');
  }

  Future<void> test_use_cascade() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self..b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      this..b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_indexAccess_read() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      print(self[0]);
    }
  }
}
class B extends A {
  int operator [](int index) => 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      print(this[0]);
    }
  }
}
class B extends A {
  int operator [](int index) => 0;
}
''');
  }

  Future<void> test_use_indexAccess_write() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self[0] = 1;
    }
  }
}
class B extends A {
  void operator []=(int index, int value) {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      this[0] = 1;
    }
  }
}
class B extends A {
  void operator []=(int index, int value) {}
}
''');
  }

  Future<void> test_use_method_argumentAndTarget() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.b(self);
    }
  }
}
class B extends A {
  void b(Object o) {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      b(this);
    }
  }
}
class B extends A {
  void b(Object o) {}
}
''');
  }

  Future<void> test_use_method_explicit_shadowedByLocal_function() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      // ignore: unused_element
      void b() {}
      self.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      // ignore: unused_element
      void b() {}
      this.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_method_explicit_shadowedByLocal_parameter() async {
    await resolveTestCode('''
class A {
  void a(int b) {
    var self = this;
    if (self is B) {
      self.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a(int b) {
    if (this is B) {
      this.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_method_explicit_shadowedByLocal_variable() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      var b = 0;
      self.b();
      print(b);
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      var b = 0;
      this.b();
      print(b);
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_method_explicit_shadowedByTopLevel() async {
    await resolveTestCode('''
void foo() {}

class Super {
  void foo() {}
}

class Sub extends Super {
  void m() {
    var self = this;
    if (self is Other) {
      self.foo();
    }
  }
}

class Other extends Sub {}
''');
    await assertHasFix('''
void foo() {}

class Super {
  void foo() {}
}

class Sub extends Super {
  void m() {
    if (this is Other) {
      this.foo();
    }
  }
}

class Other extends Sub {}
''');
  }

  Future<void> test_use_method_implicit() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_method_implicit_closure() async {
    await resolveTestCode('''
class A {
  void m1(List<int> list) {
    var self = this;
    if (self is B) {
      list.forEach((e) {
        self.b(e);
      });
    }
  }
}
class B extends A {
  void b(int x) {}
}
''');
    await assertHasFix('''
class A {
  void m1(List<int> list) {
    if (this is B) {
      list.forEach((e) {
        b(e);
      });
    }
  }
}
class B extends A {
  void b(int x) {}
}
''');
  }

  Future<void> test_use_method_implicit_extension() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.extMethod();
    }
  }
}
class B extends A {}

extension Ext on B {
  void extMethod() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      extMethod();
    }
  }
}
class B extends A {}

extension Ext on B {
  void extMethod() {}
}
''');
  }

  Future<void> test_use_method_implicit_sameNameAsAlias() async {
    await resolveTestCode('''
class A {
  void b() {}
  void a() {
    var b = this;
    if (b is B) {
      b.b();
    }
  }
}
class B extends A {}
''');
    await assertHasFix('''
class A {
  void b() {}
  void a() {
    if (this is B) {
      b();
    }
  }
}
class B extends A {}
''');
  }

  Future<void> test_use_method_implicit_shadowOutOfScope() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      if (true) {
        // ignore: unused_element
        void b() {}
      }
      self.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      if (true) {
        // ignore: unused_element
        void b() {}
      }
      b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_mixed_implicitAndExplicit() async {
    await resolveTestCode('''
class A {
  int x = 0;
  void a(int x) {
    var self = this;
    if (self is B) {
      self.x = x;
      self.b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
    await assertHasFix('''
class A {
  int x = 0;
  void a(int x) {
    if (this is B) {
      this.x = x;
      b();
    }
  }
}
class B extends A {
  void b() {}
}
''');
  }

  Future<void> test_use_property_explicit_read_shadowedByLocal() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      var x = 0;
      print(self.x);
      print(x);
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      var x = 0;
      print(this.x);
      print(x);
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }

  Future<void> test_use_property_explicit_shadowedByTopLevel() async {
    await resolveTestCode('''
int x = 0;
class Super {
  int x = 0;
}
class Sub extends Super {
  void m() {
    var self = this;
    if (self is Other) {
      self.x = 1;
    }
  }
}
class Other extends Sub {}
''');
    await assertHasFix('''
int x = 0;
class Super {
  int x = 0;
}
class Sub extends Super {
  void m() {
    if (this is Other) {
      this.x = 1;
    }
  }
}
class Other extends Sub {}
''');
  }

  Future<void> test_use_property_explicit_write_shadowedByLocal() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      var x = 0;
      self.x = 1;
      print(x);
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      var x = 0;
      this.x = 1;
      print(x);
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }

  Future<void> test_use_property_explicit_write_shadowedByParameter() async {
    await resolveTestCode('''
class A {
  void a(int x) {
    var self = this;
    if (self is B) {
      self.x = x;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a(int x) {
    if (this is B) {
      this.x = x;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }

  Future<void> test_use_property_implicit_compoundAssignment() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.x += 1;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      x += 1;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }

  Future<void> test_use_property_implicit_genericClass() async {
    await resolveTestCode('''
class A<T> {
  T? x;
  void a() {
    var self = this;
    if (self is B<T>) {
      self.x = null;
    }
  }
}
class B<T> extends A<T> {}
''');
    await assertHasFix('''
class A<T> {
  T? x;
  void a() {
    if (this is B<T>) {
      x = null;
    }
  }
}
class B<T> extends A<T> {}
''');
  }

  Future<void> test_use_property_implicit_inConstructor() async {
    await resolveTestCode('''
class A {
  num x = 0;
  A.named(num a) {
    var self = this;
    if (self is B) {
      self.x = a;
    }
  }
}
class B extends A {
  B.named(super.a) : super.named();
}
''');
    await assertHasFix('''
class A {
  num x = 0;
  A.named(num a) {
    if (this is B) {
      x = a;
    }
  }
}
class B extends A {
  B.named(super.a) : super.named();
}
''');
  }

  Future<void> test_use_property_implicit_increment() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.x++;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      x++;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }

  Future<void> test_use_property_implicit_read() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      print(self.x);
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      print(x);
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }

  Future<void> test_use_property_implicit_write() async {
    await resolveTestCode('''
class A {
  void a() {
    var self = this;
    if (self is B) {
      self.x = 1;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
    await assertHasFix('''
class A {
  void a() {
    if (this is B) {
      x = 1;
    }
  }
}
class B extends A {
  int x = 0;
}
''');
  }
}
