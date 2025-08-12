// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "vm/bootstrap_natives.h"
#include "vm/dart_api_impl.h"
#include "vm/datastream.h"
#include "vm/exceptions.h"
#include "vm/flags.h"
#include "vm/growable_array.h"
#include "vm/kernel_isolate.h"
#include "vm/message.h"
#include "vm/message_handler.h"
#include "vm/message_snapshot.h"
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, trace_service);

#ifndef PRODUCT
class RegisterRunningIsolatesVisitor : public IsolateVisitor {
 public:
  explicit RegisterRunningIsolatesVisitor(Thread* thread)
      : IsolateVisitor(),
        zone_(thread->zone()),
        register_function_(Function::Handle(thread->zone())),
        service_isolate_(thread->isolate()) {}

  virtual void VisitIsolate(Isolate* isolate) {
    isolate_ports_.Add(isolate->main_port());
    isolate_names_.Add(&String::Handle(zone_, String::New(isolate->name())));
    isolate->set_is_service_registered(true);
  }

  void RegisterIsolates() {
    ServiceIsolate::RegisterRunningIsolates(isolate_ports_, isolate_names_);
  }

 private:
  Zone* zone_;
  GrowableArray<Dart_Port> isolate_ports_;
  GrowableArray<const String*> isolate_names_;
  Function& register_function_;
  Isolate* service_isolate_;
};
#endif  // !PRODUCT

DEFINE_NATIVE_ENTRY(VMService_SendIsolateServiceMessage, 0, 2) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, sp, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(1));

  // Set the type of the OOB message.
  message.SetAt(0,
                Smi::Handle(thread->zone(), Smi::New(Message::kServiceOOBMsg)));

  // Serialize message.
  // TODO(turnidge): Throw an exception when the return value is false?
  bool result = PortMap::PostMessage(WriteMessage(
      /* same_group */ false, message, sp.Id(), Message::kOOBPriority));
  return Bool::Get(result).ptr();
#else
  return Object::null();
#endif
}

DEFINE_NATIVE_ENTRY(VMService_SendRootServiceMessage, 0, 1) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(0));
  return Service::HandleRootMessage(message);
#endif
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_OnStart, 0, 0) {
#ifndef PRODUCT
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Booting dart:vmservice library.\n");
  }
  // Boot the dart:vmservice library.
  ServiceIsolate::BootVmServiceLibrary();
  // Register running isolates with service.
  RegisterRunningIsolatesVisitor register_isolates(thread);
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Registering running isolates.\n");
  }
  Isolate::VisitIsolates(&register_isolates);
  register_isolates.RegisterIsolates();
#endif
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_OnExit, 0, 0) {
#ifndef PRODUCT
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: processed exit message.\n");
    OS::PrintErr("vm-service: has live ports: %s\n",
                 isolate->HasLivePorts() ? "yes" : "no");
  }
#endif
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_OnServerAddressChange, 0, 1) {
#ifndef PRODUCT
  GET_NATIVE_ARGUMENT(String, address, arguments->NativeArgAt(0));
  if (address.IsNull()) {
    ServiceIsolate::SetServerAddress(nullptr);
  } else {
    ServiceIsolate::SetServerAddress(address.ToCString());
  }
#endif
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_ListenStream, 0, 2) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Bool, include_privates,
                               arguments->NativeArgAt(1));
  bool result =
      Service::ListenStream(stream_id.ToCString(), include_privates.value());
  return Bool::Get(result).ptr();
#else
  return Object::null();
#endif
}

DEFINE_NATIVE_ENTRY(VMService_CancelStream, 0, 1) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
  Service::CancelStream(stream_id.ToCString());
#endif
  return Object::null();
}

#ifndef PRODUCT
class UserTagIsolatesVisitor : public IsolateVisitor {
 public:
  UserTagIsolatesVisitor(Thread* thread,
                         const GrowableObjectArray* user_tags,
                         bool set_streamable)
      : IsolateVisitor(),
        thread_(thread),
        user_tags_(user_tags),
        set_streamable_(set_streamable) {}

  virtual void VisitIsolate(Isolate* isolate) {
    if (Isolate::IsVMInternalIsolate(isolate)) {
      return;
    }
    Zone* zone = thread_->zone();
    UserTag& tag = UserTag::Handle(zone);
    String& label = String::Handle(zone);
    for (intptr_t i = 0; i < user_tags_->Length(); ++i) {
      label ^= user_tags_->At(i);
      tag ^= UserTag::FindTagInIsolate(isolate, thread_, label);
      if (!tag.IsNull()) {
        tag.set_streamable(set_streamable_);
      }
    }
  }

 private:
  Thread* thread_;
  const GrowableObjectArray* user_tags_;
  bool set_streamable_;

  DISALLOW_COPY_AND_ASSIGN(UserTagIsolatesVisitor);
};
#endif  // !PRODUCT

// TODO(derekxu16): This function is now dead code and should be cleaned up.
DEFINE_NATIVE_ENTRY(VMService_AddUserTagsToStreamableSampleList, 0, 1) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(GrowableObjectArray, user_tags,
                               arguments->NativeArgAt(0));

  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < user_tags.Length(); ++i) {
    obj = user_tags.At(i);
    UserTags::AddStreamableTagName(obj.ToCString());
  }
  UserTagIsolatesVisitor visitor(thread, &user_tags, true);
  Isolate::VisitIsolates(&visitor);
#endif
  return Object::null();
}

// TODO(derekxu16): This function is now dead code and should be cleaned up.
DEFINE_NATIVE_ENTRY(VMService_RemoveUserTagsFromStreamableSampleList, 0, 1) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(GrowableObjectArray, user_tags,
                               arguments->NativeArgAt(0));

  Object& obj = Object::Handle();
  for (intptr_t i = 0; i < user_tags.Length(); ++i) {
    obj = user_tags.At(i);
    UserTags::RemoveStreamableTagName(obj.ToCString());
  }
  UserTagIsolatesVisitor visitor(thread, &user_tags, false);
  Isolate::VisitIsolates(&visitor);
#endif
  return Object::null();
}

}  // namespace dart
