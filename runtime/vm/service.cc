// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/service.h"

#include <memory>
#include <utility>

#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/globals.h"

#include "platform/unicode.h"
#include "platform/utils.h"
#include "vm/base64.h"
#include "vm/canonical_tables.h"
#include "vm/closure_functions_cache.h"
#include "vm/compiler/jit/compiler.h"
#include "vm/cpu.h"
#include "vm/dart_api_impl.h"
#include "vm/dart_api_message.h"
#include "vm/dart_api_state.h"
#include "vm/dart_entry.h"
#include "vm/debugger.h"
#include "vm/heap/safepoint.h"
#include "vm/isolate.h"
#include "vm/kernel_isolate.h"
#include "vm/lockers.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/native_arguments.h"
#include "vm/native_entry.h"
#include "vm/native_symbol.h"
#include "vm/object.h"
#include "vm/object_graph.h"
#include "vm/object_id_ring.h"
#include "vm/object_store.h"
#include "vm/parser.h"
#include "vm/port.h"
#include "vm/profiler.h"
#include "vm/profiler_service.h"
#include "vm/raw_object_fields.h"
#include "vm/resolver.h"
#include "vm/reusable_handles.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/source_report.h"
#include "vm/stack_frame.h"
#include "vm/symbols.h"
#include "vm/timeline.h"
#include "vm/version.h"

#if defined(SUPPORT_PERFETTO)
#include "vm/perfetto_utils.h"
#endif  // defined(SUPPORT_PERFETTO)

namespace dart {

#define Z (T->zone())

DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, trace_service_pause_events);
DECLARE_FLAG(bool, profile_vm);
DEFINE_FLAG(charp,
            vm_name,
            "vm",
            "The default name of this vm as reported by the VM service "
            "protocol");

DEFINE_FLAG(bool,
            warn_on_pause_with_no_debugger,
            false,
            "Print a message when an isolate is paused but there is no "
            "debugger attached.");

DEFINE_FLAG(
    charp,
    log_service_response_sizes,
    nullptr,
    "Log sizes of service responses and events to a file in CSV format.");

void* Service::service_response_size_log_file_ = nullptr;

void Service::LogResponseSize(const char* method, JSONStream* js) {
  if (service_response_size_log_file_ == nullptr) {
    return;
  }
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  char* entry =
      OS::SCreate(nullptr, "%s, %" Pd "\n", method, js->buffer()->length());
  (*file_write)(entry, strlen(entry), service_response_size_log_file_);
  free(entry);
}

void Service::Init() {
  if (FLAG_log_service_response_sizes == nullptr) {
    return;
  }
  Dart_FileOpenCallback file_open = Dart::file_open_callback();
  Dart_FileWriteCallback file_write = Dart::file_write_callback();
  Dart_FileCloseCallback file_close = Dart::file_close_callback();
  if ((file_open == nullptr) || (file_write == nullptr) ||
      (file_close == nullptr)) {
    OS::PrintErr("Error: Could not access file callbacks.");
    UNREACHABLE();
  }
  ASSERT(service_response_size_log_file_ == nullptr);
  service_response_size_log_file_ =
      (*file_open)(FLAG_log_service_response_sizes, true);
  if (service_response_size_log_file_ == nullptr) {
    OS::PrintErr("Warning: Failed to open service response size log file: %s\n",
                 FLAG_log_service_response_sizes);
    return;
  }
}

void Service::Cleanup() {
  if (service_response_size_log_file_ == nullptr) {
    return;
  }
  Dart_FileCloseCallback file_close = Dart::file_close_callback();
  (*file_close)(service_response_size_log_file_);
  service_response_size_log_file_ = nullptr;
}

static void PrintInvalidParamError(JSONStream* js, const char* param) {
#if !defined(PRODUCT)
  js->PrintError(kInvalidParams, "%s: invalid '%s' parameter: %s", js->method(),
                 param, js->LookupParam(param));
#endif
}

// TODO(johnmccutchan): Split into separate file and write unit tests.
class MethodParameter {
 public:
  MethodParameter(const char* name, bool required)
      : name_(name), required_(required) {}

  virtual ~MethodParameter() {}

  virtual bool Validate(const char* value) const { return true; }

  virtual bool ValidateObject(const Object& value) const { return true; }

  const char* name() const { return name_; }

  bool required() const { return required_; }

  virtual void PrintError(const char* name,
                          const char* value,
                          JSONStream* js) const {
    PrintInvalidParamError(js, name);
  }

  virtual void PrintErrorObject(const char* name,
                                const Object& value,
                                JSONStream* js) const {
    PrintInvalidParamError(js, name);
  }

 private:
  const char* name_;
  bool required_;
};

class NoSuchParameter : public MethodParameter {
 public:
  explicit NoSuchParameter(const char* name) : MethodParameter(name, false) {}

  virtual bool Validate(const char* value) const { return (value == nullptr); }

  virtual bool ValidateObject(const Object& value) const {
    return value.IsNull();
  }
};

#define ISOLATE_PARAMETER new IdParameter("isolateId", true)
#define ISOLATE_GROUP_PARAMETER new IdParameter("isolateGroupId", true)
#define NO_ISOLATE_PARAMETER new NoSuchParameter("isolateId")
#define RUNNABLE_ISOLATE_PARAMETER new RunnableIsolateParameter("isolateId")
#define OBJECT_PARAMETER new IdParameter("objectId", true)

class EnumListParameter : public MethodParameter {
 public:
  EnumListParameter(const char* name, bool required, const char* const* enums)
      : MethodParameter(name, required), enums_(enums) {}

  virtual bool Validate(const char* value) const {
    return ElementCount(value) >= 0;
  }

  const char** Parse(char* value) const {
    const char* kJsonChars = " \t\r\n[,]";

    // Make a writeable copy of the value.
    intptr_t element_count = ElementCount(value);
    if (element_count < 0) {
      return nullptr;
    }
    intptr_t element_pos = 0;

    // Allocate our element array.  +1 for nullptr terminator.
    // The caller is responsible for deleting this memory.
    char** elements = new char*[element_count + 1];
    elements[element_count] = nullptr;

    // Parse the string destructively.  Build the list of elements.
    while (element_pos < element_count) {
      // Skip to the next element.
      value += strspn(value, kJsonChars);

      intptr_t len = strcspn(value, kJsonChars);
      ASSERT(len > 0);  // We rely on the parameter being validated already.
      value[len] = '\0';
      elements[element_pos++] = value;

      // Advance.  +1 for null terminator.
      value += (len + 1);
    }
    return const_cast<const char**>(elements);
  }

 private:
  // For now observatory enums are ascii letters plus underscore.
  static bool IsEnumChar(char c) {
    return (((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z')) ||
            (c == '_'));
  }

  // Returns number of elements in the list.  -1 on parse error.
  intptr_t ElementCount(const char* value) const {
    const char* kJsonWhitespaceChars = " \t\r\n";
    if (value == nullptr) {
      return -1;
    }
    const char* cp = value;
    cp += strspn(cp, kJsonWhitespaceChars);
    if (*cp++ != '[') {
      // Missing initial [.
      return -1;
    }
    bool closed = false;
    bool element_allowed = true;
    intptr_t element_count = 0;
    while (true) {
      // Skip json whitespace.
      cp += strspn(cp, kJsonWhitespaceChars);
      switch (*cp) {
        case '\0':
          return closed ? element_count : -1;
        case ']':
          closed = true;
          cp++;
          break;
        case ',':
          if (element_allowed) {
            return -1;
          }
          element_allowed = true;
          cp++;
          break;
        default:
          if (!element_allowed) {
            return -1;
          }
          bool valid_enum = false;
          const char* id_start = cp;
          while (IsEnumChar(*cp)) {
            cp++;
          }
          if (cp == id_start) {
            // Empty identifier, something like this [,].
            return -1;
          }
          intptr_t id_len = cp - id_start;
          if (enums_ != nullptr) {
            for (intptr_t i = 0; enums_[i] != nullptr; i++) {
              intptr_t len = strlen(enums_[i]);
              if (len == id_len && strncmp(id_start, enums_[i], len) == 0) {
                element_count++;
                valid_enum = true;
                element_allowed = false;  // we need a comma first.
                break;
              }
            }
          }
          if (!valid_enum) {
            return -1;
          }
          break;
      }
    }
  }

  const char* const* enums_;
};

#if defined(SUPPORT_TIMELINE)
static const char* const timeline_streams_enum_names[] = {
    "all",
#define DEFINE_NAME(name, ...) #name,
    TIMELINE_STREAM_LIST(DEFINE_NAME)
#undef DEFINE_NAME
        nullptr};

static const MethodParameter* const set_vm_timeline_flags_params[] = {
    NO_ISOLATE_PARAMETER,
    new EnumListParameter("recordedStreams",
                          false,
                          timeline_streams_enum_names),
    nullptr,
};

static bool HasStream(const char** recorded_streams, const char* stream) {
  while (*recorded_streams != nullptr) {
    if ((strstr(*recorded_streams, "all") != nullptr) ||
        (strstr(*recorded_streams, stream) != nullptr)) {
      return true;
    }
    recorded_streams++;
  }
  return false;
}

bool Service::EnableTimelineStreams(char* categories_list) {
  const EnumListParameter* recorded_streams_param =
      static_cast<const EnumListParameter*>(set_vm_timeline_flags_params[1]);
  const char** streams = recorded_streams_param->Parse(categories_list);
  if (streams == nullptr) {
    return false;
  }

#define SET_ENABLE_STREAM(name, ...)                                           \
  Timeline::SetStream##name##Enabled(HasStream(streams, #name));
  TIMELINE_STREAM_LIST(SET_ENABLE_STREAM);
#undef SET_ENABLE_STREAM

  delete[] streams;

#if !defined(PRODUCT)
  // Notify clients that the set of subscribed streams has been updated.
  if (Service::timeline_stream.enabled()) {
    ServiceEvent event(ServiceEvent::kTimelineStreamSubscriptionsUpdate);
    Service::HandleEvent(&event);
  }
#endif

  return true;
}
#endif  // defined(SUPPORT_TIMELINE)

#ifndef PRODUCT
// The name of this of this vm as reported by the VM service protocol.
static char* vm_name = nullptr;

static const char* GetVMName() {
  if (vm_name == nullptr) {
    return FLAG_vm_name;
  }
  return vm_name;
}

ServiceIdZone::ServiceIdZone() {}

ServiceIdZone::~ServiceIdZone() {}

RingServiceIdZone::RingServiceIdZone()
    : ring_(nullptr), policy_(ObjectIdRing::kAllocateId) {}

RingServiceIdZone::~RingServiceIdZone() {}

void RingServiceIdZone::Init(ObjectIdRing* ring,
                             ObjectIdRing::IdPolicy policy) {
  ring_ = ring;
  policy_ = policy;
}

char* RingServiceIdZone::GetServiceId(const Object& obj) {
  ASSERT(ring_ != nullptr);
  Thread* thread = Thread::Current();
  Zone* zone = thread->zone();
  ASSERT(zone != nullptr);
  const intptr_t id = ring_->GetIdForObject(obj.ptr(), policy_);
  return zone->PrintToString("objects/%" Pd "", id);
}

// TODO(johnmccutchan): Unify embedder service handler lists and their APIs.
EmbedderServiceHandler* Service::isolate_service_handler_head_ = nullptr;
EmbedderServiceHandler* Service::root_service_handler_head_ = nullptr;
struct ServiceMethodDescriptor;
const ServiceMethodDescriptor* FindMethod(const char* method_name);

// Support for streams defined in embedders.
Dart_ServiceStreamListenCallback Service::stream_listen_callback_ = nullptr;
Dart_ServiceStreamCancelCallback Service::stream_cancel_callback_ = nullptr;
Dart_GetVMServiceAssetsArchive Service::get_service_assets_callback_ = nullptr;
Dart_EmbedderInformationCallback Service::embedder_information_callback_ =
    nullptr;

// These are the set of streams known to the core VM.
StreamInfo Service::vm_stream("VM");
StreamInfo Service::isolate_stream("Isolate");
StreamInfo Service::debug_stream("Debug");
StreamInfo Service::gc_stream("GC");
StreamInfo Service::echo_stream("_Echo");
StreamInfo Service::heapsnapshot_stream("HeapSnapshot");
StreamInfo Service::logging_stream("Logging");
StreamInfo Service::extension_stream("Extension");
StreamInfo Service::timeline_stream("Timeline");
StreamInfo Service::profiler_stream("Profiler");

const uint8_t* Service::dart_library_kernel_ = nullptr;
intptr_t Service::dart_library_kernel_len_ = 0;

// Keep streams_ in sync with the protected streams in
// lib/developer/extension.dart
static StreamInfo* const streams_[] = {
    &Service::vm_stream,       &Service::isolate_stream,
    &Service::debug_stream,    &Service::gc_stream,
    &Service::echo_stream,     &Service::heapsnapshot_stream,
    &Service::logging_stream,  &Service::extension_stream,
    &Service::timeline_stream, &Service::profiler_stream,
};

bool Service::ListenStream(const char* stream_id,
                           bool include_private_members) {
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: starting stream '%s'\n", stream_id);
  }
  intptr_t num_streams = sizeof(streams_) / sizeof(streams_[0]);
  for (intptr_t i = 0; i < num_streams; i++) {
    if (strcmp(stream_id, streams_[i]->id()) == 0) {
      streams_[i]->set_enabled(true);
      streams_[i]->set_include_private_members(include_private_members);
      return true;
    }
  }
  if (stream_listen_callback_ != nullptr) {
    Thread* T = Thread::Current();
    TransitionVMToNative transition(T);
    return (*stream_listen_callback_)(stream_id);
  }
  return false;
}

void Service::CancelStream(const char* stream_id) {
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: stopping stream '%s'\n", stream_id);
  }
  intptr_t num_streams = sizeof(streams_) / sizeof(streams_[0]);
  for (intptr_t i = 0; i < num_streams; i++) {
    if (strcmp(stream_id, streams_[i]->id()) == 0) {
      streams_[i]->set_enabled(false);
      return;
    }
  }
  if (stream_cancel_callback_ != nullptr) {
    Thread* T = Thread::Current();
    TransitionVMToNative transition(T);
    return (*stream_cancel_callback_)(stream_id);
  }
}

ObjectPtr Service::RequestAssets() {
  Thread* T = Thread::Current();
  Object& object = Object::Handle();
  {
    Api::Scope api_scope(T);
    Dart_Handle handle;
    {
      TransitionVMToNative transition(T);
      if (get_service_assets_callback_ == nullptr) {
        return Object::null();
      }
      handle = get_service_assets_callback_();
      if (Dart_IsError(handle)) {
        Dart_PropagateError(handle);
      }
    }
    object = Api::UnwrapHandle(handle);
  }
  if (object.IsNull()) {
    return Object::null();
  }
  if (!object.IsTypedData()) {
    const String& error_message = String::Handle(
        String::New("An implementation of Dart_GetVMServiceAssetsArchive "
                    "should return a Uint8Array or null."));
    const Error& error = Error::Handle(ApiError::New(error_message));
    Exceptions::PropagateError(error);
    return Object::null();
  }
  const TypedData& typed_data = TypedData::Cast(object);
  if (typed_data.ElementSizeInBytes() != 1) {
    const String& error_message = String::Handle(
        String::New("An implementation of Dart_GetVMServiceAssetsArchive "
                    "should return a Uint8Array or null."));
    const Error& error = Error::Handle(ApiError::New(error_message));
    Exceptions::PropagateError(error);
    return Object::null();
  }
  return object.ptr();
}

static void PrintSuccess(JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Success");
}

static bool CheckDebuggerDisabled(Thread* thread, JSONStream* js) {
#if defined(DART_PRECOMPILED_RUNTIME)
  js->PrintError(kFeatureDisabled, "Debugger is disabled in AOT mode.");
  return true;
#else
  if (thread->isolate()->debugger() == nullptr) {
    js->PrintError(kFeatureDisabled, "Debugger is disabled.");
    return true;
  }
  return false;
#endif
}

static bool CheckCompilerDisabled(Thread* thread, JSONStream* js) {
#if defined(DART_PRECOMPILED_RUNTIME)
  js->PrintError(kFeatureDisabled, "Compiler is disabled in AOT mode.");
  return true;
#else
  return false;
#endif
}

static bool CheckProfilerDisabled(Thread* thread, JSONStream* js) {
  if (!FLAG_profiler) {
    js->PrintError(kFeatureDisabled, "Profiler is disabled.");
    return true;
  }
  return false;
}

