// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface Process factory _Process {
  /*
   * Creates a new process object preparing to run the executable
   * found at [path] with the specified [arguments].
   */
  Process(String path, List<String> arguments);

  /*
   * Start the process by running the specified executable. An
   * exception of type [ProcessException] is thrown if the process
   * cannot be started. There is a remote possibility of an exception
   * being thrown even though the child process did actually start.
   */
  void start();

  /*
   * Returns an input stream of the process stdout.
   */
  InputStream get stdout();

  /*
   * Returns an input stream of the process stderr.
   */
  InputStream get stderr();

  /*
   * Returns an output stream to the process stdin.
   */
  OutputStream get stdin();

  /*
   * Sets an exit handler which gets invoked when the process terminates.
   */
  void set exitHandler(void callback(int exitCode));

  /*
   * Kills the process with [signal].
   */
  bool kill();

  /*
   * Terminates the streams and closes the exit handler of a process.
   */
  void close();
}


class ProcessException implements Exception {
  const ProcessException([String message, int errorCode = 0])
      : this.message = message, this.errorCode = errorCode;
  String toString() => "ProcessException: $message";

  /*
   * Contains the system message for the process exception if any.
   */
  final String message;

  /*
   * Contains the OS error code for the process exception if any.
   */
  final int errorCode;
}
