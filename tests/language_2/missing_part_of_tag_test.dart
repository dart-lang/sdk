// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for missing part-of tag.

library lib;

part 'missing_part_of_tag_part.dart'; //# 01: compile-time error

void main() {}
