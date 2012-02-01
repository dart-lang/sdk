// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <process.h>

#include "bin/builtin.h"
#include "bin/process.h"
#include "bin/eventhandler.h"
#include "bin/thread.h"
#include "platform/globals.h"

static const int kReadHandle = 0;
static const int kWriteHandle = 1;


// ProcessInfo is used to map a process id to the process handle and
// the pipe used to communicate the exit code of the process to Dart.
// ProcessInfo objects are kept in the static singly-linked
// ProcessInfoList.
class ProcessInfo {
 public:
  ProcessInfo(DWORD process_id, HANDLE process_handle, HANDLE exit_pipe)
      : process_id_(process_id),
        process_handle_(process_handle),
        exit_pipe_(exit_pipe) { }

  ~ProcessInfo() {
    BOOL success = CloseHandle(process_handle_);
    if (!success) {
      FATAL("Failed to close process handle");
    }
    success = CloseHandle(exit_pipe_);
    if (!success) {
      FATAL("Failed to close process exit code pipe");
    }
  }

  DWORD pid() { return process_id_; }
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


// Singly-linked list of ProcessInfo objects for all active processes
// started from Dart.
class ProcessInfoList {
 public:
  static void AddProcess(DWORD pid, HANDLE handle, HANDLE pipe) {
    MutexLocker locker(&mutex_);
    ProcessInfo* info = new ProcessInfo(pid, handle, pipe);
    info->set_next(active_processes_);
    active_processes_ = info;
    ++number_of_processes_;
  }

  static bool LookupProcess(DWORD pid, HANDLE* handle, HANDLE* pipe) {
    MutexLocker locker(&mutex_);
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->pid() == pid) {
        *handle = current->process_handle();
        *pipe = current->exit_pipe();
        return true;
      }
      current = current->next();
    }
    return false;
  }

  static DWORD LookupProcessByHandle(HANDLE handle, DWORD* pid, HANDLE* pipe) {
    MutexLocker locker(&mutex_);
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->process_handle() == handle) {
        *pid = current->pid();
        *pipe = current->exit_pipe();
        return true;
      }
      current = current->next();
    }
    return false;
  }

  static void RemoveProcess(DWORD pid) {
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
        --number_of_processes_;
        return;
      }
      prev = current;
      current = current->next();
    }
  }

  static void GetHandleArray(HANDLE** handles,
                             DWORD* number_of_handles,
                             intptr_t prefix_size) {
    ASSERT(prefix_size >= 0);
    *number_of_handles = prefix_size + number_of_processes_;
    *handles = new HANDLE[*number_of_handles];
    intptr_t i = prefix_size;
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      (*handles)[i++] = current->process_handle();
      current = current->next();
    }
    ASSERT(i == *number_of_handles);
  }

 private:
  // Number of processes currently in the list.
  static intptr_t number_of_processes_;
  // Linked list of ProcessInfo objects for all active processes
  // started from Dart code.
  static ProcessInfo* active_processes_;
  // Mutex protecting all accesses to the linked list of active
  // processes.
  static dart::Mutex mutex_;
};


intptr_t ProcessInfoList::number_of_processes_ = 0;
ProcessInfo* ProcessInfoList::active_processes_ = NULL;
dart::Mutex ProcessInfoList::mutex_;


