// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

class Foo {
  int what;

  Foo() : what = 0;
  Foo.publicNamed() : what = 1;
  Foo._privateNamed() : what = 2;

  int publicMethod() {
    return 42;
  }

  int _privateMethod() {
    return 43;
  }

  static int publicStaticMethod() {
    return 44;
  }

  static int _privateStaticMethod() {
    return 45;
  }

  int publicField = 84;
  int _privateField = 85;
  static int publicStaticField = 86;
  static int _privateStaticField = 87;

  int get publicGetter => -1;
  int get _privateGetter => -2;
  static int get publicStaticGetter => -3;
  static int get _privateStaticGetter => -4;

  void set publicSetter(int x) {}
  void set _privateSetter(int x) {}
  static void set publicStaticSetter(int x) {}
  static void set _privateStaticSetter(int x) {}
}

extension PublicExtension on Foo {
  int publicPublicExtensionMethod() {
    return 20;
  }

  int _publicPrivateExtensionMethod() {
    return 21;
  }

  static int publicPublicStaticExtensionMethod() {
    return 22;
  }

  static int _publicPrivateStaticExtensionMethod() {
    return 23;
  }

  static int publicPublicStaticExtensionField = 24;
  static int _publicPrivateStaticExtensionField = 25;

  int get publicPublicExtensionGetter {
    return 26;
  }

  int get _publicPrivateExtensionGetter {
    return 27;
  }

  static int get publicPublicStaticExtensionGetter {
    return 28;
  }

  static int get _publicPrivateStaticExtensionGetter {
    return 29;
  }

  void set publicPublicExtensionSetter(int x) {}

  void set _publicPrivateExtensionSetter(int x) {}

  static void set publicPublicStaticExtensionSetter(int x) {}

  static void set _publicPrivateStaticExtensionSetter(int x) {}
}

extension _PrivateExtension on Foo {
  int privatePublicExtensionMethod() {
    return 30;
  }

  int _privatePrivateExtensionMethod() {
    return 31;
  }

  static int privatePublicStaticExtensionMethod() {
    return 32;
  }

  static int _privatePrivateStaticExtensionMethod() {
    return 33;
  }

  static int privatePublicStaticExtensionField = 34;
  static int _privatePrivateStaticExtensionField = 35;

  int get privatePublicExtensionGetter {
    return 36;
  }

  int get _privatePrivateExtensionGetter {
    return 37;
  }

  static int get privatePublicStaticExtensionGetter {
    return 38;
  }

  static int get _privatePrivateStaticExtensionGetter {
    return 39;
  }

  void set privatePublicExtensionSetter(int x) {}

  void set _privatePrivateExtensionSetter(int x) {}

  static void set privatePublicStaticExtensionSetter(int x) {}

  static void set _privatePrivateStaticExtensionSetter(int x) {}
}

int publicTopLevelMethod() {
  return 50;
}

int _privateTopLevelMethod() {
  return 51;
}

int publicTopLevelField = 52;
int _privateTopLevelField = 53;

int get publicTopLevelGetter {
  return 54;
}

int get _privateTopLevelGetter {
  return 55;
}

void set publicTopLevelSetter(int x) {}

void set _privateTopLevelSetter(int x) {}

