// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.io;

// TODO(ager): The only reason for this class is that we
// cannot patch a top-level at this point.
class _ProcessUtils {
  external static void _exit(int status);
  external static void _setExitCode(int status);
  external static int _getExitCode();
  external static void _sleep(int millis);
  external static int _pid(Process process);
  external static Stream<ProcessSignal> _watchSignal(ProcessSignal signal);
}

/**
 * Exit the Dart VM process immediately with the given exit code.
 *
 * This does not wait for any asynchronous operations to terminate. Using
 * [exit] is therefore very likely to lose data.
 *
 * The handling of exit codes is platform specific.
 *
 * On Linux and Mac OS an exit code for normal termination will always
 * be in the range [0..255]. If an exit code outside this range is
 * set the actual exit code will be the lower 8 bits masked off and
 * treated as an unsigned value. E.g. using an exit code of -1 will
 * result in an actual exit code of 255 being reported.
 *
 * On Windows the exit code can be set to any 32-bit value. However
 * some of these values are reserved for reporting system errors like
 * crashes.
 *
 * Besides this the Dart executable itself uses an exit code of `254`
 * for reporting compile time errors and an exit code of `255` for
 * reporting runtime error (unhandled exception).
 *
 * Due to these facts it is recommended to only use exit codes in the
 * range [0..127] for communicating the result of running a Dart
 * program to the surrounding environment. This will avoid any
 * cross-platform issues.
 */
void exit(int code) {
  if (code is !int) {
    throw new ArgumentError("Integer value for exit code expected");
  }
  _ProcessUtils._exit(code);
}

/**
 * Set the global exit code for the Dart VM.
 *
 * The exit code is global for the Dart VM and the last assignment to
 * exitCode from any isolate determines the exit code of the Dart VM
 * on normal termination.
 *
 * Default value is `0`.
 *
 * See [exit] for more information on how to chose a value for the
 * exit code.
 */
void set exitCode(int code) {
  if (code is !int) {
    throw new ArgumentError("Integer value for exit code expected");
  }
  _ProcessUtils._setExitCode(code);
}

/*
 * Get the global exit code for the Dart VM.
 *
 * The exit code is global for the Dart VM and the last assignment to
 * exitCode from any isolate determines the exit code of the Dart VM
 * on normal termination.
 *
 * See [exit] for more information on how to chose a value for the
 * exit code.
 */
