// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/process.h"

#include <errno.h>
#include <fcntl.h>
#include <launchpad/launchpad.h>
#include <launchpad/vmo.h>
#include <magenta/process.h>
#include <magenta/status.h>
#include <magenta/syscalls.h>
#include <magenta/syscalls/object.h>
#include <magenta/types.h>
#include <mxio/private.h>
#include <mxio/util.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/epoll.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "platform/signal_blocker.h"
#include "platform/utils.h"

// #define PROCESS_LOGGING 1
#if defined(PROCESS_LOGGING)
#define LOG_ERR(msg, ...) Log::PrintErr("Dart Process: " msg, ##__VA_ARGS__)
#define LOG_INFO(msg, ...) Log::Print("Dart Process: " msg, ##__VA_ARGS__)
#else
#define LOG_ERR(msg, ...)
#define LOG_INFO(msg, ...)
#endif  // defined(PROCESS_LOGGING)

namespace dart {
namespace bin {

int Process::global_exit_code_ = 0;
Mutex* Process::global_exit_code_mutex_ = new Mutex();
Process::ExitHook Process::exit_hook_ = NULL;

// ProcessInfo is used to map a process id to the file descriptor for
// the pipe used to communicate the exit code of the process to Dart.
// ProcessInfo objects are kept in the static singly-linked
// ProcessInfoList.
class ProcessInfo {
 public:
  ProcessInfo(mx_handle_t process, intptr_t fd)
      : process_(process), exit_pipe_fd_(fd) {}
  ~ProcessInfo() {
    int closed = NO_RETRY_EXPECTED(close(exit_pipe_fd_));
    if (closed != 0) {
      FATAL("Failed to close process exit code pipe");
    }
    mx_handle_close(process_);
  }
  mx_handle_t process() const { return process_; }
  intptr_t exit_pipe_fd() const { return exit_pipe_fd_; }
  ProcessInfo* next() const { return next_; }
  void set_next(ProcessInfo* info) { next_ = info; }

 private:
  mx_handle_t process_;
  intptr_t exit_pipe_fd_;
  ProcessInfo* next_;

  DISALLOW_COPY_AND_ASSIGN(ProcessInfo);
};


// Singly-linked list of ProcessInfo objects for all active processes
// started from Dart.
class ProcessInfoList {
 public:
  static void AddProcess(mx_handle_t process, intptr_t fd) {
    MutexLocker locker(mutex_);
    ProcessInfo* info = new ProcessInfo(process, fd);
    info->set_next(active_processes_);
    active_processes_ = info;
  }

  static intptr_t LookupProcessExitFd(mx_handle_t process) {
    MutexLocker locker(mutex_);
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->process() == process) {
        return current->exit_pipe_fd();
      }
      current = current->next();
    }
    return 0;
  }

  static bool Exists(mx_handle_t process) {
    return LookupProcessExitFd(process) != 0;
  }

  static void RemoveProcess(mx_handle_t process) {
    MutexLocker locker(mutex_);
    ProcessInfo* prev = NULL;
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->process() == process) {
        if (prev == NULL) {
          active_processes_ = current->next();
        } else {
          prev->set_next(current->next());
        }
        delete current;
        return;
      }
      prev = current;
      current = current->next();
    }
  }

 private:
  // Linked list of ProcessInfo objects for all active processes
  // started from Dart code.
  static ProcessInfo* active_processes_;
  // Mutex protecting all accesses to the linked list of active
  // processes.
  static Mutex* mutex_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ProcessInfoList);
};

ProcessInfo* ProcessInfoList::active_processes_ = NULL;
Mutex* ProcessInfoList::mutex_ = new Mutex();

