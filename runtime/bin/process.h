// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef BIN_PROCESS_H_
#define BIN_PROCESS_H_

#include "bin/builtin.h"
#include "bin/io_buffer.h"
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
