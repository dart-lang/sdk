// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <process.h>

#include "bin/builtin.h"
#include "bin/globals.h"
#include "bin/process.h"
#include "bin/eventhandler.h"

static const int kReadHandle = 0;
static const int kWriteHandle = 1;

class ProcessInfo {
 public:
  ProcessInfo(DWORD process_id, HANDLE process_handle, HANDLE exit_pipe)
      : process_id_(process_id),
        process_handle_(process_handle),
        exit_pipe_(exit_pipe) { }

  intptr_t pid() { return process_id_; }
  HANDLE process_handle() { return process_handle_; }
  HANDLE exit_pipe() { return exit_pipe_; }
  ProcessInfo* next() { return next_; }
  void set_next(ProcessInfo* next) { next_ = next; }

 private:
  DWORD process_id_;  // Process id.
  HANDLE process_handle_;  // Process handle.
  HANDLE exit_pipe_;  // File descriptor for pipe to report exit code.
  ProcessInfo* next_;
};


ProcessInfo* active_processes = NULL;


static void AddProcess(ProcessInfo* process) {
  process->set_next(active_processes);
  active_processes = process;
}


static ProcessInfo* LookupProcess(intptr_t pid) {
  ProcessInfo* current = active_processes;
  while (current != NULL) {
    if (current->pid() == pid) {
      return current;
    }
    current = current->next();
  }
  return NULL;
}


