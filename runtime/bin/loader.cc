// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


#include "bin/loader.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/extensions.h"
#include "bin/lockers.h"
#include "bin/utils.h"

namespace dart {
namespace bin {

// Development flag.
static bool trace_loader = false;

Loader::Loader(IsolateData* isolate_data)
    : port_(ILLEGAL_PORT),
      isolate_data_(isolate_data),
      error_(Dart_Null()),
      monitor_(NULL),
      pending_operations_(0),
      results_(NULL),
      results_length_(0),
      results_capacity_(0) {
  monitor_ = new Monitor();
  ASSERT(isolate_data_ != NULL);
  port_ = Dart_NewNativePort("Loader",
                             Loader::NativeMessageHandler,
                             false);
  isolate_data_->set_loader(this);
  AddLoader(port_, isolate_data_);
}


Loader::~Loader() {
  ASSERT(port_ != ILLEGAL_PORT);
  // Enter the monitor while we close the Dart port. After the Dart port is
  // closed, no more results can be queued.
  monitor_->Enter();
  Dart_CloseNativePort(port_);
  monitor_->Exit();
  RemoveLoader(port_);
  port_ = ILLEGAL_PORT;
  isolate_data_->set_loader(NULL);
  isolate_data_ = NULL;
  delete monitor_;
  monitor_ = NULL;
  for (intptr_t i = 0; i < results_length_; i++) {
    results_[i].Cleanup();
  }
  free(results_);
  results_ = NULL;
}


// Copy the contents of |message| into an |IOResult|.
void Loader::IOResult::Setup(Dart_CObject* message) {
  ASSERT(message->type == Dart_CObject_kArray);
  ASSERT(message->value.as_array.length == 4);
  Dart_CObject* tag_message = message->value.as_array.values[0];
  ASSERT(tag_message != NULL);
  Dart_CObject* uri_message = message->value.as_array.values[1];
  ASSERT(uri_message != NULL);
  Dart_CObject* library_uri_message = message->value.as_array.values[2];
  ASSERT(library_uri_message != NULL);
  Dart_CObject* payload_message = message->value.as_array.values[3];
  ASSERT(payload_message != NULL);

  // Grab the tag.
  ASSERT(tag_message->type == Dart_CObject_kInt32);
  tag = tag_message->value.as_int32;

  // Grab the uri id.
  ASSERT(uri_message->type == Dart_CObject_kString);
  uri = strdup(uri_message->value.as_string);

  // Grab the library uri if one is present.
  if (library_uri_message->type != Dart_CObject_kNull) {
    ASSERT(library_uri_message->type == Dart_CObject_kString);
    library_uri = strdup(library_uri_message->value.as_string);
  } else {
    library_uri = NULL;
  }

  // Grab the payload.
  if (payload_message->type == Dart_CObject_kString) {
    // Payload is an error message.
    payload_length = strlen(payload_message->value.as_string);
    payload =
        reinterpret_cast<uint8_t*>(strdup(payload_message->value.as_string));
  } else {
    // Payload is the contents of a file.
    ASSERT(payload_message->type == Dart_CObject_kTypedData);
    ASSERT(payload_message->value.as_typed_data.type == Dart_TypedData_kUint8);
    payload_length = payload_message->value.as_typed_data.length;
    payload = reinterpret_cast<uint8_t*>(malloc(payload_length));
    memmove(payload,
            payload_message->value.as_typed_data.values,
            payload_length);
  }
}


void Loader::IOResult::Cleanup() {
  free(uri);
  free(library_uri);
  free(payload);
}


// Send the Loader Initialization message to the service isolate. This
// message is sent the first time a loader is constructed for an isolate and
// seeds the service isolate with some initial state about this isolate.
void Loader::Init(const char* package_root,
                  const char* packages_file,
                  const char* working_directory,
                  const char* root_script_uri) {
  // This port delivers loading messages to the service isolate.
  Dart_Port loader_port = Builtin::LoadPort();
  ASSERT(loader_port != ILLEGAL_PORT);

  // Keep in sync with loader.dart.
  const intptr_t _Dart_kInitLoader = 4;

  Dart_Handle request = Dart_NewList(8);
  Dart_ListSetAt(request, 0, trace_loader ? Dart_True() : Dart_False());
  Dart_ListSetAt(request, 1, Dart_NewInteger(Dart_GetMainPortId()));
  Dart_ListSetAt(request, 2, Dart_NewInteger(_Dart_kInitLoader));
  Dart_ListSetAt(request, 3, Dart_NewSendPort(port_));
  Dart_ListSetAt(request, 4,
                 (package_root == NULL) ? Dart_Null() :
                      Dart_NewStringFromCString(package_root));
  Dart_ListSetAt(request, 5,
                 (packages_file == NULL) ? Dart_Null() :
                      Dart_NewStringFromCString(packages_file));
  Dart_ListSetAt(request, 6,
                      Dart_NewStringFromCString(working_directory));
  Dart_ListSetAt(request, 7,
                 (root_script_uri == NULL) ? Dart_Null() :
                      Dart_NewStringFromCString(root_script_uri));

  bool success = Dart_Post(loader_port, request);
  ASSERT(success);
}


// Forward a request from the tag handler to the service isolate.
void Loader::SendRequest(Dart_LibraryTag tag,
                         Dart_Handle url,
                         Dart_Handle library_url) {
  // This port delivers loading messages to the service isolate.
  Dart_Port loader_port = Builtin::LoadPort();
  ASSERT(loader_port != ILLEGAL_PORT);

  Dart_Handle request = Dart_NewList(6);
  Dart_ListSetAt(request, 0, trace_loader ? Dart_True() : Dart_False());
  Dart_ListSetAt(request, 1, Dart_NewInteger(Dart_GetMainPortId()));
  Dart_ListSetAt(request, 2, Dart_NewInteger(tag));
  Dart_ListSetAt(request, 3, Dart_NewSendPort(port_));

  Dart_ListSetAt(request, 4, url);
  Dart_ListSetAt(request, 5, library_url);

  if (Dart_Post(loader_port, request)) {
    MonitorLocker ml(monitor_);
    pending_operations_++;
  }
}


void Loader::QueueMessage(Dart_CObject* message) {
  MonitorLocker ml(monitor_);
  if (results_length_ == results_capacity_) {
    // Grow to an initial capacity or double in size.
    results_capacity_ = (results_capacity_ == 0) ? 4 : results_capacity_ * 2;
    results_ =
        reinterpret_cast<IOResult*>(
            realloc(results_,
                    sizeof(IOResult) * results_capacity_));
    ASSERT(results_ != NULL);
  }
  ASSERT(results_ != NULL);
  ASSERT(results_length_ < results_capacity_);
  results_[results_length_].Setup(message);
  results_length_++;
  ml.Notify();
}


void Loader::BlockUntilComplete() {
  MonitorLocker ml(monitor_);

  while (true) {
    // If |ProcessQueueLocked| returns false, we've hit an error and should
    // stop loading.
    if (!ProcessQueueLocked()) {
      break;
    }

    // When |pending_operations_| hits 0, we are done loading.
    if (pending_operations_ == 0) {
      break;
    }

    // Wait to be notified about new I/O results.
    ml.Wait();
  }
}


bool Loader::ProcessResultLocked(Loader::IOResult* result) {
  // A negative result tag indicates a loading error occurred in the service
  // isolate. The payload is a C string of the error message.
  if (result->tag < 0) {
    error_ =
        Dart_NewUnhandledExceptionError(
            Dart_NewStringFromUTF8(result->payload,
                                   result->payload_length));

    return false;
  }

  // We have to copy everything we care about out of |result| because after
  // dropping the lock below |result| may no longer valid.
  Dart_Handle uri =
      Dart_NewStringFromCString(reinterpret_cast<char*>(result->uri));
  Dart_Handle library_uri = Dart_Null();
  if (result->library_uri != NULL) {
    library_uri =
        Dart_NewStringFromCString(reinterpret_cast<char*>(result->library_uri));
  }
  // Check for payload and load accordingly.
  bool is_snapshot = false;
  const uint8_t* payload = result->payload;
  intptr_t payload_length = result->payload_length;
  payload =
      DartUtils::SniffForMagicNumber(payload,
                                     &payload_length,
                                     &is_snapshot);
  Dart_Handle source = Dart_Null();
  if (!is_snapshot) {
    source = Dart_NewStringFromUTF8(result->payload,
                                    result->payload_length);
    if (Dart_IsError(source)) {
      error_  = DartUtils::NewError("%s is not a valid UTF-8 script",
                                    reinterpret_cast<char*>(result->uri));
      return false;
    }
  }
  intptr_t tag = result->tag;

  // No touching.
  result = NULL;

  // We must drop the lock here because the tag handler may be recursively
  // invoked and it will attempt to acquire the lock to queue more work.
  monitor_->Exit();

  Dart_Handle dart_result = Dart_Null();

  switch (tag) {
    case Dart_kImportTag:
      dart_result = Dart_LoadLibrary(uri, source, 0, 0);
    break;
    case Dart_kSourceTag: {
      ASSERT(library_uri != Dart_Null());
      Dart_Handle library = Dart_LookupLibrary(library_uri);
      ASSERT(!Dart_IsError(library));
      dart_result = Dart_LoadSource(library, uri, source, 0, 0);
    }
    break;
    case Dart_kScriptTag:
      if (is_snapshot) {
        dart_result = Dart_LoadScriptFromSnapshot(payload, payload_length);
      } else {
        dart_result = Dart_LoadScript(uri, source, 0, 0);
      }
    break;
    default:
      UNREACHABLE();
  }

  // Re-acquire the lock before exiting the function (it was held before entry),
  monitor_->Enter();
  if (Dart_IsError(dart_result)) {
    // Remember the error if we encountered one.
    error_ = dart_result;
    return false;
  }

  return true;
}


bool Loader::ProcessQueueLocked() {
  bool hit_error = false;
  for (intptr_t i = 0; i < results_length(); i++) {
    if (!hit_error) {
      hit_error = !ProcessResultLocked(&results_[i]);
    }
    pending_operations_--;
    ASSERT(hit_error || (pending_operations_ >= 0));
    results_[i].Cleanup();
  }
  results_length_ = 0;
  return !hit_error;
}


static bool IsWindowsHost() {
#if defined(TARGET_OS_WINDOWS)
  return true;
#else  // defined(TARGET_OS_WINDOWS)
  return false;
#endif  // defined(TARGET_OS_WINDOWS)
}


void Loader::InitForSnapshot(const char* snapshot_uri) {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);
  ASSERT(!isolate_data->HasLoader());
  // Setup a loader. The constructor does a bunch of leg work.
  Loader* loader = new Loader(isolate_data);
  // Send the init message.
  loader->Init(isolate_data->package_root,
               isolate_data->packages_file,
               DartUtils::original_working_directory,
               snapshot_uri);
  // Destroy the loader. The destructor does a bunch of leg work.
  delete loader;
}


Dart_Handle Loader::LibraryTagHandler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    return Dart_DefaultCanonicalizeUrl(library, url);
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }

  // Special case for handling dart: imports and parts.
  if (tag != Dart_kScriptTag) {
    // Grab the library's url.
    Dart_Handle library_url = Dart_LibraryUrl(library);
    const char* library_url_string = NULL;
    result = Dart_StringToCString(library_url, &library_url_string);
    if (Dart_IsError(result)) {
      return result;
    }

    bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
    bool is_dart_library = DartUtils::IsDartSchemeURL(library_url_string);

    if (is_dart_scheme_url || is_dart_library) {
      return DartColonLibraryTagHandler(tag,
                                        library,
                                        url,
                                        library_url_string,
                                        url_string);
    }
  }

  if (DartUtils::IsDartExtensionSchemeURL(url_string)) {
    // Load a native code shared library to use in a native extension
    if (tag != Dart_kImportTag) {
      return DartUtils::NewError("Dart extensions must use import: '%s'",
                                 url_string);
    }
    Dart_Handle library_url = Dart_LibraryUrl(library);
    Dart_Handle library_file_path = DartUtils::LibraryFilePath(library_url);
    const char* lib_path_str = NULL;
    Dart_StringToCString(library_file_path, &lib_path_str);
    const char* extension_path = DartUtils::RemoveScheme(url_string);
    if (strchr(extension_path, '/') != NULL ||
        (IsWindowsHost() && strchr(extension_path, '\\') != NULL)) {
      return DartUtils::NewError(
          "Relative paths for dart extensions are not supported: '%s'",
          extension_path);
    }
    return Extensions::LoadExtension(lib_path_str,
                                     extension_path,
                                     library);
  }

  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);

  // Grab this isolate's loader.
  Loader* loader = NULL;

  // The outer invocation of the tag handler for this isolate. We make the outer
  // invocation block and allow any nested invocations to operate in parallel.
  bool blocking_call = !isolate_data->HasLoader();

  if (!isolate_data->HasLoader()) {
    // The isolate doesn't have a loader -- this is the outer invocation which
    // will block.

    // Setup the loader. The constructor does a bunch of leg work.
    loader = new Loader(isolate_data);
    loader->Init(isolate_data->package_root,
                 isolate_data->packages_file,
                 DartUtils::original_working_directory,
                 (tag == Dart_kScriptTag) ? url_string : NULL);
  } else {
    ASSERT(tag != Dart_kScriptTag);
    // The isolate has a loader -- this is an inner invocation that will queue
    // work with the service isolate.
    // Use the existing loader.
    loader = isolate_data->loader();
  }
  ASSERT(loader != NULL);
  ASSERT(isolate_data->HasLoader());

  loader->SendRequest(tag,
                      url,
                      (library != Dart_Null()) ?
                          Dart_LibraryUrl(library) : Dart_Null());

  if (blocking_call) {
    // The outer invocation of the tag handler will block here until all nested
    // invocations complete.
    loader->BlockUntilComplete();

    // Remember the error (if any).
    Dart_Handle error = loader->error();
    // Destroy the loader. The destructor does a bunch of leg work.
    delete loader;

    // An error occurred during loading.
    if (Dart_IsError(error)) {
      return error;
    }

    // Finalize loading. This will complete any futures for completed deferred
    // loads.
    error = Dart_FinalizeLoading(true);
    if (Dart_IsError(error)) {
      return error;
    }
  }
  return Dart_Null();
}


