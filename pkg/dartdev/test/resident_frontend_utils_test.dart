// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:dartdev/src/resident_frontend_utils.dart';
import 'package:frontend_server/resident_frontend_server_utils.dart'
    show ResidentCompilerInfo;
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'utils.dart';

void main() {
  late TestProject testProject;
  late File testExecutableFile;

  setUpAll(() async {
    testProject = project(mainSrc: 'void main() {}');
    testExecutableFile = File(path.join(testProject.dirPath, 'exe'));
  });

  group('ResidentCompilerInfo.fromFile', () {
    test('correctly parses resident compiler info files', () async {
      final testInfoFile = File(path.join(
        testProject.dirPath,
        'resident_compiler_info.txt',
      ));
      testInfoFile.writeAsStringSync('address:127.0.0.1 port:45678');

      final testInfo = ResidentCompilerInfo.fromFile(testInfoFile);
      expect(testInfo.address.address, '127.0.0.1');
      expect(testInfo.port, 45678);
    });
  });

  group('isFileKernelFile', () {
    test(
        'returns false when passed a file that is too small to contain the kernel magic number',
        () async {
      testExecutableFile.writeAsBytesSync([1, 2, 3]);
      expect(await isFileKernelFile(testExecutableFile), false);
    });

    test(
        'returns false when passed a file that does not start with the kernel magic number',
        () async {
      testExecutableFile.writeAsBytesSync([1, 2, 3, 4]);
      expect(await isFileKernelFile(testExecutableFile), false);
    });

    test(
        'returns true when passed a file that starts with the kernel magic number',
        () async {
      testExecutableFile.writeAsBytesSync([0x90, 0xab, 0xcd, 0xef, 1, 2, 3]);
      expect(await isFileKernelFile(testExecutableFile), true);
    });
  });

  group('isFileAppJitSnapshot', () {
    test(
        'returns false when passed a file that is too small to contain the AppJIT magic number',
        () async {
      testExecutableFile.writeAsBytesSync([1, 2, 3]);
      expect(await isFileAppJitSnapshot(testExecutableFile), false);
    });

    test(
        'returns false when passed a file that does not start with the AppJIT magic number',
        () async {
      testExecutableFile.writeAsBytesSync([1, 2, 3, 4, 5, 6, 7, 8]);
      expect(await isFileAppJitSnapshot(testExecutableFile), false);
    });

    test(
        'returns true when passed a file that starts with the AppJIT magic number',
        () async {
      testExecutableFile
          .writeAsBytesSync([0xdc, 0xdc, 0xf6, 0xf6, 0, 0, 0, 0, 1, 2, 3]);
      expect(await isFileAppJitSnapshot(testExecutableFile), true);
    });

    group('isFileAotSnapshot', () {
      test(
          'returns false when passed a file that is too small to contain any of the AOT magic numbers',
          () async {
        testExecutableFile.writeAsBytesSync([1]);
        expect(await isFileAotSnapshot(testExecutableFile), false);
      });

      test(
          'returns false when passed a file that does not start with any of the AOT magic numbers',
          () async {
        testExecutableFile.writeAsBytesSync([1, 2, 3, 4]);
        expect(await isFileAotSnapshot(testExecutableFile), false);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for arm32 COFF files',
          () async {
        testExecutableFile.writeAsBytesSync([0x01, 0xc0, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for arm64 COFF files',
          () async {
        testExecutableFile.writeAsBytesSync([0xaa, 0x64, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for riscv32 COFF files',
          () async {
        testExecutableFile.writeAsBytesSync([0x50, 0x32, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for riscv64 COFF files',
          () async {
        testExecutableFile.writeAsBytesSync([0x50, 0x64, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for ELF files',
          () async {
        testExecutableFile.writeAsBytesSync([0x7f, 0x45, 0x4c, 0x46, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for macho32 files',
          () async {
        testExecutableFile.writeAsBytesSync([0xfe, 0xed, 0xfa, 0xce, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for macho64 files',
          () async {
        testExecutableFile.writeAsBytesSync([0xfe, 0xed, 0xfa, 0xcf, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });

      test(
          'returns true when passed a file that starts with the AOT magic number for macho64_arm64 files',
          () async {
        testExecutableFile.writeAsBytesSync([0xcf, 0xfa, 0xed, 0xfe, 1, 2, 3]);
        expect(await isFileAotSnapshot(testExecutableFile), true);
      });
    });
  });
}
