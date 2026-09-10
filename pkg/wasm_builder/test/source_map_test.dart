// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:wasm_builder/source_map.dart';
import 'package:wasm_builder/wasm_builder.dart';

void main() {
  testEmpty();
  testSingleMapping();
  testSpecialOpcodeSameLine();
  testSpecialOpcodeNextLine();
  testGeneralLineColDeltas();
  testFileAndNameChanges();
  testUnmappedRegions();
  testDeduplicationAndOverwrite();
  testModuleSourceMapJson();
  testSourceMapDeserializationRoundTrip();
}

void testEmpty() {
  final debugInfo = DebugInfoTables();
  final writer = DebugInfoWriter(debugInfo);
  Expect.isTrue(writer.isEmpty);
  final bytes = writer.build();
  Expect.equals(0, bytes.length);
  final reader = DebugInfoReader(bytes, debugInfo);
  Expect.isFalse(reader.moveNext());
}

void testSingleMapping() {
  final debugInfo = DebugInfoTables();
  final fileUri = Uri.parse('file:///app/main.dart');
  final writer = DebugInfoWriter(debugInfo);
  writer.setSourcePosition(0, fileUri, 10, 5, 'myFunction');

  final bytes = writer.build();
  Expect.isFalse(writer.isEmpty);

  final reader = DebugInfoReader(bytes, debugInfo);
  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.isTrue(reader.hasSourcePosition);
  Expect.equals(fileUri, reader.fileUri);
  Expect.equals(0, reader.fileIndex);
  Expect.equals(10, reader.line);
  Expect.equals(5, reader.col);
  Expect.equals('myFunction', reader.name);
  Expect.equals(0, reader.nameIndex);
  Expect.isFalse(reader.moveNext());
}

