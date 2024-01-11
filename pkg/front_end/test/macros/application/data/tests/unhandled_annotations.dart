// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:macro/annotations.dart';

int get a => 1;
const b = 2;
T id<T>(T t) => t;

@AnnotationsMacro(const Object())
@AnnotationsMacro(const [])
@AnnotationsMacro(const {})
@AnnotationsMacro(<void Function()>{})
@AnnotationsMacro(Object())
@AnnotationsMacro(#a)
@AnnotationsMacro((0))
@AnnotationsMacro((0,))
@AnnotationsMacro(<(int, {String a})>{})
@AnnotationsMacro(<(int, {String a})>{})
@AnnotationsMacro(0 is int)
@AnnotationsMacro(0 as int)
@AnnotationsMacro(true ? 0 : 1)
@AnnotationsMacro(Object.new())
@AnnotationsMacro("foo".length)
@AnnotationsMacro(id<int>)
// TODO(johnniwinther): Support code arguments.
@AnnotationsMacro(Class)
@AnnotationsMacro(a + b)
class Class {}
