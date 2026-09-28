// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <memory>

#include "platform/globals.h"

#include "include/dart_tools_api.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/debugger_api_impl_test.h"
#include "vm/globals.h"
#include "vm/heap/safepoint.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/os.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/resolver.h"
#include "vm/service.h"
#include "vm/unit_test.h"

namespace dart {

// This flag is used in the Service_Flags test below.
DEFINE_FLAG(bool, service_testing_flag, false, "Comment");

#ifndef PRODUCT

class ServiceTestMessageHandler : public MessageHandler {
 public:
  ServiceTestMessageHandler() : _msg(nullptr) {}

  ~ServiceTestMessageHandler() {
    PortMap::ClosePorts(this);
    free(_msg);
  }

  MessageStatus HandleMessage(std::unique_ptr<Message> message) {
    if (_msg != nullptr) {
      free(_msg);
      _msg = nullptr;
    }

    // Parse the message.
    Object& response_obj = Object::Handle();
    if (message->IsRaw()) {
      response_obj = message->raw_obj();
    } else {
      Thread* thread = Thread::Current();
      response_obj = ReadMessage(thread, message.get());
    }
    if (response_obj.IsString()) {
      String& response = String::Handle();
      response ^= response_obj.ptr();
      _msg = Utils::StrDup(response.ToCString());
    } else {
      ASSERT(response_obj.IsArray());
      Array& response_array = Array::Handle();
      response_array ^= response_obj.ptr();
      ASSERT(response_array.Length() == 1);
      ExternalTypedData& response = ExternalTypedData::Handle();
      response ^= response_array.At(0);
      _msg = Utils::StrDup(reinterpret_cast<char*>(response.DataAddr(0)));
    }

    return kOK;
  }

  const char* msg() const { return _msg; }

  virtual Isolate* isolate() const { return Isolate::Current(); }

