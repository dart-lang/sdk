// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Class<T> {}

class ConcreteClass implements Class<ConcreteClass> {}

typedef F<X extends Class<X>> = Class<X>;

class G<X extends Class<X>> {}

class ExtendsT1 extends F {} // Error

class ExtendsT2 extends F<dynamic> {} // Error

class ExtendsT3 extends F<Class> {} // Error

class ExtendsT4 extends F<Class<dynamic>> {} // Error

class ExtendsT5 extends F<ConcreteClass> {} // Ok

class ExtendsT6 extends F<Class<ConcreteClass>> {} // Ok

class ExtendsT7 extends F<Object> {} // Error

class ExtendsT8 extends F<int> {} // Error

class ExtendsS1 extends G {} // Error

class ExtendsS2 extends G<dynamic> {} // Error

class ExtendsS3 extends G<Class> {} // Error

class ExtendsS4 extends G<Class<dynamic>> {} // Error

class ExtendsS5 extends G<ConcreteClass> {} // Ok

class ExtendsS6 extends G<Class<ConcreteClass>> {} // Ok

class ExtendsS7 extends G<Object> {} // Error

class ExtendsS8 extends G<int> {} // Error

class ImplementsT1 implements F {} // Error

class ImplementsT2 implements F<dynamic> {} // Error

class ImplementsT3 implements F<Class> {} // Error

class ImplementsT4 implements F<Class<dynamic>> {} // Error

class ImplementsT5 implements F<ConcreteClass> {} // Ok

class ImplementsT6 implements F<Class<ConcreteClass>> {} // Ok

class ImplementsT7 implements F<Object> {} // Error

class ImplementsT8 implements F<int> {} // Error

class ImplementsS1 implements G {} // Error

class ImplementsS2 implements G<dynamic> {} // Error

class ImplementsS3 implements G<Class> {} // Error

class ImplementsS4 implements G<Class<dynamic>> {} // Error

class ImplementsS5 implements G<ConcreteClass> {} // Ok

class ImplementsS6 implements G<Class<ConcreteClass>> {} // Ok

class ImplementsS7 implements G<Object> {} // Error

class ImplementsS8 implements G<int> {} // Error

class WithT1 with F {} // Error

class WithT2 with F<dynamic> {} // Error

class WithT3 with F<Class> {} // Error

class WithT4 with F<Class<dynamic>> {} // Error

class WithT5 with F<ConcreteClass> {} // Ok

class WithT6 with F<Class<ConcreteClass>> {} // Ok

class WithT7 with F<Object> {} // Error

class WithT8 with F<int> {} // Error

class WithS1 with G {} // Error

class WithS2 with G<dynamic> {} // Error

class WithS3 with G<Class> {} // Error

class WithS4 with G<Class<dynamic>> {} // Error

class WithS5 with G<ConcreteClass> {} // Ok

class WithS6 with G<Class<ConcreteClass>> {} // Ok

class WithS7 with G<Object> {} // Error

class WithS8 with G<int> {} // Error

enum EnumImplementsT1 implements F /* Error */ { a }

enum EnumImplementsT2 implements F<dynamic> /* Error */ { a }

enum EnumImplementsT3 implements F<Class> /* Error */ { a }

enum EnumImplementsT4 implements F<Class<dynamic>> /* Error */ { a }

enum EnumImplementsT5 implements F<ConcreteClass> /* Ok */ { a }

enum EnumImplementsT6 implements F<Class<ConcreteClass>> /* Ok */ { a }

enum EnumImplementsT7 implements F<Object> /* Error */ { a }

enum EnumImplementsT8 implements F<int> /* Error */ { a }

enum EnumImplementsS1 implements G /* Error */ { a }

enum EnumImplementsS2 implements G<dynamic> /* Error */ { a }

enum EnumImplementsS3 implements G<Class> /* Error */ { a }

enum EnumImplementsS4 implements G<Class<dynamic>> /* Error */ { a }

enum EnumImplementsS5 implements G<ConcreteClass> /* Ok */ { a }

enum EnumImplementsS6 implements G<Class<ConcreteClass>> /* Ok */ { a }

enum EnumImplementsS7 implements G<Object> /* Error */ { a }

enum EnumImplementsS8 implements G<int> /* Error */ { a }

enum EnumWithT1 with F /* Error */ { a }

enum EnumWithT2 with F<dynamic> /* Error */ { a }

enum EnumWithT3 with F<Class> /* Error */ { a }

enum EnumWithT4 with F<Class<dynamic>> /* Error */ { a }

enum EnumWithT5 with F<ConcreteClass> /* Ok */ { a }

enum EnumWithT6 with F<Class<ConcreteClass>> /* Ok */ { a }

enum EnumWithT7 with F<Object> /* Error */ { a }

enum EnumWithT8 with F<int> /* Error */ { a }

enum EnumWithS1 with G /* Error */ { a }

enum EnumWithS2 with G<dynamic> /* Error */ { a }

enum EnumWithS3 with G<Class> /* Error */ { a }

enum EnumWithS4 with G<Class<dynamic>> /* Error */ { a }

enum EnumWithS5 with G<ConcreteClass> /* Ok */ { a }

enum EnumWithS6 with G<Class<ConcreteClass>> /* Ok */ { a }

enum EnumWithS7 with G<Object> /* Error */ { a }

enum EnumWithS8 with G<int> /* Error */ { a }

mixin MixinOnT1 on F {} // Error

mixin MixinOnT2 on F<dynamic> {} // Error

mixin MixinOnT3 on F<Class> {} // Error

mixin MixinOnT4 on F<Class<dynamic>> {} // Error

mixin MixinOnT5 on F<ConcreteClass> {} // Ok

mixin MixinOnT6 on F<Class<ConcreteClass>> {} // Ok

mixin MixinOnT7 on F<Object> {} // Error

mixin MixinOnT8 on F<int> {} // Error

mixin MixinOnS1 on G {} // Error

mixin MixinOnS2 on G<dynamic> {} // Error

mixin MixinOnS3 on G<Class> {} // Error

mixin MixinOnS4 on G<Class<dynamic>> {} // Error

mixin MixinOnS5 on G<ConcreteClass> {} // Ok

mixin MixinOnS6 on G<Class<ConcreteClass>> {} // Ok

mixin MixinOnS7 on G<Object> {} // Error

mixin MixinOnS8 on G<int> {} // Error

extension ExtensionOnT1 on F {} // Ok

extension ExtensionOnT2 on F<dynamic> {} // Ok

extension ExtensionOnT3 on F<Class> {} // Ok

extension ExtensionOnT4 on F<Class<dynamic>> {} // Ok

extension ExtensionOnT5 on F<ConcreteClass> {} // Ok

extension ExtensionOnT6 on F<Class<ConcreteClass>> {} // Ok

extension ExtensionOnT7 on F<Object> {} // Error

extension ExtensionOnT8 on F<int> {} // Error

extension ExtensionOnS1 on G {} // Ok

extension ExtensionOnS2 on G<dynamic> {} // Ok

extension ExtensionOnS3 on G<Class> {} // Ok

extension ExtensionOnS4 on G<Class<dynamic>> {} // Ok

extension ExtensionOnS5 on G<ConcreteClass> {} // Ok

extension ExtensionOnS6 on G<Class<ConcreteClass>> {} // Ok

extension ExtensionOnS7 on G<Object> {} // Error

extension ExtensionOnS8 on G<int> {} // Error

main() {}
