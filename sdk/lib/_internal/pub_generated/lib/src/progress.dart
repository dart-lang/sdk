library pub.progress;
import 'dart:async';
import 'dart:io';
import 'log.dart' as log;
import 'utils.dart';
class Progress {
  Timer _timer;
  final _stopwatch = new Stopwatch();
  final String _message;
  String get _time => "(${niceDuration(_stopwatch.elapsed)})";
  Progress(this._message, {bool fine: false}) {
    _stopwatch.start();
    var level = fine ? log.Level.FINE : log.Level.MESSAGE;
    if (stdioType(stdout) != StdioType.TERMINAL ||
        !log.verbosity.isLevelVisible(level) ||
        log.json.enabled ||
        fine ||
        log.verbosity.isLevelVisible(log.Level.FINE)) {
      log.write(level, "$_message...");
      return;
    }
    _update();
    _timer = new Timer.periodic(new Duration(milliseconds: 100), (_) {
      _update();
    });
  }
  void stop() {
    _stopwatch.stop();
    log.fine("$_message finished $_time.");
    if (_timer == null) return;
    _timer.cancel();
    _timer = null;
    _update();
    stdout.writeln();
  }
  void stopAnimating() {
    if (_timer == null) return;
    stdout.writeln(log.format("\r$_message..."));
    _timer.cancel();
    _timer = null;
  }
  void _update() {
    stdout.write(log.format("\r$_message... "));
    if (_stopwatch.elapsed.inSeconds > 0) {
      stdout.write(log.gray(_time));
    }
  }
}
