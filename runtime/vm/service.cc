// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/debugger.h"
#include "vm/heap_histogram.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/object.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/service.h"

namespace dart {

typedef void (*ServiceMessageHandler)(Isolate* isolate, JSONStream* stream);

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
    ASSERT(handler != NULL);
    {
      JSONStream js;

      // Setup JSONStream arguments and options. The arguments and options
      // are zone allocated and will be freed immediately after handling the
      // message.
      Zone* zoneAllocator = zone.GetZone();
      const char** arguments = zoneAllocator->Alloc<const char*>(path.Length());
      String& string_iterator = String::Handle();
      for (intptr_t i = 0; i < path.Length(); i++) {
        string_iterator ^= path.At(i);
        arguments[i] =
            zoneAllocator->MakeCopyOfString(string_iterator.ToCString());
      }
      js.SetArguments(arguments, path.Length());
      if (option_keys.Length() > 0) {
        const char** option_keys_native =
            zoneAllocator->Alloc<const char*>(option_keys.Length());
        const char** option_values_native =
            zoneAllocator->Alloc<const char*>(option_keys.Length());
        for (intptr_t i = 0; i < option_keys.Length(); i++) {
          string_iterator ^= option_keys.At(i);
          option_keys_native[i] =
              zoneAllocator->MakeCopyOfString(string_iterator.ToCString());
          string_iterator ^= option_values.At(i);
          option_values_native[i] =
              zoneAllocator->MakeCopyOfString(string_iterator.ToCString());
        }
        js.SetOptions(option_keys_native, option_values_native,
                      option_keys.Length());
      }

      handler(isolate, &js);
      const String& reply = String::Handle(String::New(js.ToCString()));
      ASSERT(!reply.IsNull());
      PostReply(reply, reply_port);
    }
  }
}


static void PrintArgumentsAndOptions(const JSONObject& obj, JSONStream* js) {
  JSONObject jsobj(&obj, "message");
  {
    JSONArray jsarr(&jsobj, "arguments");
    for (intptr_t i = 0; i < js->num_arguments(); i++) {
      jsarr.AddValue(js->GetArgument(i));
    }
  }
  {
    JSONArray jsarr(&jsobj, "option_keys");
    for (intptr_t i = 0; i < js->num_options(); i++) {
      jsarr.AddValue(js->GetOptionKey(i));
    }
  }
  {
    JSONArray jsarr(&jsobj, "option_values");
    for (intptr_t i = 0; i < js->num_options(); i++) {
      jsarr.AddValue(js->GetOptionValue(i));
    }
  }
}


static void PrintCollectionErrorResponse(const char* collection_name,
                                         JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "error");
  jsobj.AddPropertyF("text", "Must specify collection object id: /%s/id",
                     collection_name);
}


static void HandleName(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "IsolateName");
  jsobj.AddProperty("id", static_cast<intptr_t>(isolate->main_port()));
  jsobj.AddProperty("name", isolate->name());
}


static void HandleStackTrace(Isolate* isolate, JSONStream* js) {
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "StackTrace");
  JSONArray jsarr(&jsobj, "members");
  intptr_t n_frames = stack->Length();
  String& url = String::Handle();
  String& function = String::Handle();
  for (int i = 0; i < n_frames; i++) {
    ActivationFrame* frame = stack->FrameAt(i);
    url ^= frame->SourceUrl();
    function ^= frame->function().UserVisibleName();
    JSONObject jsobj(&jsarr);
    jsobj.AddProperty("name", function.ToCString());
    jsobj.AddProperty("url", url.ToCString());
    jsobj.AddProperty("line", frame->LineNumber());
    jsobj.AddProperty("function", frame->function());
    jsobj.AddProperty("code", frame->code());
  }
}


static void HandleObjectHistogram(Isolate* isolate, JSONStream* js) {
  ObjectHistogram* histogram = Isolate::Current()->object_histogram();
  if (histogram == NULL) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "error");
    jsobj.AddProperty("text", "Run with --print_object_histogram");
    return;
  }
  histogram->PrintToJSONStream(js);
}


static void HandleEcho(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "message");
  PrintArgumentsAndOptions(jsobj, js);
}

// Print an error message if there is no ID argument.
#define REQUIRE_COLLECTION_ID(collection)                                      \
  if (js->num_arguments() == 1) {                                              \
    PrintCollectionErrorResponse(collection, js);                              \
    return;                                                                    \
  }

// Print a Dart object to the stream if found in ring. Otherwise print null.
#define PRINT_RING_OBJ(type)                                                   \
  ASSERT(js->num_arguments() >= 2);                                            \
  ObjectIdRing* ring = isolate->object_id_ring();                              \
  ASSERT(ring != NULL);                                                        \
  intptr_t id = atoi(js->GetArgument(1));                                      \
  Object& obj = Object::Handle(ring->GetObjectForId(id));                      \
  if (!obj.Is##type()) {                                                       \
    /* Object is not type, replace with null. */                               \
    obj = Object::null();                                                      \
  }                                                                            \
  obj.PrintToJSONStream(js, false)


static void HandleLibraries(Isolate* isolate, JSONStream* js) {
  if (js->num_arguments() == 1) {
    const Library& lib =
        Library::Handle(isolate->object_store()->root_library());
    lib.PrintToJSONStream(js, true);
  } else {
    PRINT_RING_OBJ(Library);
  }
}


static void HandleFunctions(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("functions");
  PRINT_RING_OBJ(Function);
}


static void HandleClasses(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("classes");
  PRINT_RING_OBJ(Class);
}


static void HandleCodes(Isolate* isolate, JSONStream* js) {
  REQUIRE_COLLECTION_ID("codes");
  PRINT_RING_OBJ(Code);
}


static ServiceMessageHandlerEntry __message_handlers[] = {
  { "name", HandleName },
  { "stacktrace", HandleStackTrace },
  { "objecthistogram", HandleObjectHistogram},
  { "libraries", HandleLibraries },
  { "functions", HandleFunctions },
  { "classes", HandleClasses },
  { "codes", HandleCodes },
  { "_echo", HandleEcho },
};


static void HandleFallthrough(Isolate* isolate, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "error");
  jsobj.AddProperty("text", "request not understood.");
  PrintArgumentsAndOptions(jsobj, js);
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
