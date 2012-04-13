// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * [Process] objects are used to start new processes and interact with
 * them.
 */
interface Process default _Process {
  /**
   * Creates a new process object and starts a process running the
   * [executable] with the specified [arguments]. When the process has
   * been successfully started [onStart] is called. If the process
   * fails to start [onError] is called.
   *
   * An optional [ProcessOptions] object can be passed to specify
   * options other than the executable and the arguments.
   *
   * No data can be written to the process stdin and the process
   * cannot be closed nor killed before [onStart] has been invoked.
   */
  Process.start(String executable,
                List<String> arguments,
                [ProcessOptions options]);

  /**
   * Creates a new process object, starts a process and runs it
   * non-interactively to completion. The process run is [executable]
   * with the specified [arguments]. When the process has been
   * successfully started [onStart] is called. If the process fails to
   * start [onError] is called.
   *
   * Options other than the executable and the arguments are specified
   * using a [ProcessOptions] object. If no options are required,
   * [null] can be passed as the options.
   *
   * No communication via [stdin], [stdout] or [stderr] can take place
   * with a non-interactive process. Instead, the process is run to
   * completion at which point the exit code and stdout and stderr are
   * supplied to the [callback] parameter.
   */
  Process.run(String executable,
              List<String> arguments,
              ProcessOptions options,
              void callback(int exitCode, String stdout, String stderr));

  /**
   * Returns an input stream of the process stdout.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  InputStream get stdout();

  /**
   * Returns an input stream of the process stderr.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  InputStream get stderr();

  /**
   * Returns an output stream to the process stdin.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  OutputStream get stdin();

  /**
   * Set the start handler which gets invoked when the process is
   * successfully started.
   */
  void set onStart(void callback());

  /**
   * Sets an exit handler which gets invoked when the process
   * terminates.
   *
   * Throws an [UnsupportedOperationException] if the process is
   * non-interactive.
   */
  void set onExit(void callback(int exitCode));

  /**
   * Set an error handler which gets invoked if an operation on the process
   * fails.
   */
  void set onError(void callback(ProcessException error));

  /**
   * Kills the process. When the process terminates as a result of
   * calling [kill] [onExit] is called. If the kill operation fails,
   * [onError] is called.
   */
  void kill();

  /**
   * Terminates the streams of a process. [close] most be called on a
   * process to free the system resources associated with it. Usually,
   * close should be called in [onExit]. Once a process has been
   * closed it can no longer be killed and [onExit] is detached so the
   * application is not notified of process termination.
   */
  void close();
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
}


class ProcessException implements Exception {
  const ProcessException([String this.message, int this.errorCode = 0]);
  String toString() => "ProcessException: $message";

  /**
   * Contains the system message for the process exception if any.
   */
  final String message;

  /**
   * Contains the OS error code for the process exception if any.
   */
  final int errorCode;
}