void testSpecialOpcodeSameLine() {
  final debugInfo = DebugInfoTables();
  final fileUri = Uri.parse('file:///app/main.dart');
  final writer = DebugInfoWriter(debugInfo);

  // First mapping (SET_ALL)
  writer.setSourcePosition(0, fileUri, 10, 20, 'fn');
  final firstLen = writer.build().length;

  // Same line (deltaLine == 0), deltaOffset = 2, deltaCol = 5 -> should take 1 byte
  final writer2 = DebugInfoWriter(debugInfo);
  writer2.setSourcePosition(0, fileUri, 10, 20, 'fn');
  writer2.setSourcePosition(2, fileUri, 10, 25, 'fn');
  final secondLen = writer2.build().length;
  Expect.equals(firstLen + 1, secondLen);

  // Same line (deltaLine == 0), deltaOffset = 3, deltaCol = -7 -> should take 1 byte
  final writer3 = DebugInfoWriter(debugInfo);
  writer3.setSourcePosition(0, fileUri, 10, 20, 'fn');
  writer3.setSourcePosition(2, fileUri, 10, 25, 'fn');
  writer3.setSourcePosition(5, fileUri, 10, 18, 'fn');
  final thirdLen = writer3.build().length;
  Expect.equals(secondLen + 1, thirdLen);

  final reader = DebugInfoReader(writer3.build(), debugInfo);

  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.equals(10, reader.line);
  Expect.equals(20, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(2, reader.offset);
  Expect.equals(10, reader.line);
  Expect.equals(25, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(5, reader.offset);
  Expect.equals(10, reader.line);
  Expect.equals(18, reader.col);

  Expect.isFalse(reader.moveNext());
}

void testSpecialOpcodeNextLine() {
  final debugInfo = DebugInfoTables();
  final fileUri = Uri.parse('file:///app/main.dart');
  final writer = DebugInfoWriter(debugInfo);

  writer.setSourcePosition(0, fileUri, 10, 20, 'fn');
  final firstLen = writer.build().length;

  // Next line (deltaLine == 1), deltaOffset = 4, deltaCol = -2 -> should take 1 byte
  final writer2 = DebugInfoWriter(debugInfo);
  writer2.setSourcePosition(0, fileUri, 10, 20, 'fn');
  writer2.setSourcePosition(4, fileUri, 11, 18, 'fn');
  final secondLen = writer2.build().length;
  Expect.equals(firstLen + 1, secondLen);

  // Next line (deltaLine == 1), deltaOffset = 1, deltaCol = 3 -> should take 1 byte
  final writer3 = DebugInfoWriter(debugInfo);
  writer3.setSourcePosition(0, fileUri, 10, 20, 'fn');
  writer3.setSourcePosition(4, fileUri, 11, 18, 'fn');
  writer3.setSourcePosition(5, fileUri, 12, 21, 'fn');
  final thirdLen = writer3.build().length;
  Expect.equals(secondLen + 1, thirdLen);

  final reader = DebugInfoReader(writer3.build(), debugInfo);

  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.equals(10, reader.line);
  Expect.equals(20, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(4, reader.offset);
  Expect.equals(11, reader.line);
  Expect.equals(18, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(5, reader.offset);
  Expect.equals(12, reader.line);
  Expect.equals(21, reader.col);

  Expect.isFalse(reader.moveNext());
}

void testGeneralLineColDeltas() {
  final debugInfo = DebugInfoTables();
  final fileUri = Uri.parse('file:///app/main.dart');
  final writer = DebugInfoWriter(debugInfo);

  writer.setSourcePosition(0, fileUri, 100, 50, 'fn');

  // Jump forward 50 lines, column +100, offset +200
  writer.setSourcePosition(200, fileUri, 150, 150, 'fn');

  // Jump backward 80 lines, column -90, offset +10
  writer.setSourcePosition(210, fileUri, 70, 60, 'fn');

  final reader = DebugInfoReader(writer.build(), debugInfo);

  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.equals(100, reader.line);
  Expect.equals(50, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(200, reader.offset);
  Expect.equals(150, reader.line);
  Expect.equals(150, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(210, reader.offset);
  Expect.equals(70, reader.line);
  Expect.equals(60, reader.col);

  Expect.isFalse(reader.moveNext());
}

void testFileAndNameChanges() {
  final debugInfo = DebugInfoTables();
  final file1 = Uri.parse('file:///app/a.dart');
  final file2 = Uri.parse('file:///app/b.dart');
  final writer = DebugInfoWriter(debugInfo);

  writer.setSourcePosition(0, file1, 10, 5, 'funcA');
  writer.setSourcePosition(5, file2, 20, 8, 'funcB');
  writer.setSourcePosition(10, file2, 22, 12, null);

  final reader = DebugInfoReader(writer.build(), debugInfo);

  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.equals(file1, reader.fileUri);
  Expect.equals(0, reader.fileIndex);
  Expect.equals('funcA', reader.name);
  Expect.equals(0, reader.nameIndex);
  Expect.equals(10, reader.line);
  Expect.equals(5, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(5, reader.offset);
  Expect.equals(file2, reader.fileUri);
  Expect.equals(1, reader.fileIndex);
  Expect.equals('funcB', reader.name);
  Expect.equals(1, reader.nameIndex);
  Expect.equals(20, reader.line);
  Expect.equals(8, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(10, reader.offset);
  Expect.equals(file2, reader.fileUri);
  Expect.equals(1, reader.fileIndex);
  Expect.isNull(reader.name);
  Expect.equals(-1, reader.nameIndex);
  Expect.equals(22, reader.line);
  Expect.equals(12, reader.col);

  Expect.isFalse(reader.moveNext());
}

void testUnmappedRegions() {
  final debugInfo = DebugInfoTables();
  final file = Uri.parse('file:///app/main.dart');
  final writer = DebugInfoWriter(debugInfo);

  writer.setSourcePosition(0, file, 10, 5, 'fn');
  writer.clearSourcePosition(5);
  writer.setSourcePosition(10, file, 15, 2, 'fn');

  final reader = DebugInfoReader(writer.build(), debugInfo);

  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.isTrue(reader.hasSourcePosition);
  Expect.equals(10, reader.line);

  Expect.isTrue(reader.moveNext());
  Expect.equals(5, reader.offset);
  Expect.isFalse(reader.hasSourcePosition);
  Expect.isNull(reader.fileUri);

  Expect.isTrue(reader.moveNext());
  Expect.equals(10, reader.offset);
  Expect.isTrue(reader.hasSourcePosition);
  Expect.equals(15, reader.line);
  Expect.equals(2, reader.col);

  Expect.isFalse(reader.moveNext());
}

void testDeduplicationAndOverwrite() {
  final debugInfo = DebugInfoTables();
  final file = Uri.parse('file:///app/main.dart');
  final writer = DebugInfoWriter(debugInfo);

  writer.setSourcePosition(0, file, 10, 5, 'fn');
  // Duplicate mapping at offset 5 with same location -> ignored
  writer.setSourcePosition(5, file, 10, 5, 'fn');
  // Overwrite mapping at offset 5 with new location
  writer.setSourcePosition(5, file, 12, 8, 'fn');
  // Duplicate unmapped
  writer.clearSourcePosition(10);
  writer.clearSourcePosition(12); // ignored because already unmapped

  final reader = DebugInfoReader(writer.build(), debugInfo);

  Expect.isTrue(reader.moveNext());
  Expect.equals(0, reader.offset);
  Expect.equals(10, reader.line);
  Expect.equals(5, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(5, reader.offset);
  Expect.equals(12, reader.line);
  Expect.equals(8, reader.col);

  Expect.isTrue(reader.moveNext());
  Expect.equals(10, reader.offset);
  Expect.isFalse(reader.hasSourcePosition);

  Expect.isFalse(reader.moveNext());
}

void testModuleSourceMapJson() {
  final file1 = Uri.parse('file:///app/a.dart');
  final file2 = Uri.parse('file:///app/b.dart');

  final moduleBuilder = ModuleBuilder('test', Uri.parse('test.wasm.map'));
  final fnType = moduleBuilder.types.defineFunction(const [], const []);

  final fn1 = moduleBuilder.functions.define(fnType);
  final b1 = fn1.body;
  b1.setSourcePosition(file1, 10, 0, 'funcA');
  b1.i32_const(1);
  b1.setSourcePosition(file1, 11, 4, 'funcA');
  b1.drop();
  b1.end();
  fn1.build();

  final fn2 = moduleBuilder.functions.define(fnType);
  final b2 = fn2.body;
  b2.setSourcePosition(file2, 20, 2, 'funcB');
  b2.i32_const(2);
  b2.clearSourcePosition();
  b2.drop();
  b2.end();
  fn2.build();

  final module = moduleBuilder.build();
  final serializer = Serializer();
  final sourceMapBuilder = SourceMapBuilder(module.debugInfoTables);
  module.serialize(serializer, sourceMapBuilder);

  final json = sourceMapBuilder.toJson();
  Expect.equals(3, json['version']);
  Expect.listEquals([
    'file:///app/a.dart',
    'file:///app/b.dart',
  ], json['sources'] as List);
  Expect.listEquals(['funcA', 'funcB'], json['names'] as List);
  Expect.type<String>(json['mappings']);
  Expect.isTrue((json['mappings'] as String).isNotEmpty);
}

void testSourceMapDeserializationRoundTrip() {
  final file1 = Uri.parse('file:///app/a.dart');
  final file2 = Uri.parse('file:///app/b.dart');

  final moduleBuilder = ModuleBuilder('test', Uri.parse('test.wasm.map'));
  final fnType = moduleBuilder.types.defineFunction(const [], const []);

  final fn1 = moduleBuilder.functions.define(fnType);
  final b1 = fn1.body;
  b1.setSourcePosition(file1, 10, 0, 'funcA');
  b1.i32_const(1);
  b1.setSourcePosition(file1, 11, 4, 'funcA');
  b1.drop();
  b1.end();
  fn1.build();

  final fn2 = moduleBuilder.functions.define(fnType);
  final b2 = fn2.body;
  b2.setSourcePosition(file2, 20, 2, 'funcB');
  b2.i32_const(2);
  b2.clearSourcePosition();
  b2.drop();
  b2.end();
  fn2.build();

  final originalModule = moduleBuilder.build();
  final originalSerializer = Serializer();
  final originalSourceMapBuilder = SourceMapBuilder(
    originalModule.debugInfoTables,
  );
  originalModule.serialize(originalSerializer, originalSourceMapBuilder);
  final originalBytes = originalSerializer.data;
  final originalJson = originalSourceMapBuilder.toJson();

  // Deserialize module with streaming SourceMapDecoder
  final deserializedModule = Module.deserialize(
    Deserializer(originalBytes),
    debugInfoDeserializer: SourceMapDecoder.fromJson(originalJson),
  );

  // Verify deserialized module debug info
  Expect.isNotNull(deserializedModule.debugInfoTables);
  Expect.listEquals(
    ['file:///app/a.dart', 'file:///app/b.dart'],
    deserializedModule.debugInfoTables!.files.map((u) => u.toString()).toList(),
  );
  Expect.listEquals([
    'funcA',
    'funcB',
  ], deserializedModule.debugInfoTables!.names);

  // Verify function source mappings
  final f1 = deserializedModule.functions.defined[0];
  final r1 = DebugInfoReader(
    f1.body.debugInfo!,
    deserializedModule.debugInfoTables,
  );
  Expect.isTrue(r1.moveNext());
  Expect.equals(0, r1.offset);
  Expect.equals(file1, r1.fileUri);
  Expect.equals(10, r1.line);
  Expect.equals(0, r1.col);
  Expect.equals('funcA', r1.name);

  Expect.isTrue(r1.moveNext());
  Expect.equals(1, r1.offset);
  Expect.equals(file1, r1.fileUri);
  Expect.equals(11, r1.line);
  Expect.equals(4, r1.col);
  Expect.equals('funcA', r1.name);
  Expect.isFalse(r1.moveNext());

  final f2 = deserializedModule.functions.defined[1];
  final r2 = DebugInfoReader(
    f2.body.debugInfo!,
    deserializedModule.debugInfoTables,
  );
  Expect.isTrue(r2.moveNext());
  Expect.equals(0, r2.offset);
  Expect.equals(file2, r2.fileUri);
  Expect.equals(20, r2.line);
  Expect.equals(2, r2.col);
  Expect.equals('funcB', r2.name);

  Expect.isTrue(r2.moveNext());
  Expect.equals(1, r2.offset);
  Expect.isFalse(r2.hasSourcePosition);
  Expect.isFalse(r2.moveNext());

  // Serialize the deserialized module and compare generated Wasm bytes & source map JSON
  final reserializer = Serializer();
  final reserializedSourceMapBuilder = SourceMapBuilder(
    deserializedModule.debugInfoTables,
  );
  deserializedModule.serialize(reserializer, reserializedSourceMapBuilder);
  Expect.listEquals(originalBytes, reserializer.data);

  final reserializedJson = reserializedSourceMapBuilder.toJson();

  Expect.equals(originalJson['version'], reserializedJson['version']);
  Expect.listEquals(
    originalJson['sources'] as List,
    reserializedJson['sources'] as List,
  );
  Expect.listEquals(
    originalJson['names'] as List,
    reserializedJson['names'] as List,
  );
  Expect.equals(originalJson['mappings'], reserializedJson['mappings']);
}
