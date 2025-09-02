import 'dart:async';
import 'dart:convert';
import 'dart:typed_data' show BytesBuilder;
import 'dart:io';

import 'benchmarker.dart';

/// Take --verbose-gc data from stdin and print the combined runtime.
///
/// E.g. (and this is not pretty):
/// out/ReleaseX64/dart --verbose-gc \
///   hello.dart 2> /dev/stdout 1> /dev/null | out/ReleaseX64/dart \
///   pkg/front_end/tool/verbose_gc_helper.dart
Future<void> main() async {
  Completer completer = new Completer();
  BytesBuilder bb = new BytesBuilder();
  late StreamSubscription<List<int>> subscription;
  subscription = stdin.listen(
    (List<int> data) {
      bb.add(data);
    },
    onDone: () {
      subscription.cancel();
      completer.complete();
    },
    onError: (_) {
      subscription.cancel();
      completer.complete();
    },
  );
  await completer.future;
  GCInfo gcInfo = parseVerboseGcText(utf8.decode(bb.takeBytes()).split("\n"));
  print(gcInfo.combinedTime);
}
