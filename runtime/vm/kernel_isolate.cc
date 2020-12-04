// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/kernel_isolate.h"

#include "include/dart_native_api.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_entry.h"
#include "vm/flags.h"
#include "vm/isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/native_message_handler.h"
#include "vm/object.h"
#include "vm/object_store.h"
#include "vm/port.h"
#include "vm/service.h"
#include "vm/symbols.h"
#include "vm/thread_pool.h"
#include "vm/timeline.h"

#if !defined(DART_PRECOMPILED_RUNTIME)

namespace dart {

#define Z (T->zone())

DEFINE_FLAG(bool, trace_kernel, false, "Trace Kernel service requests.");
DEFINE_FLAG(bool,
            suppress_fe_warnings,
            false,
            "Suppress warnings from the FE.");
DEFINE_FLAG(charp,
            kernel_multiroot_filepaths,
            NULL,
            "Comma-separated list of file paths that should be treated as roots"
            " by frontend compiler.");
DEFINE_FLAG(charp,
            kernel_multiroot_scheme,
            NULL,
            "URI scheme that replaces filepaths prefixes specified"
            " by kernel_multiroot_filepaths option");

// Tags used to indicate different requests to the dart frontend.
//
// Current tags include the following:
//   0 - Perform normal compilation.
//   1 - Update in-memory file system with in-memory sources (used by tests).
//   2 - Accept last compilation result.
//   3 - APP JIT snapshot training run for kernel_service.
//   4 - Compile expressions in context (used by expression evaluation).
//   5 - Generate dependencies used to create a dependencies file.
//   6 - Triggers shutdown of the kernel isolate.
//   7 - Detects the nullability of a script based on it's opt-in status.
const int KernelIsolate::kCompileTag = 0;
const int KernelIsolate::kUpdateSourcesTag = 1;
const int KernelIsolate::kAcceptTag = 2;
const int KernelIsolate::kTrainTag = 3;
const int KernelIsolate::kCompileExpressionTag = 4;
const int KernelIsolate::kListDependenciesTag = 5;
const int KernelIsolate::kNotifyIsolateShutdown = 6;
const int KernelIsolate::kDetectNullabilityTag = 7;

const char* KernelIsolate::kName = DART_KERNEL_ISOLATE_NAME;
Dart_IsolateGroupCreateCallback KernelIsolate::create_group_callback_ = NULL;
Monitor* KernelIsolate::monitor_ = new Monitor();
KernelIsolate::State KernelIsolate::state_ = KernelIsolate::kNotStarted;
Isolate* KernelIsolate::isolate_ = NULL;
Dart_Port KernelIsolate::kernel_port_ = ILLEGAL_PORT;

class RunKernelTask : public ThreadPool::Task {
 public:
  virtual void Run() {
    ASSERT(Isolate::Current() == NULL);
#ifdef SUPPORT_TIMELINE
    TimelineBeginEndScope tbes(Timeline::GetVMStream(), "KernelIsolateStartup");
#endif  // SUPPORT_TIMELINE
    char* error = NULL;
    Isolate* isolate = NULL;

    Dart_IsolateGroupCreateCallback create_group_callback =
        KernelIsolate::create_group_callback();
    ASSERT(create_group_callback != NULL);

    // Note: these flags must match those passed to the VM during
    // the app-jit training run (see //utils/kernel-service/BUILD.gn).
    Dart_IsolateFlags api_flags;
    Isolate::FlagsInitialize(&api_flags);
    api_flags.enable_asserts = false;
    api_flags.is_system_isolate = true;
#if !defined(DART_PRECOMPILER)
    api_flags.use_field_guards = true;
#endif
#if !defined(DART_PRECOMPILER)
    api_flags.use_osr = true;
#endif

    isolate = reinterpret_cast<Isolate*>(
        create_group_callback(KernelIsolate::kName, KernelIsolate::kName, NULL,
                              NULL, &api_flags, NULL, &error));
    if (isolate == NULL) {
      if (FLAG_trace_kernel) {
        OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": Isolate creation error: %s\n",
                     error);
      }
      free(error);
      error = nullptr;
      KernelIsolate::SetKernelIsolate(NULL);
      KernelIsolate::InitializingFailed();
      return;
    }

    bool got_unwind;
    {
      ASSERT(Isolate::Current() == NULL);
      StartIsolateScope start_scope(isolate);
      got_unwind = RunMain(isolate);
    }
    KernelIsolate::FinishedInitializing();

