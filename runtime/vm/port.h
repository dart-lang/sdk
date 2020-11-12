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
class PortMapTestPeer;

class PortMap : public AllStatic {
 public:
  enum PortState {
    kNewPort = 0,      // a newly allocated port
    kLivePort = 1,     // a regular port (has a ReceivePort)
    kControlPort = 2,  // a special control port (has a ReceivePort)
    kInactivePort =
        3,  // an inactive port (has a ReceivePort) not considered live.
  };

  // Allocate a port for the provided handler and return its VM-global id.
  static Dart_Port CreatePort(MessageHandler* handler);

  // Indicates that a port has had a ReceivePort created for it at the
  // dart language level.  The port remains live until it is closed.
  static void SetPortState(Dart_Port id, PortState kind);

  // Close the port with id. All pending messages will be dropped.
  //
  // Returns true if the port is successfully closed.
  static bool ClosePort(Dart_Port id);

  // Close all the ports for the provided handler.
  static void ClosePorts(MessageHandler* handler);

  // Enqueues the message in the port with id. Returns false if the port is not
  // active any longer.
  //
  // Claims ownership of 'message'.
  static bool PostMessage(std::unique_ptr<Message> message,
                          bool before_events = false);

  // Returns whether a port is local to the current isolate.
  static bool IsLocalPort(Dart_Port id);

  // Returns whether a port is live (e.g., is not new or inactive).
  static bool IsLivePort(Dart_Port id);

  // Returns the owning Isolate for port 'id'.
  static Isolate* GetIsolate(Dart_Port id);

  static bool IsReceiverInThisIsolateGroup(Dart_Port receiver,
                                           IsolateGroup* group);

  static void Init();
  static void Cleanup();

  static void PrintPortsForMessageHandler(MessageHandler* handler,
                                          JSONStream* stream);

  static void DebugDumpForMessageHandler(MessageHandler* handler);

 private:
  friend class dart::PortMapTestPeer;

  struct Entry : public PortSet<Entry>::Entry {
    Entry() : handler(nullptr), state(kNewPort) {}

    MessageHandler* handler;
    PortState state;
  };

  static const char* PortStateString(PortState state);

  // Allocate a new unique port.
  static Dart_Port AllocatePort();

  // Lock protecting access to the port map.
  static Mutex* mutex_;

  static PortSet<Entry>* ports_;
  static MessageHandler* deleted_entry_;

  static Random* prng_;
};

}  // namespace dart

#endif  // RUNTIME_VM_PORT_H_
