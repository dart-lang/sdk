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

DEFINE_NATIVE_ENTRY(VMService_SendObjectRootServiceMessage, 0, 1) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(0));
  return Service::HandleObjectRootMessage(message);
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

DEFINE_NATIVE_ENTRY(VMService_RequestAssets, 0, 0) {
#ifndef PRODUCT
  return Service::RequestAssets();
#else
  return Object::null();
#endif
}

#ifndef PRODUCT
// TODO(25041): When reading, this class copies out the filenames and contents
// into new buffers. It does this because the lifetime of |bytes| is uncertain.
// If |bytes| is pinned in memory, then we could instead load up
// |filenames_| and |contents_| with pointers into |bytes| without making
// copies.
class TarArchive {
 public:
  TarArchive(uint8_t* bytes, intptr_t bytes_length)
      : rs_(bytes, bytes_length) {}

  void Read() {
    while (HasNext()) {
      char* filename;
      uint8_t* data;
      intptr_t data_length;
      if (Next(&filename, &data, &data_length)) {
        filenames_.Add(filename);
        contents_.Add(data);
        content_lengths_.Add(data_length);
      }
    }
  }

  char* NextFilename() { return filenames_.RemoveLast(); }

  uint8_t* NextContent() { return contents_.RemoveLast(); }

  intptr_t NextContentLength() { return content_lengths_.RemoveLast(); }

  bool HasMore() const { return filenames_.length() > 0; }

  intptr_t Length() const { return filenames_.length(); }

 private:
  enum TarHeaderFields {
    kTarHeaderFilenameOffset = 0,
    kTarHeaderFilenameSize = 100,
    kTarHeaderSizeOffset = 124,
    kTarHeaderSizeSize = 12,
    kTarHeaderTypeOffset = 156,
    kTarHeaderTypeSize = 1,
    kTarHeaderSize = 512,
  };

  enum TarType {
    kTarAregType = '\0',
    kTarRegType = '0',
    kTarLnkType = '1',
    kTarSymType = '2',
    kTarChrType = '3',
    kTarBlkType = '4',
    kTarDirType = '5',
    kTarFifoType = '6',
    kTarContType = '7',
    kTarXhdType = 'x',
    kTarXglType = 'g',
  };

  bool HasNext() const { return !EndOfArchive(); }

  bool Next(char** filename, uint8_t** data, intptr_t* data_length) {
    intptr_t startOfBlock = rs_.Position();
    *filename = ReadFilename();
    rs_.SetPosition(startOfBlock + kTarHeaderSizeOffset);
    intptr_t size = ReadSize();
    rs_.SetPosition(startOfBlock + kTarHeaderTypeOffset);
    TarType type = ReadType();
    SeekToNextBlock(kTarHeaderSize);
    if ((type != kTarRegType) && (type != kTarAregType)) {
      SkipContents(size);
      return false;
    }
    ReadContents(data, size);
    *data_length = size;
    return true;
  }

  void SeekToNextBlock(intptr_t blockSize) {
    intptr_t remainder = blockSize - (rs_.Position() % blockSize);
    rs_.Advance(remainder);
  }

  uint8_t PeekByte(intptr_t i) const {
    return *(rs_.AddressOfCurrentPosition() + i);
  }

  bool EndOfArchive() const {
    if (rs_.PendingBytes() < (kTarHeaderSize * 2)) {
      return true;
    }
    for (intptr_t i = 0; i < (kTarHeaderSize * 2); i++) {
      if (PeekByte(i) != 0) {
        return false;
      }
    }
    return true;
  }

  TarType ReadType() {
    return static_cast<TarType>(ReadStream::Raw<1, uint8_t>::Read(&rs_));
  }

  void SkipContents(intptr_t size) {
    rs_.Advance(size);
    SeekToNextBlock(kTarHeaderSize);
  }

