// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <time.h>

#include "vm/bootstrap_natives.h"

#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/os.h"

namespace dart {

static int64_t kMaxAllowedSeconds = kMaxInt32;

DEFINE_NATIVE_ENTRY(DateTime_timeZoneName, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, dart_seconds,
                               arguments->NativeArgAt(0));
  int64_t seconds = dart_seconds.AsInt64Value();
  if (llabs(seconds) > kMaxAllowedSeconds) {
    Exceptions::ThrowArgumentError(dart_seconds);
  }
  const char* name = OS::GetTimeZoneName(seconds);
  return String::New(name);
}

DEFINE_NATIVE_ENTRY(DateTime_timeZoneOffsetInSeconds, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Integer, dart_seconds,
                               arguments->NativeArgAt(0));
  int64_t seconds = dart_seconds.AsInt64Value();
  if (llabs(seconds) > kMaxAllowedSeconds) {
    Exceptions::ThrowArgumentError(dart_seconds);
  }
  int offset = OS::GetTimeZoneOffsetInSeconds(seconds);
  return Integer::New(offset);
}

DEFINE_NATIVE_ENTRY(DateTime_localTimeZoneAdjustmentInSeconds, 0) {
  int adjustment = OS::GetLocalTimeZoneAdjustmentInSeconds();
  return Integer::New(adjustment);
}

DEFINE_NATIVE_ENTRY(DateTime_currentTimeMicros, 0) {
  return Integer::New(OS::GetCurrentTimeMicros());
}

}  // namespace dart
