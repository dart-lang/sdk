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


static void GetSockAddr(Dart_Handle obj, RawAddr* addr) {
  Dart_TypedData_Type data_type;
  uint8_t* data = NULL;
  intptr_t len;
  Dart_Handle result = Dart_TypedDataAcquireData(
      obj, &data_type, reinterpret_cast<void**>(&data), &len);
  if (Dart_IsError(result)) Dart_PropagateError(result);
  memmove(reinterpret_cast<void *>(addr), data, len);
  Dart_TypedDataReleaseData(obj);
}


void FUNCTION_NAME(InternetAddress_Fixed)(Dart_NativeArguments args) {
  int64_t id = 0;
  bool ok = DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &id);
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
      raw.in6.sin6_addr = in6addr_loopback;
      break;
    }
    case SocketAddress::ADDRESS_ANY_IP_V4: {
      raw.in.sin_family = AF_INET;
      raw.in.sin_addr.s_addr = INADDR_ANY;
      break;
    }
    case SocketAddress::ADDRESS_ANY_IP_V6: {
      raw.in6.sin6_family = AF_INET6;
      raw.in6.sin6_addr = in6addr_any;
      break;
    }
    default:
      Dart_Handle error = DartUtils::NewDartArgumentError("");
      if (Dart_IsError(error)) Dart_PropagateError(error);
      Dart_ThrowException(error);
  }
  Dart_SetReturnValue(args, SocketAddress::ToTypedData(&raw));
}


void FUNCTION_NAME(InternetAddress_Parse)(Dart_NativeArguments args) {
  int64_t type = 0;
  bool ok = DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 0), &type);
  ASSERT(ok);
  USE(ok);
  const char* address =
      DartUtils::GetStringValue(Dart_GetNativeArgument(args, 1));
  ASSERT(address != NULL);
  RawAddr raw;
  memset(&raw, 0, sizeof(raw));
  if (type == SocketAddress::TYPE_IPV4) {
    raw.addr.sa_family = AF_INET;
  } else {
    ASSERT(type == SocketAddress::TYPE_IPV6);
    raw.addr.sa_family = AF_INET6;
  }
  ok = Socket::ParseAddress(type, address, &raw);
  if (!ok) {
    Dart_SetReturnValue(args, Dart_Null());
  } else {
    Dart_SetReturnValue(args, SocketAddress::ToTypedData(&raw));
  }
}


void FUNCTION_NAME(Socket_CreateConnect)(Dart_NativeArguments args) {
  RawAddr addr;
  GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  int64_t port = 0;
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 2), &port)) {
    intptr_t socket = Socket::CreateConnect(addr, port);
    OSError error;
    if (socket >= 0) {
      Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket);
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
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t available = Socket::Available(socket);
  if (available >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(available));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_Read)(Dart_NativeArguments args) {
  static bool short_socket_reads = Dart_IsVMFlagSet("short_socket_read");
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t available = Socket::Available(socket);
  if (available > 0) {
    int64_t length = 0;
    if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 1), &length)) {
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
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
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
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  OSError os_error;
  intptr_t port = Socket::GetPort(socket);
  if (port > 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(port));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_GetRemotePeer)(Dart_NativeArguments args) {
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  OSError os_error;
  intptr_t port = 0;
  SocketAddress* addr = Socket::GetRemotePeer(socket, &port);
  if (addr != NULL) {
    Dart_Handle list = Dart_NewList(2);

    Dart_Handle entry = Dart_NewList(3);
    Dart_ListSetAt(entry, 0, Dart_NewInteger(addr->GetType()));
    Dart_ListSetAt(entry, 1, Dart_NewStringFromCString(addr->as_string()));

    RawAddr raw = addr->addr();
    intptr_t data_length = SocketAddress::GetAddrLength(&raw);
    Dart_Handle data = Dart_NewTypedData(Dart_TypedData_kUint8, data_length);
    Dart_ListSetAsBytes(data, 0, reinterpret_cast<uint8_t*>(&raw), data_length);
    Dart_ListSetAt(entry, 2, data);

    Dart_ListSetAt(list, 0, entry);
    Dart_ListSetAt(list, 1, Dart_NewInteger(port));
    Dart_SetReturnValue(args, list);
    delete addr;
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_GetError)(Dart_NativeArguments args) {
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  OSError os_error;
  Socket::GetError(socket, &os_error);
  Dart_SetReturnValue(args, DartUtils::NewDartOSError(&os_error));
}


void FUNCTION_NAME(Socket_GetType)(Dart_NativeArguments args) {
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  OSError os_error;
  intptr_t type = Socket::GetType(socket);
  if (type >= 0) {
    Dart_SetReturnValue(args, Dart_NewInteger(type));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


void FUNCTION_NAME(Socket_GetStdioHandle)(Dart_NativeArguments args) {
  intptr_t num =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  ASSERT(num == 0 || num == 1 || num == 2);
  intptr_t socket = Socket::GetStdioHandle(num);
  Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket);
  Dart_SetReturnValue(args, Dart_NewBoolean(socket >= 0));
}


void FUNCTION_NAME(Socket_SetSocketId)(Dart_NativeArguments args) {
  intptr_t id =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), id);
}


