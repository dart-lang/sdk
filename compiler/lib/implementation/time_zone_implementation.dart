// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

// JavaScript implementation of TimeZoneImplementation.
class TimeZoneImplementation implements TimeZone {
  const TimeZoneImplementation.utc() : this.isUtc = true;
  const TimeZoneImplementation.local() : this.isUtc = false;

  bool operator ==(other) {
    if (!(other is TimeZoneImplementation)) return false;
    return isUtc == other.isUtc;
  }

  String toString() {
    if (isUtc) return "TimeZone (UTC)";
    return "TimeZone (Local)";
  }

  final bool isUtc;
}
