// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A utility class used to write logging information during a test.
 */
class Logger {
  /**
   * The width of the field in which labels are printed.
   */
  static const int _labelWidth = 8;

  /**
   * The separator used to separate the label from the content.
   */
  static const String _separator = ' : ';

  /**
   * The sink to which the logged information should be written.
   */
  final StringSink sink;

  /**
   * Initialize a newly created logger to write to the given [sink].
   */
  Logger(this.sink);

  /**
   * Log the given information.
   *
   * The [label] is used to indicate the kind of information being logged, while
   * the [content] contains the actual information. If a list of [arguments] is
   * provided, then they will be written after the content.
   */
  void log(String label, String content, {List<String> arguments = null}) {
    for (int i = _labelWidth - label.length; i > 0; i--) {
      sink.write(' ');
    }
    sink.write(label);
    sink.write(_separator);
    sink.write(content);
    arguments?.forEach((String argument) {
      sink.write(' ');
      sink.write(argument);
    });
    sink.writeln();
  }
}
