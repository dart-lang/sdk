// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SERVICE_H_
#define RUNTIME_VM_SERVICE_H_

#include <atomic>
#include <memory>

#include "include/dart_tools_api.h"

#include "vm/allocation.h"
#include "vm/object_id_ring.h"
#include "vm/os_thread.h"
#include "vm/tagged_pointer.h"
#include "vm/thread.h"

namespace dart {

#define SERVICE_PROTOCOL_MAJOR_VERSION 4
#define SERVICE_PROTOCOL_MINOR_VERSION 19

class Array;
class EmbedderServiceHandler;
class Error;
class GCEvent;
class GrowableObjectArray;
class Instance;
class Isolate;
class IsolateGroup;
class JSONStream;
class JSONObject;
class Object;
class ServiceEvent;
class String;

class ServiceIdZone {
 public:
  ServiceIdZone(intptr_t id, ObjectIdRing::IdPolicy policy);
  virtual ~ServiceIdZone();

  // Parses a Service ID zone ID string and returns the corresponding integer
  // ID. Or, returns -1 if |id_string| is invalid.
  //
  // For example, this function will return 5 when called with the argument
  // "zones/5".
  intptr_t static StringIdToInt(const char* id_string);

  intptr_t id() const { return id_; }
  ObjectIdRing::IdPolicy policy() const { return policy_; }

  virtual int32_t GetIdForObject(const ObjectPtr obj) = 0;
  virtual ObjectPtr GetObjectForId(int32_t id,
                                   ObjectIdRing::LookupResult* kind) = 0;
  // Returned string will be zone allocated.
  virtual char* GetServiceId(const Object& obj) = 0;
  // Invalidate all the Service IDs currently living in this zone.
  virtual void Invalidate() = 0;
  virtual void VisitPointers(ObjectPointerVisitor* visitor) const = 0;

  virtual void PrintJSON(JSONStream& js) const = 0;

 private:
  intptr_t id_;
  ObjectIdRing::IdPolicy policy_;

  friend class ServiceIdZonePolicyOverrideScope;
};

#define ISOLATE_SERVICE_ID_FORMAT_STRING "isolates/%" Pd64 ""
#define ISOLATE_GROUP_SERVICE_ID_PREFIX "isolateGroups/"
#define ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING                                 \
  ISOLATE_GROUP_SERVICE_ID_PREFIX "%" Pu64 ""

class RingServiceIdZone final : public ServiceIdZone {
 public:
  // The capacity of the default Service ID zone of each isolate.
  static constexpr int32_t kCapacityOfDefaultIdZone = 8192;
  // The fallback capacity used when the `createIdZone` Service procedure is
  // called without a `capacity` argument.
  static constexpr int32_t kFallbackCapacityForCreateIdZone = 512;

  RingServiceIdZone(intptr_t id,
                    ObjectIdRing::IdPolicy policy,
                    int32_t capacity);
  ~RingServiceIdZone() final;

  int32_t GetIdForObject(const ObjectPtr obj) final;
  ObjectPtr GetObjectForId(int32_t id, ObjectIdRing::LookupResult* kind) final;
  // Returned string will be zone allocated.
  char* GetServiceId(const Object& obj) final;
  void Invalidate() final;
  void VisitPointers(ObjectPointerVisitor* visitor) const final;

  void PrintJSON(JSONStream& js) const final;

 private:
  ObjectIdRing ring_;
};

class StreamInfo {
 public:
  explicit StreamInfo(const char* id)
      : id_(id), enabled_(0), include_private_members_(false) {}

  const char* id() const { return id_; }

  void set_enabled(bool value) { enabled_ = value ? 1 : 0; }
  bool enabled() const { return enabled_ != 0; }

  void set_include_private_members(bool value) {
    include_private_members_ = value;
  }
  bool include_private_members() const { return include_private_members_; }

  // This may get access by multiple threads, but relaxed access is ok.
  static intptr_t enabled_offset() { return OFFSET_OF(StreamInfo, enabled_); }

 private:
  const char* id_;
  std::atomic<intptr_t> enabled_;
  std::atomic<bool> include_private_members_;
};

class Service : public AllStatic {
 public:
  static void Init();
  static void Cleanup();

  // Handles a message which is not directed to an isolate.
  static ErrorPtr HandleRootMessage(const Array& message);

  // Handles a message which is directed to a particular isolate.
  static ErrorPtr HandleIsolateMessage(Isolate* isolate, const Array& message);

  static void HandleEvent(ServiceEvent* event, bool enter_safepoint = true);

  static void RegisterIsolateEmbedderCallback(
      const char* name,
      Dart_ServiceRequestCallback callback,
      void* user_data);

  static void RegisterRootEmbedderCallback(const char* name,
                                           Dart_ServiceRequestCallback callback,
                                           void* user_data);

  static void SetEmbedderInformationCallback(
      Dart_EmbedderInformationCallback callback);

  static void SetEmbedderStreamCallbacks(
      Dart_ServiceStreamListenCallback listen_callback,
      Dart_ServiceStreamCancelCallback cancel_callback);

