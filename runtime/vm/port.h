// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_PORT_H_
#define VM_PORT_H_

#include "include/dart_api.h"
#include "vm/allocation.h"
#include "vm/globals.h"

namespace dart {

class Isolate;
class Mutex;

class PortMap: public AllStatic {
 public:
  // Allocate a port in the current isolate and return its VM-global id.
  static Dart_Port CreatePort();

  // Close the port with id. All pending messages will be dropped.
  static void ClosePort(Dart_Port id);

  // Close all the ports of the current isolate.
  static void ClosePorts();

  static bool IsActivePort(Dart_Port id);

  // Enqueues the message in the port with id. Returns false if the port is not
  // active any longer.
  //
  // Claims ownership of the memory pointed to by 'message' and will
  // ensure that free(message) is called.
  static bool PostMessage(Dart_Port dest_port,
                          Dart_Port reply_port,
                          Dart_Message message);

  static void InitOnce();

 private:
  // Mapping between port numbers and isolates.
  // Free entries have id == 0 and isolate == NULL. Deleted entries have id == 0
  // and isolate == deleted_entry_.
  typedef struct {
    Dart_Port port;
    Isolate* isolate;
  } Entry;

  // Allocate a new unique port.
  static Dart_Port AllocatePort();

  static intptr_t FindPort(Dart_Port port);
  static void Rehash(intptr_t new_capacity);

  static void MaintainInvariants();

  // Lock protecting access to the port map.
  static Mutex* mutex_;

  // Hashmap of ports.
  static Entry* map_;
  static Isolate* deleted_entry_;
  static intptr_t capacity_;
  static intptr_t used_;
  static intptr_t deleted_;

  static Dart_Port next_port_;
};

}  // namespace dart

#endif  // VM_PORT_H_
