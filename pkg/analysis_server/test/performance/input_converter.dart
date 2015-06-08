library input.transformer;

import 'dart:convert';

import 'instrumentation_input_converter.dart';
import 'operation.dart';

final int NINE = '9'.codeUnitAt(0);
final int ZERO = '0'.codeUnitAt(0);

/**
 * [InputConverter] converts an input stream
 * into a series of operations to be sent to the analysis server.
 * The input stream can be either an instrumenation or log file.
 */
class InputConverter extends Converter<String, Operation> {

  /**
   * The number of lines read before the underlying converter was determined
   * or the end of file was reached.
   */
  int headerLineCount = 0;

  /**
   * The underlying converter used to translate lines into operations
   * or `null` if it has not yet been determined.
   */
  Converter<String, Operation> converter;

  @override
  Operation convert(String line) {
    if (converter != null) {
      return converter.convert(line);
    }
    if (headerLineCount == 20) {
      throw 'Failed to determine input file format';
    }
    if (InstrumentationInputConverter.isFormat(line)) {
      converter = new InstrumentationInputConverter();
    } else if (LogFileInputConverter.isFormat(line)) {
      converter = new LogFileInputConverter();
    }
    if (converter != null) {
      return converter.convert(line);
    }
    print(line);
    return null;
  }

  @override
  _InputSink startChunkedConversion(outSink) {
    return new _InputSink(this, outSink);
  }
}

/**
 * [LogFileInputConverter] converts a log file stream
 * into a series of operations to be sent to the analysis server.
 */
class LogFileInputConverter extends Converter<String, Operation> {
  @override
  Operation convert(String line) {
    throw 'not implemented yet';
  }

  /**
   * Determine if the given line is from an instrumentation file.
   * For example:
   * `1428347977499 <= {"event":"server.connected","params":{"version":"1.6.0"}}`
   */
  static bool isFormat(String line) {
    String timeStampString = _parseTimeStamp(line);
    int start = timeStampString.length;
    int end = start + 5;
    return start > 10 &&
        line.length > end &&
        line.substring(start, end) == ' <= {"event":"server.connected"';
  }

  /**
   * Parse the given line and return the millisecond timestamp or `null`
   * if it cannot be determined.
   */
  static String _parseTimeStamp(String line) {
    int index = 0;
    while (index < line.length) {
      int code = line.codeUnitAt(index);
      if (code < ZERO || NINE < code) {
        return line.substring(0, index);
      }
      ++index;
    }
    return line;
  }
}

class _InputSink extends ChunkedConversionSink<String> {
  final Converter<String, Operation> converter;
  final outSink;

  _InputSink(this.converter, this.outSink);

  @override
  void add(String line) {
    Operation op = converter.convert(line);
    if (op != null) {
      outSink.add(op);
    }
  }

  @override
  void close() {
    outSink.close();
  }
}