 private:
  char* _msg;
};

static ArrayPtr Eval(Dart_Handle lib, const char* expr) {
  const String& dummy_isolate_id = String::Handle(String::New("isolateId"));
  Dart_Handle expr_val;
  {
    TransitionVMToNative transition(Thread::Current());
    expr_val = Dart_EvaluateStaticExpr(lib, NewString(expr));
    EXPECT_VALID(expr_val);
  }
  Zone* zone = Thread::Current()->zone();
  const GrowableObjectArray& value =
      Api::UnwrapGrowableObjectArrayHandle(zone, expr_val);
  const Array& result = Array::Handle(Array::MakeFixedLength(value));
  GrowableObjectArray& growable = GrowableObjectArray::Handle();
  growable ^= result.At(5);
  // Append dummy isolate id to parameter values.
  growable.Add(dummy_isolate_id);
  Array& array = Array::Handle(Array::MakeFixedLength(growable));
  result.SetAt(5, array);
  growable ^= result.At(6);
  // Append dummy isolate id to parameter values.
  growable.Add(dummy_isolate_id);
  array = Array::MakeFixedLength(growable);
  result.SetAt(6, array);
  return result.ptr();
}

static ArrayPtr EvalF(Dart_Handle lib, const char* fmt, ...) {
  va_list measure_args;
  va_start(measure_args, fmt);
  intptr_t len = Utils::VSNPrint(nullptr, 0, fmt, measure_args);
  va_end(measure_args);

  char* buffer = Thread::Current()->zone()->Alloc<char>(len + 1);
  va_list print_args;
  va_start(print_args, fmt);
  Utils::VSNPrint(buffer, (len + 1), fmt, print_args);
  va_end(print_args);

  return Eval(lib, buffer);
}

static FunctionPtr GetFunction(const Class& cls, const char* name) {
  const Function& result = Function::Handle(Resolver::ResolveDynamicFunction(
      Thread::Current()->zone(), cls, String::Handle(String::New(name))));
  EXPECT(!result.IsNull());
  return result.ptr();
}

static ClassPtr GetClass(const Library& lib, const char* name) {
  const Class& cls = Class::Handle(
      lib.LookupClass(String::Handle(Symbols::New(Thread::Current(), name))));
  EXPECT(!cls.IsNull());  // No ambiguity error expected.
  return cls.ptr();
}

static void HandleIsolateMessage(Isolate* isolate, const Array& msg) {
  Service::HandleIsolateMessage(isolate, msg);
}

static void HandleRootMessage(const Array& message) {
  Service::HandleRootMessage(message);
}

ISOLATE_UNIT_TEST_CASE(Service_IsolateStickyError) {
  const char* kScript = "main() => throw 'HI THERE STICKY';\n";

  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle result;
  {
    TransitionVMToNative transition(thread);
    Dart_Handle lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT(Dart_IsUnhandledExceptionError(result));
    EXPECT(!Dart_HasStickyError());
  }
  EXPECT(Thread::Current()->sticky_error() == Error::null());

  {
    JSONStream js;
    js.set_id_zone(isolate->EnsureDefaultServiceIdZone());
    isolate->PrintJSON(&js, false);
    // No error property and no PauseExit state.
    EXPECT_NOTSUBSTRING("\"error\":", js.ToCString());
    EXPECT_NOTSUBSTRING("HI THERE STICKY", js.ToCString());
    EXPECT_NOTSUBSTRING("PauseExit", js.ToCString());
  }

  {
    // Set the sticky error.
    TransitionVMToNative transition(thread);
    Dart_SetStickyError(result);
    Dart_SetPausedOnExit(true);
    EXPECT(Dart_HasStickyError());
  }

  {
    JSONStream js;
    js.set_id_zone(isolate->EnsureDefaultServiceIdZone());
    isolate->PrintJSON(&js, false);
    // Error and PauseExit set.
    EXPECT_SUBSTRING("\"error\":", js.ToCString());
    EXPECT_SUBSTRING("HI THERE STICKY", js.ToCString());
    EXPECT_SUBSTRING("PauseExit", js.ToCString());
  }
}

ISOLATE_UNIT_TEST_CASE(Service_RingServiceIdZonePolicies) {
  Zone* zone = thread->zone();

  const String& test_a = String::Handle(zone, String::New("a"));
  const String& test_b = String::Handle(zone, String::New("b"));
  const String& test_c = String::Handle(zone, String::New("c"));
  const String& test_d = String::Handle(zone, String::New("d"));

  const intptr_t kDefaultIdZoneId = 0;
  const int32_t kTestIdZoneCapacity = 32;

  // Always allocate a new id.
  RingServiceIdZone always_allocate_zone(
      kDefaultIdZoneId, ObjectIdRing::kAllocateId, kTestIdZoneCapacity);
  EXPECT_STREQ("objects/0/0", always_allocate_zone.GetServiceId(test_a));
  EXPECT_STREQ("objects/1/0", always_allocate_zone.GetServiceId(test_a));
  EXPECT_STREQ("objects/2/0", always_allocate_zone.GetServiceId(test_a));
  EXPECT_STREQ("objects/3/0", always_allocate_zone.GetServiceId(test_b));
  EXPECT_STREQ("objects/4/0", always_allocate_zone.GetServiceId(test_c));

  // Reuse an existing id or allocate a new id.
  RingServiceIdZone reuse_existing_zone(
      kDefaultIdZoneId, ObjectIdRing::kReuseId, kTestIdZoneCapacity);
  EXPECT_STREQ("objects/0/0", reuse_existing_zone.GetServiceId(test_a));
  EXPECT_STREQ("objects/0/0", reuse_existing_zone.GetServiceId(test_a));
  EXPECT_STREQ("objects/1/0", reuse_existing_zone.GetServiceId(test_b));
  EXPECT_STREQ("objects/1/0", reuse_existing_zone.GetServiceId(test_b));
  EXPECT_STREQ("objects/2/0", reuse_existing_zone.GetServiceId(test_c));
  EXPECT_STREQ("objects/2/0", reuse_existing_zone.GetServiceId(test_c));
  EXPECT_STREQ("objects/3/0", reuse_existing_zone.GetServiceId(test_d));
  EXPECT_STREQ("objects/3/0", reuse_existing_zone.GetServiceId(test_d));
}

ISOLATE_UNIT_TEST_CASE(Service_Code) {
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

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  Library& vmlib = Library::Handle();
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    EXPECT(!Dart_IsNull(lib));
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }
  vmlib ^= Api::UnwrapHandle(lib);
  EXPECT(!vmlib.IsNull());
  const Class& class_a = Class::Handle(GetClass(vmlib, "A"));
  EXPECT(!class_a.IsNull());
  const Function& function_c = Function::Handle(GetFunction(class_a, "c"));
  EXPECT(!function_c.IsNull());
  const Code& code_c = Code::Handle(function_c.CurrentCode());
  EXPECT(!code_c.IsNull());
  // Use the entry of the code object as it's reference.
  uword entry = code_c.PayloadStart();
  int64_t compile_timestamp = code_c.compile_timestamp();
  EXPECT_GT(code_c.Size(), 16u);
  uword last = entry + code_c.Size();

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  // Request an invalid code object.
  service_msg =
      Eval(lib, "[0, port, '0', 'getObject', false, ['objectId'], ['code/0']]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"error\"", handler.msg());