static bool GetIntegerId(const char* s, intptr_t* id, int base = 10) {
  if ((s == nullptr) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if (id == nullptr) {
    // No id pointer.
    return false;
  }
  intptr_t r = 0;
  char* end_ptr = nullptr;
#if defined(ARCH_IS_32_BIT)
  r = strtol(s, &end_ptr, base);
#else
  r = strtoll(s, &end_ptr, base);
#endif
  if (end_ptr == s) {
    // String was not advanced at all, cannot be valid.
    return false;
  }
  *id = r;
  return true;
}

static bool GetUnsignedIntegerId(const char* s, uintptr_t* id, int base = 10) {
  if ((s == nullptr) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if (id == nullptr) {
    // No id pointer.
    return false;
  }
  uintptr_t r = 0;
  char* end_ptr = nullptr;
#if defined(ARCH_IS_32_BIT)
  r = strtoul(s, &end_ptr, base);
#else
  r = strtoull(s, &end_ptr, base);
#endif
  if (end_ptr == s) {
    // String was not advanced at all, cannot be valid.
    return false;
  }
  *id = r;
  return true;
}

static bool GetInteger64Id(const char* s, int64_t* id, int base = 10) {
  if ((s == nullptr) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if (id == nullptr) {
    // No id pointer.
    return false;
  }
  int64_t r = 0;
  char* end_ptr = nullptr;
  r = strtoll(s, &end_ptr, base);
  if (end_ptr == s) {
    // String was not advanced at all, cannot be valid.
    return false;
  }
  *id = r;
  return true;
}

// Scans the string until the '-' character. Returns pointer to string
// at '-' character. Returns nullptr if not found.
static const char* ScanUntilDash(const char* s) {
  if ((s == nullptr) || (*s == '\0')) {
    // Empty string.
    return nullptr;
  }
  while (*s != '\0') {
    if (*s == '-') {
      return s;
    }
    s++;
  }
  return nullptr;
}

static bool GetCodeId(const char* s, int64_t* timestamp, uword* address) {
  if ((s == nullptr) || (*s == '\0')) {
    // Empty string.
    return false;
  }
  if ((timestamp == nullptr) || (address == nullptr)) {
    // Bad arguments.
    return false;
  }
  // Extract the timestamp.
  if (!GetInteger64Id(s, timestamp, 16) || (*timestamp < 0)) {
    return false;
  }
  s = ScanUntilDash(s);
  if (s == nullptr) {
    return false;
  }
  // Skip the dash.
  s++;
  // Extract the PC.
  if (!GetUnsignedIntegerId(s, address, 16)) {
    return false;
  }
  return true;
}

// Verifies that |s| begins with |prefix| and then calls |GetIntegerId| on
// the remainder of |s|.
static bool GetPrefixedIntegerId(const char* s,
                                 const char* prefix,
                                 intptr_t* service_id) {
  if (s == nullptr) {
    return false;
  }
  ASSERT(prefix != nullptr);
  const intptr_t kInputLen = strlen(s);
  const intptr_t kPrefixLen = strlen(prefix);
  ASSERT(kPrefixLen > 0);
  if (kInputLen <= kPrefixLen) {
    return false;
  }
  if (strncmp(s, prefix, kPrefixLen) != 0) {
    return false;
  }
  // Prefix satisfied. Move forward.
  s += kPrefixLen;
  // Attempt to read integer id.
  return GetIntegerId(s, service_id);
}

static bool IsValidClassId(Isolate* isolate, intptr_t cid) {
  ASSERT(isolate != nullptr);
  ClassTable* class_table = isolate->group()->class_table();
  ASSERT(class_table != nullptr);
  return class_table->IsValidIndex(cid) && class_table->HasValidClassAt(cid);
}

static ClassPtr GetClassForId(Isolate* isolate, intptr_t cid) {
  ASSERT(isolate == Isolate::Current());
  ASSERT(isolate != nullptr);
  ClassTable* class_table = isolate->group()->class_table();
  ASSERT(class_table != nullptr);
  return class_table->At(cid);
}

class DartStringParameter : public MethodParameter {
 public:
  DartStringParameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool ValidateObject(const Object& value) const {
    return value.IsString();
  }
};

class DartListParameter : public MethodParameter {
 public:
  DartListParameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool ValidateObject(const Object& value) const {
    return value.IsArray() || value.IsGrowableObjectArray();
  }
};

class BoolParameter : public MethodParameter {
 public:
  BoolParameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool Validate(const char* value) const {
    if (value == nullptr) {
      return false;
    }
    return (strcmp("true", value) == 0) || (strcmp("false", value) == 0);
  }

  static bool Parse(const char* value, bool default_value = false) {
    if (value == nullptr) {
      return default_value;
    }
    return strcmp("true", value) == 0;
  }
};

class UIntParameter : public MethodParameter {
 public:
  UIntParameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool Validate(const char* value) const {
    if (value == nullptr) {
      return false;
    }
    for (const char* cp = value; *cp != '\0'; cp++) {
      if (*cp < '0' || *cp > '9') {
        return false;
      }
    }
    return true;
  }

  static uintptr_t Parse(const char* value) {
    if (value == nullptr) {
      return -1;
    }
    char* end_ptr = nullptr;
    uintptr_t result = strtoul(value, &end_ptr, 10);
    ASSERT(*end_ptr == '\0');  // Parsed full string
    return result;
  }
};

class Int64Parameter : public MethodParameter {
 public:
  Int64Parameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool Validate(const char* value) const {
    if (value == nullptr) {
      return false;
    }
    for (const char* cp = value; *cp != '\0'; cp++) {
      if ((*cp < '0' || *cp > '9') && (*cp != '-')) {
        return false;
      }
    }
    return true;
  }

  static int64_t Parse(const char* value, int64_t default_value = -1) {
    if ((value == nullptr) || (*value == '\0')) {
      return default_value;
    }
    char* end_ptr = nullptr;
    int64_t result = strtoll(value, &end_ptr, 10);
    ASSERT(*end_ptr == '\0');  // Parsed full string
    return result;
  }
};

class UInt64Parameter : public MethodParameter {
 public:
  UInt64Parameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool Validate(const char* value) const {
    if (value == nullptr) {
      return false;
    }
    for (const char* cp = value; *cp != '\0'; cp++) {
      if ((*cp < '0' || *cp > '9') && (*cp != '-')) {
        return false;
      }
    }
    return true;
  }

  static uint64_t Parse(const char* value, uint64_t default_value = 0) {
    if ((value == nullptr) || (*value == '\0')) {
      return default_value;
    }
    char* end_ptr = nullptr;
    uint64_t result = strtoull(value, &end_ptr, 10);
    ASSERT(*end_ptr == '\0');  // Parsed full string
    return result;
  }
};

class IdParameter : public MethodParameter {
 public:
  IdParameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool Validate(const char* value) const { return (value != nullptr); }
};

class StringParameter : public MethodParameter {
 public:
  StringParameter(const char* name, bool required)
      : MethodParameter(name, required) {}

  virtual bool Validate(const char* value) const { return (value != nullptr); }
};

class RunnableIsolateParameter : public MethodParameter {
 public:
  explicit RunnableIsolateParameter(const char* name)
      : MethodParameter(name, true) {}

  virtual bool Validate(const char* value) const {
    Isolate* isolate = Isolate::Current();
    return (value != nullptr) && (isolate != nullptr) &&
           (isolate->is_runnable());
  }

  virtual void PrintError(const char* name,
                          const char* value,
                          JSONStream* js) const {
    js->PrintError(kIsolateMustBeRunnable,
                   "Isolate must be runnable before this request is made.");
  }
};

class EnumParameter : public MethodParameter {
 public:
  EnumParameter(const char* name, bool required, const char* const* enums)
      : MethodParameter(name, required), enums_(enums) {}

  virtual bool Validate(const char* value) const {
    if (value == nullptr) {
      return true;
    }
    for (intptr_t i = 0; enums_[i] != nullptr; i++) {
      if (strcmp(value, enums_[i]) == 0) {
        return true;
      }
    }
    return false;
  }

 private:
  const char* const* enums_;
};

// If the key is not found, this function returns the last element in the
// values array. This can be used to encode the default value.
template <typename T>
T EnumMapper(const char* value, const char* const* enums, T* values) {
  ASSERT(value != nullptr);
  intptr_t i = 0;
  for (i = 0; enums[i] != nullptr; i++) {
    if (strcmp(value, enums[i]) == 0) {
      return values[i];
    }
  }
  // Default value.
  return values[i];
}

typedef void (*ServiceMethodEntry)(Thread* thread, JSONStream* js);

struct ServiceMethodDescriptor {
  const char* name;
  const ServiceMethodEntry entry;
  const MethodParameter* const* parameters;
};

static void PrintMissingParamError(JSONStream* js, const char* param) {
  js->PrintError(kInvalidParams, "%s expects the '%s' parameter", js->method(),
                 param);
}

static void PrintUnrecognizedMethodError(JSONStream* js) {
  js->PrintError(kMethodNotFound, nullptr);
}

// TODO(johnmccutchan): Do we reject unexpected parameters?
static bool ValidateParameters(const MethodParameter* const* parameters,
                               JSONStream* js) {
  if (parameters == nullptr) {
    return true;
  }
  if (js->NumObjectParameters() > 0) {
    Object& value = Object::Handle();
    for (intptr_t i = 0; parameters[i] != nullptr; i++) {
      const MethodParameter* parameter = parameters[i];
      const char* name = parameter->name();
      const bool required = parameter->required();
      value = js->LookupObjectParam(name);
      const bool has_parameter = !value.IsNull();
      if (required && !has_parameter) {
        PrintMissingParamError(js, name);
        return false;
      }
      if (has_parameter && !parameter->ValidateObject(value)) {
        parameter->PrintErrorObject(name, value, js);
        return false;
      }
    }
  } else {
    for (intptr_t i = 0; parameters[i] != nullptr; i++) {
      const MethodParameter* parameter = parameters[i];
      const char* name = parameter->name();
      const bool required = parameter->required();
      const char* value = js->LookupParam(name);
      const bool has_parameter = (value != nullptr);
      if (required && !has_parameter) {
        PrintMissingParamError(js, name);
        return false;
      }
      if (has_parameter && !parameter->Validate(value)) {
        parameter->PrintError(name, value, js);
        return false;
      }
    }
  }
  return true;
}

void Service::PostError(const String& method_name,
                        const Array& parameter_keys,
                        const Array& parameter_values,
                        const Instance& reply_port,
                        const Instance& id,
                        const Error& error) {
  Thread* T = Thread::Current();
  StackZone zone(T);
  JSONStream js;
  js.Setup(zone.GetZone(), SendPort::Cast(reply_port).Id(), id, method_name,
           parameter_keys, parameter_values);
  js.PrintError(kExtensionError, "Error in extension `%s`: %s", js.method(),
                error.ToErrorCString());
  js.PostReply();
}

ErrorPtr Service::InvokeMethod(Isolate* I,
                               const Array& msg,
                               bool parameters_are_dart_objects) {
  Thread* T = Thread::Current();
  ASSERT(I == T->isolate());
  ASSERT(I != nullptr);
  ASSERT(T->execution_state() == Thread::kThreadInVM);
  ASSERT(!msg.IsNull());
  ASSERT(msg.Length() == 6);

  {
    StackZone zone(T);

    Instance& reply_port = Instance::Handle(Z);
    Instance& seq = String::Handle(Z);
    String& method_name = String::Handle(Z);
    Array& param_keys = Array::Handle(Z);
    Array& param_values = Array::Handle(Z);
    reply_port ^= msg.At(1);
    seq ^= msg.At(2);
    method_name ^= msg.At(3);
    param_keys ^= msg.At(4);
    param_values ^= msg.At(5);

    ASSERT(!method_name.IsNull());
    ASSERT(seq.IsNull() || seq.IsString() || seq.IsNumber());
    ASSERT(!param_keys.IsNull());
    ASSERT(!param_values.IsNull());
    ASSERT(param_keys.Length() == param_values.Length());

    // We expect a reply port unless there is a null sequence id,
    // which indicates that no reply should be sent.  We use this in
    // tests.
    if (!seq.IsNull() && !reply_port.IsSendPort()) {
      FATAL("SendPort expected.");
    }

    JSONStream js;
    Dart_Port reply_port_id =
        (reply_port.IsNull() ? ILLEGAL_PORT : SendPort::Cast(reply_port).Id());
    js.Setup(zone.GetZone(), reply_port_id, seq, method_name, param_keys,
             param_values, parameters_are_dart_objects);

    // RPC came in with a custom service id zone.
    const char* id_zone_param = js.LookupParam("_idZone");

    if (id_zone_param != nullptr) {
      // Override id zone.
      if (strcmp("default", id_zone_param) == 0) {
        // Ring with eager id allocation. This is the default ring and default
        // policy.
        // Nothing to do.
      } else if (strcmp("default.reuse", id_zone_param) == 0) {
        // Change the default ring's policy.
        RingServiceIdZone* zone =
            reinterpret_cast<RingServiceIdZone*>(js.id_zone());
        zone->set_policy(ObjectIdRing::kReuseId);
      } else {
        // TODO(johnmccutchan): Support creating, deleting, and selecting
        // custom service id zones.
        // For now, always return an error.
        PrintInvalidParamError(&js, "_idZone");
        js.PostReply();
        return T->StealStickyError();
      }
    }
    const char* c_method_name = method_name.ToCString();

    const ServiceMethodDescriptor* method = FindMethod(c_method_name);
    if (method != nullptr) {
      if (!ValidateParameters(method->parameters, &js)) {
        js.PostReply();
        return T->StealStickyError();
      }
      method->entry(T, &js);
      Service::LogResponseSize(c_method_name, &js);
      js.PostReply();
      return T->StealStickyError();
    }

    EmbedderServiceHandler* handler = FindIsolateEmbedderHandler(c_method_name);
    if (handler == nullptr) {
      handler = FindRootEmbedderHandler(c_method_name);
    }

    if (handler != nullptr) {
      EmbedderHandleMessage(handler, &js);
      return T->StealStickyError();
    }

    const Instance& extension_handler =
        Instance::Handle(Z, I->LookupServiceExtensionHandler(method_name));
    if (!extension_handler.IsNull()) {
      ScheduleExtensionHandler(extension_handler, method_name, param_keys,
                               param_values, reply_port, seq);
      // Schedule was successful. Extension code will post a reply
      // asynchronously.
      return T->StealStickyError();
    }

    PrintUnrecognizedMethodError(&js);
    js.PostReply();
    return T->StealStickyError();
  }
}

ErrorPtr Service::HandleRootMessage(const Array& msg_instance) {
  Isolate* isolate = Isolate::Current();
  return InvokeMethod(isolate, msg_instance);
}

ErrorPtr Service::HandleObjectRootMessage(const Array& msg_instance) {
  Isolate* isolate = Isolate::Current();
  return InvokeMethod(isolate, msg_instance, true);
}

ErrorPtr Service::HandleIsolateMessage(Isolate* isolate, const Array& msg) {
  ASSERT(isolate != nullptr);
  const Error& error = Error::Handle(InvokeMethod(isolate, msg));
  return MaybePause(isolate, error);
}

static void Finalizer(void* isolate_callback_data, void* buffer) {
  free(buffer);
}

void Service::SendEvent(const char* stream_id,
                        const char* event_type,
                        uint8_t* bytes,
                        intptr_t bytes_length) {
  Thread* thread = Thread::Current();
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != nullptr);

  if (FLAG_trace_service) {
    OS::PrintErr(
        "vm-service: Pushing ServiceEvent(isolate='%s', "
        "isolateId='" ISOLATE_SERVICE_ID_FORMAT_STRING
        "', kind='%s',"
        " len=%" Pd ") to stream %s\n",
        isolate->name(), static_cast<int64_t>(isolate->main_port()), event_type,
        bytes_length, stream_id);
  }

  bool result;
  {
    Dart_CObject cbytes;
    cbytes.type = Dart_CObject_kExternalTypedData;
    cbytes.value.as_external_typed_data.type = Dart_TypedData_kUint8;
    cbytes.value.as_external_typed_data.length = bytes_length;
    cbytes.value.as_external_typed_data.data = bytes;
    cbytes.value.as_external_typed_data.peer = bytes;
    cbytes.value.as_external_typed_data.callback = Finalizer;

    Dart_CObject cstream_id;
    cstream_id.type = Dart_CObject_kString;
    cstream_id.value.as_string = const_cast<char*>(stream_id);

    Dart_CObject* elements[2];
    elements[0] = &cstream_id;
    elements[1] = &cbytes;
    Dart_CObject message;
    message.type = Dart_CObject_kArray;
    message.value.as_array.length = 2;
    message.value.as_array.values = elements;

    std::unique_ptr<Message> msg =
        WriteApiMessage(thread->zone(), &message, ServiceIsolate::Port(),
                        Message::kNormalPriority);
    if (msg == nullptr) {
      result = false;
    } else {
      result = PortMap::PostMessage(std::move(msg));
    }
  }

  if (!result) {
    free(bytes);
  }
}

void Service::SendEventWithData(const char* stream_id,
                                const char* event_type,
                                intptr_t reservation,
                                const char* metadata,
                                intptr_t metadata_size,
                                uint8_t* data,
                                intptr_t data_size) {
  ASSERT(kInt32Size + metadata_size <= reservation);
  // Using a SPACE creates valid JSON. Our goal here is to prevent the memory
  // overhead of copying to concatenate metadata and payload together by
  // over-allocating to underlying buffer before we know how long the metadata
  // will be.
  memset(data, ' ', reservation);
  reinterpret_cast<uint32_t*>(data)[0] = reservation;
  memmove(&(reinterpret_cast<uint32_t*>(data)[1]), metadata, metadata_size);
  Service::SendEvent(stream_id, event_type, data, data_size);
}

static void ReportPauseOnConsole(ServiceEvent* event) {
  const char* name = event->isolate()->name();
  const int64_t main_port = static_cast<int64_t>(event->isolate()->main_port());
  switch (event->kind()) {
    case ServiceEvent::kPauseStart:
      OS::PrintErr("vm-service: isolate(%" Pd64
                   ") '%s' has no debugger attached and is paused at start.",
                   main_port, name);
      break;
    case ServiceEvent::kPauseExit:
      OS::PrintErr("vm-service: isolate(%" Pd64
                   ")  '%s' has no debugger attached and is paused at exit.",
                   main_port, name);
      break;
    case ServiceEvent::kPauseException:
      OS::PrintErr(
          "vm-service: isolate (%" Pd64
          ") '%s' has no debugger attached and is paused due to exception.",
          main_port, name);
      break;
    case ServiceEvent::kPauseInterrupted:
      OS::PrintErr(
          "vm-service: isolate (%" Pd64
          ") '%s' has no debugger attached and is paused due to interrupt.",
          main_port, name);
      break;
    case ServiceEvent::kPauseBreakpoint:
      OS::PrintErr("vm-service: isolate (%" Pd64
                   ") '%s' has no debugger attached and is paused.",
                   main_port, name);
      break;
    case ServiceEvent::kPausePostRequest:
      OS::PrintErr("vm-service: isolate (%" Pd64
                   ") '%s' has no debugger attached and is paused post reload.",
                   main_port, name);
      break;
    default:
      UNREACHABLE();
      break;
  }
  if (!ServiceIsolate::IsRunning()) {
    OS::PrintErr("  Start the vm-service to debug.\n");
  } else if (ServiceIsolate::server_address() == nullptr) {
    OS::PrintErr("  Connect to the Dart VM service to debug.\n");
  } else {
    OS::PrintErr("  Connect to the Dart VM service at %s to debug.\n",
                 ServiceIsolate::server_address());
  }
  const Error& err = Error::Handle(Thread::Current()->sticky_error());
  if (!err.IsNull()) {
    OS::PrintErr("%s\n", err.ToErrorCString());
  }
}

void Service::HandleEvent(ServiceEvent* event, bool enter_safepoint) {
  if (event->stream_info() != nullptr && !event->stream_info()->enabled()) {
    if (FLAG_warn_on_pause_with_no_debugger && event->IsPause()) {
      // If we are about to pause a running program which has no
      // debugger connected, tell the user about it.
      ReportPauseOnConsole(event);
    }
    // Ignore events when no one is listening to the event stream.
    return;
  } else if (event->stream_info() != nullptr &&
             FLAG_warn_on_pause_with_no_debugger && event->IsPause()) {
    ReportPauseOnConsole(event);
  }
  if (!ServiceIsolate::IsRunning()) {
    return;
  }
  JSONStream js;
  if (event->stream_info() != nullptr) {
    js.set_include_private_members(
        event->stream_info()->include_private_members());
  }
  const char* stream_id = event->stream_id();
  ASSERT(stream_id != nullptr);
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("jsonrpc", "2.0");
    jsobj.AddProperty("method", "streamNotify");
    JSONObject params(&jsobj, "params");
    params.AddProperty("streamId", stream_id);
    params.AddProperty("event", event);
  }
  PostEvent(event->isolate_group(), event->isolate(), stream_id,
            event->KindAsCString(), &js, enter_safepoint);
}

void Service::PostEvent(IsolateGroup* isolate_group,
                        Isolate* isolate,
                        const char* stream_id,
                        const char* kind,
                        JSONStream* event,
                        bool enter_safepoint) {
  if (enter_safepoint) {
    // Enter a safepoint so we don't block the mutator while processing
    // large events.
    TransitionToNative transition(Thread::Current());
    PostEventImpl(isolate_group, isolate, stream_id, kind, event);
    return;
  }
  PostEventImpl(isolate_group, isolate, stream_id, kind, event);
}

void Service::PostEventImpl(IsolateGroup* isolate_group,
                            Isolate* isolate,
                            const char* stream_id,
                            const char* kind,
                            JSONStream* event) {
  ASSERT(stream_id != nullptr);
  ASSERT(kind != nullptr);
  ASSERT(event != nullptr);

  if (FLAG_trace_service) {
    if (isolate != nullptr) {
      ASSERT(isolate_group != nullptr);
      OS::PrintErr(
          "vm-service: Pushing "
          "ServiceEvent(isolateGroupId='" ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING
          "', isolate='%s', isolateId='" ISOLATE_SERVICE_ID_FORMAT_STRING
          "', kind='%s') to stream %s\n",
          isolate_group->id(), isolate->name(),
          static_cast<int64_t>(isolate->main_port()), kind, stream_id);
    } else if (isolate_group != nullptr) {
      OS::PrintErr(
          "vm-service: Pushing "
          "ServiceEvent(isolateGroupId='" ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING
          "', kind='%s') to stream %s\n",
          isolate_group->id(), kind, stream_id);
    } else {
      OS::PrintErr(
          "vm-service: Pushing ServiceEvent(isolate='<no current isolate>', "
          "kind='%s') to stream %s\n",
          kind, stream_id);
    }
  }

  Service::LogResponseSize(kind, event);

  // Message is of the format [<stream id>, <json string>].
  //
  // Build the event message in the C heap to avoid dart heap
  // allocation.  This method can be called while we have acquired a
  // direct pointer to typed data, so we can't allocate here.
  Dart_CObject list_cobj;
  Dart_CObject* list_values[2];
  list_cobj.type = Dart_CObject_kArray;
  list_cobj.value.as_array.length = 2;
  list_cobj.value.as_array.values = list_values;

  Dart_CObject stream_id_cobj;
  stream_id_cobj.type = Dart_CObject_kString;
  stream_id_cobj.value.as_string = const_cast<char*>(stream_id);
  list_values[0] = &stream_id_cobj;

  Dart_CObject json_cobj;
  json_cobj.type = Dart_CObject_kString;
  json_cobj.value.as_string = const_cast<char*>(event->ToCString());
  list_values[1] = &json_cobj;

  AllocOnlyStackZone zone;
  std::unique_ptr<Message> msg =
      WriteApiMessage(zone.GetZone(), &list_cobj, ServiceIsolate::Port(),
                      Message::kNormalPriority);
  if (msg != nullptr) {
    PortMap::PostMessage(std::move(msg));
  }
}

class EmbedderServiceHandler {
 public:
  explicit EmbedderServiceHandler(const char* name)
      : name_(nullptr),
        callback_(nullptr),
        user_data_(nullptr),
        next_(nullptr) {
    ASSERT(name != nullptr);
    name_ = Utils::StrDup(name);
  }

  ~EmbedderServiceHandler() { free(name_); }

  const char* name() const { return name_; }

  Dart_ServiceRequestCallback callback() const { return callback_; }
  void set_callback(Dart_ServiceRequestCallback callback) {
    callback_ = callback;
  }

  void* user_data() const { return user_data_; }
  void set_user_data(void* user_data) { user_data_ = user_data; }

  EmbedderServiceHandler* next() const { return next_; }
  void set_next(EmbedderServiceHandler* next) { next_ = next; }

 private:
  char* name_;
  Dart_ServiceRequestCallback callback_;
  void* user_data_;
  EmbedderServiceHandler* next_;
};

void Service::EmbedderHandleMessage(EmbedderServiceHandler* handler,
                                    JSONStream* js) {
  ASSERT(handler != nullptr);
  Dart_ServiceRequestCallback callback = handler->callback();
  ASSERT(callback != nullptr);
  const char* response = nullptr;
  bool success;
  {
    TransitionVMToNative transition(Thread::Current());
    success = callback(js->method(), js->param_keys(), js->param_values(),
                       js->num_params(), handler->user_data(), &response);
  }
  ASSERT(response != nullptr);
  if (!success) {
    js->SetupError();
  }
  js->buffer()->AddString(response);
  js->PostReply();
  free(const_cast<char*>(response));
}

void Service::RegisterIsolateEmbedderCallback(
    const char* name,
    Dart_ServiceRequestCallback callback,
    void* user_data) {
  if (name == nullptr) {
    return;
  }
  EmbedderServiceHandler* handler = FindIsolateEmbedderHandler(name);
  if (handler != nullptr) {
    // Update existing handler entry.
    handler->set_callback(callback);
    handler->set_user_data(user_data);
    return;
  }
  // Create a new handler.
  handler = new EmbedderServiceHandler(name);
  handler->set_callback(callback);
  handler->set_user_data(user_data);

  // Insert into isolate_service_handler_head_ list.
  handler->set_next(isolate_service_handler_head_);
  isolate_service_handler_head_ = handler;
}

EmbedderServiceHandler* Service::FindIsolateEmbedderHandler(const char* name) {
  EmbedderServiceHandler* current = isolate_service_handler_head_;
  while (current != nullptr) {
    if (strcmp(name, current->name()) == 0) {
      return current;
    }
    current = current->next();
  }
  return nullptr;
}

void Service::RegisterRootEmbedderCallback(const char* name,
                                           Dart_ServiceRequestCallback callback,
                                           void* user_data) {
  if (name == nullptr) {
    return;
  }
  EmbedderServiceHandler* handler = FindRootEmbedderHandler(name);
  if (handler != nullptr) {
    // Update existing handler entry.
    handler->set_callback(callback);
    handler->set_user_data(user_data);
    return;
  }
  // Create a new handler.
  handler = new EmbedderServiceHandler(name);
  handler->set_callback(callback);
  handler->set_user_data(user_data);

  // Insert into root_service_handler_head_ list.
  handler->set_next(root_service_handler_head_);
  root_service_handler_head_ = handler;
}

void Service::SetEmbedderStreamCallbacks(
    Dart_ServiceStreamListenCallback listen_callback,
    Dart_ServiceStreamCancelCallback cancel_callback) {
  stream_listen_callback_ = listen_callback;
  stream_cancel_callback_ = cancel_callback;
}

void Service::SetGetServiceAssetsCallback(
    Dart_GetVMServiceAssetsArchive get_service_assets) {
  get_service_assets_callback_ = get_service_assets;
}

void Service::SetEmbedderInformationCallback(
    Dart_EmbedderInformationCallback callback) {
  embedder_information_callback_ = callback;
}

int64_t Service::CurrentRSS() {
  if (embedder_information_callback_ == nullptr) {
    return -1;
  }
  Dart_EmbedderInformation info = {
      0,        // version
      nullptr,  // name
      0,        // max_rss
      0         // current_rss
  };
  embedder_information_callback_(&info);
  ASSERT(info.version == DART_EMBEDDER_INFORMATION_CURRENT_VERSION);
  return info.current_rss;
}

int64_t Service::MaxRSS() {
  if (embedder_information_callback_ == nullptr) {
    return -1;
  }
  Dart_EmbedderInformation info = {
      0,        // version
      nullptr,  // name
      0,        // max_rss
      0         // current_rss
  };
  embedder_information_callback_(&info);
  ASSERT(info.version == DART_EMBEDDER_INFORMATION_CURRENT_VERSION);
  return info.max_rss;
}

void Service::SetDartLibraryKernelForSources(const uint8_t* kernel_bytes,
                                             intptr_t kernel_length) {
  dart_library_kernel_ = kernel_bytes;
  dart_library_kernel_len_ = kernel_length;
}

EmbedderServiceHandler* Service::FindRootEmbedderHandler(const char* name) {
  EmbedderServiceHandler* current = root_service_handler_head_;
  while (current != nullptr) {
    if (strcmp(name, current->name()) == 0) {
      return current;
    }
    current = current->next();
  }
  return nullptr;
}

void Service::ScheduleExtensionHandler(const Instance& handler,
                                       const String& method_name,
                                       const Array& parameter_keys,
                                       const Array& parameter_values,
                                       const Instance& reply_port,
                                       const Instance& id) {
  ASSERT(!handler.IsNull());
  ASSERT(!method_name.IsNull());
  ASSERT(!parameter_keys.IsNull());
  ASSERT(!parameter_values.IsNull());
  ASSERT(!reply_port.IsNull());
  Isolate* isolate = Isolate::Current();
  ASSERT(isolate != nullptr);
  isolate->AppendServiceExtensionCall(handler, method_name, parameter_keys,
                                      parameter_values, reply_port, id);
}

static const MethodParameter* const get_isolate_params[] = {
    ISOLATE_PARAMETER,
    nullptr,
};

static void GetIsolate(Thread* thread, JSONStream* js) {
  thread->isolate()->PrintJSON(js, false);
}

static const MethodParameter* const get_isolate_group_params[] = {
    ISOLATE_GROUP_PARAMETER,
    nullptr,
};

enum SentinelType {
  kCollectedSentinel,
  kExpiredSentinel,
  kFreeSentinel,
};

static void PrintSentinel(JSONStream* js, SentinelType sentinel_type) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Sentinel");
  switch (sentinel_type) {
    case kCollectedSentinel:
      jsobj.AddProperty("kind", "Collected");
      jsobj.AddProperty("valueAsString", "<collected>");
      break;
    case kExpiredSentinel:
      jsobj.AddProperty("kind", "Expired");
      jsobj.AddProperty("valueAsString", "<expired>");
      break;
    case kFreeSentinel:
      jsobj.AddProperty("kind", "Free");
      jsobj.AddProperty("valueAsString", "<free>");
      break;
    default:
      UNIMPLEMENTED();
      break;
  }
}

static const MethodParameter* const
    set_stream_include_private_members_params[] = {
        NO_ISOLATE_PARAMETER,
        new BoolParameter("includePrivateMembers", true),
        nullptr,
};

static void SetStreamIncludePrivateMembers(Thread* thread, JSONStream* js) {
  const char* stream_id = js->LookupParam("streamId");
  if (stream_id == nullptr) {
    PrintMissingParamError(js, "streamId");
    return;
  }
  bool include_private_members =
      BoolParameter::Parse(js->LookupParam("includePrivateMembers"), false);
  intptr_t num_streams = sizeof(streams_) / sizeof(streams_[0]);
  for (intptr_t i = 0; i < num_streams; i++) {
    if (strcmp(stream_id, streams_[i]->id()) == 0) {
      streams_[i]->set_include_private_members(include_private_members);
      break;
    }
  }
  PrintSuccess(js);
}

