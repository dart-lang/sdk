// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final bool inSoundMode = <int?>[] is! List<int>;

main() {
  try {
    throw null as dynamic;
  } on NullThrownError catch (e) {
    if (inSoundMode) {
      throw 'Expected TypeError';
    } else {
      print('${e.runtimeType}:$e');
    }
  } on TypeError catch (e) {
    if (inSoundMode) {
      print('${e.runtimeType}:$e');
    } else {
      throw 'Expected NullThrowError';
    }
  }
}
