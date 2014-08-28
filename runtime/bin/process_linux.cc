// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_LINUX)

#include "bin/process.h"

#include <errno.h>  // NOLINT
#include <fcntl.h>  // NOLINT
#include <poll.h>  // NOLINT
#include <stdio.h>  // NOLINT
#include <stdlib.h>  // NOLINT
#include <string.h>  // NOLINT
#include <sys/wait.h>  // NOLINT
#include <unistd.h>  // NOLINT

#include "platform/signal_blocker.h"
#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/thread.h"


extern char **environ;


namespace dart {
namespace bin {

// ProcessInfo is used to map a process id to the file descriptor for
// the pipe used to communicate the exit code of the process to Dart.
// ProcessInfo objects are kept in the static singly-linked
// ProcessInfoList.
class ProcessInfo {
 public:
  ProcessInfo(pid_t pid, intptr_t fd) : pid_(pid), fd_(fd) { }
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

    // Fork to wake up waitpid.
    if (TEMP_FAILURE_RETRY(fork()) == 0) {
      exit(0);
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
        while (running_ && process_count_ == 0) {
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
          int message[2] = { exit_code, negative };
          ssize_t result =
              FDUtils::WriteToBlocking(exit_code_fd, &message, sizeof(message));
          // If the process has been closed, the read end of the exit
          // pipe has been closed. It is therefore not a problem that
          // write fails with a broken pipe error. Other errors should
          // not happen.
          if (result != -1 && result != sizeof(message)) {
            FATAL("Failed to write entire process exit message");
          } else if (result == -1 && errno != EPIPE) {
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
};


bool ExitCodeHandler::running_ = false;
int ExitCodeHandler::process_count_ = 0;
bool ExitCodeHandler::terminate_done_ = false;
Monitor* ExitCodeHandler::monitor_ = new Monitor();


static void SetChildOsErrorMessage(char** os_error_message) {
  const int kBufferSize = 1024;
  char error_buf[kBufferSize];
  *os_error_message = strdup(strerror_r(errno, error_buf, kBufferSize));
}


static void ReportChildError(int exec_control_fd) {
  // In the case of failure in the child process write the errno and
  // the OS error message to the exec control pipe and exit.
  int child_errno = errno;
  const int kBufferSize = 1024;
  char error_buf[kBufferSize];
  char* os_error_message = strerror_r(errno, error_buf, kBufferSize);
  ASSERT(sizeof(child_errno) == sizeof(errno));
  int bytes_written =
      FDUtils::WriteToBlocking(
          exec_control_fd, &child_errno, sizeof(child_errno));
  if (bytes_written == sizeof(child_errno)) {
    FDUtils::WriteToBlocking(
        exec_control_fd, os_error_message, strlen(os_error_message) + 1);
  }
  VOID_TEMP_FAILURE_RETRY(close(exec_control_fd));
  exit(1);
}


int Process::Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   const char* working_directory,
                   char* environment[],
                   intptr_t environment_length,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_event,
                   char** os_error_message) {
  pid_t pid;
  int read_in[2];  // Pipe for stdout to child process.
  int read_err[2];  // Pipe for stderr to child process.
  int write_out[2];  // Pipe for stdin to child process.
  int exec_control[2];  // Pipe to get the result from exec.
  int result;

  result = pipe(read_in);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message);
    Log::PrintErr("Error pipe creation failed: %s\n", *os_error_message);
    return errno;
  }
  FDUtils::SetCloseOnExec(read_in[0]);

  result = pipe(read_err);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message);
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    Log::PrintErr("Error pipe creation failed: %s\n", *os_error_message);
    return errno;
  }
  FDUtils::SetCloseOnExec(read_err[0]);

