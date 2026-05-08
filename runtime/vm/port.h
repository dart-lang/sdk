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
#include "vm/lockers.h"
#include "vm/port_set.h"
#include "vm/random.h"

namespace dart {

class Isolate;
class Message;
class MessageHandler;
class Mutex;
class PortHandler;

class PortMap : public AllStatic {
 public:
  // Allocate a port for the provided handler and return its VM-global id.
  static Dart_Port CreatePort(PortHandler* handler);

  // Close the port with id. All pending messages will be dropped.
  //
  // Returns true if the port is successfully closed.
  static bool ClosePort(Dart_Port id, PortHandler** port_handler = nullptr);

  // Close all the ports for the provided handler.
  static void ClosePorts(MessageHandler* handler);

  // Enqueues the message in the port with id. Returns false if the port is not
  // active any longer.
  //
  // Claims ownership of 'message'.
  static bool PostMessage(std::unique_ptr<Message> message,
                          bool before_events = false);

  // Returns the origin id for port 'id'.
  static Dart_Port GetOriginId(Dart_Port id);

  // Returns whether the isolate that owns the port is owned by the current
  // thread.
  static bool IsOwnedByCurrentThread(Dart_Port id);

#if defined(TESTING)
  static Isolate* GetIsolate(Dart_Port id);
  static bool PortExists(Dart_Port id);
  static bool HasPorts(MessageHandler* handler);
#endif

  // Whether the destination port's isolate is a member of [isolate_group].
  static bool IsReceiverInThisIsolateGroupOrClosed(Dart_Port receiver,
                                                   IsolateGroup* group);

  static void Init();
  static void Shutdown();
  static void Cleanup();

  static void PrintPortsForMessageHandler(MessageHandler* handler,
                                          JSONStream* stream);

  class Locker : public MutexLocker {
   public:
    Locker() : MutexLocker(PortMap::mutex_) {}
  };

 private:
  struct Entry : public PortSet<Entry>::Entry {
    Entry() : handler(nullptr) {}
    Entry(Dart_Port port, PortHandler* handler)
        : PortSet<Entry>::Entry(port), handler(handler) {}

    PortHandler* handler;
  };

  // Allocate a new unique port.
  static Dart_Port AllocatePort();

  static Isolate* GetIsolateLocked(const Locker& ml, Dart_Port id);

  // Lock protecting access to the port map.
  static Mutex* mutex_;

  static PortSet<Entry>* ports_;

  static Random* prng_;
};

// An object handling messages dispatched to one or more ports in the |PortMap|.
class PortHandler {
 public:
  virtual ~PortHandler();

  virtual const char* name() const = 0;

  // Notify the handler that a port previously associated with it is
  // now closed.
  virtual void OnPortClosed(Dart_Port port) = 0;

#if defined(DEBUG)
  // Check that it is safe to access this port handler.
  //
  // For example, if this |PortHandler| is an isolate, then it is
  // only safe to access it when it is the current isolate.
  virtual void CheckAccess() const;
#endif

  // Return Isolate to which this message handler corresponds to.
  virtual Isolate* isolate() const = 0;

  // Ask the handler to shutdown, e.g. stop associated thread pools if any.
  virtual void Shutdown() = 0;

  // Posts a message on this handler's message queue.
  // If before_events is true, then the message is enqueued before any pending
  // events, but after any pending isolate library events.
  virtual void PostMessage(std::unique_ptr<Message> message,
                           bool before_events = false) = 0;

 protected:
  struct PortSetEntry : public PortSet<PortSetEntry>::Entry {
    PortSetEntry() : Entry() {}
    explicit PortSetEntry(Dart_Port port) : Entry(port) {}
  };

 private:
  friend class PortMap;

  // Returns set of ports associate with this handler if
  // handler supports multiple ports or |nullptr| otherwise.
  //
  // Only |PortMap| is expected to call this method under locked
  // PortMap::mutex_.
  virtual PortSet<PortSetEntry>* ports(PortMap::Locker& locker) = 0;
};

}  // namespace dart

#endif  // RUNTIME_VM_PORT_H_
