// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include "bin/file_system_watcher.h"

#if !DART_HOST_OS_IOS

#include <CoreServices/CoreServices.h>  // NOLINT
#include <dispatch/dispatch.h>
#include <errno.h>   // NOLINT
#include <fcntl.h>   // NOLINT
#include <unistd.h>  // NOLINT

#include "bin/eventhandler.h"
#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/namespace.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "platform/signal_blocker.h"

namespace dart {
namespace bin {

union FSEvent {
  struct {
    uint32_t exists;
    uint32_t flags;
    char path[PATH_MAX];
  } data;
  uint8_t bytes[PATH_MAX + 8];
};

// A helper for creating Dart_CObject array using a single allocation.
//
// We can't use CObject helpers because those rely on Dart_ScopeAllocate.
namespace {

template <typename T>
struct SetCObjectValue;

template <>
struct SetCObjectValue<const char*> {
  static void Assign(Dart_CObject* o, const char* str) {
    o->type = Dart_CObject_kString;
    o->value.as_string = str;
  }
};

template <>
struct SetCObjectValue<char*> {
  static void Assign(Dart_CObject* o, const char* str) {
    o->type = Dart_CObject_kString;
    o->value.as_string = str;
  }
};

template <>
struct SetCObjectValue<int64_t> {
  static void Assign(Dart_CObject* o, int64_t v) {
    o->type = Dart_CObject_kInt64;
    o->value.as_int64 = v;
  }
};

template <typename... Ts>
Dart_CObject* CreateCObjectArray(Ts... elements) {
  const auto length = sizeof...(elements);
  auto array = static_cast<Dart_CObject*>(
      malloc(sizeof(Dart_CObject) +
             (sizeof(Dart_CObject*) + sizeof(Dart_CObject)) * length));
  array->type = Dart_CObject_kArray;
  array->value.as_array.values = reinterpret_cast<Dart_CObject**>(array + 1);
  array->value.as_array.length = length;
  for (uintptr_t i = 0; i < length; i++) {
    array->value.as_array.values[i] =
        reinterpret_cast<Dart_CObject*>(array->value.as_array.values + length) +
        i;
  }

  int index = 0;
  (
      [&] {
        SetCObjectValue<Ts>::Assign(array->value.as_array.values[index],
                                    elements);
        ++index;
      }(),
      ...);

  return array;
}

}  // namespace

class Node {
 public:
  Node(Dart_Port port, char* base_path, bool recursive)
      : port_(port),
        base_path_length_(strlen(base_path)),
        path_ref_(CFStringCreateWithCString(nullptr,
                                            base_path,
                                            kCFStringEncodingUTF8)),
        recursive_(recursive),
        ref_(nullptr) {
    Start();
  }

  ~Node() {
    // This is invoked outside of [Callback] execution because
    // [context.release] callback is invoked when [FSEventStream] is
    // deallocated, the same [FSEventStream] that [Callback] gets a reference
    // to during its execution. [Callback] holding a reference prevents stream
    // from deallocation.
    CFRelease(path_ref_);
  }

  void set_ref(FSEventStreamRef ref) { ref_ = ref; }

  void Start() {
    FSEventStreamContext context;
    memset(&context, 0, sizeof(context));
    context.info = reinterpret_cast<void*>(this);
    context.release = [](const void* info) {
      reinterpret_cast<Node*>(const_cast<void*>(info))->NotifyStopped();
    };
    CFArrayRef array = CFArrayCreate(
        nullptr, reinterpret_cast<const void**>(&path_ref_), 1, nullptr);
    FSEventStreamRef ref = FSEventStreamCreate(
        nullptr, Callback, &context, array, kFSEventStreamEventIdSinceNow, 0.10,
        kFSEventStreamCreateFlagFileEvents);
    CFRelease(array);

    set_ref(ref);

    FSEventStreamSetDispatchQueue(ref_, notification_queue_);
    FSEventStreamStart(ref_);
    FSEventStreamFlushSync(ref_);
  }

  void Stop() {
    FSEventStreamStop(ref_);
    FSEventStreamInvalidate(ref_);
    FSEventStreamRelease(ref_);
    {
      MonitorLocker lock(&monitor_);
      while (running_) {
        lock.Wait();
      }
    }
  }

  intptr_t base_path_length() const { return base_path_length_; }
  bool recursive() const { return recursive_; }

  static Node* Watch(Dart_Port port,
                     const char* path,
                     int events,
                     bool recursive) {
    char base_path[PATH_MAX];
    realpath(path, base_path);

    return new Node(port, base_path, recursive);
  }

  static void Unwatch(Node* node) {
    node->Stop();
    delete node;
  }

  static void InitOnce() {
    notification_queue_ =
        dispatch_queue_create("dev.dart.fsevents", DISPATCH_QUEUE_SERIAL);
  }

  static void Cleanup() {
    // We want to make sure that no Node is active, these should have all been
    // destroyed.
    dispatch_release(notification_queue_);
  }

 private:
  void NotifyStopped() {
    MonitorLocker lock(&monitor_);
    running_ = false;
    lock.Notify();
  }