// The exit code handler sets up a separate thread which waits for child
// processes to terminate. That separate thread can then get the exit code from
// processes that have exited and communicate it to Dart through the
// event loop.
class ExitCodeHandler {
 public:
  // Notify the ExitCodeHandler that another process exists.
  static void Start() {
    // Multiple isolates could be starting processes at the same
    // time. Make sure that only one ExitCodeHandler thread exists.
    MonitorLocker locker(monitor_);
    if (running_) {
      return;
    }

    LOG_INFO("ExitCodeHandler Starting\n");

    mx_status_t status = mx_socket_create(0, &interrupt_in_, &interrupt_out_);
    if (status < 0) {
      FATAL1("Failed to create exit code handler interrupt socket: %s\n",
             mx_status_get_string(status));
    }

    // Start thread that handles process exits when wait returns.
    intptr_t result =
        Thread::Start(ExitCodeHandlerEntry, static_cast<uword>(interrupt_out_));
    if (result != 0) {
      FATAL1("Failed to start exit code handler worker thread %ld", result);
    }

    running_ = true;
  }

  static void Add(mx_handle_t process) {
    MonitorLocker locker(monitor_);
    LOG_INFO("ExitCodeHandler Adding Process: %ld\n", process);
    SendMessage(Message::kAdd, process);
  }

  static void Terminate() {
    MonitorLocker locker(monitor_);
    if (!running_) {
      return;
    }
    running_ = false;

    LOG_INFO("ExitCodeHandler Terminating\n");
    SendMessage(Message::kShutdown, MX_HANDLE_INVALID);

    while (!terminate_done_) {
      monitor_->Wait(Monitor::kNoTimeout);
    }
    mx_handle_close(interrupt_in_);
    LOG_INFO("ExitCodeHandler Terminated\n");
  }

 private:
  class Message {
   public:
    enum Command {
      kAdd,
      kShutdown,
    };
    Command command;
    mx_handle_t handle;
  };

  static void SendMessage(Message::Command command, mx_handle_t handle) {
    Message msg;
    msg.command = command;
    msg.handle = handle;
    size_t actual;
    mx_status_t status =
        mx_socket_write(interrupt_in_, 0, &msg, sizeof(msg), &actual);
    if (status < 0) {
      FATAL1("Write to exit handler interrupt handle failed: %s\n",
             mx_status_get_string(status));
    }
    ASSERT(actual == sizeof(msg));
  }

  // Entry point for the separate exit code handler thread started by
  // the ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    LOG_INFO("ExitCodeHandler Entering ExitCodeHandler thread\n");
    item_capacity_ = 16;
    items_ = reinterpret_cast<mx_wait_item_t*>(
        malloc(item_capacity_ * sizeof(*items_)));
    items_to_remove_ = reinterpret_cast<intptr_t*>(
        malloc(item_capacity_ * sizeof(*items_to_remove_)));

    // The interrupt handle is fixed to the first entry.
    items_[0].handle = interrupt_out_;
    items_[0].waitfor = MX_SOCKET_READABLE | MX_SOCKET_PEER_CLOSED;
    items_[0].pending = MX_SIGNAL_NONE;
    item_count_ = 1;

    while (!do_shutdown_) {
      LOG_INFO("ExitCodeHandler Calling mx_object_wait_many: %ld items\n",
               item_count_);
      mx_status_t status =
          mx_object_wait_many(items_, item_count_, MX_TIME_INFINITE);
      if (status < 0) {
        FATAL1("Exit code handler handle wait failed: %s\n",
               mx_status_get_string(status));
      }
      LOG_INFO("ExitCodeHandler mx_object_wait_many returned\n");

      bool have_interrupt = false;
      intptr_t remove_count = 0;
      for (intptr_t i = 0; i < item_count_; i++) {
        if (items_[i].pending == MX_SIGNAL_NONE) {
          continue;
        }
        if (i == 0) {
          LOG_INFO("ExitCodeHandler thread saw interrupt\n");
          have_interrupt = true;
          continue;
        }
        ASSERT(items_[i].waitfor == MX_TASK_TERMINATED);
        ASSERT((items_[i].pending & MX_TASK_TERMINATED) != 0);
        LOG_INFO("ExitCodeHandler signal for %ld\n", items_[i].handle);
        SendProcessStatus(items_[i].handle);
        items_to_remove_[remove_count++] = i;
      }
      for (intptr_t i = 0; i < remove_count; i++) {
        RemoveItem(items_to_remove_[i]);
      }
      if (have_interrupt) {
        HandleInterruptMsg();
      }
    }

