// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Process default _Process {
  /**
   * Creates a new process object and starts a process running the 
   * [executable] with the specified [arguments]. When the process has been 
   * successfully started the [startHandler] is called. If the process fails 
   * to start the [errorHandler] is called.
   *
   * An optional [workingDirectory] can be passed to specify where the process
   * is run from. Note that the change of directory occurs before executing
   * the process on some platforms, which may have impact when using relative
   * paths for [executable] and [arguments].
   *
   * No data can be written to the process stdin and the process cannot be
   * closed nor killed before the [startHandler] has been invoked.
   */
  Process.start(String executable, 
                List<String> arguments, 
                [String workingDirectory]);

  /**
   * Returns an input stream of the process stdout.
   */
  InputStream get stdout();

  /**
   * Returns an input stream of the process stderr.
   */
  InputStream get stderr();

  /**
   * Returns an output stream to the process stdin.
   */
  OutputStream get stdin();

  /**
   * Set the start handler which gets invoked when the process is
   * successfully started.
   */
  void set startHandler(void callback());

  /**
   * Sets an exit handler which gets invoked when the process terminates.
   */
  void set exitHandler(void callback(int exitCode));

  /**
   * Set an error handler which gets invoked if an operation on the process
   * fails.
   */
  void set errorHandler(void callback(ProcessException error));

  /**
   * Kills the process. When the process terminates as a result of calling 
   * [kill] the [exitHandler] is called. If the kill operation fails, the
   * [errorHandler] is called.
   */
  void kill();

  /**
   * Terminates the streams of a process. [close] most be called on a process
   * to free the system resources associated with it. Usually, close should be
   * called in the [exitHandler]. Once a process has been closed it can no
   * longer be killed and the [exitHandler] is detached so the application is
   * not notified of process termination.
   */
  void close();
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
