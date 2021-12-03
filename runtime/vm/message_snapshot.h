// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_MESSAGE_SNAPSHOT_H_
#define RUNTIME_VM_MESSAGE_SNAPSHOT_H_

#include <memory>

#include "include/dart_native_api.h"
#include "vm/message.h"
#include "vm/object.h"

namespace dart {

std::unique_ptr<Message> WriteMessage(bool can_send_any_object,
                                      bool same_group,
                                      const Object& obj,
                                      Dart_Port dest_port,
                                      Message::Priority priority);

std::unique_ptr<Message> WriteApiMessage(Zone* zone,
                                         Dart_CObject* obj,
                                         Dart_Port dest_port,
                                         Message::Priority priority);

ObjectPtr ReadObjectGraphCopyMessage(Thread* thread, PersistentHandle* handle);

ObjectPtr ReadMessage(Thread* thread, Message* message);

Dart_CObject* ReadApiMessage(Zone* zone, Message* message);

}  // namespace dart

#endif  // RUNTIME_VM_MESSAGE_SNAPSHOT_H_
