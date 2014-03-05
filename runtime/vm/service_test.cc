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


static RawInstance* EvalF(Dart_Handle lib, const char* fmt, ...) {
  Isolate* isolate = Isolate::Current();

  va_list args;
  va_start(args, fmt);
  intptr_t len = OS::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = isolate->current_zone()->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, fmt);
  OS::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  return Eval(lib, buffer);
}


// Search for the formatted string in buff.
static void ExpectSubstringF(const char* buff, const char* fmt, ...) {
  Isolate* isolate = Isolate::Current();

  va_list args;
  va_start(args, fmt);
  intptr_t len = OS::VSNPrint(NULL, 0, fmt, args);
  va_end(args);

  char* buffer = isolate->current_zone()->Alloc<char>(len + 1);
  va_list args2;
  va_start(args2, fmt);
  OS::VSNPrint(buffer, (len + 1), fmt, args2);
  va_end(args2);

  EXPECT_SUBSTRING(buffer, buff);
}


static RawFunction* GetFunction(const Class& cls, const char* name) {
  const Function& result = Function::Handle(cls.LookupDynamicFunction(
      String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.raw();
}


static RawClass* GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.raw();
}


TEST_CASE(Service_Isolate) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "main() {\n"
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

  // Get the isolate summary.
  service_msg = Eval(lib, "[port, [], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();

  JSONReader reader(handler.msg());

  const int kBufferSize = 128;
  char buffer[kBufferSize];

  // Check that the response string is somewhat sane.

  // type
  EXPECT(reader.Seek("type"));
  EXPECT_EQ(reader.Type(), JSONReader::kString);
  reader.GetDecodedValueChars(buffer, kBufferSize);
  EXPECT_STREQ("Isolate", buffer);

  // id
  EXPECT(reader.Seek("id"));
  EXPECT_EQ(reader.Type(), JSONReader::kString);
  reader.GetDecodedValueChars(buffer, kBufferSize);
  EXPECT_SUBSTRING("isolates/", buffer);

  // heap
  EXPECT(reader.Seek("heap"));
  EXPECT_EQ(reader.Type(), JSONReader::kObject);

  // timers
  EXPECT(reader.Seek("timers"));
  EXPECT_EQ(reader.Type(), JSONReader::kArray);
}


TEST_CASE(Service_StackTrace) {
  // TODO(turnidge): Extend this test to cover a non-trivial stack trace.
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "main() {\n"
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

  // Get the stacktrace.
  service_msg = Eval(lib, "[port, ['stacktrace'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"StackTrace\",\"members\":[]}",
      handler.msg());

  // Malformed request.
  service_msg = Eval(lib, "[port, ['stacktrace', 'jamboree'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"Error\",\"text\":\"Command too long\","
      "\"message\":{\"arguments\":[\"stacktrace\",\"jamboree\"],"
      "\"option_keys\":[],\"option_values\":[]}}",
      handler.msg());
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
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"BreakpointList\",\"breakpoints\":[{"
          "\"type\":\"Breakpoint\",\"id\":1,\"enabled\":true,"
          "\"resolved\":false,"
          "\"location\":{\"type\":\"Location\","
                        "\"script\":\"dart:test-lib\",\"tokenPos\":5}}]}",
      handler.msg());

  // Individual breakpoint.
  service_msg = Eval(lib, "[port, ['debug', 'breakpoints', '1'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"Breakpoint\",\"id\":1,\"enabled\":true,"
       "\"resolved\":false,"
       "\"location\":{\"type\":\"Location\","
                     "\"script\":\"dart:test-lib\",\"tokenPos\":5}}",
      handler.msg());

  // Missing sub-command.
  service_msg = Eval(lib, "[port, ['debug'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
      "{\"type\":\"Error\","
       "\"text\":\"Must specify a subcommand\","
       "\"message\":{\"arguments\":[\"debug\"],\"option_keys\":[],"
                    "\"option_values\":[]}}",
      handler.msg());

  // Unrecognized breakpoint.
  service_msg = Eval(lib, "[port, ['debug', 'breakpoints', '1111'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
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
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("{\"type\":\"Error\",\"text\":\"Command too long\","
                "\"message\":{\"arguments\":[\"debug\",\"breakpoints\","
                                            "\"1111\",\"green\"],"
                             "\"option_keys\":[],\"option_values\":[]}}",
               handler.msg());

  // Unrecognized subcommand.
  service_msg = Eval(lib, "[port, ['debug', 'nosferatu'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("{\"type\":\"Error\","
                "\"text\":\"Unrecognized subcommand 'nosferatu'\","
                "\"message\":{\"arguments\":[\"debug\",\"nosferatu\"],"
                             "\"option_keys\":[],\"option_values\":[]}}",
               handler.msg());
}


TEST_CASE(Service_Classes) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "class A {\n"
      "  var a;\n"
      "  dynamic b() {}\n"
      "  dynamic c() {\n"
      "    var d = () { b(); };\n"
      "    return d;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var z = new A();\n"
      "  var x = z.c();\n"
      "  x();\n"
      "}";

  Isolate* isolate = Isolate::Current();
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  const Class& class_a = Class::Handle(GetClass(lib, "A"));
  EXPECT(!class_a.IsNull());
  intptr_t cid = class_a.id();

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(h_lib, NewString("port"), port));

  Instance& service_msg = Instance::Handle();

  // Request an invalid class id.
  service_msg = Eval(h_lib, "[port, ['classes', '999999'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
    "{\"type\":\"Error\",\"text\":\"999999 is not a valid class id.\","
    "\"message\":{\"arguments\":[\"classes\",\"999999\"],"
    "\"option_keys\":[],\"option_values\":[]}}", handler.msg());

  // Request the class A over the service.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "'], [], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();

  EXPECT_SUBSTRING("\"type\":\"Class\"", handler.msg());
  ExpectSubstringF(handler.msg(),
                   "\"id\":\"classes\\/%" Pd "\",\"name\":\"A\",", cid);

  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'functions', '0'],"
                              "[], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_SUBSTRING("\"type\":\"Function\"", handler.msg());
  ExpectSubstringF(handler.msg(),
                   "\"id\":\"classes\\/%" Pd "\\/functions\\/0\","
                   "\"name\":\"get:a\",", cid);

  // Request field 0 from class A.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'fields', '0'],"
                              "[], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_SUBSTRING("\"type\":\"Field\"", handler.msg());
  ExpectSubstringF(handler.msg(),
                   "\"id\":\"classes\\/%" Pd "\\/fields\\/0\","
                   "\"name\":\"a\",", cid);

  // Invalid sub command.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'huh', '0'],"
                              "[], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  ExpectSubstringF(handler.msg(),
    "{\"type\":\"Error\",\"text\":\"Invalid sub collection huh\",\"message\":"
    "{\"arguments\":[\"classes\",\"%" Pd "\",\"huh\",\"0\"],\"option_keys\":[],"
    "\"option_values\":[]}}", cid);

  // Invalid field request.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'fields', '9'],"
                              "[], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  ExpectSubstringF(handler.msg(),
    "{\"type\":\"Error\",\"text\":\"Field 9 not found\","
    "\"message\":{\"arguments\":[\"classes\",\"%" Pd "\",\"fields\",\"9\"],"
    "\"option_keys\":[],\"option_values\":[]}}", cid);

  // Invalid function request.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'functions', '9'],"
                              "[], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  ExpectSubstringF(handler.msg(),
    "{\"type\":\"Error\",\"text\":\"Function 9 not found\","
    "\"message\":{\"arguments\":[\"classes\",\"%" Pd "\",\"functions\",\"9\"],"
    "\"option_keys\":[],\"option_values\":[]}}", cid);


  // Invalid field subcommand.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'fields', '9', 'x']"
                             ",[], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  ExpectSubstringF(handler.msg(),
    "{\"type\":\"Error\",\"text\":\"Command too long\",\"message\":"
    "{\"arguments\":[\"classes\",\"%" Pd "\",\"fields\",\"9\",\"x\"],"
    "\"option_keys\":[],\"option_values\":[]}}", cid);

  // Invalid function request.
  service_msg = EvalF(h_lib, "[port, ['classes', '%" Pd "', 'functions', '9',"
                             "'x'], [], []]", cid);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  ExpectSubstringF(handler.msg(),
    "{\"type\":\"Error\",\"text\":\"Command too long\",\"message\":"
    "{\"arguments\":[\"classes\",\"%" Pd "\",\"functions\",\"9\",\"x\"],"
    "\"option_keys\":[],\"option_values\":[]}}", cid);
}


