// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/port.h"

#include <utility>

#include "include/dart_api.h"
#include "platform/utils.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message_handler.h"
#include "vm/os_thread.h"

namespace dart {

Mutex* PortMap::mutex_ = nullptr;
PortSet<PortMap::Entry>* PortMap::ports_ = nullptr;
Random* PortMap::prng_ = nullptr;

Dart_Port PortMap::AllocatePort() {
  Dart_Port result;

  ASSERT(mutex_->IsOwnedByCurrentThread());

  // Keep getting new values while we have an illegal port number or the port
  // number is already in use.
  do {
    // Ensure port ids are never valid object pointers so that reinterpreting
    // an object pointer as a port id never produces a used port id.
    const Dart_Port kMask2 = 0x3;

    // Ensure port ids are representable in JavaScript for the benefit of
    // vm-service clients such as Observatory.
    result = prng_->NextJSInt() | kMask2;

    // The two special marker ports are used for the hashset implementation and
    // cannot be used as actual ports.
    if (result == PortSet<Entry>::kFreePort ||
        result == PortSet<Entry>::kDeletedPort) {
      continue;
    }

    ASSERT(!static_cast<ObjectPtr>(static_cast<uword>(result))->IsWellFormed());
  } while (ports_->Contains(result));

  ASSERT(result != 0);
  ASSERT(!ports_->Contains(result));
  return result;
}

Dart_Port PortMap::CreatePort(PortHandler* handler) {
  ASSERT(handler != nullptr);
  PortMap::Locker ml;
  if (ports_ == nullptr) {
    return ILLEGAL_PORT;
  }

#if defined(DEBUG)
  handler->CheckAccess();
#endif

  const Dart_Port port = AllocatePort();
  if (auto ports = handler->ports(ml)) {
    ports->Insert(PortHandler::PortSetEntry{port});
  }
  ports_->Insert(Entry{port, handler});

  if (FLAG_trace_isolates) {
    OS::PrintErr(
        "[+] Opening port: \n"
        "\thandler:    %s\n"
        "\tport:       %" Pd64 "\n",
        handler->name(), port);
  }

  return port;
}

bool PortMap::ClosePort(Dart_Port port, PortHandler** port_handler) {
  if (port_handler != nullptr) *port_handler = nullptr;

  PortHandler* handler = nullptr;
  {
    PortMap::Locker ml;
    if (ports_ == nullptr) {
      return false;
    }
    auto it = ports_->TryLookup(port);
    if (it == ports_->end()) {
      return false;
    }
    Entry entry = *it;
    handler = entry.handler;
    ASSERT(handler != nullptr);

#if defined(DEBUG)
    handler->CheckAccess();
#endif

    it.Delete();
    ports_->Rebalance();

    if (auto ports = handler->ports(ml)) {
      auto isolate_it = ports->TryLookup(port);
      ASSERT(isolate_it != ports->end());
      isolate_it.Delete();
      ports->Rebalance();
    }
  }
  handler->OnPortClosed(port);
  if (port_handler != nullptr) *port_handler = handler;
  return true;
}

void PortMap::ClosePorts(MessageHandler* handler) {
  {
    PortMap::Locker ml;
    if (ports_ == nullptr) {
      return;
    }

    auto ports = handler->ports(ml);
    ASSERT(ports != nullptr);

    for (auto isolate_it = ports->begin(); isolate_it != ports->end();
         ++isolate_it) {
      auto it = ports_->TryLookup((*isolate_it).port);
      ASSERT(it != ports_->end());
      Entry entry = *it;
      ASSERT(entry.port == (*isolate_it).port);
      ASSERT(entry.handler == handler);
      it.Delete();
      isolate_it.Delete();
    }
    ASSERT(ports->IsEmpty());
    ports_->Rebalance();
  }
  handler->OnAllPortsClosed();
}

bool PortMap::PostMessage(std::unique_ptr<Message> message,
                          bool before_events) {
  MutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    return false;
  }
  auto it = ports_->TryLookup(message->dest_port());
  if (it == ports_->end()) {
    // Ownership of external data remains with the poster.
    message->DropFinalizers();
    return false;
  }
  auto handler = (*it).handler;
  ASSERT(handler != nullptr);
  handler->PostMessage(std::move(message), before_events);
  return true;
}

#if defined(TESTING)
bool PortMap::PortExists(Dart_Port id) {
  MutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    return false;
  }
  auto it = ports_->TryLookup(id);
  return it != ports_->end();
}
#endif  // defined(TESTING)

