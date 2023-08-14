// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include "bin/file_system_watcher.h"

#if !DART_HOST_OS_IOS

#include <CoreServices/CoreServices.h>  // NOLINT
#include <errno.h>                      // NOLINT
#include <fcntl.h>                      // NOLINT
#include <unistd.h>                     // NOLINT

#include "bin/eventhandler.h"
#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/namespace.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "platform/signal_blocker.h"

#ifndef MAC_OS_X_VERSION_10_7
enum { kFSEventStreamCreateFlagFileEvents = 0x00000010 };
enum {
  kFSEventStreamEventFlagItemCreated = 0x00000100,
  kFSEventStreamEventFlagItemRemoved = 0x00000200,
  kFSEventStreamEventFlagItemInodeMetaMod = 0x00000400,
  kFSEventStreamEventFlagItemRenamed = 0x00000800,
  kFSEventStreamEventFlagItemModified = 0x00001000,
  kFSEventStreamEventFlagItemFinderInfoMod = 0x00002000,
  kFSEventStreamEventFlagItemChangeOwner = 0x00004000,
  kFSEventStreamEventFlagItemXattrMod = 0x00008000,
  kFSEventStreamEventFlagItemIsFile = 0x00010000,
  kFSEventStreamEventFlagItemIsDir = 0x00020000,
  kFSEventStreamEventFlagItemIsSymlink = 0x00040000
};
#endif

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

class FSEventsWatcher {
 public:
  class Node {
   public:
    Node(FSEventsWatcher* watcher,
         char* base_path,
         int read_fd,
         int write_fd,
         bool recursive)
        : watcher_(watcher),
          base_path_length_(strlen(base_path)),
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
      watcher_ = nullptr;  // this is to catch access-after-free in Callback
    }

    void set_ref(FSEventStreamRef ref) { ref_ = ref; }

    void Start() {
      FSEventStreamContext context;
      memset(&context, 0, sizeof(context));
      context.info = reinterpret_cast<void*>(this);
      context.release = [](const void* info) {
        delete static_cast<const Node*>(info);
      };
      CFArrayRef array = CFArrayCreate(
          nullptr, reinterpret_cast<const void**>(&path_ref_), 1, nullptr);
      FSEventStreamRef ref = FSEventStreamCreate(
          nullptr, Callback, &context, array, kFSEventStreamEventIdSinceNow,
          0.10, kFSEventStreamCreateFlagFileEvents);
      CFRelease(array);

      set_ref(ref);

      FSEventStreamScheduleWithRunLoop(ref_, watcher_->run_loop_,
                                       kCFRunLoopDefaultMode);

      FSEventStreamStart(ref_);
      FSEventStreamFlushSync(ref_);
    }

    void Stop() {
      FSEventStreamStop(ref_);
      FSEventStreamInvalidate(ref_);
      FSEventStreamRelease(ref_);
    }

    FSEventsWatcher* watcher() const { return watcher_; }
    intptr_t base_path_length() const { return base_path_length_; }
    int read_fd() const { return read_fd_; }
    int write_fd() const { return write_fd_; }
    bool recursive() const { return recursive_; }

   private:
    FSEventsWatcher* watcher_;
    intptr_t base_path_length_;
    CFStringRef path_ref_;
    int read_fd_;
    int write_fd_;
    bool recursive_;
    FSEventStreamRef ref_;