void FUNCTION_NAME(ServerSocket_CreateBindListen)(Dart_NativeArguments args) {
  RawAddr addr;
  int64_t port = 0;
  int64_t backlog = 0;
  GetSockAddr(Dart_GetNativeArgument(args, 1), &addr);
  if (DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 2), &port) &&
      DartUtils::GetInt64Value(Dart_GetNativeArgument(args, 3), &backlog)) {
    bool v6_only = DartUtils::GetBooleanValue(Dart_GetNativeArgument(args, 4));
    intptr_t socket = ServerSocket::CreateBindListen(
        addr, port, backlog, v6_only);
    OSError error;
    if (socket >= 0) {
      Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 0), socket);
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
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  intptr_t new_socket = ServerSocket::Accept(socket);
  if (new_socket >= 0) {
    Socket::SetSocketIdNativeField(Dart_GetNativeArgument(args, 1), new_socket);
    Dart_SetReturnValue(args, Dart_True());
  } else if (new_socket == ServerSocket::kTemporaryFailure) {
    Dart_SetReturnValue(args, Dart_False());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}


CObject* Socket::LookupRequest(const CObjectArray& request) {
  if (request.Length() == 2 &&
      request[0]->IsString() &&
      request[1]->IsInt32()) {
    CObjectString host(request[0]);
    CObjectInt32 type(request[1]);
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


CObject* Socket::ReverseLookupRequest(const CObjectArray& request) {
  if (request.Length() == 1 &&
      request[0]->IsTypedData()) {
    CObjectUint8Array addr_object(request[0]);
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



CObject* Socket::ListInterfacesRequest(const CObjectArray& request) {
  if (request.Length() == 1 &&
      request[0]->IsInt32()) {
    CObjectInt32 type(request[0]);
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


void FUNCTION_NAME(Socket_SetOption)(Dart_NativeArguments args) {
  bool result = false;
  intptr_t socket =
      Socket::GetSocketIdNativeField(Dart_GetNativeArgument(args, 0));
  Dart_Handle option_obj = Dart_GetNativeArgument(args, 1);
  int64_t option;
  Dart_Handle err = Dart_IntegerToInt64(option_obj, &option);
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


void Socket::SetSocketIdNativeField(Dart_Handle socket, intptr_t id) {
  Dart_Handle err =
      Dart_SetNativeInstanceField(socket, kSocketIdNativeField, id);
  if (Dart_IsError(err)) Dart_PropagateError(err);
}


intptr_t Socket::GetSocketIdNativeField(Dart_Handle socket_obj) {
  intptr_t socket = 0;
  Dart_Handle err =
      Dart_GetNativeInstanceField(socket_obj, kSocketIdNativeField, &socket);
  if (Dart_IsError(err)) Dart_PropagateError(err);
  return socket;
}

}  // namespace bin
}  // namespace dart
