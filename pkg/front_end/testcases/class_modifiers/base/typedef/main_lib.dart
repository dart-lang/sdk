// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

base class A {}

typedef ATypeDef = A;

typedef ATypeDef2 = ATypeDef;

base mixin M {}

typedef MTypeDef = M;

typedef MTypeDef2 = MTypeDef;
