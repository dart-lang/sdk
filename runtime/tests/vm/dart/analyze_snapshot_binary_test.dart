// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:ffi';
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:expect/expect.dart';
import 'package:native_stack_traces/elf.dart';
import 'package:path/path.dart' as path;

import 'use_flag_test_helper.dart';

const int headerSize = 8;
final int compressedWordSize =
    sizeOf<Pointer>() == 8 && !Platform.executable.contains('64C') ? 8 : 4;
const int wordSize = 8; // analyze_snapshot is not supported on arm32

// Used to ensure we don't have multiple equivalent calls to test.
final _seenDescriptions = <String>{};

Future<void> testAOT(
  String dillPath, {
  bool useAsm = false,
  bool forceDrops = false,
  bool stripUtil = false, // Note: forced true if useAsm.
  bool stripFlag = false,
}) async {
  const isProduct = const bool.fromEnvironment('dart.vm.product');

  final analyzeSnapshot = path.join(buildDir, 'analyze_snapshot');

  // For assembly, we can't test the sizes of the snapshot sections, since we
  // don't have a Mach-O reader for Mac snapshots and for ELF, the assembler
  // merges the text/data sections and the VM/isolate section symbols may not
  // have length information. Thus, we force external stripping so we can test
  // the approximate size of the stripped snapshot.
  if (useAsm) {
    stripUtil = true;
  }

  final descriptionBuilder = StringBuffer()..write(useAsm ? 'assembly' : 'elf');
  if (forceDrops) {
    descriptionBuilder.write('-dropped');
  }
  if (stripFlag) {
    descriptionBuilder.write('-intstrip');
  }
  if (stripUtil) {
    descriptionBuilder.write('-extstrip');
  }

  final description = descriptionBuilder.toString();
  Expect.isTrue(
    _seenDescriptions.add(description),
    "test configuration $description would be run multiple times",
  );

  await withTempDir('analyze_snapshot_binary-$description', (
    String tempDir,
  ) async {
    // Generate the snapshot
    final snapshotPath = path.join(tempDir, 'test.snap');
    final commonSnapshotArgs = [
      if (stripFlag) '--strip', //  gen_snapshot specific and not a VM flag.
      if (forceDrops) ...[
        '--dwarf-stack-traces',
        '--no-retain-function-objects',
        '--no-retain-code-objects',
      ],
      dillPath,
    ];

    final int textSectionSize;
    if (useAsm) {
      final assemblyPath = path.join(tempDir, 'test.S');

      textSectionSize = _findTextSectionSize(
        await runOutput(genSnapshot, <String>[
          '--snapshot-kind=app-aot-assembly',
          '--assembly=$assemblyPath',
          '--print-snapshot-sizes',
          ...commonSnapshotArgs,
        ], ignoreStdErr: true),
      );

      await assembleSnapshot(assemblyPath, snapshotPath);
    } else {
      textSectionSize = _findTextSectionSize(
        await runOutput(genSnapshot, <String>[
          '--snapshot-kind=app-aot-elf',
          '--elf=$snapshotPath',
          '--print-snapshot-sizes',
          ...commonSnapshotArgs,
        ], ignoreStdErr: true),
      );
    }

    print("Snapshot generated at $snapshotPath.");

    // May not be ELF, but another format.
    final elf = Elf.fromFile(snapshotPath);
    if (!useAsm) {
      Expect.isNotNull(elf);
    }

    if (elf != null) {
      // Verify some ELF file format parameters.
      final textSections = elf.namedSections(".text");
      Expect.isNotEmpty(textSections);
      Expect.isTrue(
        textSections.length <= 2,
        "More text sections than expected",
      );
      final dataSections = elf.namedSections(".rodata");
      Expect.isNotEmpty(dataSections);
      Expect.isTrue(
        dataSections.length <= 2,
        "More data sections than expected",
      );
    }

    final analyzerOutputPath = path.join(tempDir, 'analyze_test.json');

    // This will throw if exit code is not 0.
    await run(analyzeSnapshot, <String>[
      '--out=$analyzerOutputPath',
      '$snapshotPath',
    ]);

    final analyzerJsonBytes = await readFile(analyzerOutputPath);
    final analyzerJson = json.decode(analyzerJsonBytes);
    Expect.isFalse(analyzerJson.isEmpty);
    Expect.isTrue(
      analyzerJson.keys.toSet().containsAll([
        'snapshot_data',
        'objects',
        'metadata',
      ]),
    );

    final objects = (analyzerJson['objects'] as List)
        .map((o) => o as Map)
        .toList();
    final classes = objects.where((o) => o['type'] == 'Class').toList();
    final classnames = <int, String>{};
    final superclass = <int, int>{};
    final implementedInterfaces = <int, List<int>>{};
    for (final klass in classes) {
      final id = klass['id'];
      superclass[id] = klass['super_class'] as int;
      classnames[id] = klass['name'];
      implementedInterfaces[id] = [
        for (final superTypeId in klass['interfaces'] as List? ?? [])
          objects[superTypeId]['type_class']!,
      ];
    }

    // Find MethodChannel class.
    final methodChannelId = classnames.entries
        .singleWhere((e) => e.value == 'MethodChannel')
        .key;

    // Find string instance.
    final stringList = objects
        .where((o) => o['type'] == 'String' && o['value'] == 'constChannel1')
        .toList();
    Expect.isTrue(
      stringList.length == 1,
      'one "constChannel1" string must exist in output',
    );
    final int stringObjId = stringList.first['id'];

    // Find MethodChannel instance.
    final instanceList = objects
        .where(
          (o) =>
              o['type'] == 'Instance' &&
              o['class'] == methodChannelId &&
              o['references'].contains(stringObjId),
        )
        .toList();
    Expect.isTrue(instanceList.length == 1, '''one instance of MethodChannel
        with reference to "constChannel1" must exist in output''');

    // Test class hierarchy information
    final myBaseClassId = classnames.entries
        .singleWhere((e) => e.value == 'MyBase')
        .key;
    final mySubClassId = classnames.entries
        .singleWhere((e) => e.value == 'MySub')
        .key;
    final myInterfaceClassId = classnames.entries
        .singleWhere((e) => e.value == 'MyInterface')
        .key;

    Expect.equals(myBaseClassId, superclass[mySubClassId]);
    Expect.equals(
      myInterfaceClassId,
      implementedInterfaces[mySubClassId]!.single,
    );

    // Ensure instance fields of classes are reported.
    final baseClass =
        objects[classnames.entries
            .singleWhere((e) => e.value == 'FieldTestBase')
            .key];
    final subClass =
        objects[classnames.entries
            .singleWhere((e) => e.value == 'FieldTestSub')
            .key];
    final baseFieldIds = baseClass['fields'];
    final baseFields = [for (final int id in baseFieldIds) objects[id]];
    final baseSlots = baseClass['instance_slots']
        .map<Map>((e) => e as Map)
        .toList();
    final subFieldIds = subClass['fields'];
    final subFields = [for (final int id in subFieldIds) objects[id]];
    final subSlots = subClass['instance_slots'];

    // We have:
    //   class Base {
    //     static int baseS0 = int.parse('1');
    //     static int baseS1 = int.parse('2');
    //     int base0;
    //     double base1;
    //     Object? base2;
    //     Float32x4 base3;
    //     Float64x2 base4;
    //   }
    //
    // This static field is never tree shaken.
    expectField(baseFields[0], name: 'baseS0', flags: ['static']);
    expectField(baseFields[1], name: 'baseS1', flags: ['static']);

    // Neighboring static fields should always be one word away
    final int staticFieldOffset0 = baseFields[0]["static_field_offset"];
    final int staticFieldOffset1 = baseFields[1]["static_field_offset"];
    Expect.equals(staticFieldOffset1 - staticFieldOffset0, wordSize);

    if (isProduct) {
      // Most [Field] objests are tree shaken.
      Expect.equals(2, baseFields.length);

      int slotOffset = 0;
      slotOffset += expectUnknown8Bytes(
        baseSlots.skip(slotOffset),
        offsetReferences: 0,
        offsetBytes: 0,
      );
      slotOffset += expectUnknown8Bytes(
        baseSlots.skip(slotOffset),
        offsetReferences: 0,
        offsetBytes: 8,
      );
      slotOffset += expectUnknownReference(
        baseSlots[slotOffset],
        offsetReferences: 0,
        offsetBytes: 16,
      );
      slotOffset += expectUnknown16Bytes(
        baseSlots.skip(slotOffset),
        offsetReferences: 1,
        offsetBytes: 16,
      );
      slotOffset += expectUnknown16Bytes(
        baseSlots.skip(slotOffset),
        offsetReferences: 1,
        offsetBytes: 32,
      );
    } else {
      // We don't tree shake [Field] objects in non-product builds.
      Expect.equals(7, baseFields.length);
      expectField(
        baseFields[2],
        name: 'base0',
        isReference: false,
        unboxedType: 'int',
      );
      expectField(
        baseFields[3],
        name: 'base1',
        isReference: false,
        unboxedType: 'double',
      );
      expectField(baseFields[4], name: 'base2');
      expectField(
        baseFields[5],
        name: 'base3',
        isReference: false,
        unboxedType: 'Float32x4',
      );
      expectField(
        baseFields[6],
        name: 'base4',
        isReference: false,
        unboxedType: 'Float64x2',
      );
      int slotOffset = 0;
      slotOffset += expectInstanceSlot(
        baseSlots[slotOffset],
        offsetReferences: 0,
        offsetBytes: 0,
        isReference: false,
        fieldId: baseFieldIds[2],
      );
      slotOffset += expectInstanceSlot(
        baseSlots[slotOffset],
        offsetReferences: 0,
        offsetBytes: 8,
        isReference: false,
        fieldId: baseFieldIds[3],
      );
      slotOffset += expectInstanceSlot(
        baseSlots[slotOffset],
        offsetReferences: 0,
        offsetBytes: 16,
        fieldId: baseFieldIds[4],
      );
      slotOffset += expectInstanceSlot(
        baseSlots[slotOffset],
        offsetReferences: 1,
        offsetBytes: 16,
        isReference: false,
        fieldId: baseFieldIds[5],
      );
      slotOffset += expectInstanceSlot(
        baseSlots[slotOffset],
        offsetReferences: 1,
        offsetBytes: 32,
        isReference: false,
        fieldId: baseFieldIds[6],
      );
    }
    // We have:
    //   class Sub<T> extends Base{
    //     late int subL1 = int.parse('1');
    //     late final double subL2 = double.parse('1.2');
    //   }
    // These late instance fields are never tree shaken.
    expectField(subFields[0], name: 'subL1', flags: ['late']);
    expectField(subFields[1], name: 'subL2', flags: ['final', 'late']);
    expectTypeArgumentsSlot(
      subSlots[0],
      offsetReferences: 1,
      offsetBytes: 8 + 8 + 16 + 16,
    );
    expectSlot(
      subSlots[1],
      offsetReferences: 2,
      offsetBytes: 8 + 8 + 16 + 16,
      type: 'instance_field',
      fieldId: subFieldIds[0],
    );
    expectSlot(
      subSlots[2],
      offsetReferences: 3,
      offsetBytes: 8 + 8 + 16 + 16,
      type: 'instance_field',
      fieldId: subFieldIds[1],
    );

    Expect.isTrue(
      analyzerJson['metadata'].containsKey('analyzer_version'),
      'snapshot analyzer version must be reported',
    );
    Expect.isTrue(
      analyzerJson['metadata']['analyzer_version'] == 2,
      'invalid snapshot analyzer version',
    );

    // Find all code objects.
    final codeObjects = objects
        .where((o) => o['type'] == 'Code' && o['size'] != 0)
        .map(
          (o) => (
            name: o['name'] as String,
            stub: (o['is_stub'] as bool? ?? false),
            offset: o['offset'] as int,
            size: o['size'] as int,
          ),
        )
        .toList();
    codeObjects.sort((a, b) => a.offset.compareTo(b.offset));
    Expect.isNotEmpty(codeObjects);
    Expect.isNotNull(
      codeObjects.firstWhereOrNull((o) => o.stub && o.name == 'AllocateArray'),
      'expected stubs to be identified',
    );
    final int totalSize = codeObjects.fold(0, (size, code) => size + code.size);
    int totalGap = 0;
    for (int i = 0; i < codeObjects.length - 1; i++) {
      final code = codeObjects[i];
      final nextCode = codeObjects[i + 1];
      totalGap += code.offset + code.size - nextCode.offset;
    }
    Expect.isTrue(totalGap < 500);
    Expect.isTrue((totalSize + totalGap - textSectionSize) < 500);
  });
}

