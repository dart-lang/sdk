// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

class ExtendsInterfaceClassTypedef extends ATypeDef {}

class ExtendsInterfaceClassTypedef2 extends ATypeDef2 {}

class MixInInterfaceMixinTypeDef with MTypeDef {}

enum EnumMixInInterfaceMixinTypeDef with MTypeDef { foo }

class MixInInterfaceMixinTypeDef2 with MTypeDef2 {}

enum EnumMixInInterfaceMixinTypeDef2 with MTypeDef2 { foo }

typedef AOutsideTypedef = A;

typedef MOutsideTypedef = M;

class ExtendsInterfaceClassTypedefOutside extends AOutsideTypedef {}

class MixInInterfaceMixinTypeDefOutside with MOutsideTypedef {}

enum EnumMixInInterfaceMixinTypeDefOutside with MOutsideTypedef { foo }
