// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

import 'member_signature_lib.dart';

abstract class AbstractClass extends Super implements Interface1, Interface2 {}

class ConcreteSub extends AbstractClass {}

class ConcreteClass extends Super implements Interface1, Interface2 {}

abstract class OptOutInterface {}

abstract class ClassImplementsOptOut implements OptOutInterface {}

main() {}