TEST_CASE(Service_Code) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "class A {\n"
      "  var a;\n"
      "  dynamic b() {}\n"
      "  dynamic c() {\n"
      "    var d = () { b(); };\n"
      "    return d;\n"
      "  }\n"
      "}\n"
      "main() {\n"
      "  var z = new A();\n"
      "  var x = z.c();\n"
      "  x();\n"
      "}";

  Isolate* isolate = Isolate::Current();
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);
  const Class& class_a = Class::Handle(GetClass(lib, "A"));
  EXPECT(!class_a.IsNull());
  const Function& function_c = Function::Handle(GetFunction(class_a, "c"));
  EXPECT(!function_c.IsNull());
  const Code& code_c = Code::Handle(function_c.CurrentCode());
  EXPECT(!code_c.IsNull());
  // Use the entry of the code object as it's reference.
  uword entry = code_c.EntryPoint();
  EXPECT_GT(code_c.Size(), 16);
  uword last = entry + code_c.Size();

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(h_lib, NewString("port"), port));

  Instance& service_msg = Instance::Handle();

  // Request an invalid code object.
  service_msg = Eval(h_lib, "[port, ['code', '0'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ(
    "{\"type\":\"Error\",\"text\":\"Could not find code at 0\",\"message\":"
    "{\"arguments\":[\"code\",\"0\"],"
    "\"option_keys\":[],\"option_values\":[]}}", handler.msg());

  // The following four tests check that a code object can be found
  // inside the range: [code.EntryPoint(), code.EntryPoint() + code.Size()).
  // Request code object at code.EntryPoint()
  // Expect this to succeed as it is inside [entry, entry + size).
  service_msg = EvalF(h_lib, "[port, ['code', '%" Px "'], [], []]", entry);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  {
    // Only perform a partial match.
    const intptr_t kBufferSize = 512;
    char buffer[kBufferSize];
    OS::SNPrint(buffer, kBufferSize-1,
                "{\"type\":\"Code\",\"id\":\"code\\/%" Px "\",", entry);
    EXPECT_SUBSTRING(buffer, handler.msg());
  }

  // Request code object at code.EntryPoint() + 16.
  // Expect this to succeed as it is inside [entry, entry + size).
  uintptr_t address = entry + 16;
  service_msg = EvalF(h_lib, "[port, ['code', '%" Px "'], [], []]", address);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  {
    // Only perform a partial match.
    const intptr_t kBufferSize = 512;
    char buffer[kBufferSize];
    OS::SNPrint(buffer, kBufferSize-1,
                "{\"type\":\"Code\",\"id\":\"code\\/%" Px "\",", entry);
    EXPECT_SUBSTRING(buffer, handler.msg());
  }

  // Request code object at code.EntryPoint() + code.Size() - 1.
  // Expect this to succeed as it is inside [entry, entry + size).
  address = last - 1;
  service_msg = EvalF(h_lib, "[port, ['code', '%" Px "'], [], []]", address);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  {
    // Only perform a partial match.
    const intptr_t kBufferSize = 512;
    char buffer[kBufferSize];
    OS::SNPrint(buffer, kBufferSize-1,
                "{\"type\":\"Code\",\"id\":\"code\\/%" Px "\",", entry);
    EXPECT_SUBSTRING(buffer, handler.msg());
  }

  // Request code object at code.EntryPoint() + code.Size(). Expect this
  // to fail as it's outside of [entry, entry + size).
  address = last;
  service_msg = EvalF(h_lib, "[port, ['code', '%" Px "'], [], []]", address);
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  {
    const intptr_t kBufferSize = 1024;
    char buffer[kBufferSize];
    OS::SNPrint(buffer, kBufferSize-1,
        "{\"type\":\"Error\",\"text\":\"Could not find code at %" Px "\","
        "\"message\":{\"arguments\":[\"code\",\"%" Px "\"],"
        "\"option_keys\":[],\"option_values\":[]}}", address, address);
    EXPECT_STREQ(buffer, handler.msg());
  }
}