void expectField(
  Map fieldJson, {
  required String name,
  List<String> flags = const [],
  bool isReference = true,
  String? unboxedType,
}) {
  Expect.equals(name, fieldJson['name']);
  Expect.equals(isReference, fieldJson['is_reference']);
  Expect.listEquals(flags, fieldJson['flags']);
  if (unboxedType != null) {
    Expect.equals(unboxedType, fieldJson['unboxed_type']);
  } else {
    Expect.isFalse(fieldJson.containsKey('unboxed_type'));
  }
}

void expectSlot(
  Map slotJson, {
  required int offsetReferences,
  required int offsetBytes,
  required String type,
  bool isReference = true,
  int? fieldId,
}) {
  Expect.equals(type, slotJson['slot_type']);
  if (fieldId != null) {
    Expect.equals(fieldId, slotJson['field']);
  } else {
    Expect.isFalse(slotJson.containsKey('field'));
  }
  final int offset =
      headerSize + offsetReferences * compressedWordSize + offsetBytes;
  Expect.equals(offset, slotJson['offset']);
  Expect.equals(isReference, slotJson['is_reference']);
}

int expectInstanceSlot(
  Map slotJson, {
  required int offsetReferences,
  required int offsetBytes,
  bool isReference = true,
  int? fieldId,
}) {
  expectSlot(
    slotJson,
    isReference: isReference,
    fieldId: fieldId,
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes,
    type: 'instance_field',
  );
  return 1;
}

