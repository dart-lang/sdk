// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

part 'no_part_of_part.dart';

//   ^
// [analyzer] unspecified
// [cfe] Can't use 'tests/language/part/enhanced_parts/no_part_of_part.dart' as a part, because it has no 'part of' declaration.

void main() {}
