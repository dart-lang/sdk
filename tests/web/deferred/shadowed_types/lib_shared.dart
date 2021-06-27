// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Class A has a type used in libb, but a class used in liba.
class A {}

// Class B has a class used in the main output unit, and a type used in libb.
class B {}

// Class C_Parent is extended is libb, and closed around in the main output
// unit.
class C_Parent {}

// Classes D through F represent a simple heirarchy.
// D's type is used in liba.
// F is instantiated, but unused in libb.
class D {}

class E extends D {}

class F {}