  // The following test checks that a code object can be found only
  // at compile_timestamp()-code.EntryPoint().
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['code/%" Px64 "-%" Px "']]",
                      compile_timestamp, entry);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"type\":\"Code\"", handler.msg());
  {
    // Only perform a partial match.
    const intptr_t kBufferSize = 512;
    char buffer[kBufferSize];
    Utils::SNPrint(buffer, kBufferSize - 1,
                   "\"fixedId\":true,\"id\":\"code\\/%" Px64 "-%" Px "\",",
                   compile_timestamp, entry);
    EXPECT_SUBSTRING(buffer, handler.msg());
  }

  // Request code object at compile_timestamp-code.EntryPoint() + 16
  // Expect this to fail because the address is not the entry point.
  uintptr_t address = entry + 16;
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['code/%" Px64 "-%" Px "']]",
                      compile_timestamp, address);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"error\"", handler.msg());

  // Request code object at (compile_timestamp - 1)-code.EntryPoint()
  // Expect this to fail because the timestamp is wrong.
  address = entry;
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['code/%" Px64 "-%" Px "']]",
                      compile_timestamp - 1, address);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"error\"", handler.msg());

  // Request native code at address. Expect the null code object back.
  address = last;
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['code/native-%" Px "']]",
                      address);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  // TODO(turnidge): It is pretty broken to return an Instance here.  Fix.
  EXPECT_SUBSTRING("\"kind\":\"Null\"", handler.msg());

  // Request malformed native code.
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, ['objectId'], "
                      "['code/native%" Px "']]",
                      address);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"error\"", handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_PcDescriptors) {
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

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  Library& vmlib = Library::Handle();
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    EXPECT(!Dart_IsNull(lib));
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }
  vmlib ^= Api::UnwrapHandle(lib);
  EXPECT(!vmlib.IsNull());
  const Class& class_a = Class::Handle(GetClass(vmlib, "A"));
  EXPECT(!class_a.IsNull());
  const Function& function_c = Function::Handle(GetFunction(class_a, "c"));
  EXPECT(!function_c.IsNull());
  const Code& code_c = Code::Handle(function_c.CurrentCode());
  EXPECT(!code_c.IsNull());

  const PcDescriptors& descriptors =
      PcDescriptors::Handle(code_c.pc_descriptors());
  EXPECT(!descriptors.IsNull());
  ServiceIdZone& default_id_zone = isolate->EnsureDefaultServiceIdZone();
  const char* id = default_id_zone.GetServiceId(descriptors);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  // Fetch object.
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['%s']]",
                      id);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  // Check type.
  EXPECT_SUBSTRING("\"type\":\"Object\"", handler.msg());
  EXPECT_SUBSTRING("\"_vmType\":\"PcDescriptors\"", handler.msg());
  // Check for members array.
  EXPECT_SUBSTRING("\"members\":[", handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_LocalVarDescriptors) {
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

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  Library& vmlib = Library::Handle();
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    EXPECT(!Dart_IsNull(lib));
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }
  vmlib ^= Api::UnwrapHandle(lib);
  EXPECT(!vmlib.IsNull());
  const Class& class_a = Class::Handle(GetClass(vmlib, "A"));
  EXPECT(!class_a.IsNull());
  const Function& function_c = Function::Handle(GetFunction(class_a, "c"));
  EXPECT(!function_c.IsNull());
  LocalVarDescriptors& descriptors = LocalVarDescriptors::Handle();
  if (function_c.IsInterpreted()) {
#if defined(DART_DYNAMIC_MODULES)
    const Bytecode& bytecode_c = Bytecode::Handle(function_c.GetBytecode());
    EXPECT(!bytecode_c.IsNull());
    descriptors = bytecode_c.var_descriptors();
#else
    UNREACHABLE();
#endif
  } else {
    const Code& code_c = Code::Handle(function_c.CurrentCode());
    EXPECT(!code_c.IsNull());
    descriptors = code_c.GetLocalVarDescriptors();
  }
  EXPECT(!descriptors.IsNull());
  AbstractType& static_type = AbstractType::Handle();
  for (intptr_t i = 0; i < descriptors.Length(); i++) {
    static_type = descriptors.GetStaticType(i);
    EXPECT(!static_type.IsNull());
  }
  // Generate an ID for this object.
  ServiceIdZone& default_id_zone = isolate->EnsureDefaultServiceIdZone();
  const char* id = default_id_zone.GetServiceId(descriptors);

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  // Fetch object.
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['%s']]",
                      id);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  // Check type.
  EXPECT_SUBSTRING("\"type\":\"Object\"", handler.msg());
  EXPECT_SUBSTRING("\"_vmType\":\"LocalVarDescriptors\"", handler.msg());
  // Check for members array.
  EXPECT_SUBSTRING("\"members\":[", handler.msg());
}

