// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'flutter_issue_63029_lib1.dart';
import 'flutter_issue_63029_lib2.dart';

class E extends A {}

class F extends B<E> with D<E> {}

main() {}