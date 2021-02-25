// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/port.h"

#include <utility>

#include "platform/utils.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message_handler.h"
#include "vm/os_thread.h"

namespace dart {

Mutex* PortMap::mutex_ = NULL;
PortSet<PortMap::Entry>* PortMap::ports_ = NULL;
MessageHandler* PortMap::deleted_entry_ = reinterpret_cast<MessageHandler*>(1);
Random* PortMap::prng_ = NULL;

const char* PortMap::PortStateString(PortState kind) {
  switch (kind) {
    case kNewPort:
      return "new";
    case kLivePort:
      return "live";
    case kControlPort:
      return "control";
    case kInactivePort:
      return "inactive";
    default:
      UNREACHABLE();
      return "UNKNOWN";
  }
}

Dart_Port PortMap::AllocatePort() {
  Dart_Port result;

  // Keep getting new values while we have an illegal port number or the port
  // number is already in use.
  do {
    // Ensure port ids are representable in JavaScript for the benefit of
    // vm-service clients such as Observatory.
    const Dart_Port kMask1 = 0xFFFFFFFFFFFFF;
    // Ensure port ids are never valid object pointers so that reinterpreting
    // an object pointer as a port id never produces a used port id.
    const Dart_Port kMask2 = 0x3;
    result = (prng_->NextUInt64() & kMask1) | kMask2;

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

void PortMap::SetPortState(Dart_Port port, PortState state) {
  MutexLocker ml(mutex_);

  auto it = ports_->TryLookup(port);
  ASSERT(it != ports_->end());

  Entry& entry = *it;
  PortState old_state = entry.state;
  entry.state = state;
  if (state == kLivePort) {
    entry.handler->increment_live_ports();
  } else if (state == kInactivePort && old_state == kLivePort) {
    entry.handler->decrement_live_ports();
  }
  if (FLAG_trace_isolates) {
    OS::PrintErr(
        "[^] Port (%s) -> (%s): \n"
        "\thandler:    %s\n"
        "\tport:       %" Pd64 "\n",
        PortStateString(old_state), PortStateString(state),
        entry.handler->name(), port);
  }
}

Dart_Port PortMap::CreatePort(MessageHandler* handler) {
  ASSERT(handler != NULL);
  MutexLocker ml(mutex_);
#if defined(DEBUG)
  handler->CheckAccess();
#endif

  const Dart_Port port = AllocatePort();

  // The MessageHandler::ports_ is only accessed by [PortMap], it is guarded
  // by the [PortMap::mutex_] we already hold.
  MessageHandler::PortSetEntry isolate_entry;
  isolate_entry.port = port;
  handler->ports_.Insert(isolate_entry);

  Entry entry;
  entry.port = port;
  entry.handler = handler;
  entry.state = kNewPort;
  ports_->Insert(entry);

  if (FLAG_trace_isolates) {
    OS::PrintErr(
        "[+] Opening port: \n"
        "\thandler:    %s\n"
        "\tport:       %" Pd64 "\n",
        handler->name(), entry.port);
  }

  return entry.port;
}

bool PortMap::ClosePort(Dart_Port port) {
  MessageHandler* handler = NULL;
  {
    MutexLocker ml(mutex_);
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

    if (entry.state == kLivePort) {
      handler->decrement_live_ports();
    }

    // Delete the port entry before releasing the lock to avoid holding the lock
    // while flushing the messages below.
    it.Delete();
    ports_->Rebalance();

    // The MessageHandler::ports_ is only accessed by [PortMap], it is guarded
    // by the [PortMap::mutex_] we already hold.
    auto isolate_it = handler->ports_.TryLookup(port);
    ASSERT(isolate_it != handler->ports_.end());
    isolate_it.Delete();
    handler->ports_.Rebalance();
  }
  handler->ClosePort(port);
  if (!handler->HasLivePorts() && handler->OwnedByPortMap()) {
    // Delete handler as soon as it isn't busy with a task.
    handler->RequestDeletion();
  }
  return true;
}

void PortMap::ClosePorts(MessageHandler* handler) {
  {
    MutexLocker ml(mutex_);
    // The MessageHandler::ports_ is only accessed by [PortMap], it is guarded
    // by the [PortMap::mutex_] we already hold.
    for (auto isolate_it = handler->ports_.begin();
         isolate_it != handler->ports_.end(); ++isolate_it) {
      auto it = ports_->TryLookup((*isolate_it).port);
      ASSERT(it != ports_->end());
      Entry entry = *it;
      ASSERT(entry.port == (*isolate_it).port);
      ASSERT(entry.handler == handler);
      if (entry.state == kLivePort) {
        handler->decrement_live_ports();
      }
      it.Delete();
      isolate_it.Delete();
    }
    ASSERT(handler->ports_.IsEmpty());
    ports_->Rebalance();
  }
  handler->CloseAllPorts();
}

bool PortMap::PostMessage(std::unique_ptr<Message> message,
                          bool before_events) {
  MutexLocker ml(mutex_);
  auto it = ports_->TryLookup(message->dest_port());
  if (it == ports_->end()) {
    // Ownership of external data remains with the poster.
    message->DropFinalizers();
    return false;
  }
  MessageHandler* handler = (*it).handler;
  ASSERT(handler != nullptr);
  handler->PostMessage(std::move(message), before_events);
  return true;
}

bool PortMap::IsLocalPort(Dart_Port id) {
  MutexLocker ml(mutex_);
  auto it = ports_->TryLookup(id);
  if (it == ports_->end()) {
    // Port does not exist.
    return false;
  }

  MessageHandler* handler = (*it).handler;
  ASSERT(handler != nullptr);
  return handler->IsCurrentIsolate();
}

bool PortMap::IsLivePort(Dart_Port id) {
  MutexLocker ml(mutex_);
  auto it = ports_->TryLookup(id);
  if (it == ports_->end()) {
    // Port does not exist.
    return false;
  }

  PortState state = (*it).state;
  return (state == kLivePort || state == kControlPort);
}

Isolate* PortMap::GetIsolate(Dart_Port id) {
  MutexLocker ml(mutex_);
  auto it = ports_->TryLookup(id);
  if (it == ports_->end()) {
    // Port does not exist.
    return nullptr;
  }

  MessageHandler* handler = (*it).handler;
  return handler->isolate();
}

bool PortMap::IsReceiverInThisIsolateGroup(Dart_Port receiver,
                                           IsolateGroup* group) {
  MutexLocker ml(mutex_);
  auto it = ports_->TryLookup(receiver);
  if (it == ports_->end()) return false;
  return (*it).handler->isolate()->group() == group;
}

void PortMap::Init() {
  // TODO(bkonyi): don't keep ports_ after Dart_Cleanup.
  if (mutex_ == NULL) {
    mutex_ = new Mutex();
  }
  ASSERT(mutex_ != NULL);
  if (prng_ == nullptr) {
    prng_ = new Random();
  }
  if (ports_ == nullptr) {
    ports_ = new PortSet<Entry>();
  }
}

void PortMap::Cleanup() {
  ASSERT(ports_ != nullptr);
  ASSERT(prng_ != NULL);
  for (auto it = ports_->begin(); it != ports_->end(); ++it) {
    const auto& entry = *it;
    ASSERT(entry.handler != nullptr);
    if (entry.state == kLivePort) {
      entry.handler->decrement_live_ports();
    }
    delete entry.handler;
    it.Delete();
  }
  ports_->Rebalance();

  delete prng_;
  prng_ = NULL;
  // TODO(bkonyi): find out why deleting map_ sometimes causes crashes.
  // delete ports_;
  // ports_ = nullptr;
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
    for (auto& entry : *ports_) {
      if (entry.handler == handler) {
        if (entry.state == kLivePort) {
          JSONObject port(&ports);
          port.AddProperty("type", "_Port");
          port.AddPropertyF("name", "Isolate Port (%" Pd64 ")", entry.port);
          msg_handler = DartLibraryCalls::LookupHandler(entry.port);
          port.AddProperty("handler", msg_handler);
        }
      }
    }
  }
#endif
}

void PortMap::DebugDumpForMessageHandler(MessageHandler* handler) {
  SafepointMutexLocker ml(mutex_);
  Object& msg_handler = Object::Handle();
  for (auto& entry : *ports_) {
    if (entry.handler == handler) {
      if (entry.state == kLivePort) {
        OS::PrintErr("Live Port = %" Pd64 "\n", entry.port);
        msg_handler = DartLibraryCalls::LookupHandler(entry.port);
        OS::PrintErr("Handler = %s\n", msg_handler.ToCString());
      }
    }
  }
}

}  // namespace dart