Isolate* PortMap::GetIsolate(Dart_Port id) {
  MutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    return nullptr;
  }
  auto it = ports_->TryLookup(id);
  if (it == ports_->end()) {
    // Port does not exist.
    return nullptr;
  }

  auto handler = (*it).handler;
  return handler->isolate();
}

Dart_Port PortMap::GetOriginId(Dart_Port id) {
  MutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    return ILLEGAL_PORT;
  }
  auto it = ports_->TryLookup(id);
  if (it == ports_->end()) {
    // Port does not exist.
    return ILLEGAL_PORT;
  }

  auto handler = (*it).handler;
  Isolate* isolate = handler->isolate();
  if (isolate == nullptr) {
    // Message handler is a native port instead of an isolate.
    return ILLEGAL_PORT;
  }
  return isolate->origin_id();
}

#if defined(TESTING)
bool PortMap::HasPorts(MessageHandler* handler) {
  MutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    return false;
  }
  // The MessageHandler::ports_ is only accessed by [PortMap], it is guarded
  // by the [PortMap::mutex_] we already hold.
  return !handler->ports_.IsEmpty();
}
#endif

bool PortMap::IsReceiverInThisIsolateGroupOrClosed(Dart_Port receiver,
                                                   IsolateGroup* group) {
  MutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    // Port was closed.
    return true;
  }
  auto it = ports_->TryLookup(receiver);
  if (it == ports_->end()) {
    // Port was closed.
    return true;
  }
  auto isolate = (*it).handler->isolate();
  if (isolate == nullptr) {
    // Port belongs to a native port instead of an isolate.
    return false;
  }
  return isolate->group() == group;
}

void PortMap::Init() {
  if (mutex_ == nullptr) {
    mutex_ = new Mutex();
  }
  ASSERT(mutex_ != nullptr);
  if (prng_ == nullptr) {
    prng_ = new Random();
  }
  if (ports_ == nullptr) {
    ports_ = new PortSet<Entry>();
  }
}

void PortMap::Shutdown() {
  // Tell all handlers which are running their own thread pools to shutdown.
  for (auto& entry : *ports_) {
    entry.handler->Shutdown();
  }
}

void PortMap::Cleanup() {
  ASSERT(ports_ != nullptr);
  ASSERT(prng_ != nullptr);
  for (auto it = ports_->begin(); it != ports_->end(); ++it) {
    const auto& entry = *it;
    ASSERT(entry.handler != nullptr);
    delete entry.handler;
    it.Delete();
  }
  ports_->Rebalance();

  // Grab the mutex and delete the port set.
  MutexLocker ml(mutex_);
  delete prng_;
  prng_ = nullptr;
  delete ports_;
  ports_ = nullptr;
}

void PortMap::PrintPortsForMessageHandler(MessageHandler* handler,
                                          JSONStream* stream) {
#ifndef PRODUCT
  JSONObject jsobj(stream);
  jsobj.AddProperty("type", "_Ports");
  Object& msg_handler = Object::Handle();
  {
    JSONArray ports(&jsobj, "ports");
    SafepointMutexLocker ml(mutex_);
    if (ports_ == nullptr) {
      return;
    }
    for (auto& entry : *ports_) {
      if (entry.handler == handler) {
        JSONObject port(&ports);
        port.AddProperty("type", "_Port");
        port.AddPropertyF("name", "Isolate Port (%" Pd64 ")", entry.port);
        msg_handler = DartLibraryCalls::LookupHandler(entry.port);
        port.AddProperty("handler", msg_handler);
      }
    }
  }
#endif
}

void PortMap::DebugDumpForMessageHandler(MessageHandler* handler) {
  SafepointMutexLocker ml(mutex_);
  if (ports_ == nullptr) {
    return;
  }
  Object& msg_handler = Object::Handle();
  for (auto& entry : *ports_) {
    if (entry.handler == handler) {
      OS::PrintErr("Port = %" Pd64 "\n", entry.port);
      msg_handler = DartLibraryCalls::LookupHandler(entry.port);
      OS::PrintErr("Handler = %s\n", msg_handler.ToCString());
    }
  }
}

PortHandler::~PortHandler() {}

#if defined(DEBUG)
void PortHandler::CheckAccess() const {
  // By default there is no checking.
}
#endif

}  // namespace dart
