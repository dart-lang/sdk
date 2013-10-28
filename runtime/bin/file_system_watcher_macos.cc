// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_MACOS)

#include "bin/file_system_watcher.h"

#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <unistd.h>  // NOLINT
#include <CoreServices/CoreServices.h>  // NOLINT

#include "bin/eventhandler.h"
#include "bin/fdutils.h"
#include "bin/socket.h"
#include "bin/thread.h"


#ifndef MAC_OS_X_VERSION_10_7
enum {
  kFSEventStreamCreateFlagFileEvents = 0x00000010
};
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

static Mutex* watcher_mutex = new Mutex();
static Monitor* watcher_monitor = new Monitor();

class FSEventsWatcher;
static FSEventsWatcher* watcher = NULL;

union FSEvent {
  struct {
    uint32_t flags;
    char path[PATH_MAX];
  } data;
  uint8_t bytes[PATH_MAX + 4];
};

class FSEventsWatcher {
 public:
  class Node {
   public:
    Node(intptr_t base_path_length, int read_fd, int write_fd, bool recursive)
      : base_path_length_(base_path_length),
        read_fd_(read_fd),
        write_fd_(write_fd),
        recursive_(recursive),
        ref_(NULL) {}

    ~Node() {
      close(write_fd_);
      FSEventStreamInvalidate(ref_);
      FSEventStreamRelease(ref_);
    }

    void set_ref(FSEventStreamRef ref) {
      ref_ = ref;
    }

    void Start() {
      FSEventStreamStart(ref_);
    }

    void Stop() {
      FSEventStreamStop(ref_);
    }

    intptr_t base_path_length() const { return base_path_length_; }
    int read_fd() const { return read_fd_; }
    int write_fd() const { return write_fd_; }
    bool recursive() const { return recursive_; }

   private:
    intptr_t base_path_length_;
    int read_fd_;
    int write_fd_;
    bool recursive_;
    FSEventStreamRef ref_;
  };

  FSEventsWatcher() : run_loop_(0), users_(0) {
    Thread::Start(Run, reinterpret_cast<uword>(this));
  }

  ~FSEventsWatcher() {
    CFRunLoopStop(run_loop_);
  }

  static void TimerCallback(CFRunLoopTimerRef timer, void* context) {
    // Dummy callback to keep RunLoop alive.
  }

  static void Run(uword arg) {
    FSEventsWatcher* watcher = reinterpret_cast<FSEventsWatcher*>(arg);
    watcher->run_loop_ = CFRunLoopGetCurrent();

    // Notify, as the run-loop is set.
    watcher_monitor->Enter();
    watcher_monitor->Notify();
    watcher_monitor->Exit();

    CFRunLoopTimerRef timer = CFRunLoopTimerCreate(
        NULL,
        CFAbsoluteTimeGetCurrent() + 1,
        1,
        0,
        0,
        TimerCallback,
        NULL);

    CFRunLoopAddTimer(watcher->run_loop_, timer, kCFRunLoopCommonModes);

    CFRunLoopRun();
  }

  static void Increment() {
    if (watcher == NULL) {
      watcher_monitor->Enter();
      watcher = new FSEventsWatcher();
      while (watcher->run_loop_ == NULL) {
        watcher_monitor->Wait(Monitor::kNoTimeout);
      }
      watcher_monitor->Exit();
    }
    watcher->users_++;
  }

  static void Decrement() {
    ASSERT(watcher->users_ > 0);
    watcher->users_--;
    if (watcher->users_ == 0) {
      delete watcher;
      watcher = NULL;
    }
  }

  Node* AddPath(const char* path, int events, bool recursive) {
    int fds[2];
    VOID_TEMP_FAILURE_RETRY(pipe(fds));
    Socket::SetNonBlocking(fds[0]);
    Socket::SetBlocking(fds[1]);

    char base_path[PATH_MAX];
    realpath(path, base_path);
    CFStringRef path_ref = CFStringCreateWithCString(
        NULL, base_path, kCFStringEncodingUTF8);

    Node* node = new Node(strlen(base_path), fds[0], fds[1], recursive);

    FSEventStreamContext context;
    context.version = 0;
    context.info = reinterpret_cast<void*>(node);
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    FSEventStreamRef ref = FSEventStreamCreate(
        NULL,
        Callback,
        &context,
        CFArrayCreate(NULL, reinterpret_cast<const void**>(&path_ref), 1, NULL),
        kFSEventStreamEventIdSinceNow,
        0.10,
        kFSEventStreamCreateFlagFileEvents);

    node->set_ref(ref);

    FSEventStreamScheduleWithRunLoop(
        ref,
        run_loop_,
        kCFRunLoopDefaultMode);

    return node;
  }

