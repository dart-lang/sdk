// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include "platform/globals.h"
#if defined(DART_HOST_OS_MACOS)

#include "bin/process.h"

#include <errno.h>
#include <fcntl.h>
#include <mach/mach.h>
#include <poll.h>
#include <signal.h>
#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/event.h>
#include <unistd.h>

#include "bin/dartutils.h"
#include "bin/fdutils.h"
#include "bin/lockers.h"
#include "bin/namespace.h"
#include "bin/thread.h"
#include "platform/syslog.h"

#include "platform/signal_blocker.h"
#include "platform/utils.h"

namespace dart {
namespace bin {

int Process::global_exit_code_ = 0;
Mutex* Process::global_exit_code_mutex_ = nullptr;
Process::ExitHook Process::exit_hook_ = nullptr;

// Spawning new processes isn't supported on iOS.
#if !defined(DART_HOST_OS_IOS)

// The exit code handler sets up a separate thread which waits for child
// processes to terminate. That separate thread can then get the exit code from
// processes that have exited and communicate it to Dart through the
// event loop.
class ExitCodeHandler {
 public:
  static void Init();
  static void Cleanup();

  static void EnsureStarted() {
    MonitorLocker locker(monitor_);
    if (kqueue_fd_ != -1) {
      return;
    }

    kqueue_fd_ = NO_RETRY_EXPECTED(kqueue());
    if (kqueue_fd_ == -1) {
      FATAL("Failed creating kqueue");
    }
    if (!FDUtils::SetCloseOnExec(kqueue_fd_)) {
      FATAL("Failed to set kqueue fd close on exec\n");
    }

    // Start thread that handles process exits when wait returns.
    Thread::Start("dart:io Process.start", ExitCodeHandlerEntry, 0);
  }

  static void TerminateExitCodeThread() {
    MonitorLocker locker(monitor_);
    if (kqueue_fd_ == -1) {
      return;
    }

    struct kevent event;
    EV_SET(&event, kShutdown, EVFILT_USER, EV_ADD | EV_ENABLE | EV_ONESHOT,
           NOTE_TRIGGER, 0, 0);
    int status = kevent(kqueue_fd_, &event, 1, nullptr, 0, nullptr);
    if (status == -1) {
      FATAL("kevent failed");
    }

    while (kqueue_fd_ != -1) {
      locker.Wait();
    }
  }

  static void AddProcess(pid_t pid, int exit_pipe) {
    ASSERT(pid != kShutdown);

    struct kevent event;
    EV_SET(&event, pid, EVFILT_PROC, EV_ADD | EV_ONESHOT, NOTE_EXIT, 0,
           reinterpret_cast<void*>(exit_pipe));
    int status = kevent(kqueue_fd_, &event, 1, nullptr, 0, nullptr);
    if (status == -1) {
      if (errno == ESRCH) {
        // Process already exited.
        EV_SET(&event, pid, EVFILT_USER, EV_ADD | EV_ENABLE | EV_ONESHOT,
               NOTE_TRIGGER, 0, reinterpret_cast<void*>(exit_pipe));
        status = kevent(kqueue_fd_, &event, 1, nullptr, 0, nullptr);
        if (status == -1) {
          FATAL("kevent failed");
        }
      } else {
        FATAL("kevent failed");
      }
    }
  }

