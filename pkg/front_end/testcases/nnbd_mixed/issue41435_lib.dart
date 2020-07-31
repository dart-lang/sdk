// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

Never x = throw "Unreachable";
void takesNever(Never x) {}
void takesTakesNull(void Function(Null) f) {}
void Function(Null) f = (n) {};
