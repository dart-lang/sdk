// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of models;

abstract class Zone {
  /// The total amount of memory in bytes allocated in the zone, including
  /// memory that is not actually being used.
  int get capacity;

  /// The total amount of memory in bytes actually used in the zone.
  int get used;
}
