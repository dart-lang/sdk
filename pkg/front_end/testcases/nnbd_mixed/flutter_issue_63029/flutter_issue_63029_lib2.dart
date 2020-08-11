// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.8

import 'flutter_issue_63029_lib1.dart';

class C {}

mixin D<T extends A> on B<T> implements C {}
