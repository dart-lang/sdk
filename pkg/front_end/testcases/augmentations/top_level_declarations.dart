// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void topLevelMethod();
augment void topLevelMethod() {}

int get topLevelGetter;
augment get topLevelGetter => 0;

void set topLevelSetter(int value);
augment void set topLevelSetter(int value) {}
