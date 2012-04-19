// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef VM_NATIVE_MESSAGE_HANDLER_H_
#define VM_NATIVE_MESSAGE_HANDLER_H_

#include "include/dart_api.h"
#include "vm/message_handler.h"

namespace dart {

// A NativeMessageHandler accepts messages and dispatches them to
// native C handlers.
class NativeMessageHandler : public MessageHandler {
 public:
  NativeMessageHandler(const char* name, Dart_NativeMessageHandler func);
  ~NativeMessageHandler();

  const char* name() const { return name_; }
  Dart_NativeMessageHandler func() const { return func_; }

  bool HandleMessage(Message* message);

#if defined(DEBUG)
  // Check that it is safe to access this handler.
  void CheckAccess();
#endif

  // Delete this handlers when its last live port is closed.
  virtual bool OwnedByPortMap() const { return true; }

 private:
  char* name_;
  Dart_NativeMessageHandler func_;
};

}  // namespace dart

#endif  // VM_NATIVE_MESSAGE_HANDLER_H_
