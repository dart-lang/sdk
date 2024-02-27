// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library augment 'class_augmentation_test.dart';

String get foo => 'a';

augment String get foo => '$augmented + b';

augment String get foo => '$augmented + c';

augment class A extends B implements I {
  augment List<int> get ints => augmented..add(2);
  augment List<int> get ints => augmented..add(3);

  String str = 'hello';
  augment String get str => '$augmented world';
  augment set str(String value) => augmented = '2$value'

  augment int needsInitialization = 1;

  augment String fieldWithInitializer = '${augmented}b';
  augment String fieldWithInitializer = '${augmented}c';

  augment bool _privateField = false;

  augment String funcWithoutBody() => 'a';

  augment String funcWithBody() => 'b${augmented()}';
  augment String funcWithBody() => '${augmented()}c';

  augment String get getterWithoutBody => _underlyingString;
  augment set setterWithoutBody(String value) => _underlyingString = value;
  augment set setterWithBody(String value) =>
      augmented = '$_underlyingString$value';

  augment operator==(Object other) => false;

  String newFunction() => 'a';
  augment String newFunction() => '${augmented()}b';

  String get newGetter => 'a';
  augment String get newGetter => '${augmented}b';

  set newSetter(String value) => _underlyingString = value;
  augment set newSetter(String value) => augmented='$value 1';

  // Override of `S.superX`.
  String get superX => '${super.superX}c';
  augment String get superX => '${augmented}d';

  augment A() : augmentationInitializerInitialized = true {
    augmented();
    augmentationConstructorInitialized = true;
  }
}

augment class A with M {
  augment List<int> get ints => augmented..add(4);

  augment String get str => '$augmented!';
  augment set str(String value) => augmented = '4$value';

  // Override of `M.mixinX`.
  String get mixinX => '${super.mixinX}c';
  augment String get mixinX => '${augmented}d';
}


augment class B {
  augment String get superX => '${augmented}b';
}

augment mixin M {
  augment String get mixinX => '${augmented}b';
}
