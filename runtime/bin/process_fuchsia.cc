// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(HOST_OS_FUCHSIA)

#include "bin/process.h"

#include <errno.h>
#include <fcntl.h>
#include <launchpad/launchpad.h>
#include <launchpad/vmo.h>
#include <zircon/process.h>
#include <zircon/status.h>
#include <zircon/syscalls.h>
#include <zircon/syscalls/object.h>
#include <zircon/types.h>
#include <fdio/io.h>
#include <fdio/namespace.h>
#include <fdio/private.h>
#include <fdio/util.h>
#include <poll.h>
#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/eventhandler.h"
#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/namespace.h"
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
  ProcessInfo(zx_handle_t process, intptr_t fd)
      : process_(process), exit_pipe_fd_(fd) {}
  ~ProcessInfo() {
    int closed = NO_RETRY_EXPECTED(close(exit_pipe_fd_));
    if (closed != 0) {
      LOG_ERR("Failed to close process exit code pipe");
    }
    zx_handle_close(process_);
  }
  zx_handle_t process() const { return process_; }
  intptr_t exit_pipe_fd() const { return exit_pipe_fd_; }
  ProcessInfo* next() const { return next_; }
  void set_next(ProcessInfo* info) { next_ = info; }

 private:
  zx_handle_t process_;
  intptr_t exit_pipe_fd_;
  ProcessInfo* next_;

  DISALLOW_COPY_AND_ASSIGN(ProcessInfo);
};

// Singly-linked list of ProcessInfo objects for all active processes
// started from Dart.
class ProcessInfoList {
 public:
  static void AddProcess(zx_handle_t process, intptr_t fd) {
    MutexLocker locker(mutex_);
    ProcessInfo* info = new ProcessInfo(process, fd);
    info->set_next(active_processes_);
    active_processes_ = info;
  }

  static intptr_t LookupProcessExitFd(zx_handle_t process) {
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

  static bool Exists(zx_handle_t process) {
    return LookupProcessExitFd(process) != 0;
  }

  static void RemoveProcess(zx_handle_t process) {
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

    zx_status_t status = zx_port_create(0, &port_);
    if (status != ZX_OK) {
      FATAL1("ExitCodeHandler: zx_port_create failed: %s\n",
             zx_status_get_string(status));
      return;
    }

    // Start thread that handles process exits when wait returns.
    intptr_t result = Thread::Start(ExitCodeHandlerEntry, 0);
    if (result != 0) {
      FATAL1("Failed to start exit code handler worker thread %ld", result);
    }

    running_ = true;
  }

  static zx_status_t Add(zx_handle_t process) {
    MonitorLocker locker(monitor_);
    LOG_INFO("ExitCodeHandler Adding Process: %ld\n", process);
    return zx_object_wait_async(process, port_, static_cast<uint64_t>(process),
                                ZX_TASK_TERMINATED, ZX_WAIT_ASYNC_ONCE);
  }

  static void Terminate() {
    MonitorLocker locker(monitor_);
    if (!running_) {
      return;
    }
    running_ = false;

    LOG_INFO("ExitCodeHandler Terminating\n");
    SendShutdownMessage();

    while (!terminate_done_) {
      monitor_->Wait(Monitor::kNoTimeout);
    }
    zx_handle_close(port_);
    LOG_INFO("ExitCodeHandler Terminated\n");
  }

 private:
  static const uint64_t kShutdownPacketKey = 1;

  static void SendShutdownMessage() {
    zx_port_packet_t pkt;
    pkt.key = kShutdownPacketKey;
    zx_status_t status = zx_port_queue(port_, reinterpret_cast<void*>(&pkt), 0);
    if (status != ZX_OK) {
      Log::PrintErr("ExitCodeHandler: zx_port_queue failed: %s\n",
                    zx_status_get_string(status));
    }
  }

  // Entry point for the separate exit code handler thread started by
  // the ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    LOG_INFO("ExitCodeHandler Entering ExitCodeHandler thread\n");

    zx_port_packet_t pkt;
    while (true) {
      zx_status_t status = zx_port_wait(port_, ZX_TIME_INFINITE,
                                        reinterpret_cast<void*>(&pkt), 0);
      if (status != ZX_OK) {
        FATAL1("ExitCodeHandler: zx_port_wait failed: %s\n",
               zx_status_get_string(status));
      }
      if (pkt.type == ZX_PKT_TYPE_USER) {
        ASSERT(pkt.key == kShutdownPacketKey);
        break;
      }
      zx_handle_t process = static_cast<zx_handle_t>(pkt.key);
      zx_signals_t observed = pkt.signal.observed;
      if ((observed & ZX_TASK_TERMINATED) == ZX_SIGNAL_NONE) {
        LOG_ERR("ExitCodeHandler: Unexpected signals, process %ld: %lx\n",
                process, observed);
      }
      SendProcessStatus(process);
    }

    LOG_INFO("ExitCodeHandler thread shutting down\n");
    terminate_done_ = true;
    monitor_->Notify();
  }

