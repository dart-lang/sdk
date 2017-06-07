// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/io_natives.h"

#include <stdlib.h>
#include <string.h>

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "include/dart_api.h"
#include "platform/assert.h"

namespace dart {
namespace bin {

// Lists the native functions implementing advanced dart:io classes.
// Some classes, like File and Directory, list their implementations in
// builtin_natives.cc instead.
#define IO_NATIVE_LIST(V)                                                      \
  V(Crypto_GetRandomBytes, 1)                                                  \
  V(Directory_Exists, 1)                                                       \
  V(Directory_Create, 1)                                                       \
  V(Directory_Current, 0)                                                      \
  V(Directory_SetCurrent, 1)                                                   \
  V(Directory_SystemTemp, 0)                                                   \
  V(Directory_CreateTemp, 1)                                                   \
  V(Directory_Delete, 2)                                                       \
  V(Directory_Rename, 2)                                                       \
  V(Directory_FillWithDirectoryListing, 4)                                     \
  V(Directory_GetAsyncDirectoryListerPointer, 1)                               \
  V(Directory_SetAsyncDirectoryListerPointer, 2)                               \
  V(EventHandler_SendData, 3)                                                  \
  V(EventHandler_TimerMillisecondClock, 0)                                     \
  V(File_GetPointer, 1)                                                        \
  V(File_SetPointer, 2)                                                        \
  V(File_Open, 2)                                                              \
  V(File_Exists, 1)                                                            \
  V(File_Close, 1)                                                             \
  V(File_ReadByte, 1)                                                          \
  V(File_WriteByte, 2)                                                         \
  V(File_Read, 2)                                                              \
  V(File_ReadInto, 4)                                                          \
  V(File_WriteFrom, 4)                                                         \
  V(File_Position, 1)                                                          \
  V(File_SetPosition, 2)                                                       \
  V(File_Truncate, 2)                                                          \
  V(File_Length, 1)                                                            \
  V(File_LengthFromPath, 1)                                                    \
  V(File_Stat, 1)                                                              \
  V(File_LastModified, 1)                                                      \
  V(File_SetLastModified, 2)                                                   \
  V(File_LastAccessed, 1)                                                      \
  V(File_SetLastAccessed, 2)                                                   \
  V(File_Flush, 1)                                                             \
  V(File_Lock, 4)                                                              \
  V(File_Create, 1)                                                            \
  V(File_CreateLink, 2)                                                        \
  V(File_LinkTarget, 1)                                                        \
  V(File_Delete, 1)                                                            \
  V(File_DeleteLink, 1)                                                        \
  V(File_Rename, 2)                                                            \
  V(File_Copy, 2)                                                              \
  V(File_RenameLink, 2)                                                        \
  V(File_ResolveSymbolicLinks, 1)                                              \
  V(File_OpenStdio, 1)                                                         \
  V(File_GetStdioHandleType, 1)                                                \
  V(File_GetType, 2)                                                           \
  V(File_AreIdentical, 2)                                                      \
  V(FileSystemWatcher_CloseWatcher, 1)                                         \
  V(FileSystemWatcher_GetSocketId, 2)                                          \
  V(FileSystemWatcher_InitWatcher, 0)                                          \
  V(FileSystemWatcher_IsSupported, 0)                                          \
  V(FileSystemWatcher_ReadEvents, 2)                                           \
  V(FileSystemWatcher_UnwatchPath, 2)                                          \
  V(FileSystemWatcher_WatchPath, 4)                                            \
  V(Filter_CreateZLibDeflate, 8)                                               \
  V(Filter_CreateZLibInflate, 4)                                               \
  V(Filter_Process, 4)                                                         \
  V(Filter_Processed, 3)                                                       \
  V(InternetAddress_Parse, 1)                                                  \
  V(IOService_NewServicePort, 0)                                               \
  V(NetworkInterface_ListSupported, 0)                                         \
  V(Platform_NumberOfProcessors, 0)                                            \
  V(Platform_OperatingSystem, 0)                                               \
  V(Platform_PathSeparator, 0)                                                 \
  V(Platform_LocalHostname, 0)                                                 \
  V(Platform_ExecutableName, 0)                                                \
  V(Platform_ResolvedExecutableName, 0)                                        \
  V(Platform_Environment, 0)                                                   \
  V(Platform_ExecutableArguments, 0)                                           \
  V(Platform_GetVersion, 0)                                                    \
  V(Platform_LocaleName, 0)                                                    \
  V(Process_Start, 11)                                                         \
  V(Process_Wait, 5)                                                           \
  V(Process_KillPid, 2)                                                        \
  V(Process_SetExitCode, 1)                                                    \
  V(Process_GetExitCode, 0)                                                    \
  V(Process_Exit, 1)                                                           \
  V(Process_Sleep, 1)                                                          \
  V(Process_Pid, 1)                                                            \
  V(Process_SetSignalHandler, 1)                                               \
  V(Process_ClearSignalHandler, 1)                                             \
  V(ProcessInfo_CurrentRSS, 0)                                                 \
  V(ProcessInfo_MaxRSS, 0)                                                     \
  V(SecureSocket_Connect, 7)                                                   \
  V(SecureSocket_Destroy, 1)                                                   \
  V(SecureSocket_FilterPointer, 1)                                             \
  V(SecureSocket_GetSelectedProtocol, 1)                                       \
  V(SecureSocket_Handshake, 1)                                                 \
  V(SecureSocket_Init, 1)                                                      \
  V(SecureSocket_PeerCertificate, 1)                                           \
  V(SecureSocket_RegisterBadCertificateCallback, 2)                            \
  V(SecureSocket_RegisterHandshakeCompleteCallback, 2)                         \
  V(SecureSocket_Renegotiate, 4)                                               \
  V(SecurityContext_Allocate, 1)                                               \
  V(SecurityContext_UsePrivateKeyBytes, 3)                                     \
  V(SecurityContext_SetAlpnProtocols, 3)                                       \
  V(SecurityContext_SetClientAuthoritiesBytes, 3)                              \
  V(SecurityContext_SetTrustedCertificatesBytes, 3)                            \
  V(SecurityContext_TrustBuiltinRoots, 1)                                      \
  V(SecurityContext_UseCertificateChainBytes, 3)                               \
  V(ServerSocket_Accept, 2)                                                    \
  V(ServerSocket_CreateBindListen, 6)                                          \
  V(SocketBase_IsBindError, 2)                                                 \
  V(Socket_Available, 1)                                                       \
  V(Socket_CreateBindConnect, 4)                                               \
  V(Socket_CreateBindDatagram, 4)                                              \
  V(Socket_CreateConnect, 3)                                                   \
  V(Socket_GetPort, 1)                                                         \
  V(Socket_GetRemotePeer, 1)                                                   \
  V(Socket_GetError, 1)                                                        \
  V(Socket_GetOption, 3)                                                       \
  V(Socket_GetSocketId, 1)                                                     \
  V(Socket_GetStdioHandle, 2)                                                  \
  V(Socket_GetType, 1)                                                         \
  V(Socket_JoinMulticast, 4)                                                   \
  V(Socket_LeaveMulticast, 4)                                                  \
  V(Socket_Read, 2)                                                            \
  V(Socket_RecvFrom, 1)                                                        \
  V(Socket_SendTo, 6)                                                          \
  V(Socket_SetOption, 4)                                                       \
  V(Socket_SetSocketId, 2)                                                     \
  V(Socket_WriteList, 4)                                                       \
  V(Stdin_ReadByte, 0)                                                         \
  V(Stdin_GetEchoMode, 0)                                                      \
  V(Stdin_SetEchoMode, 1)                                                      \
  V(Stdin_GetLineMode, 0)                                                      \
  V(Stdin_SetLineMode, 1)                                                      \
  V(Stdin_AnsiSupported, 0)                                                    \
  V(Stdout_GetTerminalSize, 1)                                                 \
  V(Stdout_AnsiSupported, 1)                                                   \
  V(StringToSystemEncoding, 1)                                                 \
  V(SynchronousSocket_Available, 1)                                            \
  V(SynchronousSocket_CloseSync, 1)                                            \
  V(SynchronousSocket_CreateConnectSync, 3)                                    \
  V(SynchronousSocket_GetPort, 1)                                              \
  V(SynchronousSocket_GetRemotePeer, 1)                                        \
  V(SynchronousSocket_LookupRequest, 2)                                        \
  V(SynchronousSocket_ShutdownRead, 1)                                         \
  V(SynchronousSocket_ShutdownWrite, 1)                                        \
  V(SynchronousSocket_Read, 2)                                                 \
  V(SynchronousSocket_ReadList, 4)                                             \
  V(SynchronousSocket_WriteList, 4)                                            \
  V(SystemEncodingToString, 1)                                                 \
  V(X509_Subject, 1)                                                           \
  V(X509_Issuer, 1)                                                            \
  V(X509_StartValidity, 1)                                                     \
  V(X509_EndValidity, 1)

IO_NATIVE_LIST(DECLARE_FUNCTION);

static struct NativeEntries {
  const char* name_;
  Dart_NativeFunction function_;
  int argument_count_;
} IOEntries[] = {IO_NATIVE_LIST(REGISTER_FUNCTION)};


Dart_NativeFunction IONativeLookup(Dart_Handle name,
                                   int argument_count,
                                   bool* auto_setup_scope) {
  const char* function_name = NULL;
  Dart_Handle result = Dart_StringToCString(name, &function_name);
  DART_CHECK_VALID(result);
  ASSERT(function_name != NULL);
  ASSERT(auto_setup_scope != NULL);
  *auto_setup_scope = true;
  int num_entries = sizeof(IOEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(IOEntries[i]);
    if ((strcmp(function_name, entry->name_) == 0) &&
        (entry->argument_count_ == argument_count)) {
      return reinterpret_cast<Dart_NativeFunction>(entry->function_);
    }
  }
  return NULL;
}


const uint8_t* IONativeSymbol(Dart_NativeFunction nf) {
  int num_entries = sizeof(IOEntries) / sizeof(struct NativeEntries);
  for (int i = 0; i < num_entries; i++) {
    struct NativeEntries* entry = &(IOEntries[i]);
    if (reinterpret_cast<Dart_NativeFunction>(entry->function_) == nf) {
      return reinterpret_cast<const uint8_t*>(entry->name_);
    }
  }
  return NULL;
}

}  // namespace bin
}  // namespace dart
