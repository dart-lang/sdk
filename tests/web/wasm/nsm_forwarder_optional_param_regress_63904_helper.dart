// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

mixin Mixin {
  Invocation foo({bool arg = true}) => throw 'a';
  Invocation bar([bool arg = true]) => throw 'a';
}

abstract class Interface with Mixin {}
