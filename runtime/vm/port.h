// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_PORT_H_
#define RUNTIME_VM_PORT_H_

#include <memory>

#include "include/dart_api.h"
#include "vm/allocation.h"
#include "vm/globals.h"
#include "vm/json_stream.h"
#include "vm/port_set.h"
#include "vm/random.h"

namespace dart {

class Isolate;
class Message;
class MessageHandler;
class Mutex;

class PortMap : public AllStatic {
 public:
  // Allocate a port for the provided handler and return its VM-global id.
  static Dart_Port CreatePort(MessageHandler* handler);

  // Close the port with id. All pending messages will be dropped.
  //
  // Returns true if the port is successfully closed.
  static bool ClosePort(Dart_Port id,
                        MessageHandler** message_handler = nullptr);

  // Close all the ports for the provided handler.
  static void ClosePorts(MessageHandler* handler);

  // Enqueues the message in the port with id. Returns false if the port is not
  // active any longer.
  //
  // Claims ownership of 'message'.
  static bool PostMessage(std::unique_ptr<Message> message,
                          bool before_events = false);


  // Returns the owning Isolate for port 'id'.
  static Isolate* GetIsolate(Dart_Port id);

  // Returns the origin id for port 'id'.
  static Dart_Port GetOriginId(Dart_Port id);

#if defined(TESTING)
  static bool PortExists(Dart_Port id);
  static bool HasPorts(MessageHandler* handler);
#endif

  // Whether the destination port's isolate is a member of [isolate_group].
  static bool IsReceiverInThisIsolateGroupOrClosed(Dart_Port receiver,
                                                   IsolateGroup* group);

  static void Init();
  static void Cleanup();

  static void PrintPortsForMessageHandler(MessageHandler* handler,
                                          JSONStream* stream);

  static void DebugDumpForMessageHandler(MessageHandler* handler);

 private:
  struct Entry : public PortSet<Entry>::Entry {
    Entry() : handler(nullptr) {}

    MessageHandler* handler;
  };

  // Allocate a new unique port.
  static Dart_Port AllocatePort();

  // Lock protecting access to the port map.
  static Mutex* mutex_;

  static PortSet<Entry>* ports_;

  static Random* prng_;
};

}  // namespace dart

#endif  // RUNTIME_VM_PORT_H_
