// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_buffer.h"
#include "bin/socket.h"
#include "bin/dartutils.h"
#include "bin/thread.h"
#include "bin/utils.h"

#include "platform/globals.h"
#include "platform/thread.h"
#include "platform/utils.h"

#include "include/dart_api.h"


namespace dart {
namespace bin {

static const int kSocketIdNativeField = 0;

dart::Mutex* Socket::mutex_ = new dart::Mutex();
int Socket::service_ports_size_ = 0;
Dart_Port* Socket::service_ports_ = NULL;
int Socket::service_ports_index_ = 0;


static Dart_Handle GetSockAddr(Dart_Handle obj, RawAddr* addr) {
  Dart_TypedData_Type data_type;
  uint8_t* data = NULL;
  intptr_t len;
  Dart_Handle result = Dart_TypedDataAcquireData(
      obj, &data_type, reinterpret_cast<void**>(&data), &len);
  if (Dart_IsError(result)) return result;
  memmove(reinterpret_cast<void *>(addr), data, len);
  return Dart_Null();
}


void FUNCTION_NAME(InternetAddress_Fixed)(Dart_NativeArguments args) {
  Dart_Handle id_obj = Dart_GetNativeArgument(args, 0);
  ASSERT(!Dart_IsError(id_obj));
  int64_t id = 0;
  bool ok = DartUtils::GetInt64Value(id_obj, &id);
  ASSERT(ok);
  USE(ok);
  RawAddr raw;
  memset(&raw, 0, sizeof(raw));
  switch (id) {
    case SocketAddress::ADDRESS_LOOPBACK_IP_V4: {
      raw.in.sin_family = AF_INET;
      raw.in.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
      break;
    }
    case SocketAddress::ADDRESS_LOOPBACK_IP_V6: {
      raw.in6.sin6_family = AF_INET6;
      raw.in6.sin6_addr = in6addr_any;
      break;
    }
    case SocketAddress::ADDRESS_ANY_IP_V4: {
      raw.in.sin_family = AF_INET;
      raw.in.sin_addr.s_addr = INADDR_ANY;
      break;
    }
    case SocketAddress::ADDRESS_ANY_IP_V6: {
      raw.in6.sin6_family = AF_INET6;
      raw.in6.sin6_addr = in6addr_loopback;
      break;
    }
    default:
      Dart_Handle error = DartUtils::NewDartArgumentError("");
      if (Dart_IsError(error)) Dart_PropagateError(error);
      Dart_ThrowException(error);
  }
  int len = SocketAddress::GetAddrLength(&raw);
  Dart_Handle result = Dart_NewTypedData(Dart_TypedData_kUint8, len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  Dart_ListSetAsBytes(result, 0, reinterpret_cast<uint8_t *>(&raw), len);
  Dart_SetReturnValue(args, result);
}


void FUNCTION_NAME(Socket_CreateConnect)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle host_obj = Dart_GetNativeArgument(args, 1);
  RawAddr addr;
  Dart_Handle result = GetSockAddr(host_obj, &addr);
  int64_t port = 0;
  if (!Dart_IsError(result) &&
      DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 2), &port)) {
    intptr_t socket = Socket::CreateConnect(addr, port);
    OSError error;
    Dart_TypedDataReleaseData(host_obj);
    if (socket >= 0) {
      Dart_Handle err = Socket::SetSocketIdNativeField(socket_obj, socket);
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, Dart_True());
    } else {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_Handle err = DartUtils::NewDartOSError(&os_error);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Socket_Available)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  intptr_t available = Socket::Available(socket);
  if (available >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(available));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_Read)(Dart_NativeArguments args) {
  static bool short_socket_reads = Dart_IsVMFlagSet("short_socket_read");
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  intptr_t available = Socket::Available(socket);
  if (available > 0) {
    int64_t length = 0;
    Dart_Handle length_obj = Dart_GetNativeArgument(args, 1);
    if (DartUtils::GetInt64Value(length_obj, &length)) {
      if (length == -1 || available < length) {
        length = available;
      }
      if (short_socket_reads) {
        length = (length + 1) / 2;
      }
      uint8_t* buffer = NULL;
      Dart_Handle result = IOBuffer::Allocate(length, &buffer);
      if (Dart_IsError(result)) Dart_PropagateError(result);
      ASSERT(buffer != NULL);
      intptr_t bytes_read = Socket::Read(socket, buffer, length);
      if (bytes_read == length) {
        Dart_SetReturnValue(args, result);
      } else if (bytes_read < length) {
        // On MacOS when reading from a tty Ctrl-D will result in reading one
        // less byte then reported as available.
        if (bytes_read == 0) {
          Dart_SetReturnValue(args, Dart_Null());
        } else {
          uint8_t* new_buffer = NULL;
          Dart_Handle new_result = IOBuffer::Allocate(bytes_read, &new_buffer);
          if (Dart_IsError(new_result)) Dart_PropagateError(new_result);
          ASSERT(new_buffer != NULL);
          memmove(new_buffer, buffer, bytes_read);
          Dart_SetReturnValue(args, new_result);
        }
      } else {
        ASSERT(bytes_read == -1);
        Dart_SetReturnValue(args, DartUtils::NewDartOSError());
      }
    } else {
      OSError os_error(-1, "Invalid argument", OSError::kUnknown);
      Dart_Handle err = DartUtils::NewDartOSError(&os_error);
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
    }
  } else if (available == 0) {
    Dart_SetReturnValue(args, Dart_Null());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_WriteList)(Dart_NativeArguments args) {
  static bool short_socket_writes = Dart_IsVMFlagSet("short_socket_write");
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  Dart_Handle buffer_obj = Dart_GetNativeArgument(args, 1);
  ASSERT(Dart_IsList(buffer_obj));
  intptr_t offset =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 2));
  intptr_t length =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 3));
  if (short_socket_writes) {
    length = (length + 1) / 2;
  }
  Dart_TypedData_Type type;
  uint8_t* buffer = NULL;
  intptr_t len;
  Dart_Handle result = Dart_TypedDataAcquireData(
      buffer_obj, &type, reinterpret_cast<void**>(&buffer), &len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  ASSERT((offset + length) <= len);
  buffer += offset;
  intptr_t bytes_written = Socket::Write(socket, buffer, length);
  if (bytes_written >= 0) {
    Dart_TypedDataReleaseData(buffer_obj);
    Dart_SetReturnValue(args, Dart_NewInteger(bytes_written));
  } else {
    // Extract OSError before we release data, as it may override the error.
    OSError os_error;
    Dart_TypedDataReleaseData(buffer_obj);
    Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
  }
}


