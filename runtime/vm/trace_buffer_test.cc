// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/globals.h"
#include "vm/json_stream.h"
#include "vm/trace_buffer.h"
#include "vm/unit_test.h"

namespace dart {


UNIT_TEST_CASE(TraceBufferEmpty) {
  TraceBuffer* trace_buffer = new TraceBuffer(3, 3);
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_STREQ("{\"type\":\"TraceBuffer\",\"id\":\"\",\"members\":[]}",
                 js.ToCString());
  }
  delete trace_buffer;
}


UNIT_TEST_CASE(TraceBufferClear) {
  TraceBuffer* trace_buffer = new TraceBuffer(3, 3);
  trace_buffer->Trace(kMicrosecondsPerSecond * 1, "abc");
  trace_buffer->Clear();
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_STREQ("{\"type\":\"TraceBuffer\",\"id\":\"\",\"members\":[]}",
                 js.ToCString());
  }
  delete trace_buffer;
}


UNIT_TEST_CASE(TraceBufferTrace) {
  TraceBuffer* trace_buffer = new TraceBuffer(3, 3);

  trace_buffer->Trace(kMicrosecondsPerSecond * 1, "abc");
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_STREQ("{\"type\":\"TraceBuffer\",\"id\":\"\",\"members\":["
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":1000,"
                 "\"message\":\"abc\"}]}", js.ToCString());
  }
  trace_buffer->Trace(kMicrosecondsPerSecond * 2, "def");
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_STREQ("{\"type\":\"TraceBuffer\",\"id\":\"\",\"members\":["
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":1000,"
                 "\"message\":\"abc\"},"
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":2000,"
                 "\"message\":\"def\"}]}", js.ToCString());
  }
  trace_buffer->Trace(kMicrosecondsPerSecond * 3, "ghi");
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_STREQ("{\"type\":\"TraceBuffer\",\"id\":\"\",\"members\":["
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":1000,"
                 "\"message\":\"abc\"},"
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":2000,"
                 "\"message\":\"def\"},"
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":3000,"
                 "\"message\":\"ghi\"}]}", js.ToCString());
  }
  // This will overwrite the first Trace.
  trace_buffer->Trace(kMicrosecondsPerSecond * 4, "jkl");
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_STREQ("{\"type\":\"TraceBuffer\",\"id\":\"\",\"members\":["
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":2000,"
                 "\"message\":\"def\"},"
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":3000,"
                 "\"message\":\"ghi\"},"
                 "{\"type\":\"TraceBufferEntry\",\"id\":\"\",\"time\":4000,"
                 "\"message\":\"jkl\"}]}", js.ToCString());
  }
  delete trace_buffer;
}


UNIT_TEST_CASE(TraceBufferTraceF) {
  TraceBuffer* trace_buffer = new TraceBuffer(3, 3);
  trace_buffer->TraceF("foo %d %s", 99, "bar");
  {
    JSONStream js;
    trace_buffer->PrintToJSONStream(&js);
    EXPECT_SUBSTRING("foo 99 bar", js.ToCString());
  }
  delete trace_buffer;
}


UNIT_TEST_CASE(TraceBufferGrow) {
  TraceBuffer* trace_buffer = new TraceBuffer(1);
  EXPECT_EQ(1, trace_buffer->capacity());
  trace_buffer->Trace(kMicrosecondsPerSecond * 1, "abc");
  EXPECT_EQ(2, trace_buffer->capacity());
}


}  // namespace dart
