// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin class NotObject {}

mixin class AlsoNotObject {}

mixin class A extends NotObject {}

mixin class B extends Object with NotObject {}

mixin class C = Object with NotObject;

mixin class D = Object with AlsoNotObject, NotObject;
