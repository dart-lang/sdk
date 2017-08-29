// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

import 'lib/lib.dart';

/// Kernel directly represents this as a type, so typedef is not preserved.
foo(Typedef1<dynamic> x) => null;

bar(Typedef2 x) => null;
