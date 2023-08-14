// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/annotations.dart';

int get a => 1;
const b = 2;

// TODO(johnniwinther): Support code arguments.
@AnnotationsMacro(Class)
@AnnotationsMacro(a + b)
class Class {}
