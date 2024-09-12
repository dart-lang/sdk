// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/native_message_handler.h"

#include <memory>
#include <utility>

#include "vm/dart_api_message.h"
#include "vm/isolate.h"
#include "vm/message.h"
#include "vm/message_snapshot.h"
#include "vm/snapshot.h"

namespace dart {

NativeMessageHandler::NativeMessageHandler(const char* name,
                                           Dart_NativeMessageHandler func,
                                           intptr_t max_concurrency)
    : name_(Utils::StrDup(name)), func_(func), pool_(max_concurrency) {}

NativeMessageHandler::~NativeMessageHandler() {}

#if defined(DEBUG)
void NativeMessageHandler::CheckAccess() const {
  ASSERT(Isolate::Current() == nullptr);
}
#endif

namespace {
class HandleMessage : public ThreadPool::Task {
 public:
  HandleMessage(Dart_NativeMessageHandler handler,
                std::unique_ptr<Message> message)
      : handler_(handler), message_(std::move(message)) {
    ASSERT(handler != nullptr);
  }

  virtual void Run() {
    ApiNativeScope scope;
    Dart_CObject* object = ReadApiMessage(scope.zone(), message_.get());
    handler_(message_->dest_port(), object);
  }

 private:
  Dart_NativeMessageHandler handler_;
  std::unique_ptr<Message> message_;

  DISALLOW_COPY_AND_ASSIGN(HandleMessage);
};
}  // namespace

void NativeMessageHandler::PostMessage(std::unique_ptr<Message> message,
                                       bool before_events /* = false */) {
  if (message->IsOOB()) {
    UNREACHABLE();
  }

  pool_.Run<HandleMessage>(func_, std::move(message));
}

void NativeMessageHandler::RequestDeletion(NativeMessageHandler* handler) {
  ThreadPool::RequestShutdown(&handler->pool_, [handler]() { delete handler; });
}

void NativeMessageHandler::Shutdown() {
  pool_.Shutdown();
}

}  // namespace dart