int expectUnknownReference(
  Map slotJson, {
  required int offsetReferences,
  required int offsetBytes,
}) {
  expectSlot(
    slotJson,
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes,
    type: 'unknown_slot',
  );
  return 1;
}

int expectTypeArgumentsSlot(
  Map slotJson, {
  required int offsetReferences,
  required int offsetBytes,
}) {
  expectSlot(
    slotJson,
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes,
    type: 'type_arguments_field',
  );
  return 1;
}

int expectUnknown8Bytes(
  Iterable<Map> slotJson, {
  required int offsetReferences,
  required int offsetBytes,
}) {
  final it = slotJson.iterator;
  Expect.isTrue(it.moveNext());
  expectSlot(
    it.current,
    isReference: false,
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes,
    type: 'unknown_slot',
  );
  if (compressedWordSize == 8) {
    return 1;
  }
  Expect.isTrue(it.moveNext());
  expectSlot(
    it.current,
    isReference: false,
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes + compressedWordSize,
    type: 'unknown_slot',
  );
  return 2;
}

int expectUnknown16Bytes(
  Iterable<Map> slotJson, {
  required int offsetReferences,
  required int offsetBytes,
}) {
  int slots = 0;
  slots += expectUnknown8Bytes(
    slotJson,
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes,
  );
  slots += expectUnknown8Bytes(
    slotJson.skip(slots),
    offsetReferences: offsetReferences,
    offsetBytes: offsetBytes + 8,
  );
  return slots;
}