    LOG_INFO("ExitCodeHandler thread shutting down\n");
    mx_handle_close(interrupt_out_);
    free(items_);
    items_ = NULL;
    free(items_to_remove_);
    items_to_remove_ = NULL;
    item_count_ = 0;
    item_capacity_ = 0;

    terminate_done_ = true;
    monitor_->Notify();
  }

  static void SendProcessStatus(mx_handle_t process) {
    LOG_INFO("ExitCodeHandler thread getting process status: %ld\n", process);
    mx_info_process_t proc_info;
    mx_status_t status = mx_object_get_info(
        process, MX_INFO_PROCESS, &proc_info, sizeof(proc_info), NULL, NULL);
    if (status < 0) {
      FATAL1("mx_object_get_info failed on process handle: %s\n",
             mx_status_get_string(status));
    }

    const int return_code = proc_info.return_code;
    status = mx_handle_close(process);
    if (status < 0) {
      FATAL1("Failed to close process handle: %s\n",
             mx_status_get_string(status));
    }
    LOG_INFO("ExitCodeHandler thread process %ld exited with %d\n", process,
             return_code);

    const intptr_t exit_code_fd = ProcessInfoList::LookupProcessExitFd(process);
    LOG_INFO("ExitCodeHandler thread sending %ld code %d on fd %ld\n", process,
             return_code, exit_code_fd);
    if (exit_code_fd != 0) {
      int exit_message[2];
      exit_message[0] = abs(return_code);
      exit_message[1] = return_code >= 0 ? 0 : 1;
      intptr_t result = FDUtils::WriteToBlocking(exit_code_fd, &exit_message,
                                                 sizeof(exit_message));
      ASSERT((result == -1) || (result == sizeof(exit_code_fd)));
      if ((result == -1) && (errno != EPIPE)) {
        int err = errno;
        FATAL1("Failed to write exit code to pipe: %d\n", err);
      }
      LOG_INFO("ExitCodeHandler thread wrote %ld bytes to fd %ld\n", result,
               exit_code_fd);
      LOG_INFO("ExitCodeHandler thread removing process %ld from list\n",
               process);
      ProcessInfoList::RemoveProcess(process);
    }
  }

  static void HandleInterruptMsg() {
    ASSERT(items_[0].handle == interrupt_out_);
    ASSERT(items_[0].waitfor == MX_SOCKET_READABLE);
    ASSERT((items_[0].pending & MX_SOCKET_READABLE) != 0);
    while (true) {
      Message msg;
      size_t actual = 0;
      LOG_INFO("ExitCodeHandler thread reading interrupt message\n");
      mx_status_t status =
          mx_socket_read(interrupt_out_, 0, &msg, sizeof(msg), &actual);
      if (status == MX_ERR_SHOULD_WAIT) {
        LOG_INFO("ExitCodeHandler thread done reading interrupt messages\n");
        return;
      }
      if (status < 0) {
        FATAL1("Failed to read exit handler interrupt handle: %s\n",
               mx_status_get_string(status));
      }
      if (actual < sizeof(msg)) {
        FATAL1("Short read from exit handler interrupt handle: %ld\n", actual);
      }
      switch (msg.command) {
        case Message::kShutdown:
          LOG_INFO("ExitCodeHandler thread got shutdown message\n");
          do_shutdown_ = true;
          break;
        case Message::kAdd:
          LOG_INFO("ExitCodeHandler thread got add message: %ld\n", msg.handle);
          AddItem(msg.handle);
          break;
      }
    }
  }

  static void AddItem(mx_handle_t h) {
    if (item_count_ == item_capacity_) {
      item_capacity_ = item_capacity_ + (item_capacity_ >> 1);
      items_ =
          reinterpret_cast<mx_wait_item_t*>(realloc(items_, item_capacity_));
      items_to_remove_ = reinterpret_cast<intptr_t*>(
          realloc(items_to_remove_, item_capacity_));
    }
    LOG_INFO("ExitCodeHandler thread adding item %ld at %ld\n", h, item_count_);
    items_[item_count_].handle = h;
    items_[item_count_].waitfor = MX_TASK_TERMINATED;
    items_[item_count_].pending = MX_SIGNAL_NONE;
    item_count_++;
  }

  static void RemoveItem(intptr_t idx) {
    LOG_INFO("ExitCodeHandler thread removing item %ld at %ld\n",
             items_[idx].handle, idx);
    ASSERT(idx != 0);
    const intptr_t last = item_count_ - 1;
    items_[idx].handle = MX_HANDLE_INVALID;
    items_[idx].waitfor = MX_SIGNAL_NONE;
    items_[idx].pending = MX_SIGNAL_NONE;
    if (idx != last) {
      items_[idx] = items_[last];
    }
    item_count_--;
  }

  // Interrupt channel.
  static mx_handle_t interrupt_in_;
  static mx_handle_t interrupt_out_;

  // Accessed only by the ExitCodeHandler thread.
  static mx_wait_item_t* items_;
  static intptr_t* items_to_remove_;
  static intptr_t item_count_;
  static intptr_t item_capacity_;

  // Protected by monitor_.
  static bool do_shutdown_;
  static bool terminate_done_;
  static bool running_;
  static Monitor* monitor_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ExitCodeHandler);
};