void FUNCTION_NAME(Socket_GetPort)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  OSError os_error;
  intptr_t port = Socket::GetPort(socket);
  if (port > 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(port));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_GetRemotePeer)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  OSError os_error;
  intptr_t port = 0;
  ASSERT(INET6_ADDRSTRLEN >= INET_ADDRSTRLEN);
  char host[INET6_ADDRSTRLEN];
  if (Socket::GetRemotePeer(socket, host, &port)) {
    Dart_Handle list = Dart_NewList(2);
    Dart_ListSetAt(list, 0, Dart_NewStringFromCString(host));
    Dart_ListSetAt(list, 1, Dart_NewInteger(port));
    Dart_SetReturnValue(args, list);
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_GetError)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  OSError os_error;
  Socket::GetError(socket, &os_error);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
}


void FUNCTION_NAME(Socket_GetType)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Socket::GetSocketIdNativeField(socket_obj, &socket);
  OSError os_error;
  intptr_t type = Socket::GetType(socket);
  if (type >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(type));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_GetStdioHandle)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t num =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  ASSERT(num == 0 || num == 1 || num == 2);
  intptr_t socket = Socket::GetStdioHandle(num);
  Dart_Handle err = Socket::SetSocketIdNativeField(socket_obj, socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  Dart_SetReturnValue(args, Dart_NewBoolean(socket >= 0));
}