  intptr_t ReadCString(char** s, intptr_t length) {
    intptr_t to_read = Utils::Minimum(length, rs_.PendingBytes());
    char* result = new char[to_read + 1];
    strncpy(result,
            reinterpret_cast<const char*>(rs_.AddressOfCurrentPosition()),
            to_read);
    result[to_read] = '\0';
    rs_.SetPosition(rs_.Position() + to_read);
    *s = result;
    return to_read;
  }

  intptr_t ReadSize() {
    char* octalSize;
    unsigned int size;

    ReadCString(&octalSize, kTarHeaderSizeSize);
    int result = sscanf(octalSize, "%o", &size);
    delete[] octalSize;

    if (result != 1) {
      return 0;
    }
    return size;
  }

  char* ReadFilename() {
    char* result;
    intptr_t result_length = ReadCString(&result, kTarHeaderFilenameSize);
    if (result[0] == '/') {
      return result;
    }
    char* fixed_result = new char[result_length + 2];  // '/' + '\0'.
    fixed_result[0] = '/';
    strncpy(&fixed_result[1], result, result_length);
    fixed_result[result_length + 1] = '\0';
    delete[] result;
    return fixed_result;
  }

  void ReadContents(uint8_t** data, intptr_t size) {
    uint8_t* result = new uint8_t[size];
    rs_.ReadBytes(result, size);
    SeekToNextBlock(kTarHeaderSize);
    *data = result;
  }

  ReadStream rs_;
  GrowableArray<char*> filenames_;
  GrowableArray<uint8_t*> contents_;
  GrowableArray<intptr_t> content_lengths_;

  DISALLOW_COPY_AND_ASSIGN(TarArchive);
};

static void ContentsFinalizer(void* isolate_callback_data, void* peer) {
  uint8_t* data = reinterpret_cast<uint8_t*>(peer);
  delete[] data;
}

static void FilenameFinalizer(void* isolate_callback_data, void* peer) {
  char* filename = reinterpret_cast<char*>(peer);
  delete[] filename;
}

#endif

DEFINE_NATIVE_ENTRY(VMService_DecodeAssets, 0, 1) {
#ifndef PRODUCT
  GET_NON_NULL_NATIVE_ARGUMENT(TypedData, data, arguments->NativeArgAt(0));
  Api::Scope scope(thread);
  Dart_Handle data_handle = Api::NewHandle(thread, data.ptr());
  Dart_Handle result_list;
  {
    TransitionVMToNative transition(thread);

    Dart_TypedData_Type typ;
    void* bytes;
    intptr_t length;
    Dart_Handle err =
        Dart_TypedDataAcquireData(data_handle, &typ, &bytes, &length);
    ASSERT(!Dart_IsError(err));

    TarArchive archive(reinterpret_cast<uint8_t*>(bytes), length);
    archive.Read();

    err = Dart_TypedDataReleaseData(data_handle);
    ASSERT(!Dart_IsError(err));

    intptr_t archive_size = archive.Length();

    result_list = Dart_NewList(2 * archive_size);
    ASSERT(!Dart_IsError(result_list));

    intptr_t idx = 0;
    while (archive.HasMore()) {
      char* filename = archive.NextFilename();
      intptr_t filename_length = strlen(filename);
      uint8_t* contents = archive.NextContent();
      intptr_t contents_length = archive.NextContentLength();

      Dart_Handle dart_filename = Dart_NewExternalLatin1String(
          reinterpret_cast<uint8_t*>(filename), filename_length, filename,
          filename_length, FilenameFinalizer);
      ASSERT(!Dart_IsError(dart_filename));

      Dart_Handle dart_contents = Dart_NewExternalTypedDataWithFinalizer(
          Dart_TypedData_kUint8, contents, contents_length, contents,
          contents_length, ContentsFinalizer);
      ASSERT(!Dart_IsError(dart_contents));

      Dart_ListSetAt(result_list, idx, dart_filename);
      Dart_ListSetAt(result_list, (idx + 1), dart_contents);
      idx += 2;
    }
  }
  return Api::UnwrapArrayHandle(thread->zone(), result_list).ptr();
#else
  return Object::null();
#endif
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
