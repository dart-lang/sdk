// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef RUNTIME_BIN_PROCESS_H_
#define RUNTIME_BIN_PROCESS_H_

#include <errno.h>

#include "bin/builtin.h"
#include "bin/io_buffer.h"
#include "bin/lockers.h"
#include "bin/thread.h"
#include "platform/globals.h"
#if !defined(HOST_OS_WINDOWS)
#include "platform/signal_blocker.h"
#endif
#include "platform/utils.h"

namespace dart {
namespace bin {

class ProcessResult {
 public:
  ProcessResult() : exit_code_(0) {}

  void set_stdout_data(Dart_Handle stdout_data) { stdout_data_ = stdout_data; }
  void set_stderr_data(Dart_Handle stderr_data) { stderr_data_ = stderr_data; }

  void set_exit_code(intptr_t exit_code) { exit_code_ = exit_code; }

  Dart_Handle stdout_data() { return stdout_data_; }
  Dart_Handle stderr_data() { return stderr_data_; }
  intptr_t exit_code() { return exit_code_; }

 private:
  Dart_Handle stdout_data_;
  Dart_Handle stderr_data_;
  intptr_t exit_code_;

  DISALLOW_ALLOCATION();
};

// To be kept in sync with ProcessSignal consts in sdk/lib/io/process.dart
// Note that this map is as on Linux.
enum ProcessSignals {
  kSighup = 1,
  kSigint = 2,
  kSigquit = 3,
  kSigill = 4,
  kSigtrap = 5,
  kSigabrt = 6,
  kSigbus = 7,
  kSigfpe = 8,
  kSigkill = 9,
  kSigusr1 = 10,
  kSigsegv = 11,
  kSigusr2 = 12,
  kSigpipe = 13,
  kSigalrm = 14,
  kSigterm = 15,
  kSigchld = 17,
  kSigcont = 18,
  kSigstop = 19,
  kSigtstp = 20,
  kSigttin = 21,
  kSigttou = 22,
  kSigurg = 23,
  kSigxcpu = 24,
  kSigxfsz = 25,
  kSigvtalrm = 26,
  kSigprof = 27,
  kSigwinch = 28,
  kSigpoll = 29,
  kSigsys = 31,
  kLastSignal = kSigsys,
};

// To be kept in sync with ProcessStartMode consts in sdk/lib/io/process.dart.
enum ProcessStartMode {
  kNormal = 0,
  kDetached = 1,
  kDetachedWithStdio = 2,
};

class Process {
 public:
  // Start a new process providing access to stdin, stdout, stderr and
  // process exit streams.
  static int Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   const char* working_directory,
                   char* environment[],
                   intptr_t environment_length,
                   ProcessStartMode mode,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_handler,
                   char** os_error_message);

  static bool Wait(intptr_t id,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_handler,
                   ProcessResult* result);

  // Kill a process with a given pid.
  static bool Kill(intptr_t id, int signal);

  // Terminate the exit code handler thread. Does not return before
  // the thread has terminated.
  static void TerminateExitCodeHandler();

  static int GlobalExitCode() {
    MutexLocker ml(global_exit_code_mutex_);
    return global_exit_code_;
  }

  static void SetGlobalExitCode(int exit_code) {
    MutexLocker ml(global_exit_code_mutex_);
    global_exit_code_ = exit_code;
  }

  typedef void (*ExitHook)(int64_t exit_code);
  static void SetExitHook(ExitHook hook) { exit_hook_ = hook; }
  static void RunExitHook(int64_t exit_code) {
    if (exit_hook_ != NULL) {
      exit_hook_(exit_code);
    }
  }

  static intptr_t CurrentProcessId();

  static intptr_t SetSignalHandler(intptr_t signal);
  // When there is a current Isolate and the 'port' argument is
  // Dart_GetMainPortId(), this clears the signal handler for the current
  // isolate. When 'port' is ILLEGAL_PORT, this clears all signal handlers for
  // 'signal' for all Isolates.
  static void ClearSignalHandler(intptr_t signal, Dart_Port port);
  static void ClearAllSignalHandlers();

  static Dart_Handle GetProcessIdNativeField(Dart_Handle process,
                                             intptr_t* pid);
  static Dart_Handle SetProcessIdNativeField(Dart_Handle process, intptr_t pid);

  static int64_t CurrentRSS();
  static int64_t MaxRSS();

 private:
  static int global_exit_code_;
  static Mutex* global_exit_code_mutex_;
  static ExitHook exit_hook_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Process);
};

class SignalInfo {
 public:
  SignalInfo(intptr_t fd, intptr_t signal, SignalInfo* next)
      : fd_(fd),
        signal_(signal),
        // SignalInfo is expected to be created when in a isolate.
        port_(Dart_GetMainPortId()),
        next_(next),
        prev_(NULL) {
    if (next_ != NULL) {
      next_->prev_ = this;
    }
  }

  ~SignalInfo();

  void Unlink() {
    if (prev_ != NULL) {
      prev_->next_ = next_;
    }
    if (next_ != NULL) {
      next_->prev_ = prev_;
    }
  }

  intptr_t fd() const { return fd_; }
  intptr_t signal() const { return signal_; }
  Dart_Port port() const { return port_; }
  SignalInfo* next() const { return next_; }