    DISALLOW_COPY_AND_ASSIGN(Node);
  };

  FSEventsWatcher() : run_loop_(0) { Start(); }

  void Start() {
    Thread::Start("dart:io FileWatcher", Run, reinterpret_cast<uword>(this));
    monitor_.Enter();
    while (run_loop_ == nullptr) {
      monitor_.Wait(Monitor::kNoTimeout);
    }
    monitor_.Exit();
  }

  static void Run(uword arg) {
    FSEventsWatcher* watcher = reinterpret_cast<FSEventsWatcher*>(arg);
    // Only checked in debug mode.
    watcher->threadId_ = Thread::GetCurrentThreadId();
    watcher->run_loop_ = CFRunLoopGetCurrent();
    CFRetain(watcher->run_loop_);

    // Notify, as the run-loop is set.
    watcher->monitor().Enter();
    watcher->monitor().Notify();
    watcher->monitor().Exit();

    CFRunLoopTimerRef timer =
        CFRunLoopTimerCreate(nullptr, CFAbsoluteTimeGetCurrent() + 1, 1, 0, 0,
                             TimerCallback, nullptr);
    CFRunLoopAddTimer(watcher->run_loop_, timer, kCFRunLoopCommonModes);
    CFRelease(timer);

    CFRunLoopRun();

    CFRelease(watcher->run_loop_);
    watcher->monitor_.Enter();
    watcher->run_loop_ = nullptr;
    watcher->monitor_.Notify();
    watcher->monitor_.Exit();
  }

  void Stop() {
    // Schedule StopCallback to be executed in the RunLoop.
    CFRunLoopTimerContext context;
    memset(&context, 0, sizeof(context));
    context.info = this;
    CFRunLoopTimerRef timer =
        CFRunLoopTimerCreate(nullptr, 0, 0, 0, 0, StopCallback, &context);
    CFRunLoopAddTimer(run_loop_, timer, kCFRunLoopCommonModes);
    CFRelease(timer);
    monitor_.Enter();
    while (run_loop_ != nullptr) {
      monitor_.Wait(Monitor::kNoTimeout);
    }
    monitor_.Exit();
  }

  static void StopCallback(CFRunLoopTimerRef timer, void* info) {
    FSEventsWatcher* watcher = reinterpret_cast<FSEventsWatcher*>(info);
    ASSERT(Thread::Compare(watcher->threadId_, Thread::GetCurrentThreadId()));
    CFRunLoopStop(watcher->run_loop_);
  }

  ~FSEventsWatcher() { Stop(); }

  Monitor& monitor() { return monitor_; }

  bool has_run_loop() const { return run_loop_ != nullptr; }

  static void TimerCallback(CFRunLoopTimerRef timer, void* context) {
    // Dummy callback to keep RunLoop alive.
  }

  Node* AddPath(const char* path, int events, bool recursive) {
    int fds[2];
    VOID_NO_RETRY_EXPECTED(pipe(fds));
    FDUtils::SetNonBlocking(fds[0]);
    FDUtils::SetBlocking(fds[1]);

    char base_path[PATH_MAX];
    realpath(path, base_path);

    return new Node(this, base_path, fds[0], fds[1], recursive);
  }

 private:
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
    RELEASE_ASSERT(node->watcher() != nullptr);
    ASSERT(Thread::Compare(node->watcher()->threadId_,
                           Thread::GetCurrentThreadId()));
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

  Monitor monitor_;
  CFRunLoopRef run_loop_;
  ThreadId threadId_;

  DISALLOW_COPY_AND_ASSIGN(FSEventsWatcher);
};

#define kCFCoreFoundationVersionNumber10_7 635.00
bool FileSystemWatcher::IsSupported() {
  return kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_7;
}

intptr_t FileSystemWatcher::Init() {
  return reinterpret_cast<intptr_t>(new FSEventsWatcher());
}

void FileSystemWatcher::Close(intptr_t id) {
  delete reinterpret_cast<FSEventsWatcher*>(id);
}

intptr_t FileSystemWatcher::WatchPath(intptr_t id,
                                      Namespace* namespc,
                                      const char* path,
                                      int events,
                                      bool recursive) {
  FSEventsWatcher* watcher = reinterpret_cast<FSEventsWatcher*>(id);
  return reinterpret_cast<intptr_t>(watcher->AddPath(path, events, recursive));
}

void FileSystemWatcher::UnwatchPath(intptr_t id, intptr_t path_id) {
  USE(id);
  reinterpret_cast<FSEventsWatcher::Node*>(path_id)->Stop();
}

intptr_t FileSystemWatcher::GetSocketId(intptr_t id, intptr_t path_id) {
  return reinterpret_cast<FSEventsWatcher::Node*>(path_id)->read_fd();
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
    Dart_Handle event = Dart_NewList(5);
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
    Dart_ListSetAt(event, 0, Dart_NewInteger(mask));
    Dart_ListSetAt(event, 1, Dart_NewInteger(1));
    Dart_Handle name = Dart_NewStringFromUTF8(
        reinterpret_cast<uint8_t*>(e.data.path), path_len);
    if (Dart_IsError(name)) {
      return name;
    }
    Dart_ListSetAt(event, 2, name);
    Dart_ListSetAt(event, 3, Dart_NewBoolean(true));
    Dart_ListSetAt(event, 4, Dart_NewInteger(path_id));
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

intptr_t FileSystemWatcher::Init() {
  return -1;
}

void FileSystemWatcher::Close(intptr_t id) {}

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
