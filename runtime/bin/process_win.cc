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
    BOOL success = SetEvent(GetProcessAddedEvent());
    if (!success) {
      FATAL("Failed to set process added event");
    }
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

  static bool LookupProcessByHandle(HANDLE handle, DWORD* pid, HANDLE* pipe) {
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

  // Extract the process handles from the process list. The handles
  // array argument must have space for MAXIMUM_WAIT_OBJECTS handles.
  static DWORD GetHandleArray(HANDLE* handles, intptr_t prefix_size) {
    MutexLocker locker(&mutex_);
    ASSERT(prefix_size >= 0);
    DWORD number_of_handles = prefix_size + number_of_processes_;
    if (number_of_handles > MAXIMUM_WAIT_OBJECTS) {
      FATAL1("Only %d processes supported on Windows at this point\n",
             MAXIMUM_WAIT_OBJECTS - prefix_size);
    }
    intptr_t i = prefix_size;
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      handles[i++] = current->process_handle();
      current = current->next();
    }
    ASSERT(i == number_of_handles);
    // We have taken a new snapshot of the handles in the list. Reset
    // the process_added_event so we will get signaled if more
    // processes are added.
    BOOL success = ResetEvent(GetProcessAddedEvent());
    if (!success) {
      FATAL("Failed to reset process added event");
    }
    return number_of_handles;
  }

 private:
  friend class ExitCodeHandler;
  static HANDLE GetProcessAddedEvent() {
    MutexLocker locker(&process_added_event_mutex_);
    if (process_added_event_ == INVALID_HANDLE_VALUE) {
      process_added_event_ = CreateEvent(NULL, TRUE, FALSE, NULL);
      if (process_added_event_ == NULL) {
        FATAL("Failed to allocate event for signaling addition of processes");
      }
    }
    return process_added_event_;
  }
  // Number of processes currently in the list.
  static intptr_t number_of_processes_;
  // Linked list of ProcessInfo objects for all active processes
  // started from Dart code.
  static ProcessInfo* active_processes_;
  // Mutex protecting all accesses to the linked list of active
  // processes.
  static dart::Mutex mutex_;
  // Event used to signal that more processes have been added to the
  // list.
  static HANDLE process_added_event_;
  static dart::Mutex process_added_event_mutex_;
};


intptr_t ProcessInfoList::number_of_processes_ = 0;
ProcessInfo* ProcessInfoList::active_processes_ = NULL;
dart::Mutex ProcessInfoList::mutex_;
HANDLE ProcessInfoList::process_added_event_ = INVALID_HANDLE_VALUE;
dart::Mutex ProcessInfoList::process_added_event_mutex_;


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

    // Allocate an event object to be signaled when the exit code
    // thread should terminate.
    terminate_event_ = CreateEvent(NULL, TRUE, FALSE, NULL);
    if (terminate_event_ == NULL) {
      return false;
    }

    // Start thread that waits for the process-addition and
    // thread-termination events as well as all process handles for
    // all active processes.
    HANDLE* events = new HANDLE[2];
    events[0] = ProcessInfoList::GetProcessAddedEvent();
    events[1] = terminate_event_;
    int result = dart::Thread::Start(ExitCodeHandlerEntry,
                                     reinterpret_cast<uword>(events));
    if (result != 0) {
      FATAL1("Failed to start exit code handler thread: %d", result);
    }

    // Thread started and the ExitCodeHandler is initialized.
    initialized_ = true;
    return true;
  }

  static void TerminateExitCodeThread() {
    MutexLocker locker(&mutex_);
    if (!initialized_) {
      return;
    }

    BOOL success = SetEvent(terminate_event_);
    if (!success) {
      FATAL("Failed to set terminate event for exit code handler shutdown");
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
  // Entry point for the exit code handler thread started by the
  // ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    HANDLE* events = reinterpret_cast<HANDLE*>(param);
    HANDLE wake_up_event = events[0];
    HANDLE terminate_event = events[1];
    delete[] events;

    HANDLE handles[MAXIMUM_WAIT_OBJECTS];
    handles[0] = wake_up_event;
    handles[1] = terminate_event;

    while (true) {
      // Get the list of handles to wait for. Allocate a prefix of two
      // extra handles for the 'process added' and 'thread
      // termination' event objects.
      static const intptr_t kPrefixSize = 2;
      DWORD number_of_handles =
          ProcessInfoList::GetHandleArray(handles, kPrefixSize);
      ASSERT(handles[0] == wake_up_event);
      ASSERT(handles[1] == terminate_event);

      // Wait for the handles.
      DWORD result =
          WaitForMultipleObjects(number_of_handles, handles, FALSE, INFINITE);
      if (result == WAIT_FAILED) {
        FATAL("Failed to wait for multiple objects for exit code handling");
      }

      if (result == 0) {
        // If the result is 0 the thread woke up because of process
        // addition. We don't have to do anything we just need to
        // update the list of handles we are waiting for.
      } else if (result == 1) {
        // The termination event was triggered. Free event objects and
        // exit.
        CloseHandle(terminate_event_);
        CloseHandle(wake_up_event);
        ExitCodeThreadTerminated();
        return;
      } else {
        // The result is the index of the process that was
        // signalled. Get its exit code and communicate it to Dart.
        ASSERT(result < number_of_handles);
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
        // If the process has been closed, the read end of the exit
        // pipe has been closed. It is therefore not a problem that
        // WriteFile fails with a closed pipe error
        // (ERROR_NO_DATA). Other errors should not happen.
        if (ok && written != sizeof(message)) {
          FATAL("Failed to write entire process exit message");
        } else if (!ok && GetLastError() != ERROR_NO_DATA) {
          FATAL1("Failed to write exit code: %d", GetLastError());
        }
        ProcessInfoList::RemoveProcess(pid);
      }
    }
  }

  static dart::Mutex mutex_;
  static bool initialized_;
  static HANDLE terminate_event_;
  static bool thread_terminated_;
  static dart::Monitor thread_terminate_monitor_;
};