Dart_Handle Loader::DartColonLibraryTagHandler(Dart_LibraryTag tag,
                                               Dart_Handle library,
                                               Dart_Handle url,
                                               const char* library_url_string,
                                               const char* url_string) {
  // Handle canonicalization, 'import' and 'part' of 'dart:' libraries.
  if (tag == Dart_kCanonicalizeUrl) {
    // These will be handled internally.
    return url;
  } else if (tag == Dart_kImportTag) {
    Builtin::BuiltinLibraryId id = Builtin::FindId(url_string);
    if (id == Builtin::kInvalidLibrary) {
      return DartUtils::NewError("The built-in library '%s' is not available"
                                 " on the stand-alone VM.\n", url_string);
    }
    return Builtin::LoadLibrary(url, id);
  } else {
    ASSERT(tag == Dart_kSourceTag);
    Builtin::BuiltinLibraryId id = Builtin::FindId(library_url_string);
    if (id == Builtin::kInvalidLibrary) {
      return DartUtils::NewError("The built-in library '%s' is not available"
                                 " on the stand-alone VM. Trying to load"
                                 " '%s'.\n", library_url_string, url_string);
    }
    // Prepend the library URI to form a unique script URI for the part.
    intptr_t len = snprintf(NULL, 0, "%s/%s", library_url_string, url_string);
    char* part_uri = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(part_uri, len + 1, "%s/%s", library_url_string, url_string);
    Dart_Handle part_uri_obj = DartUtils::NewString(part_uri);
    free(part_uri);
    return Dart_LoadSource(library,
                           part_uri_obj,
                           Builtin::PartSource(id, url_string), 0, 0);
  }
  // All cases should have been handled above.
  UNREACHABLE();
}