mx_handle_t ExitCodeHandler::interrupt_in_ = MX_HANDLE_INVALID;
mx_handle_t ExitCodeHandler::interrupt_out_ = MX_HANDLE_INVALID;
mx_wait_item_t* ExitCodeHandler::items_ = NULL;
intptr_t* ExitCodeHandler::items_to_remove_ = NULL;
intptr_t ExitCodeHandler::item_count_ = 0;
intptr_t ExitCodeHandler::item_capacity_ = 0;

bool ExitCodeHandler::do_shutdown_ = false;
bool ExitCodeHandler::running_ = false;
bool ExitCodeHandler::terminate_done_ = false;
Monitor* ExitCodeHandler::monitor_ = new Monitor();

void Process::TerminateExitCodeHandler() {
  ExitCodeHandler::Terminate();
}


intptr_t Process::CurrentProcessId() {
  return static_cast<intptr_t>(getpid());
}


int64_t Process::CurrentRSS() {
  mx_info_task_stats_t task_stats;
  mx_handle_t process = mx_process_self();
  mx_status_t status = mx_object_get_info(
      process, MX_INFO_TASK_STATS, &task_stats, sizeof(task_stats), NULL, NULL);
  if (status != MX_OK) {
    // TODO(zra): Translate this to a Unix errno.
    errno = status;
    return -1;
  }
  return task_stats.mem_private_bytes + task_stats.mem_shared_bytes;
}


int64_t Process::MaxRSS() {
  // There is currently no way to get the high watermark value on Fuchsia, so
  // just return the current RSS value.
  return CurrentRSS();
}


static bool ProcessWaitCleanup(intptr_t out,
                               intptr_t err,
                               intptr_t exit_event) {
  int e = errno;
  VOID_NO_RETRY_EXPECTED(close(out));
  VOID_NO_RETRY_EXPECTED(close(err));
  VOID_NO_RETRY_EXPECTED(close(exit_event));
  errno = e;
  return false;
}


class MxioWaitEntry {
 public:
  MxioWaitEntry() {}
  ~MxioWaitEntry() { Cancel(); }

  void Init(int fd) { mxio_ = __mxio_fd_to_io(fd); }

  void WaitBegin(mx_wait_item_t* wait_item) {
    if (mxio_ == NULL) {
      *wait_item = {};
      return;
    }

    __mxio_wait_begin(mxio_, EPOLLRDHUP | EPOLLIN, &wait_item->handle,
                      &wait_item->waitfor);
    wait_item->pending = 0;
  }

