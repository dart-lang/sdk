// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

#include "bin/dartutils.h"
#include "bin/log.h"
#include "include/dart_api.h"
#include "platform/assert.h"

namespace dart {
namespace bin {

char* Directory::system_temp_path_override_ = NULL;

void FUNCTION_NAME(Directory_Current)(Dart_NativeArguments args) {
  const char* current = Directory::Current();
  if (current != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(current));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Directory_SetCurrent)(Dart_NativeArguments args) {
  int argc = Dart_GetNativeArgumentCount(args);
  Dart_Handle path;
  if (argc == 1) {
    path = Dart_GetNativeArgument(args, 0);
  }
  if ((argc != 1) || !Dart_IsString(path)) {
    Dart_SetReturnValue(args, DartUtils::NewDartArgumentError(NULL));
  } else {
    if (Directory::SetCurrent(DartUtils::GetStringValue(path))) {
      Dart_SetReturnValue(args, Dart_True());
    } else {
      Dart_SetReturnValue(args, DartUtils::NewDartOSError());
    }
  }
}

void FUNCTION_NAME(Directory_Exists)(Dart_NativeArguments args) {
  static const int kExists = 1;
  static const int kDoesNotExist = 0;
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  Directory::ExistsResult result =
      Directory::Exists(DartUtils::GetStringValue(path));
  if (result == Directory::EXISTS) {
    Dart_SetReturnValue(args, Dart_NewInteger(kExists));
  } else if (result == Directory::DOES_NOT_EXIST) {
    Dart_SetReturnValue(args, Dart_NewInteger(kDoesNotExist));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Directory_Create)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  if (Directory::Create(DartUtils::GetStringValue(path))) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Directory_SystemTemp)(Dart_NativeArguments args) {
  const char* result = Directory::SystemTemp();
  Dart_SetReturnValue(args, DartUtils::NewString(result));
}

void FUNCTION_NAME(Directory_CreateTemp)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  if (!Dart_IsString(path)) {
    Dart_SetReturnValue(
        args, DartUtils::NewDartArgumentError(
                  "Prefix argument of CreateSystemTempSync is not a String"));
    return;
  }
  const char* result = Directory::CreateTemp(DartUtils::GetStringValue(path));
  if (result != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(result));
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Directory_Delete)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  Dart_Handle recursive = Dart_GetNativeArgument(args, 1);
  if (Directory::Delete(DartUtils::GetStringValue(path),
                        DartUtils::GetBooleanValue(recursive))) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Directory_Rename)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  Dart_Handle newPath = Dart_GetNativeArgument(args, 1);
  if (Directory::Rename(DartUtils::GetStringValue(path),
                        DartUtils::GetStringValue(newPath))) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_SetReturnValue(args, DartUtils::NewDartOSError());
  }
}

void FUNCTION_NAME(Directory_FillWithDirectoryListing)(
    Dart_NativeArguments args) {
  // The list that we should fill.
  Dart_Handle results = Dart_GetNativeArgument(args, 0);
  Dart_Handle path = Dart_GetNativeArgument(args, 1);
  Dart_Handle recursive = Dart_GetNativeArgument(args, 2);
  Dart_Handle follow_links = Dart_GetNativeArgument(args, 3);

  Dart_Handle dart_error;
  {
    // Pass the list that should hold the directory listing to the
    // SyncDirectoryListing object, which adds elements to it.
    SyncDirectoryListing sync_listing(results, DartUtils::GetStringValue(path),
                                      DartUtils::GetBooleanValue(recursive),
                                      DartUtils::GetBooleanValue(follow_links));
    Directory::List(&sync_listing);
    dart_error = sync_listing.dart_error();
  }
  if (Dart_IsError(dart_error)) {
    Dart_PropagateError(dart_error);
  } else if (!Dart_IsNull(dart_error)) {
    Dart_ThrowException(dart_error);
  }
}

static const int kAsyncDirectoryListerFieldIndex = 0;