Mutex Loader::loader_infos_lock_;
Loader::LoaderInfo* Loader::loader_infos_ = NULL;
intptr_t Loader::loader_infos_length_ = 0;
intptr_t Loader::loader_infos_capacity_ = 0;


// Add a mapping from |port| to |isolate_data| (really the loader). When a
// native message arrives, we use this map to report the I/O result to the
// correct loader.
// This happens whenever an isolate begins loading.
void Loader::AddLoader(Dart_Port port, IsolateData* isolate_data) {
  MutexLocker ml(&loader_infos_lock_);
  ASSERT(LoaderForLocked(port) == NULL);
  if (loader_infos_length_ == loader_infos_capacity_) {
    // Grow to an initial capacity or double in size.
    loader_infos_capacity_ =
        (loader_infos_capacity_ == 0) ? 4 : loader_infos_capacity_ * 2;
    loader_infos_ =
        reinterpret_cast<Loader::LoaderInfo*>(
            realloc(loader_infos_,
                    sizeof(Loader::LoaderInfo) * loader_infos_capacity_));
    ASSERT(loader_infos_ != NULL);
    // Initialize new entries.
    for (intptr_t i = loader_infos_length_; i < loader_infos_capacity_; i++) {
      loader_infos_[i].port = ILLEGAL_PORT;
      loader_infos_[i].isolate_data = NULL;
    }
  }
  ASSERT(loader_infos_length_ < loader_infos_capacity_);
  loader_infos_[loader_infos_length_].port = port;
  loader_infos_[loader_infos_length_].isolate_data = isolate_data;
  loader_infos_length_++;
  ASSERT(LoaderForLocked(port) != NULL);
}


