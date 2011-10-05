// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

interface TimeZone factory TimeZoneImplementation {
  // The offset to UTC
  // TODO(floitsch): The interface of this class will most likely change.
  // [offset] will probably not be accessible this way. It is much simpler to
  // think of TimeZones as locations instead of offsets.
  // When constructing a date, one wants to say: give me the DateTime in Paris.
  // The date is then used to determine if it should be CET or CEST.
  // However this also means that the offset is depending on an associated
  // date.
  final Time offset;

  // TODO(floitsch): The interface of this class will most likely change.
  // This constructor will probably disappear.
  const TimeZone(Time offset);
  const TimeZone.utc();
  TimeZone.local();
}