  void WaitEnd(mx_wait_item_t* wait_item, uint32_t* event) {
    if (mxio_ == NULL) {
      *event = 0;
      return;
    }
    __mxio_wait_end(mxio_, wait_item->pending, event);
  }

  void Cancel() {
    if (mxio_ != NULL) {
      __mxio_release(mxio_);
    }
    mxio_ = NULL;
  }

 private:
  mxio_t* mxio_ = NULL;

  DISALLOW_COPY_AND_ASSIGN(MxioWaitEntry);
};


bool Process::Wait(intptr_t pid,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_event,
                   ProcessResult* result) {
  VOID_NO_RETRY_EXPECTED(close(in));

  // There is no return from this function using Dart_PropagateError
  // as memory used by the buffer lists is freed through their
  // destructors.
  BufferList out_data;
  BufferList err_data;
  union {
    uint8_t bytes[8];
    int32_t ints[2];
  } exit_code_data;

  constexpr size_t kWaitItemsCount = 3;
  uint32_t events[kWaitItemsCount];
  mx_wait_item_t wait_items[kWaitItemsCount];
  size_t active = kWaitItemsCount;

  MxioWaitEntry entries[kWaitItemsCount];
  entries[0].Init(out);
  entries[1].Init(err);
  entries[2].Init(exit_event);

  while (active > 0) {
    for (size_t i = 0; i < kWaitItemsCount; ++i) {
      entries[i].WaitBegin(&wait_items[i]);
    }
    mx_object_wait_many(wait_items, kWaitItemsCount, MX_TIME_INFINITE);

    for (size_t i = 0; i < kWaitItemsCount; ++i) {
      entries[i].WaitEnd(&wait_items[i], &events[i]);
    }

    if ((events[0] & EPOLLIN) != 0) {
      const intptr_t avail = FDUtils::AvailableBytes(out);
      if (!out_data.Read(out, avail)) {
        return ProcessWaitCleanup(out, err, exit_event);
      }
    }
    if ((events[1] & EPOLLIN) != 0) {
      const intptr_t avail = FDUtils::AvailableBytes(err);
      if (!err_data.Read(err, avail)) {
        return ProcessWaitCleanup(out, err, exit_event);
      }
    }
    if ((events[2] & EPOLLIN) != 0) {
      const intptr_t avail = FDUtils::AvailableBytes(exit_event);
      if (avail == 8) {
        intptr_t b =
            NO_RETRY_EXPECTED(read(exit_event, exit_code_data.bytes, 8));
        if (b != 8) {
          return ProcessWaitCleanup(out, err, exit_event);
        }
      }
    }
    for (size_t i = 0; i < kWaitItemsCount; ++i) {
      if ((events[i] & EPOLLRDHUP) != 0) {
        active--;
        entries[i].Cancel();
      }
    }
  }

  // All handles closed and all data read.
  result->set_stdout_data(out_data.GetData());
  result->set_stderr_data(err_data.GetData());
  DEBUG_ASSERT(out_data.IsEmpty());
  DEBUG_ASSERT(err_data.IsEmpty());

  // Calculate the exit code.
  intptr_t exit_code = exit_code_data.ints[0];
  intptr_t negative = exit_code_data.ints[1];
  if (negative != 0) {
    exit_code = -exit_code;
  }
  result->set_exit_code(exit_code);

  // Close the process handle.
  mx_handle_t process = static_cast<mx_handle_t>(pid);
  mx_handle_close(process);
  return true;
}


bool Process::Kill(intptr_t id, int signal) {
  LOG_INFO("Sending signal %d to process with id %ld\n", signal, id);
  // mx_task_kill is definitely going to kill the process.
  if ((signal != SIGTERM) && (signal != SIGKILL)) {
    LOG_ERR("Signal %d not supported\n", signal);
    errno = ENOSYS;
    return false;
  }
  // We can only use mx_task_kill if we know id is a process handle, and we only
  // know that for sure if it's in our list.
  mx_handle_t process = static_cast<mx_handle_t>(id);
  if (!ProcessInfoList::Exists(process)) {
    LOG_ERR("Process %ld wasn't in the ProcessInfoList\n", id);
    errno = ESRCH;  // No such process.
    return false;
  }
  mx_status_t status = mx_task_kill(process);
  if (status != MX_OK) {
    LOG_ERR("mx_task_kill failed: %s\n", mx_status_get_string(status));
    errno = EPERM;  // TODO(zra): Figure out what it really should be.
    return false;
  }
  LOG_INFO("Signal %d sent successfully to process %ld\n", signal, id);
  return true;
}


