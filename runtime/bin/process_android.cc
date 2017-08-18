// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#if !defined(DART_IO_DISABLED)

#include "platform/globals.h"
#if defined(HOST_OS_ANDROID)

#include "bin/process.h"

#include <errno.h>     // NOLINT
#include <fcntl.h>     // NOLINT
#include <poll.h>      // NOLINT
#include <stdio.h>     // NOLINT
#include <stdlib.h>    // NOLINT
#include <string.h>    // NOLINT
#include <sys/wait.h>  // NOLINT
#include <unistd.h>    // NOLINT

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/file.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/reference_counting.h"
#include "bin/thread.h"

#include "platform/signal_blocker.h"
#include "platform/utils.h"

extern char** environ;

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
  ProcessInfo(pid_t pid, intptr_t fd) : pid_(pid), fd_(fd) {}
  ~ProcessInfo() {
    int closed = TEMP_FAILURE_RETRY(close(fd_));
    if (closed != 0) {
      FATAL("Failed to close process exit code pipe");
    }
  }
  pid_t pid() { return pid_; }
  intptr_t fd() { return fd_; }
  ProcessInfo* next() { return next_; }
  void set_next(ProcessInfo* info) { next_ = info; }

 private:
  pid_t pid_;
  intptr_t fd_;
  ProcessInfo* next_;

  DISALLOW_COPY_AND_ASSIGN(ProcessInfo);
};

// Singly-linked list of ProcessInfo objects for all active processes
// started from Dart.
class ProcessInfoList {
 public:
  static void AddProcess(pid_t pid, intptr_t fd) {
    MutexLocker locker(mutex_);
    ProcessInfo* info = new ProcessInfo(pid, fd);
    info->set_next(active_processes_);
    active_processes_ = info;
  }

  static intptr_t LookupProcessExitFd(pid_t pid) {
    MutexLocker locker(mutex_);
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->pid() == pid) {
        return current->fd();
      }
      current = current->next();
    }
    return 0;
  }

  static void RemoveProcess(pid_t pid) {
    MutexLocker locker(mutex_);
    ProcessInfo* prev = NULL;
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->pid() == pid) {
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
  static void ProcessStarted() {
    // Multiple isolates could be starting processes at the same
    // time. Make sure that only one ExitCodeHandler thread exists.
    MonitorLocker locker(monitor_);
    process_count_++;

    monitor_->Notify();

    if (running_) {
      return;
    }

    // Start thread that handles process exits when wait returns.
    int result = Thread::Start(ExitCodeHandlerEntry, 0);
    if (result != 0) {
      FATAL1("Failed to start exit code handler worker thread %d", result);
    }

    running_ = true;
  }

  static void TerminateExitCodeThread() {
    MonitorLocker locker(monitor_);

    if (!running_) {
      return;
    }

    // Set terminate_done_ to false, so we can use it as a guard for our
    // monitor.
    running_ = false;

    // Wake up the [ExitCodeHandler] thread which is blocked on `wait()` (see
    // [ExitCodeHandlerEntry]).
    if (TEMP_FAILURE_RETRY(fork()) == 0) {
      // We avoid running through registered atexit() handlers because that is
      // unnecessary work.
      _exit(0);
    }

    monitor_->Notify();

    while (!terminate_done_) {
      monitor_->Wait(Monitor::kNoTimeout);
    }
  }

 private:
  // Entry point for the separate exit code handler thread started by
  // the ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    pid_t pid = 0;
    int status = 0;
    while (true) {
      {
        MonitorLocker locker(monitor_);
        while (running_ && (process_count_ == 0)) {
          monitor_->Wait(Monitor::kNoTimeout);
        }
        if (!running_) {
          terminate_done_ = true;
          monitor_->Notify();
          return;
        }
      }

      if ((pid = TEMP_FAILURE_RETRY(wait(&status))) > 0) {
        int exit_code = 0;
        int negative = 0;
        if (WIFEXITED(status)) {
          exit_code = WEXITSTATUS(status);
        }
        if (WIFSIGNALED(status)) {
          exit_code = WTERMSIG(status);
          negative = 1;
        }
        intptr_t exit_code_fd = ProcessInfoList::LookupProcessExitFd(pid);
        if (exit_code_fd != 0) {
          int message[2] = {exit_code, negative};
          ssize_t result =
              FDUtils::WriteToBlocking(exit_code_fd, &message, sizeof(message));
          // If the process has been closed, the read end of the exit
          // pipe has been closed. It is therefore not a problem that
          // write fails with a broken pipe error. Other errors should
          // not happen.
          if ((result != -1) && (result != sizeof(message))) {
            FATAL("Failed to write entire process exit message");
          } else if ((result == -1) && (errno != EPIPE)) {
            FATAL1("Failed to write exit code: %d", errno);
          }
          ProcessInfoList::RemoveProcess(pid);
          {
            MonitorLocker locker(monitor_);
            process_count_--;
          }
        }
      }
    }
  }

  static bool terminate_done_;
  static int process_count_;
  static bool running_;
  static Monitor* monitor_;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ExitCodeHandler);
};

