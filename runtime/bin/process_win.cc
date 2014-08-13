// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(TARGET_OS_WINDOWS)

#include <process.h>  // NOLINT

#include "bin/builtin.h"
#include "bin/process.h"
#include "bin/eventhandler.h"
#include "bin/lockers.h"
#include "bin/log.h"
#include "bin/socket.h"
#include "bin/thread.h"
#include "bin/utils.h"
#include "bin/utils_win.h"


namespace dart {
namespace bin {

static const int kReadHandle = 0;
static const int kWriteHandle = 1;


// ProcessInfo is used to map a process id to the process handle,
// wait handle for registered exit code event and the pipe used to
// communicate the exit code of the process to Dart.
// ProcessInfo objects are kept in the static singly-linked
// ProcessInfoList.
class ProcessInfo {
 public:
  ProcessInfo(DWORD process_id,
              HANDLE process_handle,
              HANDLE wait_handle,
              HANDLE exit_pipe)
      : process_id_(process_id),
        process_handle_(process_handle),
        wait_handle_(wait_handle),
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
  HANDLE wait_handle() { return wait_handle_; }
  HANDLE exit_pipe() { return exit_pipe_; }
  ProcessInfo* next() { return next_; }
  void set_next(ProcessInfo* next) { next_ = next; }

 private:
  // Process id.
  DWORD process_id_;
  // Process handle.
  HANDLE process_handle_;
  // Wait handle identifying the exit-code wait operation registered
  // with RegisterWaitForSingleObject.
  HANDLE wait_handle_;
  // File descriptor for pipe to report exit code.
  HANDLE exit_pipe_;
  // Link to next ProcessInfo object in the singly-linked list.
  ProcessInfo* next_;
};


// Singly-linked list of ProcessInfo objects for all active processes
// started from Dart.
class ProcessInfoList {
 public:
  static void AddProcess(DWORD pid, HANDLE handle, HANDLE pipe) {
    // Register a callback to extract the exit code, when the process
    // is signaled.  The callback runs in a independent thread from the OS pool.
    // Because the callback depends on the process list containing
    // the process, lock the mutex until the process is added to the list.
    MutexLocker locker(mutex_);
    HANDLE wait_handle = INVALID_HANDLE_VALUE;
    BOOL success = RegisterWaitForSingleObject(
        &wait_handle,
        handle,
        &ExitCodeCallback,
        reinterpret_cast<void*>(pid),
        INFINITE,
        WT_EXECUTEONLYONCE);
    if (!success) {
      FATAL("Failed to register exit code wait operation.");
    }
    ProcessInfo* info = new ProcessInfo(pid, handle, wait_handle, pipe);
    // Mutate the process list under the mutex.
    info->set_next(active_processes_);
    active_processes_ = info;
  }

  static bool LookupProcess(DWORD pid,
                            HANDLE* handle,
                            HANDLE* wait_handle,
                            HANDLE* pipe) {
    MutexLocker locker(mutex_);
    ProcessInfo* current = active_processes_;
    while (current != NULL) {
      if (current->pid() == pid) {
        *handle = current->process_handle();
        *wait_handle = current->wait_handle();
        *pipe = current->exit_pipe();
        return true;
      }
      current = current->next();
    }
    return false;
  }