static void WeakHandleFinalizer(void* isolate_callback_data, void* peer) {}

ISOLATE_UNIT_TEST_CASE(Service_PersistentHandles) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "class A {\n"
      "  var a;\n"
      "}\n"
      "var global = new A();\n"
      "main() {\n"
      "  return global;\n"
      "}";

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);

  Dart_Handle lib;
  Dart_PersistentHandle persistent_handle;
  Dart_WeakPersistentHandle weak_persistent_handle;
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);

    // Create a persistent handle to global.
    persistent_handle = Dart_NewPersistentHandle(result);

    // Create a weak persistent handle to global.
    weak_persistent_handle = Dart_NewWeakPersistentHandle(
        result, reinterpret_cast<void*>(0xdeadbeef), 128, WeakHandleFinalizer);
  }

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  // Get persistent handles.
  service_msg =
      Eval(lib, "[0, port, '0', '_getPersistentHandles', false, [], []]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  // Look for a heart beat.
  EXPECT_SUBSTRING("\"type\":\"_PersistentHandles\"", handler.msg());
  EXPECT_SUBSTRING("\"peer\":\"0xdeadbeef\"", handler.msg());
  EXPECT_SUBSTRING("\"name\":\"A\"", handler.msg());
  EXPECT_SUBSTRING("\"externalSize\":\"128\"", handler.msg());

  // Delete persistent handles.
  {
    TransitionVMToNative transition(thread);
    Dart_DeletePersistentHandle(persistent_handle);
    Dart_DeleteWeakPersistentHandle(weak_persistent_handle);
  }

  // Get persistent handles (again).
  service_msg =
      Eval(lib, "[0, port, '0', '_getPersistentHandles', false, [], []]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"type\":\"_PersistentHandles\"", handler.msg());
  // Verify that old persistent handles are not present.
  EXPECT_NOTSUBSTRING("\"peer\":\"0xdeadbeef\"", handler.msg());
  EXPECT_NOTSUBSTRING("\"name\":\"A\"", handler.msg());
  EXPECT_NOTSUBSTRING("\"externalSize\":\"128\"", handler.msg());
}

static bool alpha_callback(const char* name,
                           const char** option_keys,
                           const char** option_values,
                           intptr_t num_options,
                           void* user_data,
                           const char** result) {
  *result = Utils::StrDup("alpha");
  return true;
}

static bool beta_callback(const char* name,
                          const char** option_keys,
                          const char** option_values,
                          intptr_t num_options,
                          void* user_data,
                          const char** result) {
  *result = Utils::StrDup("beta");
  return false;
}

