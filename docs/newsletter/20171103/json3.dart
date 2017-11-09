import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Decodes [input] in a chunked way and yields to the event loop
/// as soon as [maxMicroseconds] have elapsed.
Future<dynamic> decodeJsonChunked(String input, int maxMicroseconds) {
  const chunkCount = 100; // Actually one more.

  var result;
  var outSink = new ChunkedConversionSink.withCallback((x) {
    result = x[0];
  });
  var inSink = JSON.decoder.startChunkedConversion(outSink);
  var chunkSize = input.length ~/ chunkCount;

  int i = 0;

  Future<dynamic> addChunks() {
    var sw = new Stopwatch()..start();
    while (i < 100) {
      inSink.addSlice(input, i * chunkSize, (i + 1) * chunkSize, false);
      i++;
      if (sw.elapsedMicroseconds > maxMicroseconds) {
        // Usually one has to pay attention not to chain too many futures,
        // but here we know that there are at most chunkCount linked futures.
        return new Future(addChunks);
      }
    }
    inSink.addSlice(input, i * chunkSize, input.length, true);
    return new Future.value(result);
  }

  return addChunks();
}

main() {
  var input = new File("big.json").readAsStringSync();
  var sw = new Stopwatch()..start();
  bool done = false;
  // Show that the event-loop is free to do something:
  new Timer.periodic(const Duration(milliseconds: 2), (timer) {
    print(".");
    if (done) timer.cancel();
  });
  var future = decodeJsonChunked(input, 500);
  future.then((result) {
    print("done after ${sw.elapsedMicroseconds}us.");
    done = true;
  });
}