bool ExitCodeHandler::running_ = false;
int ExitCodeHandler::process_count_ = 0;
bool ExitCodeHandler::terminate_done_ = false;
Monitor* ExitCodeHandler::monitor_ = new Monitor();

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
    read_in_[0] = -1;
    read_in_[1] = -1;
    read_err_[0] = -1;
    read_err_[1] = -1;
    write_out_[0] = -1;
    write_out_[1] = -1;
    exec_control_[0] = -1;
    exec_control_[1] = -1;

    program_arguments_ = reinterpret_cast<char**>(Dart_ScopeAllocate(
        (arguments_length + 2) * sizeof(*program_arguments_)));
    program_arguments_[0] = const_cast<char*>(path_);
    for (int i = 0; i < arguments_length; i++) {
      program_arguments_[i + 1] = arguments[i];
    }
    program_arguments_[arguments_length + 1] = NULL;

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

  int Start() {
    // Create pipes required.
    int err = CreatePipes();
    if (err != 0) {
      return err;
    }

    // Fork to create the new process.
    pid_t pid = TEMP_FAILURE_RETRY(fork());
    if (pid < 0) {
      // Failed to fork.
      return CleanupAndReturnError();
    } else if (pid == 0) {
      // This runs in the new process.
      NewProcess();
    }

    // This runs in the original process.

    // Be sure to listen for exit-codes, now we have a child-process.
    ExitCodeHandler::ProcessStarted();

    // Register the child process if not detached.
    if (mode_ == kNormal) {
      err = RegisterProcess(pid);
      if (err != 0) {
        return err;
      }
    }

    // Notify child process to start. This is done to delay the call to exec
    // until the process is registered above, and we are ready to receive the
    // exit code.
    char msg = '1';
    int bytes_written =
        FDUtils::WriteToBlocking(read_in_[1], &msg, sizeof(msg));
    if (bytes_written != sizeof(msg)) {
      return CleanupAndReturnError();
    }

    // Read the result of executing the child process.
    VOID_TEMP_FAILURE_RETRY(close(exec_control_[1]));
    exec_control_[1] = -1;
    if (mode_ == kNormal) {
      err = ReadExecResult();
    } else {
      err = ReadDetachedExecResult(&pid);
    }
    VOID_TEMP_FAILURE_RETRY(close(exec_control_[0]));
    exec_control_[0] = -1;

    // Return error code if any failures.
    if (err != 0) {
      if (mode_ == kNormal) {
        // Since exec() failed, we're not interested in the exit code.
        // We close the reading side of the exit code pipe here.
        // GetProcessExitCodes will get a broken pipe error when it
        // tries to write to the writing side of the pipe and it will
        // ignore the error.
        VOID_TEMP_FAILURE_RETRY(close(*exit_event_));
        *exit_event_ = -1;
      }
      CloseAllPipes();
      return err;
    }

    if (mode_ != kDetached) {
      // Connect stdio, stdout and stderr.
      FDUtils::SetNonBlocking(read_in_[0]);
      *in_ = read_in_[0];
      VOID_TEMP_FAILURE_RETRY(close(read_in_[1]));
      FDUtils::SetNonBlocking(write_out_[1]);
      *out_ = write_out_[1];
      VOID_TEMP_FAILURE_RETRY(close(write_out_[0]));
      FDUtils::SetNonBlocking(read_err_[0]);
      *err_ = read_err_[0];
      VOID_TEMP_FAILURE_RETRY(close(read_err_[1]));
    } else {
      // Close all fds.
      VOID_TEMP_FAILURE_RETRY(close(read_in_[0]));
      VOID_TEMP_FAILURE_RETRY(close(read_in_[1]));
      ASSERT(write_out_[0] == -1);
      ASSERT(write_out_[1] == -1);
      ASSERT(read_err_[0] == -1);
      ASSERT(read_err_[1] == -1);
    }
    ASSERT(exec_control_[0] == -1);
    ASSERT(exec_control_[1] == -1);

    *id_ = pid;
    return 0;
  }

 private:
  int CreatePipes() {
    int result;
    result = TEMP_FAILURE_RETRY(pipe2(exec_control_, O_CLOEXEC));
    if (result < 0) {
      return CleanupAndReturnError();
    }

    // For a detached process the pipe to connect stdout is still used for
    // signaling when to do the first fork.
    result = TEMP_FAILURE_RETRY(pipe2(read_in_, O_CLOEXEC));
    if (result < 0) {
      return CleanupAndReturnError();
    }

    // For detached processes the pipe to connect stderr and stdin are not used.
    if (mode_ != kDetached) {
      result = TEMP_FAILURE_RETRY(pipe2(read_err_, O_CLOEXEC));
      if (result < 0) {
        return CleanupAndReturnError();
      }

      result = TEMP_FAILURE_RETRY(pipe2(write_out_, O_CLOEXEC));
      if (result < 0) {
        return CleanupAndReturnError();
      }
    }

    return 0;
  }

  void NewProcess() {
    // Wait for parent process before setting up the child process.
    char msg;
    int bytes_read = FDUtils::ReadFromBlocking(read_in_[0], &msg, sizeof(msg));
    if (bytes_read != sizeof(msg)) {
      perror("Failed receiving notification message");
      exit(1);
    }
    if (mode_ == kNormal) {
      ExecProcess();
    } else {
      ExecDetachedProcess();
    }
  }

  void ExecProcess() {
    if (TEMP_FAILURE_RETRY(dup2(write_out_[0], STDIN_FILENO)) == -1) {
      ReportChildError();
    }

    if (TEMP_FAILURE_RETRY(dup2(read_in_[1], STDOUT_FILENO)) == -1) {
      ReportChildError();
    }

    if (TEMP_FAILURE_RETRY(dup2(read_err_[1], STDERR_FILENO)) == -1) {
      ReportChildError();
    }

    if (working_directory_ != NULL &&
        TEMP_FAILURE_RETRY(chdir(working_directory_)) == -1) {
      ReportChildError();
    }

    if (program_environment_ != NULL) {
      environ = program_environment_;
    }

    VOID_TEMP_FAILURE_RETRY(
        execvp(path_, const_cast<char* const*>(program_arguments_)));

    ReportChildError();
  }

  void ExecDetachedProcess() {
    if (mode_ == kDetached) {
      ASSERT(write_out_[0] == -1);
      ASSERT(write_out_[1] == -1);
      ASSERT(read_err_[0] == -1);
      ASSERT(read_err_[1] == -1);
      // For a detached process the pipe to connect stdout is only used for
      // signaling when to do the first fork.
      VOID_TEMP_FAILURE_RETRY(close(read_in_[0]));
      read_in_[0] = -1;
      VOID_TEMP_FAILURE_RETRY(close(read_in_[1]));
      read_in_[1] = -1;
    } else {
      // Don't close any fds if keeping stdio open to the detached process.
      ASSERT(mode_ == kDetachedWithStdio);
    }
    // Fork once more to start a new session.
    pid_t pid = TEMP_FAILURE_RETRY(fork());
    if (pid < 0) {
      ReportChildError();
    } else if (pid == 0) {
      // Start a new session.
      if (TEMP_FAILURE_RETRY(setsid()) == -1) {
        ReportChildError();
      } else {
        // Do a final fork to not be the session leader.
        pid = TEMP_FAILURE_RETRY(fork());
        if (pid < 0) {
          ReportChildError();
        } else if (pid == 0) {
          if (mode_ == kDetached) {
            SetupDetached();
          } else {
            SetupDetachedWithStdio();
          }

          if ((working_directory_ != NULL) &&
              (TEMP_FAILURE_RETRY(chdir(working_directory_)) == -1)) {
            ReportChildError();
          }

          // Report the final PID and do the exec.
          ReportPid(getpid());  // getpid cannot fail.
          VOID_TEMP_FAILURE_RETRY(
              execvp(path_, const_cast<char* const*>(program_arguments_)));
          ReportChildError();
        } else {
          // Exit the intermediate process.
          exit(0);
        }
      }
    } else {
      // Exit the intermediate process.
      exit(0);
    }
  }

  int RegisterProcess(pid_t pid) {
    int result;
    int event_fds[2];
    result = TEMP_FAILURE_RETRY(pipe2(event_fds, O_CLOEXEC));
    if (result < 0) {
      return CleanupAndReturnError();
    }

    ProcessInfoList::AddProcess(pid, event_fds[1]);
    *exit_event_ = event_fds[0];
    FDUtils::SetNonBlocking(event_fds[0]);
    return 0;
  }

  int ReadExecResult() {
    int child_errno;
    int bytes_read = -1;
    // Read exec result from child. If no data is returned the exec was
    // successful and the exec call closed the pipe. Otherwise the errno
    // is written to the pipe.
    bytes_read = FDUtils::ReadFromBlocking(exec_control_[0], &child_errno,
                                           sizeof(child_errno));
    if (bytes_read == sizeof(child_errno)) {
      ReadChildError();
      return child_errno;
    } else if (bytes_read == -1) {
      return errno;
    }
    return 0;
  }

  int ReadDetachedExecResult(pid_t* pid) {
    int child_errno;
    int bytes_read = -1;
    // Read exec result from child. If only pid data is returned the exec was
    // successful and the exec call closed the pipe. Otherwise the errno
    // is written to the pipe as well.
    int result[2];
    bytes_read =
        FDUtils::ReadFromBlocking(exec_control_[0], result, sizeof(result));
    if (bytes_read == sizeof(int)) {
      *pid = result[0];
    } else if (bytes_read == 2 * sizeof(int)) {
      *pid = result[0];
      child_errno = result[1];
      ReadChildError();
      return child_errno;
    } else if (bytes_read == -1) {
      return errno;
    }
    return 0;
  }

  void SetupDetached() {
    ASSERT(mode_ == kDetached);

    // Close all open file descriptors except for exec_control_[1].
    int max_fds = sysconf(_SC_OPEN_MAX);
    if (max_fds == -1) {
      max_fds = _POSIX_OPEN_MAX;
    }
    for (int fd = 0; fd < max_fds; fd++) {
      if (fd != exec_control_[1]) {
        VOID_TEMP_FAILURE_RETRY(close(fd));
      }
    }

    // Re-open stdin, stdout and stderr and connect them to /dev/null.
    // The loop above should already have closed all of them, so
    // creating new file descriptors should start at STDIN_FILENO.
    int fd = TEMP_FAILURE_RETRY(open("/dev/null", O_RDWR));
    if (fd != STDIN_FILENO) {
      ReportChildError();
    }
    if (TEMP_FAILURE_RETRY(dup2(STDIN_FILENO, STDOUT_FILENO)) !=
        STDOUT_FILENO) {
      ReportChildError();
    }
    if (TEMP_FAILURE_RETRY(dup2(STDIN_FILENO, STDERR_FILENO)) !=
        STDERR_FILENO) {
      ReportChildError();
    }
  }

  void SetupDetachedWithStdio() {
    // Close all open file descriptors except for
    // exec_control_[1], write_out_[0], read_in_[1] and
    // read_err_[1].
    int max_fds = sysconf(_SC_OPEN_MAX);
    if (max_fds == -1) {
      max_fds = _POSIX_OPEN_MAX;
    }
    for (int fd = 0; fd < max_fds; fd++) {
      if ((fd != exec_control_[1]) && (fd != write_out_[0]) &&
          (fd != read_in_[1]) && (fd != read_err_[1])) {
        VOID_TEMP_FAILURE_RETRY(close(fd));
      }
    }

    if (TEMP_FAILURE_RETRY(dup2(write_out_[0], STDIN_FILENO)) == -1) {
      ReportChildError();
    }
    VOID_TEMP_FAILURE_RETRY(close(write_out_[0]));

    if (TEMP_FAILURE_RETRY(dup2(read_in_[1], STDOUT_FILENO)) == -1) {
      ReportChildError();
    }
    VOID_TEMP_FAILURE_RETRY(close(read_in_[1]));

    if (TEMP_FAILURE_RETRY(dup2(read_err_[1], STDERR_FILENO)) == -1) {
      ReportChildError();
    }
    VOID_TEMP_FAILURE_RETRY(close(read_err_[1]));
  }

  int CleanupAndReturnError() {
    int actual_errno = errno;
    // If CleanupAndReturnError is called without an actual errno make
    // sure to return an error anyway.
    if (actual_errno == 0) {
      actual_errno = EPERM;
    }
    SetChildOsErrorMessage();
    CloseAllPipes();
    return actual_errno;
  }

  void SetChildOsErrorMessage() {
    const int kBufferSize = 1024;
    char* error_message = DartUtils::ScopedCString(kBufferSize);
    Utils::StrError(errno, error_message, kBufferSize);
    *os_error_message_ = error_message;
  }

  void ReportChildError() {
    // In the case of failure in the child process write the errno and
    // the OS error message to the exec control pipe and exit.
    int child_errno = errno;
    const int kBufferSize = 1024;
    char os_error_message[kBufferSize];
    Utils::StrError(errno, os_error_message, kBufferSize);
    int bytes_written = FDUtils::WriteToBlocking(exec_control_[1], &child_errno,
                                                 sizeof(child_errno));
    if (bytes_written == sizeof(child_errno)) {
      FDUtils::WriteToBlocking(exec_control_[1], os_error_message,
                               strlen(os_error_message) + 1);
    }
    VOID_TEMP_FAILURE_RETRY(close(exec_control_[1]));

    // We avoid running through registered atexit() handlers because that is
    // unnecessary work.
    _exit(1);
  }

  void ReportPid(int pid) {
    // In the case of starting a detached process the actual pid of that process
    // is communicated using the exec control pipe.
    int bytes_written =
        FDUtils::WriteToBlocking(exec_control_[1], &pid, sizeof(pid));
    ASSERT(bytes_written == sizeof(int));
    USE(bytes_written);
  }

  void ReadChildError() {
    const int kMaxMessageSize = 256;
    char* message = DartUtils::ScopedCString(kMaxMessageSize);
    if (message != NULL) {
      FDUtils::ReadFromBlocking(exec_control_[0], message, kMaxMessageSize);
      message[kMaxMessageSize - 1] = '\0';
      *os_error_message_ = message;
    } else {
      // Could not get error message. It will be NULL.
      ASSERT(*os_error_message_ == NULL);
    }
  }

  void ClosePipe(int* fds) {
    for (int i = 0; i < 2; i++) {
      if (fds[i] != -1) {
        VOID_TEMP_FAILURE_RETRY(close(fds[i]));
        fds[i] = -1;
      }
    }
  }

  void CloseAllPipes() {
    ClosePipe(exec_control_);
    ClosePipe(read_in_);
    ClosePipe(read_err_);
    ClosePipe(write_out_);
  }

  int read_in_[2];       // Pipe for stdout to child process.
  int read_err_[2];      // Pipe for stderr to child process.
  int write_out_[2];     // Pipe for stdin to child process.
  int exec_control_[2];  // Pipe to get the result from exec.

  char** program_arguments_;
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
  ProcessStarter starter(path, arguments, arguments_length, working_directory,
                         environment, environment_length, mode, in, out, err,
                         id, exit_event, os_error_message);
  return starter.Start();
}

