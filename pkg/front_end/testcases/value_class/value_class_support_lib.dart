// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jlcontreras): this is a temp file for the valueClass experiment

const valueClass = "valueClass";

/// This code is from the dart.math sdk/lib/math/jenkins_smi_hash.dart
class JenkinsSmiHash {
  static int combine(int hash, int value) {
    hash = 0x1fffffff & (hash + value);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}
