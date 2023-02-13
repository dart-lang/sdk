// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  try {
    throw null as dynamic;
  } on TypeError catch (e) {
    print('${e.runtimeType}:$e');
  }
}
