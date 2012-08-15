// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/process.h"

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

#include "bin/fdutils.h"
#include "bin/thread.h"


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
    MutexLocker locker(&mutex_);
    ProcessInfo* info = new ProcessInfo(pid, fd);
    info->set_next(active_processes_);
    active_processes_ = info;
  }


  static intptr_t LookupProcessExitFd(pid_t pid) {
    MutexLocker locker(&mutex_);
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
    MutexLocker locker(&mutex_);
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
  static dart::Mutex mutex_;
};


ProcessInfo* ProcessInfoList::active_processes_ = NULL;
dart::Mutex ProcessInfoList::mutex_;


// The exit code handler sets up a separate thread which is signalled
// on SIGCHLD. That separate thread can then get the exit code from
// processes that have exited and communicate it to Dart through the
// event loop.
class ExitCodeHandler {
 public:
  // Ensure that the ExitCodeHandler has been initialized.
  static bool EnsureInitialized() {
    // Multiple isolates could be starting processes at the same
    // time. Make sure that only one of them initializes the
    // ExitCodeHandler.
    MutexLocker locker(&mutex_);
    if (initialized_) {
      return true;
    }

    // Allocate a pipe that the signal handler can write a byte to and
    // that the exit handler thread can poll.
    int result = TEMP_FAILURE_RETRY(pipe(sig_chld_fds_));
    if (result < 0) {
      return false;
    }

    // Start thread that polls the pipe and handles process exits when
    // data is received on the pipe.
    result = dart::Thread::Start(ExitCodeHandlerEntry, sig_chld_fds_[0]);
    if (result != 0) {
      FATAL1("Failed to start exit code handler worker thread %d", result);
    }

    // Mark write end non-blocking.
    FDUtils::SetNonBlocking(sig_chld_fds_[1]);

    // Thread started and the ExitCodeHandler is initialized.
    initialized_ = true;
    return true;
  }

  // Get the write end of the pipe.
  static int WakeUpFd() {
    ASSERT(initialized_);
    return sig_chld_fds_[1];
  }

  static void TerminateExitCodeThread() {
    MutexLocker locker(&mutex_);
    if (!initialized_) {
      return;
    }

    uint8_t data = kThreadTerminateByte;
    ssize_t result =
        TEMP_FAILURE_RETRY(write(ExitCodeHandler::WakeUpFd(), &data, 1));
    if (result < 1) {
      perror("Failed to write to wake-up fd to terminate exit code thread");
    }

    {
      MonitorLocker terminate_locker(&thread_terminate_monitor_);
      while (!thread_terminated_) {
        terminate_locker.Wait();
      }
    }
  }

  static void ExitCodeThreadTerminated() {
    MonitorLocker locker(&thread_terminate_monitor_);
    thread_terminated_ = true;
    locker.Notify();
  }

 private:
  static const uint8_t kThreadTerminateByte = 1;

  // GetProcessExitCodes is called on a separate thread when a SIGCHLD
  // signal is received to retrieve the exit codes and post them to
  // dart.
  static void GetProcessExitCodes() {
    pid_t pid = 0;
    int status = 0;
    while ((pid = TEMP_FAILURE_RETRY(waitpid(-1, &status, WNOHANG))) > 0) {
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
      }
    }
  }


  // Entry point for the separate exit code handler thread started by
  // the ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    struct pollfd pollfds;
    pollfds.fd = param;
    pollfds.events = POLLIN;
    while (true) {
      int result = TEMP_FAILURE_RETRY(poll(&pollfds, 1, -1));
      if (result == -1) {
        ASSERT(EAGAIN == EWOULDBLOCK);
        if (errno != EWOULDBLOCK) {
          perror("ExitCodeHandler poll failed");
        }
      } else {
        // Read the byte from the wake-up fd.
        ASSERT(result = 1);
        intptr_t data = 0;
        ssize_t read_bytes = FDUtils::ReadFromBlocking(pollfds.fd, &data, 1);
        if (read_bytes < 1) {
          perror("Failed to read from wake-up fd in exit-code handler");
        }
        if (data == ExitCodeHandler::kThreadTerminateByte) {
          ExitCodeThreadTerminated();
          return;
        }
        // Get the exit code from all processes that have died.
        GetProcessExitCodes();
      }
    }
  }

  static dart::Mutex mutex_;
  static bool initialized_;
  static int sig_chld_fds_[2];
  static bool thread_terminated_;
  static dart::Monitor thread_terminate_monitor_;
};