static void ActOnIsolateGroup(JSONStream* js,
                              std::function<void(IsolateGroup*)> visitor) {
  const String& prefix =
      String::Handle(String::New(ISOLATE_GROUP_SERVICE_ID_PREFIX));

  const String& s =
      String::Handle(String::New(js->LookupParam("isolateGroupId")));
  if (!s.StartsWith(prefix)) {
    PrintInvalidParamError(js, "isolateGroupId");
    return;
  }
  uint64_t isolate_group_id = UInt64Parameter::Parse(
      String::Handle(String::SubString(s, prefix.Length())).ToCString());
  IsolateGroup::RunWithIsolateGroup(
      isolate_group_id,
      [&visitor](IsolateGroup* isolate_group) { visitor(isolate_group); },
      /*if_not_found=*/[&js]() { PrintSentinel(js, kExpiredSentinel); });
}

static void GetIsolateGroup(Thread* thread, JSONStream* js) {
  ActOnIsolateGroup(js, [&](IsolateGroup* isolate_group) {
    isolate_group->PrintJSON(js, false);
  });
}

static const MethodParameter* const get_memory_usage_params[] = {
    ISOLATE_PARAMETER,
    nullptr,
};

static void GetMemoryUsage(Thread* thread, JSONStream* js) {
  thread->isolate()->PrintMemoryUsageJSON(js);
}

static const MethodParameter* const get_isolate_group_memory_usage_params[] = {
    ISOLATE_GROUP_PARAMETER,
    nullptr,
};

static void GetIsolateGroupMemoryUsage(Thread* thread, JSONStream* js) {
  ActOnIsolateGroup(js, [&](IsolateGroup* isolate_group) {
    isolate_group->PrintMemoryUsageJSON(js);
  });
}

static const MethodParameter* const get_isolate_pause_event_params[] = {
    ISOLATE_PARAMETER,
    nullptr,
};

static void GetIsolatePauseEvent(Thread* thread, JSONStream* js) {
  thread->isolate()->PrintPauseEventJSON(js);
}

static const MethodParameter* const get_scripts_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetScripts(Thread* thread, JSONStream* js) {
  auto object_store = thread->isolate_group()->object_store();
  Zone* zone = thread->zone();

  const auto& libs =
      GrowableObjectArray::Handle(zone, object_store->libraries());
  intptr_t num_libs = libs.Length();

  Library& lib = Library::Handle(zone);
  Array& scripts = Array::Handle(zone);
  Script& script = Script::Handle(zone);

  JSONObject jsobj(js);
  {
    jsobj.AddProperty("type", "ScriptList");
    JSONArray script_array(&jsobj, "scripts");
    for (intptr_t i = 0; i < num_libs; i++) {
      lib ^= libs.At(i);
      ASSERT(!lib.IsNull());
      scripts = lib.LoadedScripts();
      for (intptr_t j = 0; j < scripts.Length(); j++) {
        script ^= scripts.At(j);
        ASSERT(!script.IsNull());
        script_array.AddValue(script);
      }
    }
  }
}

static const MethodParameter* const get_stack_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new UIntParameter("limit", false),
    nullptr,
};

static void GetStack(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }
  intptr_t limit = 0;
  bool has_limit = js->HasParam("limit");
  if (has_limit) {
    limit = UIntParameter::Parse(js->LookupParam("limit"));
    if (limit < 0) {
      PrintInvalidParamError(js, "limit");
      return;
    }
  }
  Isolate* isolate = thread->isolate();
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  DebuggerStackTrace* async_awaiter_stack =
      isolate->debugger()->AsyncAwaiterStackTrace();

  // Do we want the complete script object and complete local variable objects?
  // This is true for dump requests.
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Stack");
  {
    JSONArray jsarr(&jsobj, "frames");

    intptr_t num_frames =
        has_limit ? Utils::Minimum(stack->Length(), limit) : stack->Length();

    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = stack->FrameAt(i);
      JSONObject jsobj(&jsarr);
      frame->PrintToJSONObject(&jsobj);
      jsobj.AddProperty("index", i);
    }
  }

  if (async_awaiter_stack != nullptr) {
    JSONArray jsarr(&jsobj, "asyncCausalFrames");
    intptr_t num_frames =
        has_limit ? Utils::Minimum(async_awaiter_stack->Length(), limit)
                  : async_awaiter_stack->Length();
    for (intptr_t i = 0; i < num_frames; i++) {
      ActivationFrame* frame = async_awaiter_stack->FrameAt(i);
      JSONObject jsobj(&jsarr);
      frame->PrintToJSONObject(&jsobj);
      jsobj.AddProperty("index", i);
    }
  }

  const bool truncated =
      (has_limit &&
       (limit < stack->Length() || (async_awaiter_stack != nullptr &&
                                    limit < async_awaiter_stack->Length())));
  jsobj.AddProperty("truncated", truncated);

  {
    MessageHandler::AcquiredQueues aq(isolate->message_handler());
    jsobj.AddProperty("messages", aq.queue());
  }
}

static void HandleCommonEcho(JSONObject* jsobj, JSONStream* js) {
  jsobj->AddProperty("type", "_EchoResponse");
  if (js->HasParam("text")) {
    jsobj->AddProperty("text", js->LookupParam("text"));
  }
}

void Service::SendEchoEvent(Isolate* isolate, const char* text) {
  JSONStream js;
  {
    JSONObject jsobj(&js);
    jsobj.AddProperty("jsonrpc", "2.0");
    jsobj.AddProperty("method", "streamNotify");
    {
      JSONObject params(&jsobj, "params");
      params.AddProperty("streamId", echo_stream.id());
      {
        JSONObject event(&params, "event");
        event.AddProperty("type", "Event");
        event.AddProperty("kind", "_Echo");
        event.AddProperty("isolate", isolate);
        if (text != nullptr) {
          event.AddProperty("text", text);
        }
        event.AddPropertyTimeMillis("timestamp", OS::GetCurrentTimeMillis());
      }
    }
  }

  intptr_t reservation = js.buffer()->length() + sizeof(int32_t);
  intptr_t data_size = reservation + 3;
  uint8_t* data = reinterpret_cast<uint8_t*>(malloc(data_size));
  data[reservation + 0] = 0;
  data[reservation + 1] = 128;
  data[reservation + 2] = 255;
  SendEventWithData(echo_stream.id(), "_Echo", reservation,
                    js.buffer()->buffer(), js.buffer()->length(), data,
                    data_size);
}

static void TriggerEchoEvent(Thread* thread, JSONStream* js) {
  if (Service::echo_stream.enabled()) {
    Service::SendEchoEvent(thread->isolate(), js->LookupParam("text"));
  }
  JSONObject jsobj(js);
  HandleCommonEcho(&jsobj, js);
}

static void Echo(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  HandleCommonEcho(&jsobj, js);
}

static bool ContainsNonInstance(const Object& obj) {
  if (obj.IsArray()) {
    const Array& array = Array::Cast(obj);
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < array.Length(); ++i) {
      element = array.At(i);
      if (!(element.IsInstance() || element.IsNull())) {
        return true;
      }
    }
    return false;
  } else if (obj.IsGrowableObjectArray()) {
    const GrowableObjectArray& array = GrowableObjectArray::Cast(obj);
    Object& element = Object::Handle();
    for (intptr_t i = 0; i < array.Length(); ++i) {
      element = array.At(i);
      if (!(element.IsInstance() || element.IsNull())) {
        return true;
      }
    }
    return false;
  } else {
    return !(obj.IsInstance() || obj.IsNull());
  }
}

static ObjectPtr LookupObjectId(Thread* thread,
                                const char* arg,
                                ObjectIdRing::LookupResult* kind) {
  *kind = ObjectIdRing::kValid;
  if (strncmp(arg, "int-", 4) == 0) {
    arg += 4;
    int64_t value = 0;
    if (!OS::StringToInt64(arg, &value) || !Smi::IsValid(value)) {
      *kind = ObjectIdRing::kInvalid;
      return Object::null();
    }
    const Integer& obj =
        Integer::Handle(thread->zone(), Smi::New(static_cast<intptr_t>(value)));
    return obj.ptr();
  } else if (strcmp(arg, "bool-true") == 0) {
    return Bool::True().ptr();
  } else if (strcmp(arg, "bool-false") == 0) {
    return Bool::False().ptr();
  } else if (strcmp(arg, "null") == 0) {
    return Object::null();
  }

  ObjectIdRing* ring = thread->isolate()->EnsureObjectIdRing();
  intptr_t id = -1;
  if (!GetIntegerId(arg, &id)) {
    *kind = ObjectIdRing::kInvalid;
    return Object::null();
  }
  return ring->GetObjectForId(id, kind);
}

static ObjectPtr LookupClassMembers(Thread* thread,
                                    const Class& klass,
                                    char** parts,
                                    int num_parts) {
  auto zone = thread->zone();

  if (num_parts != 4) {
    return Object::sentinel().ptr();
  }

  const char* encoded_id = parts[3];
  auto& id = String::Handle(String::New(encoded_id));
  id = String::DecodeIRI(id);
  if (id.IsNull()) {
    return Object::sentinel().ptr();
  }

  if (strcmp(parts[2], "fields") == 0) {
    // Field ids look like: "classes/17/fields/name"
    const auto& field = Field::Handle(klass.LookupField(id));
    if (field.IsNull()) {
      return Object::sentinel().ptr();
    }
    return field.ptr();
  }
  if (strcmp(parts[2], "field_inits") == 0) {
    // Field initializer ids look like: "classes/17/field_inits/name"
    const auto& field = Field::Handle(klass.LookupField(id));
    if (field.IsNull() || (field.is_late() && !field.has_initializer())) {
      return Object::sentinel().ptr();
    }
    const auto& function = Function::Handle(field.EnsureInitializerFunction());
    if (function.IsNull()) {
      return Object::sentinel().ptr();
    }
    return function.ptr();
  }
  if (strcmp(parts[2], "functions") == 0) {
    // Function ids look like: "classes/17/functions/name"

    const auto& function =
        Function::Handle(Resolver::ResolveFunction(zone, klass, id));
    if (function.IsNull()) {
      return Object::sentinel().ptr();
    }
    return function.ptr();
  }
  if (strcmp(parts[2], "implicit_closures") == 0) {
    // Function ids look like: "classes/17/implicit_closures/11"
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().ptr();
    }
    const auto& func =
        Function::Handle(zone, klass.ImplicitClosureFunctionFromIndex(id));
    if (func.IsNull()) {
      return Object::sentinel().ptr();
    }
    return func.ptr();
  }
  if (strcmp(parts[2], "dispatchers") == 0) {
    // Dispatcher Function ids look like: "classes/17/dispatchers/11"
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().ptr();
    }
    const auto& func =
        Function::Handle(zone, klass.InvocationDispatcherFunctionFromIndex(id));
    if (func.IsNull()) {
      return Object::sentinel().ptr();
    }
    return func.ptr();
  }
  if (strcmp(parts[2], "closures") == 0) {
    // Closure ids look like: "classes/17/closures/11"
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().ptr();
    }
    Function& func = Function::Handle(zone);
    func = ClosureFunctionsCache::ClosureFunctionFromIndex(id);
    if (func.IsNull()) {
      return Object::sentinel().ptr();
    }
    return func.ptr();
  }

  UNREACHABLE();
  return Object::sentinel().ptr();
}

static ObjectPtr LookupHeapObjectLibraries(IsolateGroup* isolate_group,
                                           char** parts,
                                           int num_parts) {
  // Library ids look like "libraries/35"
  if (num_parts < 2) {
    return Object::sentinel().ptr();
  }
  const auto& libs =
      GrowableObjectArray::Handle(isolate_group->object_store()->libraries());
  ASSERT(!libs.IsNull());
  const String& id = String::Handle(String::New(parts[1]));
  // Scan for private key.
  String& private_key = String::Handle();
  Library& lib = Library::Handle();
  bool lib_found = false;
  for (intptr_t i = 0; i < libs.Length(); i++) {
    lib ^= libs.At(i);
    ASSERT(!lib.IsNull());
    private_key = lib.private_key();
    if (private_key.Equals(id)) {
      lib_found = true;
      break;
    }
  }
  if (!lib_found) {
    return Object::sentinel().ptr();
  }

  const auto& klass = Class::Handle(lib.toplevel_class());
  ASSERT(!klass.IsNull());

  if (num_parts == 2) {
    return lib.ptr();
  }
  if (strcmp(parts[2], "fields") == 0) {
    // Library field ids look like: "libraries/17/fields/name"
    return LookupClassMembers(Thread::Current(), klass, parts, num_parts);
  }
  if (strcmp(parts[2], "field_inits") == 0) {
    // Library field ids look like: "libraries/17/field_inits/name"
    return LookupClassMembers(Thread::Current(), klass, parts, num_parts);
  }
  if (strcmp(parts[2], "functions") == 0) {
    // Library function ids look like: "libraries/17/functions/name"
    return LookupClassMembers(Thread::Current(), klass, parts, num_parts);
  }
  if (strcmp(parts[2], "closures") == 0) {
    // Library function ids look like: "libraries/17/closures/name"
    return LookupClassMembers(Thread::Current(), klass, parts, num_parts);
  }
  if (strcmp(parts[2], "implicit_closures") == 0) {
    // Library function ids look like: "libraries/17/implicit_closures/name"
    return LookupClassMembers(Thread::Current(), klass, parts, num_parts);
  }

  if (strcmp(parts[2], "scripts") == 0) {
    // Script ids look like "libraries/35/scripts/library%2Furl.dart/12345"
    if (num_parts != 5) {
      return Object::sentinel().ptr();
    }
    const String& id = String::Handle(String::New(parts[3]));
    ASSERT(!id.IsNull());
    // The id is the url of the script % encoded, decode it.
    const String& requested_url = String::Handle(String::DecodeIRI(id));

    // Each script id is tagged with a load time.
    int64_t timestamp;
    if (!GetInteger64Id(parts[4], &timestamp, 16) || (timestamp < 0)) {
      return Object::sentinel().ptr();
    }

    Script& script = Script::Handle();
    String& script_url = String::Handle();
    const Array& loaded_scripts = Array::Handle(lib.LoadedScripts());
    ASSERT(!loaded_scripts.IsNull());
    intptr_t i;
    for (i = 0; i < loaded_scripts.Length(); i++) {
      script ^= loaded_scripts.At(i);
      ASSERT(!script.IsNull());
      script_url = script.url();
      if (script_url.Equals(requested_url) &&
          (timestamp == script.load_timestamp())) {
        return script.ptr();
      }
    }
  }

  // Not found.
  return Object::sentinel().ptr();
}

static ObjectPtr LookupHeapObjectClasses(Thread* thread,
                                         char** parts,
                                         int num_parts) {
  // Class ids look like: "classes/17"
  if (num_parts < 2) {
    return Object::sentinel().ptr();
  }
  Zone* zone = thread->zone();
  auto table = thread->isolate_group()->class_table();
  intptr_t id;
  if (!GetIntegerId(parts[1], &id) || !table->IsValidIndex(id)) {
    return Object::sentinel().ptr();
  }
  Class& cls = Class::Handle(zone, table->At(id));
  if (num_parts == 2) {
    return cls.ptr();
  }
  if (strcmp(parts[2], "closures") == 0) {
    // Closure ids look like: "classes/17/closures/11"
    return LookupClassMembers(thread, cls, parts, num_parts);
  } else if (strcmp(parts[2], "field_inits") == 0) {
    // Field initializer ids look like: "classes/17/field_inits/name"
    return LookupClassMembers(thread, cls, parts, num_parts);
  } else if (strcmp(parts[2], "fields") == 0) {
    // Field ids look like: "classes/17/fields/name"
    return LookupClassMembers(thread, cls, parts, num_parts);
  } else if (strcmp(parts[2], "functions") == 0) {
    // Function ids look like: "classes/17/functions/name"
    return LookupClassMembers(thread, cls, parts, num_parts);
  } else if (strcmp(parts[2], "implicit_closures") == 0) {
    // Function ids look like: "classes/17/implicit_closures/11"
    return LookupClassMembers(thread, cls, parts, num_parts);
  } else if (strcmp(parts[2], "dispatchers") == 0) {
    // Dispatcher Function ids look like: "classes/17/dispatchers/11"
    return LookupClassMembers(thread, cls, parts, num_parts);
  } else if (strcmp(parts[2], "types") == 0) {
    // Type ids look like: "classes/17/types/11"
    if (num_parts != 4) {
      return Object::sentinel().ptr();
    }
    intptr_t id;
    if (!GetIntegerId(parts[3], &id)) {
      return Object::sentinel().ptr();
    }
    if (id != 0) {
      return Object::sentinel().ptr();
    }
    const Type& type = Type::Handle(zone, cls.DeclarationType());
    if (!type.IsNull()) {
      return type.ptr();
    }
  }

  // Not found.
  return Object::sentinel().ptr();
}

static ObjectPtr LookupHeapObjectTypeArguments(Thread* thread,
                                               char** parts,
                                               int num_parts) {
  // TypeArguments ids look like: "typearguments/17"
  if (num_parts < 2) {
    return Object::sentinel().ptr();
  }
  intptr_t id;
  if (!GetIntegerId(parts[1], &id)) {
    return Object::sentinel().ptr();
  }
  ObjectStore* object_store = thread->isolate_group()->object_store();
  const Array& table =
      Array::Handle(thread->zone(), object_store->canonical_type_arguments());
  ASSERT(table.Length() > 0);
  const intptr_t table_size = table.Length() - 1;
  if ((id < 0) || (id >= table_size) || (table.At(id) == Object::null())) {
    return Object::sentinel().ptr();
  }
  return table.At(id);
}

static ObjectPtr LookupHeapObjectCode(char** parts, int num_parts) {
  if (num_parts != 2) {
    return Object::sentinel().ptr();
  }
  uword pc;
  const char* const kCollectedPrefix = "collected-";
  const intptr_t kCollectedPrefixLen = strlen(kCollectedPrefix);
  const char* const kNativePrefix = "native-";
  const intptr_t kNativePrefixLen = strlen(kNativePrefix);
  const char* const kReusedPrefix = "reused-";
  const intptr_t kReusedPrefixLen = strlen(kReusedPrefix);
  const char* id = parts[1];
  if (strncmp(kCollectedPrefix, id, kCollectedPrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&id[kCollectedPrefixLen], &pc, 16)) {
      return Object::sentinel().ptr();
    }
    // TODO(turnidge): Return "collected" instead.
    return Object::null();
  }
  if (strncmp(kNativePrefix, id, kNativePrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&id[kNativePrefixLen], &pc, 16)) {
      return Object::sentinel().ptr();
    }
    // TODO(johnmccutchan): Support native Code.
    return Object::null();
  }
  if (strncmp(kReusedPrefix, id, kReusedPrefixLen) == 0) {
    if (!GetUnsignedIntegerId(&id[kReusedPrefixLen], &pc, 16)) {
      return Object::sentinel().ptr();
    }
    // TODO(turnidge): Return "expired" instead.
    return Object::null();
  }
  int64_t timestamp = 0;
  if (!GetCodeId(id, &timestamp, &pc) || (timestamp < 0)) {
    return Object::sentinel().ptr();
  }
  Code& code = Code::Handle(Code::FindCode(pc, timestamp));
  if (!code.IsNull()) {
    return code.ptr();
  }

  // Not found.
  return Object::sentinel().ptr();
}

static ObjectPtr LookupHeapObjectMessage(Thread* thread,
                                         char** parts,
                                         int num_parts) {
  if (num_parts != 2) {
    return Object::sentinel().ptr();
  }
  uword message_id = 0;
  if (!GetUnsignedIntegerId(parts[1], &message_id, 16)) {
    return Object::sentinel().ptr();
  }
  MessageHandler::AcquiredQueues aq(thread->isolate()->message_handler());
  Message* message = aq.queue()->FindMessageById(message_id);
  if (message == nullptr) {
    // The user may try to load an expired message.
    return Object::sentinel().ptr();
  }
  if (message->IsRaw()) {
    return message->raw_obj();
  } else {
    return ReadMessage(thread, message);
  }
}

static ObjectPtr LookupHeapObject(Thread* thread,
                                  const char* id_original,
                                  ObjectIdRing::LookupResult* result) {
  char* id = thread->zone()->MakeCopyOfString(id_original);

  // Parse the id by splitting at each '/'.
  const int MAX_PARTS = 8;
  char* parts[MAX_PARTS];
  int num_parts = 0;
  int i = 0;
  int start_pos = 0;
  while (id[i] != '\0') {
    if (id[i] == '/') {
      id[i++] = '\0';
      parts[num_parts++] = &id[start_pos];
      if (num_parts == MAX_PARTS) {
        break;
      }
      start_pos = i;
    } else {
      i++;
    }
  }
  if (num_parts < MAX_PARTS) {
    parts[num_parts++] = &id[start_pos];
  }

  if (result != nullptr) {
    *result = ObjectIdRing::kValid;
  }

  Isolate* isolate = thread->isolate();
  if (strcmp(parts[0], "objects") == 0) {
    // Object ids look like "objects/1123"
    Object& obj = Object::Handle(thread->zone());
    ObjectIdRing::LookupResult lookup_result;
    obj = LookupObjectId(thread, parts[1], &lookup_result);
    if (lookup_result != ObjectIdRing::kValid) {
      if (result != nullptr) {
        *result = lookup_result;
      }
      return Object::sentinel().ptr();
    }
    return obj.ptr();

  } else if (strcmp(parts[0], "libraries") == 0) {
    return LookupHeapObjectLibraries(isolate->group(), parts, num_parts);
  } else if (strcmp(parts[0], "classes") == 0) {
    return LookupHeapObjectClasses(thread, parts, num_parts);
  } else if (strcmp(parts[0], "typearguments") == 0) {
    return LookupHeapObjectTypeArguments(thread, parts, num_parts);
  } else if (strcmp(parts[0], "code") == 0) {
    return LookupHeapObjectCode(parts, num_parts);
  } else if (strcmp(parts[0], "messages") == 0) {
    return LookupHeapObjectMessage(thread, parts, num_parts);
  }

  // Not found.
  return Object::sentinel().ptr();
}

static Breakpoint* LookupBreakpoint(Isolate* isolate,
                                    const char* id,
                                    ObjectIdRing::LookupResult* result) {
  *result = ObjectIdRing::kInvalid;
  size_t end_pos = strcspn(id, "/");
  if (end_pos == strlen(id)) {
    return nullptr;
  }
  const char* rest = id + end_pos + 1;  // +1 for '/'.
  if (strncmp("breakpoints", id, end_pos) == 0) {
    intptr_t bpt_id = 0;
    Breakpoint* bpt = nullptr;
    if (GetIntegerId(rest, &bpt_id)) {
      bpt = isolate->debugger()->GetBreakpointById(bpt_id);
      if (bpt != nullptr) {
        *result = ObjectIdRing::kValid;
        return bpt;
      }
      if (bpt_id < isolate->debugger()->limitBreakpointId()) {
        *result = ObjectIdRing::kCollected;
        return nullptr;
      }
    }
  }
  return nullptr;
}

static inline void AddParentFieldToResponseBasedOnRecord(
    Thread* thread,
    Array* field_names_handle,
    String* name_handle,
    const JSONObject& jsresponse,
    const Record& record,
    const intptr_t field_slot_offset) {
  *field_names_handle = record.GetFieldNames(thread);
  const intptr_t num_positional_fields =
      record.num_fields() - field_names_handle->Length();
  const intptr_t field_index =
      (field_slot_offset - Record::field_offset(0)) / Record::kBytesPerElement;
  if (field_index < num_positional_fields) {
    jsresponse.AddProperty("parentField", field_index);
  } else {
    *name_handle ^= field_names_handle->At(field_index - num_positional_fields);
    jsresponse.AddProperty("parentField", name_handle->ToCString());
  }
}

