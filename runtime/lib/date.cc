// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <time.h>

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os.h"

namespace dart {

typedef struct BrokenDownDate {
  intptr_t year;
  intptr_t month;  // [1..12]
  intptr_t day;    // [1..31]
  intptr_t hours;
  intptr_t minutes;
  intptr_t seconds;
} BrokenDownDate;


// Takes the seconds since epoch (midnight, January 1, 1970 UTC) and breaks it
// down into date and time.
// If 'dart_is_utc', then the broken down date and time are in the UTC timezone,
// otherwise the local timezone is used.
// The returned year is offset by 1900. The returned month is 0-based.
// Returns true if the conversion succeeds, false otherwise.
static bool BreakDownSecondsSinceEpoch(const Integer& dart_seconds,
                                       const Bool& dart_is_utc,
                                       BrokenDownDate* result) {
  // Always fill the result to avoid unitialized use warnings.
  result->year = 0;
  result->month = 0;
  result->day = 0;
  result->hours = 0;
  result->minutes = 0;
  result->seconds = 0;

  bool is_utc = dart_is_utc.value();
  int64_t seconds = dart_seconds.AsInt64Value();

  struct tm tm_result;
  bool succeeded;
  if (is_utc) {
    succeeded = OS::GmTime(seconds, &tm_result);
  } else {
    succeeded = OS::LocalTime(seconds, &tm_result);
  }
  if (succeeded) {
    result->year = tm_result.tm_year;
    // C uses years since 1900, and not full years.
    // Adding 1900 could overflow the intptr_t.
    if (tm_result.tm_year > kIntptrMax - 1900) return false;
    result->year += 1900;
    // Dart has 1-based months (contrary to C's 0-based).
    result->month= tm_result.tm_mon + 1;
    result->day = tm_result.tm_mday;
    result->hours = tm_result.tm_hour;
    result->minutes = tm_result.tm_min;
    result->seconds = tm_result.tm_sec;
  }
  return succeeded;
}


static bool BrokenDownToSecondsSinceEpoch(const BrokenDownDate& broken_down,
                                          bool in_utc,
                                          int64_t* result) {
  // Always set the result to avoid unitialized use warnings.
  *result = 0;

  struct tm tm_broken_down;
  intptr_t year = broken_down.year;
  // C works with years since 1900.
  // Removing 1900 could underflow the intptr_t.
  if (year < kIntptrMin + 1900) return false;
  year -= 1900;
  intptr_t month = broken_down.month;
  // C works with 0-based months.
  // Avoid underflows (even though they should not matter since the date would
  // be invalid anyways.
  if (month < 0) return false;
  month--;
  tm_broken_down.tm_year = static_cast<int>(year);
  tm_broken_down.tm_mon = static_cast<int>(month);
  tm_broken_down.tm_mday = static_cast<int>(broken_down.day);
  tm_broken_down.tm_hour = static_cast<int>(broken_down.hours);
  tm_broken_down.tm_min = static_cast<int>(broken_down.minutes);
  tm_broken_down.tm_sec = static_cast<int>(broken_down.seconds);
  // Verify that casting to int did not change the value.
  if (tm_broken_down.tm_year != year
      || tm_broken_down.tm_mon != month
      || tm_broken_down.tm_mday != broken_down.day
      || tm_broken_down.tm_hour != broken_down.hours
      || tm_broken_down.tm_min != broken_down.minutes
      || tm_broken_down.tm_sec != broken_down.seconds) {
    return false;
  }
  if (in_utc) {
    return OS::MkGmTime(&tm_broken_down, result);
  } else {
    return OS::MkTime(&tm_broken_down, result);
  }
}


DEFINE_NATIVE_ENTRY(DateNatives_brokenDownToSecondsSinceEpoch, 7) {
  GET_NATIVE_ARGUMENT(Integer, dart_years, arguments->At(0));
  GET_NATIVE_ARGUMENT(Smi, dart_month, arguments->At(1));
  GET_NATIVE_ARGUMENT(Smi, dart_day, arguments->At(2));
  GET_NATIVE_ARGUMENT(Smi, dart_hours, arguments->At(3));
  GET_NATIVE_ARGUMENT(Smi, dart_minutes, arguments->At(4));
  GET_NATIVE_ARGUMENT(Smi, dart_seconds, arguments->At(5));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(6));
  if (!dart_years.IsSmi()) {
    UNIMPLEMENTED();
  }
  Smi& smi_years = Smi::Handle();
  smi_years ^= dart_years.raw();
  BrokenDownDate broken_down;
  broken_down.year = smi_years.Value();
  broken_down.month = dart_month.Value();
  broken_down.day = dart_day.Value();
  broken_down.hours = dart_hours.Value();
  broken_down.minutes = dart_minutes.Value();
  broken_down.seconds = dart_seconds.Value();
  int64_t value;
  bool succeeded = BrokenDownToSecondsSinceEpoch(broken_down,
                                                 dart_is_utc.value(),
                                                 &value);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  arguments->SetReturn(Integer::Handle(Integer::New(value)));
}


DEFINE_NATIVE_ENTRY(DateNatives_currentTimeMillis, 0) {
  const Integer& time = Integer::Handle(
      Integer::New(OS::GetCurrentTimeMillis()));
  arguments->SetReturn(time);
}


DEFINE_NATIVE_ENTRY(DateNatives_getYear, 2) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(1));
  BrokenDownDate broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  intptr_t year = broken_down.year;
  arguments->SetReturn(Integer::Handle(Integer::New(year)));
}


DEFINE_NATIVE_ENTRY(DateNatives_getMonth, 2) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(1));
  BrokenDownDate broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.month));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateNatives_getDay, 2) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(1));
  BrokenDownDate broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.day));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateNatives_getHours, 2) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(1));
  BrokenDownDate broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.hours));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateNatives_getMinutes, 2) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(1));
  BrokenDownDate broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.minutes));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateNatives_getSeconds, 2) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  GET_NATIVE_ARGUMENT(Bool, dart_is_utc, arguments->At(1));
  BrokenDownDate broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.seconds));
  arguments->SetReturn(result);
}

}  // namespace dart