class ProcessStarter {
 public:
  ProcessStarter(const char* path,
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
                 intptr_t* exit_event,
                 char** os_error_message)
      : path_(path),
        working_directory_(working_directory),
        mode_(mode),
        in_(in),
        out_(out),
        err_(err),
        id_(id),
        exit_event_(exit_event),
        os_error_message_(os_error_message) {
    LOG_INFO("ProcessStarter: ctor %s with %ld args, mode = %d\n", path,
             arguments_length, mode);

    read_in_ = -1;
    read_err_ = -1;
    write_out_ = -1;

    program_arguments_ = reinterpret_cast<char**>(Dart_ScopeAllocate(
        (arguments_length + 2) * sizeof(*program_arguments_)));
    program_arguments_[0] = const_cast<char*>(path_);
    for (int i = 0; i < arguments_length; i++) {
      program_arguments_[i + 1] = arguments[i];
    }
    program_arguments_[arguments_length + 1] = NULL;
    program_arguments_count_ = arguments_length + 1;

    program_environment_ = NULL;
    if (environment != NULL) {
      program_environment_ = reinterpret_cast<char**>(Dart_ScopeAllocate(
          (environment_length + 1) * sizeof(*program_environment_)));
      for (int i = 0; i < environment_length; i++) {
        program_environment_[i] = environment[i];
      }
      program_environment_[environment_length] = NULL;
    }
  }

  ~ProcessStarter() {
    if (read_in_ != -1) {
      close(read_in_);
    }
    if (read_err_ != -1) {
      close(read_err_);
    }
    if (write_out_ != -1) {
      close(write_out_);
    }
  }

  int Start() {
    LOG_INFO("ProcessStarter: Start()\n");
    int exit_pipe_fds[2];
    intptr_t result = NO_RETRY_EXPECTED(pipe(exit_pipe_fds));
    if (result != 0) {
      *os_error_message_ = DartUtils::ScopedCopyCString(
          "Failed to create exit code pipe for process start.");
      return result;
    }
    LOG_INFO("ProcessStarter: Start() set up exit_pipe_fds (%d, %d)\n",
             exit_pipe_fds[0], exit_pipe_fds[1]);

    // Set up a launchpad.
    launchpad_t* lp = NULL;
    mx_status_t status = SetupLaunchpad(&lp);
    if (status != MX_OK) {
      close(exit_pipe_fds[0]);
      close(exit_pipe_fds[1]);
      return status;
    }
    ASSERT(lp != NULL);

    // Launch it.
    LOG_INFO("ProcessStarter: Start() Calling launchpad_start\n");
    mx_handle_t process = MX_HANDLE_INVALID;
    const char* errormsg = NULL;
    status = launchpad_go(lp, &process, &errormsg);
    lp = NULL;  // launchpad_go() calls launchpad_destroy() on the launchpad.
    if (status < 0) {
      LOG_INFO("ProcessStarter: Start() launchpad_start failed\n");
      const intptr_t kMaxMessageSize = 256;
      close(exit_pipe_fds[0]);
      close(exit_pipe_fds[1]);
      char* message = DartUtils::ScopedCString(kMaxMessageSize);
      snprintf(message, kMaxMessageSize, "%s:%d: launchpad_start failed: %s\n",
               __FILE__, __LINE__, errormsg);
      *os_error_message_ = message;
      return status;
    }

    LOG_INFO("ProcessStarter: Start() adding %ld to list with exit_pipe %d\n",
             process, exit_pipe_fds[1]);
    ProcessInfoList::AddProcess(process, exit_pipe_fds[1]);
    ExitCodeHandler::Start();
    ExitCodeHandler::Add(process);

    *id_ = process;
    FDUtils::SetNonBlocking(read_in_);
    *in_ = read_in_;
    read_in_ = -1;
    FDUtils::SetNonBlocking(read_err_);
    *err_ = read_err_;
    read_err_ = -1;
    FDUtils::SetNonBlocking(write_out_);
    *out_ = write_out_;
    write_out_ = -1;
    FDUtils::SetNonBlocking(exit_pipe_fds[0]);
    *exit_event_ = exit_pipe_fds[0];
    return 0;
  }

