// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

base class ImplementsBaseClassTypedef implements ATypeDef {}

base class ImplementsBaseClassTypedef2 implements ATypeDef2 {}

base class ImplementsBaseMixinTypeDef implements MTypeDef {}

base class ImplementsBaseMixinTypeDef2 implements MTypeDef2 {}

typedef AOutsideTypedef = A;

typedef MOutsideTypedef = M;

base class ImplementsBaseClassTypedefOutside implements AOutsideTypedef {}

base class ImplementsBaseMixinTypeDefOutside implements MOutsideTypedef {}