static void PrintInboundReferences(Thread* thread,
                                   Object* target,
                                   intptr_t limit,
                                   JSONStream* js) {
  ObjectGraph graph(thread);
  Array& path = Array::Handle(Array::New(limit * 2));
  intptr_t length = graph.InboundReferences(target, path);
  OffsetsTable offsets_table(thread->zone());
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "InboundReferences");
  {
    JSONArray elements(&jsobj, "references");
    Object& source = Object::Handle();
    Smi& slot_offset = Smi::Handle();
    Array& field_names = Array::Handle();
    String& name = String::Handle();
    Class& source_class = Class::Handle();
    Field& field = Field::Handle();
    Array& parent_field_map = Array::Handle();
    limit = Utils::Minimum(limit, length);
    for (intptr_t i = 0; i < limit; ++i) {
      JSONObject jselement(&elements);
      source = path.At(i * 2);
      slot_offset ^= path.At((i * 2) + 1);

      jselement.AddProperty("source", source);
      if (source.IsArray()) {
        intptr_t element_index =
            (slot_offset.Value() - Array::element_offset(0)) /
            Array::kBytesPerElement;
        jselement.AddProperty("parentListIndex", element_index);
        jselement.AddProperty("parentField", element_index);
      } else if (source.IsRecord()) {
        AddParentFieldToResponseBasedOnRecord(thread, &field_names, &name,
                                              jselement, Record::Cast(source),
                                              slot_offset.Value());
      } else {
        if (source.IsInstance()) {
          source_class = source.clazz();
          parent_field_map = source_class.OffsetToFieldMap();
          intptr_t index = slot_offset.Value() >> kCompressedWordSizeLog2;
          if (index > 0 && index < parent_field_map.Length()) {
            field ^= parent_field_map.At(index);
            if (!field.IsNull()) {
              jselement.AddProperty("parentField", field);
              continue;
            }
          }
        }
        const char* field_name = offsets_table.FieldNameForOffset(
            source.GetClassId(), slot_offset.Value());
        if (field_name != nullptr) {
          jselement.AddProperty("_parentWordOffset", slot_offset.Value());
          // TODO(vm-service): Adjust RPC type to allow returning a field name
          // without a field object, or reify the fields described by
          // raw_object_fields.cc
          // jselement.AddProperty("_parentFieldName", field_name);
        } else if (source.IsContext()) {
          intptr_t element_index =
              (slot_offset.Value() - Context::variable_offset(0)) /
              Context::kBytesPerElement;
          jselement.AddProperty("parentListIndex", element_index);
          jselement.AddProperty("parentField", element_index);
        } else {
          jselement.AddProperty("_parentWordOffset", slot_offset.Value());
        }
      }
    }
  }

  // We nil out the array after generating the response to prevent
  // reporting spurious references when repeatedly looking for the
  // references to an object.
  for (intptr_t i = 0; i < path.Length(); i++) {
    path.SetAt(i, Object::null_object());
  }
}

static const MethodParameter* const get_inbound_references_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetInboundReferences(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == nullptr) {
    PrintMissingParamError(js, "targetId");
    return;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (limit_cstr == nullptr) {
    PrintMissingParamError(js, "limit");
    return;
  }
  intptr_t limit;
  if (!GetIntegerId(limit_cstr, &limit)) {
    PrintInvalidParamError(js, "limit");
    return;
  }

  Object& obj = Object::Handle(thread->zone());
  ObjectIdRing::LookupResult lookup_result;
  {
    HANDLESCOPE(thread);
    obj = LookupHeapObject(thread, target_id, &lookup_result);
  }
  if (obj.ptr() == Object::sentinel().ptr()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return;
  }
  PrintInboundReferences(thread, &obj, limit, js);
}

static void PrintRetainingPath(Thread* thread,
                               Object* obj,
                               intptr_t limit,
                               JSONStream* js) {
  ObjectGraph graph(thread);
  Array& path = Array::Handle(Array::New(limit * 2));
  auto result = graph.RetainingPath(obj, path);
  intptr_t length = result.length;
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "RetainingPath");
  jsobj.AddProperty("length", length);
  jsobj.AddProperty("gcRootType", result.gc_root_type);
  JSONArray elements(&jsobj, "elements");
  Object& element = Object::Handle();
  Smi& slot_offset = Smi::Handle();
  Array& field_names = Array::Handle();
  String& name = String::Handle();
  Class& element_class = Class::Handle();
  Array& element_field_map = Array::Handle();
  Map& map = Map::Handle();
  Array& map_data = Array::Handle();
  Field& field = Field::Handle();
  WeakProperty& wp = WeakProperty::Handle();
  limit = Utils::Minimum(limit, length);
  OffsetsTable offsets_table(thread->zone());
  for (intptr_t i = 0; i < limit; ++i) {
    JSONObject jselement(&elements);
    element = path.At(i * 2);
    jselement.AddProperty("value", element);
    // Interpret the word offset from parent as list index, map key,
    // weak property, or instance field.
    if (i > 0) {
      slot_offset ^= path.At((i * 2) - 1);
      if (element.IsArray() || element.IsGrowableObjectArray()) {
        intptr_t element_index =
            (slot_offset.Value() - Array::element_offset(0)) /
            Array::kBytesPerElement;
        jselement.AddProperty("parentListIndex", element_index);
        jselement.AddProperty("parentField", element_index);
      } else if (element.IsRecord()) {
        AddParentFieldToResponseBasedOnRecord(thread, &field_names, &name,
                                              jselement, Record::Cast(element),
                                              slot_offset.Value());
      } else if (element.IsMap()) {
        map = static_cast<MapPtr>(path.At(i * 2));
        map_data = map.data();
        intptr_t element_index =
            (slot_offset.Value() - Array::element_offset(0)) /
            Array::kBytesPerElement;
        Map::Iterator iterator(map);
        while (iterator.MoveNext()) {
          if (iterator.CurrentKey() == map_data.At(element_index) ||
              iterator.CurrentValue() == map_data.At(element_index)) {
            element = iterator.CurrentKey();
            jselement.AddProperty("parentMapKey", element);
            break;
          }
        }
      } else if (element.IsWeakProperty()) {
        wp ^= static_cast<WeakPropertyPtr>(element.ptr());
        element = wp.key();
        jselement.AddProperty("parentMapKey", element);
      } else {
        if (element.IsInstance()) {
          element_class = element.clazz();
          element_field_map = element_class.OffsetToFieldMap();
          intptr_t index = slot_offset.Value() >> kCompressedWordSizeLog2;
          if ((index > 0) && (index < element_field_map.Length())) {
            field ^= element_field_map.At(index);
            if (!field.IsNull()) {
              name ^= field.name();
              jselement.AddProperty("parentField", name.ToCString());
              continue;
            }
          }
        }
        const char* field_name = offsets_table.FieldNameForOffset(
            element.GetClassId(), slot_offset.Value());
        if (field_name != nullptr) {
          jselement.AddProperty("parentField", field_name);
        } else if (element.IsContext()) {
          intptr_t element_index =
              (slot_offset.Value() - Context::variable_offset(0)) /
              Context::kBytesPerElement;
          jselement.AddProperty("parentListIndex", element_index);
          jselement.AddProperty("parentField", element_index);
        } else {
          jselement.AddProperty("_parentWordOffset", slot_offset.Value());
        }
      }
    }
  }

  // We nil out the array after generating the response to prevent
  // reporting spurious references when looking for inbound references
  // after looking for a retaining path.
  for (intptr_t i = 0; i < path.Length(); i++) {
    path.SetAt(i, Object::null_object());
  }
}

static const MethodParameter* const get_retaining_path_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetRetainingPath(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  if (target_id == nullptr) {
    PrintMissingParamError(js, "targetId");
    return;
  }
  const char* limit_cstr = js->LookupParam("limit");
  if (limit_cstr == nullptr) {
    PrintMissingParamError(js, "limit");
    return;
  }
  intptr_t limit;
  if (!GetIntegerId(limit_cstr, &limit)) {
    PrintInvalidParamError(js, "limit");
    return;
  }

  Object& obj = Object::Handle(thread->zone());
  ObjectIdRing::LookupResult lookup_result;
  {
    HANDLESCOPE(thread);
    obj = LookupHeapObject(thread, target_id, &lookup_result);
  }
  if (obj.ptr() == Object::sentinel().ptr()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return;
  }
  PrintRetainingPath(thread, &obj, limit, js);
}

static const MethodParameter* const get_retained_size_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("targetId", true),
    nullptr,
};

static void GetRetainedSize(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  ASSERT(target_id != nullptr);
  ObjectIdRing::LookupResult lookup_result;
  Object& obj =
      Object::Handle(LookupHeapObject(thread, target_id, &lookup_result));
  if (obj.ptr() == Object::sentinel().ptr()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return;
  }
  // TODO(rmacnak): There is no way to get the size retained by a class object.
  // SizeRetainedByClass should be a separate RPC.
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    ObjectGraph graph(thread);
    intptr_t retained_size = graph.SizeRetainedByClass(cls.id());
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return;
  }

  ObjectGraph graph(thread);
  intptr_t retained_size = graph.SizeRetainedByInstance(obj);
  const Object& result = Object::Handle(Integer::New(retained_size));
  result.PrintJSON(js, true);
}

static const MethodParameter* const get_reachable_size_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("targetId", true),
    nullptr,
};

static void GetReachableSize(Thread* thread, JSONStream* js) {
  const char* target_id = js->LookupParam("targetId");
  ASSERT(target_id != nullptr);
  ObjectIdRing::LookupResult lookup_result;
  Object& obj =
      Object::Handle(LookupHeapObject(thread, target_id, &lookup_result));
  if (obj.ptr() == Object::sentinel().ptr()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return;
  }
  // TODO(rmacnak): There is no way to get the size retained by a class object.
  // SizeRetainedByClass should be a separate RPC.
  if (obj.IsClass()) {
    const Class& cls = Class::Cast(obj);
    ObjectGraph graph(thread);
    intptr_t retained_size = graph.SizeReachableByClass(cls.id());
    const Object& result = Object::Handle(Integer::New(retained_size));
    result.PrintJSON(js, true);
    return;
  }

  ObjectGraph graph(thread);
  intptr_t retained_size = graph.SizeReachableByInstance(obj);
  const Object& result = Object::Handle(Integer::New(retained_size));
  result.PrintJSON(js, true);
}

static const MethodParameter* const invoke_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void Invoke(Thread* thread, JSONStream* js) {
  const char* receiver_id = js->LookupParam("targetId");
  if (receiver_id == nullptr) {
    PrintMissingParamError(js, "targetId");
    return;
  }
  const char* selector_cstr = js->LookupParam("selector");
  if (selector_cstr == nullptr) {
    PrintMissingParamError(js, "selector");
    return;
  }
  const char* argument_ids = js->LookupParam("argumentIds");
  if (argument_ids == nullptr) {
    PrintMissingParamError(js, "argumentIds");
    return;
  }

#if !defined(DART_PRECOMPILED_RUNTIME)
  bool disable_breakpoints =
      BoolParameter::Parse(js->LookupParam("disableBreakpoints"), false);
  DisableBreakpointsScope db(thread->isolate()->debugger(),
                             disable_breakpoints);
#endif

  Zone* zone = thread->zone();
  ObjectIdRing::LookupResult lookup_result;
  Object& receiver = Object::Handle(
      zone, LookupHeapObject(thread, receiver_id, &lookup_result));
  if (receiver.ptr() == Object::sentinel().ptr()) {
    if (lookup_result == ObjectIdRing::kCollected) {
      PrintSentinel(js, kCollectedSentinel);
    } else if (lookup_result == ObjectIdRing::kExpired) {
      PrintSentinel(js, kExpiredSentinel);
    } else {
      PrintInvalidParamError(js, "targetId");
    }
    return;
  }

  const GrowableObjectArray& growable_args =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());

  bool is_instance = (receiver.IsInstance() || receiver.IsNull()) &&
                     !ContainsNonInstance(receiver);
  if (is_instance) {
    growable_args.Add(receiver);
  }

  intptr_t n = strlen(argument_ids);
  if ((n < 2) || (argument_ids[0] != '[') || (argument_ids[n - 1] != ']')) {
    PrintInvalidParamError(js, "argumentIds");
    return;
  }
  if (n > 2) {
    intptr_t start = 1;
    while (start < n) {
      intptr_t end = start;
      while ((argument_ids[end + 1] != ',') && (argument_ids[end + 1] != ']')) {
        end++;
      }
      if (end == start) {
        // Empty element.
        PrintInvalidParamError(js, "argumentIds");
        return;
      }

      const char* argument_id =
          zone->MakeCopyOfStringN(&argument_ids[start], end - start + 1);

      ObjectIdRing::LookupResult lookup_result;
      Object& argument = Object::Handle(
          zone, LookupHeapObject(thread, argument_id, &lookup_result));
      // Invoke only accepts Instance arguments.
      if (!(argument.IsInstance() || argument.IsNull()) ||
          ContainsNonInstance(argument)) {
        PrintInvalidParamError(js, "argumentIds");
        return;
      }
      if (argument.ptr() == Object::sentinel().ptr()) {
        if (lookup_result == ObjectIdRing::kCollected) {
          PrintSentinel(js, kCollectedSentinel);
        } else if (lookup_result == ObjectIdRing::kExpired) {
          PrintSentinel(js, kExpiredSentinel);
        } else {
          PrintInvalidParamError(js, "argumentIds");
        }
        return;
      }
      growable_args.Add(argument);

      start = end + 3;
    }
  }

  const String& selector = String::Handle(zone, String::New(selector_cstr));
  const Array& args =
      Array::Handle(zone, Array::MakeFixedLength(growable_args));
  const Array& arg_names = Object::empty_array();

  if (receiver.IsLibrary()) {
    const Library& lib = Library::Cast(receiver);
    const Object& result =
        Object::Handle(zone, lib.Invoke(selector, args, arg_names));
    result.PrintJSON(js, true);
    return;
  }
  if (receiver.IsClass()) {
    const Class& cls = Class::Cast(receiver);
    const Object& result =
        Object::Handle(zone, cls.Invoke(selector, args, arg_names));
    result.PrintJSON(js, true);
    return;
  }
  if (is_instance) {
    // We don't use Instance::Cast here because it doesn't allow null.
    Instance& instance = Instance::Handle(zone);
    instance ^= receiver.ptr();
    const Object& result =
        Object::Handle(zone, instance.Invoke(selector, args, arg_names));
    result.PrintJSON(js, true);
    return;
  }
  js->PrintError(kInvalidParams,
                 "%s: invalid 'targetId' parameter: "
                 "Cannot invoke against a VM-internal object",
                 js->method());
}

static const MethodParameter* const evaluate_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static bool IsAlpha(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}
static bool IsAlphaOrDollar(char c) {
  return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c == '$');
}
static bool IsAlphaNum(char c) {
  return (c >= '0' && c <= '9') || IsAlpha(c);
}
static bool IsAlphaNumOrDollar(char c) {
  return (c >= '0' && c <= '9') || IsAlphaOrDollar(c);
}
static bool IsWhitespace(char c) {
  return c <= ' ';
}
static bool IsObjectIdChar(char c) {
  return IsAlphaNum(c) || c == '/' || c == '-' || c == '@' || c == '%';
}

// TODO(vm-service): Consider whether we should pass structured objects in
// service messages instead of always flattening them to C strings.
static bool ParseScope(const char* scope,
                       GrowableArray<const char*>* names,
                       GrowableArray<const char*>* ids) {
  Zone* zone = Thread::Current()->zone();
  const char* c = scope;
  if (*c++ != '{') return false;

  for (;;) {
    while (IsWhitespace(*c)) {
      c++;
    }

    if (*c == '}') return true;

    const char* name = c;
    if (!IsAlphaOrDollar(*c)) return false;
    while (IsAlphaNumOrDollar(*c)) {
      c++;
    }
    names->Add(zone->MakeCopyOfStringN(name, c - name));

    while (IsWhitespace(*c)) {
      c++;
    }

    if (*c++ != ':') return false;

    while (IsWhitespace(*c)) {
      c++;
    }

    const char* id = c;
    if (!IsObjectIdChar(*c)) return false;
    while (IsObjectIdChar(*c)) {
      c++;
    }
    ids->Add(zone->MakeCopyOfStringN(id, c - id));

    while (IsWhitespace(*c)) {
      c++;
    }
    if (*c == ',') c++;
  }

  return false;
}

static bool BuildScope(Thread* thread,
                       JSONStream* js,
                       const GrowableObjectArray& names,
                       const GrowableObjectArray& values) {
  const char* scope = js->LookupParam("scope");
  GrowableArray<const char*> cnames;
  GrowableArray<const char*> cids;
  if (scope != nullptr) {
    if (!ParseScope(scope, &cnames, &cids)) {
      PrintInvalidParamError(js, "scope");
      return true;
    }
    String& name = String::Handle();
    Object& obj = Object::Handle();
    for (intptr_t i = 0; i < cids.length(); i++) {
      ObjectIdRing::LookupResult lookup_result;
      obj = LookupHeapObject(thread, cids[i], &lookup_result);
      if (obj.ptr() == Object::sentinel().ptr()) {
        if (lookup_result == ObjectIdRing::kCollected) {
          PrintSentinel(js, kCollectedSentinel);
        } else if (lookup_result == ObjectIdRing::kExpired) {
          PrintSentinel(js, kExpiredSentinel);
        } else {
          PrintInvalidParamError(js, "targetId");
        }
        return true;
      }
      if ((!obj.IsInstance() && !obj.IsNull()) || ContainsNonInstance(obj)) {
        js->PrintError(kInvalidParams,
                       "%s: invalid scope 'targetId' parameter: "
                       "Cannot evaluate against a VM-internal object",
                       js->method());
        return true;
      }
      name = String::New(cnames[i]);
      names.Add(name);
      values.Add(obj);
    }
  }
  return false;
}

static void Evaluate(Thread* thread, JSONStream* js) {
  // If a compilation service is available, this RPC invocation will have been
  // intercepted by RunningIsolates.routeRequest.
  js->PrintError(
      kExpressionCompilationError,
      "%s: No compilation service available; cannot evaluate from source.",
      js->method());
}

static const MethodParameter* const build_expression_evaluation_scope_params[] =
    {
        RUNNABLE_ISOLATE_PARAMETER,
        new IdParameter("frameIndex", false),
        new IdParameter("targetId", false),
        nullptr,
};

static void CollectStringifiedType(Zone* zone,
                                   const AbstractType& type,
                                   const GrowableObjectArray& output) {
  Instance& instance = Instance::Handle(zone);
  if (type.IsFunctionType()) {
    // The closure class
    // (IsolateGroup::Current()->object_store()->closure_class())
    // is statically typed weird (the call method redirects to itself)
    // and the type is therefore not useful for the CFE. We use null instead.
    output.Add(instance);
    return;
  }
  if (type.IsRecordType()) {
    // _Record class is not useful for the CFE. We use null instead.
    output.Add(instance);
    return;
  }
  if (type.IsDynamicType()) {
    // Dynamic is weird in that it seems to have a class with no name and a
    // library called something like '7189777121420'. We use null instead.
    output.Add(instance);
    return;
  }
  if (type.IsTypeParameter()) {
    // Calling type_class on a type parameter will crash the VM.
    // We use null instead.
    output.Add(instance);
    return;
  }
  ASSERT(type.IsType());

  const Class& cls = Class::Handle(type.type_class());
  const Library& lib = Library::Handle(zone, cls.library());

  instance ^= lib.url();
  output.Add(instance);

  instance ^= cls.ScrubbedName();
  output.Add(instance);

  instance ^= Smi::New((intptr_t)type.nullability());
  output.Add(instance);

  const TypeArguments& srcArguments =
      TypeArguments::Handle(Type::Cast(type).arguments());
  instance ^= Smi::New(srcArguments.Length());
  output.Add(instance);
  for (int i = 0; i < srcArguments.Length(); i++) {
    const AbstractType& src_type = AbstractType::Handle(srcArguments.TypeAt(i));
    CollectStringifiedType(zone, src_type, output);
  }
}

static void BuildExpressionEvaluationScope(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  Isolate* isolate = thread->isolate();
  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  intptr_t framePos = UIntParameter::Parse(js->LookupParam("frameIndex"));
  if (framePos >= stack->Length()) {
    PrintInvalidParamError(js, "frameIndex");
    return;
  }

  Zone* zone = thread->zone();
  const GrowableObjectArray& param_names =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& param_values =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& type_params_names =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& type_params_bounds =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& type_params_defaults =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  String& klass_name = String::Handle(zone);
  String& method_name = String::Handle(zone);
  String& library_uri = String::Handle(zone);
  bool isStatic = false;

  if (BuildScope(thread, js, param_names, param_values)) {
    return;
  }

  if (js->HasParam("frameIndex")) {
    // building scope in the context of a given frame
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t framePos = UIntParameter::Parse(js->LookupParam("frameIndex"));
    if (framePos >= stack->Length()) {
      PrintInvalidParamError(js, "frameIndex");
      return;
    }

    ActivationFrame* frame = stack->FrameAt(framePos);
    frame->BuildParameters(param_names, param_values, type_params_names,
                           type_params_bounds, type_params_defaults);

    if (frame->function().is_static()) {
      const Class& cls = Class::Handle(zone, frame->function().Owner());
      if (!cls.IsTopLevel()) {
        klass_name = cls.UserVisibleName();
      }
      library_uri = Library::Handle(zone, cls.library()).url();
      method_name = frame->function().UserVisibleName();
      isStatic = true;
    } else {
      Class& method_cls = Class::Handle(zone, frame->function().Owner());
      method_cls = method_cls.Mixin();
      library_uri = Library::Handle(zone, method_cls.library()).url();
      klass_name = method_cls.UserVisibleName();
      method_name = frame->function().UserVisibleName();
      isStatic = false;
    }
  } else {
    // building scope in the context of a given object
    if (!js->HasParam("targetId")) {
      js->PrintError(kInvalidParams,
                     "Either targetId or frameIndex has to be provided.");
      return;
    }
    const char* target_id = js->LookupParam("targetId");

    ObjectIdRing::LookupResult lookup_result;
    Object& obj = Object::Handle(
        zone, LookupHeapObject(thread, target_id, &lookup_result));
    if (obj.ptr() == Object::sentinel().ptr()) {
      PrintInvalidParamError(js, "targetId");
      return;
    }
    if (obj.IsLibrary()) {
      const Library& lib = Library::Cast(obj);
      library_uri = lib.url();
      isStatic = true;
    } else if (obj.IsClass() || ((obj.IsInstance() || obj.IsNull()) &&
                                 !ContainsNonInstance(obj))) {
      Class& cls = Class::Handle(zone);
      if (obj.IsClass()) {
        cls ^= obj.ptr();
        isStatic = true;
      } else {
        Instance& instance = Instance::Handle(zone);
        instance ^= obj.ptr();
        cls = instance.clazz();
        cls = cls.Mixin();
        isStatic = false;
      }
      if (!cls.IsTopLevel() &&
          (IsInternalOnlyClassId(cls.id()) || cls.id() == kTypeArgumentsCid)) {
        js->PrintError(
            kInvalidParams,
            "Expressions can be evaluated only with regular Dart instances");
        return;
      }

      if (!cls.IsTopLevel()) {
        klass_name = cls.UserVisibleName();
      }
      library_uri = Library::Handle(zone, cls.library()).url();
    } else {
      js->PrintError(kInvalidParams,
                     "%s: invalid 'targetId' parameter: "
                     "Cannot evaluate against a VM-internal object",
                     js->method());
      return;
    }
  }

  JSONObject report(js);
  {
    JSONArray jsonParamNames(&report, "param_names");

    String& param_name = String::Handle(zone);
    for (intptr_t i = 0; i < param_names.Length(); i++) {
      param_name ^= param_names.At(i);
      jsonParamNames.AddValue(param_name.ToCString());
    }
  }
  {
    const JSONArray jsonParamTypes(&report, "param_types");
    Object& obj = Object::Handle();
    Instance& instance = Instance::Handle();
    const GrowableObjectArray& param_types =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
    AbstractType& type = AbstractType::Handle();
    for (intptr_t i = 0; i < param_names.Length(); i++) {
      obj = param_values.At(i);
      if (obj.IsNull()) {
        param_types.Add(obj);
      } else if (obj.IsInstance()) {
        instance ^= param_values.At(i);
        type = instance.GetType(Heap::kNew);
        CollectStringifiedType(zone, type, param_types);
      }
    }
    for (intptr_t i = 0; i < param_types.Length(); i++) {
      instance ^= param_types.At(i);
      jsonParamTypes.AddValue(instance.ToCString());
    }
  }

  {
    JSONArray jsonTypeParamsNames(&report, "type_params_names");
    String& type_param_name = String::Handle(zone);
    for (intptr_t i = 0; i < type_params_names.Length(); i++) {
      type_param_name ^= type_params_names.At(i);
      jsonTypeParamsNames.AddValue(type_param_name.ToCString());
    }
  }
  {
    const JSONArray jsonParamTypes(&report, "type_params_bounds");
    const GrowableObjectArray& type_params_bounds_strings =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
    AbstractType& type = AbstractType::Handle();
    for (intptr_t i = 0; i < type_params_bounds.Length(); i++) {
      type ^= type_params_bounds.At(i);
      CollectStringifiedType(zone, type, type_params_bounds_strings);
    }
    Instance& instance = Instance::Handle();
    for (intptr_t i = 0; i < type_params_bounds_strings.Length(); i++) {
      instance ^= type_params_bounds_strings.At(i);
      jsonParamTypes.AddValue(instance.ToCString());
    }
  }
  {
    const JSONArray jsonParamTypes(&report, "type_params_defaults");
    const GrowableObjectArray& type_params_defaults_strings =
        GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
    AbstractType& type = AbstractType::Handle();
    for (intptr_t i = 0; i < type_params_defaults.Length(); i++) {
      type ^= type_params_defaults.At(i);
      CollectStringifiedType(zone, type, type_params_defaults_strings);
    }
    Instance& instance = Instance::Handle();
    for (intptr_t i = 0; i < type_params_defaults_strings.Length(); i++) {
      instance ^= type_params_defaults_strings.At(i);
      jsonParamTypes.AddValue(instance.ToCString());
    }
  }
  report.AddProperty("libraryUri", library_uri.ToCString());
  if (!klass_name.IsNull()) {
    report.AddProperty("klass", klass_name.ToCString());
  }
  if (!method_name.IsNull()) {
    report.AddProperty("method", method_name.ToCString());
  }
  report.AddProperty("isStatic", isStatic);
}