void FUNCTION_NAME(Directory_GetAsyncDirectoryListerPointer)(
    Dart_NativeArguments args) {
  AsyncDirectoryListing* listing;
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  ASSERT(Dart_IsInstance(dart_this));
  ThrowIfError(
      Dart_GetNativeInstanceField(dart_this, kAsyncDirectoryListerFieldIndex,
                                  reinterpret_cast<intptr_t*>(&listing)));
  if (listing != NULL) {
    intptr_t listing_pointer = reinterpret_cast<intptr_t>(listing);
    // Increment the listing's reference count. This native should only be
    // be called when we are about to send the AsyncDirectoryListing* to the
    // IO service.
    listing->Retain();
    Dart_SetReturnValue(args, Dart_NewInteger(listing_pointer));
  }
}

static void ReleaseListing(void* isolate_callback_data,
                           Dart_WeakPersistentHandle handle,
                           void* peer) {
  AsyncDirectoryListing* listing =
      reinterpret_cast<AsyncDirectoryListing*>(peer);
  listing->Release();
}

void FUNCTION_NAME(Directory_SetAsyncDirectoryListerPointer)(
    Dart_NativeArguments args) {
  Dart_Handle dart_this = ThrowIfError(Dart_GetNativeArgument(args, 0));
  intptr_t listing_pointer =
      DartUtils::GetIntptrValue(Dart_GetNativeArgument(args, 1));
  AsyncDirectoryListing* listing =
      reinterpret_cast<AsyncDirectoryListing*>(listing_pointer);
  Dart_NewWeakPersistentHandle(dart_this, reinterpret_cast<void*>(listing),
                               sizeof(*listing), ReleaseListing);
  Dart_Handle result = Dart_SetNativeInstanceField(
      dart_this, kAsyncDirectoryListerFieldIndex, listing_pointer);
  if (Dart_IsError(result)) {
    Log::PrintErr("SetAsyncDirectoryListerPointer failed\n");
    Dart_PropagateError(result);
  }
}

void Directory::SetSystemTemp(const char* path) {
  if (system_temp_path_override_ != NULL) {
    free(system_temp_path_override_);
    system_temp_path_override_ = NULL;
  }
  if (path != NULL) {
    system_temp_path_override_ = strdup(path);
  }
}

