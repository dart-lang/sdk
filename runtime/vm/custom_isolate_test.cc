// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "include/dart_api.h"

#include "vm/unit_test.h"

// Custom Isolate Test.
//
// This mid-size test uses the Dart Embedding Api to create a custom
// isolate abstraction.  Instead of having a dedicated thread for each
// isolate, as is the case normally, this implementation shares a
// single thread among the isolates using an event queue.

namespace dart {

#if defined(TARGET_ARCH_IA32)  // only ia32 can run execution tests.

static void native_echo(Dart_NativeArguments args);
static void CustomIsolateImpl_start(Dart_NativeArguments args);
static Dart_NativeFunction NativeLookup(Dart_Handle name, int argc);


static const char* kCustomIsolateScriptChars =
    "class GlobalsHack {\n"
    "  static ReceivePort _receivePort;\n"
    "}\n"
    "\n"
    "ReceivePort get receivePort() {\n"
    "  return GlobalsHack._receivePort;\n"
    "}\n"
    "\n"
    "echo(arg) native \"native_echo\";\n"
    "\n"
    "class CustomIsolateImpl implements CustomIsolate {\n"
    "  CustomIsolateImpl(String entry) : _entry = entry{\n"
    "    echo('Constructing isolate');\n"
    "  }\n"
    "\n"
    "  Future<SendPort> spawn() {\n"
    "    Completer<SendPort> completer = new Completer<SendPort>();\n"
    "    SendPort port = _start(_entry);\n"
    "    completer.complete(port);\n"
    "    return completer.future;\n"
    "  }\n"
    "\n"
    "  static SendPort _start(entry)\n"
    "      native \"CustomIsolateImpl_start\";\n"
    "\n"
    "  String _entry;\n"
    "}\n"
    "\n"
    "interface CustomIsolate factory CustomIsolateImpl {\n"
    "  CustomIsolate(String entry);\n"
    "\n"
    "  Future<SendPort> spawn();\n"
    "}\n"
    "\n"
    "isolateMain() {\n"
    "   echo('Running isolateMain');\n"
    "   receivePort.receive((message, SendPort replyTo) {\n"
    "     echo('Received: ' + message);\n"
    "     replyTo.send((message + 1), null);\n"
    "   });\n"
    "}\n"
    "\n"
    "main() {\n"
    "  Isolate isolate = new CustomIsolate(\"isolateMain\");\n"
    "  isolate.spawn().then((SendPort port) {\n"
    "    port.call(42).receive((message, replyTo) {\n"
    "      echo('Received: ' + message);\n"
    "    });\n"
    "  });\n"
    "  return 'success';\n"
    "}\n";


// An entry in our event queue.
class Event {
 protected:
  Event() : next_(NULL) {}

 public:
  virtual ~Event() {}
  virtual void Process() = 0;

  virtual bool IsShutdownEvent(Dart_Isolate isolate) {
    return false;
  }
  virtual bool IsMessageEvent(Dart_Isolate isolate, Dart_Port port) {
    return false;
  }

 private:
  friend class EventQueue;
  Event* next_;
};


// Start an isolate.
class StartEvent : public Event {
 public:
  StartEvent(Dart_Isolate isolate, const char* main)
      : isolate_(isolate), main_(main) {}

  virtual void Process();
 private:
  Dart_Isolate isolate_;
  const char* main_;
};


void StartEvent::Process() {
  OS::Print(">> StartEvent with isolate(%p)--\n", isolate_);
  Dart_EnterIsolate(isolate_);
  Dart_EnterScope();
  Dart_Handle result;

  // Reload all the test classes here.
  //
  // TODO(turnidge): Use the create isolate callback instead?
  Dart_Handle lib = TestCase::LoadTestScript(kCustomIsolateScriptChars,
                                             NativeLookup);
  EXPECT_VALID(lib);
  EXPECT_VALID(Dart_CompileAll());

  Dart_Handle recv_port = Dart_GetReceivePort(Dart_GetMainPortId());
  EXPECT_VALID(recv_port);

  // TODO(turnidge): Provide a way to set a top-level variable from
  // the dart embedding api.
  Dart_Handle hidden = Dart_GetClass(lib, Dart_NewString("GlobalsHack"));
  EXPECT_VALID(hidden);
  result = Dart_SetStaticField(hidden, Dart_NewString("_receivePort"),
                               recv_port);
  EXPECT_VALID(result);

  result = Dart_InvokeStatic(lib,
                             Dart_NewString(""),
                             Dart_NewString(main_),
                             0,
                             NULL);
  EXPECT_VALID(result);
  free(const_cast<char*>(main_));
  main_ = NULL;

  Dart_ExitScope();
  Dart_ExitIsolate();
}


// Shutdown an isolate.
class ShutdownEvent : public Event {
 public:
  explicit ShutdownEvent(Dart_Isolate isolate) : isolate_(isolate) {}