// The exit code handler sets up a separate thread which is waiting
// for Dart process termination and process start. When a process
// terminates the exit code is extracted and communicated to Dart
// through the event loop.
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

    // Allocate an event object to be signaled when new processes are
    // added.
    wake_up_event_ = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (wake_up_event_ == NULL) {
      return false;
    }

    // Start thread that waits for the process-addition handle as well
    // as all process handles for all active processes.
    new dart::Thread(ExitCodeHandlerEntry,
                     reinterpret_cast<uword>(wake_up_event_));

    // Thread started and the ExitCodeHandler is initialized.
    initialized_ = true;
    return true;
  }

  static void Shutdown() {
    MutexLocker locker(&mutex_);
    if (!initialized_) {
      return;
    }
    terminating_ = true;
    BOOL success = SetEvent(wake_up_event_);
    if (!success) {
      FATAL("Failed to set wake-up event for exit code handler shutdown");
    }
  }

  static void ProcessAdded() {
    MutexLocker locker(&mutex_);
    BOOL success = SetEvent(wake_up_event_);
    if (!success) {
      FATAL("Failed to set the process addition wake-up event");
    }
  }

  static bool Terminating() {
    MutexLocker locker(&mutex_);
    return terminating_;
  }

 private:
  // Entry point for the exit code handler thread started by the
  // ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    HANDLE wake_up_event = reinterpret_cast<HANDLE>(param);

    while (true) {
      // Get the list of handles to wait for. Allocate a prefix of one
      // extra handle for the 'process added' event object.
      HANDLE* handles;
      DWORD number_of_handles;
      intptr_t prefix_size = 1;
      ProcessInfoList::GetHandleArray(&handles,
                                      &number_of_handles,
                                      prefix_size);
      handles[0] = wake_up_event;

      // TODO(1450): support more than 63 processes on Windows.
      if (number_of_handles > MAXIMUM_WAIT_OBJECTS) {
        FATAL1("Only %d processes supported on Windows at this point\n",
               MAXIMUM_WAIT_OBJECTS - 1);
      }

      // Wait for the handles.
      DWORD result =
          WaitForMultipleObjects(number_of_handles, handles, FALSE, INFINITE);
      if (result == WAIT_FAILED) {
        FATAL("Failed to wait for multiple objects for exit code handling");
      }

      if (result == 0) {
        // If the result is 0 the thread woke up because of process
        // addition or because the ExitCodeHandler is being shut down.
        if (ExitCodeHandler::Terminating()) {
          BOOL success = CloseHandle(wake_up_event_);
          if (!success) {
            FATAL("Failed to clse the wake-up event handle");
          }
          return;
        }
        // This was an addition, we reset the wake up event so we can
        // get signalled on further additions.
        BOOL success = ResetEvent(wake_up_event);
        if (!success) {
          FATAL("Failed to reset process addition wake-up event");
        }
      } else {
        // The result is the index of the process that was
        // signalled. Get its exit code and communicate it to Dart.
        int exit_code;
        BOOL ok = GetExitCodeProcess(handles[result],
                                     reinterpret_cast<DWORD*>(&exit_code));
        if (!ok) {
          FATAL1("GetExitCodeProcess failed %d\n", GetLastError());
        }
        int negative = 0;
        if (exit_code < 0) {
          exit_code = abs(exit_code);
          negative = 1;
        }

        DWORD pid;
        HANDLE exit_pipe;
        bool success = ProcessInfoList::LookupProcessByHandle(handles[result],
                                                              &pid,
                                                              &exit_pipe);
        if (!success) {
          FATAL("Failed to lookup pid and exit pipe from process handle");
        }
        int message[2] = { exit_code, negative };
        DWORD written;
        ok = WriteFile(exit_pipe, message, sizeof(message), &written, NULL);
        if (!ok || written != sizeof(message)) {
          FATAL1("WriteFile to process exit code pipe failed %d\n",
                 GetLastError());
        }
        ProcessInfoList::RemoveProcess(pid);
      }
      delete[] handles;
    }
  }

  static dart::Mutex mutex_;
  static bool initialized_;
  static bool terminating_;
  static HANDLE wake_up_event_;
};


dart::Mutex ExitCodeHandler::mutex_;
bool ExitCodeHandler::initialized_ = false;
bool ExitCodeHandler::terminating_ = false;
HANDLE ExitCodeHandler::wake_up_event_ = 0;


// Types of pipes to create.
enum NamedPipeType {
  kInheritRead,
  kInheritWrite,
  kInheritNone
};