 private:
  intptr_t fd_;
  intptr_t signal_;
  // The port_ is used to identify what isolate the signal-info belongs to.
  Dart_Port port_;
  SignalInfo* next_;
  SignalInfo* prev_;

  DISALLOW_COPY_AND_ASSIGN(SignalInfo);
};

// Utility class for collecting the output when running a process
// synchronously by using Process::Wait. This class is sub-classed in
// the platform specific files to implement reading into the buffers
// allocated.
class BufferListBase {
 protected:
  static const intptr_t kBufferSize = 16 * 1024;

  class BufferListNode {
   public:
    explicit BufferListNode(intptr_t size) {
      data_ = new uint8_t[size];
      // We check for a failed allocation below in Allocate()
      next_ = NULL;
    }

    ~BufferListNode() { delete[] data_; }

    bool Valid() const { return data_ != NULL; }

    uint8_t* data() const { return data_; }
    BufferListNode* next() const { return next_; }
    void set_next(BufferListNode* n) { next_ = n; }

   private:
    uint8_t* data_;
    BufferListNode* next_;

    DISALLOW_IMPLICIT_CONSTRUCTORS(BufferListNode);
  };

 public:
  BufferListBase() : head_(NULL), tail_(NULL), data_size_(0), free_size_(0) {}
  ~BufferListBase() {
    Free();
    DEBUG_ASSERT(IsEmpty());
  }

  // Returns the collected data as a Uint8List. If an error occours an
  // error handle is returned.
  Dart_Handle GetData() {
    uint8_t* buffer;
    intptr_t buffer_position = 0;
    Dart_Handle result = IOBuffer::Allocate(data_size_, &buffer);
    if (Dart_IsError(result)) {
      Free();
      return result;
    }
    for (BufferListNode* current = head_; current != NULL;
         current = current->next()) {
      intptr_t to_copy = dart::Utils::Minimum(data_size_, kBufferSize);
      memmove(buffer + buffer_position, current->data(), to_copy);
      buffer_position += to_copy;
      data_size_ -= to_copy;
    }
    ASSERT(data_size_ == 0);
    Free();
    return result;
  }

#if defined(DEBUG)
  bool IsEmpty() const { return (head_ == NULL) && (tail_ == NULL); }
#endif

 protected:
  bool Allocate() {
    ASSERT(free_size_ == 0);
    BufferListNode* node = new BufferListNode(kBufferSize);
    if ((node == NULL) || !node->Valid()) {
      // Failed to allocate a buffer for the node.
      delete node;
      return false;
    }
    if (head_ == NULL) {
      head_ = node;
      tail_ = node;
    } else {
      ASSERT(tail_->next() == NULL);
      tail_->set_next(node);
      tail_ = node;
    }
    free_size_ = kBufferSize;
    return true;
  }

  void Free() {
    BufferListNode* current = head_;
    while (current != NULL) {
      BufferListNode* tmp = current;
      current = current->next();
      delete tmp;
    }
    head_ = NULL;
    tail_ = NULL;
    data_size_ = 0;
    free_size_ = 0;
  }

  // Returns the address of the first byte in the free space.
  uint8_t* FreeSpaceAddress() {
    return tail_->data() + (kBufferSize - free_size_);
  }

  intptr_t data_size() const { return data_size_; }
  void set_data_size(intptr_t size) { data_size_ = size; }

  intptr_t free_size() const { return free_size_; }
  void set_free_size(intptr_t size) { free_size_ = size; }

  BufferListNode* head() const { return head_; }
  BufferListNode* tail() const { return tail_; }

 private:
  // Linked list for data collected.
  BufferListNode* head_;
  BufferListNode* tail_;

  // Number of bytes of data collected in the linked list.
  intptr_t data_size_;

  // Number of free bytes in the last node in the list.
  intptr_t free_size_;

  DISALLOW_COPY_AND_ASSIGN(BufferListBase);
};

#if defined(HOST_OS_ANDROID) || defined(HOST_OS_FUCHSIA) ||                    \
    defined(HOST_OS_LINUX) || defined(HOST_OS_MACOS)
class BufferList : public BufferListBase {
 public:
  BufferList() {}

  bool Read(int fd, intptr_t available) {
    // Read all available bytes.
    while (available > 0) {
      if (free_size() == 0) {
        if (!Allocate()) {
          errno = ENOMEM;
          return false;
        }
      }
      ASSERT(free_size() > 0);
      ASSERT(free_size() <= kBufferSize);
      intptr_t block_size = dart::Utils::Minimum(free_size(), available);
#if defined(HOST_OS_FUCHSIA)
      intptr_t bytes = NO_RETRY_EXPECTED(
          read(fd, reinterpret_cast<void*>(FreeSpaceAddress()), block_size));
#else
      intptr_t bytes = TEMP_FAILURE_RETRY(
          read(fd, reinterpret_cast<void*>(FreeSpaceAddress()), block_size));
#endif  // defined(HOST_OS_FUCHSIA)
      if (bytes < 0) {
        return false;
      }
      set_data_size(data_size() + bytes);
      set_free_size(free_size() - bytes);
      available -= bytes;
    }
    return true;
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(BufferList);
};
#endif  // defined(HOST_OS_ANDROID) ...

}  // namespace bin
}  // namespace dart

#endif  // RUNTIME_BIN_PROCESS_H_