    if (got_unwind) {
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
      OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": ShutdownIsolate\n");
    }
    KernelIsolate::SetLoadPort(ILLEGAL_PORT);
    Dart_EnterIsolate(reinterpret_cast<Dart_Isolate>(parameter));
    {
      auto T = Thread::Current();
      TransitionNativeToVM transition(T);
      StackZone zone(T);
      HandleScope handle_scope(T);

      auto I = T->isolate();
      ASSERT(KernelIsolate::IsKernelIsolate(I));

      // Print the error if there is one.  This may execute dart code to
      // print the exception object, so we need to use a StartIsolateScope.
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
    }
    Dart_ShutdownIsolate();
    if (FLAG_trace_kernel) {
      OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": Shutdown.\n");
    }
    KernelIsolate::FinishedExiting();
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
      OS::PrintErr(DART_KERNEL_ISOLATE_NAME
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
      OS::PrintErr(DART_KERNEL_ISOLATE_NAME
                   ": Embedder did not provide a main function.");
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
        OS::PrintErr(DART_KERNEL_ISOLATE_NAME
                     ": Calling main resulted in an error: %s",
                     error.ToErrorCString());
      }
      if (result.IsUnwindError()) {
        return true;
      }
      return false;
    }
    ASSERT(result.IsReceivePort());
    const ReceivePort& rp = ReceivePort::Cast(result);
    KernelIsolate::SetLoadPort(rp.Id());
    return false;
  }
};

void KernelIsolate::InitializeState() {
  // Grab the isolate create callback here to avoid race conditions with tests
  // that change this after Dart_Initialize returns.
  if (FLAG_trace_kernel) {
    OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": InitializeState\n");
  }
  create_group_callback_ = Isolate::CreateGroupCallback();
  if (create_group_callback_ == NULL) {
    KernelIsolate::InitializingFailed();
    return;
  }
}

bool KernelIsolate::Start() {
  if (create_group_callback_ == nullptr) {
    if (FLAG_trace_kernel) {
      OS::PrintErr(DART_KERNEL_ISOLATE_NAME
                   ": Attempted to start kernel isolate without setting "
                   "Dart_InitializeParams property 'start_kernel_isolate' "
                   "to true\n");
    }
    return false;
  }
  bool start_task = false;
  {
    MonitorLocker ml(monitor_);
    if (state_ == kNotStarted) {
      if (FLAG_trace_kernel) {
        OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": Start\n");
      }
      start_task = true;
      state_ = kStarting;
      ml.NotifyAll();
    }
  }
  bool task_started = true;
  if (start_task) {
    task_started = Dart::thread_pool()->Run<RunKernelTask>();
  }
  return task_started;
}

void KernelIsolate::Shutdown() {
  MonitorLocker ml(monitor_);
  while (state_ == kStarting) {
    ml.Wait();
  }
  if (state_ == kStopped || state_ == kNotStarted) {
    return;
  }
  ASSERT(state_ == kStarted);
  state_ = kStopping;
  ml.NotifyAll();
  Isolate::KillIfExists(isolate_, Isolate::kInternalKillMsg);
  while (state_ != kStopped) {
    ml.Wait();
  }
}

