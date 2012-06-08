// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

/**
 * [TimeZone]s represent locations (for example Europe/Paris).
 *
 * *DEPRECATED*
 */
interface TimeZone default TimeZoneImplementation {
  const TimeZone.utc();
  TimeZone.local();
  bool get isUtc();
}