ISOLATE_UNIT_TEST_CASE(Service_EmbedderRootHandler) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "var x = 7;\n"
      "main() {\n"
      "  x = x * x;\n"
      "  x = (x / 13).floor();\n"
      "}";

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);

    Dart_RegisterRootServiceRequestCallback("alpha", alpha_callback, nullptr);
    Dart_RegisterRootServiceRequestCallback("beta", beta_callback, nullptr);

    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();
  service_msg = Eval(lib, "[0, port, '\"', 'alpha', false, [], []]");
  HandleRootMessage(service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_STREQ("{\"jsonrpc\":\"2.0\", \"result\":alpha,\"id\":\"\\\"\"}",
               handler.msg());
  service_msg = Eval(lib, "[0, port, 1, 'beta', false, [], []]");
  HandleRootMessage(service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_STREQ("{\"jsonrpc\":\"2.0\", \"error\":beta,\"id\":1}", handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_EmbedderIsolateHandler) {
  const char* kScript =
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "var x = 7;\n"
      "main() {\n"
      "  x = x * x;\n"
      "  x = (x / 13).floor();\n"
      "}";

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);

    Dart_RegisterIsolateServiceRequestCallback("alpha", alpha_callback,
                                               nullptr);
    Dart_RegisterIsolateServiceRequestCallback("beta", beta_callback, nullptr);

    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Isolate* isolate = thread->isolate();
  Array& service_msg = Array::Handle();
  service_msg = Eval(lib, "[0, port, '0', 'alpha', false, [], []]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_STREQ("{\"jsonrpc\":\"2.0\", \"result\":alpha,\"id\":\"0\"}",
               handler.msg());
  service_msg = Eval(lib, "[0, port, '0', 'beta', false, [], []]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_STREQ("{\"jsonrpc\":\"2.0\", \"error\":beta,\"id\":\"0\"}",
               handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_ReadNativeMemory_ValidAddress) {
  const char* kScript =
      "@pragma('vm:entry-point', 'set')\n"
      "var port;\n"
      "main() {}\n";

  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  uint8_t buffer[8] = {0x01, 0xAB, 0x0F, 0xFF, 0xDE, 0xAD, 0xBE, 0xEF};
  uintptr_t address = reinterpret_cast<uintptr_t>(buffer);

  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  // send _readNativeMemory RPC with valid address
  service_msg = EvalF(lib,
                      "[0, port, '0', '_readNativeMemory', false, "
                      "['address', 'size'], ['%" Px "', '8']]",
                      address);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());

  EXPECT_SUBSTRING("\"type\":\"NativeMemory\"", handler.msg());
  EXPECT_SUBSTRING("\"bytes\":\"01ab0fffdeadbeef\"", handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_ReadNativeMemory_LargeRead) {
  const char* kScript =
      "@pragma('vm:entry-point', 'set')\n"
      "var port;\n"
      "main() {}\n";

  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  // allocate 1MB
  const intptr_t kOneMB = 1 * MB;
  CAllocUniquePtr<uint8_t> large_buffer(
      reinterpret_cast<uint8_t*>(malloc(kOneMB)));
  for (intptr_t i = 0; i < kOneMB; i++) {
    large_buffer.get()[i] = static_cast<uint8_t>(i % 256);
  }

  uintptr_t address = reinterpret_cast<uintptr_t>(large_buffer.get());

  service_msg = EvalF(lib,
                      "[0, port, '0', '_readNativeMemory', false, "
                      "['address', 'size'], ['%" Px "', '%" Pd "']]",
                      address, kOneMB);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());

  EXPECT_SUBSTRING("\"type\":\"NativeMemory\"", handler.msg());
  EXPECT_SUBSTRING("\"bytes\":\"000102030405", handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_ReadNativeMemory_InvalidAddress) {
  const char* kScript =
      "@pragma('vm:entry-point', 'set')\n"
      "var port;\n"
      "main() {}\n";

  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  service_msg = EvalF(lib,
                      "[0, port, '0', '_readNativeMemory', false, "
                      "['address', 'size'], ['1000', '8']]");

  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());

  EXPECT_SUBSTRING("\"code\":1004", handler.msg());
#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
  EXPECT_SUBSTRING("Input\\/output error", handler.msg());
#elif defined(DART_HOST_OS_WINDOWS)
  EXPECT_SUBSTRING("error 299", handler.msg());
#elif defined(DART_HOST_OS_MACOS)
  EXPECT_SUBSTRING("invalid address", handler.msg());
#endif
}

ISOLATE_UNIT_TEST_CASE(Service_ReadNativeMemory_NullAddress) {
  const char* kScript =
      "@pragma('vm:entry-point', 'set')\n"
      "var port;\n"
      "main() {}\n";

  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();

  service_msg = EvalF(lib,
                      "[0, port, '0', '_readNativeMemory', false, "
                      "['address', 'size'], ['0', '8']]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());

  EXPECT_SUBSTRING("\"error\"", handler.msg());
  EXPECT_SUBSTRING("null pointer", handler.msg());
}

ISOLATE_UNIT_TEST_CASE(Service_ClassFfiLayout) {
  const char* kScript =
      "@pragma('vm:entry-point', 'set')\n"
      "import 'dart:ffi';\n"
      "import 'dart:typed_data';\n"
      "var port;\n"
      "final class Inner extends Struct {\n"
      "  @Int32() external int a;\n"
      "  @Int32() external int b;\n"
      "}\n"
      "final class MyUnion extends Union {\n"
      "  @Int32() external int u1;\n"
      "  @Float() external double u2;\n"
      "  external Inner u3;\n"
      "}\n"
      "final class MyStruct extends Struct {\n"
      "  @Int32() external int x;\n"
      "  @Float() external double y;\n"
      "  external Inner inner;\n"
      "  @Array(3) external Array<Uint8> tail;\n"
      "  @Array(2) external Array<Inner> items;\n"
      "  external MyUnion u;\n"
      "}\n"
      "MyStruct? instance;\n"
      "MyStruct? instanceAtOffset;\n"
      "String layoutErrors = 'checkLayout() did not run';\n"
      "String checkLayout() {\n"
      "  final backing = Uint8List(8 + sizeOf<MyStruct>());\n"
      "  final s = Struct.create<MyStruct>(backing, 8);\n"
      "  final bytes = ByteData.view(backing.buffer, 8);\n"
      "  s.x = 0x11223344;\n"
      "  s.y = 2.5;\n"
      "  s.inner.a = 0x55667788;\n"
      "  s.inner.b = 0x1a2b3c4d;\n"
      "  s.tail[0] = 0xa1;\n"
      "  s.tail[1] = 0xa2;\n"
      "  s.tail[2] = 0xa3;\n"
      "  s.items[0].a = 0x0a0b0c0d;\n"
      "  s.items[1].b = 0x7e6d5c4b;\n"
      "  s.u.u3.a = 0x21324354;\n"
      "  s.u.u3.b = 0x65768798;\n"
      "  var errors = '';\n"
      "  void check(String what, num expected, num actual) {\n"
      "    if (expected != actual) {\n"
      "      errors += '$what: expected $expected but got $actual. ';\n"
      "    }\n"
      "  }\n"
      "  check('size', 44, sizeOf<MyStruct>());\n"
      "  check('x@0', 0x11223344, bytes.getInt32(0, Endian.host));\n"
      "  check('y@4', 2.5, bytes.getFloat32(4, Endian.host));\n"
      "  check('inner.a@8', 0x55667788, bytes.getInt32(8, Endian.host));\n"
      "  check('inner.b@12', 0x1a2b3c4d, bytes.getInt32(12, Endian.host));\n"
      "  check('tail[0]@16', 0xa1, bytes.getUint8(16));\n"
      "  check('tail[1]@17', 0xa2, bytes.getUint8(17));\n"
      "  check('tail[2]@18', 0xa3, bytes.getUint8(18));\n"
      "  check('items[0].a@20', 0x0a0b0c0d, bytes.getInt32(20, Endian.host));\n"
      "  check('items[1].b@32', 0x7e6d5c4b, bytes.getInt32(32, Endian.host));\n"
      "  check('u.u3.a@36', 0x21324354, bytes.getInt32(36, Endian.host));\n"
      "  check('u.u3.b@40', 0x65768798, bytes.getInt32(40, Endian.host));\n"
      "  check('u.u1 aliases u.u3.a', 0x21324354, s.u.u1);\n"
      "  return errors;\n"
      "}\n"
      "main() {\n"
      "  instance = Struct.create<MyStruct>();\n"
      "  final backing = Uint8List(8 + sizeOf<MyStruct>());\n"
      "  instanceAtOffset = Struct.create<MyStruct>(backing, 8);\n"
      "  layoutErrors = checkLayout();\n"
      "}";

  SetFlagScope<bool> sfs(&FLAG_verify_entry_points, false);
  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);
    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  Library& vmlib = Library::Handle();
  vmlib ^= Api::UnwrapHandle(lib);
  const Class& cls = Class::Handle(GetClass(vmlib, "MyStruct"));
  EXPECT(!cls.IsNull());

  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }
  Array& service_msg = Array::Handle();
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['classes/%" Pd "']]",
                      cls.id());
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"type\":\"Class\"", handler.msg());
  EXPECT_SUBSTRING(
      "\"ffiLayout\":{\"size\":44,\"kind\":\"struct\",\"fields\":[",
      handler.msg());
  EXPECT_SUBSTRING(
      "\"name\":\"x\",\"nativeType\":\"int32\",\"offset\":0,\"size\":4",
      handler.msg());
  EXPECT_SUBSTRING(
      "\"name\":\"y\",\"nativeType\":\"float\",\"offset\":4,\"size\":4",
      handler.msg());
  // A nested struct carries its own layout.
  EXPECT_SUBSTRING(
      "\"name\":\"inner\",\"nativeType\":\"Inner\",\"offset\":8,\"size\":8,"
      "\"kind\":\"struct\",\"fields\":["
      "{\"name\":\"a\",\"nativeType\":\"int32\",\"offset\":8,\"size\":4},"
      "{\"name\":\"b\",\"nativeType\":\"int32\",\"offset\":12,\"size\":4}]",
      handler.msg());
  // An array of a primitive has no nested layout.
  EXPECT_SUBSTRING(
      "\"name\":\"tail\",\"nativeType\":\"Array\",\"offset\":16,\"size\":3,"
      "\"length\":3,\"arrayElementType\":\"uint8\"}",
      handler.msg());
  // An array of a compound carries the layout of its first element.
  EXPECT_SUBSTRING(
      "\"name\":\"items\",\"nativeType\":\"Array\",\"offset\":20,\"size\":16,"
      "\"length\":2,\"arrayElementType\":\"Inner\",\"kind\":\"struct\","
      "\"fields\":["
      "{\"name\":\"a\",\"nativeType\":\"int32\",\"offset\":20,\"size\":4},"
      "{\"name\":\"b\",\"nativeType\":\"int32\",\"offset\":24,\"size\":4}]",
      handler.msg());
  // All members of a nested union start at the union's own offset.
  EXPECT_SUBSTRING(
      "\"name\":\"u\",\"nativeType\":\"MyUnion\",\"offset\":36,\"size\":8,"
      "\"kind\":\"union\",\"fields\":["
      "{\"name\":\"u1\",\"nativeType\":\"int32\",\"offset\":36,\"size\":4},"
      "{\"name\":\"u2\",\"nativeType\":\"float\",\"offset\":36,\"size\":4},"
      "{\"name\":\"u3\",\"nativeType\":\"Inner\",\"offset\":36,\"size\":8,"
      "\"kind\":\"struct\",\"fields\":["
      "{\"name\":\"a\",\"nativeType\":\"int32\",\"offset\":36,\"size\":4},"
      "{\"name\":\"b\",\"nativeType\":\"int32\",\"offset\":40,\"size\":4}]}]",
      handler.msg());

  {
    TransitionVMToNative transition(thread);
    Dart_Handle errors = Dart_GetField(lib, NewString("layoutErrors"));
    EXPECT_VALID(errors);
    const char* errors_cstr = nullptr;
    EXPECT_VALID(Dart_StringToCString(errors, &errors_cstr));
    EXPECT_STREQ("", errors_cstr);
  }

  // A union is a compound in its own right, all of its members are at offset 0.
  const Class& union_cls = Class::Handle(GetClass(vmlib, "MyUnion"));
  EXPECT(!union_cls.IsNull());
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['classes/%" Pd "']]",
                      union_cls.id());
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"type\":\"Class\"", handler.msg());
  EXPECT_SUBSTRING(
      "\"ffiLayout\":{\"size\":8,\"kind\":\"union\",\"fields\":["
      "{\"name\":\"u1\",\"nativeType\":\"int32\",\"offset\":0,\"size\":4},"
      "{\"name\":\"u2\",\"nativeType\":\"float\",\"offset\":0,\"size\":4},"
      "{\"name\":\"u3\",\"nativeType\":\"Inner\",\"offset\":0,\"size\":8,"
      "\"kind\":\"struct\",\"fields\":["
      "{\"name\":\"a\",\"nativeType\":\"int32\",\"offset\":0,\"size\":4},"
      "{\"name\":\"b\",\"nativeType\":\"int32\",\"offset\":4,\"size\":4}]}]}",
      handler.msg());

  Dart_Handle instance_handle;
  {
    TransitionVMToNative transition(thread);
    instance_handle = Dart_GetField(lib, NewString("instanceAtOffset"));
    EXPECT_VALID(instance_handle);
  }
  Instance& instance_at_offset = Instance::Handle();
  instance_at_offset ^= Api::UnwrapHandle(instance_handle);
  EXPECT(!instance_at_offset.IsNull());
  ServiceIdZone& id_zone = isolate->EnsureDefaultServiceIdZone();
  const char* instance_id = id_zone.GetServiceId(instance_at_offset);
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['%s']]",
                      instance_id);
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"type\":\"Instance\"", handler.msg());
  EXPECT_SUBSTRING("\"name\":\"_offsetInBytes\"", handler.msg());
  EXPECT_SUBSTRING("\"valueAsString\":\"8\"", handler.msg());

  // Classes that are not FFI compounds do not get an `ffiLayout` at all.
  const Class& object_cls =
      Class::Handle(isolate->group()->object_store()->object_class());
  service_msg = EvalF(lib,
                      "[0, port, '0', 'getObject', false, "
                      "['objectId'], ['classes/%" Pd "']]",
                      object_cls.id());
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  EXPECT_SUBSTRING("\"type\":\"Class\"", handler.msg());
  EXPECT(strstr(handler.msg(), "ffiLayout") == nullptr);
}

