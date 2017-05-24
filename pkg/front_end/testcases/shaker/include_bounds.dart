// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'lib/lib.dart';

/// Tree-shaker pulls in types mentioned in type-bounds like `Bound` in
/// `Base<T extends Bound>`.
foo(Base x) => null;
