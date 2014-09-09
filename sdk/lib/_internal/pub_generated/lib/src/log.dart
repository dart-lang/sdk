library pub.log;
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:stack_trace/stack_trace.dart';
import 'exceptions.dart';
import 'io.dart';
import 'progress.dart';
import 'transcript.dart';
import 'utils.dart';
final json = new _JsonLogger();
Verbosity verbosity = Verbosity.NORMAL;
bool withPrejudice = false;
const _MAX_TRANSCRIPT = 10000;
Transcript<Entry> _transcript;
final _progresses = new Set<Progress>();
Progress _animatedProgress;
final _cyan = getSpecial('\u001b[36m');
final _green = getSpecial('\u001b[32m');
final _magenta = getSpecial('\u001b[35m');
final _red = getSpecial('\u001b[31m');
final _yellow = getSpecial('\u001b[33m');
final _gray = getSpecial('\u001b[1;30m');
final _none = getSpecial('\u001b[0m');
final _noColor = getSpecial('\u001b[39m');
final _bold = getSpecial('\u001b[1m');
class Level {
  static const ERROR = const Level._("ERR ");
  static const WARNING = const Level._("WARN");
  static const MESSAGE = const Level._("MSG ");
  static const IO = const Level._("IO  ");
  static const SOLVER = const Level._("SLVR");
  static const FINE = const Level._("FINE");
  const Level._(this.name);
  final String name;
  String toString() => name;
}
typedef _LogFn(Entry entry);
class Verbosity {
  static const NONE = const Verbosity._("none", const {
    Level.ERROR: null,
    Level.WARNING: null,
    Level.MESSAGE: null,
    Level.IO: null,
    Level.SOLVER: null,
    Level.FINE: null
  });
  static const WARNING = const Verbosity._("warning", const {
    Level.ERROR: _logToStderr,
    Level.WARNING: _logToStderr,
    Level.MESSAGE: null,
    Level.IO: null,
    Level.SOLVER: null,
    Level.FINE: null
  });
  static const NORMAL = const Verbosity._("normal", const {
    Level.ERROR: _logToStderr,
    Level.WARNING: _logToStderr,
    Level.MESSAGE: _logToStdout,
    Level.IO: null,
    Level.SOLVER: null,
    Level.FINE: null
  });
  static const IO = const Verbosity._("io", const {
    Level.ERROR: _logToStderrWithLabel,
    Level.WARNING: _logToStderrWithLabel,
    Level.MESSAGE: _logToStdoutWithLabel,
    Level.IO: _logToStderrWithLabel,
    Level.SOLVER: null,
    Level.FINE: null
  });
  static const SOLVER = const Verbosity._("solver", const {
    Level.ERROR: _logToStderr,
    Level.WARNING: _logToStderr,
    Level.MESSAGE: _logToStdout,
    Level.IO: null,
    Level.SOLVER: _logToStdout,
    Level.FINE: null
  });
  static const ALL = const Verbosity._("all", const {
    Level.ERROR: _logToStderrWithLabel,
    Level.WARNING: _logToStderrWithLabel,
    Level.MESSAGE: _logToStdoutWithLabel,
    Level.IO: _logToStderrWithLabel,
    Level.SOLVER: _logToStderrWithLabel,
    Level.FINE: _logToStderrWithLabel
  });
  const Verbosity._(this.name, this._loggers);
  final String name;
  final Map<Level, _LogFn> _loggers;
  bool isLevelVisible(Level level) => _loggers[level] != null;
  String toString() => name;
}
class Entry {
  final Level level;
  final List<String> lines;
  Entry(this.level, this.lines);
}
void error(message, [error]) {
  if (error != null) {
    message = "$message: $error";
    var trace;
    if (error is Error) trace = error.stackTrace;
    if (trace != null) {
      message = "$message\nStackTrace: $trace";
    }
  }
  write(Level.ERROR, message);
}
void warning(message) => write(Level.WARNING, message);
void message(message) => write(Level.MESSAGE, message);
void io(message) => write(Level.IO, message);
void solver(message) => write(Level.SOLVER, message);
void fine(message) => write(Level.FINE, message);
void write(Level level, message) {
  message = message.toString();
  var lines = splitLines(message);
  if (lines.isNotEmpty && lines.last == "") {
    lines.removeLast();
  }
  var entry = new Entry(level, lines.map(format).toList());
  var logFn = verbosity._loggers[level];
  if (logFn != null) logFn(entry);
  if (_transcript != null) _transcript.add(entry);
}
final _capitalizedAnsiEscape = new RegExp(r'\u001b\[\d+(;\d+)?M');
String format(String string) {
  if (!withPrejudice) return string;
  string = string.toUpperCase().replaceAllMapped(
      _capitalizedAnsiEscape,
      (match) => match[0].toLowerCase());
  return "$_bold$string$_none";
}
Future ioAsync(String startMessage, Future operation, [String
    endMessage(value)]) {
  if (endMessage == null) {
    io("Begin $startMessage.");
  } else {
    io(startMessage);
  }
  return operation.then((result) {
    if (endMessage == null) {
      io("End $startMessage.");
    } else {
      io(endMessage(result));
    }
    return result;
  });
}
void process(String executable, List<String> arguments, String workingDirectory)
    {
  io(
      "Spawning \"$executable ${arguments.join(' ')}\" in "
          "${p.absolute(workingDirectory)}");
}
void processResult(String executable, PubProcessResult result) {
  var buffer = new StringBuffer();
  buffer.writeln("Finished $executable. Exit code ${result.exitCode}.");
  dumpOutput(String name, List<String> output) {
    if (output.length == 0) {
      buffer.writeln("Nothing output on $name.");
    } else {
      buffer.writeln("$name:");
      var numLines = 0;
      for (var line in output) {
        if (++numLines > 1000) {
          buffer.writeln(
              '[${output.length - 1000}] more lines of output ' 'truncated...]');
          break;
        }
        buffer.writeln("| $line");
      }
    }
  }
  dumpOutput("stdout", result.stdout);
  dumpOutput("stderr", result.stderr);
  io(buffer.toString().trim());
}
void exception(exception, [StackTrace trace]) {
  if (exception is SilentException) return;
  var chain = trace == null ? new Chain.current() : new Chain.forTrace(trace);
  if (exception is SourceSpanException) {
    error(exception.toString(color: canUseSpecialChars));
  } else {
    error(getErrorMessage(exception));
  }
  fine("Exception type: ${exception.runtimeType}");
  if (json.enabled) {
    if (exception is UsageException) {
      json.error(exception.message);
    } else {
      json.error(exception);
    }
  }
  if (!isUserFacingException(exception)) {
    error(chain.terse);
  } else {
    fine(chain.terse);
  }
  if (exception is WrappedException && exception.innerError != null) {
    var message = "Wrapped exception: ${exception.innerError}";
    if (exception.innerChain != null) {
      message = "$message\n${exception.innerChain}";
    }
    fine(message);
  }
}
void recordTranscript() {
  _transcript = new Transcript<Entry>(_MAX_TRANSCRIPT);
}
void dumpTranscript() {
  if (_transcript == null) return;
  stderr.writeln('---- Log transcript ----');
  _transcript.forEach((entry) {
    _printToStream(stderr, entry, showLabel: true);
  }, (discarded) {
    stderr.writeln('---- ($discarded discarded) ----');
  });
  stderr.writeln('---- End log transcript ----');
}
Future progress(String message, Future callback(), {bool fine: false}) {
  _stopProgress();
  var progress = new Progress(message, fine: fine);
  _animatedProgress = progress;
  _progresses.add(progress);
  return callback().whenComplete(() {
    progress.stop();
    _progresses.remove(progress);
  });
}
void _stopProgress() {
  if (_animatedProgress != null) _animatedProgress.stopAnimating();
  _animatedProgress = null;
}
String bold(text) => withPrejudice ? text : "$_bold$text$_none";
String gray(text) =>
    withPrejudice ? "$_gray$text$_noColor" : "$_gray$text$_none";