  static void SendEchoEvent(Isolate* isolate, const char* text);
  static void SendInspectEvent(Isolate* isolate, const Object& inspectee);

  static void SendEmbedderEvent(Isolate* isolate,
                                const char* stream_id,
                                const char* event_kind,
                                const uint8_t* bytes,
                                intptr_t bytes_len);

  static void SendLogEvent(Isolate* isolate,
                           int64_t sequence_number,
                           int64_t timestamp,
                           intptr_t level,
                           const String& name,
                           const String& message,
                           const Instance& zone,
                           const Object& error,
                           const Instance& stack_trace);

  // Sends an event of kind |kTimerSignificantlyOverdue|.
  static void SendTimerEvent(Isolate* isolate, intptr_t milliseconds_overdue);

  static void SendExtensionEvent(Isolate* isolate,
                                 const String& event_kind,
                                 const String& event_data);

  // Takes ownership of 'data'.
  static void SendEventWithData(const char* stream_id,
                                const char* event_type,
                                intptr_t reservation,
                                const char* metadata,
                                intptr_t metadata_size,
                                uint8_t* data,
                                intptr_t data_size);

  static void PostError(const String& method_name,
                        const Array& parameter_keys,
                        const Array& parameter_values,
                        const Instance& reply_port,
                        const Instance& id,
                        const Error& error);

  // Logs the size of the contents of `js` to FLAG_log_service_response_sizes.
  static void LogResponseSize(const char* method, JSONStream* js);

  // Enable/Disable timeline categories.
  // Returns True if the categories were successfully enabled, False otherwise.
  static bool EnableTimelineStreams(char* categories_list);

  // Well-known streams.
  static StreamInfo vm_stream;
  static StreamInfo isolate_stream;
  static StreamInfo debug_stream;
  static StreamInfo gc_stream;
  static StreamInfo echo_stream;
  static StreamInfo heapsnapshot_stream;
  static StreamInfo logging_stream;
  static StreamInfo timer_stream;
  static StreamInfo extension_stream;
  static StreamInfo timeline_stream;
  static StreamInfo profiler_stream;

  static bool ListenStream(const char* stream_id, bool include_privates);
  static void CancelStream(const char* stream_id);

  static Dart_ServiceStreamListenCallback stream_listen_callback() {
    return stream_listen_callback_;
  }
  static Dart_ServiceStreamCancelCallback stream_cancel_callback() {
    return stream_cancel_callback_;
  }

  static void PrintJSONForEmbedderInformation(JSONObject* jsobj);
  static void PrintJSONForVM(JSONStream* js, bool ref);

  static void CheckForPause(Isolate* isolate, JSONStream* stream);

  static int64_t CurrentRSS();
  static int64_t MaxRSS();

  static void SetDartLibraryKernelForSources(const uint8_t* kernel_bytes,
                                             intptr_t kernel_length);
  static bool HasDartLibraryKernelForSources() {
    return (dart_library_kernel_ != nullptr);
  }

  static const uint8_t* dart_library_kernel() { return dart_library_kernel_; }

  static intptr_t dart_library_kernel_length() {
    return dart_library_kernel_len_;
  }

 private:
  static ErrorPtr InvokeMethod(Isolate* isolate, const Array& message);

  static void EmbedderHandleMessage(EmbedderServiceHandler* handler,
                                    JSONStream* js);

  static EmbedderServiceHandler* FindIsolateEmbedderHandler(const char* name);
  static EmbedderServiceHandler* FindRootEmbedderHandler(const char* name);
  static void ScheduleExtensionHandler(const Instance& handler,
                                       const String& method_name,
                                       const Array& parameter_keys,
                                       const Array& parameter_values,
                                       const Instance& reply_port,
                                       const Instance& id);

  // Takes ownership of 'bytes'.
  static void SendEvent(const char* stream_id,
                        const char* event_type,
                        uint8_t* bytes,
                        intptr_t bytes_length);

  static void PostEvent(IsolateGroup* isolate_group,
                        Isolate* isolate,
                        const char* stream_id,
                        const char* kind,
                        JSONStream* event,
                        bool enter_safepoint);

  static void PostEventImpl(IsolateGroup* isolate_group,
                            Isolate* isolate,
                            const char* stream_id,
                            const char* kind,
                            JSONStream* event);

  static ErrorPtr MaybePause(Isolate* isolate, const Error& error);

  static EmbedderServiceHandler* isolate_service_handler_head_;
  static EmbedderServiceHandler* root_service_handler_head_;
  static Dart_ServiceStreamListenCallback stream_listen_callback_;
  static Dart_ServiceStreamCancelCallback stream_cancel_callback_;
  static Dart_EmbedderInformationCallback embedder_information_callback_;

  static void* service_response_size_log_file_;

  static const uint8_t* dart_library_kernel_;
  static intptr_t dart_library_kernel_len_;
};

// Visible for testing.
intptr_t ParseJSONArray(Thread* thread,
                        const char* str,
                        const GrowableObjectArray& elements);

}  // namespace dart

#endif  // RUNTIME_VM_SERVICE_H_