  static void RemoveProcess(DWORD pid) {
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
  // Callback called when an exit code is available from one of the
  // processes in the list.
  static void CALLBACK ExitCodeCallback(PVOID data, BOOLEAN timed_out) {
    if (timed_out) return;
    DWORD pid = reinterpret_cast<DWORD>(data);
    HANDLE handle;
    HANDLE wait_handle;
    HANDLE exit_pipe;
    bool success = LookupProcess(pid, &handle, &wait_handle, &exit_pipe);
    if (!success) {
      FATAL("Failed to lookup process in list of active processes");
    }
    // Unregister the event in a non-blocking way.
    BOOL ok = UnregisterWait(wait_handle);
    if (!ok && GetLastError() != ERROR_IO_PENDING) {
      FATAL("Failed unregistering wait operation");
    }
    // Get and report the exit code to Dart.
    int exit_code;
    ok = GetExitCodeProcess(handle,
                            reinterpret_cast<DWORD*>(&exit_code));
    if (!ok) {
      FATAL1("GetExitCodeProcess failed %d\n", GetLastError());
    }
    int negative = 0;
    if (exit_code < 0) {
      exit_code = abs(exit_code);
      negative = 1;
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
    // Remove the process from the list of active processes.
    RemoveProcess(pid);
  }

  // Linked list of ProcessInfo objects for all active processes
  // started from Dart code.
  static ProcessInfo* active_processes_;
  // Mutex protecting all accesses to the linked list of active
  // processes.
  static dart::Mutex* mutex_;
};


ProcessInfo* ProcessInfoList::active_processes_ = NULL;
dart::Mutex* ProcessInfoList::mutex_ = new dart::Mutex();


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
                              wchar_t* pipe_name,
                              NamedPipeType type) {
  // Security attributes describing an inheritable handle.
  SECURITY_ATTRIBUTES inherit_handle;
  inherit_handle.nLength = sizeof(SECURITY_ATTRIBUTES);
  inherit_handle.bInheritHandle = TRUE;
  inherit_handle.lpSecurityDescriptor = NULL;

  if (type == kInheritRead) {
    handles[kWriteHandle] =
        CreateNamedPipeW(pipe_name,
                         PIPE_ACCESS_OUTBOUND | FILE_FLAG_OVERLAPPED,
                         PIPE_TYPE_BYTE | PIPE_WAIT,
                         1,             // Number of pipes
                         1024,          // Out buffer size
                         1024,          // In buffer size
                         0,             // Timeout in ms
                         NULL);

    if (handles[kWriteHandle] == INVALID_HANDLE_VALUE) {
      Log::PrintErr("CreateNamedPipe failed %d\n", GetLastError());
      return false;
    }

    handles[kReadHandle] =
        CreateFileW(pipe_name,
                    GENERIC_READ,
                    0,
                    &inherit_handle,
                    OPEN_EXISTING,
                    FILE_READ_ATTRIBUTES | FILE_FLAG_OVERLAPPED,
                    NULL);
    if (handles[kReadHandle] == INVALID_HANDLE_VALUE) {
      Log::PrintErr("CreateFile failed %d\n", GetLastError());
      return false;
    }
  } else {
    ASSERT(type == kInheritWrite || type == kInheritNone);
    handles[kReadHandle] =
        CreateNamedPipeW(pipe_name,
                         PIPE_ACCESS_INBOUND | FILE_FLAG_OVERLAPPED,
                         PIPE_TYPE_BYTE | PIPE_WAIT,
                         1,             // Number of pipes
                         1024,          // Out buffer size
                         1024,          // In buffer size
                         0,             // Timeout in ms
                         NULL);

    if (handles[kReadHandle] == INVALID_HANDLE_VALUE) {
      Log::PrintErr("CreateNamedPipe failed %d\n", GetLastError());
      return false;
    }

    handles[kWriteHandle] =
        CreateFileW(pipe_name,
                    GENERIC_WRITE,
                    0,
                    (type == kInheritWrite) ? &inherit_handle : NULL,
                    OPEN_EXISTING,
                    FILE_WRITE_ATTRIBUTES | FILE_FLAG_OVERLAPPED,
                    NULL);
    if (handles[kWriteHandle] == INVALID_HANDLE_VALUE) {
      Log::PrintErr("CreateFile failed %d\n", GetLastError());
      return false;
    }
  }
  return true;
}


static void CloseProcessPipe(HANDLE handles[2]) {
  for (int i = kReadHandle; i < kWriteHandle; i++) {
    if (handles[i] != INVALID_HANDLE_VALUE) {
      if (!CloseHandle(handles[i])) {
        Log::PrintErr("CloseHandle failed %d\n", GetLastError());
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


static int SetOsErrorMessage(char** os_error_message) {
  int error_code = GetLastError();
  static const int kMaxMessageLength = 256;
  wchar_t message[kMaxMessageLength];
  FormatMessageIntoBuffer(error_code, message, kMaxMessageLength);
  *os_error_message = StringUtils::WideToUtf8(message);
  return error_code;
}


typedef BOOL (WINAPI *InitProcThreadAttrListFn)(
    LPPROC_THREAD_ATTRIBUTE_LIST, DWORD, DWORD, PSIZE_T);

typedef BOOL (WINAPI *UpdateProcThreadAttrFn)(
    LPPROC_THREAD_ATTRIBUTE_LIST, DWORD, DWORD_PTR,
    PVOID, SIZE_T, PVOID, PSIZE_T);

typedef VOID (WINAPI *DeleteProcThreadAttrListFn)(
     LPPROC_THREAD_ATTRIBUTE_LIST);


static InitProcThreadAttrListFn init_proc_thread_attr_list = NULL;
static UpdateProcThreadAttrFn update_proc_thread_attr = NULL;
static DeleteProcThreadAttrListFn delete_proc_thread_attr_list = NULL;


static bool EnsureInitialized() {
  static bool load_attempted = false;
  static dart::Mutex* mutex = new dart::Mutex();
  HMODULE kernel32_module = GetModuleHandleW(L"kernel32.dll");
  if (!load_attempted) {
    MutexLocker locker(mutex);
    if (load_attempted) return delete_proc_thread_attr_list != NULL;
    init_proc_thread_attr_list = reinterpret_cast<InitProcThreadAttrListFn>(
        GetProcAddress(kernel32_module, "InitializeProcThreadAttributeList"));
    update_proc_thread_attr =
        reinterpret_cast<UpdateProcThreadAttrFn>(
            GetProcAddress(kernel32_module, "UpdateProcThreadAttribute"));
    delete_proc_thread_attr_list = reinterpret_cast<DeleteProcThreadAttrListFn>(
        reinterpret_cast<DeleteProcThreadAttrListFn>(
            GetProcAddress(kernel32_module, "DeleteProcThreadAttributeList")));
    load_attempted = true;
    return delete_proc_thread_attr_list != NULL;
  }
  return delete_proc_thread_attr_list != NULL;
}


const int kMaxPipeNameSize = 80;
template<int Count>
static int GenerateNames(wchar_t pipe_names[Count][kMaxPipeNameSize]) {
  UUID uuid;
  RPC_STATUS status = UuidCreateSequential(&uuid);
  if (status != RPC_S_OK && status != RPC_S_UUID_LOCAL_ONLY) {
    return status;
  }
  RPC_WSTR uuid_string;
  status = UuidToStringW(&uuid, &uuid_string);
  if (status != RPC_S_OK) {
    return status;
  }
  for (int i = 0; i < Count; i++) {
    static const wchar_t* prefix = L"\\\\.\\Pipe\\dart";
    _snwprintf(pipe_names[i],
               kMaxPipeNameSize,
               L"%s_%s_%d", prefix, uuid_string, i + 1);
  }
  status = RpcStringFreeW(&uuid_string);
  if (status != RPC_S_OK) {
    return status;
  }
  return 0;
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
                   char** os_error_message) {
  HANDLE stdin_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE stdout_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE stderr_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };
  HANDLE exit_handles[2] = { INVALID_HANDLE_VALUE, INVALID_HANDLE_VALUE };

  // Generate unique pipe names for the four named pipes needed.
  wchar_t pipe_names[4][kMaxPipeNameSize];
  int status = GenerateNames<4>(pipe_names);
  if (status != 0) {
    SetOsErrorMessage(os_error_message);
    Log::PrintErr("UuidCreateSequential failed %d\n", status);
    return status;
  }

  if (!CreateProcessPipe(stdin_handles, pipe_names[0], kInheritRead)) {
    int error_code = SetOsErrorMessage(os_error_message);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }
  if (!CreateProcessPipe(stdout_handles, pipe_names[1], kInheritWrite)) {
    int error_code = SetOsErrorMessage(os_error_message);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }
  if (!CreateProcessPipe(stderr_handles, pipe_names[2], kInheritWrite)) {
    int error_code = SetOsErrorMessage(os_error_message);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }
  if (!CreateProcessPipe(exit_handles, pipe_names[3], kInheritNone)) {
    int error_code = SetOsErrorMessage(os_error_message);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    return error_code;
  }

  // Setup info structures.
  STARTUPINFOEXW startup_info;
  ZeroMemory(&startup_info, sizeof(startup_info));
  startup_info.StartupInfo.cb = sizeof(startup_info);
  startup_info.StartupInfo.hStdInput = stdin_handles[kReadHandle];
  startup_info.StartupInfo.hStdOutput = stdout_handles[kWriteHandle];
  startup_info.StartupInfo.hStdError = stderr_handles[kWriteHandle];
  startup_info.StartupInfo.dwFlags = STARTF_USESTDHANDLES;

  LPPROC_THREAD_ATTRIBUTE_LIST attribute_list = NULL;

  bool supports_proc_thread_attr_lists = EnsureInitialized();
  if (supports_proc_thread_attr_lists) {
    // Setup the handles to inherit. We only want to inherit the three handles
    // for stdin, stdout and stderr.
    SIZE_T size = 0;
    // The call to determine the size of an attribute list always fails with
    // ERROR_INSUFFICIENT_BUFFER and that error should be ignored.
    if (!init_proc_thread_attr_list(NULL, 1, 0, &size) &&
        GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
      int error_code = SetOsErrorMessage(os_error_message);
      CloseProcessPipes(
          stdin_handles, stdout_handles, stderr_handles, exit_handles);
      return error_code;
    }
    attribute_list =
        reinterpret_cast<LPPROC_THREAD_ATTRIBUTE_LIST>(malloc(size));
    ZeroMemory(attribute_list, size);
    if (!init_proc_thread_attr_list(attribute_list, 1, 0, &size)) {
      int error_code = SetOsErrorMessage(os_error_message);
      CloseProcessPipes(
          stdin_handles, stdout_handles, stderr_handles, exit_handles);
      free(attribute_list);
      return error_code;
    }
    static const int kNumInheritedHandles = 3;
    HANDLE inherited_handles[kNumInheritedHandles] =
        { stdin_handles[kReadHandle],
          stdout_handles[kWriteHandle],
          stderr_handles[kWriteHandle] };
    if (!update_proc_thread_attr(attribute_list,
                                 0,
                                 PROC_THREAD_ATTRIBUTE_HANDLE_LIST,
                                 inherited_handles,
                                 kNumInheritedHandles * sizeof(HANDLE),
                                 NULL,
                                 NULL)) {
      delete_proc_thread_attr_list(attribute_list);
      int error_code = SetOsErrorMessage(os_error_message);
      CloseProcessPipes(
          stdin_handles, stdout_handles, stderr_handles, exit_handles);
      free(attribute_list);
      return error_code;
    }
    startup_info.lpAttributeList = attribute_list;
  }

  PROCESS_INFORMATION process_info;
  ZeroMemory(&process_info, sizeof(process_info));

  // Transform input strings to system format.
  const wchar_t* system_path = StringUtils::Utf8ToWide(path);
  wchar_t** system_arguments = new wchar_t*[arguments_length];
  for (int i = 0; i < arguments_length; i++) {
     system_arguments[i] = StringUtils::Utf8ToWide(arguments[i]);
  }

  // Compute command-line length.
  int command_line_length = wcslen(system_path);
  for (int i = 0; i < arguments_length; i++) {
    command_line_length += wcslen(system_arguments[i]);
  }
  // Account for null termination and one space per argument.
  command_line_length += arguments_length + 1;
  static const int kMaxCommandLineLength = 32768;
  if (command_line_length > kMaxCommandLineLength) {
    int error_code = SetOsErrorMessage(os_error_message);
    CloseProcessPipes(
        stdin_handles, stdout_handles, stderr_handles, exit_handles);
    free(const_cast<wchar_t*>(system_path));
    for (int i = 0; i < arguments_length; i++) free(system_arguments[i]);
    delete[] system_arguments;
    if (supports_proc_thread_attr_lists) {
      delete_proc_thread_attr_list(attribute_list);
      free(attribute_list);
    }
    return error_code;
  }

  // Put together command-line string.
  wchar_t* command_line = new wchar_t[command_line_length];
  int len = 0;
  int remaining = command_line_length;
  int written = _snwprintf(command_line + len, remaining, L"%s", system_path);
  len += written;
  remaining -= written;
  ASSERT(remaining >= 0);
  for (int i = 0; i < arguments_length; i++) {
    written =
        _snwprintf(command_line + len, remaining, L" %s", system_arguments[i]);
    len += written;
    remaining -= written;
    ASSERT(remaining >= 0);
  }
  free(const_cast<wchar_t*>(system_path));
  for (int i = 0; i < arguments_length; i++) free(system_arguments[i]);
  delete[] system_arguments;

  // Create environment block if an environment is supplied.
  wchar_t* environment_block = NULL;
  if (environment != NULL) {
    wchar_t** system_environment = new wchar_t*[environment_length];
    // Convert environment strings to system strings.
    for (intptr_t i = 0; i < environment_length; i++) {
      system_environment[i] = StringUtils::Utf8ToWide(environment[i]);
    }

    // An environment block is a sequence of zero-terminated strings
    // followed by a block-terminating zero char.
    intptr_t block_size = 1;
    for (intptr_t i = 0; i < environment_length; i++) {
      block_size += wcslen(system_environment[i]) + 1;
    }
    environment_block = new wchar_t[block_size];
    intptr_t block_index = 0;
    for (intptr_t i = 0; i < environment_length; i++) {
      intptr_t len = wcslen(system_environment[i]);
      intptr_t result = _snwprintf(environment_block + block_index,
                                   len,
                                   L"%s",
                                   system_environment[i]);
      ASSERT(result == len);
      block_index += len;
      environment_block[block_index++] = '\0';
    }
    // Block-terminating zero char.
    environment_block[block_index++] = '\0';
    ASSERT(block_index == block_size);
    for (intptr_t i = 0; i < environment_length; i++) {
      free(system_environment[i]);
    }
    delete[] system_environment;
  }

  const wchar_t* system_working_directory = NULL;
  if (working_directory != NULL) {
    system_working_directory = StringUtils::Utf8ToWide(working_directory);
  }

  // Create process.
  DWORD creation_flags =
      EXTENDED_STARTUPINFO_PRESENT | CREATE_UNICODE_ENVIRONMENT;
  BOOL result = CreateProcessW(NULL,   // ApplicationName
                               command_line,
                               NULL,   // ProcessAttributes
                               NULL,   // ThreadAttributes
                               TRUE,   // InheritHandles
                               creation_flags,
                               environment_block,
                               system_working_directory,
                               reinterpret_cast<STARTUPINFOW*>(&startup_info),
                               &process_info);

  // Deallocate command-line and environment block strings.
  delete[] command_line;
  delete[] environment_block;
  if (system_working_directory != NULL) {
    free(const_cast<wchar_t*>(system_working_directory));
  }

  if (supports_proc_thread_attr_lists) {
    delete_proc_thread_attr_list(attribute_list);
    free(attribute_list);
  }

  if (result == 0) {
    int error_code = SetOsErrorMessage(os_error_message);
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


class BufferList: public BufferListBase {
 public:
  BufferList() : read_pending_(true) { }

  // Indicate that data has been read into the buffer provided to
  // overlapped read.
  void DataIsRead(intptr_t size) {
    ASSERT(read_pending_ == true);
    data_size_ += size;
    free_size_ -= size;
    ASSERT(free_size_ >= 0);
    read_pending_ = false;
  }

  // The access to the read buffer for overlapped read.
  void GetReadBuffer(uint8_t** buffer, intptr_t* size) {
    ASSERT(!read_pending_);
    if (free_size_ == 0) Allocate();
    ASSERT(free_size_ > 0);
    ASSERT(free_size_ <= kBufferSize);
    *buffer = FreeSpaceAddress();
    *size = free_size_;
    read_pending_ = true;
  }

  intptr_t GetDataSize() {
    return data_size_;
  }

  uint8_t* GetFirstDataBuffer() {
    ASSERT(head_ != NULL);
    ASSERT(head_ == tail_);
    ASSERT(data_size_ <= kBufferSize);
    return head_->data_;
  }

  void FreeDataBuffer() {
    Free();
  }

 private:
  bool read_pending_;
};


class OverlappedHandle {
 public:
  void Init(HANDLE handle, HANDLE event) {
    handle_ = handle;
    event_ = event;
    ClearOverlapped();
  }

  bool HasEvent(HANDLE event) {
    return event_ == event;
  }

  bool Read() {
    // Get the data read as a result of a completed overlapped operation.
    if (overlapped_.InternalHigh > 0) {
      buffer_.DataIsRead(overlapped_.InternalHigh);
    } else {
      buffer_.DataIsRead(0);
    }

    // Keep reading until error or pending operation.
    while (true) {
      ClearOverlapped();
      uint8_t* buffer;
      intptr_t buffer_size;
      buffer_.GetReadBuffer(&buffer, &buffer_size);
      BOOL ok = ReadFile(handle_, buffer, buffer_size, NULL, &overlapped_);
      if (!ok) return GetLastError() == ERROR_IO_PENDING;
      buffer_.DataIsRead(overlapped_.InternalHigh);
    }
  }

  Dart_Handle GetData() {
    return buffer_.GetData();
  }

  intptr_t GetDataSize() {
    return buffer_.GetDataSize();
  }

  uint8_t* GetFirstDataBuffer() {
    return buffer_.GetFirstDataBuffer();
  }

  void FreeDataBuffer() {
    return buffer_.FreeDataBuffer();
  }

  void Close() {
    CloseHandle(handle_);
    CloseHandle(event_);
    handle_ = INVALID_HANDLE_VALUE;
    overlapped_.hEvent = INVALID_HANDLE_VALUE;
  }

 private:
  void ClearOverlapped() {
    memset(&overlapped_, 0, sizeof(overlapped_));
    overlapped_.hEvent = event_;
  }

  OVERLAPPED overlapped_;
  HANDLE handle_;
  HANDLE event_;
  BufferList buffer_;

  DISALLOW_ALLOCATION();
};


bool Process::Wait(intptr_t pid,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_event,
                   ProcessResult* result) {
  // Close input to the process right away.
  reinterpret_cast<FileHandle*>(in)->Close();

  // All pipes created to the sub-process support overlapped IO.
  FileHandle* stdout_handle = reinterpret_cast<FileHandle*>(out);
  ASSERT(stdout_handle->SupportsOverlappedIO());
  FileHandle* stderr_handle = reinterpret_cast<FileHandle*>(err);
  ASSERT(stderr_handle->SupportsOverlappedIO());
  FileHandle* exit_handle = reinterpret_cast<FileHandle*>(exit_event);
  ASSERT(exit_handle->SupportsOverlappedIO());

  // Create three events for overlapped IO. These are created as already
  // signalled to ensure they have read called at least once.
  static const int kHandles = 3;
  HANDLE events[kHandles];
  for (int i = 0; i < kHandles; i++) {
    events[i] = CreateEvent(NULL, FALSE, TRUE, NULL);
  }

  // Setup the structure for handling overlapped IO.
  OverlappedHandle oh[kHandles];
  oh[0].Init(stdout_handle->handle(), events[0]);
  oh[1].Init(stderr_handle->handle(), events[1]);
  oh[2].Init(exit_handle->handle(), events[2]);

  // Continue until all handles are closed.
  int alive = kHandles;
  while (alive > 0) {
    // Blocking call waiting for events from the child process.
    DWORD wait_result = WaitForMultipleObjects(alive, events, FALSE, INFINITE);

    // Find the handle signalled.
    int index = wait_result - WAIT_OBJECT_0;
    for (int i = 0; i < kHandles; i++) {
      if (oh[i].HasEvent(events[index])) {
        bool ok = oh[i].Read();
        if (!ok) {
          if (GetLastError() == ERROR_BROKEN_PIPE) {
            oh[i].Close();
            alive--;
            if (index < alive) {
              events[index] = events[alive];
            }
          } else if (err != ERROR_IO_PENDING) {
            DWORD e = GetLastError();
            oh[0].Close();
            oh[1].Close();
            oh[2].Close();
            SetLastError(e);
            return false;
          }
        }
        break;
      }
    }
  }

  // All handles closed and all data read.
  result->set_stdout_data(oh[0].GetData());
  result->set_stderr_data(oh[1].GetData());

  // Calculate the exit code.
  ASSERT(oh[2].GetDataSize() == 8);
  uint32_t exit[2];
  memmove(&exit, oh[2].GetFirstDataBuffer(), sizeof(exit));
  oh[2].FreeDataBuffer();
  intptr_t exit_code = exit[0];
  intptr_t negative = exit[1];
  if (negative) exit_code = -exit_code;
  result->set_exit_code(exit_code);
  return true;
}


bool Process::Kill(intptr_t id, int signal) {
  USE(signal);  // signal is not used on windows.
  HANDLE process_handle;
  HANDLE wait_handle;
  HANDLE exit_pipe;
  bool success = ProcessInfoList::LookupProcess(id,
                                                &process_handle,
                                                &wait_handle,
                                                &exit_pipe);
  // The process is already dead.
  if (!success) return false;
  BOOL result = TerminateProcess(process_handle, -1);
  return result ? true : false;
}


void Process::TerminateExitCodeHandler() {
  // Nothing needs to be done on Windows.
}


intptr_t Process::CurrentProcessId() {
  return static_cast<intptr_t>(GetCurrentProcessId());
}


static SignalInfo* signal_handlers = NULL;
static Mutex* signal_mutex = new Mutex();


SignalInfo::~SignalInfo() {
  reinterpret_cast<FileHandle*>(fd_)->Close();
}


BOOL WINAPI SignalHandler(DWORD signal) {
  MutexLocker lock(signal_mutex);
  const SignalInfo* handler = signal_handlers;
  bool handled = false;
  while (handler != NULL) {
    if (handler->signal() == signal) {
      int value = 0;
      Socket::Write(handler->fd(), &value, 1);
      handled = true;
    }
    handler = handler->next();
  }
  return handled;
}


intptr_t GetWinSignal(intptr_t signal) {
  switch (signal) {
    case kSighup: return CTRL_CLOSE_EVENT;
    case kSigint: return CTRL_C_EVENT;
    default:
      return -1;
  }
}


intptr_t Process::SetSignalHandler(intptr_t signal) {
  signal = GetWinSignal(signal);
  if (signal == -1) return -1;

  // Generate a unique pipe name for the named pipe.
  wchar_t pipe_name[kMaxPipeNameSize];
  int status = GenerateNames<1>(&pipe_name);
  if (status != 0) return status;

  HANDLE fds[2];
  if (!CreateProcessPipe(fds, pipe_name, kInheritNone)) {
    int error_code = GetLastError();
    CloseProcessPipe(fds);
    SetLastError(error_code);
    return -1;
  }
  MutexLocker lock(signal_mutex);
  FileHandle* write_handle = new FileHandle(fds[kWriteHandle]);
  write_handle->EnsureInitialized(EventHandler::delegate());
  intptr_t write_fd = reinterpret_cast<intptr_t>(write_handle);
  if (signal_handlers == NULL) {
    if (SetConsoleCtrlHandler(SignalHandler, true) == 0) {
      int error_code = GetLastError();
      delete write_handle;
      CloseProcessPipe(fds);
      SetLastError(error_code);
      return -1;
    }
  }
  signal_handlers = new SignalInfo(write_fd, signal, signal_handlers);
  return reinterpret_cast<intptr_t>(new FileHandle(fds[kReadHandle]));
}


void Process::ClearSignalHandler(intptr_t signal) {
  signal = GetWinSignal(signal);
  if (signal == -1) return;
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  while (handler != NULL) {
    if (handler->port() == Dart_GetMainPortId() &&
        handler->signal() == signal) {
      handler->Unlink();
      break;
    }
    handler = handler->next();
  }
  if (handler != NULL) {
    if (signal_handlers == handler) {
      signal_handlers = handler->next();
    }
    if (signal_handlers == NULL) {
      USE(SetConsoleCtrlHandler(SignalHandler, false));
    }
  }
  delete handler;
}

}  // namespace bin
}  // namespace dart

#endif  // defined(TARGET_OS_WINDOWS)