 private:
#define CHECK_FOR_ERROR(status, msg)                                           \
  if (status < 0) {                                                            \
    const intptr_t kMaxMessageSize = 256;                                      \
    char* message = DartUtils::ScopedCString(kMaxMessageSize);                 \
    snprintf(message, kMaxMessageSize, "%s:%d: %s: %s\n", __FILE__, __LINE__,  \
             msg, mx_status_get_string(status));                               \
    *os_error_message_ = message;                                              \
    return status;                                                             \
  }

  mx_status_t SetupLaunchpad(launchpad_t** launchpad) {
    // Set up a vmo for the binary.
    mx_handle_t binary_vmo = launchpad_vmo_from_file(path_);
    CHECK_FOR_ERROR(binary_vmo, "launchpad_vmo_from_file");

    // Run the child process in the same "job".
    mx_handle_t job = MX_HANDLE_INVALID;
    mx_status_t status =
        mx_handle_duplicate(mx_job_default(), MX_RIGHT_SAME_RIGHTS, &job);
    if (status != MX_OK) {
      mx_handle_close(binary_vmo);
    }
    CHECK_FOR_ERROR(status, "mx_handle_duplicate");

    // Set up the launchpad.
    launchpad_t* lp = NULL;
    launchpad_create(job, program_arguments_[0], &lp);
    launchpad_set_args(lp, program_arguments_count_, program_arguments_);
    launchpad_set_environ(lp, program_environment_);
    launchpad_clone(lp, LP_CLONE_MXIO_ROOT);
    // TODO(zra): Use the supplied working directory when launchpad adds an
    // API to set it.
    launchpad_clone(lp, LP_CLONE_MXIO_CWD);
    launchpad_add_pipe(lp, &write_out_, 0);
    launchpad_add_pipe(lp, &read_in_, 1);
    launchpad_add_pipe(lp, &read_err_, 2);
    launchpad_add_vdso_vmo(lp);
    launchpad_elf_load(lp, binary_vmo);
    launchpad_load_vdso(lp, MX_HANDLE_INVALID);
    *launchpad = lp;
    return MX_OK;
  }

#undef CHECK_FOR_ERROR

  int read_in_;    // Pipe for stdout to child process.
  int read_err_;   // Pipe for stderr to child process.
  int write_out_;  // Pipe for stdin to child process.

  char** program_arguments_;
  intptr_t program_arguments_count_;
  char** program_environment_;

  const char* path_;
  const char* working_directory_;
  ProcessStartMode mode_;
  intptr_t* in_;
  intptr_t* out_;
  intptr_t* err_;
  intptr_t* id_;
  intptr_t* exit_event_;
  char** os_error_message_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ProcessStarter);
};


int Process::Start(const char* path,
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
                   intptr_t* exit_event,
                   char** os_error_message) {
  if (mode != kNormal) {
    *os_error_message = DartUtils::ScopedCopyCString(
        "Only ProcessStartMode.NORMAL is supported on this platform");
    return -1;
  }
  ProcessStarter starter(path, arguments, arguments_length, working_directory,
                         environment, environment_length, mode, in, out, err,
                         id, exit_event, os_error_message);
  return starter.Start();
}

intptr_t Process::SetSignalHandler(intptr_t signal) {
  errno = ENOSYS;
  return -1;
}

void Process::ClearSignalHandler(intptr_t signal) {}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)

#endif  // !defined(DART_IO_DISABLED)