// Create a pipe for communicating with a new process. The handles array
// will contain the read and write ends of the pipe. Based on the type
// one of the handles will be inheritable.
// NOTE: If this function returns false the handles might have been allocated
// and the caller should make sure to close them in case of an error.
static bool CreateProcessPipe(HANDLE handles[2],
                              char* pipe_name,
                              NamedPipeType type) {
  // Security attributes describing an inheritable handle.
  SECURITY_ATTRIBUTES inherit_handle;
  inherit_handle.nLength = sizeof(SECURITY_ATTRIBUTES);
  inherit_handle.bInheritHandle = TRUE;
  inherit_handle.lpSecurityDescriptor = NULL;

  if (type == kInheritRead) {
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
                   &inherit_handle,
                   OPEN_EXISTING,
                   FILE_READ_ATTRIBUTES | FILE_FLAG_OVERLAPPED,
                   NULL);
    if (handles[kReadHandle] == INVALID_HANDLE_VALUE) {
      fprintf(stderr, "CreateFile failed %d\n", GetLastError());
      return false;
    }
  } else {
    ASSERT(type == kInheritWrite || type == kInheritNone);
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
                   (type == kInheritWrite) ? &inherit_handle : NULL,
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


static void CloseProcessPipes(HANDLE handles1[2],
                              HANDLE handles2[2],
                              HANDLE handles3[2],
                              HANDLE handles4[2]) {
  CloseProcessPipe(handles1);
  CloseProcessPipe(handles2);
  CloseProcessPipe(handles3);
  CloseProcessPipe(handles4);
}

static int SetOsErrorMessage(char* os_error_message,
                             int os_error_message_len) {
  int error_code = GetLastError();
  DWORD message_size =
      FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    error_code,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    os_error_message,
                    os_error_message_len,
                    NULL);
  if (message_size == 0) {
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      fprintf(stderr, "FormatMessage failed %d\n", GetLastError());
    }
    snprintf(os_error_message, os_error_message_len, "OS Error %d", error_code);
  }
  os_error_message[os_error_message_len - 1] = '\0';
  return error_code;
}


int Process::Start(const char* path,
                   char* arguments[],
                   intptr_t arguments_length,
                   const char* working_directory,
                   intptr_t* in,
                   intptr_t* out,
                   intptr_t* err,
                   intptr_t* id,
                   intptr_t* exit_handler,
                   char* os_error_message,
                   int os_error_message_len) {
  // Ensure that the process exit handler thread has been started.
  bool initialized = ExitCodeHandler::EnsureInitialized();
  if (!initialized) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    fprintf(stderr, "Failed to initialize ExitCodeHandler: %d\n", error_code);
    return error_code;
  }

  HANDLE stdin_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE stdout_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE stderr_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE exit_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };

  // Generate unique pipe names for the four named pipes needed.
  char pipe_names[4][80];
  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if (status != RPC_S_OK && status != RPC_S_UUID_LOCAL_ONLY) {
    fprintf(stderr, "UuidCreateSequential failed %d\n", status);
    SetOsErrorMessage(os_error_message, os_error_message_len);
    return status;
  }
  RPC_CSTR uuid_string;
  status = UuidToString(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    fprintf(stderr, "UuidToString failed %d\n", status);
    SetOsErrorMessage(os_error_message, os_error_message_len);
    return status;
  }
  for (int i = 0; i < 4; i++) {
    static const char* prefix = "\\\\.\\Pipe\\dart";
    snprintf(pipe_names[i],
             sizeof(pipe_names[i]),
             "%s_%s_%d", prefix, uuid_string, i + 1);
  }
  status = RpcStringFree(&uuid_string);
  if (status != RPC_S_OK) {
    fprintf(stderr, "RpcStringFree failed %d\n", status);
    SetOsErrorMessage(os_error_message, os_error_message_len);
    return status;
  }

  if (!CreateProcessPipe(stdin_handles, pipe_names[0], kInheritRead)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }
  if (!CreateProcessPipe(stdout_handles, pipe_names[1], kInheritWrite)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }
  if (!CreateProcessPipe(stderr_handles, pipe_names[2], kInheritWrite)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }
  if (!CreateProcessPipe(exit_handles, pipe_names[3], kInheritNone)) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
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
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
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
                              working_directory,
                              &startup_info,
                              &process_info);

  // Deallocate command-line string.
  delete[] command_line;

  if (result == 0) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }

  ProcessInfoList::AddProcess(process_info.dwProcessId,
                              process_info.hProcess,
                              exit_handles[kWriteHandle]);
  ExitCodeHandler::ProcessAdded();

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
  *id = process_info.dwProcessId;
  return 0;
}


bool Process::Kill(intptr_t id) {
  HANDLE process_handle;
  HANDLE exit_pipe;
  bool success =
      ProcessInfoList::LookupProcess(id, &process_handle, &exit_pipe);
  ASSERT(success);
  BOOL result = TerminateProcess(process_handle, -1);
  if (!result) {
    return false;
  }
  return true;
}


void Process::TerminateExitCodeHandler() {
  ExitCodeHandler::Shutdown();
}
