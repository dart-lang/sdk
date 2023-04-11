// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'issue51823_lib.dart';

const a = const bool.fromEnvironment('foo') ? E.a : E.b;
