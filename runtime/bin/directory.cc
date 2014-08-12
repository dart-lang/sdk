// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/directory.h"

#include "bin/dartutils.h"
#include "include/dart_api.h"
#include "platform/assert.h"


namespace dart {
namespace bin {

void FUNCTION_NAME(Directory_Current)(Dart_NativeArguments args) {
  char* current = Directory::Current();
  if (current != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(current));
    free(current);
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Directory_SetCurrent)(Dart_NativeArguments args) {
  int argc = Dart_GetNativeArgumentCount(args);
  Dart_Handle path;
  if (argc == 1) {
    path = Dart_GetNativeArgument(args, 0);
  }
  if (argc != 1 || !Dart_IsString(path)) {
    Dart_SetReturnValue(args, DartUtils::NewDartArgumentError(NULL));
  } else {
    if (Directory::SetCurrent(DartUtils::GetStringValue(path))) {
      Dart_SetReturnValue(args, Dart_True());
    } else {
      Dart_Handle err = DartUtils::NewDartOSError();
      if (Dart_IsError(err)) Dart_PropagateError(err);
      Dart_SetReturnValue(args, err);
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
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Directory_Create)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  if (Directory::Create(DartUtils::GetStringValue(path))) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Directory_SystemTemp)(
    Dart_NativeArguments args) {
  char* result = Directory::SystemTemp();
  Dart_SetReturnValue(args, DartUtils::NewString(result));
  free(result);
}


void FUNCTION_NAME(Directory_CreateTemp)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  if (!Dart_IsString(path)) {
    Dart_SetReturnValue(args, DartUtils::NewDartArgumentError(
        "Prefix argument of CreateSystemTempSync is not a String"));
    return;
  }
  char* result = Directory::CreateTemp(DartUtils::GetStringValue(path));
  if (result != NULL) {
    Dart_SetReturnValue(args, DartUtils::NewString(result));
    free(result);
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Directory_Delete)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  Dart_Handle recursive = Dart_GetNativeArgument(args, 1);
  if (Directory::Delete(DartUtils::GetStringValue(path),
                        DartUtils::GetBooleanValue(recursive))) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Directory_Rename)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  Dart_Handle newPath = Dart_GetNativeArgument(args, 1);
  if (Directory::Rename(DartUtils::GetStringValue(path),
                        DartUtils::GetStringValue(newPath))) {
    Dart_SetReturnValue(args, Dart_True());
  } else {
    Dart_Handle err = DartUtils::NewDartOSError();
    if (Dart_IsError(err)) Dart_PropagateError(err);
    Dart_SetReturnValue(args, err);
  }
}


void FUNCTION_NAME(Directory_List)(Dart_NativeArguments args) {
  Dart_Handle path = Dart_GetNativeArgument(args, 0);
  Dart_Handle recursive = Dart_GetNativeArgument(args, 1);
  // Create the list to hold the directory listing here, and pass it to the
  // SyncDirectoryListing object, which adds elements to it.
  Dart_Handle follow_links = Dart_GetNativeArgument(args, 2);
  // Create the list to hold the directory listing here, and pass it to the
  // SyncDirectoryListing object, which adds elements to it.
  Dart_Handle results =
      Dart_New(DartUtils::GetDartType(DartUtils::kCoreLibURL, "List"),
               Dart_Null(),
               0,
               NULL);
  SyncDirectoryListing sync_listing(results,
                                    DartUtils::GetStringValue(path),
                                    DartUtils::GetBooleanValue(recursive),
                                    DartUtils::GetBooleanValue(follow_links));
  Directory::List(&sync_listing);
  Dart_SetReturnValue(args, results);
}


CObject* Directory::CreateRequest(const CObjectArray& request) {
  if (request.Length() == 1 && request[0]->IsString()) {
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
  if (request.Length() == 2 && request[0]->IsString() && request[1]->IsBool()) {
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
  if (request.Length() == 1 && request[0]->IsString()) {
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
  if (request.Length() == 1 && request[0]->IsString()) {
    CObjectString path(request[0]);
    char* result = Directory::CreateTemp(path.CString());
    if (result != NULL) {
      CObject* temp_dir = new CObjectString(CObject::NewString(result));
      free(result);
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
  if (request.Length() == 3 &&
      request[0]->IsString() &&
      request[1]->IsBool() &&
      request[2]->IsBool()) {
    CObjectString path(request[0]);
    CObjectBool recursive(request[1]);
    CObjectBool follow_links(request[2]);
    AsyncDirectoryListing* dir_listing =
        new AsyncDirectoryListing(path.CString(),
                                  recursive.Value(),
                                  follow_links.Value());
    if (dir_listing->error()) {
      // Report error now, so we capture the correct OSError.
      CObject* err = CObject::NewOSError();
      delete dir_listing;
      CObjectArray* error = new CObjectArray(CObject::NewArray(3));
      error->SetAt(0, new CObjectInt32(
          CObject::NewInt32(AsyncDirectoryListing::kListError)));
      error->SetAt(1, request[0]);
      error->SetAt(2, err);
      return error;
    }
    // TODO(ajohnsen): Consider returning the first few results.
    return new CObjectIntptr(CObject::NewIntptr(
        reinterpret_cast<intptr_t>(dir_listing)));
  }
  return CreateIllegalArgumentError();
}


CObject* Directory::ListNextRequest(const CObjectArray& request) {
  if (request.Length() == 1 &&
      request[0]->IsIntptr()) {
    CObjectIntptr ptr(request[0]);
    AsyncDirectoryListing* dir_listing =
        reinterpret_cast<AsyncDirectoryListing*>(ptr.Value());
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
  if (request.Length() == 1 && request[0]->IsIntptr()) {
    CObjectIntptr ptr(request[0]);
    AsyncDirectoryListing* dir_listing =
        reinterpret_cast<AsyncDirectoryListing*>(ptr.Value());
    delete dir_listing;
    return new CObjectBool(CObject::Bool(true));
  }
  return CreateIllegalArgumentError();
}


CObject* Directory::RenameRequest(const CObjectArray& request) {
  if (request.Length() == 2 &&
      request[0]->IsString() &&
      request[1]->IsString()) {
    CObjectString path(request[0]);
    CObjectString new_path(request[1]);
    bool completed = Directory::Rename(path.CString(), new_path.CString());
    if (completed) return CObject::True();
    return CObject::NewOSError();
  }
  return CObject::IllegalArgumentError();
}


bool AsyncDirectoryListing::AddFileSystemEntityToResponse(Response type,
                                                          char* arg) {
  array_->SetAt(index_++, new CObjectInt32(CObject::NewInt32(type)));
  if (arg != NULL) {
    array_->SetAt(index_++, new CObjectString(CObject::NewString(arg)));
  } else {
    array_->SetAt(index_++, CObject::Null());
  }
  return index_ < length_;
}


bool AsyncDirectoryListing::HandleDirectory(char* dir_name) {
  return AddFileSystemEntityToResponse(kListDirectory, dir_name);
}


bool AsyncDirectoryListing::HandleFile(char* file_name) {
  return AddFileSystemEntityToResponse(kListFile, file_name);
}


bool AsyncDirectoryListing::HandleLink(char* link_name) {
  return AddFileSystemEntityToResponse(kListLink, link_name);
}

void AsyncDirectoryListing::HandleDone() {
  AddFileSystemEntityToResponse(kListDone, NULL);
}


bool AsyncDirectoryListing::HandleError(const char* dir_name) {
  CObject* err = CObject::NewOSError();
  array_->SetAt(index_++, new CObjectInt32(CObject::NewInt32(kListError)));
  CObjectArray* response = new CObjectArray(CObject::NewArray(3));
  response->SetAt(0, new CObjectInt32(CObject::NewInt32(kListError)));
  response->SetAt(1, new CObjectString(CObject::NewString(dir_name)));
  response->SetAt(2, err);
  array_->SetAt(index_++, response);
  return index_ < length_;
}

bool SyncDirectoryListing::HandleDirectory(char* dir_name) {
  Dart_Handle dir_name_dart = DartUtils::NewString(dir_name);
  Dart_Handle dir =
      Dart_New(directory_type_, Dart_Null(), 1, &dir_name_dart);
  Dart_Invoke(results_, add_string_, 1, &dir);
  return true;
}

bool SyncDirectoryListing::HandleLink(char* link_name) {
  Dart_Handle link_name_dart = DartUtils::NewString(link_name);
  Dart_Handle link =
      Dart_New(link_type_, Dart_Null(), 1, &link_name_dart);
  Dart_Invoke(results_, add_string_, 1, &link);
  return true;
}

bool SyncDirectoryListing::HandleFile(char* file_name) {
  Dart_Handle file_name_dart = DartUtils::NewString(file_name);
  Dart_Handle file =
      Dart_New(file_type_, Dart_Null(), 1, &file_name_dart);
  Dart_Invoke(results_, add_string_, 1, &file);
  return true;
}

bool SyncDirectoryListing::HandleError(const char* dir_name) {
  Dart_Handle dart_os_error = DartUtils::NewDartOSError();
  Dart_Handle args[3];
  args[0] = DartUtils::NewString("Directory listing failed");
  args[1] = DartUtils::NewString(dir_name);
  args[2] = dart_os_error;
  Dart_ThrowException(Dart_New(
      DartUtils::GetDartType(DartUtils::kIOLibURL, "FileSystemException"),
      Dart_Null(),
      3,
      args));
  return true;
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
      return listing->HandleError(listing->CurrentPath());

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
    listing->HandleError("Invalid path");
    listing->HandleDone();
  } else {
    while (ListNext(listing)) {}
  }
}

}  // namespace bin
}  // namespace dart