// TODO(zra): Remove when tests are ready to enable.
#if !defined(TARGET_ARCH_ARM64)

ISOLATE_UNIT_TEST_CASE(Service_Profile) {
  Dart_StartProfiling();
  const char* kScript =
      "@pragma('vm:entry-point', 'set')\n"
      "var port;\n"  // Set to our mock port by C++.
      "\n"
      "var x = 7;\n"
      "main() {\n"
      "  x = x * x;\n"
      "  x = (x / 13).floor();\n"
      "}";

  Isolate* isolate = thread->isolate();
  isolate->set_is_runnable(true);
  Dart_Handle lib;
  {
    TransitionVMToNative transition(thread);

    lib = TestCase::LoadTestScript(kScript, nullptr);
    EXPECT_VALID(lib);
    Dart_Handle result = Dart_Invoke(lib, NewString("main"), 0, nullptr);
    EXPECT_VALID(result);
  }

  // Build a mock message handler and wrap it in a dart port.
  ServiceTestMessageHandler handler;
  Dart_Port port_id = PortMap::CreatePort(&handler);
  Dart_Handle port = Api::NewHandle(thread, SendPort::New(port_id));
  {
    TransitionVMToNative transition(thread);
    EXPECT_VALID(port);
    EXPECT_VALID(Dart_SetField(lib, NewString("port"), port));
  }

  Array& service_msg = Array::Handle();
  service_msg = Eval(lib, "[0, port, '0', 'getCpuSamples', false, [], []]");
  HandleIsolateMessage(isolate, service_msg);
  EXPECT_EQ(MessageHandler::kOK, handler.HandleNextMessage());
  // Expect profile
  EXPECT_SUBSTRING("\"type\":\"CpuSamples\"", handler.msg());
}

