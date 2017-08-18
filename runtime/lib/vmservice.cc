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
#include "vm/native_entry.h"
#include "vm/object.h"
#include "vm/port.h"
#include "vm/service_event.h"
#include "vm/service_isolate.h"
#include "vm/symbols.h"

namespace dart {

DECLARE_FLAG(bool, trace_service);
DECLARE_FLAG(bool, show_kernel_isolate);

static uint8_t* malloc_allocator(uint8_t* ptr,
                                 intptr_t old_size,
                                 intptr_t new_size) {
  void* new_ptr = realloc(reinterpret_cast<void*>(ptr), new_size);
  return reinterpret_cast<uint8_t*>(new_ptr);
}

static void malloc_deallocator(uint8_t* ptr) {
  free(reinterpret_cast<void*>(ptr));
}

#ifndef PRODUCT
class RegisterRunningIsolatesVisitor : public IsolateVisitor {
 public:
  explicit RegisterRunningIsolatesVisitor(Thread* thread)
      : IsolateVisitor(),
        register_function_(Function::Handle(thread->zone())),
        service_isolate_(thread->isolate()) {
    ASSERT(ServiceIsolate::IsServiceIsolate(Isolate::Current()));
    // Get library.
    const String& library_url = Symbols::DartVMService();
    ASSERT(!library_url.IsNull());
    const Library& library =
        Library::Handle(Library::LookupLibrary(thread, library_url));
    ASSERT(!library.IsNull());
    // Get function.
    const String& function_name =
        String::Handle(String::New("_registerIsolate"));
    ASSERT(!function_name.IsNull());
    register_function_ = library.LookupFunctionAllowPrivate(function_name);
    ASSERT(!register_function_.IsNull());
  }

  virtual void VisitIsolate(Isolate* isolate) {
    ASSERT(ServiceIsolate::IsServiceIsolate(Isolate::Current()));
    bool is_kernel_isolate = false;
#ifndef DART_PRECOMPILED_RUNTIME
    is_kernel_isolate =
        KernelIsolate::IsKernelIsolate(isolate) && !FLAG_show_kernel_isolate;
#endif
    if (IsVMInternalIsolate(isolate) || is_kernel_isolate) {
      // We do not register the service (and descendants), the vm-isolate, or
      // the kernel isolate.
      return;
    }
    // Setup arguments for call.
    Dart_Port port_id = isolate->main_port();
    const Integer& port_int = Integer::Handle(Integer::New(port_id));
    ASSERT(!port_int.IsNull());
    const SendPort& send_port = SendPort::Handle(SendPort::New(port_id));
    const String& name = String::Handle(String::New(isolate->name()));
    ASSERT(!name.IsNull());
    const Array& args = Array::Handle(Array::New(3));
    ASSERT(!args.IsNull());
    args.SetAt(0, port_int);
    args.SetAt(1, send_port);
    args.SetAt(2, name);
    const Object& r =
        Object::Handle(DartEntry::InvokeFunction(register_function_, args));
    if (FLAG_trace_service) {
      OS::PrintErr("vm-service: Isolate %s %" Pd64 " registered.\n",
                   name.ToCString(), port_id);
    }
    ASSERT(!r.IsError());
  }

 private:
  Function& register_function_;
  Isolate* service_isolate_;
};
#endif  // !PRODUCT

DEFINE_NATIVE_ENTRY(VMService_SendIsolateServiceMessage, 2) {
  if (!FLAG_support_service) {
    return Bool::Get(false).raw();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(SendPort, sp, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(1));

  // Set the type of the OOB message.
  message.SetAt(0,
                Smi::Handle(thread->zone(), Smi::New(Message::kServiceOOBMsg)));

  // Serialize message.
  uint8_t* data = NULL;
  MessageWriter writer(&data, &malloc_allocator, &malloc_deallocator, false);
  writer.WriteMessage(message);

  // TODO(turnidge): Throw an exception when the return value is false?
  bool result = PortMap::PostMessage(
      new Message(sp.Id(), data, writer.BytesWritten(), Message::kOOBPriority));
  return Bool::Get(result).raw();
}

DEFINE_NATIVE_ENTRY(VMService_SendRootServiceMessage, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(0));
  if (FLAG_support_service) {
    return Service::HandleRootMessage(message);
  }
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_SendObjectRootServiceMessage, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(Array, message, arguments->NativeArgAt(0));
  if (FLAG_support_service) {
    return Service::HandleObjectRootMessage(message);
  }
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_OnStart, 0) {
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Booting dart:vmservice library.\n");
  }
  // Boot the dart:vmservice library.
  ServiceIsolate::BootVmServiceLibrary();
  if (!FLAG_support_service) {
    return Object::null();
  }
#ifndef PRODUCT
  // Register running isolates with service.
  RegisterRunningIsolatesVisitor register_isolates(thread);
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: Registering running isolates.\n");
  }
  Isolate::VisitIsolates(&register_isolates);
