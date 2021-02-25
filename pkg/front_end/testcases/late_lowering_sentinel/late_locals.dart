// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test() {
  late int? nullableTopLevelLocal;
  late int nonNullableTopLevelLocal;
  late int? nullableTopLevelLocalWithInitializer = null;
  late int nonNullableTopLevelLocalWithInitializer = 0;
  late final int? nullableFinalTopLevelLocal;
  late final int nonNullableFinalTopLevelLocal;
  late final int? nullableFinalTopLevelLocalWithInitializer = null;
  late final int nonNullableFinalTopLevelLocalWithInitializer = 0;
  late Never neverLocal;
}

main() {}
