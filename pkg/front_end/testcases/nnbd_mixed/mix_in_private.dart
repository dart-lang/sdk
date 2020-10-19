// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// @dart=2.8

import 'mix_in_private_lib.dart';

class A {}

class C = A with Private;

main() {}