void KernelIsolate::InitCallback(Isolate* I) {
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != NULL);
  if (!NameEquals(I->name())) {
    // Not kernel isolate.
    return;
  }
  ASSERT(!Exists());
  if (FLAG_trace_kernel) {
    OS::PrintErr(DART_KERNEL_ISOLATE_NAME ": InitCallback for %s.\n",
                 I->name());
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

bool KernelIsolate::NameEquals(const char* name) {
  ASSERT(name != NULL);
  return (strcmp(name, DART_KERNEL_ISOLATE_NAME) == 0);
}

bool KernelIsolate::Exists() {
  MonitorLocker ml(monitor_);
  return isolate_ != NULL;
}

void KernelIsolate::SetKernelIsolate(Isolate* isolate) {
  MonitorLocker ml(monitor_);
  if (isolate != nullptr) {
    isolate->set_is_kernel_isolate(true);
  }
  isolate_ = isolate;
  ml.NotifyAll();
}

void KernelIsolate::SetLoadPort(Dart_Port port) {
  MonitorLocker ml(monitor_);
  kernel_port_ = port;
  ml.NotifyAll();
}

void KernelIsolate::FinishedExiting() {
  MonitorLocker ml(monitor_);
  ASSERT(state_ == kStarted || state_ == kStopping);
  state_ = kStopped;
  ml.NotifyAll();
}

void KernelIsolate::FinishedInitializing() {
  MonitorLocker ml(monitor_);
  ASSERT(state_ == kStarting);
  state_ = kStarted;
  ml.NotifyAll();
}

void KernelIsolate::InitializingFailed() {
  MonitorLocker ml(monitor_);
  ASSERT(state_ == kStarting);
  state_ = kStopped;
  ml.NotifyAll();
}

Dart_Port KernelIsolate::WaitForKernelPort() {
  VMTagScope tagScope(Thread::Current(), VMTag::kLoadWaitTagId);
  MonitorLocker ml(monitor_);
  while (state_ == kStarting && (kernel_port_ == ILLEGAL_PORT)) {
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

    if (source_files[i].source != NULL) {
      source_code->type = Dart_CObject_kTypedData;
      source_code->value.as_typed_data.type = Dart_TypedData_kUint8;
      source_code->value.as_typed_data.length = strlen(source_files[i].source);
      source_code->value.as_typed_data.values =
          reinterpret_cast<uint8_t*>(const_cast<char*>(source_files[i].source));
    } else {
      source_code->type = Dart_CObject_kNull;
    }
    fileNamePairs[(i * 2) + 1] = source_code;
  }
  files.value.as_array.values = fileNamePairs;
  return files;
}

static void ReleaseFilesPairs(const Dart_CObject& files) {
  for (intptr_t i = 0; i < files.value.as_array.length; i++) {
    delete files.value.as_array.values[i];
  }
  delete[] files.value.as_array.values;
}

static void PassThroughFinalizer(void* isolate_callback_data, void* peer) {}

MallocGrowableArray<char*>* KernelIsolate::experimental_flags_ =
    new MallocGrowableArray<char*>();

void KernelIsolate::AddExperimentalFlag(const char* value) {
  char* save_ptr;  // Needed for strtok_r.
  char* temp = Utils::StrDup(value);
  char* token = strtok_r(temp, ",", &save_ptr);
  while (token != NULL) {
    experimental_flags_->Add(Utils::StrDup(token));
    token = strtok_r(NULL, ",", &save_ptr);
  }
  free(temp);
}

bool KernelIsolate::GetExperimentalFlag(ExperimentalFeature feature) {
  const char* value = GetExperimentalFeatureName(feature);
  for (const char* str : *experimental_flags_) {
    if (strcmp(str, value) == 0) {
      return true;
    } else if (strstr(str, "no-") == str && strcmp(str + 3, value) == 0) {
      return false;
    }
  }
  return GetExperimentalFeatureDefault(feature);
}

DEFINE_OPTION_HANDLER(KernelIsolate::AddExperimentalFlag,
                      enable_experiment,
                      "Comma separated list of experimental features.");

class KernelCompilationRequest : public ValueObject {
 public:
  KernelCompilationRequest()
      : monitor_(),
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
  }

  intptr_t setDillData(Dart_CObject** dills_array,
                       intptr_t dill_num,
                       const uint8_t* buffer,
                       intptr_t buffer_size) {
    if (buffer != nullptr) {
      dills_array[dill_num] = new Dart_CObject;
      dills_array[dill_num]->type = Dart_CObject_kExternalTypedData;
      dills_array[dill_num]->value.as_external_typed_data.type =
          Dart_TypedData_kUint8;
      dills_array[dill_num]->value.as_external_typed_data.length = buffer_size;
      dills_array[dill_num]->value.as_external_typed_data.data =
          const_cast<uint8_t*>(buffer);
      dills_array[dill_num]->value.as_external_typed_data.peer =
          const_cast<uint8_t*>(buffer);
      dills_array[dill_num]->value.as_external_typed_data.callback =
          PassThroughFinalizer;
      dill_num++;
    }
    return dill_num;
  }

  Dart_KernelCompilationResult SendAndWaitForResponse(
      Dart_Port kernel_port,
      const uint8_t* platform_kernel,
      intptr_t platform_kernel_size,
      const char* expression,
      const Array& definitions,
      const Array& type_definitions,
      char const* library_uri,
      char const* klass,
      bool is_static,
      const MallocGrowableArray<char*>* experimental_flags) {
    Thread* thread = Thread::Current();
    TransitionNativeToVM transition(thread);
    Dart_CObject tag;
    tag.type = Dart_CObject_kInt32;
    tag.value.as_int32 = KernelIsolate::kCompileExpressionTag;

    Dart_CObject send_port;
    send_port.type = Dart_CObject_kSendPort;
    send_port.value.as_send_port.id = port_;
    send_port.value.as_send_port.origin_id = ILLEGAL_PORT;

    Dart_CObject dart_platform_kernel;
    if (platform_kernel != NULL) {
      dart_platform_kernel.type = Dart_CObject_kExternalTypedData;
      dart_platform_kernel.value.as_external_typed_data.type =
          Dart_TypedData_kUint8;
      dart_platform_kernel.value.as_external_typed_data.length =
          platform_kernel_size;
      dart_platform_kernel.value.as_external_typed_data.data =
          const_cast<uint8_t*>(platform_kernel);
      dart_platform_kernel.value.as_external_typed_data.peer =
          const_cast<uint8_t*>(platform_kernel);
      dart_platform_kernel.value.as_external_typed_data.callback =
          PassThroughFinalizer;
    } else {
      // If NULL, the kernel service looks up the platform dill file
      // next to the executable.
      dart_platform_kernel.type = Dart_CObject_kNull;
    }

    Dart_CObject expression_object;
    expression_object.type = Dart_CObject_kString;
    expression_object.value.as_string = const_cast<char*>(expression);

    Dart_CObject definitions_object;
    intptr_t num_definitions = definitions.Length();
    definitions_object.type = Dart_CObject_kArray;
    definitions_object.value.as_array.length = num_definitions;

    Dart_CObject** definitions_array = new Dart_CObject*[num_definitions];
    for (intptr_t i = 0; i < num_definitions; ++i) {
      definitions_array[i] = new Dart_CObject;
      definitions_array[i]->type = Dart_CObject_kString;
      definitions_array[i]->value.as_string = const_cast<char*>(
          String::CheckedHandle(thread->zone(), definitions.At(i)).ToCString());
    }
    definitions_object.value.as_array.values = definitions_array;

    Dart_CObject type_definitions_object;
    intptr_t num_type_definitions = type_definitions.Length();
    type_definitions_object.type = Dart_CObject_kArray;
    type_definitions_object.value.as_array.length = num_type_definitions;

    Dart_CObject** type_definitions_array =
        new Dart_CObject*[num_type_definitions];
    for (intptr_t i = 0; i < num_type_definitions; ++i) {
      type_definitions_array[i] = new Dart_CObject;
      type_definitions_array[i]->type = Dart_CObject_kString;
      type_definitions_array[i]->value.as_string = const_cast<char*>(
          String::CheckedHandle(thread->zone(), type_definitions.At(i))
              .ToCString());
    }
    type_definitions_object.value.as_array.values = type_definitions_array;

    Dart_CObject library_uri_object;
    library_uri_object.type = Dart_CObject_kString;
    library_uri_object.value.as_string = const_cast<char*>(library_uri);

    Dart_CObject class_object;
    if (klass != NULL) {
      class_object.type = Dart_CObject_kString;
      class_object.value.as_string = const_cast<char*>(klass);
    } else {
      class_object.type = Dart_CObject_kNull;
    }

    Dart_CObject is_static_object;
    is_static_object.type = Dart_CObject_kBool;
    is_static_object.value.as_bool = is_static;

    Isolate* isolate =
        Thread::Current() != NULL ? Thread::Current()->isolate() : NULL;
    ASSERT(isolate != NULL);
    Dart_CObject isolate_id;
    isolate_id.type = Dart_CObject_kInt64;
    isolate_id.value.as_int64 =
        isolate != NULL ? static_cast<int64_t>(isolate->main_port()) : 0;

    IsolateGroupSource* source = Isolate::Current()->source();
    intptr_t num_dills = 0;
    if (source->kernel_buffer != nullptr) {
      num_dills++;
    }
    if (source->script_kernel_buffer != nullptr) {
      num_dills++;
    }
    Array& loaded_blobs = Array::Handle();
    if (source->loaded_blobs_ != nullptr) {
      loaded_blobs = source->loaded_blobs_;
      WeakProperty& weak_property = WeakProperty::Handle();
      for (intptr_t i = 0; i < loaded_blobs.Length(); i++) {
        weak_property ^= loaded_blobs.At(i);
        if (weak_property.key() != ExternalTypedData::null()) {
          num_dills++;
        }
      }
    }

    Dart_CObject dills_object;
    dills_object.type = Dart_CObject_kArray;
    dills_object.value.as_array.length = num_dills;

    Dart_CObject** dills_array = new Dart_CObject*[num_dills];
    intptr_t dill_num = 0;
    dill_num = setDillData(dills_array, dill_num, source->kernel_buffer,
                           source->kernel_buffer_size);
    dill_num = setDillData(dills_array, dill_num, source->script_kernel_buffer,
                           source->script_kernel_size);
    if (!loaded_blobs.IsNull()) {
      WeakProperty& weak_property = WeakProperty::Handle();
      for (intptr_t i = 0; i < loaded_blobs.Length(); i++) {
        weak_property ^= loaded_blobs.At(i);
        if (weak_property.key() != ExternalTypedData::null()) {
          ExternalTypedData& externalTypedData = ExternalTypedData::Handle(
              thread->zone(), ExternalTypedData::RawCast(weak_property.key()));
          NoSafepointScope no_safepoint(thread);
          const uint8_t* data = const_cast<uint8_t*>(
              reinterpret_cast<uint8_t*>(externalTypedData.DataAddr(0)));
          dill_num = setDillData(dills_array, dill_num, data,
                                 externalTypedData.Length());
        }
      }
    }
    dills_object.value.as_array.values = dills_array;

    Dart_CObject num_blob_loads;
    num_blob_loads.type = Dart_CObject_kInt64;
    num_blob_loads.value.as_int64 = source->num_blob_loads_;

    Dart_CObject suppress_warnings;
    suppress_warnings.type = Dart_CObject_kBool;
    suppress_warnings.value.as_bool = FLAG_suppress_fe_warnings;

    Dart_CObject enable_asserts;
    enable_asserts.type = Dart_CObject_kBool;
    enable_asserts.value.as_bool =
        isolate != NULL ? isolate->asserts() : FLAG_enable_asserts;

    intptr_t num_experimental_flags = experimental_flags->length();
    Dart_CObject** experimental_flags_array =
        new Dart_CObject*[num_experimental_flags];
    for (intptr_t i = 0; i < num_experimental_flags; ++i) {
      experimental_flags_array[i] = new Dart_CObject;
      experimental_flags_array[i]->type = Dart_CObject_kString;
      experimental_flags_array[i]->value.as_string = (*experimental_flags)[i];
    }
    Dart_CObject experimental_flags_object;
    experimental_flags_object.type = Dart_CObject_kArray;
    experimental_flags_object.value.as_array.values = experimental_flags_array;
    experimental_flags_object.value.as_array.length = num_experimental_flags;

    Dart_CObject message;
    message.type = Dart_CObject_kArray;
    Dart_CObject* message_arr[] = {&tag,
                                   &send_port,
                                   &isolate_id,
                                   &dart_platform_kernel,
                                   &expression_object,
                                   &definitions_object,
                                   &type_definitions_object,
                                   &library_uri_object,
                                   &class_object,
                                   &is_static_object,
                                   &dills_object,
                                   &num_blob_loads,
                                   &suppress_warnings,
                                   &enable_asserts,
                                   &experimental_flags_object};
    message.value.as_array.values = message_arr;
    message.value.as_array.length = ARRAY_SIZE(message_arr);

    {
      TransitionVMToNative transition(thread);

      // Send the message.
      Dart_PostCObject(kernel_port, &message);

      // Wait for reply to arrive.
      VMTagScope tagScope(thread, VMTag::kLoadWaitTagId);
      MonitorLocker ml(&monitor_);
      while (result_.status == Dart_KernelCompilationStatus_Unknown) {
        ml.Wait();
      }
    }

    for (intptr_t i = 0; i < num_definitions; ++i) {
      delete definitions_array[i];
    }
    delete[] definitions_array;

    for (intptr_t i = 0; i < num_type_definitions; ++i) {
      delete type_definitions_array[i];
    }
    delete[] type_definitions_array;

    for (intptr_t i = 0; i < num_dills; ++i) {
      delete dills_array[i];
    }
    delete[] dills_array;

    for (intptr_t i = 0; i < num_experimental_flags; ++i) {
      delete experimental_flags_array[i];
    }
    delete[] experimental_flags_array;

    return result_;
  }

  Dart_KernelCompilationResult SendAndWaitForResponse(
      int request_tag,
      Dart_Port kernel_port,
      const char* script_uri,
      const uint8_t* platform_kernel,
      intptr_t platform_kernel_size,
      int source_files_count,
      Dart_SourceFile source_files[],
      bool incremental_compile,
      const char* package_config,
      const char* multiroot_filepaths,
      const char* multiroot_scheme,
      const MallocGrowableArray<char*>* experimental_flags,
      const char* original_working_directory) {
    // Build the message for the Kernel isolate.
    // tag is used to specify which operation the frontend should perform.
    Dart_CObject tag;
    tag.type = Dart_CObject_kInt32;
    tag.value.as_int32 = request_tag;

    Dart_CObject send_port;
    send_port.type = Dart_CObject_kSendPort;
    send_port.value.as_send_port.id = port_;
    send_port.value.as_send_port.origin_id = ILLEGAL_PORT;

    Dart_CObject uri;
    if (script_uri != NULL) {
      uri.type = Dart_CObject_kString;
      uri.value.as_string = const_cast<char*>(script_uri);
    } else {
      uri.type = Dart_CObject_kNull;
    }

    Dart_CObject dart_platform_kernel;
    if (platform_kernel != NULL) {
      dart_platform_kernel.type = Dart_CObject_kExternalTypedData;
      dart_platform_kernel.value.as_external_typed_data.type =
          Dart_TypedData_kUint8;
      dart_platform_kernel.value.as_external_typed_data.length =
          platform_kernel_size;
      dart_platform_kernel.value.as_external_typed_data.data =
          const_cast<uint8_t*>(platform_kernel);
      dart_platform_kernel.value.as_external_typed_data.peer =
          const_cast<uint8_t*>(platform_kernel);
      dart_platform_kernel.value.as_external_typed_data.callback =
          PassThroughFinalizer;
    } else {
      // If NULL, the kernel service looks up the platform dill file
      // next to the executable.
      dart_platform_kernel.type = Dart_CObject_kNull;
    }

    Dart_CObject dart_incremental;
    dart_incremental.type = Dart_CObject_kBool;
    dart_incremental.value.as_bool = incremental_compile;

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

    Dart_CObject files = BuildFilesPairs(source_files_count, source_files);

    Dart_CObject suppress_warnings;
    suppress_warnings.type = Dart_CObject_kBool;
    suppress_warnings.value.as_bool = FLAG_suppress_fe_warnings;

    Dart_CObject enable_asserts;
    enable_asserts.type = Dart_CObject_kBool;
    enable_asserts.value.as_bool =
        isolate != NULL ? isolate->asserts() : FLAG_enable_asserts;

    Dart_CObject null_safety;
    null_safety.type = Dart_CObject_kInt32;
    null_safety.value.as_int32 =
        (isolate != NULL) ? (isolate->null_safety() ? kNullSafetyOptionStrong
                                                    : kNullSafetyOptionWeak)
                          : FLAG_sound_null_safety;

    intptr_t num_experimental_flags = experimental_flags->length();
    Dart_CObject** experimental_flags_array =
        new Dart_CObject*[num_experimental_flags];
    for (intptr_t i = 0; i < num_experimental_flags; ++i) {
      experimental_flags_array[i] = new Dart_CObject;
      experimental_flags_array[i]->type = Dart_CObject_kString;
      experimental_flags_array[i]->value.as_string = (*experimental_flags)[i];
    }
    Dart_CObject experimental_flags_object;
    experimental_flags_object.type = Dart_CObject_kArray;
    experimental_flags_object.value.as_array.values = experimental_flags_array;
    experimental_flags_object.value.as_array.length = num_experimental_flags;

    Dart_CObject package_config_uri;
    if (package_config != NULL) {
      package_config_uri.type = Dart_CObject_kString;
      package_config_uri.value.as_string = const_cast<char*>(package_config);
    } else {
      package_config_uri.type = Dart_CObject_kNull;
    }

    Dart_CObject multiroot_filepaths_object;
    {
      const char* filepaths = multiroot_filepaths != NULL
                                  ? multiroot_filepaths
                                  : FLAG_kernel_multiroot_filepaths;
      if (filepaths != NULL) {
        multiroot_filepaths_object.type = Dart_CObject_kString;
        multiroot_filepaths_object.value.as_string =
            const_cast<char*>(filepaths);
      } else {
        multiroot_filepaths_object.type = Dart_CObject_kNull;
      }
    }

    Dart_CObject multiroot_scheme_object;
    {
      const char* scheme = multiroot_scheme != NULL
                               ? multiroot_scheme
                               : FLAG_kernel_multiroot_scheme;
      if (scheme != NULL) {
        multiroot_scheme_object.type = Dart_CObject_kString;
        multiroot_scheme_object.value.as_string = const_cast<char*>(scheme);
      } else {
        multiroot_scheme_object.type = Dart_CObject_kNull;
      }
    }

    Dart_CObject original_working_directory_object;
    {
      if (original_working_directory != NULL) {
        original_working_directory_object.type = Dart_CObject_kString;
        original_working_directory_object.value.as_string =
            const_cast<char*>(original_working_directory);
      } else {
        original_working_directory_object.type = Dart_CObject_kNull;
      }
    }

    Dart_CObject* message_arr[] = {&tag,
                                   &send_port,
                                   &uri,
                                   &dart_platform_kernel,
                                   &dart_incremental,
                                   &null_safety,
                                   &isolate_id,
                                   &files,
                                   &suppress_warnings,
                                   &enable_asserts,
                                   &experimental_flags_object,
                                   &package_config_uri,
                                   &multiroot_filepaths_object,
                                   &multiroot_scheme_object,
                                   &original_working_directory_object};
    message.value.as_array.values = message_arr;
    message.value.as_array.length = ARRAY_SIZE(message_arr);
    // Send the message.
    Dart_PostCObject(kernel_port, &message);

    ReleaseFilesPairs(files);

    // Wait for reply to arrive.
    VMTagScope tagScope(Thread::Current(), VMTag::kLoadWaitTagId);
    MonitorLocker ml(&monitor_);
    while (result_.status == Dart_KernelCompilationStatus_Unknown) {
      ml.Wait();
    }

    for (intptr_t i = 0; i < num_experimental_flags; ++i) {
      delete experimental_flags_array[i];
    }
    delete[] experimental_flags_array;

    return result_;
  }

 private:
  void LoadKernelFromResponse(Dart_CObject* response) {
    ASSERT((response->type == Dart_CObject_kTypedData) ||
           (response->type == Dart_CObject_kBool) ||
           (response->type == Dart_CObject_kNull));

    if (response->type == Dart_CObject_kNull) {
      return;
    }
    if (response->type == Dart_CObject_kBool) {
      result_.null_safety = response->value.as_bool;
      return;
    }

    ASSERT(response->value.as_typed_data.type == Dart_TypedData_kUint8);
    result_.kernel_size = response->value.as_typed_data.length;
    result_.kernel = static_cast<uint8_t*>(malloc(result_.kernel_size));
    memmove(result_.kernel, response->value.as_typed_data.values,
            result_.kernel_size);
  }

  // Possible responses from the Kernel isolate:
  //
  //     [Ok, Uint8List KernelBinary]
  //     [Error, String error, Uint8List KernelBinary]
  //     [Crash, String error]
  //
  void HandleResponseImpl(Dart_CObject* message) {
    ASSERT(message->type == Dart_CObject_kArray);
    ASSERT(message->value.as_array.length >= 1);

    Dart_CObject** response = message->value.as_array.values;

    MonitorLocker ml(&monitor_);

    ASSERT(response[0]->type == Dart_CObject_kInt32);
    result_.status = static_cast<Dart_KernelCompilationStatus>(
        message->value.as_array.values[0]->value.as_int32);

    if (result_.status == Dart_KernelCompilationStatus_Ok) {
      LoadKernelFromResponse(response[1]);
    } else {
      if (result_.status == Dart_KernelCompilationStatus_Error) {
        LoadKernelFromResponse(response[2]);
      }
      // This is an error.
      ASSERT(response[1]->type == Dart_CObject_kString);
      result_.error = Utils::StrDup(response[1]->value.as_string);
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

  Monitor monitor_;
  Dart_Port port_;

  // Linked list of active requests. Guarded by requests_monitor_ lock.
  KernelCompilationRequest* next_;
  KernelCompilationRequest* prev_;

  Dart_KernelCompilationResult result_ = {};
};

Monitor* KernelCompilationRequest::requests_monitor_ = new Monitor();
KernelCompilationRequest* KernelCompilationRequest::requests_ = NULL;

Dart_KernelCompilationResult KernelIsolate::CompileToKernel(
    const char* script_uri,
    const uint8_t* platform_kernel,
    intptr_t platform_kernel_size,
    int source_file_count,
    Dart_SourceFile source_files[],
    bool incremental_compile,
    const char* package_config,
    const char* multiroot_filepaths,
    const char* multiroot_scheme) {
  // Start the kernel Isolate if it is not already running.
  if (!Start()) {
    Dart_KernelCompilationResult result = {};
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = Utils::StrDup("Error while starting Kernel isolate task");
    return result;
  }

  // This must be the main script to be loaded. Wait for Kernel isolate
  // to finish initialization.
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    Dart_KernelCompilationResult result = {};
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = Utils::StrDup("Error while initializing Kernel isolate");
    return result;
  }

  KernelCompilationRequest request;
  return request.SendAndWaitForResponse(
      kCompileTag, kernel_port, script_uri, platform_kernel,
      platform_kernel_size, source_file_count, source_files,
      incremental_compile, package_config, multiroot_filepaths,
      multiroot_scheme, experimental_flags_, NULL);
}

bool KernelIsolate::DetectNullSafety(const char* script_uri,
                                     const char* package_config,
                                     const char* original_working_directory) {
  // Start the kernel Isolate if it is not already running.
  if (!Start()) {
    return false;
  }
  // Wait for Kernel isolate to finish initialization.
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    return false;
  }
  KernelCompilationRequest request;
  Dart_KernelCompilationResult result = request.SendAndWaitForResponse(
      kDetectNullabilityTag, kernel_port, script_uri, nullptr, -1, 0, nullptr,
      false, package_config, nullptr, nullptr, experimental_flags_,
      original_working_directory);
  return result.null_safety;
}