#if !defined(DART_PRECOMPILED_RUNTIME)
// Parse comma-separated list of values, put them into values
static bool ParseCSVList(const char* csv_list,
                         const GrowableObjectArray& values) {
  Zone* zone = Thread::Current()->zone();
  String& s = String::Handle(zone);
  const char* c = csv_list;
  if (*c++ != '[') return false;
  while (IsWhitespace(*c) && *c != '\0') {
    c++;
  }
  while (*c != '\0') {
    const char* value = c;
    while (*c != '\0' && *c != ']' && *c != ',' && !IsWhitespace(*c)) {
      c++;
    }
    if (c > value) {
      s = String::New(zone->MakeCopyOfStringN(value, c - value));
      values.Add(s);
    }
    switch (*c) {
      case '\0':
        return false;
      case ',':
        c++;
        break;
      case ']':
        return true;
    }
    while (IsWhitespace(*c) && *c != '\0') {
      c++;
    }
  }
  return false;
}
#endif

static const MethodParameter* const compile_expression_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new StringParameter("expression", true),
    new StringParameter("definitions", false),
    new StringParameter("definitionTypes", false),
    new StringParameter("typeDefinitions", false),
    new StringParameter("typeBounds", false),
    new StringParameter("typeDefaults", false),
    new StringParameter("libraryUri", true),
    new StringParameter("klass", false),
    new BoolParameter("isStatic", false),
    new StringParameter("method", false),
    nullptr,
};

static void CompileExpression(Thread* thread, JSONStream* js) {
#if defined(DART_PRECOMPILED_RUNTIME)
  js->PrintError(kFeatureDisabled, "Debugger is disabled in AOT mode.");
#else
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  if (!KernelIsolate::IsRunning() && !KernelIsolate::Start()) {
    js->PrintError(
        kExpressionCompilationError,
        "%s: No compilation service available; cannot evaluate from source.",
        js->method());
    return;
  }

  const char* klass = js->LookupParam("klass");
  bool is_static =
      BoolParameter::Parse(js->LookupParam("isStatic"), (klass == nullptr));

  const GrowableObjectArray& params =
      GrowableObjectArray::Handle(thread->zone(), GrowableObjectArray::New());
  if (!ParseCSVList(js->LookupParam("definitions"), params)) {
    PrintInvalidParamError(js, "definitions");
    return;
  }
  const GrowableObjectArray& param_types =
      GrowableObjectArray::Handle(thread->zone(), GrowableObjectArray::New());
  if (!ParseCSVList(js->LookupParam("definitionTypes"), param_types)) {
    PrintInvalidParamError(js, "definitionTypes");
    return;
  }

  const GrowableObjectArray& type_params =
      GrowableObjectArray::Handle(thread->zone(), GrowableObjectArray::New());
  if (!ParseCSVList(js->LookupParam("typeDefinitions"), type_params)) {
    PrintInvalidParamError(js, "typedDefinitions");
    return;
  }
  const GrowableObjectArray& type_bounds =
      GrowableObjectArray::Handle(thread->zone(), GrowableObjectArray::New());
  if (!ParseCSVList(js->LookupParam("typeBounds"), type_bounds)) {
    PrintInvalidParamError(js, "typeBounds");
    return;
  }
  const GrowableObjectArray& type_defaults =
      GrowableObjectArray::Handle(thread->zone(), GrowableObjectArray::New());
  if (!ParseCSVList(js->LookupParam("typeDefaults"), type_defaults)) {
    PrintInvalidParamError(js, "typeDefaults");
    return;
  }

  const uint8_t* kernel_buffer = Service::dart_library_kernel();
  const intptr_t kernel_buffer_len = Service::dart_library_kernel_length();

  Dart_KernelCompilationResult compilation_result =
      KernelIsolate::CompileExpressionToKernel(
          kernel_buffer, kernel_buffer_len, js->LookupParam("expression"),
          Array::Handle(Array::MakeFixedLength(params)),
          Array::Handle(Array::MakeFixedLength(param_types)),
          Array::Handle(Array::MakeFixedLength(type_params)),
          Array::Handle(Array::MakeFixedLength(type_bounds)),
          Array::Handle(Array::MakeFixedLength(type_defaults)),
          js->LookupParam("libraryUri"), js->LookupParam("klass"),
          js->LookupParam("method"), is_static);

  if (compilation_result.status != Dart_KernelCompilationStatus_Ok) {
    js->PrintError(kExpressionCompilationError, "%s", compilation_result.error);
    free(compilation_result.error);
    return;
  }

  const uint8_t* kernel_bytes = compilation_result.kernel;
  intptr_t kernel_length = compilation_result.kernel_size;
  ASSERT(kernel_bytes != nullptr);

  JSONObject report(js);
  report.AddPropertyBase64("kernelBytes", kernel_bytes, kernel_length);
#endif
}

static const MethodParameter* const evaluate_compiled_expression_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new UIntParameter("frameIndex", false),
    new IdParameter("targetId", false),
    new StringParameter("kernelBytes", true),
    nullptr,
};

ExternalTypedDataPtr DecodeKernelBuffer(const char* kernel_buffer_base64) {
  intptr_t kernel_length;
  uint8_t* kernel_buffer = DecodeBase64(kernel_buffer_base64, &kernel_length);
  return ExternalTypedData::NewFinalizeWithFree(kernel_buffer, kernel_length);
}

static void EvaluateCompiledExpression(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  Isolate* isolate = thread->isolate();

  bool disable_breakpoints =
      BoolParameter::Parse(js->LookupParam("disableBreakpoints"), false);
  DisableBreakpointsScope db(isolate->debugger(), disable_breakpoints);

  DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
  intptr_t frame_pos = UIntParameter::Parse(js->LookupParam("frameIndex"));
  if (frame_pos >= stack->Length()) {
    PrintInvalidParamError(js, "frameIndex");
    return;
  }
  Zone* zone = thread->zone();
  const GrowableObjectArray& param_names =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& param_values =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  if (BuildScope(thread, js, param_names, param_values)) {
    return;
  }
  const GrowableObjectArray& type_params_names =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& type_params_bounds =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  const GrowableObjectArray& type_params_defaults =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());

  const ExternalTypedData& kernel_data = ExternalTypedData::Handle(
      zone, DecodeKernelBuffer(js->LookupParam("kernelBytes")));

  if (js->HasParam("frameIndex")) {
    DebuggerStackTrace* stack = isolate->debugger()->StackTrace();
    intptr_t frame_pos = UIntParameter::Parse(js->LookupParam("frameIndex"));
    if (frame_pos >= stack->Length()) {
      PrintInvalidParamError(js, "frameIndex");
      return;
    }

    ActivationFrame* frame = stack->FrameAt(frame_pos);
    TypeArguments& type_arguments = TypeArguments::Handle(
        zone,
        frame->BuildParameters(param_names, param_values, type_params_names,
                               type_params_bounds, type_params_defaults));

    const Object& result = Object::Handle(
        zone,
        frame->EvaluateCompiledExpression(
            kernel_data,
            Array::Handle(zone, Array::MakeFixedLength(type_params_names)),
            Array::Handle(zone, Array::MakeFixedLength(param_values)),
            type_arguments));
    result.PrintJSON(js, true);
  } else {
    // evaluating expression in the context of a given object
    if (!js->HasParam("targetId")) {
      js->PrintError(kInvalidParams,
                     "Either targetId or frameIndex has to be provided.");
      return;
    }
    const char* target_id = js->LookupParam("targetId");
    ObjectIdRing::LookupResult lookup_result;
    Object& obj = Object::Handle(
        zone, LookupHeapObject(thread, target_id, &lookup_result));
    if (obj.ptr() == Object::sentinel().ptr()) {
      if (lookup_result == ObjectIdRing::kCollected) {
        PrintSentinel(js, kCollectedSentinel);
      } else if (lookup_result == ObjectIdRing::kExpired) {
        PrintSentinel(js, kExpiredSentinel);
      } else {
        PrintInvalidParamError(js, "targetId");
      }
      return;
    }
    const auto& type_params_names_fixed =
        Array::Handle(zone, Array::MakeFixedLength(type_params_names));
    const auto& param_values_fixed =
        Array::Handle(zone, Array::MakeFixedLength(param_values));

    TypeArguments& type_arguments = TypeArguments::Handle(zone);
    if (obj.IsLibrary()) {
      const auto& lib = Library::Cast(obj);
      const auto& result = Object::Handle(
          zone,
          lib.EvaluateCompiledExpression(kernel_data, type_params_names_fixed,
                                         param_values_fixed, type_arguments));
      result.PrintJSON(js, true);
      return;
    }
    if (obj.IsClass()) {
      const auto& cls = Class::Cast(obj);
      const auto& result = Object::Handle(
          zone,
          cls.EvaluateCompiledExpression(kernel_data, type_params_names_fixed,
                                         param_values_fixed, type_arguments));
      result.PrintJSON(js, true);
      return;
    }
    if ((obj.IsInstance() || obj.IsNull()) && !ContainsNonInstance(obj)) {
      const auto& instance =
          Instance::Handle(zone, Instance::RawCast(obj.ptr()));
      const auto& receiver_cls = Class::Handle(zone, instance.clazz());
      const auto& result = Object::Handle(
          zone, instance.EvaluateCompiledExpression(
                    receiver_cls, kernel_data, type_params_names_fixed,
                    param_values_fixed, type_arguments));
      result.PrintJSON(js, true);
      return;
    }
    js->PrintError(kInvalidParams,
                   "%s: invalid 'targetId' parameter: "
                   "Cannot evaluate against a VM-internal object",
                   js->method());
  }
}

static const MethodParameter* const evaluate_in_frame_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new UIntParameter("frameIndex", true),
    new MethodParameter("expression", true),
    nullptr,
};

static void EvaluateInFrame(Thread* thread, JSONStream* js) {
  // If a compilation service is available, this RPC invocation will have been
  // intercepted by RunningIsolates.routeRequest.
  js->PrintError(
      kExpressionCompilationError,
      "%s: No compilation service available; cannot evaluate from source.",
      js->method());
}

static void MarkClasses(const Class& root,
                        bool include_subclasses,
                        bool include_implementors) {
  Thread* thread = Thread::Current();
  HANDLESCOPE(thread);
  ClassTable* table = thread->isolate()->group()->class_table();
  GrowableArray<const Class*> worklist;
  table->SetCollectInstancesFor(root.id(), true);
  worklist.Add(&root);
  GrowableObjectArray& subclasses = GrowableObjectArray::Handle();
  GrowableObjectArray& implementors = GrowableObjectArray::Handle();
  while (!worklist.is_empty()) {
    const Class& cls = *worklist.RemoveLast();
    // All subclasses are implementors, but they are not included in
    // `direct_implementors`.
    if (include_subclasses || include_implementors) {
      subclasses = cls.direct_subclasses_unsafe();
      if (!subclasses.IsNull()) {
        for (intptr_t j = 0; j < subclasses.Length(); j++) {
          Class& subclass = Class::Handle();
          subclass ^= subclasses.At(j);
          if (!table->CollectInstancesFor(subclass.id())) {
            table->SetCollectInstancesFor(subclass.id(), true);
            worklist.Add(&subclass);
          }
        }
      }
    }
    if (include_implementors) {
      implementors = cls.direct_implementors_unsafe();
      if (!implementors.IsNull()) {
        for (intptr_t j = 0; j < implementors.Length(); j++) {
          Class& implementor = Class::Handle();
          implementor ^= implementors.At(j);
          if (!table->CollectInstancesFor(implementor.id())) {
            table->SetCollectInstancesFor(implementor.id(), true);
            worklist.Add(&implementor);
          }
        }
      }
    }
  }
}

static void UnmarkClasses() {
  ClassTable* table = IsolateGroup::Current()->class_table();
  for (intptr_t i = 1; i < table->NumCids(); i++) {
    table->SetCollectInstancesFor(i, false);
  }
}

class GetInstancesVisitor : public ObjectGraph::Visitor {
 public:
  GetInstancesVisitor(ZoneGrowableHandlePtrArray<Object>* storage,
                      intptr_t limit)
      : table_(IsolateGroup::Current()->class_table()),
        storage_(storage),
        limit_(limit),
        count_(0) {}

  virtual Direction VisitObject(ObjectGraph::StackIterator* it) {
    ObjectPtr raw_obj = it->Get();
    if (raw_obj->IsPseudoObject()) {
      return kProceed;
    }
    if (table_->CollectInstancesFor(raw_obj->GetClassId())) {
      if (count_ < limit_) {
        storage_->Add(Object::Handle(raw_obj));
      }
      ++count_;
    }
    return kProceed;
  }

  intptr_t count() const { return count_; }

 private:
  ClassTable* const table_;
  ZoneGrowableHandlePtrArray<Object>* storage_;
  const intptr_t limit_;
  intptr_t count_;
};

static const MethodParameter* const get_instances_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("objectId", /*required=*/true),
    new UIntParameter("limit", /*required=*/true),
    new BoolParameter("includeSubclasses", /*required=*/false),
    new BoolParameter("includeImplementers", /*required=*/false),
    nullptr,
};

static void GetInstances(Thread* thread, JSONStream* js) {
  const char* object_id = js->LookupParam("objectId");
  const intptr_t limit = UIntParameter::Parse(js->LookupParam("limit"));
  const bool include_subclasses =
      BoolParameter::Parse(js->LookupParam("includeSubclasses"), false);
  const bool include_implementers =
      BoolParameter::Parse(js->LookupParam("includeImplementers"), false);

  const Object& obj =
      Object::Handle(LookupHeapObject(thread, object_id, nullptr));
  if (obj.ptr() == Object::sentinel().ptr() || !obj.IsClass()) {
    PrintInvalidParamError(js, "objectId");
    return;
  }
  const Class& cls = Class::Cast(obj);

  // Ensure the array and handles created below are promptly destroyed.
  StackZone zone(thread);

  ZoneGrowableHandlePtrArray<Object> storage(thread->zone(), limit);
  GetInstancesVisitor visitor(&storage, limit);
  {
    ObjectGraph graph(thread);
    HeapIterationScope iteration_scope(Thread::Current(), true);
    MarkClasses(cls, include_subclasses, include_implementers);
    graph.IterateObjects(&visitor);
    UnmarkClasses();
  }
  intptr_t count = visitor.count();
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "InstanceSet");
  jsobj.AddProperty("totalCount", count);
  {
    JSONArray samples(&jsobj, "instances");
    for (int i = 0; (i < limit) && (i < count); i++) {
      samples.AddValue(storage.At(i));
    }
  }
}

static const MethodParameter* const get_instances_as_list_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("objectId", /*required=*/true),
    new BoolParameter("includeSubclasses", /*required=*/false),
    new BoolParameter("includeImplementers", /*required=*/false),
    nullptr,
};

static void GetInstancesAsList(Thread* thread, JSONStream* js) {
  const char* object_id = js->LookupParam("objectId");
  bool include_subclasses =
      BoolParameter::Parse(js->LookupParam("includeSubclasses"), false);
  bool include_implementers =
      BoolParameter::Parse(js->LookupParam("includeImplementers"), false);

  const Object& obj =
      Object::Handle(LookupHeapObject(thread, object_id, nullptr));
  if (obj.ptr() == Object::sentinel().ptr() || !obj.IsClass()) {
    PrintInvalidParamError(js, "objectId");
    return;
  }
  const Class& cls = Class::Cast(obj);

  Array& instances = Array::Handle();
  {
    // Ensure the |ZoneGrowableHandlePtrArray| and handles created below are
    // promptly destroyed.
    StackZone zone(thread);

    ZoneGrowableHandlePtrArray<Object> storage(thread->zone(), 1024);
    GetInstancesVisitor visitor(&storage, kSmiMax);
    {
      ObjectGraph graph(thread);
      HeapIterationScope iteration_scope(Thread::Current(), true);
      MarkClasses(cls, include_subclasses, include_implementers);
      graph.IterateObjects(&visitor);
      UnmarkClasses();
    }
    intptr_t count = visitor.count();
    instances = Array::New(count);
    for (intptr_t i = 0; i < count; i++) {
      instances.SetAt(i, storage.At(i));
    }
  }
  instances.PrintJSON(js, /*ref=*/true);
}

static intptr_t ParseJSONArray(Thread* thread,
                               const char* str,
                               const GrowableObjectArray& elements) {
  ASSERT(str != nullptr);
  ASSERT(thread != nullptr);
  Zone* zone = thread->zone();
  intptr_t n = strlen(str);
  if (n < 2) {
    return -1;
  }
  intptr_t start = 1;
  while (start < n) {
    intptr_t end = start;
    while ((str[end + 1] != ',') && (str[end + 1] != ']')) {
      end++;
    }
    if (end == start) {
      // Empty element
      break;
    }
    String& element = String::Handle(
        zone, String::FromUTF8(reinterpret_cast<const uint8_t*>(&str[start]),
                               end - start + 1));
    elements.Add(element);
    start = end + 3;
  }
  return 0;
}

static const MethodParameter* const get_ports_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetPorts(Thread* thread, JSONStream* js) {
  // Ensure the array and handles created below are promptly destroyed.
  StackZone zone(thread);
  const GrowableObjectArray& ports = GrowableObjectArray::Handle(
      GrowableObjectArray::RawCast(DartLibraryCalls::LookupOpenPorts()));
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "PortList");
  {
    ReceivePort& port = ReceivePort::Handle(zone.GetZone());
    JSONArray arr(&jsobj, "ports");
    for (int i = 0; i < ports.Length(); ++i) {
      port ^= ports.At(i);
      // Don't report inactive ports.
      if (PortMap::IsLivePort(port.Id())) {
        arr.AddValue(port);
      }
    }
  }
}

#if !defined(DART_PRECOMPILED_RUNTIME)
static const char* const report_enum_names[] = {
    SourceReport::kCallSitesStr,           SourceReport::kCoverageStr,
    SourceReport::kPossibleBreakpointsStr, SourceReport::kProfileStr,
    SourceReport::kBranchCoverageStr,      nullptr,
};
#endif

static const MethodParameter* const get_source_report_params[] = {
#if !defined(DART_PRECOMPILED_RUNTIME)
    RUNNABLE_ISOLATE_PARAMETER,
    new EnumListParameter("reports", true, report_enum_names),
    new IdParameter("scriptId", false),
    new UIntParameter("tokenPos", false),
    new UIntParameter("endTokenPos", false),
    new BoolParameter("forceCompile", false),
#endif
    nullptr,
};

static void GetSourceReport(Thread* thread, JSONStream* js) {
#if defined(DART_PRECOMPILED_RUNTIME)
  js->PrintError(kFeatureDisabled, "disabled in AOT mode and PRODUCT.");
#else
  if (CheckCompilerDisabled(thread, js)) {
    return;
  }

  char* reports_str = Utils::StrDup(js->LookupParam("reports"));
  const EnumListParameter* reports_parameter =
      static_cast<const EnumListParameter*>(get_source_report_params[1]);
  const char** reports = reports_parameter->Parse(reports_str);
  const char** riter = reports;
  intptr_t report_set = 0;
  while (*riter != nullptr) {
    if (strcmp(*riter, SourceReport::kCallSitesStr) == 0) {
      report_set |= SourceReport::kCallSites;
    } else if (strcmp(*riter, SourceReport::kCoverageStr) == 0) {
      report_set |= SourceReport::kCoverage;
    } else if (strcmp(*riter, SourceReport::kPossibleBreakpointsStr) == 0) {
      report_set |= SourceReport::kPossibleBreakpoints;
    } else if (strcmp(*riter, SourceReport::kProfileStr) == 0) {
      report_set |= SourceReport::kProfile;
    } else if (strcmp(*riter, SourceReport::kBranchCoverageStr) == 0) {
      report_set |= SourceReport::kBranchCoverage;
    }
    riter++;
  }
  if (reports != nullptr) {
    delete[] reports;
  }
  free(reports_str);

  SourceReport::CompileMode compile_mode = SourceReport::kNoCompile;
  if (BoolParameter::Parse(js->LookupParam("forceCompile"), false)) {
    compile_mode = SourceReport::kForceCompile;
  }

  bool report_lines =
      BoolParameter::Parse(js->LookupParam("reportLines"), false);

  Script& script = Script::Handle();
  intptr_t start_pos = UIntParameter::Parse(js->LookupParam("tokenPos"));
  intptr_t end_pos = UIntParameter::Parse(js->LookupParam("endTokenPos"));

  if (js->HasParam("scriptId")) {
    // Get the target script.
    const char* script_id_param = js->LookupParam("scriptId");
    const Object& obj =
        Object::Handle(LookupHeapObject(thread, script_id_param, nullptr));
    if (obj.ptr() == Object::sentinel().ptr() || !obj.IsScript()) {
      PrintInvalidParamError(js, "scriptId");
      return;
    }
    script ^= obj.ptr();
  } else {
    if (js->HasParam("tokenPos")) {
      js->PrintError(
          kInvalidParams,
          "%s: the 'tokenPos' parameter requires the 'scriptId' parameter",
          js->method());
      return;
    }
    if (js->HasParam("endTokenPos")) {
      js->PrintError(
          kInvalidParams,
          "%s: the 'endTokenPos' parameter requires the 'scriptId' parameter",
          js->method());
      return;
    }
  }

  const char* library_filters_param = js->LookupParam("libraryFilters");
  GrowableObjectArray& library_filters = GrowableObjectArray::Handle();
  if (library_filters_param != nullptr) {
    library_filters = GrowableObjectArray::New();
    intptr_t library_filters_length =
        ParseJSONArray(thread, library_filters_param, library_filters);
    if (library_filters_length < 0) {
      PrintInvalidParamError(js, "library_filters");
      return;
    }
  }

  SourceReport report(report_set, library_filters, compile_mode, report_lines);
  report.PrintJSON(js, script, TokenPosition::Deserialize(start_pos),
                   TokenPosition::Deserialize(end_pos));
#endif  // !DART_PRECOMPILED_RUNTIME
}

static const MethodParameter* const reload_sources_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new BoolParameter("force", false),
    new BoolParameter("pause", false),
    new StringParameter("rootLibUri", false),
    new StringParameter("packagesUri", false),
    nullptr,
};

