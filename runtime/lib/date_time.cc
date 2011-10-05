// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"

#include "vm/bigint_operations.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os.h"

namespace dart {

static bool BreakDownSecondsSinceEpoch(const Integer& dart_seconds,
                                       const Bool& dart_is_utc,
                                       OS::BrokenDownDateTime* result) {
  bool is_utc = dart_is_utc.value();
  int64_t value = dart_seconds.AsInt64Value();
  time_t seconds = static_cast<time_t>(value);
  return OS::BreakDownSecondsSinceEpoch(seconds, is_utc, result);
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_brokenDownToSecondsSinceEpoch, 7) {
  const Integer& dart_years = Integer::CheckedHandle(arguments->At(0));
  const Smi& dart_month = Smi::CheckedHandle(arguments->At(1));
  const Smi& dart_day = Smi::CheckedHandle(arguments->At(2));
  const Smi& dart_hours = Smi::CheckedHandle(arguments->At(3));
  const Smi& dart_minutes = Smi::CheckedHandle(arguments->At(4));
  const Smi& dart_seconds = Smi::CheckedHandle(arguments->At(5));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(6));
  if (!dart_years.IsSmi()) {
    UNIMPLEMENTED();
  }
  Smi& smi_years = Smi::Handle();
  smi_years ^= dart_years.raw();
  OS::BrokenDownDateTime broken_down;
  // mktime takes the years since 1900.
  // TODO(floitsch): Removing 1900 could underflow the intptr_t.
  intptr_t year = smi_years.Value() - 1900;
  // TODO(floitsch): We don't handle the case yet where intptr_t and int have
  // different sizes.
  ASSERT(sizeof(year) <= sizeof(broken_down.year));
  broken_down.year = year;
  // libc months are 0-based (contrary to Dart' 1-based months).
  broken_down.month = dart_month.Value() - 1;
  broken_down.day = dart_day.Value();
  broken_down.hours = dart_hours.Value();
  broken_down.minutes = dart_minutes.Value();
  broken_down.seconds = dart_seconds.Value();
  time_t value;
  bool succeeded = OS::BrokenDownToSecondsSinceEpoch(broken_down,
                                                     dart_is_utc.value(),
                                                     &value);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  arguments->SetReturn(Integer::Handle(Integer::New(value)));
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_currentTimeMillis, 0) {
  const Integer& time = Integer::Handle(
      Integer::New(OS::GetCurrentTimeMillis()));
  arguments->SetReturn(time);
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_getYear, 2) {
  const Integer& dart_seconds = Integer::CheckedHandle(arguments->At(0));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(1));
  OS::BrokenDownDateTime broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  // C uses years since 1900, and not full years.
  // TODO(floitsch): adding 1900 could overflow the intptr_t.
  intptr_t year = broken_down.year + 1900;
  arguments->SetReturn(Integer::Handle(Integer::New(year)));
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_getMonth, 2) {
  const Integer& dart_seconds = Integer::CheckedHandle(arguments->At(0));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(1));
  OS::BrokenDownDateTime broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  // Dart has 1-based months (contrary to C's 0-based).
  const Smi& result = Smi::Handle(Smi::New(broken_down.month + 1));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_getDay, 2) {
  const Integer& dart_seconds = Integer::CheckedHandle(arguments->At(0));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(1));
  OS::BrokenDownDateTime broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.day));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_getHours, 2) {
  const Integer& dart_seconds = Integer::CheckedHandle(arguments->At(0));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(1));
  OS::BrokenDownDateTime broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.hours));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_getMinutes, 2) {
  const Integer& dart_seconds = Integer::CheckedHandle(arguments->At(0));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(1));
  OS::BrokenDownDateTime broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.minutes));
  arguments->SetReturn(result);
}


DEFINE_NATIVE_ENTRY(DateTimeNatives_getSeconds, 2) {
  const Integer& dart_seconds = Integer::CheckedHandle(arguments->At(0));
  const Bool& dart_is_utc = Bool::CheckedHandle(arguments->At(1));
  OS::BrokenDownDateTime broken_down;
  bool succeeded =
      BreakDownSecondsSinceEpoch(dart_seconds, dart_is_utc, &broken_down);
  if (!succeeded) {
    UNIMPLEMENTED();
  }
  const Smi& result = Smi::Handle(Smi::New(broken_down.seconds));
  arguments->SetReturn(result);
}

}  // namespace dart
