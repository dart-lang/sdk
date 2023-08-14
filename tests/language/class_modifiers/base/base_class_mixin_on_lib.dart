// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Other-library declarations used by base_class_mixin_on_test.dart.

base class BaseClass {}

abstract base class A extends BaseClass {}

base class B extends BaseClass {}

base mixin BaseMixin {}

base class C extends BaseClass with BaseMixin {}

base class D with BaseMixin {}
