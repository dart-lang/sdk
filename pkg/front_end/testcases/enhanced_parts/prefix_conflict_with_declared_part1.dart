// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of 'prefix_conflict_with_declared.dart';

import 'prefix_conflict_with_declared_lib.dart' as declaredInMain; // Error
import 'prefix_conflict_with_declared_lib.dart' as declaredInPart1; // Error
import 'prefix_conflict_with_declared_lib.dart' as declaredInPart2; // Error
import 'prefix_conflict_with_declared_lib.dart' as declaredInPart3; // Error
import 'prefix_conflict_with_declared_lib.dart' as setterInMain; // Error
import 'prefix_conflict_with_declared_lib.dart' as setterInPart1; // Error
import 'prefix_conflict_with_declared_lib.dart' as setterInPart2; // Error
import 'prefix_conflict_with_declared_lib.dart' as setterInPart3; // Error

part 'prefix_conflict_with_declared_part2.dart';

void declaredInPart1() {}
void set setterInPart1(_) {}
