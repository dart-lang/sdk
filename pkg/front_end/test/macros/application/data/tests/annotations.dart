// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: 
Declarations Order:
 Class:AnnotationsMacro.new(ListArgument:[0, 1])
 Class:AnnotationsMacro.new(ListArgument:[0])
 Class:AnnotationsMacro.new(ListArgument:[])
 Class:AnnotationsMacro.new(IntArgument:0,IntArgument:1)
 Class:AnnotationsMacro.new(IntArgument:0)*/

import 'package:macro/annotations.dart';

@AnnotationsMacro(0)
@AnnotationsMacro(0, 1)
@AnnotationsMacro([])
@AnnotationsMacro([0])
@AnnotationsMacro([0, 1])
class Class {}
