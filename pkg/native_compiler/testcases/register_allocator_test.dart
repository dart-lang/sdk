// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// From dart:_internal::SystemHash.

int combine(int hash, int argalue) {
  hash = 0x1fffffff & (hash + argalue);
  hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
  return hash ^ (hash >> 6);
}

int finish(int hash) {
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash = hash ^ (hash >> 11);
  return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
}

int hash19(
  int arg1,
  int arg2,
  int arg3,
  int arg4,
  int arg5,
  int arg6,
  int arg7,
  int arg8,
  int arg9,
  int arg10,
  int arg11,
  int arg12,
  int arg13,
  int arg14,
  int arg15,
  int arg16,
  int arg17,
  int arg18,
  int arg19,
  int seed,
) {
  var hash = seed;
  hash = combine(hash, arg1);
  hash = combine(hash, arg2);
  hash = combine(hash, arg3);
  hash = combine(hash, arg4);
  hash = combine(hash, arg5);
  hash = combine(hash, arg6);
  hash = combine(hash, arg7);
  hash = combine(hash, arg8);
  hash = combine(hash, arg9);
  hash = combine(hash, arg10);
  hash = combine(hash, arg11);
  hash = combine(hash, arg12);
  hash = combine(hash, arg13);
  hash = combine(hash, arg14);
  hash = combine(hash, arg15);
  hash = combine(hash, arg16);
  hash = combine(hash, arg17);
  hash = combine(hash, arg18);
  hash = combine(hash, arg19);
  return finish(hash);
}

void main() {}
