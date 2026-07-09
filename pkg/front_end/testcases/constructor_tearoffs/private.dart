// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'private_lib.dart';

mixin M {}

class D = A with M;

class E = B with M; // TODO(johnniwinther): This should not be an error.

class F = C with M;
