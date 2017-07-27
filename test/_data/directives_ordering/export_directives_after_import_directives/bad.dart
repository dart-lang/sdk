// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library dummy_lib;

import 'dummy.dart';

export 'dummy.dart';  // LINT

import 'dummy2.dart';

export 'dummy2.dart';  // LINT

import 'dummy3.dart';

export 'dummy3.dart';  // OK

part 'dummy4.dart';  // Language requires export before part directivess.
