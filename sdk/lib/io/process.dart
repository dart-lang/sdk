// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(ager): The only reason for this class is that we
// cannot patch a top-level at this point.
class _ProcessUtils {
  external static _exit(int status);
}

/** Exit the Dart VM process with the given [status] code. */
void exit(int status) {
  if (status is !int) {
    throw new ArgumentError("int status expected");
  }
  _ProcessUtils._exit(status);
}

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
   * An optional [ProcessOptions] object can be passed to specify
   * options other than the executable and the arguments.
   *
   * Users must read all data coming on the [stdout] and [stderr]
   * streams of processes started with [:Process.start:]. If the user
   * does not read all data on the streams the underlying system
   * resources will not be freed since there is still pending data.
   */
  external static Future<Process> start(String executable,
                                        List<String> arguments,
                                        [ProcessOptions options]);

  /**
   * Starts a process and runs it non-interactively to completion. The
   * process run is [executable] with the specified [arguments].
   *
   * An optional [ProcessOptions] object can be passed to specify
   * options other than the executable and the arguments.
   *
   * Returns a [:Future<ProcessResult>:] that completes with the
   * result of running the process, i.e., exit code, standard out and
   * standard in.
   */
  external static Future<ProcessResult> run(String executable,
                                            List<String> arguments,
                                            [ProcessOptions options]);

  /**
   * Returns an input stream of the process stdout.
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  InputStream get stdout;

  /**
   * Returns an input stream of the process stderr.
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  InputStream get stderr;

  /**
   * Returns an output stream to the process stdin.
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  OutputStream get stdin;

  /**
   * Sets an exit handler which gets invoked when the process
   * terminates.
   *
   * Throws an [UnsupportedError] if the process is
   * non-interactive.
   */
  void set onExit(void callback(int exitCode));

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
   * Standard output from the process as a string.
   */
  String get stdout;

  /**
   * Standard error from the process as a string.
   */
  String get stderr;
}


/**
 * [ProcessOptions] represents the options that can be supplied when
 * starting a process.
 */
class ProcessOptions {
  /**
   * The working directory from which the process is started.  Note
   * that the change of directory occurs before executing the process
   * on some platforms, which may have impact when using relative
   * paths for the executable and the arguments.
   */
  String workingDirectory;

  /**
   * The encoding used for text on stdout when starting a
   * non-interactive process with [:Process.run:].
   *
   * This option is ignored for interactive processes started with
   * [:Process.start:].
   *
   * The default stdoutEncoding is UTF_8.
   */
  Encoding stdoutEncoding;

  /**
   * The encoding used for text on stderr when starting a
   * non-interactive process with [:Process.run:].
   *
   * This option is ignored for interactive processes started with
   * [:Process.start:].
   *
   * The default stderrEncoding is UTF_8.
   */
  Encoding stderrEncoding;

  /**
   * Provides the environment variables for the process. If not set
   * the environment of the parent process is inherited.
   *
   * Currently, only ASCII environment variables are supported and
   * errors are likely to occur if an environment variables with
   * code-points outside the ASCII range is passed in.
   */
  Map<String, String> environment;
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


class ProcessException implements Exception {
  const ProcessException([String this.message = "", int this.errorCode = 0]);
  String toString() => "ProcessException: $message ($errorCode)";

  /**
   * Contains the system message for the process exception if any.
   */
  final String message;

  /**
   * Contains the OS error code for the process exception if any.
   */
  final int errorCode;
}