Dart_KernelCompilationResult KernelIsolate::ListDependencies() {
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    Dart_KernelCompilationResult result = {};
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = Utils::StrDup("Error while initializing Kernel isolate");
    return result;
  }

  KernelCompilationRequest request;
  return request.SendAndWaitForResponse(kListDependenciesTag, kernel_port, NULL,
                                        NULL, 0, 0, NULL, false, NULL, NULL,
                                        NULL, experimental_flags_, NULL);
}

Dart_KernelCompilationResult KernelIsolate::AcceptCompilation() {
  // This must be the main script to be loaded. Wait for Kernel isolate
  // to finish initialization.
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    Dart_KernelCompilationResult result = {};
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = Utils::StrDup("Error while initializing Kernel isolate");
    return result;
  }

  KernelCompilationRequest request;
  return request.SendAndWaitForResponse(kAcceptTag, kernel_port, NULL, NULL, 0,
                                        0, NULL, true, NULL, NULL, NULL,
                                        experimental_flags_, NULL);
}

Dart_KernelCompilationResult KernelIsolate::CompileExpressionToKernel(
    const uint8_t* platform_kernel,
    intptr_t platform_kernel_size,
    const char* expression,
    const Array& definitions,
    const Array& type_definitions,
    const char* library_url,
    const char* klass,
    bool is_static) {
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    Dart_KernelCompilationResult result = {};
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = Utils::StrDup("Error while initializing Kernel isolate");
    return result;
  }

  TransitionVMToNative transition(Thread::Current());
  KernelCompilationRequest request;
  ASSERT(is_static || (klass != nullptr));
  return request.SendAndWaitForResponse(
      kernel_port, platform_kernel, platform_kernel_size, expression,
      definitions, type_definitions, library_url, klass, is_static,
      experimental_flags_);
}

