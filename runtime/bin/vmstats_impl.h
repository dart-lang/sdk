// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_VMSTATS_IMPL_H_
#define BIN_VMSTATS_IMPL_H_

#include "bin/vmstats.h"

#include <map>

#include "bin/isolate_data.h"
#include "platform/thread.h"

// VmStats is a HTTP singleton service that reports status information
// of the running VM.

class VmStats {
 public:
  static void Initialize();

  static void Start(int port, const char* root_dir, bool verbose);
  static void Stop();

  // Add and remove functions for the isolate_table, called by main.cc.
  static void AddIsolate(IsolateData* isolate_data, Dart_Isolate isolate);
  static void RemoveIsolate(IsolateData* isolate_data);

  // Print stack traces of current isolates to stdout.
  static void DumpStack();

 private:
  explicit VmStats(bool verbose) :
      root_directory_(NULL), running_(false), bind_address_(0) {
    verbose_ = verbose;
  }

  static void StartServer(int port, const char* root_dir);
  static void WebServer(uword bind_address);
  static void Shutdown();
  static void DumpStackThread(uword unused);

  // Status text generators.
  char* IsolatesStatus();

  typedef std::map<IsolateData*, Dart_Isolate> IsolateTable;

  const char* root_directory_;
  IsolateTable isolate_table_;
  bool running_;
  int64_t bind_address_;
  bool verbose_;

  static VmStats* instance_;
  static dart::Monitor* instance_monitor_;

  // Disallow copy constructor.
  DISALLOW_COPY_AND_ASSIGN(VmStats);
};


// Status plug-in and linked-list node.
class VmStatusPlugin {
 public:
  explicit VmStatusPlugin(Dart_VmStatusCallback callback)
      : callback_(callback), next_(NULL) {}

  void Append(VmStatusPlugin* plugin) {
    VmStatusPlugin* list = this;
    while (list->next_ != NULL) {
      list = list->next_;
    }
    list->next_ = plugin;
  }

  Dart_VmStatusCallback callback() { return callback_; }
  VmStatusPlugin* next() { return next_; }

 private:
  Dart_VmStatusCallback callback_;
  VmStatusPlugin* next_;
};


// Singleton service managing VM status gathering and status plug-in
// registration.
class VmStatusService {
 public:
  static int RegisterPlugin(Dart_VmStatusCallback callback);

  // Returns VM status for a specified request. The caller is responsible
  // for releasing the heap memory after use.
  static char* GetVmStatus(const char* request);

  static void InitOnce();

 private:
  VmStatusService() : registered_plugin_list_(NULL) {}

  static VmStatusService* instance_;
  static dart::Mutex* mutex_;

  VmStatusPlugin* registered_plugin_list_;

  DISALLOW_COPY_AND_ASSIGN(VmStatusService);
};

#endif  // BIN_VMSTATS_IMPL_H_
