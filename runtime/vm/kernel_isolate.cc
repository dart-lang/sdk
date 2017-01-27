// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_isolate.h"

#include "vm/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_entry.h"
#include "vm/native_arguments.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/service.h"
#include "vm/symbols.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"

namespace dart {

#if !defined(DART_PRECOMPILED_RUNTIME)

#define Z (T->zone())

DEFINE_FLAG(bool, trace_kernel, false, "Trace Kernel service requests.");
DEFINE_FLAG(bool,
            use_dart_frontend,
            false,
            "Parse scripts with Dart-to-Kernel parser");

const char* KernelIsolate::kName = "kernel-service";
Dart_IsolateCreateCallback KernelIsolate::create_callback_ = NULL;
Monitor* KernelIsolate::monitor_ = new Monitor();
Isolate* KernelIsolate::isolate_ = NULL;
bool KernelIsolate::initializing_ = true;
Dart_Port KernelIsolate::kernel_port_ = ILLEGAL_PORT;


class RunKernelTask : public ThreadPool::Task {
 public:
  virtual void Run() {
    ASSERT(Isolate::Current() == NULL);

    if (!FLAG_use_dart_frontend) {
      ASSERT(FLAG_use_dart_frontend);
      // In release builds, make this a no-op. In debug builds, the
      // assert shows that this is not supposed to happen.
      return;
    }

#ifndef PRODUCT
    TimelineDurationScope tds(Timeline::GetVMStream(), "KernelIsolateStartup");
#endif  // !PRODUCT
    char* error = NULL;
    Isolate* isolate = NULL;

    Dart_IsolateCreateCallback create_callback =
        KernelIsolate::create_callback();

    if (create_callback == NULL) {
      KernelIsolate::FinishedInitializing();
      return;
    }

    Dart_IsolateFlags api_flags;
    Isolate::FlagsInitialize(&api_flags);

    isolate = reinterpret_cast<Isolate*>(create_callback(
        KernelIsolate::kName, NULL, NULL, NULL, &api_flags, NULL, &error));
    if (isolate == NULL) {
      if (FLAG_trace_kernel) {
        OS::PrintErr("kernel-service: Isolate creation error: %s\n", error);
      }
      KernelIsolate::SetKernelIsolate(NULL);
      KernelIsolate::FinishedInitializing();
      return;
    }

    bool init_success = false;
    {
      ASSERT(Isolate::Current() == NULL);
      StartIsolateScope start_scope(isolate);
      init_success = RunMain(isolate);
    }
    KernelIsolate::FinishedInitializing();

    if (!init_success) {
      ShutdownIsolate(reinterpret_cast<uword>(isolate));
      return;
    }

    // isolate_ was set as side effect of create callback.
    ASSERT(KernelIsolate::IsKernelIsolate(isolate));

    isolate->message_handler()->Run(Dart::thread_pool(), NULL, ShutdownIsolate,
                                    reinterpret_cast<uword>(isolate));
  }

 protected:
  static void ShutdownIsolate(uword parameter) {
    if (FLAG_trace_kernel) {
      OS::Print("kernel-service: ShutdownIsolate\n");
    }
    Isolate* I = reinterpret_cast<Isolate*>(parameter);
    ASSERT(KernelIsolate::IsKernelIsolate(I));
    KernelIsolate::SetKernelIsolate(NULL);
    KernelIsolate::SetLoadPort(ILLEGAL_PORT);
    I->WaitForOutstandingSpawns();
    {
      // Print the error if there is one.  This may execute dart code to
      // print the exception object, so we need to use a StartIsolateScope.
      ASSERT(Isolate::Current() == NULL);
      StartIsolateScope start_scope(I);
      Thread* T = Thread::Current();
      ASSERT(I == T->isolate());
      StackZone zone(T);
      HandleScope handle_scope(T);
      Error& error = Error::Handle(Z);
      error = T->sticky_error();
      if (!error.IsNull() && !error.IsUnwindError()) {
        OS::PrintErr("kernel-service: Error: %s\n", error.ToErrorCString());
      }
      error = I->sticky_error();
      if (!error.IsNull() && !error.IsUnwindError()) {
        OS::PrintErr("kernel-service: Error: %s\n", error.ToErrorCString());
      }
      Dart::RunShutdownCallback();
    }
    // Shut the isolate down.
    Dart::ShutdownIsolate(I);
    if (FLAG_trace_kernel) {
      OS::Print("kernel-service: Shutdown.\n");
    }
  }

