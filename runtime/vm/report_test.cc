// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/assert.h"
#include "vm/report.h"
#include "vm/unit_test.h"

namespace dart {

TEST_CASE(TraceJSWarning) {
  Isolate* isolate = Isolate::Current();
  TraceBuffer::Init(isolate, 3);
  TraceBuffer* trace_buffer = isolate->trace_buffer();
  const String& url = String::Handle(isolate, String::New("Plug"));
  const String& source = String::Handle(isolate, String::New("240 100"));
  const Script& script = Script::Handle(isolate,
      Script::New(url, source, RawScript::kScriptTag));
  script.Tokenize(String::Handle(String::New("")));
  {
    const intptr_t token_pos = 0;
    const char* message = "High Voltage";
    Report::MessageF(Report::kJSWarning, script, token_pos, "%s", message);
    {
      JSONStream js;
      trace_buffer->PrintToJSONStream(&js);
      EXPECT_SUBSTRING("{\"type\":\"TraceBuffer\",\"members\":["
                       "{\"type\":\"TraceBufferEntry\",\"time\":",
                       js.ToCString());
      // Skip time.
      EXPECT_SUBSTRING("\"message\":{\"type\":\"JSCompatibilityWarning\","
                       "\"script\":{\"type\":\"@Script\",\"id\":"
                       "\"libraries\\/-1\\/scripts\\/Plug\","
                       "\"name\":\"Plug\","
                       "\"kind\":\"script\"},\"tokenPos\":0,"
                       "\"message\":{\"type\":\"@String\"",
                       js.ToCString());
      // Skip private _OneByteString.
      EXPECT_SUBSTRING("\"valueAsString\":\"High Voltage\"",
                       js.ToCString());
    }
  }
  {
    const intptr_t token_pos = 1;
    const char* message = "Low Voltage";
    Report::MessageF(Report::kJSWarning, script, token_pos, "%s", message);
  }
  EXPECT_EQ(2, trace_buffer->Length());
  EXPECT_SUBSTRING("{\"type\":\"JSCompatibilityWarning\",\"script\":{\"type\":"
                   "\"@Script\",\"id\":\"libraries\\/-1\\/scripts\\/Plug\","
                   "\"name\":\"Plug\","
                   "\"kind\":\"script\"},\"tokenPos\":0,"
                   "\"message\":{\"type\":\"@String\"",
                   trace_buffer->At(0)->message);
  // Skip private _OneByteString.
  EXPECT_SUBSTRING("\"valueAsString\":\"High Voltage\"",
                   trace_buffer->At(0)->message);

  EXPECT_SUBSTRING("{\"type\":\"JSCompatibilityWarning\",\"script\":{\"type\":"
                   "\"@Script\",\"id\":\"libraries\\/-1\\/scripts\\/Plug\","
                   "\"name\":\"Plug\","
                   "\"kind\":\"script\"},\"tokenPos\":1,"
                   "\"message\":{\"type\":\"@String\"",
                   trace_buffer->At(1)->message);
  // Skip private _OneByteString.
  EXPECT_SUBSTRING("\"valueAsString\":\"Low Voltage\"",
                   trace_buffer->At(1)->message);

  delete trace_buffer;
}

}  // namespace dart
