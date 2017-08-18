// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/loader.h"

#include "bin/builtin.h"
#include "bin/dartutils.h"
#include "bin/dfe.h"
#include "bin/extensions.h"
#include "bin/file.h"
#include "bin/gzip.h"
#include "bin/lockers.h"
#include "bin/utils.h"
#include "include/dart_tools_api.h"
#include "platform/growable_array.h"

namespace dart {
namespace bin {

// Development flag.
static bool trace_loader = false;
#if !defined(DART_PRECOMPILED_RUNTIME)
extern DFE dfe;
#endif

// Keep in sync with loader.dart.
static const intptr_t _Dart_kImportExtension = 9;
static const intptr_t _Dart_kResolveAsFilePath = 10;

Loader::Loader(IsolateData* isolate_data)
    : port_(ILLEGAL_PORT),
      isolate_data_(isolate_data),
      error_(Dart_Null()),
      monitor_(NULL),
      pending_operations_(0),
      results_(NULL),
      results_length_(0),
      results_capacity_(0),
      payload_(NULL),
      payload_length_(0) {
  monitor_ = new Monitor();
  ASSERT(isolate_data_ != NULL);
  port_ = Dart_NewNativePort("Loader", Loader::NativeMessageHandler, false);
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
  payload_ = NULL;
  payload_length_ = 0;
}

// Copy the contents of |message| into an |IOResult|.
void Loader::IOResult::Setup(Dart_CObject* message) {
  ASSERT(message->type == Dart_CObject_kArray);
  ASSERT(message->value.as_array.length == 5);
  Dart_CObject* tag_message = message->value.as_array.values[0];
  ASSERT(tag_message != NULL);
  Dart_CObject* uri_message = message->value.as_array.values[1];
  ASSERT(uri_message != NULL);
  Dart_CObject* resolved_uri_message = message->value.as_array.values[2];
  ASSERT(resolved_uri_message != NULL);
  Dart_CObject* library_uri_message = message->value.as_array.values[3];
  ASSERT(library_uri_message != NULL);
  Dart_CObject* payload_message = message->value.as_array.values[4];
  ASSERT(payload_message != NULL);

  // Grab the tag.
  ASSERT(tag_message->type == Dart_CObject_kInt32);
  tag = tag_message->value.as_int32;

  // Grab the uri id.
  ASSERT(uri_message->type == Dart_CObject_kString);
  uri = strdup(uri_message->value.as_string);

  // Grab the resolved uri.
  ASSERT(resolved_uri_message->type == Dart_CObject_kString);
  resolved_uri = strdup(resolved_uri_message->value.as_string);

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
    memmove(payload, payload_message->value.as_typed_data.values,
            payload_length);
  }
}

void Loader::IOResult::Cleanup() {
  free(uri);
  free(resolved_uri);
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

  Dart_Handle request = Dart_NewList(9);
  Dart_ListSetAt(request, 0, trace_loader ? Dart_True() : Dart_False());
  Dart_ListSetAt(request, 1, Dart_NewInteger(Dart_GetMainPortId()));
  Dart_ListSetAt(request, 2, Dart_NewInteger(_Dart_kInitLoader));
  Dart_ListSetAt(request, 3, Dart_NewSendPort(port_));
  Dart_ListSetAt(request, 4,
                 (package_root == NULL)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(package_root));
  Dart_ListSetAt(request, 5,
                 (packages_file == NULL)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(packages_file));
  Dart_ListSetAt(request, 6, Dart_NewStringFromCString(working_directory));
  Dart_ListSetAt(request, 7,
                 (root_script_uri == NULL)
                     ? Dart_Null()
                     : Dart_NewStringFromCString(root_script_uri));
  Dart_ListSetAt(request, 8, Dart_NewBoolean(Dart_IsReloading()));

  bool success = Dart_Post(loader_port, request);
  ASSERT(success);
}

void Loader::SendImportExtensionRequest(Dart_Handle url,
                                        Dart_Handle library_url) {
  // This port delivers loading messages to the service isolate.
  Dart_Port loader_port = Builtin::LoadPort();
  ASSERT(loader_port != ILLEGAL_PORT);

  Dart_Handle request = Dart_NewList(6);
  Dart_ListSetAt(request, 0, trace_loader ? Dart_True() : Dart_False());
  Dart_ListSetAt(request, 1, Dart_NewInteger(Dart_GetMainPortId()));
  Dart_ListSetAt(request, 2, Dart_NewInteger(_Dart_kImportExtension));
  Dart_ListSetAt(request, 3, Dart_NewSendPort(port_));

  Dart_ListSetAt(request, 4, url);
  Dart_ListSetAt(request, 5, library_url);

  if (Dart_Post(loader_port, request)) {
    MonitorLocker ml(monitor_);
    pending_operations_++;
  }
}

// Forward a request from the tag handler to the service isolate.
void Loader::SendRequest(intptr_t tag,
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

// Forward a request from the tag handler to the kernel isolate.
// [ tag, send port, url ]
void Loader::SendKernelRequest(Dart_LibraryTag tag, Dart_Handle url) {
  // This port delivers loading messages to the Kernel isolate.
  Dart_Port kernel_port = Dart_KernelPort();
  ASSERT(kernel_port != ILLEGAL_PORT);

  Dart_Handle request = Dart_NewList(3);
  Dart_ListSetAt(request, 0, Dart_NewInteger(tag));
  Dart_ListSetAt(request, 1, Dart_NewSendPort(port_));
  Dart_ListSetAt(request, 2, url);
  if (Dart_Post(kernel_port, request)) {
    MonitorLocker ml(monitor_);
    pending_operations_++;
  }
}

void Loader::QueueMessage(Dart_CObject* message) {
  MonitorLocker ml(monitor_);
  if (results_length_ == results_capacity_) {
    // Grow to an initial capacity or double in size.
    results_capacity_ = (results_capacity_ == 0) ? 4 : results_capacity_ * 2;
    results_ = reinterpret_cast<IOResult*>(
        realloc(results_, sizeof(IOResult) * results_capacity_));
    ASSERT(results_ != NULL);
  }
  ASSERT(results_ != NULL);
  ASSERT(results_length_ < results_capacity_);
  results_[results_length_].Setup(message);
  results_length_++;
  ml.Notify();
}

void Loader::BlockUntilComplete(ProcessResult process_result) {
  MonitorLocker ml(monitor_);

  while (true) {
    // If |ProcessQueueLocked| returns false, we've hit an error and should
    // stop loading.
    if (!ProcessQueueLocked(process_result)) {
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

static bool LibraryHandleError(Dart_Handle library, Dart_Handle error) {
  if (!Dart_IsNull(library) && !Dart_IsError(library)) {
    ASSERT(Dart_IsLibrary(library));
    Dart_Handle res = Dart_LibraryHandleError(library, error);
    if (Dart_IsNull(res)) {
      // Error was handled by library.
      return true;
    }
  }
  return false;
}

static bool PathContainsSeparator(const char* path) {
  return (strchr(path, '/') != NULL) ||
         ((strncmp(File::PathSeparator(), "/", 1) != 0) &&
          (strstr(path, File::PathSeparator()) != NULL));
}

void Loader::AddDependencyLocked(Loader* loader, const char* resolved_uri) {
  MallocGrowableArray<char*>* dependencies =
      loader->isolate_data_->dependencies();
  if (dependencies == NULL) {
    return;
  }
  dependencies->Add(strdup(resolved_uri));
}

void Loader::ResolveDependenciesAsFilePaths() {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);
  MallocGrowableArray<char*>* dependencies = isolate_data->dependencies();
  if (dependencies == NULL) {
    return;
  }

  for (intptr_t i = 0; i < dependencies->length(); i++) {
    char* resolved_uri = (*dependencies)[i];

    uint8_t* scoped_file_path = NULL;
    intptr_t scoped_file_path_length = -1;
    Dart_Handle uri = Dart_NewStringFromCString(resolved_uri);
    ASSERT(!Dart_IsError(uri));
    Dart_Handle result = Loader::ResolveAsFilePath(uri, &scoped_file_path,
                                                   &scoped_file_path_length);
    if (Dart_IsError(result)) {
      Log::Print("Error resolving dependency: %s\n", Dart_GetError(result));
      return;
    }

    (*dependencies)[i] =
        StringUtils::StrNDup(reinterpret_cast<const char*>(scoped_file_path),
                             scoped_file_path_length);
    free(resolved_uri);
  }
}

class ScopedDecompress : public ValueObject {
 public:
  ScopedDecompress(const uint8_t** payload, intptr_t* payload_length)
      : payload_(payload),
        payload_length_(payload_length),
        decompressed_(NULL) {
    DartUtils::MagicNumber payload_type =
        DartUtils::SniffForMagicNumber(*payload, *payload_length);
    if (payload_type == DartUtils::kGzipMagicNumber) {
      int64_t start = Dart_TimelineGetMicros();
      intptr_t decompressed_length = 0;
      Decompress(*payload, *payload_length, &decompressed_,
                 &decompressed_length);
      int64_t end = Dart_TimelineGetMicros();
      Dart_TimelineEvent("Decompress", start, end, Dart_Timeline_Event_Duration,
                         0, NULL, NULL);
      *payload_ = decompressed_;
      *payload_length_ = decompressed_length;
    }
  }

  ~ScopedDecompress() {
    if (decompressed_ != NULL) {
      free(decompressed_);
    }
  }

 private:
  const uint8_t** payload_;
  intptr_t* payload_length_;
  uint8_t* decompressed_;
};

bool Loader::ProcessResultLocked(Loader* loader, Loader::IOResult* result) {
  // We have to copy everything we care about out of |result| because after
  // dropping the lock below |result| may no longer valid.
  Dart_Handle uri =
      Dart_NewStringFromCString(reinterpret_cast<char*>(result->uri));
  Dart_Handle resolved_uri =
      Dart_NewStringFromCString(reinterpret_cast<char*>(result->resolved_uri));
  Dart_Handle library_uri = Dart_Null();
  if (result->library_uri != NULL) {
    library_uri =
        Dart_NewStringFromCString(reinterpret_cast<char*>(result->library_uri));
  }

  AddDependencyLocked(loader, result->resolved_uri);

  // A negative result tag indicates a loading error occurred in the service
  // isolate. The payload is a C string of the error message.
  if (result->tag < 0) {
    Dart_Handle library = Dart_LookupLibrary(uri);
    Dart_Handle error =
        Dart_NewStringFromUTF8(result->payload, result->payload_length);
    // If a library with the given uri exists, give it a chance to handle
    // the error. If the load requests stems from a deferred library load,
    // an IO error is not fatal.
    if (LibraryHandleError(library, error)) {
      return true;
    }
    // Fall through
    loader->error_ = Dart_NewUnhandledExceptionError(error);
    return false;
  }

  if (result->tag == _Dart_kImportExtension) {
    ASSERT(library_uri != Dart_Null());
    Dart_Handle library = Dart_LookupLibrary(library_uri);
    ASSERT(!Dart_IsError(library));
    const char* lib_uri = reinterpret_cast<const char*>(result->payload);
    if (strncmp(lib_uri, "http://", 7) == 0 ||
        strncmp(lib_uri, "https://", 8) == 0) {
      loader->error_ = Dart_NewApiError(
          "Cannot load native extensions over http: or https:");
      return false;
    }
    const char* extension_uri = reinterpret_cast<const char*>(result->uri);
    const char* lib_path = NULL;
    if (strncmp(lib_uri, "file://", 7) == 0) {
      lib_path = DartUtils::RemoveScheme(lib_uri);
    } else {
      lib_path = lib_uri;
    }
    const char* extension_path = DartUtils::RemoveScheme(extension_uri);
    if (!File::IsAbsolutePath(extension_path) &&
        PathContainsSeparator(extension_path)) {
      loader->error_ = DartUtils::NewError(
          "Native extension path must be absolute, or simply the file name: %s",
          extension_path);
      return false;
    }
    Dart_Handle result =
        Extensions::LoadExtension(lib_path, extension_path, library);
    if (Dart_IsError(result)) {
      loader->error_ = result;
      return false;
    }
    return true;
  }

  // Check for payload and load accordingly.
  const uint8_t* payload = result->payload;
  intptr_t payload_length = result->payload_length;

  // Decompress if gzip'd.
  ScopedDecompress decompress(&payload, &payload_length);

  const DartUtils::MagicNumber payload_type =
      DartUtils::SniffForMagicNumber(payload, payload_length);
  Dart_Handle source = Dart_Null();
  if (payload_type == DartUtils::kUnknownMagicNumber) {
    source = Dart_NewStringFromUTF8(payload, payload_length);
    if (Dart_IsError(source)) {
      loader->error_ =
          DartUtils::NewError("%s is not a valid UTF-8 script",
                              reinterpret_cast<char*>(result->uri));
      return false;
    }
  }
  intptr_t tag = result->tag;

  // No touching.
  result = NULL;

  // We must drop the lock here because the tag handler may be recursively
  // invoked and it will attempt to acquire the lock to queue more work.
  loader->monitor_->Exit();

  Dart_Handle dart_result = Dart_Null();
  bool reload_extensions = false;

  switch (tag) {
    case Dart_kImportTag:
      dart_result = Dart_LoadLibrary(uri, resolved_uri, source, 0, 0);
      break;
    case Dart_kSourceTag: {
      ASSERT(library_uri != Dart_Null());
      Dart_Handle library = Dart_LookupLibrary(library_uri);
      ASSERT(!Dart_IsError(library));
      dart_result = Dart_LoadSource(library, uri, resolved_uri, source, 0, 0);
    } break;
    case Dart_kScriptTag:
      if (payload_type == DartUtils::kSnapshotMagicNumber) {
        DartUtils::SkipSnapshotMagicNumber(&payload, &payload_length);
        dart_result = Dart_LoadScriptFromSnapshot(payload, payload_length);
        reload_extensions = true;
      } else if (payload_type == DartUtils::kKernelMagicNumber) {
        // TODO(27590): This code path is only hit when trying to spawn
        // isolates. We currently do not have support for neither
        // `Isolate.spawn()` nor `Isolate.spawnUri()` with kernel-based
        // frontend.
        Dart_Handle kernel_binary = reinterpret_cast<Dart_Handle>(
            Dart_ReadKernelBinary(payload, payload_length));
        dart_result = Dart_LoadScript(uri, resolved_uri, kernel_binary, 0, 0);
      } else {
        dart_result = Dart_LoadScript(uri, resolved_uri, source, 0, 0);
      }
      break;
    default:
      UNREACHABLE();
  }

  // Re-acquire the lock before exiting the function (it was held before entry),
  loader->monitor_->Enter();
  if (Dart_IsError(dart_result)) {
    // Remember the error if we encountered one.
    loader->error_ = dart_result;
    return false;
  }

  if (reload_extensions) {
    dart_result = ReloadNativeExtensions();
    if (Dart_IsError(dart_result)) {
      // Remember the error if we encountered one.
      loader->error_ = dart_result;
      return false;
    }
  }

  return true;
}

bool Loader::ProcessPayloadResultLocked(Loader* loader,
                                        Loader::IOResult* result) {
  // A negative result tag indicates a loading error occurred in the service
  // isolate. The payload is a C string of the error message.
  if (result->tag < 0) {
    Dart_Handle error =
        Dart_NewStringFromUTF8(result->payload, result->payload_length);
    loader->error_ = Dart_NewUnhandledExceptionError(error);
    return false;
  }
  loader->payload_length_ = result->payload_length;
  loader->payload_ =
      reinterpret_cast<uint8_t*>(::malloc(loader->payload_length_));
  memmove(loader->payload_, result->payload, loader->payload_length_);
  return true;
}

bool Loader::ProcessQueueLocked(ProcessResult process_result) {
  bool hit_error = false;
  for (intptr_t i = 0; i < results_length(); i++) {
    if (!hit_error) {
      hit_error = !(*process_result)(this, &results_[i]);
    }
    pending_operations_--;
    ASSERT(hit_error || (pending_operations_ >= 0));
    results_[i].Cleanup();
  }
  results_length_ = 0;
  return !hit_error;
}

void Loader::InitForSnapshot(const char* snapshot_uri) {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);
  ASSERT(!isolate_data->HasLoader());
  // Setup a loader. The constructor does a bunch of leg work.
  Loader* loader = new Loader(isolate_data);
  // Send the init message.
  loader->Init(isolate_data->package_root, isolate_data->packages_file,
               DartUtils::original_working_directory, snapshot_uri);
  // Destroy the loader. The destructor does a bunch of leg work.
  delete loader;
}

#define RETURN_ERROR(result)                                                   \
  if (Dart_IsError(result)) return result;

Dart_Handle Loader::ReloadNativeExtensions() {
  Dart_Handle scheme =
      Dart_NewStringFromCString(DartUtils::kDartExtensionScheme);
  Dart_Handle extension_imports = Dart_GetImportsOfScheme(scheme);
  RETURN_ERROR(extension_imports);

  intptr_t length = -1;
  Dart_Handle result = Dart_ListLength(extension_imports, &length);
  RETURN_ERROR(result);
  Dart_Handle* import_handles = reinterpret_cast<Dart_Handle*>(
      Dart_ScopeAllocate(sizeof(Dart_Handle) * length));
  result = Dart_ListGetRange(extension_imports, 0, length, import_handles);
  RETURN_ERROR(result);
  for (intptr_t i = 0; i < length; i += 2) {
    Dart_Handle importer = import_handles[i];
    Dart_Handle importee = import_handles[i + 1];

    const char* extension_uri = NULL;
    result = Dart_StringToCString(Dart_LibraryUrl(importee), &extension_uri);
    RETURN_ERROR(result);
    const char* extension_path = DartUtils::RemoveScheme(extension_uri);

    const char* lib_uri = NULL;
    result = Dart_StringToCString(Dart_LibraryUrl(importer), &lib_uri);
    RETURN_ERROR(result);

    char* lib_path = NULL;
    if (strncmp(lib_uri, "file://", 7) == 0) {
      lib_path = DartUtils::DirName(DartUtils::RemoveScheme(lib_uri));
    } else {
      lib_path = strdup(lib_uri);
    }

    result = Extensions::LoadExtension(lib_path, extension_path, importer);
    free(lib_path);
    RETURN_ERROR(result);
  }

  return Dart_True();
}

Dart_Handle Loader::SendAndProcessReply(intptr_t tag,
                                        Dart_Handle url,
                                        uint8_t** payload,
                                        intptr_t* payload_length) {
  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);
  ASSERT(!isolate_data->HasLoader());
  Loader* loader = NULL;

  // Setup the loader. The constructor does a bunch of leg work.
  loader = new Loader(isolate_data);
  loader->Init(isolate_data->package_root, isolate_data->packages_file,
               DartUtils::original_working_directory, NULL);
  ASSERT(loader != NULL);
  ASSERT(isolate_data->HasLoader());

  // Now send a load request to the service isolate.
  loader->SendRequest(tag, url, Dart_Null());

  // Wait for a reply to the load request.
  loader->BlockUntilComplete(ProcessPayloadResultLocked);

  // Copy fields from the loader before deleting it.
  // The payload array itself which was malloced above is freed by
  // the caller of LoadUrlContents.
  Dart_Handle error = loader->error();
  *payload = loader->payload_;
  *payload_length = loader->payload_length_;

  // Destroy the loader. The destructor does a bunch of leg work.
  delete loader;

  // An error occurred during loading.
  if (!Dart_IsNull(error)) {
    return error;
  }
  return Dart_Null();
}

Dart_Handle Loader::LoadUrlContents(Dart_Handle url,
                                    uint8_t** payload,
                                    intptr_t* payload_length) {
  return SendAndProcessReply(Dart_kScriptTag, url, payload, payload_length);
}

Dart_Handle Loader::ResolveAsFilePath(Dart_Handle url,
                                      uint8_t** payload,
                                      intptr_t* payload_length) {
  return SendAndProcessReply(_Dart_kResolveAsFilePath, url, payload,
                             payload_length);
}

#if defined(DART_PRECOMPILED_RUNTIME)
Dart_Handle Loader::LibraryTagHandler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url) {
  return Dart_Null();
}

Dart_Handle Loader::DartColonLibraryTagHandler(Dart_LibraryTag tag,
                                               Dart_Handle library,
                                               Dart_Handle url,
                                               const char* library_url_string,
                                               const char* url_string) {
  return Dart_Null();
}
#else
Dart_Handle Loader::LibraryTagHandler(Dart_LibraryTag tag,
                                      Dart_Handle library,
                                      Dart_Handle url) {
  if (tag == Dart_kCanonicalizeUrl) {
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    return Dart_DefaultCanonicalizeUrl(library_url, url);
  }
  const char* url_string = NULL;
  Dart_Handle result = Dart_StringToCString(url, &url_string);
  if (Dart_IsError(result)) {
    return result;
  }
  if (tag == Dart_kKernelTag) {
    ASSERT(dfe.UseDartFrontend() || dfe.kernel_file_specified());
    Dart_Isolate current = Dart_CurrentIsolate();
    ASSERT(!Dart_IsServiceIsolate(current) && !Dart_IsKernelIsolate(current));
    return dfe.ReadKernelBinary(current, url_string);
  }
  ASSERT(!dfe.UseDartFrontend() && !dfe.kernel_file_specified());
  if (tag != Dart_kScriptTag) {
    // Special case for handling dart: imports and parts.
    // Grab the library's url.
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
    const char* library_url_string = NULL;
    result = Dart_StringToCString(library_url, &library_url_string);
    if (Dart_IsError(result)) {
      return result;
    }

    bool is_dart_scheme_url = DartUtils::IsDartSchemeURL(url_string);
    bool is_dart_library = DartUtils::IsDartSchemeURL(library_url_string);

    if (is_dart_scheme_url || is_dart_library) {
      return DartColonLibraryTagHandler(tag, library, url, library_url_string,
                                        url_string);
    }
  }
  if (DartUtils::IsDartExtensionSchemeURL(url_string)) {
    // Handle early error cases for dart-ext: imports.
    if (tag != Dart_kImportTag) {
      return DartUtils::NewError("Dart extensions must use import: '%s'",
                                 url_string);
    }
    Dart_Handle library_url = Dart_LibraryUrl(library);
    if (Dart_IsError(library_url)) {
      return library_url;
    }
  }

  IsolateData* isolate_data =
      reinterpret_cast<IsolateData*>(Dart_CurrentIsolateData());
  ASSERT(isolate_data != NULL);
  if ((tag == Dart_kScriptTag) && Dart_IsString(library)) {
    // Update packages file for isolate.
    const char* packages_file = NULL;
    Dart_Handle result = Dart_StringToCString(library, &packages_file);
    if (Dart_IsError(result)) {
      return result;
    }
    isolate_data->UpdatePackagesFile(packages_file);
  }
  // Grab this isolate's loader.
  Loader* loader = NULL;

  // The outer invocation of the tag handler for this isolate. We make the outer
  // invocation block and allow any nested invocations to operate in parallel.
  const bool blocking_call = !isolate_data->HasLoader();

  // If we are the outer invocation of the tag handler and the tag is an import
  // this means that we are starting a deferred library load.
  const bool is_deferred_import = blocking_call && (tag == Dart_kImportTag);
  if (!isolate_data->HasLoader()) {
    // The isolate doesn't have a loader -- this is the outer invocation which
    // will block.

    // Setup the loader. The constructor does a bunch of leg work.
    loader = new Loader(isolate_data);
    loader->Init(isolate_data->package_root, isolate_data->packages_file,
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

  if (DartUtils::IsDartExtensionSchemeURL(url_string)) {
    loader->SendImportExtensionRequest(url, Dart_LibraryUrl(library));
  } else {
    if (Dart_KernelIsolateIsRunning()) {
      loader->SendKernelRequest(tag, url);
    } else {
      loader->SendRequest(
          tag, url,
          (library != Dart_Null()) ? Dart_LibraryUrl(library) : Dart_Null());
    }
  }

  if (blocking_call) {
    // The outer invocation of the tag handler will block here until all nested
    // invocations complete.
    loader->BlockUntilComplete(ProcessResultLocked);

    // Remember the error (if any).
    Dart_Handle error = loader->error();
    // Destroy the loader. The destructor does a bunch of leg work.
    delete loader;

    // An error occurred during loading.
    if (!Dart_IsNull(error)) {
      if (false && is_deferred_import) {
        // This blocks handles transitive load errors caused by a deferred
        // import. Non-transitive load errors are handled above (see callers of
        // |LibraryHandleError|). To handle the transitive case, we give the
        // originating deferred library an opportunity to handle it.
        Dart_Handle deferred_library = Dart_LookupLibrary(url);
        if (!LibraryHandleError(deferred_library, error)) {
          // Library did not handle it, return to caller as an unhandled
          // exception.
          return Dart_NewUnhandledExceptionError(error);
        }
      } else {
        // We got an error during loading but we aren't loading a deferred
        // library, return the error to the caller.
        return error;
      }
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
      return DartUtils::NewError(
          "The built-in library '%s' is not available"
          " on the stand-alone VM.\n",
          url_string);
    }
    return Builtin::LoadLibrary(url, id);
  } else {
    ASSERT(tag == Dart_kSourceTag);
    Builtin::BuiltinLibraryId id = Builtin::FindId(library_url_string);
    if (id == Builtin::kInvalidLibrary) {
      return DartUtils::NewError(
          "The built-in library '%s' is not available"
          " on the stand-alone VM. Trying to load"
          " '%s'.\n",
          library_url_string, url_string);
    }
    // Prepend the library URI to form a unique script URI for the part.
    intptr_t len = snprintf(NULL, 0, "%s/%s", library_url_string, url_string);
    char* part_uri = reinterpret_cast<char*>(malloc(len + 1));
    snprintf(part_uri, len + 1, "%s/%s", library_url_string, url_string);
    Dart_Handle part_uri_obj = DartUtils::NewString(part_uri);
    free(part_uri);
    return Dart_LoadSource(library, part_uri_obj, Dart_Null(),
                           Builtin::PartSource(id, url_string), 0, 0);
  }
  // All cases should have been handled above.
  UNREACHABLE();
  return Dart_Null();
}
#endif  // !defined(DART_PRECOMPILED_RUNTIME)

void Loader::InitOnce() {
  loader_infos_lock_ = new Mutex();
}

Mutex* Loader::loader_infos_lock_;
Loader::LoaderInfo* Loader::loader_infos_ = NULL;
intptr_t Loader::loader_infos_length_ = 0;
intptr_t Loader::loader_infos_capacity_ = 0;

// Add a mapping from |port| to |isolate_data| (really the loader). When a
// native message arrives, we use this map to report the I/O result to the
// correct loader.
// This happens whenever an isolate begins loading.
void Loader::AddLoader(Dart_Port port, IsolateData* isolate_data) {
  MutexLocker ml(loader_infos_lock_);
  ASSERT(LoaderForLocked(port) == NULL);
  if (loader_infos_length_ == loader_infos_capacity_) {
    // Grow to an initial capacity or double in size.
    loader_infos_capacity_ =
        (loader_infos_capacity_ == 0) ? 4 : loader_infos_capacity_ * 2;
    loader_infos_ = reinterpret_cast<Loader::LoaderInfo*>(realloc(
        loader_infos_, sizeof(Loader::LoaderInfo) * loader_infos_capacity_));
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
  MutexLocker ml(loader_infos_lock_);
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
  MutexLocker ml(loader_infos_lock_);
  return LoaderForLocked(port);
}

void Loader::NativeMessageHandler(Dart_Port dest_port_id,
                                  Dart_CObject* message) {
  MutexLocker ml(loader_infos_lock_);
  Loader* loader = LoaderForLocked(dest_port_id);
  if (loader == NULL) {
    return;
  }
  loader->QueueMessage(message);
}

}  // namespace bin
}  // namespace dart