int get exitCode => _ProcessUtils._getExitCode();

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
 * The means to execute a program.
 *
 * Use the static [start] and [run] methods to start a new process.
 * The run method executes the process non-interactively to completion.
 * In contrast, the start method allows your code to interact with the
 * running process.
 *
 * ## Start a process with the run method
 *
 * The following code sample uses the run method to create a process
 * that runs the UNIX command `ls`, which lists the contents of a directory.
 * The run method completes with a [ProcessResult] object when the process
 * terminates. This provides access to the output and exit code from the
 * process. The run method does not return a Process object; this prevents your
 * code from interacting with the running process.
 *
 *     import 'dart:io';
 *
 *     main() {
 *       // List all files in the current directory in UNIX-like systems.
 *       Process.run('ls', ['-l']).then((ProcessResult results) {
 *         print(results.stdout);
 *       });
 *     }
 *
 * ## Start a process with the start method
 *
 * The following example uses start to create the process.
 * The start method returns a [Future] for a Process object.
 * When the future completes the process is started and
 * your code can interact with the
 * Process: writing to stdin, listening to stdout, and so on.
 *
 * The following sample starts the UNIX `cat` utility, which when given no
 * command-line arguments, echos its input.
 * The program writes to the process's standard input stream
 * and prints data from its standard output stream.
 *
 *     import 'dart:io';
 *     import 'dart:convert';
 *
 *     main() {
 *       Process.start('cat', []).then((Process process) {
 *         process.stdout
 *             .transform(UTF8.decoder)
 *             .listen((data) { print(data); });
 *         process.stdin.writeln('Hello, world!');
 *         process.stdin.writeln('Hello, galaxy!');
 *         process.stdin.writeln('Hello, universe!');
 *       });
 *     }
 *
 * ## Standard I/O streams
 *
 * As seen in the previous code sample, you can interact with the Process's
 * standard output stream through the getter [stdout],
 * and you can interact with the Process's standard input stream through
 * the getter [stdin].
 * In addition, Process provides a getter [stderr] for using the Process's
 * standard error stream.
 *
 * A Process's streams are distinct from the top-level streams
 * for the current program.
 *
 * ## Exit codes
 *
 * Call the [exitCode] method to get the exit code of the process.
 * The exit code indicates whether the program terminated successfully
 * (usually indicated with an exit code of 0) or with an error.
 *
 * If the start method is used, the exitCode is available through a future
 * on the Process object (as shown in the example below).
 * If the run method is used, the exitCode is available
 * through a getter on the ProcessResult instance.
 *
 *     import 'dart:io';
 *
 *     main() {
 *       Process.start('ls', ['-l']).then((process) {
 *         // Get the exit code from the new process.
 *         process.exitCode.then((exitCode) {
 *           print('exit code: $exitCode');
 *         });
 *       });
 *     }
 *
 * ## Other resources
 *
 * [Dart by Example](https://www.dartlang.org/dart-by-example/#dart-io-and-command-line-apps)
 * provides additional task-oriented code samples that show how to use
 * various API from the [dart:io] library.
 */
abstract class Process {
  /**
   * Returns a [:Future:] which completes with the exit code of the process
   * when the process completes.
   *
   * The handling of exit codes is platform specific.
   *
   * On Linux and Mac a normal exit code will be a positive value in
   * the range [0..255]. If the process was terminated due to a signal
   * the exit code will be a negative value in the range [-255..-1],
   * where the absolute value of the exit code is the signal
   * number. For example, if a process crashes due to a segmentation
   * violation the exit code will be -11, as the signal SIGSEGV has the
   * number 11.
   *
   * On Windows a process can report any 32-bit value as an exit
   * code. When returning the exit code this exit code is turned into
   * a signed value. Some special values are used to report
   * termination due to some system event. E.g. if a process crashes
   * due to an access violation the 32-bit exit code is `0xc0000005`,
   * which will be returned as the negative number `-1073741819`. To
   * get the original 32-bit value use `(0x100000000 + exitCode) &
   * 0xffffffff`.
   */
  Future<int> exitCode;

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
   *
   * The following code uses `Process.start` to grep for `main` in the
   * file `test.dart` on Linux.
   *
   *     Process.start('grep', ['-i', 'main', 'test.dart']).then((process) {
   *       stdout.addStream(process.stdout);
   *       stderr.addStream(process.stderr);
   *     });
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
   *
   * The following code uses `Process.run` to grep for `main` in the
   * file `test.dart` on Linux.
   *
   *     Process.run('grep', ['-i', 'main', 'test.dart']).then((result) {
   *       stdout.write(result.stdout);
   *       stderr.write(result.stderr);
   *     });
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
   */
  Stream<List<int>> get stdout;

  /**
   * Returns the standard error stream of the process as a [:Stream:].
   */
  Stream<List<int>> get stderr;

  /**
   * Returns the standard input stream of the process as an [IOSink].
   */
  IOSink get stdin;

  /**
   * Returns the process id of the process.
   */
  int get pid;

  /**
   * On Linux and Mac OS, [kill] sends [signal] to the process. When the process
   * terminates as a result of calling [kill], the value for [exitCode] may be a
   * negative number corresponding to the provided [signal].
   *
   * On Windows, [kill] kills the process, ignoring the [signal] flag.
   *
   * Returns [:true:] if the signal is successfully sent and process is killed.
   * Otherwise the signal could not be sent, usually meaning that the process is
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
   *
   * See [Process.exitCode] for more information in the exit code
   * value.
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
 *
 * Some [ProcessSignal]s can also be watched, as a way to intercept the default
 * signal handler and implement another. See [ProcessSignal.watch] for more
 * information.
 */
class ProcessSignal {
  static const ProcessSignal SIGHUP = const ProcessSignal._(1, "SIGHUP");
  static const ProcessSignal SIGINT = const ProcessSignal._(2, "SIGINT");
  static const ProcessSignal SIGQUIT = const ProcessSignal._(3, "SIGQUIT");
  static const ProcessSignal SIGILL = const ProcessSignal._(4, "SIGILL");
  static const ProcessSignal SIGTRAP = const ProcessSignal._(5, "SIGTRAP");
  static const ProcessSignal SIGABRT = const ProcessSignal._(6, "SIGABRT");
  static const ProcessSignal SIGBUS = const ProcessSignal._(7, "SIGBUS");
  static const ProcessSignal SIGFPE = const ProcessSignal._(8, "SIGFPE");
  static const ProcessSignal SIGKILL = const ProcessSignal._(9, "SIGKILL");
  static const ProcessSignal SIGUSR1 = const ProcessSignal._(10, "SIGUSR1");
  static const ProcessSignal SIGSEGV = const ProcessSignal._(11, "SIGSEGV");
  static const ProcessSignal SIGUSR2 = const ProcessSignal._(12, "SIGUSR2");
  static const ProcessSignal SIGPIPE = const ProcessSignal._(13, "SIGPIPE");
  static const ProcessSignal SIGALRM = const ProcessSignal._(14, "SIGALRM");
  static const ProcessSignal SIGTERM = const ProcessSignal._(15, "SIGTERM");
  static const ProcessSignal SIGCHLD = const ProcessSignal._(17, "SIGCHLD");
  static const ProcessSignal SIGCONT = const ProcessSignal._(18, "SIGCONT");
  static const ProcessSignal SIGSTOP = const ProcessSignal._(19, "SIGSTOP");
  static const ProcessSignal SIGTSTP = const ProcessSignal._(20, "SIGTSTP");
  static const ProcessSignal SIGTTIN = const ProcessSignal._(21, "SIGTTIN");
  static const ProcessSignal SIGTTOU = const ProcessSignal._(22, "SIGTTOU");
  static const ProcessSignal SIGURG = const ProcessSignal._(23, "SIGURG");
  static const ProcessSignal SIGXCPU = const ProcessSignal._(24, "SIGXCPU");
  static const ProcessSignal SIGXFSZ = const ProcessSignal._(25, "SIGXFSZ");
  static const ProcessSignal SIGVTALRM = const ProcessSignal._(26, "SIGVTALRM");
  static const ProcessSignal SIGPROF = const ProcessSignal._(27, "SIGPROF");
  static const ProcessSignal SIGWINCH = const ProcessSignal._(28, "SIGWINCH");
  static const ProcessSignal SIGPOLL = const ProcessSignal._(29, "SIGPOLL");
  static const ProcessSignal SIGSYS = const ProcessSignal._(31, "SIGSYS");

  final int _signalNumber;
  final String _name;

  const ProcessSignal._(this._signalNumber, this._name);

  String toString() => _name;

  /**
   * Watch for process signals.
   *
   * The following [ProcessSignal]s can be listened to:
   *
   *   * [ProcessSignal.SIGHUP].
   *   * [ProcessSignal.SIGINT]. Signal sent by e.g. CTRL-C.
   *   * [ProcessSignal.SIGTERM]. Not available on Windows.
   *   * [ProcessSignal.SIGUSR1]. Not available on Windows.
   *   * [ProcessSignal.SIGUSR2]. Not available on Windows.
   *   * [ProcessSignal.SIGWINCH]. Not available on Windows.
   *
   * Other signals are disallowed, as they may be used by the VM.
   *
   * A signal can be watched multiple times, from multiple isolates, where all
   * callbacks are invoked when signaled, in no specific order.
   */
  Stream<ProcessSignal> watch() => _ProcessUtils._watchSignal(this);
}


class SignalException implements IOException {
  final String message;
  final osError;

  const SignalException(this.message, [this.osError = null]);

  String toString() {
    var msg = "";
    if (osError != null) {
      msg = ", osError: $osError";
    }
    return "SignalException: $message$msg";
  }
}


class ProcessException implements IOException {
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

  const ProcessException(this.executable, this.arguments, [this.message = "",
                         this.errorCode = 0]);
  String toString() {
    var msg = (message == null) ? 'OS error code: $errorCode' : message;
    var args = arguments.join(' ');
    return "ProcessException: $msg\n  Command: $executable $args";
  }
}
