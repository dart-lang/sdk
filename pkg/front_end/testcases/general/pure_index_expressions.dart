// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

extension Extension on int {
  Class operator [](Class cls) => new Class();
  void operator []=(Class cls, Class value) {}
}

class Class {
  Class operator [](Class cls) => new Class();
  void operator []=(Class cls, Class value) {}
  Class operator +(Class cls) => cls;

  void indexGetSetForEffect(Map<Class, Class> map) {
    final Class self = this;
    map[this] ??= this;
    map[self] ??= self;

    map[this] = this;
    map[self] = self;

    map[this];
    map[self];

    map[this] += this;
    map[self] += self;
  }

  void indexGetSetForValue(Map<Class, Class> map) {
    final Class self = this;
    var v;
    v = map[this] ??= this;
    v = map[self] ??= self;

    v = map[this] = this;
    v = map[self] = self;

    v = map[this];
    v = map[self];

    v = map[this] += this;
    v = map[self] += self;
  }

  void implicitExtensionGetSetForEffect(int i) {
    final Class self = this;
    i[this] ??= this;
    i[self] ??= self;

    i[this] = this;
    i[self] = self;

    i[this];
    i[self];

    i[this] += this;
    i[self] += self;
  }

  void implicitExtensionGetSetForValue(int i) {
    final Class self = this;
    var v;
    v = i[this] ??= this;
    v = i[self] ??= self;

    v = i[this] = this;
    v = i[self] = self;

    v = i[this];
    v = i[self];

    v = i[this] += this;
    v = i[self] += self;
  }

  void explicitExtensionGetSetForEffect(int i) {
    final Class self = this;
    Extension(i)[this] ??= this;
    Extension(i)[self] ??= self;

    Extension(i)[this] = this;
    Extension(i)[self] = self;

    Extension(i)[this];
    Extension(i)[self];

    Extension(i)[this] += this;
    Extension(i)[self] += self;
  }

  void explicitExtensionGetSetForValue(int i) {
    final Class self = this;
    var v;
    v = Extension(i)[this] ??= this;
    v = Extension(i)[self] ??= self;

    v = Extension(i)[this] = this;
    v = Extension(i)[self] = self;

    v = Extension(i)[this];
    v = Extension(i)[self];

    v = Extension(i)[this] += this;
    v = Extension(i)[self] += self;
  }
}

class Subclass extends Class {
  void superIndexGetSetForEffect() {
    final Class self = this;
    super[this] ??= this;
    super[self] ??= self;

    super[this] = this;
    super[self] = self;

    super[this];
    super[self];

    super[this] += this;
    super[self] += self;
  }

  void superIndexGetSetForValue() {
    final Class self = this;
    var v;
    v = super[this] ??= this;
    v = super[self] ??= self;

    v = super[this] = this;
    v = super[self] = self;

    v = super[this];
    v = super[self];

    v = super[this] += this;
    v = super[self] += self;
  }
}

extension Extension2 on Class2 {
  Class2 operator [](Class2 cls) => new Class2();
  void operator []=(Class2 cls, Class2 value) {}
}

class Class2 {
  Class2 operator +(Class2 cls) => cls;

  void implicitExtensionGetSetForEffect() {
    final Class2 self = this;
    this[this] ??= this;
    self[self] ??= self;

    this[this] = this;
    self[self] = self;

    this[this];
    self[self];

    this[this] += this;
    self[self] += self;
  }

  void implicitExtensionGetSetForValue() {
    final Class2 self = this;
    var v;
    v = this[this] ??= this;
    v = self[self] ??= self;

    v = this[this] = this;
    v = self[self] = self;

    v = this[this];
    v = self[self];

    v = this[this] += this;
    v = self[self] += self;
  }

  void explicitExtensionGetSetForEffect() {
    final Class2 self = this;
    Extension2(this)[this] ??= this;
    Extension2(self)[self] ??= self;

    Extension2(this)[this] = this;
    Extension2(self)[self] = self;

    Extension2(this)[this];
    Extension2(self)[self];

    Extension2(this)[this] += this;
    Extension2(self)[self] += self;
  }

  void explicitExtensionGetSetForValue() {
    final Class2 self = this;
    var v;
    v = Extension2(this)[this] ??= this;
    v = Extension2(self)[self] ??= self;

    v = Extension2(this)[this] = this;
    v = Extension2(self)[self] = self;

    v = Extension2(this)[this];
    v = Extension2(self)[self];

    v = Extension2(this)[this] += this;
    v = Extension2(self)[self] += self;
  }
}

main() {}