static void ReloadSources(Thread* thread, JSONStream* js) {
#if defined(DART_PRECOMPILED_RUNTIME)
  js->PrintError(kFeatureDisabled, "Compiler is disabled in AOT mode.");
#else
  if (CheckCompilerDisabled(thread, js)) {
    return;
  }

  IsolateGroup* isolate_group = thread->isolate_group();
  if (isolate_group->library_tag_handler() == nullptr) {
    js->PrintError(kFeatureDisabled,
                   "A library tag handler must be installed.");
    return;
  }
  // TODO(dartbug.com/36097): We need to change the "reloadSources" service-api
  // call to accept an isolate group instead of an isolate.
  Isolate* isolate = thread->isolate();
  if ((isolate->sticky_error() != Error::null()) ||
      (Thread::Current()->sticky_error() != Error::null())) {
    js->PrintError(kIsolateReloadBarred,
                   "This isolate cannot reload sources anymore because there "
                   "was an unhandled exception error. Restart the isolate.");
    return;
  }
  if (isolate_group->IsReloading()) {
    js->PrintError(kIsolateIsReloading, "This isolate is being reloaded.");
    return;
  }
  if (!isolate_group->CanReload()) {
    js->PrintError(kFeatureDisabled,
                   "This isolate cannot reload sources right now.");
    return;
  }
  const bool force_reload =
      BoolParameter::Parse(js->LookupParam("force"), false);

  isolate_group->ReloadSources(js, force_reload, js->LookupParam("rootLibUri"),
                               js->LookupParam("packagesUri"));

  Service::CheckForPause(isolate, js);

#endif
}

void Service::CheckForPause(Isolate* isolate, JSONStream* stream) {
  // Should we pause?
  isolate->set_should_pause_post_service_request(
      BoolParameter::Parse(stream->LookupParam("pause"), false));
}

ErrorPtr Service::MaybePause(Isolate* isolate, const Error& error) {
  // Don't pause twice.
  if (!isolate->IsPaused()) {
    if (isolate->should_pause_post_service_request()) {
      isolate->set_should_pause_post_service_request(false);
      if (!error.IsNull()) {
        // Before pausing, restore the sticky error. The debugger will return it
        // from PausePostRequest.
        Thread::Current()->set_sticky_error(error);
      }
      return isolate->PausePostRequest();
    }
  }
  return error.ptr();
}

static void AddBreakpointCommon(Thread* thread,
                                JSONStream* js,
                                const String& script_uri) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  const char* line_param = js->LookupParam("line");
  intptr_t line = UIntParameter::Parse(line_param);
  const char* col_param = js->LookupParam("column");
  intptr_t col = -1;
  if (col_param != nullptr) {
    col = UIntParameter::Parse(col_param);
    if (col == 0) {
      // Column number is 1-based.
      PrintInvalidParamError(js, "column");
      return;
    }
  }
  ASSERT(!script_uri.IsNull());
  Breakpoint* bpt = nullptr;
  bpt = thread->isolate()->debugger()->SetBreakpointAtLineCol(script_uri, line,
                                                              col);
  if (bpt == nullptr) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at line '%s'", js->method(),
                   line_param);
    return;
  }
  bpt->PrintJSON(js);
}

static const MethodParameter* const add_breakpoint_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("scriptId", true),
    new UIntParameter("line", true),
    new UIntParameter("column", false),
    nullptr,
};

static void AddBreakpoint(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  const char* script_id_param = js->LookupParam("scriptId");
  Object& obj =
      Object::Handle(LookupHeapObject(thread, script_id_param, nullptr));
  if (obj.ptr() == Object::sentinel().ptr() || !obj.IsScript()) {
    PrintInvalidParamError(js, "scriptId");
    return;
  }
  const Script& script = Script::Cast(obj);
  const String& script_uri = String::Handle(script.url());
  ASSERT(!script_uri.IsNull());
  AddBreakpointCommon(thread, js, script_uri);
}

static const MethodParameter* const add_breakpoint_with_script_uri_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("scriptUri", true),
    new UIntParameter("line", true),
    new UIntParameter("column", false),
    nullptr,
};

static void AddBreakpointWithScriptUri(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  const char* script_uri_param = js->LookupParam("scriptUri");
  const String& script_uri = String::Handle(String::New(script_uri_param));
  AddBreakpointCommon(thread, js, script_uri);
}

static const MethodParameter* const add_breakpoint_at_entry_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("functionId", true),
    nullptr,
};

static void AddBreakpointAtEntry(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  const char* function_id = js->LookupParam("functionId");
  Object& obj = Object::Handle(LookupHeapObject(thread, function_id, nullptr));
  if (obj.ptr() == Object::sentinel().ptr() || !obj.IsFunction()) {
    PrintInvalidParamError(js, "functionId");
    return;
  }
  const Function& function = Function::Cast(obj);
  Breakpoint* bpt =
      thread->isolate()->debugger()->SetBreakpointAtEntry(function, false);
  if (bpt == nullptr) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at function '%s'", js->method(),
                   function.ToCString());
    return;
  }
  bpt->PrintJSON(js);
}

static const MethodParameter* const add_breakpoint_at_activation_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("objectId", true),
    nullptr,
};

static void AddBreakpointAtActivation(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  const char* object_id = js->LookupParam("objectId");
  Object& obj = Object::Handle(LookupHeapObject(thread, object_id, nullptr));
  if (obj.ptr() == Object::sentinel().ptr() || !obj.IsInstance()) {
    PrintInvalidParamError(js, "objectId");
    return;
  }
  const Instance& closure = Instance::Cast(obj);
  Breakpoint* bpt = thread->isolate()->debugger()->SetBreakpointAtActivation(
      closure, /*single_shot=*/false);
  if (bpt == nullptr) {
    js->PrintError(kCannotAddBreakpoint,
                   "%s: Cannot add breakpoint at activation", js->method());
    return;
  }
  bpt->PrintJSON(js);
}

static const MethodParameter* const remove_breakpoint_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void RemoveBreakpoint(Thread* thread, JSONStream* js) {
  if (CheckDebuggerDisabled(thread, js)) {
    return;
  }

  if (!js->HasParam("breakpointId")) {
    PrintMissingParamError(js, "breakpointId");
    return;
  }
  const char* bpt_id = js->LookupParam("breakpointId");
  ObjectIdRing::LookupResult lookup_result;
  Isolate* isolate = thread->isolate();
  Breakpoint* bpt = LookupBreakpoint(isolate, bpt_id, &lookup_result);
  // TODO(turnidge): Should we return a different error for bpts which
  // have been already removed?
  if (bpt == nullptr) {
    PrintInvalidParamError(js, "breakpointId");
    return;
  }
  isolate->debugger()->RemoveBreakpoint(bpt->id());
  PrintSuccess(js);
}

static void HandleNativeMetricsList(Thread* thread, JSONStream* js) {
  JSONObject obj(js);
  obj.AddProperty("type", "MetricList");
  {
    JSONArray metrics(&obj, "metrics");

    auto isolate = thread->isolate();
#define ADD_METRIC(type, variable, name, unit)                                 \
  metrics.AddValue(isolate->Get##variable##Metric());
    ISOLATE_METRIC_LIST(ADD_METRIC);
#undef ADD_METRIC

    auto isolate_group = thread->isolate_group();
#define ADD_METRIC(type, variable, name, unit)                                 \
  metrics.AddValue(isolate_group->Get##variable##Metric());
    ISOLATE_GROUP_METRIC_LIST(ADD_METRIC);
#undef ADD_METRIC
  }
}

static void HandleNativeMetric(Thread* thread, JSONStream* js, const char* id) {
  auto isolate = thread->isolate();
#define ADD_METRIC(type, variable, name, unit)                                 \
  if (strcmp(id, name) == 0) {                                                 \
    isolate->Get##variable##Metric()->PrintJSON(js);                           \
    return;                                                                    \
  }
  ISOLATE_METRIC_LIST(ADD_METRIC);
#undef ADD_METRIC

  auto isolate_group = thread->isolate_group();
#define ADD_METRIC(type, variable, name, unit)                                 \
  if (strcmp(id, name) == 0) {                                                 \
    isolate_group->Get##variable##Metric()->PrintJSON(js);                     \
    return;                                                                    \
  }
  ISOLATE_GROUP_METRIC_LIST(ADD_METRIC);
#undef ADD_METRIC

  PrintInvalidParamError(js, "metricId");
}

static const MethodParameter* const get_isolate_metric_list_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetIsolateMetricList(Thread* thread, JSONStream* js) {
  if (js->HasParam("type")) {
    if (!js->ParamIs("type", "Native")) {
      PrintInvalidParamError(js, "type");
      return;
    }
  } else {
    PrintMissingParamError(js, "type");
    return;
  }
  HandleNativeMetricsList(thread, js);
}

static const MethodParameter* const get_isolate_metric_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetIsolateMetric(Thread* thread, JSONStream* js) {
  const char* metric_id = js->LookupParam("metricId");
  if (metric_id == nullptr) {
    PrintMissingParamError(js, "metricId");
    return;
  }
  // Verify id begins with "metrics/native/".
  static const char* const kNativeMetricIdPrefix = "metrics/native/";
  static intptr_t kNativeMetricIdPrefixLen = strlen(kNativeMetricIdPrefix);
  if (strncmp(metric_id, kNativeMetricIdPrefix, kNativeMetricIdPrefixLen) !=
      0) {
    PrintInvalidParamError(js, "metricId");
    return;
  }
  const char* id = metric_id + kNativeMetricIdPrefixLen;
  HandleNativeMetric(thread, js, id);
}

enum TimelineOrSamplesResponseFormat : bool { JSON = false, Perfetto = true };

static void GetCpuSamplesCommon(TimelineOrSamplesResponseFormat format,
                                Thread* thread,
                                JSONStream* js) {
  const int64_t time_origin_micros =
      Int64Parameter::Parse(js->LookupParam("timeOriginMicros"));
  const int64_t time_extent_micros =
      Int64Parameter::Parse(js->LookupParam("timeExtentMicros"));
  const bool include_code_samples =
      BoolParameter::Parse(js->LookupParam("_code"), false);
  if (CheckProfilerDisabled(thread, js)) {
    return;
  }

  if (format == TimelineOrSamplesResponseFormat::JSON) {
    ProfilerService::PrintJSON(js, time_origin_micros, time_extent_micros,
                               include_code_samples);
  } else if (format == TimelineOrSamplesResponseFormat::Perfetto) {
#if defined(SUPPORT_PERFETTO)
    // This branch will never be reached when SUPPORT_PERFETTO is not defined,
    // because |GetPerfettoCpuSamples| is not defined when SUPPORT_PERFETTO is
    // not defined.
    ProfilerService::PrintPerfetto(js, time_origin_micros, time_extent_micros);
#else
    UNREACHABLE();
#endif  // defined(SUPPORT_PERFETTO)
  }
}

inline void GetVMTimelineCommon(TimelineOrSamplesResponseFormat format,
                                Thread* thread,
                                JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != nullptr);
  StackZone zone(thread);
  TimelineEventRecorder* timeline_recorder = Timeline::recorder();
  ASSERT(timeline_recorder != nullptr);
  const char* name = timeline_recorder->name();
  if (strcmp(name, CALLBACK_RECORDER_NAME) == 0) {
    js->PrintError(kInvalidTimelineRequest,
                   "A recorder of type \"%s\" is currently in use. As a "
                   "result, timeline events are handled by the embedder rather "
                   "than the VM.",
                   timeline_recorder->name());
    return;
  } else if (strcmp(name, FUCHSIA_RECORDER_NAME) == 0 ||
             strcmp(name, SYSTRACE_RECORDER_NAME) == 0 ||
             strcmp(name, MACOS_RECORDER_NAME) == 0) {
    js->PrintError(
        kInvalidTimelineRequest,
        "A recorder of type \"%s\" is currently in use. As a result, timeline "
        "events are handled by the OS rather than the VM. See the VM service "
        "documentation for more details on where timeline events can be found "
        "for this recorder type.",
        timeline_recorder->name());
    return;
  } else if (strcmp(name, FILE_RECORDER_NAME) == 0 ||
             strcmp(name, PERFETTO_FILE_RECORDER_NAME) == 0) {
    js->PrintError(kInvalidTimelineRequest,
                   "A recorder of type \"%s\" is currently in use. As a "
                   "result, timeline events are written directly to a file and "
                   "thus cannot be retrieved through the VM Service.",
                   timeline_recorder->name());
    return;
  }
  int64_t time_origin_micros =
      Int64Parameter::Parse(js->LookupParam("timeOriginMicros"));
  int64_t time_extent_micros =
      Int64Parameter::Parse(js->LookupParam("timeExtentMicros"));
  TimelineEventFilter filter(time_origin_micros, time_extent_micros);
  if (format == TimelineOrSamplesResponseFormat::JSON) {
    timeline_recorder->PrintJSON(js, &filter);
  } else if (format == TimelineOrSamplesResponseFormat::Perfetto) {
#if defined(SUPPORT_PERFETTO)
    // This branch will never be reached when SUPPORT_PERFETTO is not defined,
    // because |GetPerfettoVMTimeline| is not defined when SUPPORT_PERFETTO is
    // not defined.
    timeline_recorder->PrintPerfettoTimeline(js, filter);
#else
    UNREACHABLE();
#endif  // defined(SUPPORT_PERFETTO)
  }
}

#if defined(SUPPORT_PERFETTO)
static void GetPerfettoCpuSamples(Thread* thread, JSONStream* js) {
  GetCpuSamplesCommon(TimelineOrSamplesResponseFormat::Perfetto, thread, js);
}

static void GetPerfettoVMTimeline(Thread* thread, JSONStream* js) {
  GetVMTimelineCommon(TimelineOrSamplesResponseFormat::Perfetto, thread, js);
}
#endif  // defined(SUPPORT_PERFETTO)

static void SetVMTimelineFlags(Thread* thread, JSONStream* js) {
#if !defined(SUPPORT_TIMELINE)
  PrintSuccess(js);
#else
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != nullptr);
  StackZone zone(thread);

  char* recorded_streams = Utils::StrDup(js->LookupParam("recordedStreams"));
  Service::EnableTimelineStreams(recorded_streams);
  free(recorded_streams);

  PrintSuccess(js);
#endif
}

static const MethodParameter* const get_vm_timeline_flags_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void GetVMTimelineFlags(Thread* thread, JSONStream* js) {
#if !defined(SUPPORT_TIMELINE)
  JSONObject obj(js);
  obj.AddProperty("type", "TimelineFlags");
#else
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != nullptr);
  StackZone zone(thread);
  Timeline::PrintFlagsToJSON(js);
#endif
}

static const MethodParameter* const get_vm_timeline_micros_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void GetVMTimelineMicros(Thread* thread, JSONStream* js) {
  JSONObject obj(js);
  obj.AddProperty("type", "Timestamp");
  obj.AddPropertyTimeMicros("timestamp", OS::GetCurrentMonotonicMicros());
}

static const MethodParameter* const clear_vm_timeline_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void ClearVMTimeline(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != nullptr);
  StackZone zone(thread);

  Timeline::Clear();

  PrintSuccess(js);
}

static const MethodParameter* const get_vm_timeline_params[] = {
    NO_ISOLATE_PARAMETER,
    new Int64Parameter("timeOriginMicros", /*required=*/false),
    new Int64Parameter("timeExtentMicros", /*required=*/false),
    nullptr,
};

static void GetVMTimeline(Thread* thread, JSONStream* js) {
  GetVMTimelineCommon(TimelineOrSamplesResponseFormat::JSON, thread, js);
}

static const char* const step_enum_names[] = {
    "None", "Into", "Over", "Out", "Rewind", "OverAsyncSuspension", nullptr,
};

static const Debugger::ResumeAction step_enum_values[] = {
    Debugger::kContinue,   Debugger::kStepInto,
    Debugger::kStepOver,   Debugger::kStepOut,
    Debugger::kStepRewind, Debugger::kStepOverAsyncSuspension,
    Debugger::kContinue,  // Default value
};

static const MethodParameter* const resume_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new EnumParameter("step", false, step_enum_names),
    new UIntParameter("frameIndex", false),
    nullptr,
};

static void Resume(Thread* thread, JSONStream* js) {
  const char* step_param = js->LookupParam("step");
  Debugger::ResumeAction step = Debugger::kContinue;
  if (step_param != nullptr) {
    step = EnumMapper(step_param, step_enum_names, step_enum_values);
  }
  intptr_t frame_index = 1;
  const char* frame_index_param = js->LookupParam("frameIndex");
  if (frame_index_param != nullptr) {
    if (step != Debugger::kStepRewind) {
      // Only rewind supports the frameIndex parameter.
      js->PrintError(
          kInvalidParams,
          "%s: the 'frameIndex' parameter can only be used when rewinding",
          js->method());
      return;
    }
    frame_index = UIntParameter::Parse(js->LookupParam("frameIndex"));
  }
  Isolate* isolate = thread->isolate();
  if (isolate->message_handler()->is_paused_on_start()) {
    // If the user is issuing a 'Over' or an 'Out' step, that is the
    // same as a regular resume request.
    if (step == Debugger::kStepInto) {
      isolate->debugger()->EnterSingleStepMode();
    }
    isolate->message_handler()->set_should_pause_on_start(false);
    isolate->SetResumeRequest();
    if (Service::debug_stream.enabled()) {
      ServiceEvent event(isolate, ServiceEvent::kResume);
      Service::HandleEvent(&event);
    }
    PrintSuccess(js);
    return;
  }
  if (isolate->message_handler()->should_pause_on_start()) {
    isolate->message_handler()->set_should_pause_on_start(false);
    isolate->SetResumeRequest();
    if (Service::debug_stream.enabled()) {
      ServiceEvent event(isolate, ServiceEvent::kResume);
      Service::HandleEvent(&event);
    }
    PrintSuccess(js);
    return;
  }
  if (isolate->message_handler()->is_paused_on_exit()) {
    isolate->message_handler()->set_should_pause_on_exit(false);
    isolate->SetResumeRequest();
    // We don't send a resume event because we will be exiting.
    PrintSuccess(js);
    return;
  }
  if (isolate->debugger()->PauseEvent() == nullptr) {
    js->PrintError(kIsolateMustBePaused, nullptr);
    return;
  }

  const char* error = nullptr;
  if (!isolate->debugger()->SetResumeAction(step, frame_index, &error)) {
    js->PrintError(kCannotResume, "%s", error);
    return;
  }
  isolate->SetResumeRequest();
  PrintSuccess(js);
}

static const MethodParameter* const kill_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void Kill(Thread* thread, JSONStream* js) {
  const String& msg =
      String::Handle(String::New("isolate terminated by Kill service request"));
  const UnwindError& error = UnwindError::Handle(UnwindError::New(msg));
  error.set_is_user_initiated(true);
  Thread::Current()->set_sticky_error(error);
  PrintSuccess(js);
}

static const MethodParameter* const pause_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void Pause(Thread* thread, JSONStream* js) {
  // TODO(turnidge): This interrupt message could have been sent from
  // the service isolate directly, but would require some special case
  // code.  That would prevent this isolate getting double-interrupted
  // with OOB messages.
  Isolate* isolate = thread->isolate();
  isolate->SendInternalLibMessage(Isolate::kInterruptMsg,
                                  isolate->pause_capability());
  PrintSuccess(js);
}

static const MethodParameter* const enable_profiler_params[] = {
    nullptr,
};

static void EnableProfiler(Thread* thread, JSONStream* js) {
  if (!FLAG_profiler) {
    FLAG_profiler = true;
    Profiler::Init();
  }
  PrintSuccess(js);
}

static const MethodParameter* const get_tag_profile_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetTagProfile(Thread* thread, JSONStream* js) {
  JSONObject miniProfile(js);
  miniProfile.AddProperty("type", "TagProfile");
  thread->isolate()->vm_tag_counters()->PrintToJSONObject(&miniProfile);
}

static const MethodParameter* const get_cpu_samples_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new Int64Parameter("timeOriginMicros", /*required=*/false),
    new Int64Parameter("timeExtentMicros", /*required=*/false),
    nullptr,
};

static void GetCpuSamples(Thread* thread, JSONStream* js) {
  GetCpuSamplesCommon(TimelineOrSamplesResponseFormat::JSON, thread, js);
}

static const MethodParameter* const get_allocation_traces_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("classId", false),
    new Int64Parameter("timeOriginMicros", false),
    new Int64Parameter("timeExtentMicros", false),
    nullptr,
};

static void GetAllocationTraces(Thread* thread, JSONStream* js) {
  int64_t time_origin_micros =
      Int64Parameter::Parse(js->LookupParam("timeOriginMicros"));
  int64_t time_extent_micros =
      Int64Parameter::Parse(js->LookupParam("timeExtentMicros"));
  Isolate* isolate = thread->isolate();

  // Return only allocations for objects with classId.
  if (js->HasParam("classId")) {
    const char* class_id = js->LookupParam("classId");
    intptr_t cid = -1;
    GetPrefixedIntegerId(class_id, "classes/", &cid);
    if (IsValidClassId(isolate, cid)) {
      if (CheckProfilerDisabled(thread, js)) {
        return;
      }
      const Class& cls = Class::Handle(GetClassForId(isolate, cid));
      ProfilerService::PrintAllocationJSON(js, cls, time_origin_micros,
                                           time_extent_micros);
    } else {
      PrintInvalidParamError(js, "classId");
    }
  } else {
    // Otherwise, return allocations for all traced class IDs.
    if (CheckProfilerDisabled(thread, js)) {
      return;
    }
    ProfilerService::PrintAllocationJSON(js, time_origin_micros,
                                         time_extent_micros);
  }
}

static const MethodParameter* const clear_cpu_samples_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void ClearCpuSamples(Thread* thread, JSONStream* js) {
  ProfilerService::ClearSamples();
  PrintSuccess(js);
}

static void GetAllocationProfileImpl(Thread* thread,
                                     JSONStream* js,
                                     bool internal) {
  bool should_reset_accumulator = false;
  bool should_collect = false;
  if (js->HasParam("reset")) {
    if (js->ParamIs("reset", "true")) {
      should_reset_accumulator = true;
    } else {
      PrintInvalidParamError(js, "reset");
      return;
    }
  }
  if (js->HasParam("gc")) {
    if (js->ParamIs("gc", "true")) {
      should_collect = true;
    } else {
      PrintInvalidParamError(js, "gc");
      return;
    }
  }
  auto isolate_group = thread->isolate_group();
  if (should_reset_accumulator) {
    isolate_group->UpdateLastAllocationProfileAccumulatorResetTimestamp();
  }
  if (should_collect) {
    isolate_group->UpdateLastAllocationProfileGCTimestamp();
    isolate_group->heap()->CollectAllGarbage(GCReason::kDebugging);
  }
  isolate_group->class_table()->AllocationProfilePrintJSON(js, internal);
}

static const MethodParameter* const get_allocation_profile_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetAllocationProfilePublic(Thread* thread, JSONStream* js) {
  GetAllocationProfileImpl(thread, js, false);
}

static void GetAllocationProfile(Thread* thread, JSONStream* js) {
  GetAllocationProfileImpl(thread, js, true);
}

static const MethodParameter* const collect_all_garbage_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void CollectAllGarbage(Thread* thread, JSONStream* js) {
  auto heap = thread->isolate_group()->heap();
  heap->CollectAllGarbage(GCReason::kDebugging);
  PrintSuccess(js);
}

static const MethodParameter* const get_heap_map_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetHeapMap(Thread* thread, JSONStream* js) {
  auto isolate_group = thread->isolate_group();
  if (js->HasParam("gc")) {
    if (js->ParamIs("gc", "scavenge")) {
      isolate_group->heap()->CollectGarbage(thread, GCType::kScavenge,
                                            GCReason::kDebugging);
    } else if (js->ParamIs("gc", "mark-sweep")) {
      isolate_group->heap()->CollectGarbage(thread, GCType::kMarkSweep,
                                            GCReason::kDebugging);
    } else if (js->ParamIs("gc", "mark-compact")) {
      isolate_group->heap()->CollectGarbage(thread, GCType::kMarkCompact,
                                            GCReason::kDebugging);
    } else {
      PrintInvalidParamError(js, "gc");
      return;
    }
  }
  isolate_group->heap()->PrintHeapMapToJSONStream(isolate_group, js);
}

