// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [Process] is used to start new processes using the static
 * [start] and [run] methods.
 */
class Process {
  /**
   * Starts a process running the [executable] with the specified
   * [arguments]. Returns a [Process] instance that can be used to
   * interact with the process.
   *
   * An optional [ProcessOptions] object can be passed to specify
   * options other than the executable and the arguments.
   *
   * When the process has been successfully started [onStart] is
   * called on the returned Process object. If the process fails to
   * start [onError] is called on the returned Process object.
   *
   * No data can be written to the process stdin and the process
   * cannot be closed nor killed before [onStart] has been invoked.
   */
  static Process start(String executable,
                       List<String> arguments,
                       [ProcessOptions options]) {
    return _Process.start(executable, arguments, options);
  }

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
  static Future<ProcessResult> run(String executable,
                                   List<String> arguments,
                                   [ProcessOptions options]) {
    return _Process.run(executable, arguments, options);
  }

  /**
   * Returns an input stream of the process stdout.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  abstract InputStream get stdout();

  /**
   * Returns an input stream of the process stderr.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  abstract InputStream get stderr();

  /**
   * Returns an output stream to the process stdin.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  abstract OutputStream get stdin();

  /**
   * Set the start handler which gets invoked when the process is
   * successfully started.
   */
  abstract void set onStart(void callback());

  /**
   * Sets an exit handler which gets invoked when the process
   * terminates.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  abstract void set onExit(void callback(int exitCode));

  /**
   * Set an error handler which gets invoked if an operation on the process
   * fails.
   */
  abstract void set onError(void callback(e));

  /**
   * Kills the process. When the process terminates as a result of
   * calling [kill] [onExit] is called. If the kill operation fails,
   * [onError] is called.
   */
  abstract void kill();

  /**
   * Terminates the streams of a process. [close] must be called on a
   * process to free the system resources associated with it if not all
   * data on the stdout and stderr streams have been read. Usually,
   * close should be called in [onExit], but care must be taken to actually
   * wait on the stderr and stdout streams to close if all data is required.
   * Once a process has been closed it can no longer be killed and [onExit]
   * is detached so the application is not notified of process termination.
   */
  abstract void close();
}


/**
 * [ProcessResult] represents the result of running a non-interactive
 * process started with [:Process.run:].
 */
interface ProcessResult {
  /**
   * Exit code for the process.
   */
  int get exitCode();

  /**
   * Standard output from the process as a string.
   */
  String get stdout();

  /**
   * Standard error from the process as a string.
   */
  String get stderr();
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


class ProcessException implements Exception {
  const ProcessException([String this.message, int this.errorCode = 0]);
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
