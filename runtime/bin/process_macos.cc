// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "bin/process.h"

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "bin/fdutils.h"


class ProcessInfo {
 public:
  ProcessInfo(pid_t pid, intptr_t fd) : pid_(pid), fd_(fd) { }

  pid_t pid() { return pid_; }
  intptr_t fd() { return fd_; }
  ProcessInfo* next() { return next_; }
  void set_next(ProcessInfo* next) { next_ = next; }

 private:
  pid_t pid_;  // Process pid.
  intptr_t fd_;  // File descriptor for pipe to report exit code.
  ProcessInfo* next_;
};


ProcessInfo* active_processes = NULL;


static void AddProcess(ProcessInfo* process) {
  process->set_next(active_processes);
  active_processes = process;
}


static ProcessInfo* LookupProcess(pid_t pid) {
  ProcessInfo* current = active_processes;
  while (current != NULL) {
    if (current->pid() == pid) {
      return current;
    }
    current = current->next();
  }
  return NULL;
}


static ProcessInfo* RemoveProcess(pid_t pid) {
  ProcessInfo* prev = NULL;
  ProcessInfo* current = active_processes;
  while (current != NULL) {
    if (current->pid() == pid) {
      if (prev == NULL) {
        active_processes = current->next();
      } else {
        prev->set_next(current->next());
      }
      return current;
    }
    prev = current;
    current = current->next();
  }
  return NULL;
}


static char* SafeStrNCpy(char* dest, const char* src, size_t n) {
  strncpy(dest, src, n);
  dest[n - 1] = '\0';
  return dest;
}


static void SetChildOsErrorMessage(char* os_error_message,
                                   int os_error_message_len) {
  SafeStrNCpy(os_error_message, strerror(errno), os_error_message_len);
}


void ExitHandler(int process_signal, siginfo_t* siginfo, void* tmp) {
  int pid = 0;
  int status = 0;
  while ((pid = waitpid(-1, &status, WNOHANG)) > 0) {
    int exit_code = 0;
    int negative = 0;
    if (WIFEXITED(status)) {
      exit_code = WEXITSTATUS(status);
      if (exit_code == 255) {
        exit_code = 1;
        negative = 1;
      }
    }
    if (WIFSIGNALED(status)) {
      exit_code = WTERMSIG(status);
      negative = 1;
    }
    ProcessInfo* process = LookupProcess(pid);
    if (process != NULL) {
      int message[3] = { pid, exit_code, negative };
      intptr_t result =
          FDUtils::WriteToBlocking(process->fd(), &message, sizeof(message));
      if (result != sizeof(message) && errno != EPIPE) {
        perror("ExitHandler notification failed");
      }
      close(process->fd());
    }
  }
}


int Process::Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
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

  result = pipe(read_in);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  result = pipe(read_err);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    close(read_in[0]);
    close(read_in[1]);
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  result = pipe(write_out);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    close(read_in[0]);
    close(read_in[1]);
    close(read_err[0]);
    close(read_err[1]);
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  result = pipe(exec_control);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    close(read_in[0]);
    close(read_in[1]);
    close(read_err[0]);
    close(read_err[1]);
    close(write_out[0]);
    close(write_out[1]);
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  // Set close on exec on the write file descriptor of the exec control pipe.
  result = fcntl(
      exec_control[1], F_SETFD, fcntl(exec_control[1], F_GETFD) | FD_CLOEXEC);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    close(read_in[0]);
    close(read_in[1]);
    close(read_err[0]);
    close(read_err[1]);
    close(write_out[0]);
    close(write_out[1]);
    close(exec_control[0]);
    close(exec_control[1]);
    fprintf(stderr, "fcntl failed: %s\n", os_error_message);
    return errno;
  }

  char** program_arguments = new char*[arguments_length + 2];
  program_arguments[0] = const_cast<char *>(path);
  for (int i = 0; i < arguments_length; i++) {
    program_arguments[i + 1] = arguments[i];
  }
  program_arguments[arguments_length + 1] = NULL;

  struct sigaction act;
  bzero(&act, sizeof(act));
  act.sa_sigaction = ExitHandler;
  act.sa_flags = SA_NOCLDSTOP | SA_SIGINFO;
  if (sigaction(SIGCHLD, &act, 0) != 0) {
    perror("Process start: setting signal handler failed");
  }
  pid = fork();
  if (pid < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    delete[] program_arguments;
    close(read_in[0]);
    close(read_in[1]);
    close(read_err[0]);
    close(read_err[1]);
    close(write_out[0]);
    close(write_out[1]);
    close(exec_control[0]);
    close(exec_control[1]);
    return errno;
  } else if (pid == 0) {
    // Wait for parent process before setting up the child process.
    char msg;
    int bytes_read = FDUtils::ReadFromBlocking(read_in[0], &msg, sizeof(msg));
    if (bytes_read != sizeof(msg)) {
      perror("Failed receiving notification message");
      exit(1);
    }

    close(write_out[1]);
    close(read_in[0]);
    close(read_err[0]);
    close(exec_control[0]);

    dup2(write_out[0], STDIN_FILENO);
    close(write_out[0]);

    dup2(read_in[1], STDOUT_FILENO);
    close(read_in[1]);

    dup2(read_err[1], STDERR_FILENO);
    close(read_err[1]);

    execvp(path, const_cast<char* const*>(program_arguments));
    // In the case of failure write the errno and the OS error message
    // to the exec control pipe.
    int child_errno = errno;
    char* os_error_message = strerror(errno);
    ASSERT(sizeof(child_errno) == sizeof(errno));
    int bytes_written =
        FDUtils::WriteToBlocking(
            exec_control[1], &child_errno, sizeof(child_errno));
    if (bytes_written == sizeof(child_errno)) {
      FDUtils::WriteToBlocking(
          exec_control[1], os_error_message, strlen(os_error_message) + 1);
    }
    close(exec_control[1]);
    exit(1);
  }

  // The arguments for the spawned process are not needed any longer.
  delete[] program_arguments;

  int event_fds[2];
  result = pipe(event_fds);
  if (result < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
    close(read_in[0]);
    close(read_in[1]);
    close(read_err[0]);
    close(read_err[1]);
    close(write_out[0]);
    close(write_out[1]);
    fprintf(stderr, "Error pipe creation failed: %s\n", os_error_message);
    return errno;
  }

  ProcessInfo* process = new ProcessInfo(pid, event_fds[1]);
  AddProcess(process);
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
  close(exec_control[1]);
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
  close(exec_control[0]);

  // Return error code if any failures.
  if (bytes_read != 0) {
    close(read_in[0]);
    close(read_in[1]);
    close(read_err[0]);
    close(read_err[1]);
    close(write_out[0]);
    close(write_out[1]);
    if (bytes_read == -1) {
      return errno;  // Read failed.
    } else {
      return child_errno;  // Exec failed.
    }
  }

  FDUtils::SetNonBlocking(read_in[0]);
  *in = read_in[0];
  close(read_in[1]);
  FDUtils::SetNonBlocking(write_out[1]);
  *out = write_out[1];
  close(write_out[0]);
  FDUtils::SetNonBlocking(read_err[0]);
  *err = read_err[0];
  close(read_err[1]);

  *id = pid;
  return 0;
}


bool Process::Kill(intptr_t id) {
  int result = kill(id, SIGKILL);
  if (result == -1) {
    return false;
  }
  return true;
}


void Process::Exit(intptr_t id) {
  RemoveProcess(id);
}