main() {
  // Class constructors.
  Foo foo = new Foo();
  assert(foo.what == 0);
  foo = new Foo.publicNamed();
  assert(foo.what == 1);
  foo = new Foo._privateNamed();
  assert(foo.what == 2);

  // Class methods.
  assert(foo.publicMethod() == 42);
  assert(foo._privateMethod() == 43);
  assert(Foo.publicStaticMethod() == 44);
  assert(Foo._privateStaticMethod() == 45);

  // Class fields.
  assert(foo.publicField == 84);
  foo.publicField = -84;
  assert(foo.publicField == -84);
  assert(foo._privateField == 85);
  foo._privateField = -85;
  assert(foo._privateField == -85);
  assert(Foo.publicStaticField == 86);
  Foo.publicStaticField = -86;
  assert(Foo.publicStaticField == -86);
  assert(Foo._privateStaticField == 87);
  Foo._privateStaticField = -87;
  assert(Foo._privateStaticField == -87);

  // Class getters.
  assert(foo.publicGetter == -1);
  assert(foo._privateGetter == -2);
  assert(Foo.publicStaticGetter == -3);
  assert(Foo._privateStaticGetter == -4);

  // Class setters.
  foo.publicSetter = 42;
  foo._privateSetter = 42;
  Foo.publicStaticSetter = 42;
  Foo._privateStaticSetter = 42;

  // Extension methods.
  assert(foo.publicPublicExtensionMethod() == 20);
  assert(foo._publicPrivateExtensionMethod() == 21);
  assert(PublicExtension.publicPublicStaticExtensionMethod() == 22);
  assert(PublicExtension._publicPrivateStaticExtensionMethod() == 23);
  assert(foo.privatePublicExtensionMethod() == 30);
  assert(foo._privatePrivateExtensionMethod() == 31);
  assert(_PrivateExtension.privatePublicStaticExtensionMethod() == 32);
  assert(_PrivateExtension._privatePrivateStaticExtensionMethod() == 33);

  // Extension fields.
  assert(PublicExtension.publicPublicStaticExtensionField == 24);
  PublicExtension.publicPublicStaticExtensionField = -24;
  assert(PublicExtension.publicPublicStaticExtensionField == -24);
  assert(PublicExtension._publicPrivateStaticExtensionField == 25);
  PublicExtension._publicPrivateStaticExtensionField = -25;
  assert(PublicExtension._publicPrivateStaticExtensionField == -25);
  assert(_PrivateExtension.privatePublicStaticExtensionField == 34);
  _PrivateExtension.privatePublicStaticExtensionField = -34;
  assert(_PrivateExtension.privatePublicStaticExtensionField == -34);
  assert(_PrivateExtension._privatePrivateStaticExtensionField == 35);
  _PrivateExtension._privatePrivateStaticExtensionField = -35;
  assert(_PrivateExtension._privatePrivateStaticExtensionField == -35);

  // Extension getters.
  assert(foo.publicPublicExtensionGetter == 26);
  assert(foo._publicPrivateExtensionGetter == 27);
  assert(PublicExtension.publicPublicStaticExtensionGetter == 28);
  assert(PublicExtension._publicPrivateStaticExtensionGetter == 29);
  assert(foo.privatePublicExtensionGetter == 36);
  assert(foo._privatePrivateExtensionGetter == 37);
  assert(_PrivateExtension.privatePublicStaticExtensionGetter == 38);
  assert(_PrivateExtension._privatePrivateStaticExtensionGetter == 39);

  // Extension setters.
  foo.publicPublicExtensionSetter = 42;
  foo._publicPrivateExtensionSetter = 42;
  PublicExtension.publicPublicStaticExtensionSetter = 42;
  PublicExtension._publicPrivateStaticExtensionSetter = 42;
  foo.privatePublicExtensionSetter = 42;
  foo._privatePrivateExtensionSetter = 42;
  _PrivateExtension.privatePublicStaticExtensionSetter = 42;
  _PrivateExtension._privatePrivateStaticExtensionSetter = 42;

  // Top-level methods.
  assert(publicTopLevelMethod() == 50);
  assert(_privateTopLevelMethod() == 51);

  // Top-level fields.
  assert(publicTopLevelField == 52);
  publicTopLevelField = -52;
  assert(publicTopLevelField == -52);
  assert(_privateTopLevelField == 53);
  _privateTopLevelField = -53;
  assert(_privateTopLevelField == -53);

  // Top-level getters.
  assert(publicTopLevelGetter == 54);
  assert(_privateTopLevelGetter == 55);

  // Top-level setters.
  publicTopLevelSetter = 42;
  _privateTopLevelSetter = 42;
}