 private:
  // Entry point for the separate exit code handler thread started by
  // the ExitCodeHandler.
  static void ExitCodeHandlerEntry(uword param) {
    while (true) {
      struct kevent event;
      int r = kevent(kqueue_fd_, nullptr, 0, &event, 1, nullptr);
      if ((r == -1) && (errno != EINTR)) {
        FATAL("kevent failed");
      }
      if (r == 0) continue;
      ASSERT(event.filter == EVFILT_PROC || event.filter == EVFILT_USER);

      int exit_pipe = reinterpret_cast<intptr_t>(event.udata);
      pid_t pid = event.ident;

      if (pid == kShutdown) break;

      int status;
      pid_t wait_result;
      do {
        wait_result = waitpid(pid, &status, 0);
      } while (wait_result == -1 && errno == EINTR);
      ASSERT(wait_result == pid);

      int exit_code = 0;
      int negative = 0;
      if (WIFEXITED(status)) {
        exit_code = WEXITSTATUS(status);
      }
      if (WIFSIGNALED(status)) {
        exit_code = WTERMSIG(status);
        negative = 1;
      }

      int message[2] = {exit_code, negative};
      ssize_t result =
          FDUtils::WriteToBlocking(exit_pipe, &message, sizeof(message));
      // If the process has been closed, the read end of the exit
      // pipe has been closed. It is therefore not a problem that
      // write fails with a broken pipe error. Other errors should
      // not happen.
      if ((result != -1) && (result != sizeof(message))) {
        FATAL("Failed to write entire process exit message");
      } else if ((result == -1) && (errno != EPIPE)) {
        FATAL("Failed to write exit code: %d", errno);
      }
      close(exit_pipe);
    }

    MonitorLocker locker(monitor_);
    close(kqueue_fd_);
    kqueue_fd_ = -1;
    locker.NotifyAll();
  }

  static Monitor* monitor_;
  static int kqueue_fd_;
  static constexpr pid_t kShutdown = 0;

  DISALLOW_ALLOCATION();
  DISALLOW_IMPLICIT_CONSTRUCTORS(ExitCodeHandler);
};

Monitor* ExitCodeHandler::monitor_ = nullptr;
int ExitCodeHandler::kqueue_fd_ = -1;

class ProcessStarter {
 public:
  ProcessStarter(const char* path,
                 const char* arguments[],
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
    stdout_pipe_[0] = -1;
    stdout_pipe_[1] = -1;
    stderr_pipe_[0] = -1;
    stderr_pipe_[1] = -1;
    stdin_pipe_[0] = -1;
    stdin_pipe_[1] = -1;
    exit_pipe_[0] = -1;
    exit_pipe_[1] = -1;

    program_arguments_ = reinterpret_cast<const char**>(Dart_ScopeAllocate(
        (arguments_length + 2) * sizeof(*program_arguments_)));
    program_arguments_[0] = const_cast<char*>(path_);
    for (int i = 0; i < arguments_length; i++) {
      program_arguments_[i + 1] = arguments[i];
    }
    program_arguments_[arguments_length + 1] = nullptr;

    program_environment_ = nullptr;
    if (environment != nullptr) {
      program_environment_ = reinterpret_cast<char**>(Dart_ScopeAllocate(
          (environment_length + 1) * sizeof(*program_environment_)));
      for (int i = 0; i < environment_length; i++) {
        program_environment_[i] = environment[i];
      }
      program_environment_[environment_length] = nullptr;
    }
  }

  int Start() {
    // Create pipes required.
    int err = CreatePipes();
    if (err != 0) {
      return err;
    }

    pid_t pid;
    err = Spawn(&pid);
    if (err != 0) {
      errno = err;
      return CleanupAndReturnError();
    }

    if (Process::ModeIsAttached(mode_)) {
      ExitCodeHandler::EnsureStarted();
    }

    // If the child process is not started in detached mode, be sure to
    // listen for exit-codes, now that we have a non detached child process
    // and also Register this child process.
    if (Process::ModeIsAttached(mode_)) {
      RegisterProcess(pid);
    }

    if (Process::ModeHasStdio(mode_)) {
      // Connect stdio, stdout and stderr.
      FDUtils::SetNonBlocking(stdout_pipe_[0]);
      *in_ = stdout_pipe_[0];
      stdout_pipe_[0] = -1;
      CloseWriteEndOfPipe(stdout_pipe_);
      FDUtils::SetNonBlocking(stdin_pipe_[1]);
      *out_ = stdin_pipe_[1];
      stdin_pipe_[1] = -1;
      CloseReadEndOfPipe(stdin_pipe_);
      FDUtils::SetNonBlocking(stderr_pipe_[0]);
      *err_ = stderr_pipe_[0];
      stderr_pipe_[0] = -1;
      CloseWriteEndOfPipe(stderr_pipe_);
    } else {
      // Close all fds.
      ClosePipe(stdin_pipe_);
      ASSERT(stdout_pipe_[0] == -1);
      ASSERT(stdout_pipe_[1] == -1);
      ASSERT(stderr_pipe_[0] == -1);
      ASSERT(stderr_pipe_[1] == -1);
    }
    ASSERT(exit_pipe_[0] == -1);
    ASSERT(exit_pipe_[1] == -1);

    *id_ = pid;
    return 0;
  }