TEST_CASE(Service_Cpu) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "main() {\n"
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
  service_msg = Eval(lib, "[port, ['cpu'], [], []]");

  Service::HandleRootMessage(service_msg);
  handler.HandleNextMessage();
  EXPECT_SUBSTRING("\"type\":\"CPU\"", handler.msg());
}


TEST_CASE(Service_Coverage) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "var x = 7;\n"
      "main() {\n"
      "  x = x * x;\n"
      "  x = x / 13;\n"
      "}";

  Isolate* isolate = Isolate::Current();
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(h_lib, NewString("port"), port));

  Instance& service_msg = Instance::Handle();
  service_msg = Eval(h_lib, "[port, ['coverage'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_SUBSTRING(
      "{\"source\":\"dart:test-lib\",\"script\":{"
      "\"type\":\"@Script\",\"id\":\"scripts\\/dart%3Atest-lib\","
      "\"name\":\"dart:test-lib\",\"user_name\":\"dart:test-lib\","
      "\"kind\":\"script\"},\"hits\":"
      "[3,0,3,1,5,1,5,1,5,1,6,1,6,1]}", handler.msg());
}


TEST_CASE(Service_AllocationProfile) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "var x = 7;\n"
      "main() {\n"
      "  x = x * x;\n"
      "  x = x / 13;\n"
      "}";

  Isolate* isolate = Isolate::Current();
  Dart_Handle h_lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(h_lib);
  Library& lib = Library::Handle();
  lib ^= Api::UnwrapHandle(h_lib);
  EXPECT(!lib.IsNull());
  Dart_Handle result = Dart_Invoke(h_lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(h_lib, NewString("port"), port));

  Instance& service_msg = Instance::Handle();
  service_msg = Eval(h_lib, "[port, ['allocationprofile'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_SUBSTRING("\"type\":\"AllocationProfile\"", handler.msg());
}