  result = pipe(write_out);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message);
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));
    Log::PrintErr("Error pipe creation failed: %s\n", *os_error_message);
    return errno;
  }
  FDUtils::SetCloseOnExec(write_out[1]);

  result = pipe(exec_control);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message);
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[0]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[1]));
    Log::PrintErr("Error pipe creation failed: %s\n", *os_error_message);
    return errno;
  }
  FDUtils::SetCloseOnExec(exec_control[0]);
  FDUtils::SetCloseOnExec(exec_control[1]);

  if (result < 0) {
    SetChildOsErrorMessage(os_error_message);
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[0]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[1]));
    VOID_TEMP_FAILURE_RETRY(close(exec_control[0]));
    VOID_TEMP_FAILURE_RETRY(close(exec_control[1]));
    Log::PrintErr("fcntl failed: %s\n", *os_error_message);
    return errno;
  }

  char** program_arguments = new char*[arguments_length + 2];
  program_arguments[0] = const_cast<char*>(path);
  for (int i = 0; i < arguments_length; i++) {
    program_arguments[i + 1] = arguments[i];
  }
  program_arguments[arguments_length + 1] = NULL;

  char** program_environment = NULL;
  if (environment != NULL) {
    program_environment = new char*[environment_length + 1];
    for (int i = 0; i < environment_length; i++) {
      program_environment[i] = environment[i];
    }
    program_environment[environment_length] = NULL;
  }

  pid = TEMP_FAILURE_RETRY(fork());
  if (pid < 0) {
    SetChildOsErrorMessage(os_error_message);
    delete[] program_arguments;
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[0]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[1]));
    VOID_TEMP_FAILURE_RETRY(close(exec_control[0]));
    VOID_TEMP_FAILURE_RETRY(close(exec_control[1]));
    return errno;
  } else if (pid == 0) {
    // Wait for parent process before setting up the child process.
    char msg;
    int bytes_read = FDUtils::ReadFromBlocking(read_in[0], &msg, sizeof(msg));
    if (bytes_read != sizeof(msg)) {
      perror("Failed receiving notification message");
      exit(1);
    }

    VOID_TEMP_FAILURE_RETRY(close(write_out[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(exec_control[0]));

    if (TEMP_FAILURE_RETRY(dup2(write_out[0], STDIN_FILENO)) == -1) {
      ReportChildError(exec_control[1]);
    }
    VOID_TEMP_FAILURE_RETRY(close(write_out[0]));

    if (TEMP_FAILURE_RETRY(dup2(read_in[1], STDOUT_FILENO)) == -1) {
      ReportChildError(exec_control[1]);
    }
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));

    if (TEMP_FAILURE_RETRY(dup2(read_err[1], STDERR_FILENO)) == -1) {
      ReportChildError(exec_control[1]);
    }
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));

    if (working_directory != NULL && chdir(working_directory) == -1) {
      ReportChildError(exec_control[1]);
    }

    if (program_environment != NULL) {
      environ = program_environment;
    }

    execvp(path, const_cast<char* const*>(program_arguments));

    ReportChildError(exec_control[1]);
  }

  // Be sure to listen for exit-codes, now we have a child-process.
  ExitCodeHandler::ProcessStarted();

  // The arguments and environment for the spawned process are not needed
  // any longer.
  delete[] program_arguments;
  delete[] program_environment;

  int event_fds[2];
  result = pipe(event_fds);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message);
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[0]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[1]));
    Log::PrintErr("Error pipe creation failed: %s\n", *os_error_message);
    return errno;
  }
  FDUtils::SetCloseOnExec(event_fds[0]);
  FDUtils::SetCloseOnExec(event_fds[1]);

  ProcessInfoList::AddProcess(pid, event_fds[1]);
  *exit_event = event_fds[0];
  FDUtils::SetNonBlocking(event_fds[0]);

  // Notify child process to start.
  char msg = '1';
  result = FDUtils::WriteToBlocking(read_in[1], &msg, sizeof(msg));
  if (result != sizeof(msg)) {
    perror("Failed sending notification message");
  }

  // Read exec result from child. If no data is returned the exec was
  // successful and the exec call closed the pipe. Otherwise the errno
  // is written to the pipe.
  VOID_TEMP_FAILURE_RETRY(close(exec_control[1]));
  int child_errno;
  int bytes_read = -1;
  ASSERT(sizeof(child_errno) == sizeof(errno));
  bytes_read =
      FDUtils::ReadFromBlocking(
          exec_control[0], &child_errno, sizeof(child_errno));
  if (bytes_read == sizeof(child_errno)) {
    static const int kMaxMessageSize = 256;
    char* message = static_cast<char*>(malloc(kMaxMessageSize));
    bytes_read = FDUtils::ReadFromBlocking(exec_control[0],
                                           message,
                                           kMaxMessageSize);
    message[kMaxMessageSize - 1] = '\0';
    *os_error_message = message;
  }
  VOID_TEMP_FAILURE_RETRY(close(exec_control[0]));

  // Return error code if any failures.
  if (bytes_read != 0) {
    VOID_TEMP_FAILURE_RETRY(close(read_in[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[0]));
    VOID_TEMP_FAILURE_RETRY(close(read_err[1]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[0]));
    VOID_TEMP_FAILURE_RETRY(close(write_out[1]));

    // Since exec() failed, we're not interested in the exit code.
    // We close the reading side of the exit code pipe here.
    // GetProcessExitCodes will get a broken pipe error when it tries to write
    // to the writing side of the pipe and it will ignore the error.
    VOID_TEMP_FAILURE_RETRY(close(*exit_event));
    *exit_event = -1;

    if (bytes_read == -1) {
      return errno;  // Read failed.
    } else {
      return child_errno;  // Exec failed.
    }
  }

  FDUtils::SetNonBlocking(read_in[0]);
  *in = read_in[0];
  VOID_TEMP_FAILURE_RETRY(close(read_in[1]));
  FDUtils::SetNonBlocking(write_out[1]);
  *out = write_out[1];
  VOID_TEMP_FAILURE_RETRY(close(write_out[0]));
  FDUtils::SetNonBlocking(read_err[0]);
  *err = read_err[0];
  VOID_TEMP_FAILURE_RETRY(close(read_err[1]));

  *id = pid;
  return 0;
}


