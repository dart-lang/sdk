// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "main_lib1.dart";
import "main_lib2.dart";

base class Base {}

base class BaseA extends A /* Ok */ {}

base class BaseA2 extends BaseA /* Ok */ {}

base class DirectA implements A /* Error */ {}

base class IndirectA implements BaseA /* Error */ {}

base class IndirectBaseA extends Base implements BaseA /* Error */ {}

base class IndirectA2 implements BaseA2 /* Error */ {}

base class IndirectBaseA2 extends Base implements BaseA2 /* Error */ {}

base class BaseB extends B /* Ok */ {}

base class BaseB2 extends BaseB /* Ok */ {}

base class DirectB implements B /* Error */ {}

base class IndirectB implements BaseB /* Error */ {}

base class IndirectB2 implements BaseB2 /* Error */ {}

base class IndirectBaseB extends Base implements BaseB /* Error */ {}

base class IndirectBaseB2 extends Base implements BaseB2 /* Error */ {}