#endif  // !defined(TARGET_ARCH_ARM64)

ISOLATE_UNIT_TEST_CASE(Service_ParseJSONArray) {
  {
    const auto& elements =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    EXPECT_EQ(-1, ParseJSONArray(thread, "", elements));
    EXPECT_EQ(-1, ParseJSONArray(thread, "[", elements));
  }

  {
    const auto& elements =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    EXPECT_EQ(0, ParseJSONArray(thread, "[]", elements));
    EXPECT_EQ(0, elements.Length());
  }

  {
    const auto& elements =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    EXPECT_EQ(0, ParseJSONArray(thread, "[a]", elements));
    EXPECT_EQ(1, elements.Length());
    auto& element = String::Handle();
    element ^= elements.At(0);
    EXPECT(element.Equals("a"));
  }

  {
    const auto& elements =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    EXPECT_EQ(0, ParseJSONArray(thread, "[abc, def]", elements));
    EXPECT_EQ(2, elements.Length());
    auto& element = String::Handle();
    element ^= elements.At(0);
    EXPECT(element.Equals("abc"));
    element ^= elements.At(1);
    EXPECT(element.Equals("def"));
  }

  {
    const auto& elements =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    EXPECT_EQ(0, ParseJSONArray(thread, "[abc, def, ghi]", elements));
    EXPECT_EQ(3, elements.Length());
    auto& element = String::Handle();
    element ^= elements.At(0);
    EXPECT(element.Equals("abc"));
    element ^= elements.At(1);
    EXPECT(element.Equals("def"));
    element ^= elements.At(2);
    EXPECT(element.Equals("ghi"));
  }

  {
    const auto& elements =
        GrowableObjectArray::Handle(GrowableObjectArray::New());
    EXPECT_EQ(0, ParseJSONArray(thread, "[abc, , ghi]", elements));
    EXPECT_EQ(3, elements.Length());
    auto& element = String::Handle();
    element ^= elements.At(0);
    EXPECT(element.Equals("abc"));
    element ^= elements.At(1);
    EXPECT(element.Equals(""));
    element ^= elements.At(2);
    EXPECT(element.Equals("ghi"));
  }
}

#endif  // !PRODUCT

}  // namespace dart