class BufferList: public BufferListBase {
 public:
  bool Read(int fd, intptr_t available) {
    // Read all available bytes.
    while (available > 0) {
      if (free_size_ == 0) Allocate();
      ASSERT(free_size_ > 0);
      ASSERT(free_size_ <= kBufferSize);
      intptr_t block_size = dart::Utils::Minimum(free_size_, available);
      intptr_t bytes = TEMP_FAILURE_RETRY(read(
          fd,
          reinterpret_cast<void*>(FreeSpaceAddress()),
          block_size));
      if (bytes < 0) return false;
      data_size_ += bytes;
      free_size_ -= bytes;
      available -= bytes;
    }
    return true;
  }
};


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
      if (fds[i].revents & POLLIN) {
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
            intptr_t b = TEMP_FAILURE_RETRY(read(exit_event,
                                                 exit_code_data.bytes, 8));
            if (b != 8) {
              return CloseProcessBuffers(fds);
            }
          }
        } else {
          UNREACHABLE();
        }
      }
      if (fds[i].revents & POLLHUP) {
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

  // Calculate the exit code.
  intptr_t exit_code = exit_code_data.ints[0];
  intptr_t negative = exit_code_data.ints[1];
  if (negative) exit_code = -exit_code;
  result->set_exit_code(exit_code);

  return true;
}


bool Process::Kill(intptr_t id, int signal) {
  return kill(id, signal) != -1;
}


void Process::TerminateExitCodeHandler() {
  ExitCodeHandler::TerminateExitCodeThread();
}


intptr_t Process::CurrentProcessId() {
  return static_cast<intptr_t>(getpid());
}


static Mutex* signal_mutex = new Mutex();
static SignalInfo* signal_handlers = NULL;
static const int kSignalsCount = 7;
static const int kSignals[kSignalsCount] = {
  SIGHUP,
  SIGINT,
  SIGTERM,
  SIGUSR1,
  SIGUSR2,
  SIGWINCH,
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
  if (!found) return -1;
  int fds[2];
  if (NO_RETRY_EXPECTED(pipe2(fds, O_CLOEXEC)) != 0) {
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
    int status = sigaction(signal, &act, NULL);
    if (status < 0) {
      int err = errno;
      VOID_TEMP_FAILURE_RETRY(close(fds[0]));
      VOID_TEMP_FAILURE_RETRY(close(fds[1]));
      errno = err;
      return -1;
    }
  }
  signal_handlers = new SignalInfo(fds[1], signal, signal_handlers);
  return fds[0];
}


void Process::ClearSignalHandler(intptr_t signal) {
  ThreadSignalBlocker blocker(kSignalsCount, kSignals);
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  bool unlisten = true;
  while (handler != NULL) {
    bool remove = false;
    if (handler->signal() == signal) {
      if (handler->port() == Dart_GetMainPortId()) {
        if (signal_handlers == handler) signal_handlers = handler->next();
        handler->Unlink();
        remove = true;
      } else {
        unlisten = false;
      }
    }
    SignalInfo* next = handler->next();
    if (remove) delete handler;
    handler = next;
  }
  if (unlisten) {
    struct sigaction act;
    bzero(&act, sizeof(act));
    act.sa_handler = SIG_DFL;
    sigaction(signal, &act, NULL);
  }
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_LINUX)
