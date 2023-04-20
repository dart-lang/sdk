// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'main_lib.dart';

final class ExtendsFinalClassTypedef extends ATypeDef {}

final class ExtendsFinalClassTypedef2 extends ATypeDef2 {}

final class ImplementsFinalClassTypedef implements ATypeDef {}

final class ImplementsFinalClassTypedef2 implements ATypeDef2 {}

enum EnumImplementsFinalClassTypedef implements ATypeDef { x }

enum EnumImplementsFinalClassTypedef2 implements ATypeDef2 { x }

typedef AOutsideTypedef = A;

final class ExtendsFinalClassTypedefOutside extends AOutsideTypedef {}

final class ImplementsFinalClassTypedefOutside implements AOutsideTypedef {}

enum EnumImplementsFinalClassTypedefOutside implements AOutsideTypedef { x }
