// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_VM_SERVICE_H_
#define RUNTIME_VM_SERVICE_H_

#include "include/dart_tools_api.h"

#include "vm/allocation.h"
#include "vm/object_id_ring.h"
#include "vm/os_thread.h"
#include "vm/tagged_pointer.h"

namespace dart {

#define SERVICE_PROTOCOL_MAJOR_VERSION 3
#define SERVICE_PROTOCOL_MINOR_VERSION 42

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
  ServiceIdZone();
  virtual ~ServiceIdZone();

  // Returned string will be zone allocated.
  virtual char* GetServiceId(const Object& obj) = 0;

 private:
};

#define ISOLATE_SERVICE_ID_FORMAT_STRING "isolates/%" Pd64 ""
#define ISOLATE_GROUP_SERVICE_ID_PREFIX "isolateGroups/"
#define ISOLATE_GROUP_SERVICE_ID_FORMAT_STRING                                 \
  ISOLATE_GROUP_SERVICE_ID_PREFIX "%" Pu64 ""

class RingServiceIdZone : public ServiceIdZone {
 public:
  RingServiceIdZone();
  virtual ~RingServiceIdZone();

  void Init(ObjectIdRing* ring, ObjectIdRing::IdPolicy policy);

  // Returned string will be zone allocated.
  virtual char* GetServiceId(const Object& obj);

  void set_policy(ObjectIdRing::IdPolicy policy) { policy_ = policy; }

  ObjectIdRing::IdPolicy policy() const { return policy_; }

 private:
  ObjectIdRing* ring_;
  ObjectIdRing::IdPolicy policy_;
};

class StreamInfo {
 public:
  explicit StreamInfo(const char* id) : id_(id), enabled_(false) {}

  const char* id() const { return id_; }

  void set_enabled(bool value) { enabled_ = value; }
  bool enabled() const { return enabled_; }

  void set_consumer(Dart_NativeStreamConsumer consumer) {
    callback_ = consumer;
  }
  Dart_NativeStreamConsumer consumer() const { return callback_; }

 private:
  const char* id_;
  bool enabled_;
  Dart_NativeStreamConsumer callback_;
};

class Service : public AllStatic {
 public:
  // Handles a message which is not directed to an isolate.
  static ErrorPtr HandleRootMessage(const Array& message);

  // Handles a message which is not directed to an isolate and also
  // expects the parameter keys and values to be actual dart objects.
  static ErrorPtr HandleObjectRootMessage(const Array& message);

  // Handles a message which is directed to a particular isolate.
  static ErrorPtr HandleIsolateMessage(Isolate* isolate, const Array& message);

  static void HandleEvent(ServiceEvent* event);

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

  static void SetNativeServiceStreamCallback(Dart_NativeStreamConsumer consumer,
                                             const char* stream_id);

  static void SetGetServiceAssetsCallback(
      Dart_GetVMServiceAssetsArchive get_service_assets);

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

  // Well-known streams.
  static StreamInfo vm_stream;
  static StreamInfo isolate_stream;
  static StreamInfo debug_stream;
  static StreamInfo gc_stream;
  static StreamInfo echo_stream;
  static StreamInfo heapsnapshot_stream;
  static StreamInfo logging_stream;
  static StreamInfo extension_stream;
  static StreamInfo timeline_stream;

  static bool ListenStream(const char* stream_id);
  static void CancelStream(const char* stream_id);

  static ObjectPtr RequestAssets();

  static Dart_ServiceStreamListenCallback stream_listen_callback() {
    return stream_listen_callback_;
  }
  static Dart_ServiceStreamCancelCallback stream_cancel_callback() {
    return stream_cancel_callback_;
  }

  static void PrintJSONForEmbedderInformation(JSONObject *jsobj);
  static void PrintJSONForVM(JSONStream* js, bool ref);

  static void CheckForPause(Isolate* isolate, JSONStream* stream);

  static int64_t CurrentRSS();
  static int64_t MaxRSS();

  static void SetDartLibraryKernelForSources(const uint8_t* kernel_bytes,
                                             intptr_t kernel_length);
  static bool HasDartLibraryKernelForSources() {
    return (dart_library_kernel_ != NULL);
  }

  static const uint8_t* dart_library_kernel() { return dart_library_kernel_; }

  static intptr_t dart_library_kernel_length() {
    return dart_library_kernel_len_;
  }

 private:
  static ErrorPtr InvokeMethod(Isolate* isolate,
                               const Array& message,
                               bool parameters_are_dart_objects = false);

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

  static void PostEvent(Isolate* isolate,
                        const char* stream_id,
                        const char* kind,
                        JSONStream* event);

  static ErrorPtr MaybePause(Isolate* isolate, const Error& error);

  static EmbedderServiceHandler* isolate_service_handler_head_;
  static EmbedderServiceHandler* root_service_handler_head_;
  static Dart_ServiceStreamListenCallback stream_listen_callback_;
  static Dart_ServiceStreamCancelCallback stream_cancel_callback_;
  static Dart_GetVMServiceAssetsArchive get_service_assets_callback_;
  static Dart_EmbedderInformationCallback embedder_information_callback_;

  static const uint8_t* dart_library_kernel_;
  static intptr_t dart_library_kernel_len_;
};

}  // namespace dart

#endif  // RUNTIME_VM_SERVICE_H_