  bool RunMain(Isolate* I) {
    Thread* T = Thread::Current();
    ASSERT(I == T->isolate());
    StackZone zone(T);
    HANDLESCOPE(T);
    // Invoke main which will return the port to which load requests are sent.
    const Library& root_library =
        Library::Handle(Z, I->object_store()->root_library());
    if (root_library.IsNull()) {
      if (FLAG_trace_kernel) {
        OS::Print("kernel-service: Embedder did not install a script.");
      }
      // Kernel isolate is not supported by embedder.
      return false;
    }
    ASSERT(!root_library.IsNull());
    const String& entry_name = String::Handle(Z, String::New("main"));
    ASSERT(!entry_name.IsNull());
    const Function& entry = Function::Handle(
        Z, root_library.LookupFunctionAllowPrivate(entry_name));
    if (entry.IsNull()) {
      // Kernel isolate is not supported by embedder.
      if (FLAG_trace_kernel) {
        OS::Print("kernel-service: Embedder did not provide a main function.");
      }
      return false;
    }
    ASSERT(!entry.IsNull());
    const Object& result = Object::Handle(
        Z, DartEntry::InvokeFunction(entry, Object::empty_array()));
    ASSERT(!result.IsNull());
    if (result.IsError()) {
      // Kernel isolate did not initialize properly.
      if (FLAG_trace_kernel) {
        const Error& error = Error::Cast(result);
        OS::Print("kernel-service: Calling main resulted in an error: %s",
                  error.ToErrorCString());
      }
      return false;
    }
    ASSERT(result.IsReceivePort());
    const ReceivePort& rp = ReceivePort::Cast(result);
    KernelIsolate::SetLoadPort(rp.Id());
    return true;
  }
};


void KernelIsolate::Run() {
  if (!FLAG_use_dart_frontend) {
    return;
  }
  // Grab the isolate create callback here to avoid race conditions with tests
  // that change this after Dart_Initialize returns.
  create_callback_ = Isolate::CreateCallback();
  Dart::thread_pool()->Run(new RunKernelTask());
}


void KernelIsolate::InitCallback(Isolate* I) {
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != NULL);
  ASSERT(I->name() != NULL);
  if (!FLAG_use_dart_frontend ||
      (strstr(I->name(), "kernel-service") == NULL)) {
    // Not kernel isolate.
    return;
  }
  ASSERT(!Exists());
  if (FLAG_trace_kernel) {
    OS::Print("kernel-service: InitCallback for %s.\n", I->name());
  }
  SetKernelIsolate(I);
}


bool KernelIsolate::IsKernelIsolate(const Isolate* isolate) {
  MonitorLocker ml(monitor_);
  return isolate == isolate_;
}


bool KernelIsolate::IsRunning() {
  MonitorLocker ml(monitor_);
  return (kernel_port_ != ILLEGAL_PORT) && (isolate_ != NULL);
}


bool KernelIsolate::Exists() {
  MonitorLocker ml(monitor_);
  return isolate_ != NULL;
}


void KernelIsolate::SetKernelIsolate(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  isolate_ = isolate;
}

void KernelIsolate::SetLoadPort(Dart_Port port) {
  MonitorLocker ml(monitor_);
  kernel_port_ = port;
}

void KernelIsolate::FinishedInitializing() {
  MonitorLocker ml(monitor_);
  initializing_ = false;
  ml.NotifyAll();
}


Dart_Port KernelIsolate::WaitForKernelPort() {
  if (!FLAG_use_dart_frontend) {
    return ILLEGAL_PORT;
  }
  MonitorLocker ml(monitor_);
  while (initializing_ && (kernel_port_ == ILLEGAL_PORT)) {
    ml.Wait();
  }
  return kernel_port_;
}

#endif  // DART_PRECOMPILED_RUNTIME

}  // namespace dart