static bool CloseProcessBuffers(struct pollfd fds[3]) {
  int e = errno;
  VOID_TEMP_FAILURE_RETRY(close(fds[0].fd));
  VOID_TEMP_FAILURE_RETRY(close(fds[1].fd));
  VOID_TEMP_FAILURE_RETRY(close(fds[2].fd));
  errno = e;
  return false;
}

bool Process::Wait(intptr_t pid,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_event,
                   ProcessResult* result) {
  // Close input to the process right away.
  VOID_TEMP_FAILURE_RETRY(close(in));

  // There is no return from this function using Dart_PropagateError
  // as memory used by the buffer lists is freed through their
  // destructors.
  BufferList out_data;
  BufferList err_data;
  union {
    uint8_t bytes[8];
    int32_t ints[2];
  } exit_code_data;

  struct pollfd fds[3];
  fds[0].fd = out;
  fds[1].fd = err;
  fds[2].fd = exit_event;

  for (int i = 0; i < 3; i++) {
    fds[i].events = POLLIN;
  }

  int alive = 3;
  while (alive > 0) {
    // Blocking call waiting for events from the child process.
    if (TEMP_FAILURE_RETRY(poll(fds, alive, -1)) <= 0) {
      return CloseProcessBuffers(fds);
    }

    // Process incoming data.
    int current_alive = alive;
    for (int i = 0; i < current_alive; i++) {
      if ((fds[i].revents & POLLIN) != 0) {
        intptr_t avail = FDUtils::AvailableBytes(fds[i].fd);
        if (fds[i].fd == out) {
          if (!out_data.Read(out, avail)) {
            return CloseProcessBuffers(fds);
          }
        } else if (fds[i].fd == err) {
          if (!err_data.Read(err, avail)) {
            return CloseProcessBuffers(fds);
          }
        } else if (fds[i].fd == exit_event) {
          if (avail == 8) {
            intptr_t b =
                TEMP_FAILURE_RETRY(read(exit_event, exit_code_data.bytes, 8));
            if (b != 8) {
              return CloseProcessBuffers(fds);
            }
          }
        } else {
          UNREACHABLE();
        }
      }
      if ((fds[i].revents & POLLHUP) != 0) {
        VOID_TEMP_FAILURE_RETRY(close(fds[i].fd));
        alive--;
        if (i < alive) {
          fds[i] = fds[alive];
        }
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

  return true;
}

bool Process::Kill(intptr_t id, int signal) {
  return (TEMP_FAILURE_RETRY(kill(id, signal)) != -1);
}

void Process::TerminateExitCodeHandler() {
  ExitCodeHandler::TerminateExitCodeThread();
}

intptr_t Process::CurrentProcessId() {
  return static_cast<intptr_t>(getpid());
}

static void SaveErrorAndClose(FILE* file) {
  int actual_errno = errno;
  fclose(file);
  errno = actual_errno;
}

int64_t Process::CurrentRSS() {
  // The second value in /proc/self/statm is the current RSS in pages.
  // It is not possible to use getrusage() because the interested fields are not
  // implemented by the linux kernel.
  FILE* statm = fopen("/proc/self/statm", "r");
  if (statm == NULL) {
    return -1;
  }
  int64_t current_rss_pages = 0;
  int matches = fscanf(statm, "%*s%" Pd64 "", &current_rss_pages);
  if (matches != 1) {
    SaveErrorAndClose(statm);
    return -1;
  }
  fclose(statm);
  return current_rss_pages * getpagesize();
}

int64_t Process::MaxRSS() {
  struct rusage usage;
  usage.ru_maxrss = 0;
  int r = getrusage(RUSAGE_SELF, &usage);
  if (r < 0) {
    return -1;
  }
  return usage.ru_maxrss * KB;
}

static Mutex* signal_mutex = new Mutex();
static SignalInfo* signal_handlers = NULL;
static const int kSignalsCount = 7;
static const int kSignals[kSignalsCount] = {
    SIGHUP, SIGINT, SIGTERM, SIGUSR1, SIGUSR2, SIGWINCH,
    SIGQUIT  // Allow VMService to listen on SIGQUIT.
};

SignalInfo::~SignalInfo() {
  VOID_TEMP_FAILURE_RETRY(close(fd_));
}

static void SignalHandler(int signal) {
  MutexLocker lock(signal_mutex);
  const SignalInfo* handler = signal_handlers;
  while (handler != NULL) {
    if (handler->signal() == signal) {
      int value = 0;
      VOID_TEMP_FAILURE_RETRY(write(handler->fd(), &value, 1));
    }
    handler = handler->next();
  }
}

intptr_t Process::SetSignalHandler(intptr_t signal) {
  bool found = false;
  for (int i = 0; i < kSignalsCount; i++) {
    if (kSignals[i] == signal) {
      found = true;
      break;
    }
  }
  if (!found) {
    return -1;
  }
  int fds[2];
  if (NO_RETRY_EXPECTED(pipe2(fds, O_CLOEXEC)) != 0) {
    return -1;
  }
  if (!FDUtils::SetNonBlocking(fds[0])) {
    VOID_TEMP_FAILURE_RETRY(close(fds[0]));
    VOID_TEMP_FAILURE_RETRY(close(fds[1]));
    return -1;
  }
  ThreadSignalBlocker blocker(kSignalsCount, kSignals);
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  bool listen = true;
  while (handler != NULL) {
    if (handler->signal() == signal) {
      listen = false;
      break;
    }
    handler = handler->next();
  }
  if (listen) {
    struct sigaction act;
    bzero(&act, sizeof(act));
    act.sa_handler = SignalHandler;
    sigemptyset(&act.sa_mask);
    for (int i = 0; i < kSignalsCount; i++) {
      sigaddset(&act.sa_mask, kSignals[i]);
    }
    int status = NO_RETRY_EXPECTED(sigaction(signal, &act, NULL));
    if (status < 0) {
      VOID_TEMP_FAILURE_RETRY(close(fds[0]));
      VOID_TEMP_FAILURE_RETRY(close(fds[1]));
      return -1;
    }
  }
  signal_handlers = new SignalInfo(fds[1], signal, signal_handlers);
  return fds[0];
}

void Process::ClearSignalHandler(intptr_t signal, Dart_Port port) {
  // Either the port is illegal or there is no current isolate, but not both.
  ASSERT((port != ILLEGAL_PORT) || (Dart_CurrentIsolate() == NULL));
  ASSERT((port == ILLEGAL_PORT) || (Dart_CurrentIsolate() != NULL));
  ThreadSignalBlocker blocker(kSignalsCount, kSignals);
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  bool unlisten = true;
  while (handler != NULL) {
    bool remove = false;
    if (handler->signal() == signal) {
      if ((port == ILLEGAL_PORT) || (handler->port() == port)) {
        if (signal_handlers == handler) {
          signal_handlers = handler->next();
        }
        handler->Unlink();
        remove = true;
      } else {
        unlisten = false;
      }
    }
    SignalInfo* next = handler->next();
    if (remove) {
      delete handler;
    }
    handler = next;
  }
  if (unlisten) {
    struct sigaction act;
    bzero(&act, sizeof(act));
    act.sa_handler = SIG_DFL;
    VOID_NO_RETRY_EXPECTED(sigaction(signal, &act, NULL));
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(HOST_OS_ANDROID)

#endif  // !defined(DART_IO_DISABLED)