  static void Callback(ConstFSEventStreamRef ref,
                       void* client,
                       size_t num_events,
                       void* event_paths,
                       const FSEventStreamEventFlags event_flags[],
                       const FSEventStreamEventId event_ids[]) {
    if (FileSystemWatcher::delayed_filewatch_callback()) {
      // Used in tests to highlight race between callback invocation
      // and unwatching the file path, Node destruction
      TimerUtils::Sleep(1000 /* ms */);
    }
    Node* node = static_cast<Node*>(client);

    // Can't use CObject helpers because they expect Dart_ScopeAllocate to work
    // and this thread is not attached to any isolate or native message handler.
    Dart_CObject events;
    events.type = Dart_CObject_kArray;
    events.value.as_array.values =
        static_cast<Dart_CObject**>(malloc(sizeof(Dart_CObject*) * num_events));
    events.value.as_array.length = 0;
    for (size_t i = 0; i < num_events; i++) {
      char* path = reinterpret_cast<char**>(event_paths)[i];
      char* relative_path = path;

      relative_path += node->base_path_length();
      // If path is longer than the base, skip next character ('/').
      if (relative_path[0] != '\0') {
        relative_path += 1;
      }
      if (!node->recursive() && (strstr(relative_path, "/") != nullptr)) {
        continue;
      }

      const bool is_self = relative_path[0] == '\0';
      const bool path_exists =
          File::GetType(nullptr, path, false) != File::kDoesNotExist;

      events.value.as_array.values[events.value.as_array.length++] =
          CreateCObjectArray(
              /*flags=*/ConvertEventFlags(event_flags[i], is_self, path_exists),
              /*cookie=*/static_cast<int64_t>(0), relative_path,
              /*path_id=*/reinterpret_cast<int64_t>(node));
    }

    if (events.value.as_array.length != 0) {
      Dart_PostCObject(node->port_, &events);
    }

    for (int i = 0; i < events.value.as_array.length; i++) {
      free(events.value.as_array.values[i]);
    }
    free(events.value.as_array.values);
  }

  static int64_t ConvertEventFlags(FSEventStreamEventFlags flags,
                                   bool is_self,
                                   bool path_exists) {
    int64_t mask = 0;
    if ((flags & kFSEventStreamEventFlagItemRenamed) != 0) {
      if (is_self) {
        // The moved path is the path being watched.
        mask |= FileSystemWatcher::kDeleteSelf;
      } else if (path_exists) {
        mask |= FileSystemWatcher::kCreate;
      } else {
        mask |= FileSystemWatcher::kDelete;
      }
    }
    if ((flags & kFSEventStreamEventFlagItemModified) != 0) {
      mask |= FileSystemWatcher::kModifyContent;
    }
    if ((flags & kFSEventStreamEventFlagItemXattrMod) != 0) {
      mask |= FileSystemWatcher::kModifyAttribute;
    }
    if ((flags & kFSEventStreamEventFlagItemCreated) != 0) {
      mask |= FileSystemWatcher::kCreate;
    }
    if ((flags & kFSEventStreamEventFlagItemIsDir) != 0) {
      mask |= FileSystemWatcher::kIsDir;
    }
    if ((flags & kFSEventStreamEventFlagItemRemoved) != 0) {
      if (is_self) {
        // The removed path is the path being watched.
        mask |= FileSystemWatcher::kDeleteSelf;
      } else {
        mask |= FileSystemWatcher::kDelete;
      }
    }
    return mask;
  }

  static dispatch_queue_t notification_queue_;

  Dart_Port port_;
  intptr_t base_path_length_;
  CFStringRef path_ref_;
  bool recursive_;
  FSEventStreamRef ref_;
  Monitor monitor_;
  bool running_ = true;

  DISALLOW_COPY_AND_ASSIGN(Node);
};

dispatch_queue_t Node::notification_queue_;

bool FileSystemWatcher::IsSupported() {
  return true;
}

void FileSystemWatcher::InitOnce() {
  Node::InitOnce();
}

void FileSystemWatcher::Cleanup() {
  Node::Cleanup();
}

intptr_t FileSystemWatcher::Init() {
  return 0;
}

intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      Namespace* namespc,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  return reinterpret_cast<intptr_t>(
      Node::Watch(static_cast<Dart_Port>(id), path, events, recursive));
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  USE(id);
  Node::Unwatch(reinterpret_cast<Node*>(path_id));
}

void FileSystemWatcher::DestroyWatch(intptr_t path_id) {
  FileSystemWatcher::UnwatchPath(0, path_id);
}

intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  // This API should not be called. We are communicating over ports instead.
  return -1;
}

Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  // This API should not be called. We are communicating over ports instead.
  return DartUtils::NewDartOSError();
}

}  // namespace bin
}  // namespace dart

#else  // !DART_HOST_OS_IOS

namespace dart {
namespace bin {

// FSEvents are unavailable on iOS. Stub out related methods
Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  return DartUtils::NewDartOSError();
}

intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  return -1;
}

bool FileSystemWatcher::IsSupported() {
  return false;
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {}

void FileSystemWatcher::DestroyWatch(intptr_t path_id) {}

void FileSystemWatcher::InitOnce() {}

void FileSystemWatcher::Cleanup() {}

intptr_t FileSystemWatcher::Init() {
  return -1;
}

intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      Namespace* namespc,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  return -1;
}

}  // namespace bin
}  // namespace dart

#endif  // !DART_HOST_OS_IOS
#endif  // defined(DART_HOST_OS_MACOS)
