// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/service.h"

namespace dart {

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


static RawString* HandleIdMessage(Isolate* isolate, Dart_Port reply_port) {
  TextBuffer buffer(256);
  buffer.Printf("{ \"id\": \"%s\" }", isolate->name());
  return String::New(buffer.buf());
}


void Service::HandleServiceMessage(Isolate* isolate, Dart_Port reply_port,
                                   const Instance& message) {
  ASSERT(isolate != NULL);
  ASSERT(reply_port != ILLEGAL_PORT);
  ASSERT(!message.IsNull());
  ASSERT(message.IsString());

  String& reply = String::Handle();

  // For now, assume service message is always an id check.
  reply = HandleIdMessage(isolate, reply_port);

  ASSERT(!reply.IsNull());

  PostReply(reply, reply_port);
}

}  // namespace dart