static const char* alpha_callback(
    const char* name,
    const char** arguments,
    intptr_t num_arguments,
    const char** option_keys,
    const char** option_values,
    intptr_t num_options,
    void* user_data) {
  return strdup("alpha");
}


static const char* beta_callback(
    const char* name,
    const char** arguments,
    intptr_t num_arguments,
    const char** option_keys,
    const char** option_values,
    intptr_t num_options,
    void* user_data) {
  return strdup("beta");
}


TEST_CASE(Service_EmbedderRootHandler) {
  const char* kScript =
    "var port;\n"  // Set to our mock port by C++.
    "\n"
    "var x = 7;\n"
    "main() {\n"
    "  x = x * x;\n"
    "  x = x / 13;\n"
    "}";

  Dart_RegisterRootServiceRequestCallback("alpha", alpha_callback, NULL);
  Dart_RegisterRootServiceRequestCallback("beta", beta_callback, NULL);

  Isolate* isolate = Isolate::Current();
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));


  Instance& service_msg = Instance::Handle();
  service_msg = Eval(lib, "[port, ['alpha'], [], []]");
  Service::HandleRootMessage(service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("alpha", handler.msg());
  service_msg = Eval(lib, "[port, ['beta'], [], []]");
  Service::HandleRootMessage(service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("beta", handler.msg());
}

TEST_CASE(Service_EmbedderIsolateHandler) {
  const char* kScript =
    "var port;\n"  // Set to our mock port by C++.
    "\n"
    "var x = 7;\n"
    "main() {\n"
    "  x = x * x;\n"
    "  x = x / 13;\n"
    "}";

  Dart_RegisterIsolateServiceRequestCallback("alpha", alpha_callback, NULL);
  Dart_RegisterIsolateServiceRequestCallback("beta", beta_callback, NULL);

  Isolate* isolate = Isolate::Current();
  Dart_Handle lib = TestCase::LoadTestScript(kScript, NULL);
  EXPECT_VALID(lib);
  Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, NULL);
  EXPECT_VALID(result);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port =
      Api::NewHandle(isolate, DartLibraryCalls::NewSendPort(port_id));
  EXPECT_VALID(port);
  EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));

  Instance& service_msg = Instance::Handle();
  service_msg = Eval(lib, "[port, ['alpha'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("alpha", handler.msg());
  service_msg = Eval(lib, "[port, ['beta'], [], []]");
  Service::HandleIsolateMessage(isolate, service_msg);
  handler.HandleNextMessage();
  EXPECT_STREQ("beta", handler.msg());
}

}  // namespace dart
