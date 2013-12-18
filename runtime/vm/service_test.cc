// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_debugger_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/globals.h"
#include "vm/message_handler.h"
#include "vm/os.h"
#include "vm/port.h"
#include "vm/service.h"
#include "vm/unit_test.h"

namespace dart {

class ServiceTestMessageHandler : public MessageHandler {
 public:
  ServiceTestMessageHandler() : _msg(NULL) {}

  ~ServiceTestMessageHandler() {
    free(_msg);
  }

  bool HandleMessage(Message* message) {
    if (_msg != NULL) {
      free(_msg);
    }

    // Parse the message.
    SnapshotReader reader(message->data(), message->len(),
                          Snapshot::kMessage, Isolate::Current());
    const Object& response_obj = Object::Handle(reader.ReadObject());
    String& response = String::Handle();
    response ^= response_obj.raw();
    _msg = strdup(response.ToCString());
    return true;
  }

  const char* msg() const { return _msg; }

 private:
  char* _msg;
};


static RawInstance* Eval(Dart_Handle lib, const char* expr) {
  Dart_Handle result = Dart_EvaluateExpr(lib, NewString(expr));
  EXPECT_VALID(result);
  Isolate* isolate = Isolate::Current();
  const Instance& instance = Api::UnwrapInstanceHandle(isolate, result);
  return instance.raw();
}


TEST_CASE(Service_DebugBreakpoints) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "main() {\n"   // We set breakpoint here.
      "}";

  Isolate* isolate = Isolate::Current();
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));

  Instance& service_msg = Instance::Handle();

  // Add a breakpoint.
  const String& url = String::Handle(String::New(TestCase::url()));
  isolate->debugger()->SetBreakpointAtLine(url, 3);

  // Get the breakpoint list.
  service_msg = Eval(lib, "[port, ['debug', 'breakpoints'], [], []]");
  Service::HandleServiceMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"BreakpointList\",\"breakpoints\":[{"
          "\"type\":\"Breakpoint\",\"id\":1,\"enabled\":true,"
          "\"resolved\":false,"
          "\"location\":{\"type\":\"Location\",\"libId\":12,"
                        "\"script\":\"dart:test-lib\",\"tokenPos\":5}}]}",
      handler.msg());

  // Individual breakpoint.
  service_msg = Eval(lib, "[port, ['debug', 'breakpoints', '1'], [], []]");
  Service::HandleServiceMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"Breakpoint\",\"id\":1,\"enabled\":true,"
       "\"resolved\":false,"
       "\"location\":{\"type\":\"Location\",\"libId\":12,"
                     "\"script\":\"dart:test-lib\",\"tokenPos\":5}}",
      handler.msg());

  // Missing sub-command.
  service_msg = Eval(lib, "[port, ['debug'], [], []]");
  Service::HandleServiceMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"Error\","
       "\"text\":\"Must specify a subcommand\","
       "\"message\":{\"arguments\":[\"debug\"],\"option_keys\":[],"
                    "\"option_values\":[]}}",
      handler.msg());

  // Unrecognized breakpoint.
  service_msg = Eval(lib, "[port, ['debug', 'breakpoints', '1111'], [], []]");
  Service::HandleServiceMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("{\"type\":\"Error\","
                "\"text\":\"Unrecognized breakpoint id 1111\","
                "\"message\":{"
                    "\"arguments\":[\"debug\",\"breakpoints\",\"1111\"],"
                    "\"option_keys\":[],\"option_values\":[]}}",
               handler.msg());

  // Command too long.
  service_msg =
      Eval(lib, "[port, ['debug', 'breakpoints', '1111', 'green'], [], []]");
  Service::HandleServiceMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("{\"type\":\"Error\",\"text\":\"Command too long\","
                "\"message\":{\"arguments\":[\"debug\",\"breakpoints\","
                                            "\"1111\",\"green\"],"
                             "\"option_keys\":[],\"option_values\":[]}}",
               handler.msg());

  // Unrecognized subcommand.
  service_msg = Eval(lib, "[port, ['debug', 'nosferatu'], [], []]");
  Service::HandleServiceMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("{\"type\":\"Error\","
                "\"text\":\"Unrecognized subcommand 'nosferatu'\","
                "\"message\":{\"arguments\":[\"debug\",\"nosferatu\"],"
                             "\"option_keys\":[],\"option_values\":[]}}",
               handler.msg());
}

}  // namespace dart
