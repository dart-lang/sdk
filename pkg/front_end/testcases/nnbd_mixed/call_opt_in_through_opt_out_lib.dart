// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void takesNull(Null n) {}
void takesNever(Never n) {}
applyTakesNull(void Function(Null) f) {}
applyTakesNever(void Function(Never) f) {}
applyTakesNullNamed({required void Function(Null) f}) {}
applyTakesNeverNamed({required void Function(Never) f}) {}

void takesNullable(int? i) {}
void takesNonNullable(int i) {}
applyTakesNullable(void Function(int?) f) {}
applyTakesNonNullable(void Function(int) f) {}
applyTakesNullableNamed({required void Function(int?) f}) {}
applyTakesNonNullableNamed({required void Function(int) f}) {}