CObject* Directory::CreateRequest(const CObjectArray& request) {
  if ((request.Length() == 1) && request[0]->IsString()) {
    CObjectString path(request[0]);
    if (Directory::Create(path.CString())) {
      return CObject::True();
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}

CObject* Directory::DeleteRequest(const CObjectArray& request) {
  if ((request.Length() == 2) && request[0]->IsString() &&
      request[1]->IsBool()) {
    CObjectString path(request[0]);
    CObjectBool recursive(request[1]);
    if (Directory::Delete(path.CString(), recursive.Value())) {
      return CObject::True();
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}

CObject* Directory::ExistsRequest(const CObjectArray& request) {
  static const int kExists = 1;
  static const int kDoesNotExist = 0;
  if ((request.Length() == 1) && request[0]->IsString()) {
    CObjectString path(request[0]);
    Directory::ExistsResult result = Directory::Exists(path.CString());
    if (result == Directory::EXISTS) {
      return new CObjectInt32(CObject::NewInt32(kExists));
    } else if (result == Directory::DOES_NOT_EXIST) {
      return new CObjectInt32(CObject::NewInt32(kDoesNotExist));
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}

CObject* Directory::CreateTempRequest(const CObjectArray& request) {
  if ((request.Length() == 1) && request[0]->IsString()) {
    CObjectString path(request[0]);
    const char* result = Directory::CreateTemp(path.CString());
    if (result != NULL) {
      CObject* temp_dir = new CObjectString(CObject::NewString(result));
      return temp_dir;
    } else {
      return CObject::NewOSError();
    }
  }
  return CObject::IllegalArgumentError();
}

static CObject* CreateIllegalArgumentError() {
  // Respond with an illegal argument list error message.
  CObjectArray* error = new CObjectArray(CObject::NewArray(3));
  error->SetAt(0, new CObjectInt32(
                      CObject::NewInt32(AsyncDirectoryListing::kListError)));
  error->SetAt(1, CObject::Null());
  error->SetAt(2, CObject::IllegalArgumentError());
  return error;
}

CObject* Directory::ListStartRequest(const CObjectArray& request) {
  if ((request.Length() == 3) && request[0]->IsString() &&
      request[1]->IsBool() && request[2]->IsBool()) {
    CObjectString path(request[0]);
    CObjectBool recursive(request[1]);
    CObjectBool follow_links(request[2]);
    AsyncDirectoryListing* dir_listing = new AsyncDirectoryListing(
        path.CString(), recursive.Value(), follow_links.Value());
    if (dir_listing->error()) {
      // Report error now, so we capture the correct OSError.
      CObject* err = CObject::NewOSError();
      dir_listing->Release();
      CObjectArray* error = new CObjectArray(CObject::NewArray(3));
      error->SetAt(0, new CObjectInt32(CObject::NewInt32(
                          AsyncDirectoryListing::kListError)));
      error->SetAt(1, request[0]);
      error->SetAt(2, err);
      return error;
    }
    // TODO(ajohnsen): Consider returning the first few results.
    return new CObjectIntptr(
        CObject::NewIntptr(reinterpret_cast<intptr_t>(dir_listing)));
  }
  return CreateIllegalArgumentError();
}

CObject* Directory::ListNextRequest(const CObjectArray& request) {
  if ((request.Length() == 1) && request[0]->IsIntptr()) {
    CObjectIntptr ptr(request[0]);
    AsyncDirectoryListing* dir_listing =
        reinterpret_cast<AsyncDirectoryListing*>(ptr.Value());
    RefCntReleaseScope<AsyncDirectoryListing> rs(dir_listing);
    if (dir_listing->IsEmpty()) {
      return new CObjectArray(CObject::NewArray(0));
    }
    const int kArraySize = 128;
    CObjectArray* response = new CObjectArray(CObject::NewArray(kArraySize));
    dir_listing->SetArray(response, kArraySize);
    Directory::List(dir_listing);
    // In case the listing ended before it hit the buffer length, we need to
    // override the array length.
    response->AsApiCObject()->value.as_array.length = dir_listing->index();
    return response;
  }
  return CreateIllegalArgumentError();
}

CObject* Directory::ListStopRequest(const CObjectArray& request) {
  if ((request.Length() == 1) && request[0]->IsIntptr()) {
    CObjectIntptr ptr(request[0]);
    AsyncDirectoryListing* dir_listing =
        reinterpret_cast<AsyncDirectoryListing*>(ptr.Value());
    RefCntReleaseScope<AsyncDirectoryListing> rs(dir_listing);

    // We have retained a reference to the listing here. Therefore the listing's
    // destructor can't be running. Since no further requests are dispatched by
    // the Dart code after an async stop call, this PopAll() can't be racing
    // with any other call on the listing. We don't do an extra Release(), and
    // we don't delete the weak persistent handle. The file is closed here, but
    // the memory for the listing will be cleaned up when the finalizer runs.
    dir_listing->PopAll();
    return new CObjectBool(CObject::Bool(true));
  }
  return CreateIllegalArgumentError();
}

CObject* Directory::RenameRequest(const CObjectArray& request) {
  if ((request.Length() == 2) && request[0]->IsString() &&
      request[1]->IsString()) {
    CObjectString path(request[0]);
    CObjectString new_path(request[1]);
    bool completed = Directory::Rename(path.CString(), new_path.CString());
    if (completed) {
      return CObject::True();
    }
    return CObject::NewOSError();
  }
  return CObject::IllegalArgumentError();
}

bool AsyncDirectoryListing::AddFileSystemEntityToResponse(Response type,
                                                          const char* arg) {
  array_->SetAt(index_++, new CObjectInt32(CObject::NewInt32(type)));
  if (arg != NULL) {
    array_->SetAt(index_++, new CObjectString(CObject::NewString(arg)));
  } else {
    array_->SetAt(index_++, CObject::Null());
  }
  return index_ < length_;
}

bool AsyncDirectoryListing::HandleDirectory(const char* dir_name) {
  return AddFileSystemEntityToResponse(kListDirectory, dir_name);
}

bool AsyncDirectoryListing::HandleFile(const char* file_name) {
  return AddFileSystemEntityToResponse(kListFile, file_name);
}

bool AsyncDirectoryListing::HandleLink(const char* link_name) {
  return AddFileSystemEntityToResponse(kListLink, link_name);
}

void AsyncDirectoryListing::HandleDone() {
  AddFileSystemEntityToResponse(kListDone, NULL);
}

bool AsyncDirectoryListing::HandleError() {
  CObject* err = CObject::NewOSError();
  array_->SetAt(index_++, new CObjectInt32(CObject::NewInt32(kListError)));
  CObjectArray* response = new CObjectArray(CObject::NewArray(3));
  response->SetAt(0, new CObjectInt32(CObject::NewInt32(kListError)));
  // Delay calling CurrentPath() until after CObject::NewOSError() in case
  // CurrentPath() pollutes the OS error code.
  response->SetAt(1, new CObjectString(CObject::NewString(
                         error() ? "Invalid path" : CurrentPath())));
  response->SetAt(2, err);
  array_->SetAt(index_++, response);
  return index_ < length_;
}

bool SyncDirectoryListing::HandleDirectory(const char* dir_name) {
  Dart_Handle dir_name_dart = DartUtils::NewString(dir_name);
  Dart_Handle dir = Dart_New(directory_type_, Dart_Null(), 1, &dir_name_dart);
  Dart_Handle result = Dart_Invoke(results_, add_string_, 1, &dir);
  if (Dart_IsError(result)) {
    dart_error_ = result;
    return false;
  }
  return true;
}

bool SyncDirectoryListing::HandleLink(const char* link_name) {
  Dart_Handle link_name_dart = DartUtils::NewString(link_name);
  Dart_Handle link = Dart_New(link_type_, Dart_Null(), 1, &link_name_dart);
  Dart_Handle result = Dart_Invoke(results_, add_string_, 1, &link);
  if (Dart_IsError(result)) {
    dart_error_ = result;
    return false;
  }
  return true;
}

bool SyncDirectoryListing::HandleFile(const char* file_name) {
  Dart_Handle file_name_dart = DartUtils::NewString(file_name);
  Dart_Handle file = Dart_New(file_type_, Dart_Null(), 1, &file_name_dart);
  Dart_Handle result = Dart_Invoke(results_, add_string_, 1, &file);
  if (Dart_IsError(result)) {
    dart_error_ = result;
    return false;
  }
  return true;
}

bool SyncDirectoryListing::HandleError() {
  Dart_Handle dart_os_error = DartUtils::NewDartOSError();
  Dart_Handle args[3];
  args[0] = DartUtils::NewString("Directory listing failed");
  args[1] = DartUtils::NewString(error() ? "Invalid path" : CurrentPath());
  args[2] = dart_os_error;

  dart_error_ = Dart_New(
      DartUtils::GetDartType(DartUtils::kIOLibURL, "FileSystemException"),
      Dart_Null(), 3, args);
  return false;
}

static bool ListNext(DirectoryListing* listing) {
  switch (listing->top()->Next(listing)) {
    case kListFile:
      return listing->HandleFile(listing->CurrentPath());

    case kListLink:
      return listing->HandleLink(listing->CurrentPath());

    case kListDirectory:
      if (listing->recursive()) {
        listing->Push(new DirectoryListingEntry(listing->top()));
      }
      return listing->HandleDirectory(listing->CurrentPath());

    case kListError:
      return listing->HandleError();

    case kListDone:
      listing->Pop();
      if (listing->IsEmpty()) {
        listing->HandleDone();
        return false;
      } else {
        return true;
      }

    default:
      UNREACHABLE();
  }
  return false;
}

void Directory::List(DirectoryListing* listing) {
  if (listing->error()) {
    listing->HandleError();
    listing->HandleDone();
  } else {
    while (ListNext(listing)) {
    }
  }
}

}  // namespace bin
}  // namespace dart
