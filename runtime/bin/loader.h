// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_LOADER_H_
#define RUNTIME_BIN_LOADER_H_

#include "bin/isolate_data.h"
#include "include/dart_api.h"
#include "include/dart_native_api.h"
#include "platform/assert.h"
#include "platform/globals.h"
#include "bin/thread.h"

namespace dart {
namespace bin {

class Loader {
 public:
  explicit Loader(IsolateData* isolate_data);
  ~Loader();

  static void InitForSnapshot(const char* snapshot_uri);

  static Dart_Handle ReloadNativeExtensions();

  // Loads contents of the specified url.
  static Dart_Handle LoadUrlContents(Dart_Handle url,
                                     uint8_t** payload,
                                     intptr_t* payload_length);

  static void ResolveDependenciesAsFilePaths();

  // A static tag handler that hides all usage of a loader for an isolate.
  static Dart_Handle LibraryTagHandler(Dart_LibraryTag tag,
                                       Dart_Handle library,
                                       Dart_Handle url);

  Dart_Handle error() const { return error_; }

  static void InitOnce();

 private:
  // The port assigned to our native message handler.
  Dart_Port port_;
  // Each Loader is associated with an Isolate via its IsolateData.
  IsolateData* isolate_data_;
  // Remember the first error that occurs during loading.
  Dart_Handle error_;
  // This monitor is used to protect the pending operations count and the
  // I/O result queue.
  Monitor* monitor_;

  // The number of operations dispatched to the service isolate for loading.
  // Must be accessed with monitor_ held.
  intptr_t pending_operations_;

  // The result of an I/O request to the service isolate. Payload is either
  // a UInt8Array or a C string containing an error message.
  struct IOResult {
    uint8_t* payload;
    intptr_t payload_length;
    char* library_uri;
    char* uri;
    char* resolved_uri;
    int8_t tag;

    void Setup(Dart_CObject* message);
    void Cleanup();
  };
  // An array of I/O results queued from the service isolate.
  IOResult* results_;
  intptr_t results_length_;
  intptr_t results_capacity_;
  uint8_t* payload_;
  intptr_t payload_length_;
  typedef bool (*ProcessResult)(Loader* loader, IOResult* result);

  intptr_t results_length() {
    return *static_cast<volatile intptr_t*>(&results_length_);
  }

  // Send the loader init request to the service isolate.
  void Init(const char* package_root,
            const char* packages_file,
            const char* working_directory,
            const char* root_script_uri);

  // Send a request for a dart-ext: import to the service isolate.
  void SendImportExtensionRequest(Dart_Handle url, Dart_Handle library_url);

  // Send a request from the tag handler to the service isolate.
  void SendRequest(intptr_t tag, Dart_Handle url, Dart_Handle library_url);

  static Dart_Handle SendAndProcessReply(intptr_t tag,
                                         Dart_Handle url,
                                         uint8_t** payload,
                                         intptr_t* payload_length);

  static Dart_Handle ResolveAsFilePath(Dart_Handle url,
                                       uint8_t** payload,
                                       intptr_t* payload_length);

  // Send a request from the tag handler to the kernel isolate.
  void SendKernelRequest(Dart_LibraryTag tag, Dart_Handle url);

  /// Queue |message| and notify the loader that a message is available.
  void QueueMessage(Dart_CObject* message);

  /// Blocks the caller until the loader is finished.
  void BlockUntilComplete(ProcessResult process_result);

  /// Saves a script dependency when applicable.
  static void AddDependencyLocked(Loader* loader, const char* resolved_uri);

  /// Returns false if |result| is an error and the loader should quit.
  static bool ProcessResultLocked(Loader* loader, IOResult* result);

  /// Returns false if |result| is an error and the loader should quit.
  static bool ProcessPayloadResultLocked(Loader* loader, IOResult* result);

  /// Returns false if an error occurred and the loader should quit.
  bool ProcessQueueLocked(ProcessResult process_result);

  // Special inner tag handler for dart: uris.
  static Dart_Handle DartColonLibraryTagHandler(Dart_LibraryTag tag,
                                                Dart_Handle library,
                                                Dart_Handle url,
                                                const char* library_url_string,
                                                const char* url_string);

  // We use one native message handler callback for N loaders. The native
  // message handler callback provides us with the Dart_Port which we use as a
  // key into our map of active loaders from |port| to |isolate_data|.

  // Static information to map Dart_Port back to the isolate in question.
  struct LoaderInfo {
    Dart_Port port;
    IsolateData* isolate_data;
  };

  // The map of active loaders.
  static Mutex* loader_infos_lock_;
  static LoaderInfo* loader_infos_;
  static intptr_t loader_infos_length_;
  static intptr_t loader_infos_capacity_;

  static void AddLoader(Dart_Port port, IsolateData* data);
  static void RemoveLoader(Dart_Port port);
  static intptr_t LoaderIndexFor(Dart_Port port);
  static Loader* LoaderFor(Dart_Port port);
  static Loader* LoaderForLocked(Dart_Port port);

  // This is the global callback for the native message handlers.
  static void NativeMessageHandler(Dart_Port dest_port_id,
                                   Dart_CObject* message);
};

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_LOADER_H_
