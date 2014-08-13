// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_PROCESS_H_
#define BIN_PROCESS_H_

#include "bin/builtin.h"
#include "bin/io_buffer.h"
#include "bin/lockers.h"
#include "bin/thread.h"
#include "platform/globals.h"
#include "platform/utils.h"


namespace dart {
namespace bin {

class ProcessResult {
 public:
  ProcessResult() : exit_code_(0) {}

  void set_stdout_data(Dart_Handle stdout_data) {
    stdout_data_ = stdout_data;
  }
  void set_stderr_data(Dart_Handle stderr_data) {
    stderr_data_ = stderr_data;
  }

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
  kSigsys = 31
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

  static intptr_t CurrentProcessId();

  static intptr_t SetSignalHandler(intptr_t signal);
  static void ClearSignalHandler(intptr_t signal);

  static Dart_Handle GetProcessIdNativeField(Dart_Handle process,
                                             intptr_t* pid);
  static Dart_Handle SetProcessIdNativeField(Dart_Handle process,
                                             intptr_t pid);

 private:
  static int global_exit_code_;
  static dart::Mutex* global_exit_code_mutex_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(Process);
};


class SignalInfo {
 public:
  SignalInfo(int fd, int signal, SignalInfo* next)
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

  int fd() const { return fd_; }
  int signal() const { return signal_; }
  Dart_Port port() const { return port_; }
  SignalInfo* next() const { return next_; }

 private:
  int fd_;
  int signal_;
  // The port_ is used to identify what isolate the signal-info belongs to.
  Dart_Port port_;
  SignalInfo* next_;
  SignalInfo* prev_;
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
      if (data_ == NULL) FATAL("Allocation failed");
      next_ = NULL;
    }

    ~BufferListNode() {
      delete[] data_;
    }

    uint8_t* data_;
    BufferListNode* next_;

   private:
    DISALLOW_IMPLICIT_CONSTRUCTORS(BufferListNode);
  };

 public:
  BufferListBase() : head_(NULL), tail_(NULL), data_size_(0), free_size_(0) {}
  ~BufferListBase() {
    ASSERT(head_ == NULL);
    ASSERT(tail_ == NULL);
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
    for (BufferListNode* current = head_;
         current != NULL;
         current = current->next_) {
      intptr_t to_copy = dart::Utils::Minimum(data_size_, kBufferSize);
      memmove(buffer + buffer_position, current->data_, to_copy);
      buffer_position += to_copy;
      data_size_ -= to_copy;
    }
    ASSERT(data_size_ == 0);
    Free();
    return result;
  }

 protected:
  void Allocate() {
    ASSERT(free_size_ == 0);
    BufferListNode* node = new BufferListNode(kBufferSize);
    if (head_ == NULL) {
      head_ = node;
      tail_ = node;
    } else {
      ASSERT(tail_->next_ == NULL);
      tail_->next_ = node;
      tail_ = node;
    }
    free_size_ = kBufferSize;
  }

  void Free() {
    BufferListNode* current = head_;
    while (current != NULL) {
      BufferListNode* tmp = current;
      current = current->next_;
      delete tmp;
    }
    head_ = NULL;
    tail_ = NULL;
    data_size_ = 0;
    free_size_ = 0;
  }

  // Returns the address of the first byte in the free space.
  uint8_t* FreeSpaceAddress() {
    return tail_->data_ + (kBufferSize - free_size_);
  }

  // Linked list for data collected.
  BufferListNode* head_;
  BufferListNode* tail_;

  // Number of bytes of data collected in the linked list.
  intptr_t data_size_;

  // Number of free bytes in the last node in the list.
  intptr_t free_size_;
};

}  // namespace bin
}  // namespace dart

#endif  // BIN_PROCESS_H_