 private:
  int CreatePipes() {
    int result;

    if (Process::ModeHasStdio(mode_)) {
      result = TEMP_FAILURE_RETRY(pipe(stdin_pipe_));
      if (result < 0) {
        return CleanupAndReturnError();
      }
      FDUtils::SetCloseOnExec(stdin_pipe_[0]);
      FDUtils::SetCloseOnExec(stdin_pipe_[1]);

      result = TEMP_FAILURE_RETRY(pipe(stdout_pipe_));
      if (result < 0) {
        return CleanupAndReturnError();
      }
      FDUtils::SetCloseOnExec(stdout_pipe_[0]);
      FDUtils::SetCloseOnExec(stdout_pipe_[1]);

      result = TEMP_FAILURE_RETRY(pipe(stderr_pipe_));
      if (result < 0) {
        return CleanupAndReturnError();
      }
      FDUtils::SetCloseOnExec(stderr_pipe_[0]);
      FDUtils::SetCloseOnExec(stderr_pipe_[1]);
    }

    if (Process::ModeIsAttached(mode_)) {
      result = TEMP_FAILURE_RETRY(pipe(exit_pipe_));
      if (result < 0) {
        return CleanupAndReturnError();
      }
      FDUtils::SetCloseOnExec(exit_pipe_[0]);
      FDUtils::SetCloseOnExec(exit_pipe_[1]);
    }

    return 0;
  }

  int Spawn(pid_t* pid) {
#define TRY(expr)                                                              \
  do {                                                                         \
    int err = (expr);                                                          \
    if (err != 0) return err;                                                  \
  } while (false)

    class DestroyFileActions {
     public:
      explicit DestroyFileActions(posix_spawn_file_actions_t* facts)
          : facts_(facts) {}
      ~DestroyFileActions() { posix_spawn_file_actions_destroy(facts_); }
      posix_spawn_file_actions_t* facts_;
    };
    class DestroyAttr {
     public:
      explicit DestroyAttr(posix_spawnattr_t* attr) : attr_(attr) {}
      ~DestroyAttr() { posix_spawnattr_destroy(attr_); }
      posix_spawnattr_t* attr_;
    };

    posix_spawn_file_actions_t facts = {};
    posix_spawnattr_t attr = {};

    TRY(posix_spawn_file_actions_init(&facts));
    DestroyFileActions dfa(&facts);

    if (Process::ModeHasStdio(mode_)) {
      TRY(posix_spawn_file_actions_adddup2(&facts, stdin_pipe_[0],
                                           STDIN_FILENO));
      TRY(posix_spawn_file_actions_adddup2(&facts, stdout_pipe_[1],
                                           STDOUT_FILENO));
      TRY(posix_spawn_file_actions_adddup2(&facts, stderr_pipe_[1],
                                           STDERR_FILENO));
    } else if (mode_ == kDetached) {
      TRY(posix_spawn_file_actions_addopen(&facts, STDIN_FILENO, "/dev/null",
                                           O_RDWR, 0));
      TRY(posix_spawn_file_actions_addopen(&facts, STDOUT_FILENO, "/dev/null",
                                           O_RDWR, 0));
      TRY(posix_spawn_file_actions_addopen(&facts, STDERR_FILENO, "/dev/null",
                                           O_RDWR, 0));
    } else {
      ASSERT(mode_ == kInheritStdio);
      TRY(posix_spawn_file_actions_addinherit_np(&facts, STDIN_FILENO));
      TRY(posix_spawn_file_actions_addinherit_np(&facts, STDOUT_FILENO));
      TRY(posix_spawn_file_actions_addinherit_np(&facts, STDERR_FILENO));
    }

    if (working_directory_ != nullptr) {
      TRY(posix_spawn_file_actions_addchdir_np(&facts, working_directory_));
    }

    TRY(posix_spawnattr_init(&attr));
    DestroyAttr da(&attr);

    TRY(posix_spawnattr_setflags(
        &attr, POSIX_SPAWN_CLOEXEC_DEFAULT |
                   (Process::ModeIsAttached(mode_) ? 0 : POSIX_SPAWN_SETSID)));

    return posix_spawnp(pid, path_, &facts, &attr,
                        const_cast<char* const*>(program_arguments_),
                        program_environment_);
#undef TRY
  }

