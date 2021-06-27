// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Interface1 {
  int get implementMultipleGetter => 0;

  int get declareConcreteImplementMultipleGetter => 0;

  int get declareAbstractImplementMultipleGetter => 0;
}

class Interface2 {
  int get implementMultipleGetter => 0;

  int get declareConcreteImplementMultipleGetter => 0;

  int get declareAbstractImplementMultipleGetter => 0;
}

class ConcreteClass implements Interface1, Interface2 {
  int get declareConcreteImplementMultipleGetter => 0;

  int get declareAbstractImplementMultipleGetter;
}

abstract class AbstractClass implements Interface1, Interface2 {
  int get declareConcreteImplementMultipleGetter => 0;

  int get declareAbstractImplementMultipleGetter;
}

class ConcreteSub extends AbstractClass {}

main() {}