// Remove |port| from the map.
// This happens once an isolate has finished loading.
void Loader::RemoveLoader(Dart_Port port) {
  MutexLocker ml(&loader_infos_lock_);
  const intptr_t index = LoaderIndexFor(port);
  ASSERT(index >= 0);
  const intptr_t last = loader_infos_length_ - 1;
  ASSERT(last >= 0);
  if (index != last) {
    // Swap with the tail.
    loader_infos_[index] = loader_infos_[last];
  }
  loader_infos_length_--;
}


intptr_t Loader::LoaderIndexFor(Dart_Port port) {
  for (intptr_t i = 0; i < loader_infos_length_; i++) {
    if (loader_infos_[i].port == port) {
      return i;
    }
  }
  return -1;
}


Loader* Loader::LoaderForLocked(Dart_Port port) {
  intptr_t index = LoaderIndexFor(port);
  if (index < 0) {
    return NULL;
  }
  return loader_infos_[index].isolate_data->loader();
}


Loader* Loader::LoaderFor(Dart_Port port) {
  MutexLocker ml(&loader_infos_lock_);
  return LoaderForLocked(port);
}


void Loader::NativeMessageHandler(Dart_Port dest_port_id,
                                  Dart_CObject* message) {
  MutexLocker ml(&loader_infos_lock_);
  Loader* loader = LoaderForLocked(dest_port_id);
  if (loader == NULL) {
    return;
  }
  loader->QueueMessage(message);
}

}  // namespace bin
}  // namespace dart