static const MethodParameter* const request_heap_snapshot_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void RequestHeapSnapshot(Thread* thread, JSONStream* js) {
  if (Service::heapsnapshot_stream.enabled()) {
    VmServiceHeapSnapshotChunkedWriter vmservice_writer(thread);
    HeapSnapshotWriter writer(thread, &vmservice_writer);
    writer.Write();
  }
  // TODO(koda): Provide some id that ties this request to async response(s).
  PrintSuccess(js);
}

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
struct VMMapping {
  char path[256];
  size_t size;
};

static void AddVMMappings(JSONArray* rss_children) {
  FILE* fp = fopen("/proc/self/smaps", "r");
  if (fp == nullptr) {
    return;
  }

  MallocGrowableArray<VMMapping> mappings(10);
  char line[256];
  char path[256];
  char property[32];
  size_t start, end, size;
  while (fgets(line, sizeof(line), fp) != nullptr) {
    if (sscanf(line, "%zx-%zx", &start, &end) == 2) {
      // Mapping line.
      strncpy(path, strrchr(line, ' ') + 1, sizeof(path) - 1);
      int len = strlen(path);
      if ((len > 0) && path[len - 1] == '\n') {
        path[len - 1] = 0;
      }
    } else if (sscanf(line, "%s%zd", property, &size) == 2) {
      // Property line.
      // Skipping a few paths to avoid double counting:
      // (deleted) - memfd dual mapping in Dart heap
      // [heap] - sbrk area, should already included with malloc
      // <empty> - anonymous mappings, mostly in Dart heap (Linux)
      // [anon:dart-*] - as labelled (Android)
      if ((strcmp(property, "Rss:") == 0) && (size != 0) &&
          (strcmp(path, "(deleted)") != 0) && (strcmp(path, "[heap]") != 0) &&
          (strcmp(path, "") != 0) && (strcmp(path, "[anon:dart-heap]") != 0) &&
          (strcmp(path, "[anon:dart-code]") != 0) &&
          (strcmp(path, "[anon:dart-profiler]") != 0) &&
          (strcmp(path, "[anon:dart-timeline]") != 0) &&
          (strcmp(path, "[anon:dart-zone]") != 0)) {
        bool updated = false;
        for (intptr_t i = 0; i < mappings.length(); i++) {
          if (strcmp(mappings[i].path, path) == 0) {
            mappings[i].size += size;
            updated = true;
            break;
          }
        }
        if (!updated) {
          VMMapping mapping;
          strncpy(mapping.path, path, sizeof(mapping.path));
          mapping.size = size;
          mappings.Add(mapping);
        }
      }
    }
  }
  fclose(fp);

  for (intptr_t i = 0; i < mappings.length(); i++) {
    JSONObject mapping(rss_children);
    mapping.AddProperty("name", mappings[i].path);
    mapping.AddProperty("description",
                        "Mapped file / shared library / executable");
    mapping.AddProperty64("size", mappings[i].size * KB);
    JSONArray(&mapping, "children");
  }
}
#endif

static intptr_t GetProcessMemoryUsageHelper(JSONStream* js) {
  JSONObject response(js);
  response.AddProperty("type", "ProcessMemoryUsage");

  JSONObject rss(&response, "root");
  rss.AddPropertyF("name", "Process %" Pd "", OS::ProcessId());
  rss.AddProperty("description", "Resident set size");
  rss.AddProperty64("size", Service::CurrentRSS());
  JSONArray rss_children(&rss, "children");

  intptr_t vm_size = 0;
  {
    JSONObject vm(&rss_children);
    {
      JSONArray vm_children(&vm, "children");

      {
        JSONObject profiler(&vm_children);
        profiler.AddProperty("name", "Profiler");
        profiler.AddProperty("description",
                             "Samples from the Dart VM's profiler");
        intptr_t size = Profiler::Size();
        vm_size += size;
        profiler.AddProperty64("size", size);
        JSONArray(&profiler, "children");
      }

      {
        JSONObject timeline(&vm_children);
        timeline.AddProperty("name", "Timeline");
        timeline.AddProperty(
            "description",
            "Timeline events from dart:developer and Dart_TimelineEvent");
        intptr_t size = Timeline::recorder()->Size();
        vm_size += size;
        timeline.AddProperty64("size", size);
        JSONArray(&timeline, "children");
      }

      {
        JSONObject zone(&vm_children);
        zone.AddProperty("name", "Zone");
        zone.AddProperty("description", "Arena allocation in the Dart VM");
        intptr_t size = Zone::Size();
        vm_size += size;
        zone.AddProperty64("size", size);
        JSONArray(&zone, "children");
      }

      {
        JSONObject semi(&vm_children);
        semi.AddProperty("name", "Page Cache");
        semi.AddProperty("description", "Cached heap regions");
        intptr_t size = Page::CachedSize();
        vm_size += size;
        semi.AddProperty64("size", size);
        JSONArray(&semi, "children");
      }

      IsolateGroup::ForEach([&vm_children,
                             &vm_size](IsolateGroup* isolate_group) {
        // Note: new_space()->CapacityInWords() includes memory that hasn't been
        // allocated from the OS yet.
        int64_t capacity =
            (isolate_group->heap()->new_space()->UsedInWords() +
             isolate_group->heap()->old_space()->CapacityInWords()) *
            kWordSize;
        int64_t used = isolate_group->heap()->TotalUsedInWords() * kWordSize;
        int64_t free = capacity - used;

        JSONObject group(&vm_children);
        group.AddPropertyF("name", "IsolateGroup %s",
                           isolate_group->source()->name);
        group.AddProperty("description", "Dart heap capacity");
        vm_size += capacity;
        group.AddProperty64("size", capacity);
        JSONArray group_children(&group, "children");

        {
          JSONObject jsused(&group_children);
          jsused.AddProperty("name", "Used");
          jsused.AddProperty("description", "");
          jsused.AddProperty64("size", used);
          JSONArray(&jsused, "children");
        }

        {
          JSONObject jsfree(&group_children);
          jsfree.AddProperty("name", "Free");
          jsfree.AddProperty("description", "");
          jsfree.AddProperty64("size", free);
          JSONArray(&jsfree, "children");
        }
      });
    }  // vm_children

    vm.AddProperty("name", "Dart VM");
    vm.AddProperty("description", "");
    vm.AddProperty64("size", vm_size);
  }

#if defined(DART_HOST_OS_LINUX) || defined(DART_HOST_OS_ANDROID)
  AddVMMappings(&rss_children);
#endif
  // TODO(46166): Implement for other operating systems.

  return vm_size;
}

static const MethodParameter* const get_process_memory_usage_params[] = {
    nullptr,
};

static void GetProcessMemoryUsage(Thread* thread, JSONStream* js) {
  GetProcessMemoryUsageHelper(js);
}

void Service::SendInspectEvent(Isolate* isolate, const Object& inspectee) {
  if (!Service::debug_stream.enabled()) {
    return;
  }
  ServiceEvent event(isolate, ServiceEvent::kInspect);
  event.set_inspectee(&inspectee);
  Service::HandleEvent(&event);
}

void Service::SendEmbedderEvent(Isolate* isolate,
                                const char* stream_id,
                                const char* event_kind,
                                const uint8_t* bytes,
                                intptr_t bytes_len) {
  ServiceEvent event(isolate, ServiceEvent::kEmbedder);
  event.set_embedder_kind(event_kind);
  event.set_embedder_stream_id(stream_id);
  event.set_bytes(bytes, bytes_len);
  Service::HandleEvent(&event, /*enter_safepoint=*/false);
}

void Service::SendLogEvent(Isolate* isolate,
                           int64_t sequence_number,
                           int64_t timestamp,
                           intptr_t level,
                           const String& name,
                           const String& message,
                           const Instance& zone,
                           const Object& error,
                           const Instance& stack_trace) {
  if (!Service::logging_stream.enabled()) {
    return;
  }
  ServiceEvent::LogRecord log_record;
  log_record.sequence_number = sequence_number;
  log_record.timestamp = timestamp;
  log_record.level = level;
  log_record.name = &name;
  log_record.message = &message;
  log_record.zone = &zone;
  log_record.error = &error;
  log_record.stack_trace = &stack_trace;
  ServiceEvent event(isolate, ServiceEvent::kLogging);
  event.set_log_record(log_record);
  Service::HandleEvent(&event);
}

void Service::SendExtensionEvent(Isolate* isolate,
                                 const String& event_kind,
                                 const String& event_data) {
  if (!Service::extension_stream.enabled()) {
    return;
  }
  ServiceEvent::ExtensionEvent extension_event;
  extension_event.event_kind = &event_kind;
  extension_event.event_data = &event_data;
  ServiceEvent event(isolate, ServiceEvent::kExtension);
  event.set_extension_event(extension_event);
  Service::HandleEvent(&event);
}

static const MethodParameter* const get_persistent_handles_params[] = {
    ISOLATE_PARAMETER,
    nullptr,
};

template <typename T>
class PersistentHandleVisitor : public HandleVisitor {
 public:
  PersistentHandleVisitor(Thread* thread, JSONArray* handles)
      : HandleVisitor(thread), handles_(handles) {
    ASSERT(handles_ != nullptr);
  }

  void Append(PersistentHandle* persistent_handle) {
    JSONObject obj(handles_);
    obj.AddProperty("type", "_PersistentHandle");
    const Object& object = Object::Handle(persistent_handle->ptr());
    obj.AddProperty("object", object);
  }

  void Append(FinalizablePersistentHandle* weak_persistent_handle) {
    if (!weak_persistent_handle->ptr()->IsHeapObject()) {
      return;  // Free handle.
    }

    JSONObject obj(handles_);
    obj.AddProperty("type", "_WeakPersistentHandle");
    const Object& object = Object::Handle(weak_persistent_handle->ptr());
    obj.AddProperty("object", object);
    obj.AddPropertyF(
        "peer", "0x%" Px "",
        reinterpret_cast<uintptr_t>(weak_persistent_handle->peer()));
    obj.AddPropertyF(
        "callbackAddress", "0x%" Px "",
        reinterpret_cast<uintptr_t>(weak_persistent_handle->callback()));
    // Attempt to include a native symbol name.
    char* name = NativeSymbolResolver::LookupSymbolName(
        reinterpret_cast<uword>(weak_persistent_handle->callback()), nullptr);
    obj.AddProperty("callbackSymbolName", (name == nullptr) ? "" : name);
    if (name != nullptr) {
      NativeSymbolResolver::FreeSymbolName(name);
    }
    obj.AddPropertyF("externalSize", "%" Pd "",
                     weak_persistent_handle->external_size());
  }

 protected:
  void VisitHandle(uword addr) override {
    T* handle = reinterpret_cast<T*>(addr);
    Append(handle);
  }

  JSONArray* handles_;
};

static void GetPersistentHandles(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  ASSERT(isolate != nullptr);

  ApiState* api_state = isolate->group()->api_state();
  ASSERT(api_state != nullptr);

  {
    JSONObject obj(js);
    obj.AddProperty("type", "_PersistentHandles");
    // Persistent handles.
    {
      JSONArray persistent_handles(&obj, "persistentHandles");
      api_state->RunWithLockedPersistentHandles(
          [&](PersistentHandles& handles) {
            PersistentHandleVisitor<PersistentHandle> visitor(
                thread, &persistent_handles);
            handles.Visit(&visitor);
          });
    }
    // Weak persistent handles.
    {
      JSONArray weak_persistent_handles(&obj, "weakPersistentHandles");
      api_state->RunWithLockedWeakPersistentHandles(
          [&](FinalizablePersistentHandles& handles) {
            PersistentHandleVisitor<FinalizablePersistentHandle> visitor(
                thread, &weak_persistent_handles);
            handles.VisitHandles(&visitor);
          });
    }
  }
}

static const MethodParameter* const get_ports_private_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetPortsPrivate(Thread* thread, JSONStream* js) {
  MessageHandler* message_handler = thread->isolate()->message_handler();
  PortMap::PrintPortsForMessageHandler(message_handler, js);
}

static void RespondWithMalformedJson(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("a", "a");
  JSONObject jsobj1(js);
  jsobj1.AddProperty("a", "a");
  JSONObject jsobj2(js);
  jsobj2.AddProperty("a", "a");
  JSONObject jsobj3(js);
  jsobj3.AddProperty("a", "a");
}

static void RespondWithMalformedObject(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("bart", "simpson");
}

// Returns |true| if a heap object with the specified ID was successfully found,
// and |false| otherwise. If an object was found, it will be stored at address
// |obj|.
// This function should be used to handle shared logic between |GetObject| and
// |GetImplementationFields|.
static bool GetHeapObjectCommon(Thread* thread,
                                JSONStream* js,
                                const char* id,
                                Object* obj,
                                ObjectIdRing::LookupResult* lookup_result) {
  *obj = LookupHeapObject(thread, id, lookup_result);
  ASSERT(obj != nullptr);
  ASSERT(lookup_result != nullptr);
  if (obj->ptr() != Object::sentinel().ptr()) {
#if !defined(DART_PRECOMPILED_RUNTIME)
    // If obj is a script from dart:* and doesn't have source loaded, try and
    // load the source before sending the response.
    if (obj->IsScript()) {
      const Script& script = Script::Cast(*obj);
      if (!script.HasSource() && script.IsPartOfDartColonLibrary() &&
          Service::HasDartLibraryKernelForSources()) {
        const uint8_t* kernel_buffer = Service::dart_library_kernel();
        const intptr_t kernel_buffer_len =
            Service::dart_library_kernel_length();
        script.LoadSourceFromKernel(kernel_buffer, kernel_buffer_len);
      }
    }
#endif  // !defined(DART_PRECOMPILED_RUNTIME)
    // We found a heap object for this id.
    return true;
  }

  return false;
}

static const MethodParameter* const get_object_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new UIntParameter("offset", false),
    new UIntParameter("count", false),
    nullptr,
};

static void GetObject(Thread* thread, JSONStream* js) {
  const char* id = js->LookupParam("objectId");
  if (id == nullptr) {
    PrintMissingParamError(js, "objectId");
    return;
  }
  if (js->HasParam("offset")) {
    intptr_t value = UIntParameter::Parse(js->LookupParam("offset"));
    if (value < 0) {
      PrintInvalidParamError(js, "offset");
      return;
    }
    js->set_offset(value);
  }
  if (js->HasParam("count")) {
    intptr_t value = UIntParameter::Parse(js->LookupParam("count"));
    if (value < 0) {
      PrintInvalidParamError(js, "count");
      return;
    }
    js->set_count(value);
  }

  // Handle heap objects.
  Object& obj = Object::Handle();
  ObjectIdRing::LookupResult lookup_result;
  if (GetHeapObjectCommon(thread, js, id, &obj, &lookup_result)) {
    obj.PrintJSON(js, false);
    return;
  } else if (lookup_result == ObjectIdRing::kCollected) {
    PrintSentinel(js, kCollectedSentinel);
    return;
  } else if (lookup_result == ObjectIdRing::kExpired) {
    PrintSentinel(js, kExpiredSentinel);
    return;
  }

  // Handle non-heap objects.
  Breakpoint* bpt = LookupBreakpoint(thread->isolate(), id, &lookup_result);
  if (bpt != nullptr) {
    bpt->PrintJSON(js);
    return;
  } else if (lookup_result == ObjectIdRing::kCollected) {
    PrintSentinel(js, kCollectedSentinel);
    return;
  }

  PrintInvalidParamError(js, "objectId");
}

static const MethodParameter* const get_implementation_fields_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    OBJECT_PARAMETER,
    nullptr,
};

static void GetImplementationFields(Thread* thread, JSONStream* js) {
  const char* id = js->LookupParam("objectId");

  // Handle heap objects.
  Object& obj = Object::Handle();
  ObjectIdRing::LookupResult lookup_result;
  if (GetHeapObjectCommon(thread, js, id, &obj, &lookup_result)) {
    obj.PrintImplementationFields(js);
    return;
  } else if (lookup_result == ObjectIdRing::kCollected) {
    PrintSentinel(js, kCollectedSentinel);
    return;
  } else if (lookup_result == ObjectIdRing::kExpired) {
    PrintSentinel(js, kExpiredSentinel);
    return;
  }

  // Handle non-heap objects.
  Breakpoint* bpt = LookupBreakpoint(thread->isolate(), id, &lookup_result);
  if (bpt != nullptr) {
    const JSONObject jsobj(js);
    jsobj.AddProperty("type", "ImplementationFields");
    JSONArray jsarr_fields(&jsobj, "fields");
    return;
  } else if (lookup_result == ObjectIdRing::kCollected) {
    PrintSentinel(js, kCollectedSentinel);
    return;
  }

  PrintInvalidParamError(js, "objectId");
}

static const MethodParameter* const get_object_store_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetObjectStore(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  thread->isolate_group()->object_store()->PrintToJSONObject(&jsobj);
}

static const MethodParameter* const get_isolate_object_store_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetIsolateObjectStore(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  thread->isolate()->isolate_object_store()->PrintToJSONObject(&jsobj);
}

static const MethodParameter* const get_class_list_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetClassList(Thread* thread, JSONStream* js) {
  ClassTable* table = thread->isolate_group()->class_table();
  JSONObject jsobj(js);
  table->PrintToJSONObject(&jsobj);
}

static const MethodParameter* const get_type_arguments_list_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    nullptr,
};

static void GetTypeArgumentsList(Thread* thread, JSONStream* js) {
  bool only_with_instantiations = false;
  if (js->ParamIs("onlyWithInstantiations", "true")) {
    only_with_instantiations = true;
  }
  Zone* zone = thread->zone();
  ObjectStore* object_store = thread->isolate_group()->object_store();
  CanonicalTypeArgumentsSet typeargs_table(
      zone, object_store->canonical_type_arguments());
  const intptr_t table_size = typeargs_table.NumEntries();
  const intptr_t table_used = typeargs_table.NumOccupied();
  const Array& typeargs_array =
      Array::Handle(zone, HashTables::ToArray(typeargs_table, false));
  ASSERT(typeargs_array.Length() == table_used);
  TypeArguments& typeargs = TypeArguments::Handle(zone);
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "TypeArgumentsList");
  jsobj.AddProperty("canonicalTypeArgumentsTableSize", table_size);
  jsobj.AddProperty("canonicalTypeArgumentsTableUsed", table_used);
  JSONArray members(&jsobj, "typeArguments");
  for (intptr_t i = 0; i < table_used; i++) {
    typeargs ^= typeargs_array.At(i);
    if (!typeargs.IsNull()) {
      if (!only_with_instantiations || typeargs.HasInstantiations()) {
        members.AddValue(typeargs);
      }
    }
  }
  typeargs_table.Release();
}

static const MethodParameter* const get_version_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void GetVersion(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "Version");
  jsobj.AddProperty("major",
                    static_cast<intptr_t>(SERVICE_PROTOCOL_MAJOR_VERSION));
  jsobj.AddProperty("minor",
                    static_cast<intptr_t>(SERVICE_PROTOCOL_MINOR_VERSION));
  jsobj.AddProperty("_privateMajor", static_cast<intptr_t>(0));
  jsobj.AddProperty("_privateMinor", static_cast<intptr_t>(0));
}

class ServiceIsolateVisitor : public IsolateVisitor {
 public:
  explicit ServiceIsolateVisitor(JSONArray* jsarr) : jsarr_(jsarr) {}
  virtual ~ServiceIsolateVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    if (!IsSystemIsolate(isolate) && isolate->is_service_registered()) {
      jsarr_->AddValue(isolate);
    }
  }

 private:
  JSONArray* jsarr_;
};

class SystemServiceIsolateVisitor : public IsolateVisitor {
 public:
  explicit SystemServiceIsolateVisitor(JSONArray* jsarr) : jsarr_(jsarr) {}
  virtual ~SystemServiceIsolateVisitor() {}

  void VisitIsolate(Isolate* isolate) {
    if (IsSystemIsolate(isolate) &&
        !Dart::VmIsolateNameEquals(isolate->name())) {
      jsarr_->AddValue(isolate);
    }
  }

 private:
  JSONArray* jsarr_;
};

static const MethodParameter* const get_vm_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

void Service::PrintJSONForEmbedderInformation(JSONObject* jsobj) {
  if (embedder_information_callback_ != nullptr) {
    Dart_EmbedderInformation info = {
        0,        // version
        nullptr,  // name
        -1,       // max_rss
        -1        // current_rss
    };
    embedder_information_callback_(&info);
    ASSERT(info.version == DART_EMBEDDER_INFORMATION_CURRENT_VERSION);
    if (info.name != nullptr) {
      jsobj->AddProperty("_embedder", info.name);
    }
    if (info.max_rss >= 0) {
      jsobj->AddProperty64("_maxRSS", info.max_rss);
    }
    if (info.current_rss >= 0) {
      jsobj->AddProperty64("_currentRSS", info.current_rss);
    }
  }
}

void Service::PrintJSONForVM(JSONStream* js, bool ref) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", (ref ? "@VM" : "VM"));
  jsobj.AddProperty("name", GetVMName());
  if (ref) {
    return;
  }
  jsobj.AddProperty("architectureBits", static_cast<intptr_t>(kBitsPerWord));
  jsobj.AddProperty("hostCPU", HostCPUFeatures::hardware());
  jsobj.AddProperty("operatingSystem", OS::Name());
  jsobj.AddProperty("targetCPU", CPU::Id());
  jsobj.AddProperty("version", Version::String());
#if defined(DART_PRECOMPILED_RUNTIME)
  Snapshot::Kind kind = Snapshot::kFullAOT;
#else
  Snapshot::Kind kind = Snapshot::kFullJIT;
#endif
  char* features_string = Dart::FeaturesString(nullptr, true, kind);
  jsobj.AddProperty("_features", features_string);
  free(features_string);
  jsobj.AddProperty("_profilerMode", FLAG_profile_vm ? "VM" : "Dart");
  jsobj.AddProperty64("pid", OS::ProcessId());
  jsobj.AddPropertyTimeMillis(
      "startTime", OS::GetCurrentTimeMillis() - Dart::UptimeMillis());
  PrintJSONForEmbedderInformation(&jsobj);
  // Construct the isolate and isolate_groups list.
  {
    JSONArray jsarr(&jsobj, "isolates");
    ServiceIsolateVisitor visitor(&jsarr);
    Isolate::VisitIsolates(&visitor);
  }
  {
    JSONArray jsarr(&jsobj, "systemIsolates");
    SystemServiceIsolateVisitor visitor(&jsarr);
    Isolate::VisitIsolates(&visitor);
  }
  {
    JSONArray jsarr_isolate_groups(&jsobj, "isolateGroups");
    IsolateGroup::ForEach([&jsarr_isolate_groups](IsolateGroup* isolate_group) {
      if (!isolate_group->is_system_isolate_group()) {
        jsarr_isolate_groups.AddValue(isolate_group);
      }
    });
  }
  {
    JSONArray jsarr_isolate_groups(&jsobj, "systemIsolateGroups");
    IsolateGroup::ForEach([&jsarr_isolate_groups](IsolateGroup* isolate_group) {
      // Don't surface the vm-isolate since it's not a "real" isolate.
      if (Dart::VmIsolateNameEquals(isolate_group->source()->name)) {
        return;
      }
      if (isolate_group->is_system_isolate_group()) {
        jsarr_isolate_groups.AddValue(isolate_group);
      }
    });
  }
  {
    JSONStream discard_js;
    intptr_t vm_memory = GetProcessMemoryUsageHelper(&discard_js);
    jsobj.AddProperty("_currentMemory", vm_memory);
  }
}

static void GetVM(Thread* thread, JSONStream* js) {
  Service::PrintJSONForVM(js, false);
}

class UriMappingTraits {
 public:
  static const char* Name() { return "UriMappingTraits"; }
  static bool ReportStats() { return false; }

  static bool IsMatch(const Object& a, const Object& b) {
    const String& a_str = String::Cast(a);
    const String& b_str = String::Cast(b);

    ASSERT(a_str.HasHash() && b_str.HasHash());
    return a_str.Equals(b_str);
  }

  static uword Hash(const Object& key) { return String::Cast(key).Hash(); }

  static ObjectPtr NewKey(const String& str) { return str.ptr(); }
};

typedef UnorderedHashMap<UriMappingTraits> UriMapping;