  virtual bool IsShutdownEvent(Dart_Isolate isolate) {
    return isolate == isolate_;
  }

  virtual void Process();
 private:
  Dart_Isolate isolate_;
};


void ShutdownEvent::Process() {
  OS::Print("<< ShutdownEvent with isolate(%p)--\n", isolate_);
  Dart_EnterIsolate(isolate_);
  Dart_ShutdownIsolate();
}


// Deliver a message to an isolate.
class MessageEvent : public Event {
 public:
  MessageEvent(Dart_Isolate isolate, Dart_Port dest, Dart_Port reply,
               Dart_Message msg)
      : isolate_(isolate), dest_(dest), reply_(reply), msg_(msg) {}

  ~MessageEvent() {
    free(msg_);
    msg_ = NULL;
  }

  virtual bool IsMessageEvent(Dart_Isolate isolate, Dart_Port port) {
    return isolate == isolate_ && (port == kCloseAllPorts || port == dest_);
  }

  virtual void Process();
 private:
  Dart_Isolate isolate_;
  Dart_Port dest_;
  Dart_Port reply_;
  Dart_Message msg_;
};


void MessageEvent::Process() {
  OS::Print("$$ MessageEvent with dest port %lld--\n", dest_);
  Dart_EnterIsolate(isolate_);
  Dart_EnterScope();

  Dart_Handle result = Dart_HandleMessage(dest_, reply_, msg_);
  EXPECT_VALID(result);

  Dart_ExitScope();
  Dart_ExitIsolate();
}


// A simple event queue for our test.
class EventQueue {
 public:
  EventQueue() {
    head_ = NULL;
  }

  void Add(Event* event) {
    if (head_ == NULL) {
      head_ = event;
      tail_ = event;
    } else {
      tail_->next_ = event;
      tail_ = event;
    }
  }

  Event* Get() {
    if (head_ == NULL) {
      return NULL;
    }
    Event* tmp = head_;
    head_ = head_->next_;
    if (head_ == NULL) {
      tail_ = NULL;
    }

    return tmp;
  }

  void ClosePort(Dart_Isolate isolate, Dart_Port port) {
    Event* cur = head_;
    Event* prev = NULL;
    while (cur != NULL) {
      Event* next = cur->next_;
      if (cur->IsMessageEvent(isolate, port)) {
        // Remove matching event.
        if (prev != NULL) {
          prev->next_ = next;
        } else {
          head_ = next;
        }
        delete cur;
      } else {
        // Advance.
        prev = cur;
      }
      cur = next;
    }
    tail_ = prev;
  }

