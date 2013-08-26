// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// TODO(ager): The only reason for this class is that we
// cannot patch a top-level at this point.
class _ProcessUtils {
  external static void _exit(int status);
  external static void _setExitCode(int status);
  external static void _sleep(int millis);
  external static int _pid(Process process);
}

/**
 * Exit the Dart VM process immediately with the given [status] code.
 *
 * This does not wait for any asynchronous operations to terminate. Using
 * [exit] is therefore very likely to lose data.
 */
void exit(int status) {
  if (status is !int) {
    throw new ArgumentError("exit: int status expected");
  }
  _ProcessUtils._exit(status);
}

/**
 * Global exit code for the Dart VM.
 *
 * The exit code is global for the Dart VM and the last assignment to
 * exitCode from any isolate determines the exit code of the Dart VM
 * on normal termination.
 */
set exitCode(int status) {
  if (status is !int) {
    throw new ArgumentError("setExitCode: int status expected");
  }
  _ProcessUtils._setExitCode(status);
}

/**
 * Sleep for the duration specified in [duration].
 *
 * Use this with care, as no asynchronous operations can be processed
 * in a isolate while it is blocked in a [sleep] call.
 */
void sleep(Duration duration) {
  int milliseconds = duration.inMilliseconds;
  if (milliseconds < 0) {
    throw new ArgumentError("sleep: duration cannot be negative");
  }
  _ProcessUtils._sleep(milliseconds);
}

/**
 * Returns the PID of the current process.
 */
int get pid => _ProcessUtils._pid(null);

/**
 * [Process] is used to start new processes using the static
 * [start] and [run] methods.
 */
abstract class Process {
  /**
   * Starts a process running the [executable] with the specified
   * [arguments]. Returns a [:Future<Process>:] that completes with a
   * Process instance when the process has been successfully
   * started. That [Process] object can be used to interact with the
   * process. If the process cannot be started the returned [Future]
   * completes with an exception.
   *
   * Use [workingDirectory] to set the working directory for the process. Note
   * that the change of directory occurs before executing the process on some
   * platforms, which may have impact when using relative paths for the
   * executable and the arguments.
   *
   * Use [environment] to set the environment variables for the process. If not
   * set the environment of the parent process is inherited. Currently, only
   * US-ASCII environment variables are supported and errors are likely to occur
   * if an environment variable with code-points outside the US-ASCII range is
   * passed in.
   *
   * If [includeParentEnvironment] is `true`, the process's environment will
   * include the parent process's environment, with [environment] taking
   * precedence. Default is `true`.
   *
   * If [runInShell] is true, the process will be spawned through a system
   * shell. On Linux and Mac OS, [:/bin/sh:] is used, while
   * [:%WINDIR%\system32\cmd.exe:] is used on Windows.
   *
   * Users must read all data coming on the [stdout] and [stderr]
   * streams of processes started with [:Process.start:]. If the user
   * does not read all data on the streams the underlying system
   * resources will not be freed since there is still pending data.
   */
  external static Future<Process> start(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       bool includeParentEnvironment: true,
       bool runInShell: false});

  /**
   * Starts a process and runs it non-interactively to completion. The
   * process run is [executable] with the specified [arguments].
   *
   * Use [workingDirectory] to set the working directory for the process. Note
   * that the change of directory occurs before executing the process on some
   * platforms, which may have impact when using relative paths for the
   * executable and the arguments.
   *
   * Use [environment] to set the environment variables for the process. If not
   * set the environment of the parent process is inherited. Currently, only
   * US-ASCII environment variables are supported and errors are likely to occur
   * if an environment variable with code-points outside the US-ASCII range is
   * passed in.
   *
   * If [includeParentEnvironment] is `true`, the process's environment will
   * include the parent process's environment, with [environment] taking
   * precedence. Default is `true`.
   *
   * If [runInShell] is true, the process will be spawned through a system
   * shell. On Linux and Mac OS, `/bin/sh` is used, while
   * `%WINDIR%\system32\cmd.exe` is used on Windows.
   *
   * The encoding used for decoding `stdout` and `stderr` into text is
   * controlled through [stdoutEncoding] and [stderrEncoding]. The
   * default encoding is [SYSTEM_ENCODING]. If `null` is used no
   * decoding will happen and the [ProcessResult] will hold binary
   * data.
   *
   * Returns a `Future<ProcessResult>` that completes with the
   * result of running the process, i.e., exit code, standard out and
   * standard in.
   */
  external static Future<ProcessResult> run(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       bool includeParentEnvironment: true,
       bool runInShell: false,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING});


  /**
   * Starts a process and runs it to completion. This is a synchronous
   * call and will block until the child process terminates.
   *
   * The arguments are the same as for `Process.run`.
   *
   * Returns a `ProcessResult` with the result of running the process,
   * i.e., exit code, standard out and standard in.
   */
  external static ProcessResult runSync(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       bool includeParentEnvironment: true,
       bool runInShell: false,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING});

  /**
   * Returns the standard output stream of the process as a [:Stream:].
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  Stream<List<int>> get stdout;

  /**
   * Returns the standard error stream of the process as a [:Stream:].
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  Stream<List<int>> get stderr;

  /**
   * Returns the standard input stream of the process as an [IOSink].
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  IOSink get stdin;

  /**
   * Returns the process id of the process.
   */
  int get pid;

  /**
   * Returns a [:Future:] which completes with the exit code of the process
   * when the process completes.
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  Future<int> exitCode;

  /**
   * On Windows, [kill] kills the process, ignoring the [signal]
   * flag. On Posix systems, [kill] sends [signal] to the
   * process. Depending on the signal giving, it'll have different
   * meanings. When the process terminates as a result of calling
   * [kill] [onExit] is called.
   *
   * Returns [:true:] if the process is successfully killed (the
   * signal is successfully sent). Returns [:false:] if the process
   * could not be killed (the signal could not be sent). Usually,
   * a [:false:] return value from kill means that the process is
   * already dead.
   */
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]);
}


