// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_NATIVE_MESSAGE_HANDLER_H_
#define RUNTIME_VM_NATIVE_MESSAGE_HANDLER_H_

#include <memory>

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "vm/message_handler.h"

namespace dart {

// A NativeMessageHandler accepts messages and dispatches them to
// native C handlers on worker threads. It will spawn up to
// |max_concurrency| worker threads which will handle incomming messages
// concurrently.
class NativeMessageHandler final : public PortHandler {
 public:
  NativeMessageHandler(const char* name,
                       Dart_NativeMessageHandler func,
                       intptr_t max_concurrency);

  ~NativeMessageHandler() override;

  const char* name() const override { return name_.get(); }
  Dart_NativeMessageHandler func() const { return func_; }

#if defined(DEBUG)
  // Check that it is safe to access this handler.
  void CheckAccess() const override;
#endif

  void OnPortClosed(Dart_Port port) override {}

  Isolate* isolate() const override { return nullptr; }

  // Posts a message on this handler's message queue.
  // If before_events is true, then the message is enqueued before any pending
  // events, but after any pending isolate library events.
  void PostMessage(std::unique_ptr<Message> message,
                   bool before_events = false) override;

  // Request deletion of the given handler once it is down with the currently
  // running Dart_NativeMessageHandler callbacks. No new callbacks will be
  // scheduled after this call.
  //
  // Note: |handler| might be deleted synchronously if no callback is running,
  // or it can be deleted later on a worker thread.
  static void RequestDeletion(NativeMessageHandler* handler);

  void Shutdown() override;

 private:
  PortSet<PortSetEntry>* ports(PortMap::Locker& locker) override {
    return nullptr;
  }

  CStringUniquePtr name_;
  const Dart_NativeMessageHandler func_;

  ThreadPool pool_;
};

}  // namespace dart

#endif  // RUNTIME_VM_NATIVE_MESSAGE_HANDLER_H_