#endif
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_OnExit, 0) {
  if (FLAG_trace_service) {
    OS::PrintErr("vm-service: processed exit message.\n");
    MessageHandler* message_handler = isolate->message_handler();
    OS::PrintErr("vm-service: live ports = %" Pd "\n",
                 message_handler->live_ports());
  }
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_OnServerAddressChange, 1) {
  if (!FLAG_support_service) {
    return Object::null();
  }
  GET_NATIVE_ARGUMENT(String, address, arguments->NativeArgAt(0));
  if (address.IsNull()) {
    ServiceIsolate::SetServerAddress(NULL);
  } else {
    ServiceIsolate::SetServerAddress(address.ToCString());
  }
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_ListenStream, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
  bool result = false;
  if (FLAG_support_service) {
    result = Service::ListenStream(stream_id.ToCString());
  }
  return Bool::Get(result).raw();
}

DEFINE_NATIVE_ENTRY(VMService_CancelStream, 1) {
  GET_NON_NULL_NATIVE_ARGUMENT(String, stream_id, arguments->NativeArgAt(0));
  if (FLAG_support_service) {
    Service::CancelStream(stream_id.ToCString());
  }
  return Object::null();
}

DEFINE_NATIVE_ENTRY(VMService_RequestAssets, 0) {
  if (!FLAG_support_service) {
    return Object::null();
  }
  return Service::RequestAssets();
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

static void ContentsFinalizer(void* isolate_callback_data,
                              Dart_WeakPersistentHandle handle,
                              void* peer) {
  uint8_t* data = reinterpret_cast<uint8_t*>(peer);
  delete[] data;
}

static void FilenameFinalizer(void* peer) {
  char* filename = reinterpret_cast<char*>(peer);
  delete[] filename;
}

#endif

DEFINE_NATIVE_ENTRY(VMService_DecodeAssets, 1) {
#ifndef PRODUCT
  if (!FLAG_support_service) {
    return Object::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(TypedData, data, arguments->NativeArgAt(0));
  TransitionVMToNative transition(thread);
  Api::Scope scope(thread);

  Dart_Handle data_handle = Api::NewHandle(thread, data.raw());

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

  Dart_Handle result_list = Dart_NewList(2 * archive_size);
  ASSERT(!Dart_IsError(result_list));

  intptr_t idx = 0;
  while (archive.HasMore()) {
    char* filename = archive.NextFilename();
    uint8_t* contents = archive.NextContent();
    intptr_t contents_length = archive.NextContentLength();

    Dart_Handle dart_filename = Dart_NewExternalLatin1String(
        reinterpret_cast<uint8_t*>(filename), strlen(filename), filename,
        FilenameFinalizer);
    ASSERT(!Dart_IsError(dart_filename));

    Dart_Handle dart_contents = Dart_NewExternalTypedData(
        Dart_TypedData_kUint8, contents, contents_length);
    ASSERT(!Dart_IsError(dart_contents));
    Dart_NewWeakPersistentHandle(dart_contents, contents, contents_length,
                                 ContentsFinalizer);

    Dart_ListSetAt(result_list, idx, dart_filename);
    Dart_ListSetAt(result_list, (idx + 1), dart_contents);
    idx += 2;
  }
  return Api::UnwrapArrayHandle(thread->zone(), result_list).raw();
#else
  return Object::null();
#endif
}

DEFINE_NATIVE_ENTRY(VMService_spawnUriNotify, 2) {
#ifndef PRODUCT
  if (!FLAG_support_service) {
    return Object::null();
  }
  GET_NON_NULL_NATIVE_ARGUMENT(Instance, result, arguments->NativeArgAt(0));
  GET_NON_NULL_NATIVE_ARGUMENT(String, token, arguments->NativeArgAt(1));

  if (result.IsSendPort()) {
    Dart_Port id = SendPort::Cast(result).Id();
    Isolate* isolate = PortMap::GetIsolate(id);
    if (isolate != NULL) {
      ServiceEvent spawn_event(isolate, ServiceEvent::kIsolateSpawn);
      spawn_event.set_spawn_token(&token);
      Service::HandleEvent(&spawn_event);
    } else {
      // There is no isolate at the control port anymore.  Must have
      // died already.
      ServiceEvent spawn_event(NULL, ServiceEvent::kIsolateSpawn);
      const String& error = String::Handle(
          String::New("spawned isolate exited before notification completed"));
      spawn_event.set_spawn_token(&token);
      spawn_event.set_spawn_error(&error);
      Service::HandleEvent(&spawn_event);
    }
  } else {
    // The isolate failed to spawn.
    ASSERT(result.IsString());
    ServiceEvent spawn_event(NULL, ServiceEvent::kIsolateSpawn);
    spawn_event.set_spawn_token(&token);
    spawn_event.set_spawn_error(&String::Cast(result));
    Service::HandleEvent(&spawn_event);
  }
#endif  // PRODUCT
  return Object::null();
}

}  // namespace dart
