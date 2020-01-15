// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

part of 'having_part_with_parts_and_annotation.dart';

@Bar
part 'having_part_with_parts_and_annotation_lib2.dart';
@Baz
part 'having_part_with_parts_and_annotation_lib2.dart';

const int Bar = 43;
const int Baz = 44;

void fromLib1() {}