 private:
  Event* head_;
  Event* tail_;
};
EventQueue* event_queue;
Event* current_event;

static bool PostMessage(Dart_Isolate dest_isolate,
                        Dart_Port dest_port,
                        Dart_Port reply_port,
                        Dart_Message message) {
  OS::Print("-- Posting message dest(%d) reply(%d) --\n",
            dest_port, reply_port);
  OS::Print("-- Adding MessageEvent to queue --\n");
  event_queue->Add(
      new MessageEvent(dest_isolate, dest_port, reply_port, message));
}


static void ClosePort(Dart_Isolate isolate,
                      Dart_Port port) {
  OS::Print("-- Closing port (%lld) for isolate(%p) --\n",
            port, isolate);

  // Remove any pending events for the isolate/port.
  event_queue->ClosePort(isolate, port);

  Dart_Isolate current = Dart_CurrentIsolate();
  if (current) {
    Dart_ExitIsolate();
  }
  Dart_EnterIsolate(isolate);
  if (!Dart_HasLivePorts() &&
      (current_event == NULL || !current_event->IsShutdownEvent(isolate))) {
    OS::Print("-- Adding ShutdownEvent to queue --\n");
    event_queue->Add(new ShutdownEvent(isolate));
  }
  Dart_ExitIsolate();
  if (current) {
    Dart_EnterIsolate(current);
  }
}


static Dart_NativeFunction NativeLookup(Dart_Handle name, int argc) {
  const char* name_str = NULL;
  EXPECT(Dart_IsString(name));
  EXPECT_VALID(Dart_StringToCString(name, &name_str));
  if (strcmp(name_str, "native_echo") == 0) {
    return &native_echo;
  } else if (strcmp(name_str, "CustomIsolateImpl_start") == 0) {
    return &CustomIsolateImpl_start;
  }
  return NULL;
}


const char* saved_echo = NULL;
static void native_echo(Dart_NativeArguments args) {
  Dart_EnterScope();
  Dart_Handle arg = Dart_GetNativeArgument(args, 0);
  Dart_Handle toString = Dart_ToString(arg);
  EXPECT_VALID(toString);
  const char* c_str = NULL;
  EXPECT_VALID(Dart_StringToCString(toString, &c_str));
  if (saved_echo) {
    free(const_cast<char*>(saved_echo));
  }
  saved_echo = strdup(c_str);
  OS::Print("-- (isolate=%p) %s\n", Dart_CurrentIsolate(), c_str);
  Dart_ExitScope();
}


static void CustomIsolateImpl_start(Dart_NativeArguments args) {
  OS::Print("-- Enter: CustomIsolateImpl_start --\n");
  Dart_Handle result;

  // We would probably want to pass in the this pointer too, so we
  // could associate the CustomIsolateImpl instance with the
  // Dart_Isolate by storing it in a native field.
  EXPECT_EQ(1, Dart_GetNativeArgumentCount(args));
  Dart_Handle param = Dart_GetNativeArgument(args, 0);
  EXPECT_VALID(param);
  EXPECT(Dart_IsString(param));
  const char* isolate_main = NULL;
  EXPECT_VALID(Dart_StringToCString(param, &isolate_main));
  isolate_main = strdup(isolate_main);

  // Save current isolate.
  Dart_Isolate saved_isolate = Dart_CurrentIsolate();
  Dart_ExitIsolate();

  // Create a new Dart_Isolate.
  Dart_Isolate new_isolate = Dart_CreateIsolate(NULL, NULL);
  Dart_SetMessageCallbacks(&PostMessage, &ClosePort);
  Dart_Port new_port = Dart_GetMainPortId();

  OS::Print("-- Adding StartEvent to queue --\n");
  event_queue->Add(new StartEvent(new_isolate, isolate_main));

  // Restore the original isolate.
  Dart_ExitIsolate();
  Dart_EnterIsolate(saved_isolate);
  Dart_EnterScope();

  Dart_Handle send_port = Dart_NewSendPort(new_port);
  EXPECT_VALID(send_port);
  Dart_SetReturnValue(args, send_port);

  OS::Print("-- Exit: CustomIsolateImpl_start --\n");
  Dart_ExitScope();
}


UNIT_TEST_CASE(CustomIsolates) {
  event_queue = new EventQueue();
  current_event = NULL;

  Dart_Isolate main_isolate = Dart_CreateIsolate(NULL, NULL);
  Dart_SetMessageCallbacks(&PostMessage, &ClosePort);
  Dart_EnterScope();
  Dart_Handle result;

  // Create a test library.
  Dart_Handle lib = TestCase::LoadTestScript(kCustomIsolateScriptChars,
                                             NativeLookup);
  EXPECT_VALID(lib);

  // Run main.
  result = Dart_InvokeStatic(lib,
                             Dart_NewString(""),
                             Dart_NewString("main"),
                             0,
                             NULL);
  EXPECT_VALID(result);
  EXPECT(Dart_IsString(result));
  const char* result_str = NULL;
  EXPECT_VALID(Dart_StringToCString(result, &result_str));
  EXPECT_STREQ("success", result_str);

  Dart_ExitScope();
  Dart_ExitIsolate();

  OS::Print("-- Starting event loop --\n");
  Event* event = event_queue->Get();
  while (event) {
    current_event = event;
    event->Process();
    current_event = NULL;
    delete event;
    event = event_queue->Get();
  }
  OS::Print("-- Finished event loop --\n");
  EXPECT_STREQ("Received: 43", saved_echo);
  free(const_cast<char*>(saved_echo));

  delete event_queue;
}

#endif  // TARGET_ARCH_IA32.

}  // namespace dart
