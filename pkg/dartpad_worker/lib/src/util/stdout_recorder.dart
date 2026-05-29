import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:typed_data';

final class StdoutRecorder {
  final _sink = _ByteSink();

  StreamSink<List<int>> get sink => _sink;
  String get log => utf8.decode(_sink.bytes, allowMalformed: true);
}

final class _ByteSink implements StreamSink<List<int>> {
  final builder = BytesBuilder();
  final _completer = Completer<void>();

  /// Access the buffered bytes as a Uint8List
  Uint8List get bytes => builder.toBytes();

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (!_completer.isCompleted) {
      _completer.completeError(error, stackTrace);
    }
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await stream.forEach(add);
  }

  @override
  Future<void> close() async {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }

  @override
  Future<void> get done => _completer.future;
}
