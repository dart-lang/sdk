// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String topLevelField = 'original';

int topLevelGetterInternal = 0;
String get topLevelGetter {
  topLevelGetterInternal++;
  return 'original';
}

int topLevelSetterInternal = 0;
set topLevelSetter(String value) {
  topLevelSetterInternal++;
}

int topLevelMethodInternal = 0;
void topLevelMethod(String value) {
  topLevelMethodInternal++;
}