String cyan(text) => "$_cyan$text$_noColor";
String green(text) => "$_green$text$_noColor";
String magenta(text) => "$_magenta$text$_noColor";
String red(text) => "$_red$text$_noColor";
String yellow(text) => "$_yellow$text$_noColor";
void _logToStdout(Entry entry) {
  _logToStream(stdout, entry, showLabel: false);
}
void _logToStdoutWithLabel(Entry entry) {
  _logToStream(stdout, entry, showLabel: true);
}
void _logToStderr(Entry entry) {
  _logToStream(stderr, entry, showLabel: false);
}
void _logToStderrWithLabel(Entry entry) {
  _logToStream(stderr, entry, showLabel: true);
}
void _logToStream(IOSink sink, Entry entry, {bool showLabel}) {
  if (json.enabled) return;
  _printToStream(sink, entry, showLabel: showLabel);
}
void _printToStream(IOSink sink, Entry entry, {bool showLabel}) {
  _stopProgress();
  bool firstLine = true;
  for (var line in entry.lines) {
    if (showLabel) {
      if (firstLine) {
        sink.write('${entry.level.name}: ');
      } else {
        sink.write('    | ');
      }
    }
    sink.writeln(line);
    firstLine = false;
  }
}
class _JsonLogger {
  bool enabled = false;
  void error(error, [stackTrace]) {
    var errorJson = {
      "error": error.toString()
    };
    if (stackTrace == null && error is Error) stackTrace = error.stackTrace;
    if (stackTrace != null) {
      errorJson["stackTrace"] = new Chain.forTrace(stackTrace).toString();
    }
    if (error is SourceSpanException && error.span.sourceUrl != null) {
      errorJson["path"] = p.fromUri(error.span.sourceUrl);
    }
    if (error is FileException) {
      errorJson["path"] = error.path;
    }
    this.message(errorJson);
  }
  void message(message) {
    if (!enabled) return;
    print(JSON.encode(message));
  }
}