main() async {
  void printSkip(String description) => print(
    'Skipping $description for ${path.basename(buildDir)} '
            'on ${Platform.operatingSystem}' +
        (clangBuildToolsDir == null ? ' without //buildtools' : ''),
  );

  // We don't have access to the SDK on Android.
  if (Platform.isAndroid) {
    printSkip('all tests');
    return;
  }

  await withTempDir('analyze_snapshot_binary', (String tempDir) async {
    // We only need to generate the dill file once for all JIT tests.
    final thisTestPath = path.join(
      sdkDir,
      'runtime',
      'tests',
      'vm',
      'dart',
      'analyze_snapshot_program.dart',
    );

    // We only need to generate the dill file once for all AOT tests.
    final aotDillPath = path.join(tempDir, 'aot_test.dill');
    await run(genKernel, <String>[
      '--aot',
      '--platform',
      platformDill,
      ...Platform.executableArguments.where(
        (arg) =>
            arg.startsWith('--enable-experiment=') ||
            arg == '--sound-null-safety' ||
            arg == '--no-sound-null-safety',
      ),
      '-o',
      aotDillPath,
      thisTestPath,
    ]);

    // Just as a reminder for AOT tests:
    // * If useAsm is true, then stripUtil is forced (as the assembler may add
    //   extra information that needs stripping), so no need to specify
    //   stripUtil for useAsm tests.

    await Future.wait([
      // Test unstripped ELF generation directly.
      testAOT(aotDillPath),
      testAOT(aotDillPath, forceDrops: true),

      // Test flag-stripped ELF generation.
      testAOT(aotDillPath, stripFlag: true),
    ]);

    // Test unstripped ELF generation that is then externally stripped.
    await Future.wait([testAOT(aotDillPath, stripUtil: true)]);

    // Dont test assembled snapshot for simulated platforms or macos
    if (!buildDir.endsWith("SIMARM64") &&
        !buildDir.endsWith("SIMARM64C") &&
        !Platform.isMacOS) {
      await Future.wait([
        // Test unstripped assembly generation that is then externally stripped.
        testAOT(aotDillPath, useAsm: true),
        // Test stripped assembly generation that is then externally stripped.
        testAOT(aotDillPath, useAsm: true, stripFlag: true),
      ]);
    }
  });
}

Future<String> readFile(String file) {
  return new File(file).readAsString();
}

int _findTextSectionSize(List<String> output) {
  const prefix = 'Instructions(CodeSize): ';
  return int.parse(
    output.firstWhere((l) => l.startsWith(prefix)).substring(prefix.length),
  );
}
