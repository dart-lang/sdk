// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_isolate.h"

#include "bin/dartutils.h"
#include "include/dart_native_api.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
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
            show_kernel_isolate,
            false,
            "Show Kernel service isolate as normal isolate.");

const char* KernelIsolate::kName = DART_KERNEL_ISOLATE_NAME;
Dart_IsolateCreateCallback KernelIsolate::create_callback_ = NULL;
Monitor* KernelIsolate::monitor_ = new Monitor();
Isolate* KernelIsolate::isolate_ = NULL;
bool KernelIsolate::initializing_ = true;
Dart_Port KernelIsolate::kernel_port_ = ILLEGAL_PORT;

class RunKernelTask : public ThreadPool::Task {
 public:
  virtual void Run() {
    ASSERT(Isolate::Current() == NULL);
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

    // Note: these flags must match those passed to the VM during
    // the app-jit training run (see //utils/kernel-service/BUILD.gn).
    Dart_IsolateFlags api_flags;
    Isolate::FlagsInitialize(&api_flags);
    api_flags.enable_type_checks = false;
    api_flags.enable_asserts = false;
    api_flags.enable_error_on_bad_type = false;
    api_flags.enable_error_on_bad_override = false;
    api_flags.reify_generic_functions = false;
    api_flags.strong = false;
#if !defined(DART_PRECOMPILER)
    api_flags.use_field_guards = true;
    api_flags.use_osr = true;
#endif

    isolate = reinterpret_cast<Isolate*>(create_callback(
        KernelIsolate::kName, NULL, NULL, NULL, &api_flags, NULL, &error));
    if (isolate == NULL) {
      OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": Isolate creation error: %s\n",
                   error);
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
      OS::Print(DART_KERNEL_ISOLATE_NAME ": ShutdownIsolate\n");
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
        OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": Error: %s\n",
                     error.ToErrorCString());
      }
      error = I->sticky_error();
      if (!error.IsNull() && !error.IsUnwindError()) {
        OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": Error: %s\n",
                     error.ToErrorCString());
      }
      Dart::RunShutdownCallback();
    }
    // Shut the isolate down.
    Dart::ShutdownIsolate(I);
    if (FLAG_trace_kernel) {
      OS::Print(DART_KERNEL_ISOLATE_NAME ": Shutdown.\n");
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
      OS::Print(DART_KERNEL_ISOLATE_NAME
                ": Embedder did not install a script.");
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
      OS::Print(DART_KERNEL_ISOLATE_NAME
                ": Embedder did not provide a main function.");
      return false;
    }
    ASSERT(!entry.IsNull());
    const Object& result = Object::Handle(
        Z, DartEntry::InvokeFunction(entry, Object::empty_array()));
    ASSERT(!result.IsNull());
    if (result.IsError()) {
      // Kernel isolate did not initialize properly.
      const Error& error = Error::Cast(result);
      OS::Print(DART_KERNEL_ISOLATE_NAME
                ": Calling main resulted in an error: %s",
                error.ToErrorCString());
      return false;
    }
    ASSERT(result.IsReceivePort());
    const ReceivePort& rp = ReceivePort::Cast(result);
    KernelIsolate::SetLoadPort(rp.Id());
    return true;
  }
};

