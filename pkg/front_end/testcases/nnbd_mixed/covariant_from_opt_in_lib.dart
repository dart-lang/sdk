// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Mixin {}

abstract class Class {
  void covariant(covariant Class cls);
  void invariant(Class cls);
  void contravariant(Class cls);
}