  void RegisterProcess(pid_t pid) {
    ASSERT(exit_pipe_[0] != -1);
    ASSERT(exit_pipe_[1] != -1);
    ExitCodeHandler::AddProcess(pid, exit_pipe_[1]);
    exit_pipe_[1] = -1;
    *exit_event_ = exit_pipe_[0];
    FDUtils::SetNonBlocking(exit_pipe_[0]);
    exit_pipe_[0] = -1;
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

  void ClosePipe(int* fds) {
    CloseReadEndOfPipe(fds);
    CloseWriteEndOfPipe(fds);
  }

  void CloseReadEndOfPipe(int* fds) {
    if (fds[0] != -1) {
      close(fds[0]);
      fds[0] = -1;
    }
  }

  void CloseWriteEndOfPipe(int* fds) {
    if (fds[1] != -1) {
      close(fds[1]);
      fds[1] = -1;
    }
  }

  void CloseAllPipes() {
    ClosePipe(stdout_pipe_);
    ClosePipe(stderr_pipe_);
    ClosePipe(stdin_pipe_);
    ClosePipe(exit_pipe_);
  }

  int stdout_pipe_[2];  // Pipe for stdout to child process.
  int stderr_pipe_[2];  // Pipe for stderr to child process.
  int stdin_pipe_[2];   // Pipe for stdin to child process.
  int exit_pipe_[2];    // Pipe for exit event.

  const char** program_arguments_;
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
#endif  // !defined(DART_HOST_OS_IOS)

int Process::Start(Namespace* namespc,
                   const char* path,
                   const char* arguments[],
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
#if defined(DART_HOST_OS_IOS)
  return EPERM;
#else   // defined(DART_HOST_OS_IOS)
  ProcessStarter starter(path, arguments, arguments_length, working_directory,
                         environment, environment_length, mode, in, out, err,
                         id, exit_event, os_error_message);
  return starter.Start();
#endif  // defined(DART_HOST_OS_IOS)
}

#if !defined(DART_HOST_OS_IOS)
static bool CloseProcessBuffers(struct pollfd* fds, int alive) {
  int e = errno;
  for (int i = 0; i < alive; i++) {
    close(fds[i].fd);
  }
  errno = e;
  return false;
}
#endif  // !defined(DART_HOST_OS_IOS)

bool Process::Wait(intptr_t pid,
                   intptr_t in,
                   intptr_t out,
                   intptr_t err,
                   intptr_t exit_event,
                   ProcessResult* result) {
#if defined(DART_HOST_OS_IOS)
  return false;
#else   // defined(DART_HOST_OS_IOS)
  // Close input to the process right away.
  close(in);

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
      return CloseProcessBuffers(fds, alive);
    }

    // Process incoming data.
    for (int i = 0; i < alive; i++) {
      intptr_t avail;
      if ((fds[i].revents & (POLLNVAL | POLLERR)) != 0) {
        return CloseProcessBuffers(fds, alive);
      }
      if ((fds[i].revents & POLLIN) != 0) {
        avail = FDUtils::AvailableBytes(fds[i].fd);
        // On Mac OS POLLIN can be set with zero available
        // bytes. POLLHUP is most likely also set in this case.
        if (avail > 0) {
          if (fds[i].fd == out) {
            if (!out_data.Read(out, avail)) {
              return CloseProcessBuffers(fds, alive);
            }
          } else if (fds[i].fd == err) {
            if (!err_data.Read(err, avail)) {
              return CloseProcessBuffers(fds, alive);
            }
          } else if (fds[i].fd == exit_event) {
            if (avail == 8) {
              intptr_t b =
                  TEMP_FAILURE_RETRY(read(exit_event, exit_code_data.bytes, 8));
              if (b != 8) {
                return CloseProcessBuffers(fds, alive);
              }
            }
          } else {
            UNREACHABLE();
          }
        }
      }
      if (((fds[i].revents & POLLHUP) != 0) ||
          (((fds[i].revents & POLLIN) != 0) && (avail == 0))) {
        // Remove the pollfd from the list of pollfds.
        close(fds[i].fd);
        alive--;
        if (i < alive) {
          fds[i] = fds[alive];
        }
        // Process the same index again.
        i--;
        continue;
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
#endif  // defined(DART_HOST_OS_IOS)
}

int Process::Exec(Namespace* namespc,
                  const char* path,
                  const char* arguments[],
                  intptr_t arguments_length,
                  const char* working_directory,
                  char* errmsg,
                  intptr_t errmsg_len) {
#if defined(DART_HOST_OS_WATCH)
  // execvp is not available on watchOS.
  Utils::StrError(ENOSYS, errmsg, errmsg_len);
  return -1;
#else
  if (working_directory != nullptr &&
      TEMP_FAILURE_RETRY(chdir(working_directory)) == -1) {
    Utils::StrError(errno, errmsg, errmsg_len);
    return -1;
  }

  execvp(const_cast<const char*>(path), const_cast<char* const*>(arguments));
  Utils::StrError(errno, errmsg, errmsg_len);
  return -1;
#endif
}

static int SignalMap(intptr_t id) {
  switch (static_cast<ProcessSignals>(id)) {
    case kSighup:
      return SIGHUP;
    case kSigint:
      return SIGINT;
    case kSigquit:
      return SIGQUIT;
    case kSigill:
      return SIGILL;
    case kSigtrap:
      return SIGTRAP;
    case kSigabrt:
      return SIGABRT;
    case kSigbus:
      return SIGBUS;
    case kSigfpe:
      return SIGFPE;
    case kSigkill:
      return SIGKILL;
    case kSigusr1:
      return SIGUSR1;
    case kSigsegv:
      return SIGSEGV;
    case kSigusr2:
      return SIGUSR2;
    case kSigpipe:
      return SIGPIPE;
    case kSigalrm:
      return SIGALRM;
    case kSigterm:
      return SIGTERM;
    case kSigchld:
      return SIGCHLD;
    case kSigcont:
      return SIGCONT;
    case kSigstop:
      return SIGSTOP;
    case kSigtstp:
      return SIGTSTP;
    case kSigttin:
      return SIGTTIN;
    case kSigttou:
      return SIGTTOU;
    case kSigurg:
      return SIGURG;
    case kSigxcpu:
      return SIGXCPU;
    case kSigxfsz:
      return SIGXFSZ;
    case kSigvtalrm:
      return SIGVTALRM;
    case kSigprof:
      return SIGPROF;
    case kSigwinch:
      return SIGWINCH;
    case kSigpoll:
      return -1;
    case kSigsys:
      return SIGSYS;
  }
  return -1;
}

bool Process::Kill(intptr_t id, int signal) {
#if defined(DART_HOST_OS_IOS)
  return false;
#else   // defined(DART_HOST_OS_IOS)
  return (TEMP_FAILURE_RETRY(kill(id, SignalMap(signal))) != -1);
#endif  // defined(DART_HOST_OS_IOS)
}

void Process::TerminateExitCodeHandler() {
#if !defined(DART_HOST_OS_IOS)
  ExitCodeHandler::TerminateExitCodeThread();
#endif  // !defined(DART_HOST_OS_IOS)
}

intptr_t Process::CurrentProcessId() {
  return static_cast<intptr_t>(getpid());
}

int64_t Process::CurrentRSS() {
  struct mach_task_basic_info info;
  mach_msg_type_number_t infoCount = MACH_TASK_BASIC_INFO_COUNT;
  kern_return_t result =
      task_info(mach_task_self(), MACH_TASK_BASIC_INFO,
                reinterpret_cast<task_info_t>(&info), &infoCount);
  if (result != KERN_SUCCESS) {
    return -1;
  }
  return info.resident_size;
}

int64_t Process::MaxRSS() {
  struct rusage usage;
  usage.ru_maxrss = 0;
  int r = getrusage(RUSAGE_SELF, &usage);
  if (r < 0) {
    return -1;
  }
  return usage.ru_maxrss;
}

static Mutex* signal_mutex = nullptr;
static SignalInfo* signal_handlers = nullptr;
static constexpr int kSignalsCount = 7;
static const int kSignals[kSignalsCount] = {
    SIGHUP, SIGINT, SIGTERM, SIGUSR1, SIGUSR2, SIGWINCH,
    SIGQUIT  // Allow VMService to listen on SIGQUIT.
};

SignalInfo::~SignalInfo() {
  close(fd_);
}

static void SignalHandler(int signal) {
  MutexLocker lock(signal_mutex);
  const SignalInfo* handler = signal_handlers;
  while (handler != nullptr) {
    if (handler->signal() == signal) {
      int value = 0;
      VOID_TEMP_FAILURE_RETRY(write(handler->fd(), &value, 1));
    }
    handler = handler->next();
  }
}

intptr_t Process::SetSignalHandler(intptr_t signal) {
  signal = SignalMap(signal);
  if (signal == -1) {
    return -1;
  }
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
  if (NO_RETRY_EXPECTED(pipe(fds)) != 0) {
    return -1;
  }
  if (!FDUtils::SetCloseOnExec(fds[0]) || !FDUtils::SetCloseOnExec(fds[1]) ||
      !FDUtils::SetNonBlocking(fds[0])) {
    close(fds[0]);
    close(fds[1]);
    return -1;
  }
  ThreadSignalBlocker blocker(kSignalsCount, kSignals);
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  bool listen = true;
  sa_handler_t oldact_handler = nullptr;
  while (handler != nullptr) {
    if (handler->signal() == signal) {
      oldact_handler = handler->oldact();
      listen = false;
      break;
    }
    handler = handler->next();
  }
  if (listen) {
    struct sigaction act = {};
    act.sa_handler = SignalHandler;
    sigemptyset(&act.sa_mask);
    for (int i = 0; i < kSignalsCount; i++) {
      sigaddset(&act.sa_mask, kSignals[i]);
    }
    struct sigaction oldact = {};
    intptr_t status = NO_RETRY_EXPECTED(sigaction(signal, &act, &oldact));
    if (status < 0) {
      close(fds[0]);
      close(fds[1]);
      return -1;
    }
    oldact_handler = oldact.sa_handler;
  }
  signal_handlers =
      new SignalInfo(fds[1], signal, oldact_handler, signal_handlers);
  return fds[0];
}

void Process::ClearSignalHandler(intptr_t signal, Dart_Port port) {
  signal = SignalMap(signal);
  if (signal == -1) {
    return;
  }
  ThreadSignalBlocker blocker(kSignalsCount, kSignals);
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  sa_handler_t oldact_handler = SIG_DFL;
  bool any_removed = false;
  bool any_remaining = false;
  while (handler != nullptr) {
    bool remove = false;
    if (handler->signal() == signal) {
      if ((port == ILLEGAL_PORT) || (handler->port() == port)) {
        if (signal_handlers == handler) {
          signal_handlers = handler->next();
        }
        handler->Unlink();
        remove = true;
        oldact_handler = handler->oldact();
        any_removed = true;
      } else {
        any_remaining = true;
      }
    }
    SignalInfo* next = handler->next();
    if (remove) {
      delete handler;
    }
    handler = next;
  }
  if (any_removed && !any_remaining) {
    struct sigaction act = {};
    act.sa_handler = oldact_handler;
    VOID_NO_RETRY_EXPECTED(sigaction(signal, &act, nullptr));
  }
}

void Process::ClearSignalHandlerByFd(intptr_t fd, Dart_Port port) {
  ThreadSignalBlocker blocker(kSignalsCount, kSignals);
  MutexLocker lock(signal_mutex);
  SignalInfo* handler = signal_handlers;
  sa_handler_t oldact_handler = SIG_DFL;
  bool any_remaining = false;
  intptr_t signal = -1;
  while (handler != nullptr) {
    bool remove = false;
    if (handler->fd() == fd) {
      if ((port == ILLEGAL_PORT) || (handler->port() == port)) {
        if (signal_handlers == handler) {
          signal_handlers = handler->next();
        }
        handler->Unlink();
        remove = true;
        signal = handler->signal();
      } else {
        any_remaining = true;
      }
    }
    SignalInfo* next = handler->next();
    if (remove) {
      delete handler;
    }
    handler = next;
  }
  if ((signal != -1) && !any_remaining) {
    struct sigaction act = {};
    act.sa_handler = oldact_handler;
    VOID_NO_RETRY_EXPECTED(sigaction(signal, &act, nullptr));
  }
}

#if !defined(DART_HOST_OS_IOS)
void ExitCodeHandler::Init() {
  ASSERT(ExitCodeHandler::monitor_ == nullptr);
  ExitCodeHandler::monitor_ = new Monitor();
}

void ExitCodeHandler::Cleanup() {
  ASSERT(ExitCodeHandler::monitor_ != nullptr);
  delete ExitCodeHandler::monitor_;
  ExitCodeHandler::monitor_ = nullptr;
}
#endif  // !defined(DART_HOST_OS_IOS)

void Process::Init() {
#if !defined(DART_HOST_OS_IOS)
  ExitCodeHandler::Init();
#endif  // !defined(DART_HOST_OS_IOS)

  ASSERT(signal_mutex == nullptr);
  signal_mutex = new Mutex();
  signal_handlers = nullptr;

  ASSERT(Process::global_exit_code_mutex_ == nullptr);
  Process::global_exit_code_mutex_ = new Mutex();
}

void Process::Cleanup() {
  ClearAllSignalHandlers();

  ASSERT(signal_mutex != nullptr);
  delete signal_mutex;
  signal_mutex = nullptr;

  ASSERT(Process::global_exit_code_mutex_ != nullptr);
  delete Process::global_exit_code_mutex_;
  Process::global_exit_code_mutex_ = nullptr;

#if !defined(DART_HOST_OS_IOS)
  ExitCodeHandler::Cleanup();
#endif  // !defined(DART_HOST_OS_IOS)
}

}  // namespace bin
}  // namespace dart

#endif  // defined(DART_HOST_OS_MACOS)