dart::Mutex ExitCodeHandler::mutex_;
bool ExitCodeHandler::initialized_ = false;
int ExitCodeHandler::sig_chld_fds_[2] = { 0, 0 };
bool ExitCodeHandler::thread_terminated_ = false;
dart::Monitor ExitCodeHandler::thread_terminate_monitor_;


static char* SafeStrNCpy(char* dest, const char* src, size_t n) {
  strncpy(dest, src, n);
  dest[n - 1] = '\0';
  return dest;
}


static void SetChildOsErrorMessage(char* os_error_message,
                                   int os_error_message_len) {
  SafeStrNCpy(os_error_message, strerror(errno), os_error_message_len);
}


static void SigChldHandler(int process_signal, siginfo_t* siginfo, void* tmp) {
  // Save errno so it can be restored at the end.
  int entry_errno = errno;
  // Signal the exit code handler where the actual processing takes
  // place.
  ssize_t result =
      TEMP_FAILURE_RETRY(write(ExitCodeHandler::WakeUpFd(), "", 1));
  if (result < 1) {
    perror("Failed to write to wake-up fd in SIGCHLD handler");
  }
  // Restore errno.
  errno = entry_errno;
}


static void ReportChildError(int exec_control_fd) {
  // In the case of failure in the child process write the errno and
  // the OS error message to the exec control pipe and exit.
  int child_errno = errno;
  char* os_error_message = strerror(errno);
  ASSERT(sizeof(child_errno) == sizeof(errno));
  int bytes_written =
      FDUtils::WriteToBlocking(
          exec_control_fd, &child_errno, sizeof(child_errno));
  if (bytes_written == sizeof(child_errno)) {
    FDUtils::WriteToBlocking(
        exec_control_fd, os_error_message, strlen(os_error_message) + 1);
  }
  TEMP_FAILURE_RETRY(close(exec_control_fd));
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
                   char* os_error_message,
                   int os_error_message_len) {
  pid_t pid;
  int read_in[2];  // Pipe for stdout to child process.
  int read_err[2];  // Pipe for stderr to child process.
  int write_out[2];  // Pipe for stdin to child process.
  int exec_control[2];  // Pipe to get the result from exec.
  int result;

  bool initialized = ExitCodeHandler::EnsureInitialized();
  if (!initialized) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    fprintf(stderr,
            "Error initializing exit code handler: %s\n",
            os_error_message);
    return errno;
  }

  result = TEMP_FAILURE_RETRY(pipe(read_in));
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  result = TEMP_FAILURE_RETRY(pipe(read_err));
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  result = TEMP_FAILURE_RETRY(pipe(write_out));
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(read_err[1]));
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  result = TEMP_FAILURE_RETRY(pipe(exec_control));
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(read_err[1]));
    TEMP_FAILURE_RETRY(close(write_out[0]));
    TEMP_FAILURE_RETRY(close(write_out[1]));
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  // Set close on exec on the write file descriptor of the exec control pipe.
  result = TEMP_FAILURE_RETRY(
      fcntl(exec_control[1],
            F_SETFD,
            TEMP_FAILURE_RETRY(fcntl(exec_control[1], F_GETFD)) | FD_CLOEXEC));
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(read_err[1]));
    TEMP_FAILURE_RETRY(close(write_out[0]));
    TEMP_FAILURE_RETRY(close(write_out[1]));
    TEMP_FAILURE_RETRY(close(exec_control[0]));
    TEMP_FAILURE_RETRY(close(exec_control[1]));
    fprintf(stderr, "fcntl failed: %s\n", os_error_message);
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

  struct sigaction act;
  bzero(&act, sizeof(act));
  act.sa_sigaction = SigChldHandler;
  act.sa_flags = SA_NOCLDSTOP | SA_SIGINFO;
  if (sigaction(SIGCHLD, &act, 0) != 0) {
    perror("Process start: setting signal handler failed");
  }
  pid = TEMP_FAILURE_RETRY(fork());
  if (pid < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    delete[] program_arguments;
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(read_err[1]));
    TEMP_FAILURE_RETRY(close(write_out[0]));
    TEMP_FAILURE_RETRY(close(write_out[1]));
    TEMP_FAILURE_RETRY(close(exec_control[0]));
    TEMP_FAILURE_RETRY(close(exec_control[1]));
    return errno;
  } else if (pid == 0) {
    // Wait for parent process before setting up the child process.
    char msg;
    int bytes_read = FDUtils::ReadFromBlocking(read_in[0], &msg, sizeof(msg));
    if (bytes_read != sizeof(msg)) {
      perror("Failed receiving notification message");
      exit(1);
    }

    TEMP_FAILURE_RETRY(close(write_out[1]));
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(exec_control[0]));

    if (TEMP_FAILURE_RETRY(dup2(write_out[0], STDIN_FILENO)) == -1) {
      ReportChildError(exec_control[1]);
    }
    TEMP_FAILURE_RETRY(close(write_out[0]));

    if (TEMP_FAILURE_RETRY(dup2(read_in[1], STDOUT_FILENO)) == -1) {
      ReportChildError(exec_control[1]);
    }
    TEMP_FAILURE_RETRY(close(read_in[1]));

    if (TEMP_FAILURE_RETRY(dup2(read_err[1], STDERR_FILENO)) == -1) {
      ReportChildError(exec_control[1]);
    }
    TEMP_FAILURE_RETRY(close(read_err[1]));

    if (working_directory != NULL &&
        TEMP_FAILURE_RETRY(chdir(working_directory)) == -1) {
      ReportChildError(exec_control[1]);
    }

    if (environment != NULL) {
      TEMP_FAILURE_RETRY(
          execve(path,
                 const_cast<char* const*>(program_arguments),
                 program_environment));
    } else {
      TEMP_FAILURE_RETRY(
          execvp(path, const_cast<char* const*>(program_arguments)));
    }
    ReportChildError(exec_control[1]);
  }

  // The arguments and environment for the spawned process are not needed
  // any longer.
  delete[] program_arguments;
  delete[] program_environment;

  int event_fds[2];
  result = TEMP_FAILURE_RETRY(pipe(event_fds));
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(read_err[1]));
    TEMP_FAILURE_RETRY(close(write_out[0]));
    TEMP_FAILURE_RETRY(close(write_out[1]));
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

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
  TEMP_FAILURE_RETRY(close(exec_control[1]));
  int child_errno;
  int bytes_read = -1;
  ASSERT(sizeof(child_errno) == sizeof(errno));
  bytes_read =
      FDUtils::ReadFromBlocking(
          exec_control[0], &child_errno, sizeof(child_errno));
  if (bytes_read == sizeof(child_errno)) {
      bytes_read = FDUtils::ReadFromBlocking(exec_control[0],
                                             os_error_message,
                                             os_error_message_len);
      os_error_message[os_error_message_len - 1] = '\0';
  }
  TEMP_FAILURE_RETRY(close(exec_control[0]));

  // Return error code if any failures.
  if (bytes_read != 0) {
    TEMP_FAILURE_RETRY(close(read_in[0]));
    TEMP_FAILURE_RETRY(close(read_in[1]));
    TEMP_FAILURE_RETRY(close(read_err[0]));
    TEMP_FAILURE_RETRY(close(read_err[1]));
    TEMP_FAILURE_RETRY(close(write_out[0]));
    TEMP_FAILURE_RETRY(close(write_out[1]));
    if (bytes_read == -1) {
      return errno;  // Read failed.
    } else {
      return child_errno;  // Exec failed.
    }
  }

  FDUtils::SetNonBlocking(read_in[0]);
  *in = read_in[0];
  TEMP_FAILURE_RETRY(close(read_in[1]));
  FDUtils::SetNonBlocking(write_out[1]);
  *out = write_out[1];
  TEMP_FAILURE_RETRY(close(write_out[0]));
  FDUtils::SetNonBlocking(read_err[0]);
  *err = read_err[0];
  TEMP_FAILURE_RETRY(close(read_err[1]));

  *id = pid;
  return 0;
}


bool Process::Kill(intptr_t id, int signal) {
  int result = TEMP_FAILURE_RETRY(kill(id, signal));
  if (result == -1) {
    return false;
  }
  return true;
}


void Process::TerminateExitCodeHandler() {
  ExitCodeHandler::TerminateExitCodeThread();
}


intptr_t Process::CurrentProcessId() {
  return static_cast<intptr_t>(getpid());
}