/**
 * [ProcessResult] represents the result of running a non-interactive
 * process started with [:Process.run:].
 */
abstract class ProcessResult {
  /**
   * Exit code for the process.
   */
  int get exitCode;

  /**
   * Standard output from the process. The value used for the
   * `stdoutEncoding` argument to `Process.run` determins the type. If
   * `null` was used this value is of type `List<int> otherwise it is
   * of type `String`.
   */
  get stdout;

  /**
   * Standard error from the process. The value used for the
   * `stderrEncoding` argument to `Process.run` determins the type. If
   * `null` was used this value is of type `List<int>
   * otherwise it is of type `String`.
   */
  get stderr;

  /**
   * Process id from the process.
   */
  int get pid;
}


/**
 * On Posix systems, [ProcessSignal] is used to send a specific signal
 * to a child process, see [:Process.kill:].
 */
class ProcessSignal {
  static const ProcessSignal SIGHUP = const ProcessSignal._signal(1);
  static const ProcessSignal SIGINT = const ProcessSignal._signal(2);
  static const ProcessSignal SIGQUIT = const ProcessSignal._signal(3);
  static const ProcessSignal SIGILL = const ProcessSignal._signal(4);
  static const ProcessSignal SIGTRAP = const ProcessSignal._signal(5);
  static const ProcessSignal SIGABRT = const ProcessSignal._signal(6);
  static const ProcessSignal SIGBUS = const ProcessSignal._signal(7);
  static const ProcessSignal SIGFPE = const ProcessSignal._signal(8);
  static const ProcessSignal SIGKILL = const ProcessSignal._signal(9);
  static const ProcessSignal SIGUSR1 = const ProcessSignal._signal(10);
  static const ProcessSignal SIGSEGV = const ProcessSignal._signal(11);
  static const ProcessSignal SIGUSR2 = const ProcessSignal._signal(12);
  static const ProcessSignal SIGPIPE = const ProcessSignal._signal(13);
  static const ProcessSignal SIGALRM = const ProcessSignal._signal(14);
  static const ProcessSignal SIGTERM = const ProcessSignal._signal(15);
  static const ProcessSignal SIGCHLD = const ProcessSignal._signal(17);
  static const ProcessSignal SIGCONT = const ProcessSignal._signal(18);
  static const ProcessSignal SIGSTOP = const ProcessSignal._signal(19);
  static const ProcessSignal SIGTSTP = const ProcessSignal._signal(20);
  static const ProcessSignal SIGTTIN = const ProcessSignal._signal(21);
  static const ProcessSignal SIGTTOU = const ProcessSignal._signal(22);
  static const ProcessSignal SIGURG = const ProcessSignal._signal(23);
  static const ProcessSignal SIGXCPU = const ProcessSignal._signal(24);
  static const ProcessSignal SIGXFSZ = const ProcessSignal._signal(25);
  static const ProcessSignal SIGVTALRM = const ProcessSignal._signal(26);
  static const ProcessSignal SIGPROF = const ProcessSignal._signal(27);
  static const ProcessSignal SIGPOLL = const ProcessSignal._signal(29);
  static const ProcessSignal SIGSYS = const ProcessSignal._signal(31);

  const ProcessSignal._signal(int this._signalNumber);
  final int _signalNumber;
}


class ProcessException implements IOException {
  const ProcessException(String this.executable,
                         List<String> this.arguments,
                         [String this.message = "",
                          int this.errorCode = 0]);
  String toString() {
    var msg = (message == null) ? 'OS error code: $errorCode' : message;
    var args = arguments.join(' ');
    return "ProcessException: $msg\n  Command: $executable $args";
  }

  /**
   * Contains the executable provided for the process.
   */
  final String executable;

  /**
   * Contains the arguments provided for the process.
   */
  final List<String> arguments;

  /**
   * Contains the system message for the process exception if any.
   */
  final String message;

  /**
   * Contains the OS error code for the process exception if any.
   */
  final int errorCode;
}
