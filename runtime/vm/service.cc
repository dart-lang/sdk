// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"
#include "vm/heap_histogram.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/service.h"

namespace dart {

typedef RawString* (*ServiceMessageHandler)(Isolate* isolate);

struct ServiceMessageHandlerEntry {
  const char* command;
  ServiceMessageHandler handler;
};

static ServiceMessageHandler FindServiceMessageHandler(const char* command);


static uint8_t* allocator(uint8_t* ptr, intptr_t old_size, intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}


static void PostReply(const String& reply, Dart_Port reply_port) {
  uint8_t* data = NULL;
  MessageWriter writer(&data, &allocator);
  writer.WriteMessage(reply);
  PortMap::PostMessage(new Message(reply_port, Message::kIllegalPort, data,
                                   writer.BytesWritten(),
                                   Message::kNormalPriority));
}


void Service::HandleServiceMessage(Isolate* isolate, Dart_Port reply_port,
                                   const Instance& msg) {
  ASSERT(isolate != NULL);
  ASSERT(reply_port != ILLEGAL_PORT);
  ASSERT(!msg.IsNull());
  ASSERT(msg.IsGrowableObjectArray());

  {
    StackZone zone(isolate);
    HANDLESCOPE(isolate);
    const GrowableObjectArray& message = GrowableObjectArray::Cast(msg);
    // Message is a list with three entries.
    ASSERT(message.Length() == 3);

    GrowableObjectArray& path = GrowableObjectArray::Handle();
    GrowableObjectArray& option_keys = GrowableObjectArray::Handle();
    GrowableObjectArray& option_values = GrowableObjectArray::Handle();
    path ^= message.At(0);
    option_keys ^= message.At(1);
    option_values ^= message.At(2);

    ASSERT(!path.IsNull());
    ASSERT(!option_keys.IsNull());
    ASSERT(!option_values.IsNull());
    // Path always has at least one entry in it.
    ASSERT(path.Length() > 0);
    // Same number of option keys as values.
    ASSERT(option_keys.Length() == option_values.Length());

    String& pathSegment = String::Handle();
    pathSegment ^= path.At(0);
    ASSERT(!pathSegment.IsNull());

    ServiceMessageHandler handler =
        FindServiceMessageHandler(pathSegment.ToCString());
    String& reply = String::Handle();
    reply ^= handler(isolate);
    ASSERT(!reply.IsNull());
    PostReply(reply, reply_port);
  }
}


static RawString* HandleName(Isolate* isolate) {
  TextBuffer buffer(256);
  JSONStream js(&buffer);
  js.OpenObject();
  js.PrintProperty("type", "IsolateName");
  js.PrintProperty("id", static_cast<intptr_t>(isolate->main_port()));
  js.PrintProperty("name", isolate->name());
  js.CloseObject();
  return String::New(buffer.buf());
}


RawString* HandleStackTrace(Isolate* isolate) {
  TextBuffer buffer(256);
  JSONStream js(&buffer);
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  js.OpenObject();
  js.PrintProperty("type", "StackTrace");
  js.OpenArray("members");
  intptr_t n_frames = stack->Length();
  String& url = String::Handle();
  String& function = String::Handle();
  for (int i = 0; i < n_frames; i++) {
    ActivationFrame* frame = stack->ActivationFrameAt(i);
    url ^= frame->SourceUrl();
    function ^= frame->function().UserVisibleName();
    js.OpenObject();
    js.PrintProperty("name", function.ToCString());
    js.PrintProperty("url", url.ToCString());
    js.PrintProperty("line", frame->LineNumber());
    js.PrintProperty("function", frame->function());
    js.PrintProperty("code", frame->code());
    js.CloseObject();
  }
  js.CloseArray();
  js.CloseObject();
  return String::New(buffer.buf());
}


RawString* HandleObjectHistogram(Isolate* isolate) {
  TextBuffer buffer(256);
  JSONStream js(&buffer);
  ObjectHistogram* histogram = Isolate::Current()->object_histogram();
  if (histogram == NULL) {
    js.OpenObject();
    js.PrintProperty("type", "ObjectHistogram");
    js.PrintProperty("error", "Run with --print_object_histogram");
    js.CloseObject();
    return String::New(buffer.buf());
  }
  histogram->PrintToJSONStream(&js);
  return String::New(buffer.buf());
}


static ServiceMessageHandlerEntry __message_handlers[] = {
  { "name", HandleName },
  { "stacktrace", HandleStackTrace },
  { "objecthistogram", HandleObjectHistogram},
};


static RawString* HandleFallthrough(Isolate* isolate) {
  TextBuffer buffer(256);
  JSONStream js(&buffer);
  js.OpenObject();
  js.PrintProperty("type", "error");
  js.PrintProperty("text", "request not supported.");
  js.CloseObject();
  return String::New(buffer.buf());
}


static ServiceMessageHandler FindServiceMessageHandler(const char* command) {
  intptr_t num_message_handlers = sizeof(__message_handlers) /
                                  sizeof(__message_handlers[0]);
  for (intptr_t i = 0; i < num_message_handlers; i++) {
    const ServiceMessageHandlerEntry& entry = __message_handlers[i];
    if (!strcmp(command, entry.command)) {
      return entry.handler;
    }
  }
  return HandleFallthrough;
}

}  // namespace dart
