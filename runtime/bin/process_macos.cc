// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <errno.h>
#include <fcntl.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "bin/fdutils.h"
#include "bin/process.h"
#include "bin/set.h"


class ActiveProcess {
 public:
  pid_t pid;
  intptr_t fd;

  bool operator==(const ActiveProcess &other) const {
    if (pid == other.pid) {
      return true;
    }
    return false;
  }
};


static Set<ActiveProcess> activeProcesses;


static char* SafeStrNCpy(char* dest, const char* src, size_t n) {
  strncpy(dest, src, n);
  dest[n - 1] = '\0';
  return dest;
}


static void SetChildOsErrorMessage(char* os_error_message,
                                   int os_error_message_len) {
  SafeStrNCpy(os_error_message, strerror(errno), os_error_message_len);
}


void ExitHandle(int processSignal, siginfo_t* siginfo, void* tmp) {
  assert(processSignal == SIGCHLD);
  struct sigaction act;
  bzero(&act, sizeof(act));
  act.sa_handler = SIG_IGN;
  act.sa_flags = SA_NOCLDSTOP | SA_SIGINFO;
  if (sigaction(SIGCHLD, &act, 0) != 0) {
    perror("Process start: disabling signal handler failed");
  }
  pid_t pid = siginfo->si_pid;
  ActiveProcess element;
  element.pid = pid;
  ActiveProcess* current = activeProcesses.Remove(element);
  if (current != NULL) {
    intptr_t message = siginfo->si_status;
    intptr_t result =
        FDUtils::WriteToBlocking(current->fd, &message, sizeof(message));
    if (result != sizeof(message)) {
      perror("ExitHandle notification failed");
    }
    close(current->fd);

    delete current;
  }
  act.sa_handler = 0;
  act.sa_sigaction = ExitHandle;
  if (sigaction(SIGCHLD, &act, 0) != 0) {
    perror("Process start: enabling signal handler failed");
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

  char* program_arguments[arguments_length + 2];
  program_arguments[0] = const_cast<char *>(path);
  for (int i = 0; i < arguments_length; i++) {
    program_arguments[i + 1] = arguments[i];
  }
  program_arguments[arguments_length + 1] = NULL;

  struct sigaction act;
  bzero(&act, sizeof(act));
  act.sa_sigaction = ExitHandle;
  act.sa_flags = SA_NOCLDSTOP | SA_SIGINFO;
  if (sigaction(SIGCHLD, &act, 0) != 0) {
    perror("Process start: setting signal handler failed");
  }
  pid = fork();
  if (pid < 0) {
    SetChildOsErrorMessage(os_error_message, os_error_message_len);
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

  ActiveProcess* activeProcess = new ActiveProcess();
  activeProcess->pid = pid;
  activeProcess->fd = event_fds[1];
  activeProcesses.Add(*activeProcess);
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
