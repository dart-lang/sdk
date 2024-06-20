// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';
import 'dart:convert';
import 'dart:typed_data';

import 'package:benchmark_harness/benchmark_harness.dart';

void main(List<String> args) {
  final smallDartString = 'a' * 10;
  final mediumDartString = 'a' * 1024;
  final largeDartString = 'a' * 1024 * 1024;

  final smallJsString = smallDartString.toJS;
  final mediumJsString = mediumDartString.toJS;
  final largeJsString = largeDartString.toJS;

  final smallDartBytes = utf8.encode(smallDartString);
  final mediumDartBytes = utf8.encode(mediumDartString);
  final largeDartBytes = utf8.encode(largeDartString);

  final smallJsBytes = smallDartBytes.toJS;
  final mediumJsBytes = mediumDartBytes.toJS;
  final largeJsBytes = largeDartBytes.toJS;

  WasmDataTransferFromBrowserString(smallJsString, '10').report();
  WasmDataTransferFromBrowserBytes(smallJsBytes, '10').report();
  WasmDataTransferToBrowserString(smallDartString, '10').report();
  WasmDataTransferToBrowserBytes(smallDartBytes, '10').report();

  WasmDataTransferFromBrowserString(mediumJsString, '1KB').report();
  WasmDataTransferFromBrowserBytes(mediumJsBytes, '1KB').report();
  WasmDataTransferToBrowserString(mediumDartString, '1KB').report();
  WasmDataTransferToBrowserBytes(mediumDartBytes, '1KB').report();

  WasmDataTransferFromBrowserString(largeJsString, '1MB').report();
  WasmDataTransferFromBrowserBytes(largeJsBytes, '1MB').report();
  WasmDataTransferToBrowserString(largeDartString, '1MB').report();
  WasmDataTransferToBrowserBytes(largeDartBytes, '1MB').report();
}

abstract class Benchmark extends BenchmarkBase {
  Benchmark(super.name);

  @override
  void exercise() {
    // To avoid using the super class's implementation which runs for 10
    // iterations thereby making the measured time off by 10x.
    run();
  }
}

class WasmDataTransferFromBrowserString extends Benchmark {
  final JSString jsonString;

  WasmDataTransferFromBrowserString(this.jsonString, String subName)
      : super('WasmDataTransfer.FromBrowserString.$subName');

  @override
  void run() {
    // We don't expose a way to convert JS string to Dart string (as string
    // implementation in Dart is implementation specific - we may even use JS
    // strings).
    //
    // But currently we use internal one/two byte strings and using string
    // interpolation forces transfer of string to be internal string.
    //
    // Though string interpolation also causes other work (it convers JS string
    // to dart and then allocates new string for interpolation result)
    use('a${jsonString.toDart}');
  }
}

class WasmDataTransferFromBrowserBytes extends Benchmark {
  final JSUint8Array bytes;

  WasmDataTransferFromBrowserBytes(this.bytes, String subName)
      : super('WasmDataTransfer.FromBrowserBytes.$subName');

  @override
  void run() {
    use(Uint8List.fromList(bytes.toDart));
  }
}

class WasmDataTransferToBrowserString extends Benchmark {
  final String string;

  WasmDataTransferToBrowserString(this.string, String subName)
      : super('WasmDataTransfer.ToBrowserString.$subName');

  @override
  void run() {
    use(string.toJS);
  }
}

class WasmDataTransferToBrowserBytes extends Benchmark {
  final Uint8List bytes;

  WasmDataTransferToBrowserBytes(this.bytes, String subName)
      : super('WasmDataTransfer.ToBrowserBytes.$subName');

  @override
  void run() {
    use(bytes.toJS);
  }
}

var globalSink;
void use<T>(T a) {
  globalSink = a;
  if (kFalse) print(globalSink);
}

final kTrue = int.parse('1') == 1;
final kFalse = !kTrue;
