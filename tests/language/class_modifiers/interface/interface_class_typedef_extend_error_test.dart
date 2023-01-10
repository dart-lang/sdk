// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Error when attempting to extend typedef interface class outside of its
// library.

import 'interface_class_typedef_lib.dart';

class ATypeDef extends InterfaceClassTypeDef {}
// ^
// [analyzer] unspecified
// [cfe] unspecified