Dart_KernelCompilationResult KernelIsolate::UpdateInMemorySources(
    int source_files_count,
    Dart_SourceFile source_files[]) {
  // This must be the main script to be loaded. Wait for Kernel isolate
  // to finish initialization.
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    Dart_KernelCompilationResult result = {};
    result.status = Dart_KernelCompilationStatus_Unknown;
    result.error = Utils::StrDup("Error while initializing Kernel isolate");
    return result;
  }

  KernelCompilationRequest request;
  return request.SendAndWaitForResponse(
      kUpdateSourcesTag, kernel_port, NULL, NULL, 0, source_files_count,
      source_files, true, NULL, NULL, NULL, experimental_flags_, NULL);
}

void KernelIsolate::NotifyAboutIsolateShutdown(const Isolate* isolate) {
  if (!KernelIsolate::IsRunning()) {
    return;
  }
  Dart_Port kernel_port = WaitForKernelPort();
  if (kernel_port == ILLEGAL_PORT) {
    return;
  }

  Dart_CObject tag;
  tag.type = Dart_CObject_kInt32;
  tag.value.as_int32 = KernelIsolate::kNotifyIsolateShutdown;

  Dart_CObject isolate_id;
  isolate_id.type = Dart_CObject_kInt64;
  isolate_id.value.as_int64 =
      isolate != NULL ? static_cast<int64_t>(isolate->main_port()) : 0;

  Dart_CObject message;
  message.type = Dart_CObject_kArray;
  Dart_CObject* message_arr[] = {&tag, &isolate_id};
  message.value.as_array.values = message_arr;
  message.value.as_array.length = ARRAY_SIZE(message_arr);
  // Send the message.
  Dart_PostCObject(kernel_port, &message);
}

}  // namespace dart

#endif  // !defined(DART_PRECOMPILED_RUNTIME)