void KernelIsolate::Run() {
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
  if (strcmp(I->name(), DART_KERNEL_ISOLATE_NAME) != 0) {
    // Not kernel isolate.
    return;
  }
  ASSERT(!Exists());
  if (FLAG_trace_kernel) {
    OS::Print(DART_KERNEL_ISOLATE_NAME ": InitCallback for %s.\n", I->name());
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
  MonitorLocker ml(monitor_);
  while (initializing_ && (kernel_port_ == ILLEGAL_PORT)) {
    ml.Wait();
  }
  return kernel_port_;
}

static Dart_CObject BuildFilesPairs(int source_files_count,
                                    Dart_SourceFile source_files[]) {
  Dart_CObject files;
  files.type = Dart_CObject_kArray;
  files.value.as_array.length = source_files_count * 2;
  // typedef Dart_CObject* Dart_CObjectPtr;
  Dart_CObject** fileNamePairs = new Dart_CObject*[source_files_count * 2];
  for (int i = 0; i < source_files_count; i++) {
    Dart_CObject* source_uri = new Dart_CObject();
    source_uri->type = Dart_CObject_kString;
    source_uri->value.as_string = const_cast<char*>(source_files[i].uri);
    fileNamePairs[i * 2] = source_uri;

    Dart_CObject* source_code = new Dart_CObject();
    source_code->type = Dart_CObject_kTypedData;
    source_code->value.as_typed_data.type = Dart_TypedData_kUint8;
    source_code->value.as_typed_data.length = strlen(source_files[i].source);
    source_code->value.as_typed_data.values =
        reinterpret_cast<uint8_t*>(const_cast<char*>(source_files[i].source));
    fileNamePairs[(i * 2) + 1] = source_code;
  }
  files.value.as_array.values = fileNamePairs;
  return files;
}

class KernelCompilationRequest : public ValueObject {
 public:
  KernelCompilationRequest()
      : monitor_(new Monitor()),
        port_(Dart_NewNativePort("kernel-compilation-port",
                                 &HandleResponse,
                                 false)),
        next_(NULL),
        prev_(NULL) {
    ASSERT(port_ != ILLEGAL_PORT);
    RegisterRequest(this);
    result_.status = Dart_KernelCompilationStatus_Unknown;
    result_.error = NULL;
    result_.kernel = NULL;
    result_.kernel_size = 0;
  }

  ~KernelCompilationRequest() {
    UnregisterRequest(this);
    Dart_CloseNativePort(port_);
    delete monitor_;
  }

  Dart_KernelCompilationResult SendAndWaitForResponse(
      Dart_Port kernel_port,
      const char* script_uri,
      const char* platform_kernel,
      int source_files_count,
      Dart_SourceFile source_files[],
      bool incremental_compile) {
    // Build the [null, send_port, script_uri, platform_kernel,
    // incremental_compile, isolate_id, [files]] message for the Kernel isolate.
    // null tag tells it that request came from this code, instead of Loader
    // so that it can given a more informative response.
    Dart_CObject tag;
    tag.type = Dart_CObject_kNull;

    Dart_CObject send_port;
    send_port.type = Dart_CObject_kSendPort;
    send_port.value.as_send_port.id = port_;
    send_port.value.as_send_port.origin_id = ILLEGAL_PORT;

    Dart_CObject uri;
    uri.type = Dart_CObject_kString;
    uri.value.as_string = const_cast<char*>(script_uri);

    Dart_CObject dart_platform_kernel;
    if (platform_kernel != NULL) {
      dart_platform_kernel.type = Dart_CObject_kString;
      dart_platform_kernel.value.as_string = const_cast<char*>(platform_kernel);
    } else {
      dart_platform_kernel.type = Dart_CObject_kNull;
    }

    Dart_CObject dart_incremental;
    dart_incremental.type = Dart_CObject_kBool;
    dart_incremental.value.as_bool = incremental_compile;

    Dart_CObject dart_strong;
    dart_strong.type = Dart_CObject_kBool;
    dart_strong.value.as_bool = FLAG_strong;

    // TODO(aam): Assert that isolate exists once we move CompileAndReadScript
    // compilation logic out of CreateIsolateAndSetupHelper and into
    // IsolateSetupHelper in main.cc.
    Isolate* isolate =
        Thread::Current() != NULL ? Thread::Current()->isolate() : NULL;
    if (incremental_compile) {
      ASSERT(isolate != NULL);
    }
    Dart_CObject isolate_id;
    isolate_id.type = Dart_CObject_kInt64;
    isolate_id.value.as_int64 =
        isolate != NULL ? static_cast<int64_t>(isolate->main_port()) : 0;

    Dart_CObject message;
    message.type = Dart_CObject_kArray;

    Dart_CObject files;
    if (source_files_count != 0) {
      files = BuildFilesPairs(source_files_count, source_files);
    } else {
      files.type = Dart_CObject_kNull;
    }
    Dart_CObject* message_arr[] = {&tag,
                                   &send_port,
                                   &uri,
                                   &dart_platform_kernel,
                                   &dart_incremental,
                                   &dart_strong,
                                   &isolate_id,
                                   &files};
    message.value.as_array.values = message_arr;
    message.value.as_array.length = ARRAY_SIZE(message_arr);
    // Send the message.
    Dart_PostCObject(kernel_port, &message);

    // Wait for reply to arrive.
    MonitorLocker ml(monitor_);
    while (result_.status == Dart_KernelCompilationStatus_Unknown) {
      ml.Wait();
    }

    return result_;
  }

 private:
  // Possible responses from the Kernel isolate:
  //
  //     [Ok, Uint8List KernelBinary]
  //     [Error, String error]
  //     [Crash, String error]
  //
  void HandleResponseImpl(Dart_CObject* message) {
    ASSERT(message->type == Dart_CObject_kArray);
    ASSERT(message->value.as_array.length >= 1);

    Dart_CObject** response = message->value.as_array.values;

    MonitorLocker ml(monitor_);

    ASSERT(response[0]->type == Dart_CObject_kInt32);
    result_.status = static_cast<Dart_KernelCompilationStatus>(
        message->value.as_array.values[0]->value.as_int32);

    if (result_.status == Dart_KernelCompilationStatus_Ok) {
      ASSERT(response[1]->type == Dart_CObject_kTypedData);
      ASSERT(response[1]->value.as_typed_data.type == Dart_TypedData_kUint8);

      result_.kernel_size = response[1]->value.as_typed_data.length;
      result_.kernel = static_cast<uint8_t*>(malloc(result_.kernel_size));
      memmove(result_.kernel, response[1]->value.as_typed_data.values,
              result_.kernel_size);
    } else {
      ASSERT(result_.status == Dart_KernelCompilationStatus_Crash ||
             result_.status == Dart_KernelCompilationStatus_Error);
      // This is an error.
      ASSERT(response[1]->type == Dart_CObject_kString);
      result_.error = strdup(response[1]->value.as_string);
    }
    ml.Notify();
  }

  static void HandleResponse(Dart_Port port, Dart_CObject* message) {
    MonitorLocker locker(requests_monitor_);
    KernelCompilationRequest* rq = FindRequestLocked(port);
    if (rq == NULL) {
      return;
    }
    rq->HandleResponseImpl(message);
  }

  static void RegisterRequest(KernelCompilationRequest* rq) {
    MonitorLocker locker(requests_monitor_);
    rq->next_ = requests_;
    if (requests_ != NULL) {
      requests_->prev_ = rq;
    }
    requests_ = rq;
  }

  static void UnregisterRequest(KernelCompilationRequest* rq) {
    MonitorLocker locker(requests_monitor_);
    if (rq->next_ != NULL) {
      rq->next_->prev_ = rq->prev_;
    }
    if (rq->prev_ != NULL) {
      rq->prev_->next_ = rq->next_;
    } else {
      requests_ = rq->next_;
    }
  }

  // Note: Caller must hold requests_monitor_.
  static KernelCompilationRequest* FindRequestLocked(Dart_Port port) {
    for (KernelCompilationRequest* rq = requests_; rq != NULL; rq = rq->next_) {
      if (rq->port_ == port) {
        return rq;
      }
    }
    return NULL;
  }

  // This monitor must be held whenever linked list of requests is accessed.
  static Monitor* requests_monitor_;

  // Linked list of all active requests. Used to find a request by port number.
  // Guarded by requests_monitor_ lock.
  static KernelCompilationRequest* requests_;

  Monitor* monitor_;
  Dart_Port port_;

  // Linked list of active requests. Guarded by requests_monitor_ lock.
  KernelCompilationRequest* next_;
  KernelCompilationRequest* prev_;

  Dart_KernelCompilationResult result_;
};

Monitor* KernelCompilationRequest::requests_monitor_ = new Monitor();
KernelCompilationRequest* KernelCompilationRequest::requests_ = NULL;

Dart_KernelCompilationResult KernelIsolate::CompileToKernel(
    const char* script_uri,
    const char* platform_kernel,
    int source_file_count,
    Dart_SourceFile source_files[],
    bool incremental_compile) {
  // This must be the main script to be loaded. Wait for Kernel isolate
  // to finish initialization.
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    Dart_KernelCompilationResult result;
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = strdup("Error while initializing Kernel isolate");
    return result;
  }

  KernelCompilationRequest request;
  return request.SendAndWaitForResponse(kernel_port, script_uri,
                                        platform_kernel, source_file_count,
                                        source_files, incremental_compile);
}

#endif  // DART_PRECOMPILED_RUNTIME

}  // namespace dart