static void PopulateUriMappings(Thread* thread) {
  Zone* zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();
  UriMapping uri_to_resolved_uri(HashTables::New<UriMapping>(16, Heap::kOld));
  UriMapping resolved_uri_to_uri(HashTables::New<UriMapping>(16, Heap::kOld));

  const auto& libs =
      GrowableObjectArray::Handle(zone, object_store->libraries());
  intptr_t num_libs = libs.Length();

  Library& lib = Library::Handle(zone);
  Script& script = Script::Handle(zone);
  Array& scripts = Array::Handle(zone);
  String& uri = String::Handle(zone);
  String& resolved_uri = String::Handle(zone);
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_MACOS)
  String& tmp = thread->StringHandle();
#endif
  for (intptr_t i = 0; i < num_libs; ++i) {
    lib ^= libs.At(i);
    scripts ^= lib.LoadedScripts();
    intptr_t num_scripts = scripts.Length();
    for (intptr_t j = 0; j < num_scripts; ++j) {
      script ^= scripts.At(j);
      uri ^= script.url();
      resolved_uri ^= script.resolved_url();
      uri_to_resolved_uri.UpdateOrInsert(uri, resolved_uri);
      resolved_uri_to_uri.UpdateOrInsert(resolved_uri, uri);

#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_MACOS)
      // Allow for case insensitive matching on platforms that might allow for
      // case insensitive paths.
      tmp = String::ToLowerCase(uri);
      uri_to_resolved_uri.UpdateOrInsert(tmp, resolved_uri);
      tmp = String::ToLowerCase(resolved_uri);
      resolved_uri_to_uri.UpdateOrInsert(tmp, uri);
#endif
    }
  }

  object_store->set_uri_to_resolved_uri_map(uri_to_resolved_uri.Release());
  object_store->set_resolved_uri_to_uri_map(resolved_uri_to_uri.Release());
  Smi& count = Smi::Handle(zone, Smi::New(num_libs));
  object_store->set_last_libraries_count(count);
}

static void LookupScriptUrisImpl(Thread* thread,
                                 JSONStream* js,
                                 bool lookup_resolved) {
  Zone* zone = thread->zone();
  auto object_store = thread->isolate_group()->object_store();

  const auto& libs =
      GrowableObjectArray::Handle(zone, object_store->libraries());
  Smi& last_libraries_count =
      Smi::Handle(zone, object_store->last_libraries_count());
  if ((object_store->uri_to_resolved_uri_map() == Array::null()) ||
      (object_store->resolved_uri_to_uri_map() == Array::null()) ||
      (last_libraries_count.Value() != libs.Length())) {
    PopulateUriMappings(thread);
  }
  const char* uris_arg = js->LookupParam("uris");
  if (uris_arg == nullptr) {
    PrintMissingParamError(js, "uris");
    return;
  }

  const GrowableObjectArray& uris =
      GrowableObjectArray::Handle(zone, GrowableObjectArray::New());
  intptr_t uris_length = ParseJSONArray(thread, uris_arg, uris);
  if (uris_length < 0) {
    PrintInvalidParamError(js, "uris");
    return;
  }

  UriMapping map(lookup_resolved ? object_store->uri_to_resolved_uri_map()
                                 : object_store->resolved_uri_to_uri_map());
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "UriList");

  {
    JSONArray uris_array(&jsobj, "uris");
    String& uri = String::Handle(zone);
    String& res = String::Handle(zone);
    for (intptr_t i = 0; i < uris.Length(); ++i) {
      uri ^= uris.At(i);
      res ^= map.GetOrNull(uri);
#if defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_MACOS)
      // Windows and MacOS paths can be case insensitive, so we should allow for
      // case insensitive URI mappings on Windows and MacOS.
      if (res.IsNull()) {
        String& lower_case_uri = thread->StringHandle();
        lower_case_uri = String::ToLowerCase(uri);
        res ^= map.GetOrNull(lower_case_uri);
      }
#endif  // defined(DART_HOST_OS_WINDOWS) || defined(DART_HOST_OS_MACOS)
      if (res.IsNull()) {
        uris_array.AddValueNull();
      } else {
        uris_array.AddValue(res.ToCString());
      }
    }
  }
  map.Release();
}

static const MethodParameter* const lookup_resolved_package_uris_params[] = {
    ISOLATE_PARAMETER,
    nullptr,
};

static void LookupResolvedPackageUris(Thread* thread, JSONStream* js) {
  LookupScriptUrisImpl(thread, js, true);
}

static const MethodParameter* const lookup_package_uris_params[] = {
    ISOLATE_PARAMETER,
    nullptr,
};

static void LookupPackageUris(Thread* thread, JSONStream* js) {
  LookupScriptUrisImpl(thread, js, false);
}

static const char* const exception_pause_mode_names[] = {
    "All",
    "None",
    "Unhandled",
    nullptr,
};

static Dart_ExceptionPauseInfo exception_pause_mode_values[] = {
    kPauseOnAllExceptions,
    kNoPauseOnExceptions,
    kPauseOnUnhandledExceptions,
    kInvalidExceptionPauseInfo,
};

static const MethodParameter* const set_exception_pause_mode_params[] = {
    ISOLATE_PARAMETER,
    new EnumParameter("mode", true, exception_pause_mode_names),
    nullptr,
};

static void SetExceptionPauseMode(Thread* thread, JSONStream* js) {
  const char* mode = js->LookupParam("mode");
  if (mode == nullptr) {
    PrintMissingParamError(js, "mode");
    return;
  }
  Dart_ExceptionPauseInfo info =
      EnumMapper(mode, exception_pause_mode_names, exception_pause_mode_values);
  if (info == kInvalidExceptionPauseInfo) {
    PrintInvalidParamError(js, "mode");
    return;
  }
  Isolate* isolate = thread->isolate();
  isolate->debugger()->SetExceptionPauseInfo(info);
  if (Service::debug_stream.enabled()) {
    ServiceEvent event(isolate, ServiceEvent::kDebuggerSettingsUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
}

static const MethodParameter* const set_isolate_pause_mode_params[] = {
    ISOLATE_PARAMETER,
    new EnumParameter("exceptionPauseMode", false, exception_pause_mode_names),
    new BoolParameter("shouldPauseOnExit", false),
    nullptr,
};

static void SetIsolatePauseMode(Thread* thread, JSONStream* js) {
  bool state_changed = false;
  const char* exception_pause_mode = js->LookupParam("exceptionPauseMode");
  if (exception_pause_mode != nullptr) {
    Dart_ExceptionPauseInfo info =
        EnumMapper(exception_pause_mode, exception_pause_mode_names,
                   exception_pause_mode_values);
    if (info == kInvalidExceptionPauseInfo) {
      PrintInvalidParamError(js, "exceptionPauseMode");
      return;
    }
    Isolate* isolate = thread->isolate();
    isolate->debugger()->SetExceptionPauseInfo(info);
    state_changed = true;
  }

  const char* pause_isolate_on_exit = js->LookupParam("shouldPauseOnExit");
  if (pause_isolate_on_exit != nullptr) {
    bool enable = BoolParameter::Parse(pause_isolate_on_exit, false);
    thread->isolate()->message_handler()->set_should_pause_on_exit(enable);
    state_changed = true;
  }

  if (state_changed && Service::debug_stream.enabled()) {
    ServiceEvent event(thread->isolate(),
                       ServiceEvent::kDebuggerSettingsUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
}

static const MethodParameter* const set_breakpoint_state_params[] = {
    ISOLATE_PARAMETER,
    new IdParameter("breakpointId", true),
    new BoolParameter("enable", true),
    nullptr,
};

static void SetBreakpointState(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  const char* bpt_id = js->LookupParam("breakpointId");
  bool enable = BoolParameter::Parse(js->LookupParam("enable"), true);
  ObjectIdRing::LookupResult lookup_result;
  Breakpoint* bpt = LookupBreakpoint(isolate, bpt_id, &lookup_result);
  // TODO(bkonyi): Should we return a different error for bpts which
  // have been already removed?
  if (bpt == nullptr) {
    PrintInvalidParamError(js, "breakpointId");
    return;
  }
  if (isolate->debugger()->SetBreakpointState(bpt, enable)) {
    if (Service::debug_stream.enabled()) {
      ServiceEvent event(isolate, ServiceEvent::kBreakpointUpdated);
      event.set_breakpoint(bpt);
      Service::HandleEvent(&event);
    }
  }
  bpt->PrintJSON(js);
}

static const MethodParameter* const get_flag_list_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void GetFlagList(Thread* thread, JSONStream* js) {
  Flags::PrintJSON(js);
}

static const MethodParameter* const set_flags_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void SetFlag(Thread* thread, JSONStream* js) {
  const char* flag_name = js->LookupParam("name");
  if (flag_name == nullptr) {
    PrintMissingParamError(js, "name");
    return;
  }
  const char* flag_value = js->LookupParam("value");
  if (flag_value == nullptr) {
    PrintMissingParamError(js, "value");
    return;
  }

  if (Flags::Lookup(flag_name) == nullptr) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Error");
    jsobj.AddProperty("message", "Cannot set flag: flag not found");
    return;
  }

  // Changing most flags at runtime is dangerous because e.g., it may leave the
  // behavior generated code and the runtime out of sync.
  const uintptr_t kProfilePeriodIndex = 3;
  const uintptr_t kProfilerIndex = 4;
  const char* kAllowedFlags[] = {
      "pause_isolates_on_start",
      "pause_isolates_on_exit",
      "pause_isolates_on_unhandled_exceptions",
      "profile_period",
      "profiler",
  };

  bool allowed = false;
  bool profile_period = false;
  bool profiler = false;
  for (size_t i = 0; i < ARRAY_SIZE(kAllowedFlags); i++) {
    if (strcmp(flag_name, kAllowedFlags[i]) == 0) {
      allowed = true;
      profile_period = (i == kProfilePeriodIndex);
      profiler = (i == kProfilerIndex);
      break;
    }
  }

  if (!allowed) {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Error");
    jsobj.AddProperty("message", "Cannot set flag: cannot change at runtime");
    return;
  }

  const char* error = nullptr;
  if (Flags::SetFlag(flag_name, flag_value, &error)) {
    PrintSuccess(js);
    if (profile_period) {
      // FLAG_profile_period has already been set to the new value. Now we need
      // to notify the ThreadInterrupter to pick up the change.
      Profiler::UpdateSamplePeriod();
    } else if (profiler) {
      // FLAG_profiler has already been set to the new value.
      Profiler::UpdateRunningState();
    }
    if (Service::vm_stream.enabled()) {
      ServiceEvent event(ServiceEvent::kVMFlagUpdate);
      event.set_flag_name(flag_name);
      event.set_flag_new_value(flag_value);
      Service::HandleEvent(&event);
    }
  } else {
    JSONObject jsobj(js);
    jsobj.AddProperty("type", "Error");
    jsobj.AddProperty("message", error);
  }
}

static const MethodParameter* const set_library_debuggable_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("libraryId", true),
    new BoolParameter("isDebuggable", true),
    nullptr,
};

static void SetLibraryDebuggable(Thread* thread, JSONStream* js) {
  const char* lib_id = js->LookupParam("libraryId");
  ObjectIdRing::LookupResult lookup_result;
  Object& obj =
      Object::Handle(LookupHeapObject(thread, lib_id, &lookup_result));
  const bool is_debuggable =
      BoolParameter::Parse(js->LookupParam("isDebuggable"), false);
  if (obj.IsLibrary()) {
    const Library& lib = Library::Cast(obj);
    lib.set_debuggable(is_debuggable);
    PrintSuccess(js);
    return;
  }
  PrintInvalidParamError(js, "libraryId");
}

static const MethodParameter* const set_name_params[] = {
    ISOLATE_PARAMETER,
    new MethodParameter("name", true),
    nullptr,
};

static void SetName(Thread* thread, JSONStream* js) {
  Isolate* isolate = thread->isolate();
  isolate->set_name(js->LookupParam("name"));
  if (Service::isolate_stream.enabled()) {
    ServiceEvent event(isolate, ServiceEvent::kIsolateUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
  return;
}

static const MethodParameter* const set_vm_name_params[] = {
    NO_ISOLATE_PARAMETER,
    new MethodParameter("name", true),
    nullptr,
};

static void SetVMName(Thread* thread, JSONStream* js) {
  const char* name_param = js->LookupParam("name");
  free(vm_name);
  vm_name = Utils::StrDup(name_param);
  if (Service::vm_stream.enabled()) {
    ServiceEvent event(ServiceEvent::kVMUpdate);
    Service::HandleEvent(&event);
  }
  PrintSuccess(js);
  return;
}

static const MethodParameter* const set_trace_class_allocation_params[] = {
    RUNNABLE_ISOLATE_PARAMETER,
    new IdParameter("classId", true),
    new BoolParameter("enable", true),
    nullptr,
};

static void SetTraceClassAllocation(Thread* thread, JSONStream* js) {
  if (CheckCompilerDisabled(thread, js)) {
    return;
  }

  const char* class_id = js->LookupParam("classId");
  const bool enable = BoolParameter::Parse(js->LookupParam("enable"));
  intptr_t cid = -1;
  GetPrefixedIntegerId(class_id, "classes/", &cid);
  Isolate* isolate = thread->isolate();
  if (!IsValidClassId(isolate, cid)) {
    PrintInvalidParamError(js, "classId");
    return;
  }
  const Class& cls = Class::Handle(GetClassForId(isolate, cid));
  ASSERT(!cls.IsNull());
  cls.SetTraceAllocation(enable);
  PrintSuccess(js);
}

static const MethodParameter* const get_default_classes_aliases_params[] = {
    NO_ISOLATE_PARAMETER,
    nullptr,
};

static void GetDefaultClassesAliases(Thread* thread, JSONStream* js) {
  JSONObject jsobj(js);
  jsobj.AddProperty("type", "ClassesAliasesMap");

  JSONObject map(&jsobj, "map");

#define DEFINE_ADD_VALUE_F(id)                                                 \
  internals.AddValueF("classes/%" Pd, static_cast<intptr_t>(id));
#define DEFINE_ADD_VALUE_F_CID(clazz) DEFINE_ADD_VALUE_F(k##clazz##Cid)
  {
    JSONArray internals(&map, "<VM Internals>");
    for (intptr_t id = kFirstInternalOnlyCid; id <= kLastInternalOnlyCid;
         ++id) {
      DEFINE_ADD_VALUE_F(id);
    }
    DEFINE_ADD_VALUE_F_CID(LibraryPrefix);
  }
  {
    JSONArray internals(&map, "Type");
    for (intptr_t id = kAbstractTypeCid; id <= kTypeParameterCid; ++id) {
      DEFINE_ADD_VALUE_F(id);
    }
  }
  {
    JSONArray internals(&map, "Object");
    DEFINE_ADD_VALUE_F_CID(Instance);
  }
  {
    JSONArray internals(&map, "Closure");
    DEFINE_ADD_VALUE_F_CID(Closure);
    DEFINE_ADD_VALUE_F_CID(Context);
  }
  {
    JSONArray internals(&map, "Int");
    for (intptr_t id = kIntegerCid; id <= kMintCid; ++id) {
      DEFINE_ADD_VALUE_F(id);
    }
  }
  {
    JSONArray internals(&map, "Double");
    DEFINE_ADD_VALUE_F_CID(Double);
  }
  {
    JSONArray internals(&map, "String");
    CLASS_LIST_STRINGS(DEFINE_ADD_VALUE_F_CID)
  }
  {
    JSONArray internals(&map, "List");
    CLASS_LIST_ARRAYS(DEFINE_ADD_VALUE_F_CID)
    DEFINE_ADD_VALUE_F_CID(ByteBuffer)
  }
  {
    JSONArray internals(&map, "Map");
    CLASS_LIST_MAPS(DEFINE_ADD_VALUE_F_CID)
  }

  {
    JSONArray internals(&map, "Set");
    CLASS_LIST_SETS(DEFINE_ADD_VALUE_F_CID)
  }
#define DEFINE_ADD_MAP_KEY(clazz)                                              \
  {                                                                            \
    JSONArray internals(&map, #clazz);                                         \
    DEFINE_ADD_VALUE_F_CID(TypedData##clazz)                                   \
    DEFINE_ADD_VALUE_F_CID(TypedData##clazz##View)                             \
    DEFINE_ADD_VALUE_F_CID(ExternalTypedData##clazz)                           \
    DEFINE_ADD_VALUE_F_CID(UnmodifiableTypedData##clazz##View)                 \
  }
  CLASS_LIST_TYPED_DATA(DEFINE_ADD_MAP_KEY)
#undef DEFINE_ADD_MAP_KEY
#define DEFINE_ADD_MAP_KEY(clazz)                                              \
  {                                                                            \
    JSONArray internals(&map, #clazz);                                         \
    DEFINE_ADD_VALUE_F_CID(Ffi##clazz)                                         \
  }
  CLASS_LIST_FFI(DEFINE_ADD_MAP_KEY)
#undef DEFINE_ADD_MAP_KEY
#undef DEFINE_ADD_VALUE_F_CID
#undef DEFINE_ADD_VALUE_F
}

// clang-format off
static const ServiceMethodDescriptor service_methods_[] = {
  { "_echo", Echo,
    nullptr },
  { "_respondWithMalformedJson", RespondWithMalformedJson,
    nullptr },
  { "_respondWithMalformedObject", RespondWithMalformedObject,
    nullptr },
  { "_triggerEchoEvent", TriggerEchoEvent,
    nullptr },
  { "addBreakpoint", AddBreakpoint,
    add_breakpoint_params },
  { "addBreakpointWithScriptUri", AddBreakpointWithScriptUri,
    add_breakpoint_with_script_uri_params },
  { "addBreakpointAtEntry", AddBreakpointAtEntry,
    add_breakpoint_at_entry_params },
  { "_addBreakpointAtActivation", AddBreakpointAtActivation,
    add_breakpoint_at_activation_params },
  { "_buildExpressionEvaluationScope", BuildExpressionEvaluationScope,
    build_expression_evaluation_scope_params },
  { "clearCpuSamples", ClearCpuSamples,
    clear_cpu_samples_params },
  { "clearVMTimeline", ClearVMTimeline,
    clear_vm_timeline_params, },
  { "_compileExpression", CompileExpression, compile_expression_params },
  { "_enableProfiler", EnableProfiler,
    enable_profiler_params, },
  { "evaluate", Evaluate,
    evaluate_params },
  { "evaluateInFrame", EvaluateInFrame,
    evaluate_in_frame_params },
  { "_getAllocationProfile", GetAllocationProfile,
    get_allocation_profile_params },
  { "getAllocationProfile", GetAllocationProfilePublic,
    get_allocation_profile_params },
  { "getAllocationTraces", GetAllocationTraces,
      get_allocation_traces_params },
  { "getClassList", GetClassList,
    get_class_list_params },
  { "getCpuSamples", GetCpuSamples,
    get_cpu_samples_params },
  { "getFlagList", GetFlagList,
    get_flag_list_params },
  { "_getHeapMap", GetHeapMap,
    get_heap_map_params },
  { "_getImplementationFields", GetImplementationFields,
    get_implementation_fields_params },
  { "getInboundReferences", GetInboundReferences,
    get_inbound_references_params },
  { "getInstances", GetInstances,
    get_instances_params },
  { "getInstancesAsList", GetInstancesAsList,
    get_instances_as_list_params },
#if defined(SUPPORT_PERFETTO)
  { "getPerfettoCpuSamples", GetPerfettoCpuSamples,
    get_cpu_samples_params },
  { "getPerfettoVMTimeline", GetPerfettoVMTimeline,
    get_vm_timeline_params },
#endif  // defined(SUPPORT_PERFETTO)
  { "getPorts", GetPorts,
    get_ports_params },
  { "getIsolate", GetIsolate,
    get_isolate_params },
  { "_getIsolateObjectStore", GetIsolateObjectStore,
    get_isolate_object_store_params },
  { "getIsolateGroup", GetIsolateGroup,
    get_isolate_group_params },
  { "getMemoryUsage", GetMemoryUsage,
    get_memory_usage_params },
  { "getIsolateGroupMemoryUsage", GetIsolateGroupMemoryUsage,
    get_isolate_group_memory_usage_params },
  { "_getIsolateMetric", GetIsolateMetric,
    get_isolate_metric_params },
  { "_getIsolateMetricList", GetIsolateMetricList,
    get_isolate_metric_list_params },
  { "getIsolatePauseEvent", GetIsolatePauseEvent,
    get_isolate_pause_event_params },
  { "getObject", GetObject,
    get_object_params },
  { "_getObjectStore", GetObjectStore,
    get_object_store_params },
  { "_getPersistentHandles", GetPersistentHandles,
      get_persistent_handles_params, },
  { "_getPorts", GetPortsPrivate,
    get_ports_private_params },
  { "getProcessMemoryUsage", GetProcessMemoryUsage,
    get_process_memory_usage_params },
  { "_getReachableSize", GetReachableSize,
    get_reachable_size_params },
  { "_getRetainedSize", GetRetainedSize,
    get_retained_size_params },
  { "lookupResolvedPackageUris", LookupResolvedPackageUris,
    lookup_resolved_package_uris_params },
  { "lookupPackageUris", LookupPackageUris,
    lookup_package_uris_params },
  { "getRetainingPath", GetRetainingPath,
    get_retaining_path_params },
  { "getScripts", GetScripts,
    get_scripts_params },
  { "getSourceReport", GetSourceReport,
    get_source_report_params },
  { "getStack", GetStack,
    get_stack_params },
  { "_getTagProfile", GetTagProfile,
    get_tag_profile_params },
  { "_getTypeArgumentsList", GetTypeArgumentsList,
    get_type_arguments_list_params },
  { "getVersion", GetVersion,
    get_version_params },
  { "getVM", GetVM,
    get_vm_params },
  { "getVMTimeline", GetVMTimeline,
    get_vm_timeline_params },
  { "getVMTimelineFlags", GetVMTimelineFlags,
    get_vm_timeline_flags_params },
  { "getVMTimelineMicros", GetVMTimelineMicros,
    get_vm_timeline_micros_params },
  { "invoke", Invoke, invoke_params },
  { "kill", Kill, kill_params },
  { "pause", Pause,
    pause_params },
  { "removeBreakpoint", RemoveBreakpoint,
    remove_breakpoint_params },
  { "reloadSources", ReloadSources,
    reload_sources_params },
  { "_reloadSources", ReloadSources,
    reload_sources_params },
  { "resume", Resume,
    resume_params },
  { "requestHeapSnapshot", RequestHeapSnapshot,
    request_heap_snapshot_params },
  { "_evaluateCompiledExpression", EvaluateCompiledExpression,
    evaluate_compiled_expression_params },
  { "setBreakpointState", SetBreakpointState,
    set_breakpoint_state_params },
  { "setExceptionPauseMode", SetExceptionPauseMode,
    set_exception_pause_mode_params },
  { "setIsolatePauseMode", SetIsolatePauseMode,
    set_isolate_pause_mode_params },
  { "setFlag", SetFlag,
    set_flags_params },
  { "setLibraryDebuggable", SetLibraryDebuggable,
    set_library_debuggable_params },
  { "setName", SetName,
    set_name_params },
  { "_setStreamIncludePrivateMembers", SetStreamIncludePrivateMembers,
    set_stream_include_private_members_params },
  { "setTraceClassAllocation", SetTraceClassAllocation,
    set_trace_class_allocation_params },
  { "setVMName", SetVMName,
    set_vm_name_params },
  { "setVMTimelineFlags", SetVMTimelineFlags,
    set_vm_timeline_flags_params },
  { "_collectAllGarbage", CollectAllGarbage,
    collect_all_garbage_params },
  { "_getDefaultClassesAliases", GetDefaultClassesAliases,
    get_default_classes_aliases_params },
};
// clang-format on

const ServiceMethodDescriptor* FindMethod(const char* method_name) {
  intptr_t num_methods = sizeof(service_methods_) / sizeof(service_methods_[0]);
  for (intptr_t i = 0; i < num_methods; i++) {
    const ServiceMethodDescriptor& method = service_methods_[i];
    if (strcmp(method_name, method.name) == 0) {
      return &method;
    }
  }
  return nullptr;
}

#endif  // !PRODUCT

}  // namespace dart
