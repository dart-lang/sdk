import 'dart:convert';
import 'dart:io';
import 'dart:math';

main() {
  for (int i = 0; i < 5; i++) {
    var sw = new Stopwatch()..start();
    // Here we just read the contents of a file, but the string could come from
    // anywhere.
    var input = new File("big.json").readAsStringSync();
    print("Reading took: ${sw.elapsedMicroseconds}us");

    // Measure synchronous decoding.
    sw.reset();
    var decoded = JSON.decode(input);
    print("Decoding took: ${sw.elapsedMicroseconds}us");

    // Measure chunked decoding.
    sw.reset();
    const chunkCount = 100; // Actually one more for simplicity.
    var result;
    // This is where the chunked converter will publish its result.
    var outSink = new ChunkedConversionSink.withCallback((List<dynamic> x) {
      result = x.single;
    });

    var inSink = JSON.decoder.startChunkedConversion(outSink);
    var chunkSw = new Stopwatch()..start();
    var maxChunkTime = 0;
    var chunkSize = input.length ~/ chunkCount;
    int i;
    for (i = 0; i < 100; i++) {
      chunkSw.reset();
      inSink.addSlice(input, i * chunkSize, (i + 1) * chunkSize, false);
      maxChunkTime = max(maxChunkTime, chunkSw.elapsedMicroseconds);
    }
    // Now add the last chunk (which could be non-empty because of the rounding
    // division).
    chunkSw.reset();
    inSink.addSlice(input, i * chunkSize, input.length, true);
    maxChunkTime = max(maxChunkTime, chunkSw.elapsedMicroseconds);
    assert(result != null);
    print("Decoding took at most ${maxChunkTime}us per chunk,"
        " and ${sw.elapsedMicroseconds} in total");
  }
}
