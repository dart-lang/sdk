// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'access_no_nsm_lib.dart';

class SubClass1 extends SuperClass {}

class SubClass2 implements SuperClass {}

class SubClass3 with SuperClass {}

class SubSubClass1 extends SubClass1 {}

class SubSubClass2 extends SubClass2 {}

class SubSubClass3 extends SubClass3 {}

abstract class AbstractSubClass1 extends SuperClass {}

abstract class AbstractSubClass2 implements SuperClass {}

abstract class AbstractSubClass3 with SuperClass {}

class SubAbstractSubClass1 extends AbstractSubClass1 {}

class SubAbstractSubClass2 extends AbstractSubClass2 {}

class SubAbstractSubClass3 extends AbstractSubClass3 {}