void FUNCTION_NAME(ServerSocket_CreateBindListen)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  Dart_Handle host_obj = Dart_GetNativeArgument(args, 1);
  RawAddr addr;
  Dart_Handle result = GetSockAddr(host_obj, &addr);
  Dart_Handle port_obj = Dart_GetNativeArgument(args, 2);
  Dart_Handle backlog_obj = Dart_GetNativeArgument(args, 3);
  Dart_Handle v6_only_obj = Dart_GetNativeArgument(args, 4);
  bool v6_only = DartUtils::GetBooleanValue(v6_only_obj);
  int64_t port = 0;
  int64_t backlog = 0;
  if (!Dart_IsError(result) &&
      DartUtils::GetInt64Value(port_obj, &port) &&
      DartUtils::GetInt64Value(backlog_obj, &backlog)) {
    intptr_t socket = ServerSocket::CreateBindListen(
        addr, port, backlog, v6_only);
    OSError error;
    Dart_TypedDataReleaseData(host_obj);
    if (socket >= 0) {
      Dart_Handle err = Socket::SetSocketIdNativeField(socket_obj, socket);
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, Dart_True());
    } else {
      if (socket == -5) {
        OSError os_error(-1, "Invalid host", OSError::kUnknown);
        Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
      } else {
        Dart_SetReturnValue(args, DartUtils::NewDartOSError(&error));
      }
    }
  } else {
    OSError os_error(-1, "Invalid argument", OSError::kUnknown);
    Dart_Handle err = DartUtils::NewDartOSError(&os_error);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(ServerSocket_Accept)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  Dart_Handle result_socket_obj = Dart_GetNativeArgument(args, 1);
  intptr_t new_socket = ServerSocket::Accept(socket);
  if (new_socket >= 0) {
    Dart_Handle err = Socket::SetSocketIdNativeField(result_socket_obj,
                                                     new_socket);
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, Dart_True());
  } else if (new_socket == ServerSocket::kTemporaryFailure) {
    Dart_SetReturnValue(args, Dart_False());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


static CObject* LookupRequest(const CObjectArray& request) {
  if (request.Length() == 3 &&
      request[1]->IsString() &&
      request[2]->IsInt32()) {
    CObjectString host(request[1]);
    CObjectInt32 type(request[2]);
    CObject* result = NULL;
    OSError* os_error = NULL;
    AddressList<SocketAddress>* addresses =
        Socket::LookupAddress(host.CString(), type.Value(), &os_error);
    if (addresses != NULL) {
      CObjectArray* array = new CObjectArray(
          CObject::NewArray(addresses->count() + 1));
      array->SetAt(0, new CObjectInt32(CObject::NewInt32(0)));
      for (intptr_t i = 0; i < addresses->count(); i++) {
        SocketAddress* addr = addresses->GetAt(i);
        CObjectArray* entry = new CObjectArray(CObject::NewArray(3));

        CObjectInt32* type = new CObjectInt32(
            CObject::NewInt32(addr->GetType()));
        entry->SetAt(0, type);

        CObjectString* as_string = new CObjectString(CObject::NewString(
            addr->as_string()));
        entry->SetAt(1, as_string);

        RawAddr raw = addr->addr();
        CObjectUint8Array* data = new CObjectUint8Array(CObject::NewUint8Array(
            SocketAddress::GetAddrLength(&raw)));
        memmove(data->Buffer(),
                reinterpret_cast<void *>(&raw),
                SocketAddress::GetAddrLength(&raw));

        entry->SetAt(2, data);
        array->SetAt(i + 1, entry);
      }
      result = array;
      delete addresses;
    } else {
      result = CObject::NewOSError(os_error);
      delete os_error;
    }
    return result;
  }
  return CObject::IllegalArgumentError();
}


static CObject* ReverseLookupRequest(const CObjectArray& request) {
  if (request.Length() == 2 &&
      request[1]->IsTypedData()) {
    CObjectUint8Array addr_object(request[1]);
    RawAddr addr;
    memmove(reinterpret_cast<void *>(&addr),
            addr_object.Buffer(),
            addr_object.Length());
    OSError* os_error = NULL;
    const intptr_t kMaxHostLength = 1025;
    char host[kMaxHostLength];
    if (Socket::ReverseLookup(addr, host, kMaxHostLength, &os_error)) {
      return new CObjectString(CObject::NewString(host));
    } else {
      CObject* result = CObject::NewOSError(os_error);
      delete os_error;
      return result;
    }
  }
  return CObject::IllegalArgumentError();
}



static CObject* ListInterfacesRequest(const CObjectArray& request) {
  if (request.Length() == 2 &&
      request[1]->IsInt32()) {
    CObjectInt32 type(request[1]);
    CObject* result = NULL;
    OSError* os_error = NULL;
    AddressList<InterfaceSocketAddress>* addresses = Socket::ListInterfaces(
        type.Value(), &os_error);
    if (addresses != NULL) {
      CObjectArray* array = new CObjectArray(
          CObject::NewArray(addresses->count() + 1));
      array->SetAt(0, new CObjectInt32(CObject::NewInt32(0)));
      for (intptr_t i = 0; i < addresses->count(); i++) {
        InterfaceSocketAddress* interface = addresses->GetAt(i);
        SocketAddress* addr = interface->socket_address();
        CObjectArray* entry = new CObjectArray(CObject::NewArray(4));

        CObjectInt32* type = new CObjectInt32(
            CObject::NewInt32(addr->GetType()));
        entry->SetAt(0, type);

        CObjectString* as_string = new CObjectString(CObject::NewString(
            addr->as_string()));
        entry->SetAt(1, as_string);

        RawAddr raw = addr->addr();
        CObjectUint8Array* data = new CObjectUint8Array(CObject::NewUint8Array(
            SocketAddress::GetAddrLength(&raw)));
        memmove(data->Buffer(),
                reinterpret_cast<void *>(&raw),
                SocketAddress::GetAddrLength(&raw));
        entry->SetAt(2, data);

        CObjectString* interface_name = new CObjectString(CObject::NewString(
            interface->interface_name()));
        entry->SetAt(3, interface_name);

        array->SetAt(i + 1, entry);
      }
      result = array;
      delete addresses;
    } else {
      result = CObject::NewOSError(os_error);
      delete os_error;
    }
    return result;
  }
  return CObject::IllegalArgumentError();
}


void SocketService(Dart_Port dest_port_id,
                   Dart_Port reply_port_id,
                   Dart_CObject* message) {
  CObject* response = CObject::IllegalArgumentError();
  CObjectArray request(message);
  if (message->type == Dart_CObject_kArray) {
    if (request.Length() > 1 && request[0]->IsInt32()) {
      CObjectInt32 request_type(request[0]);
      switch (request_type.Value()) {
        case Socket::kLookupRequest:
          response = LookupRequest(request);
          break;
        case Socket::kListInterfacesRequest:
          response = ListInterfacesRequest(request);
          break;
        case Socket::kReverseLookupRequest:
          response = ReverseLookupRequest(request);
          break;
        default:
          UNREACHABLE();
      }
    }
  }

  Dart_PostCObject(reply_port_id, response->AsApiCObject());
}


Dart_Port Socket::GetServicePort() {
  MutexLocker lock(mutex_);
  if (service_ports_size_ == 0) {
    ASSERT(service_ports_ == NULL);
    service_ports_size_ = 16;
    service_ports_ = new Dart_Port[service_ports_size_];
    service_ports_index_ = 0;
    for (int i = 0; i < service_ports_size_; i++) {
      service_ports_[i] = ILLEGAL_PORT;
    }
  }

  Dart_Port result = service_ports_[service_ports_index_];
  if (result == ILLEGAL_PORT) {
    result = Dart_NewNativePort("SocketService",
                                SocketService,
                                true);
    ASSERT(result != ILLEGAL_PORT);
    service_ports_[service_ports_index_] = result;
  }
  service_ports_index_ = (service_ports_index_ + 1) % service_ports_size_;
  return result;
}


void FUNCTION_NAME(Socket_NewServicePort)(Dart_NativeArguments args) {
  Dart_SetReturnValue(args, Dart_Null());
  Dart_Port service_port = Socket::GetServicePort();
  if (service_port != ILLEGAL_PORT) {
    // Return a send port for the service port.
    Dart_Handle send_port = Dart_NewSendPort(service_port);
    Dart_SetReturnValue(args, send_port);
  }
}


void FUNCTION_NAME(Socket_SetOption)(Dart_NativeArguments args) {
  Dart_Handle socket_obj = Dart_GetNativeArgument(args, 0);
  intptr_t socket = 0;
  bool result = false;
  Dart_Handle err = Socket::GetSocketIdNativeField(socket_obj, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  Dart_Handle option_obj = Dart_GetNativeArgument(args, 1);
  int64_t option;
  err = Dart_IntegerToInt64(option_obj, &option);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  Dart_Handle enabled_obj = Dart_GetNativeArgument(args, 2);
  bool enabled;
  err = Dart_BooleanValue(enabled_obj, &enabled);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  switch (option) {
    case 0:  // TCP_NODELAY.
      result = Socket::SetNoDelay(socket, enabled);
      break;
    default:
      break;
  }
  Dart_SetReturnValue(args, Dart_NewBoolean(result));
}


Dart_Handle Socket::SetSocketIdNativeField(Dart_Handle socket, intptr_t id) {
  return Dart_SetNativeInstanceField(socket, kSocketIdNativeField, id);
}


Dart_Handle Socket::GetSocketIdNativeField(Dart_Handle socket, intptr_t* id) {
  return Dart_GetNativeInstanceField(socket, kSocketIdNativeField, id);
}

}  // namespace bin
}  // namespace dart