 private:
  static void Callback(ConstFSEventStreamRef ref,
                       void* client,
                       size_t num_events,
                       void* event_paths,
                       const FSEventStreamEventFlags event_flags[],
                       const FSEventStreamEventId event_ids[]) {
    Node* node = reinterpret_cast<Node*>(client);
    for (size_t i = 0; i < num_events; i++) {
      char *path = reinterpret_cast<char**>(event_paths)[i];
      path += node->base_path_length();
      // If path is longer the base, skip next character ('/').
      if (path[0] != '\0') path += 1;
      if (!node->recursive() && strstr(path, "/") != NULL) continue;
      FSEvent event;
      event.data.flags = event_flags[i];
      memmove(event.data.path, path, strlen(path) + 1);
      write(node->write_fd(), event.bytes, sizeof(event));
    }
  }

  CFRunLoopRef run_loop_;
  int users_;
};


#define kCFCoreFoundationVersionNumber10_7      635.00
bool FileSystemWatcher::IsSupported() {
  return kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_7;
}


intptr_t FileSystemWatcher::WatchPath(const char* path,
                                      int events,
                                      bool recursive) {
  MutexLocker lock(watcher_mutex);
  FSEventsWatcher::Increment();

  FSEventsWatcher::Node* node = watcher->AddPath(path, events, recursive);
  node->Start();
  return reinterpret_cast<intptr_t>(node);
}


void FileSystemWatcher::UnwatchPath(intptr_t id) {
  MutexLocker lock(watcher_mutex);

  FSEventsWatcher::Node* node = reinterpret_cast<FSEventsWatcher::Node*>(id);
  node->Stop();
  delete node;

  FSEventsWatcher::Decrement();
}


intptr_t FileSystemWatcher::GetSocketId(intptr_t id) {
  return reinterpret_cast<FSEventsWatcher::Node*>(id)->read_fd();
}


Dart_Handle FileSystemWatcher::ReadEvents(intptr_t id) {
  intptr_t fd = GetSocketId(id);
  intptr_t avail = FDUtils::AvailableBytes(fd);
  int count = avail / sizeof(FSEvent);
  if (count <= 0) return Dart_NewList(0);
  Dart_Handle events = Dart_NewList(count);
  FSEvent e;
  for (int i = 0; i < count; i++) {
    intptr_t bytes = TEMP_FAILURE_RETRY(read(fd, e.bytes, sizeof(e)));
    if (bytes < 0) {
      return DartUtils::NewDartOSError();
    }
    size_t path_len = strlen(e.data.path);
    Dart_Handle event = Dart_NewList(4);
    int flags = e.data.flags;
    int mask = 0;
    if (flags & kFSEventStreamEventFlagItemModified) mask |= kModifyContent;
    if (flags & kFSEventStreamEventFlagItemRenamed) mask |= kMove;
    if (flags & kFSEventStreamEventFlagItemXattrMod) mask |= kModefyAttribute;
    if (flags & kFSEventStreamEventFlagItemCreated) mask |= kCreate;
    if (flags & kFSEventStreamEventFlagItemRemoved) {
      if (path_len == 0) {
        // The removed path is the path being watched.
        mask |= kDeleteSelf;
      } else {
        mask |= kDelete;
      }
    }
    Dart_ListSetAt(event, 0, Dart_NewInteger(mask));
    Dart_ListSetAt(event, 1, Dart_NewInteger(1));
    Dart_ListSetAt(event, 2, Dart_NewStringFromUTF8(
        reinterpret_cast<uint8_t*>(e.data.path), path_len));
    Dart_ListSetAt(event, 3, Dart_NewBoolean(true));
    Dart_ListSetAt(events, i, event);
  }
  return events;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_MACOS)


