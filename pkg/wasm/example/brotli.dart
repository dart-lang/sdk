// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Example of using package:wasm to run a wasm build of the Brotli compression
// library. Usage:
// dart brotli.dart input.txt

import 'dart:convert';
import "dart:io";
import "dart:typed_data";
import "package:wasm/wasm.dart";

// Brotli compression parameters.
const int kDefaultQuality = 11;
const int kDefaultWindow = 22;
const int kDefaultMode = 0;

main(List<String> args) {
  var brotliPath = Platform.script.resolve('libbrotli.wasm');
  var moduleData = File(brotliPath.path).readAsBytesSync();
  var module = WasmModule(moduleData);
  print(module.describe());

  var instance = module.instantiate().enableWasi().build();
  var memory = instance.memory;
  var compress = instance.lookupFunction("BrotliEncoderCompress");
  var decompress = instance.lookupFunction("BrotliDecoderDecompress");

  print("Loading ${args[0]}");
  var inputData = File(args[0]).readAsBytesSync();
  print("Input size: ${inputData.length} bytes");

  // Grow the module's memory to get unused space to put our data.
  // [initial memory][input data][output data][size][decoded data][size]
  var inputPtr = memory.lengthInBytes;
  memory.grow((3 * inputData.length / WasmMemory.kPageSizeInBytes).ceil());
  var memoryView = memory.view;
  var outputPtr = inputPtr + inputData.length;
  var outSizePtr = outputPtr + inputData.length;
  var decodedPtr = outSizePtr + 4;
  var decSizePtr = decodedPtr + inputData.length;

  memoryView.setRange(inputPtr, inputPtr + inputData.length, inputData);

  var sizeBytes = ByteData(4);
  sizeBytes.setUint32(0, inputData.length, Endian.host);
  memoryView.setRange(
      outSizePtr, outSizePtr + 4, sizeBytes.buffer.asUint8List());

  print("\nCompressing...");
  var status = compress(kDefaultQuality, kDefaultWindow, kDefaultMode,
      inputData.length, inputPtr, outSizePtr, outputPtr);
  print("Compression status: $status");

  var compressedSize =
      ByteData.sublistView(memoryView, outSizePtr, outSizePtr + 4)
          .getUint32(0, Endian.host);
  print("Compressed size: $compressedSize bytes");
  var spaceSaving = 100 * (1 - compressedSize / inputData.length);
  print("Space saving: ${spaceSaving.toStringAsFixed(2)}%");

  var decSizeBytes = ByteData(4);
  decSizeBytes.setUint32(0, inputData.length, Endian.host);
  memoryView.setRange(
      decSizePtr, decSizePtr + 4, decSizeBytes.buffer.asUint8List());

  print("\nDecompressing...");
  status = decompress(compressedSize, outputPtr, decSizePtr, decodedPtr);
  print("Decompression status: $status");

  var decompressedSize =
      ByteData.sublistView(memoryView, decSizePtr, decSizePtr + 4)
          .getUint32(0, Endian.host);
  print("Decompressed size: $decompressedSize bytes");

  print("\nVerifying decompression...");
  assert(inputData.length == decompressedSize);
  for (var i = 0; i < inputData.length; ++i) {
    assert(inputData[i] == memoryView[decodedPtr + i]);
  }
  print("Decompression succeeded :)");
}
