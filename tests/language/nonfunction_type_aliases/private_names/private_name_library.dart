// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Shared code for tests that private names exported publicly via a typedef work
// as expected.

library private;

// Sentinel values for checking that the correct methods are called.  Methods
// defined in this library return the private sentinel, and (potentially
// overriding) methods defined in other libraries return the public sentinel.
// By checking the return value of methods against the respective sentinels,
// test expectations can establish whether the correct method has been called.
const int privateLibrarySentinel = -1;
const int publicLibrarySentinel = privateLibrarySentinel + 1;

// A private class that will be exported via a public typedef.
class _PrivateClass {
  final int x;
  const _PrivateClass() : x = privateLibrarySentinel;
  _PrivateClass.named(this.x);
  static int staticMethod() => privateLibrarySentinel;
  static int _privateStaticMethod() => privateLibrarySentinel;
  int instanceMethod() => privateLibrarySentinel;
  int _privateInstanceMethod() => privateLibrarySentinel;
}

// Export the private class publicly, along with a factory.
typedef PublicClass = _PrivateClass;
PublicClass mkPublicClass() => PublicClass();

// Export the private class publicly via an indirection through another private
// typedef, along with a factory.
typedef _PrivateTypeDef = _PrivateClass;
typedef AlsoPublicClass = _PrivateTypeDef;
AlsoPublicClass mkAlsoPublicClass() => AlsoPublicClass();

// A private generic class which will be exported through a public typedef.
class _PrivateGenericClass<T> {
  static int staticMethod() => privateLibrarySentinel;
}

// Export the private generic class publicly, along with a factory and a
// specific instantiation.
typedef PublicGenericClass<T> = _PrivateGenericClass<T>;
PublicGenericClass<T> mkPublicGenericClass<T>() => PublicGenericClass();
typedef PublicGenericClassOfInt = _PrivateGenericClass<int>;

// Helper methods to do virtual calls on instances of _PrivateClass in this
// library context.
int callPrivateInstanceMethod(_PrivateClass other) => other._privateInstanceMethod();
int callInstanceMethod(_PrivateClass other) => other.instanceMethod();
int readInstanceField(_PrivateClass other) => other.x;

// A private mixin to be exported via a typedef.
mixin _PrivateMixin {
  int mixinMethod() => privateLibrarySentinel;
  int _privateMixinMethod() => privateLibrarySentinel;
}

// Helper method to call a private method on the mixin in this library context.
int callPrivateMixinMethod(_PrivateMixin other) => other._privateMixinMethod();

// Export the private mixin
typedef PublicMixin = _PrivateMixin;

// A private super-mixin which is intended to be mixed onto PublicClass
// and which makes super calls into it.
mixin _PrivateSuperMixin on PublicClass {
  int mixinMethod() => super.instanceMethod();
  int _privateMixinMethod() => super._privateInstanceMethod();
}

// Call the private SuperMixinMethod
int callPrivateSuperMixinMethod(_PrivateSuperMixin other) =>
other._privateMixinMethod();

// Export the private super-mixin.
typedef PublicSuperMixin = _PrivateSuperMixin;
