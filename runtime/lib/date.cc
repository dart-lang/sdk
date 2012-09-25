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

static int32_t kMaxAllowedSeconds = 2100000000;

DEFINE_NATIVE_ENTRY(DateNatives_timeZoneName, 1) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  int64_t seconds = dart_seconds.AsInt64Value();
  if (seconds < 0 || seconds > kMaxAllowedSeconds) {
    GrowableArray<const Object*> args;
    args.Add(&dart_seconds);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  const char* name = OS::GetTimeZoneName(seconds);
  return String::New(name);
}


DEFINE_NATIVE_ENTRY(DateNatives_timeZoneOffsetInSeconds, 1) {
  GET_NATIVE_ARGUMENT(Integer, dart_seconds, arguments->At(0));
  int64_t seconds = dart_seconds.AsInt64Value();
  if (seconds < 0 || seconds > kMaxAllowedSeconds) {
    GrowableArray<const Object*> args;
    args.Add(&dart_seconds);
    Exceptions::ThrowByType(Exceptions::kArgument, args);
  }
  int offset = OS::GetTimeZoneOffsetInSeconds(seconds);
  return Integer::New(offset);
}


DEFINE_NATIVE_ENTRY(DateNatives_localTimeZoneAdjustmentInSeconds, 0) {
  int adjustment = OS::GetLocalTimeZoneAdjustmentInSeconds();
  return Integer::New(adjustment);
}


DEFINE_NATIVE_ENTRY(DateNatives_currentTimeMillis, 0) {
  return Integer::New(OS::GetCurrentTimeMillis());
}

}  // namespace dart