static void RemoveProcess(intptr_t pid) {
  ProcessInfo* prev = NULL;
  ProcessInfo* current = active_processes;
  while (current != NULL) {
    if (current->pid() == pid) {
      if (prev == NULL) {
        active_processes = current->next();
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


// Create a pipe for communicating with a new process. The handles array
// will contain the read and write ends of the pipe. Based on the is_input
// argument either the read or the write end of the handle will be
// non-inherited.
static bool CreateProcessPipe(HANDLE handles[2],
                              char* pipe_name,
                              bool is_input) {
  SECURITY_ATTRIBUTES security_attributes;
  security_attributes.nLength = sizeof(SECURITY_ATTRIBUTES);
  security_attributes.bInheritHandle = TRUE;
  security_attributes.lpSecurityDescriptor = NULL;
  if (is_input) {
    handles[kWriteHandle] =
        CreateNamedPipe(pipe_name,
                        PIPE_ACCESS_OUTBOUND | FILE_FLAG_OVERLAPPED,
                        PIPE_TYPE_BYTE | PIPE_WAIT,
                        1,             // Number of pipes
                        1024,          // Out buffer size
                        1024,          // In buffer size
                        0,             // Timeout in ms
                        NULL);

    if (handles[kWriteHandle] == INVALID_HANDLE_VALUE) {
      fprintf(stderr, "CreateNamedPipe failed %d\n", GetLastError());
      return false;
    }

    handles[kReadHandle] =
        CreateFile(pipe_name,
                   GENERIC_READ,
                   0,
                   &security_attributes,
                   OPEN_EXISTING,
                   FILE_READ_ATTRIBUTES | FILE_FLAG_OVERLAPPED,
                   NULL);
    if (handles[kReadHandle] == INVALID_HANDLE_VALUE) {
      fprintf(stderr, "CreateFile failed %d\n", GetLastError());
      return false;
    }
  } else {
    handles[kReadHandle] =
        CreateNamedPipe(pipe_name,
                        PIPE_ACCESS_INBOUND | FILE_FLAG_OVERLAPPED,
                        PIPE_TYPE_BYTE | PIPE_WAIT,
                        1,             // Number of pipes
                        1024,          // Out buffer size
                        1024,          // In buffer size
                        0,             // Timeout in ms
                        NULL);

    if (handles[kReadHandle] == INVALID_HANDLE_VALUE) {
      fprintf(stderr, "CreateNamedPipe failed %d\n", GetLastError());
      return false;
    }

    handles[kWriteHandle] =
        CreateFile(pipe_name,
                   GENERIC_WRITE,
                   0,
                   &security_attributes,
                   OPEN_EXISTING,
                   FILE_WRITE_ATTRIBUTES | FILE_FLAG_OVERLAPPED,
                   NULL);
    if (handles[kWriteHandle] == INVALID_HANDLE_VALUE) {
      fprintf(stderr, "CreateFile failed %d\n", GetLastError());
      return false;
    }
  }
  return true;
}


static void CloseProcessPipe(HANDLE handles[2]) {
  for (int i = kReadHandle; i < kWriteHandle; i++) {
    if (handles[i] != INVALID_HANDLE_VALUE) {
      if (!CloseHandle(handles[i])) {
        fprintf(stderr, "CloseHandle failed %d\n", GetLastError());
      }
      handles[i] = INVALID_HANDLE_VALUE;
    }
  }
}


static int SetOsErrorMessage(char* os_error_message,
                              int os_error_message_len) {
  int error_code = GetLastError();
  // TODO(sgjesse): Use FormatMessage to get the error message.
  char message[80];
  snprintf(os_error_message, os_error_message_len, "OS Error %d", error_code);
  return error_code;
}


static unsigned int __stdcall TerminationWaitThread(void* args) {
  ProcessInfo* process = reinterpret_cast<ProcessInfo*>(args);
  WaitForSingleObject(process->process_handle(), INFINITE);
  DWORD exit_code;
  BOOL ok = GetExitCodeProcess(process->process_handle(), &exit_code);
  if (!ok) {
    fprintf(stderr, "GetExitCodeProcess failed %d\n", GetLastError());
  }
  intptr_t message[2] = { process->pid(), static_cast<intptr_t>(exit_code) };
  DWORD written;
  ok = WriteFile(
      process->exit_pipe(), message, sizeof(message), &written, NULL);
  if (!ok || written != 8) {
    fprintf(stderr, "FileWrite failed %d\n", GetLastError());
  }
  return 0;
}


int Process::Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_handler,
                   char* os_error_message,
                   int os_error_message_len) {
  HANDLE stdin_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE stdout_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE stderr_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE exit_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  // TODO(sgjesse): Find a better way of generating unique pipe names
  // (e.g. UUID).
  DWORD current_pid = GetCurrentProcessId();
  static int pipe_id = 0;
  char pipe_name[80];
  pipe_id++;
  snprintf(pipe_name, sizeof(pipe_name),
           "\\\\.\\Pipe\\dart%d_%d_1", current_pid, pipe_id);
  if (!CreateProcessPipe(stdin_handles, pipe_name, true)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipe(stdin_handles);
    return error_code;
  }
  snprintf(pipe_name, sizeof(pipe_name),
           "\\\\.\\Pipe\\dart%d_%d_2", current_pid, pipe_id);
  if (!CreateProcessPipe(stdout_handles, pipe_name, false)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipe(stdin_handles);
    CloseProcessPipe(stdout_handles);
    return error_code;
  }
  snprintf(pipe_name, sizeof(pipe_name),
           "\\\\.\\Pipe\\dart%d_%d_3", current_pid, pipe_id);
  if (!CreateProcessPipe(stderr_handles, pipe_name, false)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipe(stdin_handles);
    CloseProcessPipe(stdout_handles);
    CloseProcessPipe(stderr_handles);
    return error_code;
  }
  snprintf(pipe_name, sizeof(pipe_name),
           "\\\\.\\Pipe\\dart%d_%d_4", current_pid, pipe_id);
  if (!CreateProcessPipe(exit_handles, pipe_name, false)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipe(stdin_handles);
    CloseProcessPipe(stdout_handles);
    CloseProcessPipe(stderr_handles);
    CloseProcessPipe(exit_handles);
    return error_code;
  }

  // Setup info structures.
  STARTUPINFO startup_info;
  ZeroMemory(&startup_info, sizeof(startup_info));
  startup_info.cb = sizeof(startup_info);
  startup_info.hStdInput = stdin_handles[kReadHandle];
  startup_info.hStdOutput = stdout_handles[kWriteHandle];
  startup_info.hStdError = stderr_handles[kWriteHandle];
  startup_info.dwFlags |= STARTF_USESTDHANDLES;

  PROCESS_INFORMATION process_info;
  ZeroMemory(&process_info, sizeof(process_info));

  // Compute command-line length.
  int command_line_length = strlen(path);
  for (int i = 0; i < arguments_length; i++) {
    command_line_length += strlen(arguments[i]);
  }
  // Account for two occurrences of '"' around the command, one
  // space per argument and a terminating '\0'.
  command_line_length += 2 + arguments_length + 1;
  static const int kMaxCommandLineLength = 32768;
  if (command_line_length > kMaxCommandLineLength) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipe(stdin_handles);
    CloseProcessPipe(stdout_handles);
    CloseProcessPipe(stderr_handles);
    CloseProcessPipe(exit_handles);
    return error_code;
  }

  // Put together command-line string.
  char* command_line = new char[command_line_length];
  int len = 0;
  int remaining = command_line_length;
  int written = snprintf(command_line + len, remaining, "\"%s\"", path);
  len += written;
  remaining -= written;
  ASSERT(remaining >= 0);
  for (int i = 0; i < arguments_length; i++) {
    written = snprintf(command_line + len, remaining, " %s", arguments[i]);
    len += written;
    remaining -= written;
    ASSERT(remaining >= 0);
  }

  // Create process.
  BOOL result = CreateProcess(NULL,   // ApplicationName
                              command_line,
                              NULL,   // ProcessAttributes
                              NULL,   // ThreadAttributes
                              TRUE,   // InheritHandles
                              0,      // CreationFlags
                              NULL,   // Environment
                              NULL,   // CurrentDirectory,
                              &startup_info,
                              &process_info);

  // Deallocate command-line string.
  delete[] command_line;

  if (result == 0) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipe(stdin_handles);
    CloseProcessPipe(stdout_handles);
    CloseProcessPipe(stderr_handles);
    CloseProcessPipe(exit_handles);
    return error_code;
  }

  ProcessInfo* process = new ProcessInfo(process_info.dwProcessId,
                                         process_info.hProcess,
                                         exit_handles[kWriteHandle]);
  AddProcess(process);

  // TODO(sgjesse): Don't use a separate thread for waiting for each process to
  // terminate.
  uint32_t tid;
  uintptr_t thread_handle =
      _beginthreadex(NULL, 32 * 1024, TerminationWaitThread, process, 0, &tid);
  if (thread_handle == -1) {
    FATAL("Failed to start event handler thread");
  }


  // Connect the three std streams.
  FileHandle* stdin_handle = new FileHandle(stdin_handles[kWriteHandle]);
  CloseHandle(stdin_handles[kReadHandle]);
  FileHandle* stdout_handle = new FileHandle(stdout_handles[kReadHandle]);
  CloseHandle(stdout_handles[kWriteHandle]);
  FileHandle* stderr_handle = new FileHandle(stderr_handles[kReadHandle]);
  CloseHandle(stderr_handles[kWriteHandle]);
  FileHandle* exit_handle = new FileHandle(exit_handles[kReadHandle]);
  *in = reinterpret_cast<intptr_t>(stdout_handle);
  *out = reinterpret_cast<intptr_t>(stdin_handle);
  *err = reinterpret_cast<intptr_t>(stderr_handle);
  *exit_handler = reinterpret_cast<intptr_t>(exit_handle);

  CloseHandle(process_info.hThread);

  // Return process id.
  *id = process->pid();
  return 0;
}


bool Process::Kill(intptr_t id) {
  ProcessInfo* process = LookupProcess(id);
  ASSERT(process != NULL);
  if (process != NULL) {
    BOOL result = TerminateProcess(process->process_handle(), -1);
    if (result == 0) {
      return false;
    }
  }
  return true;
}


void Process::Exit(intptr_t id) {
  RemoveProcess(id);
}