dart::Mutex ExitCodeHandler::mutex_;
bool ExitCodeHandler::initialized_ = false;
HANDLE ExitCodeHandler::terminate_event_ = INVALID_HANDLE_VALUE;
bool ExitCodeHandler::thread_terminated_ = false;
dart::Monitor ExitCodeHandler::thread_terminate_monitor_;


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
                   char* environment[],
                   intptr_t environment_length,
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
  // Account for null termination and one space per argument.
  command_line_length += arguments_length + 1;
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
  int written = snprintf(command_line + len, remaining, "%s", path);
  len += written;
  remaining -= written;
  ASSERT(remaining >= 0);
  for (int i = 0; i < arguments_length; i++) {
    written = snprintf(command_line + len, remaining, " %s", arguments[i]);
    len += written;
    remaining -= written;
    ASSERT(remaining >= 0);
  }

  // Create environment block if an environment is supplied.
  char* environment_block = NULL;
  if (environment != NULL) {
    // An environment block is a sequence of zero-terminated strings
    // followed by a block-terminating zero char.
    intptr_t block_size = 1;
    for (intptr_t i = 0; i < environment_length; i++) {
      block_size += strlen(environment[i]) + 1;
    }
    environment_block = new char[block_size];
    intptr_t block_index = 0;
    for (intptr_t i = 0; i < environment_length; i++) {
      intptr_t len = strlen(environment[i]);
      intptr_t result = snprintf(environment_block + block_index,
                                 len,
                                 "%s",
                                 environment[i]);
      ASSERT(result == len);
      block_index += len;
      environment_block[block_index++] = '\0';
    }
    // Block-terminating zero char.
    environment_block[block_index++] = '\0';
    ASSERT(block_index == block_size);
  }

  // Create process.
  BOOL result = CreateProcess(NULL,   // ApplicationName
                              command_line,
                              NULL,   // ProcessAttributes
                              NULL,   // ThreadAttributes
                              TRUE,   // InheritHandles
                              0,      // CreationFlags
                              environment_block,
                              working_directory,
                              &startup_info,
                              &process_info);

  // Deallocate command-line and environment block strings.
  delete[] command_line;
  delete[] environment_block;

  if (result == 0) {
    int error_code = SetOsErrorMessage(os_error_message, os_error_message_len);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }

  ProcessInfoList::AddProcess(process_info.dwProcessId,
                              process_info.hProcess,
                              exit_handles[kWriteHandle]);

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
  ExitCodeHandler::TerminateExitCodeThread();
}