  static void SendProcessStatus(zx_handle_t process) {
    LOG_INFO("ExitCodeHandler thread getting process status: %ld\n", process);
    int return_code = -1;
    zx_info_process_t proc_info;
    zx_status_t status = zx_object_get_info(
        process, ZX_INFO_PROCESS, &proc_info, sizeof(proc_info), NULL, NULL);
    if (status != ZX_OK) {
      Log::PrintErr("ExitCodeHandler: zx_object_get_info failed: %s\n",
                    zx_status_get_string(status));
    } else {
      return_code = proc_info.return_code;
    }
    zx_handle_close(process);
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
        Log::PrintErr("Failed to write exit code for process %ld: errno=%d\n",
                      process, err);
      }
      LOG_INFO("ExitCodeHandler thread wrote %ld bytes to fd %ld\n", result,
               exit_code_fd);
      LOG_INFO("ExitCodeHandler thread removing process %ld from list\n",
               process);
      ProcessInfoList::RemoveProcess(process);
    } else {
      LOG_ERR("ExitCodeHandler: Process %ld not found\n", process);
    }
  }

  static zx_handle_t port_;

  // Protected by monitor_.
  static bool terminate_done_;
  static bool running_;
  static Monitor* monitor_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ExitCodeHandler);
};

zx_handle_t ExitCodeHandler::port_ = ZX_HANDLE_INVALID;
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
  zx_info_task_stats_t task_stats;
  zx_handle_t process = zx_process_self();
  zx_status_t status = zx_object_get_info(
      process, ZX_INFO_TASK_STATS, &task_stats, sizeof(task_stats), NULL, NULL);
  if (status != ZX_OK) {
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

class IOHandleScope {
 public:
  explicit IOHandleScope(IOHandle* io_handle) : io_handle_(io_handle) {}
  ~IOHandleScope() {
    io_handle_->Close();
    io_handle_->Release();
  }

 private:
  IOHandle* io_handle_;

  DISALLOW_ALLOCATION();
  DISALLOW_COPY_AND_ASSIGN(IOHandleScope);
};

bool Process::Wait(intptr_t pid,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_event,
                   ProcessResult* result) {
  // input not needed.
  IOHandle* in_iohandle = reinterpret_cast<IOHandle*>(in);
  in_iohandle->Close();
  in_iohandle->Release();
  in_iohandle = NULL;

  IOHandle* out_iohandle = reinterpret_cast<IOHandle*>(out);
  IOHandle* err_iohandle = reinterpret_cast<IOHandle*>(err);
  IOHandle* exit_iohandle = reinterpret_cast<IOHandle*>(exit_event);
  IOHandleScope out_ioscope(out_iohandle);
  IOHandleScope err_ioscope(err_iohandle);
  IOHandleScope exit_ioscope(exit_iohandle);

  // There is no return from this function using Dart_PropagateError
  // as memory used by the buffer lists is freed through their
  // destructors.
  BufferList out_data;
  BufferList err_data;
  union {
    uint8_t bytes[8];
    int32_t ints[2];
  } exit_code_data;

  // Create a port, which is like an epoll() fd on Linux.
  zx_handle_t port;
  zx_status_t status = zx_port_create(0, &port);
  if (status != ZX_OK) {
    Log::PrintErr("Process::Wait: zx_port_create failed: %s\n",
                  zx_status_get_string(status));
    return false;
  }

  IOHandle* out_tmp = out_iohandle;
  IOHandle* err_tmp = err_iohandle;
  IOHandle* exit_tmp = exit_iohandle;
  const uint64_t out_key = reinterpret_cast<uint64_t>(out_tmp);
  const uint64_t err_key = reinterpret_cast<uint64_t>(err_tmp);
  const uint64_t exit_key = reinterpret_cast<uint64_t>(exit_tmp);
  const uint32_t events = POLLRDHUP | POLLIN;
  if (!out_tmp->AsyncWait(port, events, out_key)) {
    return false;
  }
  if (!err_tmp->AsyncWait(port, events, err_key)) {
    return false;
  }
  if (!exit_tmp->AsyncWait(port, events, exit_key)) {
    return false;
  }
  while ((out_tmp != NULL) || (err_tmp != NULL) || (exit_tmp != NULL)) {
    zx_port_packet_t pkt;
    status =
        zx_port_wait(port, ZX_TIME_INFINITE, reinterpret_cast<void*>(&pkt), 0);
    if (status != ZX_OK) {
      Log::PrintErr("Process::Wait: zx_port_wait failed: %s\n",
                    zx_status_get_string(status));
      return false;
    }
    IOHandle* event_handle = reinterpret_cast<IOHandle*>(pkt.key);
    const intptr_t event_mask = event_handle->WaitEnd(pkt.signal.observed);
    if (event_handle == out_tmp) {
      if ((event_mask & POLLIN) != 0) {
        const intptr_t avail = FDUtils::AvailableBytes(out_tmp->fd());
        if (!out_data.Read(out_tmp->fd(), avail)) {
          return false;
        }
      }
      if ((event_mask & POLLRDHUP) != 0) {
        out_tmp->CancelWait(port, out_key);
        out_tmp = NULL;
      }
    } else if (event_handle == err_tmp) {
      if ((event_mask & POLLIN) != 0) {
        const intptr_t avail = FDUtils::AvailableBytes(err_tmp->fd());
        if (!err_data.Read(err_tmp->fd(), avail)) {
          return false;
        }
      }
      if ((event_mask & POLLRDHUP) != 0) {
        err_tmp->CancelWait(port, err_key);
        err_tmp = NULL;
      }
    } else if (event_handle == exit_tmp) {
      if ((event_mask & POLLIN) != 0) {
        const intptr_t avail = FDUtils::AvailableBytes(exit_tmp->fd());
        if (avail == 8) {
          intptr_t b =
              NO_RETRY_EXPECTED(read(exit_tmp->fd(), exit_code_data.bytes, 8));
          if (b != 8) {
            return false;
          }
        }
      }
      if ((event_mask & POLLRDHUP) != 0) {
        exit_tmp->CancelWait(port, exit_key);
        exit_tmp = NULL;
      }
    } else {
      Log::PrintErr("Process::Wait: Unexpected wait key: %p\n", event_handle);
    }
    if (out_tmp != NULL) {
      if (!out_tmp->AsyncWait(port, events, out_key)) {
        return false;
      }
    }
    if (err_tmp != NULL) {
      if (!err_tmp->AsyncWait(port, events, err_key)) {
        return false;
      }
    }
    if (exit_tmp != NULL) {
      if (!exit_tmp->AsyncWait(port, events, exit_key)) {
        return false;
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
  zx_handle_t process = static_cast<zx_handle_t>(pid);
  zx_handle_close(process);
  return true;
}

bool Process::Kill(intptr_t id, int signal) {
  LOG_INFO("Sending signal %d to process with id %ld\n", signal, id);
  // zx_task_kill is definitely going to kill the process.
  if ((signal != SIGTERM) && (signal != SIGKILL)) {
    LOG_ERR("Signal %d not supported\n", signal);
    errno = ENOSYS;
    return false;
  }
  // We can only use zx_task_kill if we know id is a process handle, and we only
  // know that for sure if it's in our list.
  zx_handle_t process = static_cast<zx_handle_t>(id);
  if (!ProcessInfoList::Exists(process)) {
    LOG_ERR("Process %ld wasn't in the ProcessInfoList\n", id);
    errno = ESRCH;  // No such process.
    return false;
  }
  zx_status_t status = zx_task_kill(process);
  if (status != ZX_OK) {
    LOG_ERR("zx_task_kill failed: %s\n", zx_status_get_string(status));
    errno = EPERM;  // TODO(zra): Figure out what it really should be.
    return false;
  }
  LOG_INFO("Signal %d sent successfully to process %ld\n", signal, id);
  return true;
}

class ProcessStarter {
 public:
  ProcessStarter(Namespace* namespc,
                 const char* path,
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
      : namespc_(namespc),
        path_(path),
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
    zx_status_t status = SetupLaunchpad(&lp);
    if (status != ZX_OK) {
      close(exit_pipe_fds[0]);
      close(exit_pipe_fds[1]);
      return status;
    }
    ASSERT(lp != NULL);

    // Launch it.
    LOG_INFO("ProcessStarter: Start() Calling launchpad_start\n");
    zx_handle_t process = ZX_HANDLE_INVALID;
    const char* errormsg = NULL;
    status = launchpad_go(lp, &process, &errormsg);
    lp = NULL;  // launchpad_go() calls launchpad_destroy() on the launchpad.
    if (status != ZX_OK) {
      LOG_ERR("ProcessStarter: Start() launchpad_start failed\n");
      close(exit_pipe_fds[0]);
      close(exit_pipe_fds[1]);
      ReportStartError(errormsg);
      return status;
    }

    LOG_INFO("ProcessStarter: Start() adding %ld to list with exit_pipe %d\n",
             process, exit_pipe_fds[1]);
    ProcessInfoList::AddProcess(process, exit_pipe_fds[1]);
    ExitCodeHandler::Start();
    status = ExitCodeHandler::Add(process);
    if (status != ZX_OK) {
      LOG_ERR("ProcessStarter: ExitCodeHandler: Add failed: %s\n",
              zx_status_get_string(status));
      close(exit_pipe_fds[0]);
      close(exit_pipe_fds[1]);
      zx_task_kill(process);
      ProcessInfoList::RemoveProcess(process);
      ReportStartError(zx_status_get_string(status));
      return status;
    }

    // The IOHandles allocated below are returned to Dart code. The Dart code
    // calls into the runtime again to allocate a C++ Socket object, which
    // becomes the native field of a Dart _NativeSocket object. The C++ Socket
    // object and the EventHandler manage the lifetime of these IOHandles.
    *id_ = process;
    FDUtils::SetNonBlocking(read_in_);
    *in_ = reinterpret_cast<intptr_t>(new IOHandle(read_in_));
    read_in_ = -1;
    FDUtils::SetNonBlocking(read_err_);
    *err_ = reinterpret_cast<intptr_t>(new IOHandle(read_err_));
    read_err_ = -1;
    FDUtils::SetNonBlocking(write_out_);
    *out_ = reinterpret_cast<intptr_t>(new IOHandle(write_out_));
    write_out_ = -1;
    FDUtils::SetNonBlocking(exit_pipe_fds[0]);
    *exit_event_ = reinterpret_cast<intptr_t>(new IOHandle(exit_pipe_fds[0]));
    return 0;
  }

 private:
  void ReportStartError(const char* errormsg) {
    const intptr_t kMaxMessageSize = 256;
    char* message = DartUtils::ScopedCString(kMaxMessageSize);
    snprintf(message, kMaxMessageSize, "Process start failed: %s\n", errormsg);
    *os_error_message_ = message;
  }

  zx_status_t SetupLaunchpad(launchpad_t** launchpad) {
    // TODO(zra): Use the supplied working directory when launchpad adds an
    // API to set it.
    ASSERT(launchpad != NULL);
    launchpad_t* lp = NULL;
    launchpad_create(ZX_HANDLE_INVALID, program_arguments_[0], &lp);
    launchpad_set_args(lp, program_arguments_count_, program_arguments_);
    launchpad_set_environ(lp, program_environment_);
    launchpad_clone(lp, LP_CLONE_FDIO_NAMESPACE | LP_CLONE_FDIO_CWD);
    launchpad_add_pipe(lp, &write_out_, 0);
    launchpad_add_pipe(lp, &read_in_, 1);
    launchpad_add_pipe(lp, &read_err_, 2);
    launchpad_add_vdso_vmo(lp);

    NamespaceScope ns(namespc_, path_);
    const int pathfd =
        TEMP_FAILURE_RETRY(openat64(ns.fd(), ns.path(), O_RDONLY));
    launchpad_load_from_fd(lp, pathfd);
    VOID_TEMP_FAILURE_RETRY(close(pathfd));

    // If there were any errors, grab launchpad's error message and put it in
    // the os_error_message_ field.
    zx_status_t status = launchpad_get_status(lp);
    if (status != ZX_OK) {
      const intptr_t kMaxMessageSize = 256;
      char* message = DartUtils::ScopedCString(kMaxMessageSize);
      snprintf(message, kMaxMessageSize, "launchpad failed: %s, %s",
               zx_status_get_string(status), launchpad_error_message(lp));
      *os_error_message_ = message;
      return status;
    }

    *launchpad = lp;
    return ZX_OK;
  }

  int read_in_;    // Pipe for stdout to child process.
  int read_err_;   // Pipe for stderr to child process.
  int write_out_;  // Pipe for stdin to child process.

  char** program_arguments_;
  intptr_t program_arguments_count_;
  char** program_environment_;

  Namespace* namespc_;
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

int Process::Start(Namespace* namespc,
                   const char* path,
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
  ProcessStarter starter(namespc, path, arguments, arguments_length,
                         working_directory, environment, environment_length,
                         mode, in, out, err, id, exit_event, os_error_message);
  return starter.Start();
}

intptr_t Process::SetSignalHandler(intptr_t signal) {
  errno = ENOSYS;
  return -1;
}

void Process::ClearSignalHandler(intptr_t signal, Dart_Port port) {}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_FUCHSIA)
