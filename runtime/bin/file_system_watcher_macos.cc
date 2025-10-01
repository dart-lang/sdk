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

class Node {
 public:
  Node(char* base_path, int read_fd, int write_fd, bool recursive)
      : base_path_length_(strlen(base_path)),
        path_ref_(CFStringCreateWithCString(nullptr,
                                            base_path,
                                            kCFStringEncodingUTF8)),
        read_fd_(read_fd),
        write_fd_(write_fd),
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
    close(write_fd_);
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
  int read_fd() const { return read_fd_; }
  int write_fd() const { return write_fd_; }
  bool recursive() const { return recursive_; }

  static Node* Watch(const char* path, int events, bool recursive) {
    int fds[2];
    VOID_NO_RETRY_EXPECTED(pipe(fds));
    FDUtils::SetNonBlocking(fds[0]);
    FDUtils::SetBlocking(fds[1]);

    char base_path[PATH_MAX];
    realpath(path, base_path);

    return new Node(base_path, fds[0], fds[1], recursive);
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
    for (size_t i = 0; i < num_events; i++) {
      char* path = reinterpret_cast<char**>(event_paths)[i];
      FSEvent event;
      event.data.exists =
          File::GetType(nullptr, path, false) != File::kDoesNotExist;
      path += node->base_path_length();
      // If path is longer the base, skip next character ('/').
      if (path[0] != '\0') {
        path += 1;
      }
      if (!node->recursive() && (strstr(path, "/") != nullptr)) {
        continue;
      }
      event.data.flags = event_flags[i];
      memmove(event.data.path, path, strlen(path) + 1);
      write(node->write_fd(), event.bytes, sizeof(event));
    }
  }

  static dispatch_queue_t notification_queue_;

  intptr_t base_path_length_;
  CFStringRef path_ref_;
  int read_fd_;
  int write_fd_;
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
  return reinterpret_cast<intptr_t>(Node::Watch(path, events, recursive));
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  USE(id);
  Node::Unwatch(reinterpret_cast<Node*>(path_id));
}

void FileSystemWatcher::DestroyWatch(intptr_t path_id) {
  FileSystemWatcher::UnwatchPath(0, path_id);
}

intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  return reinterpret_cast<Node*>(path_id)->read_fd();
}

Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id, intptr_t path_id) {
  intptr_t fd = GetSocketId(id, path_id);
  intptr_t avail = FDUtils::AvailableBytes(fd);
  int count = avail / sizeof(FSEvent);
  if (count <= 0) {
    return Dart_NewList(0);
  }
  Dart_Handle events = Dart_NewList(count);
  FSEvent e;
  for (int i = 0; i < count; i++) {
    intptr_t bytes = TEMP_FAILURE_RETRY(read(fd, e.bytes, sizeof(e)));
    if (bytes < 0) {
      return DartUtils::NewDartOSError();
    }
    size_t path_len = strlen(e.data.path);
    Dart_Handle event = Dart_NewList(kEventNumElements);
    int flags = e.data.flags;
    int mask = 0;
    if ((flags & kFSEventStreamEventFlagItemRenamed) != 0) {
      if (path_len == 0) {
        // The moved path is the path being watched.
        mask |= kDeleteSelf;
      } else {
        mask |= e.data.exists ? kCreate : kDelete;
      }
    }
    if ((flags & kFSEventStreamEventFlagItemModified) != 0) {
      mask |= kModifyContent;
    }
    if ((flags & kFSEventStreamEventFlagItemXattrMod) != 0) {
      mask |= kModifyAttribute;
    }
    if ((flags & kFSEventStreamEventFlagItemCreated) != 0) {
      mask |= kCreate;
    }
    if ((flags & kFSEventStreamEventFlagItemIsDir) != 0) {
      mask |= kIsDir;
    }
    if ((flags & kFSEventStreamEventFlagItemRemoved) != 0) {
      if (path_len == 0) {
        // The removed path is the path being watched.
        mask |= kDeleteSelf;
      } else {
        mask |= kDelete;
      }
    }
    Dart_ListSetAt(event, kEventFlagsIndex, Dart_NewInteger(mask));
    Dart_ListSetAt(event, kEventCookieIndex, Dart_NewInteger(0));
    Dart_Handle name = Dart_NewStringFromUTF8(
        reinterpret_cast<uint8_t*>(e.data.path), path_len);
    if (Dart_IsError(name)) {
      return name;
    }
    Dart_ListSetAt(event, kEventPathIndex, name);
    Dart_ListSetAt(event, kEventPathIdIndex, Dart_NewInteger(path_id));
    Dart_ListSetAt(events, i, event);
  }
  return events;
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
