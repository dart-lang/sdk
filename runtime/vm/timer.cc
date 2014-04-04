// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#include "vm/timer.h"
#include "vm/json_stream.h"

namespace dart {

// Define timer command line flags.
#define DEFINE_TIMER_FLAG(name, msg)                                           \
  DEFINE_FLAG(bool, name, false, ""#name);
TIMER_LIST(DEFINE_TIMER_FLAG)
#undef DEFINE_TIMER_FLAG
DEFINE_FLAG(bool, time_all, false, "Time all functionality");


// Maintains a list of timers per isolate.
#define INIT_TIMERS(name, msg)                                                 \
  name##_((FLAG_##name || FLAG_time_all), msg),
TimerList::TimerList()
    : TIMER_LIST(INIT_TIMERS)
      padding_(false) {
}
#undef INIT_TIMERS


#define TIMER_FIELD_REPORT(name, msg)                                          \
  if (name().report() && name().message() != NULL) {                           \
    OS::Print("%s :  %.3f ms total; %.3f ms max.\n",                           \
              name().message(),                                                \
              MicrosecondsToMilliseconds(name().TotalElapsedTime()),           \
              MicrosecondsToMilliseconds(name().MaxContiguous()));             \
  }
void TimerList::ReportTimers() {
  TIMER_LIST(TIMER_FIELD_REPORT);
}
#undef TIMER_FIELD_REPORT


#define JSON_TIMER(name, msg)                                                  \
  {                                                                            \
    JSONObject jsobj(&jsarr);                                                  \
    jsobj.AddProperty("name", #name);                                          \
    jsobj.AddProperty("time",                                                  \
                      MicrosecondsToSeconds(name().TotalElapsedTime()));       \
    jsobj.AddProperty("max_contiguous",                                        \
                      MicrosecondsToSeconds(name().MaxContiguous()));          \
  }
void TimerList::PrintTimersToJSONProperty(JSONObject* jsobj) {
  JSONArray jsarr(jsobj, "timers");
  TIMER_LIST(JSON_TIMER);
}
#undef JSON_TIMER

}  // namespace dart
