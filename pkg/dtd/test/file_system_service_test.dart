// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:dtd/dtd.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  final fooDirContents = <Uri>[];
  final barDirContents = <Uri>[];
  late ToolingDaemonTestProcess toolingDaemonProcess;
  late Directory tmpDirectory;
  late Directory fooDirectory;
  late Directory barDirectory;
  late File fooPubspecFile;
  late File barPubspecFile;
  late File aFile;
  late File bFile;
  late Directory cDir;
  late File eFile;
  late File fFile;
  final aFileContents = 'These are the contents for aFile';
  final eFileContents = 'These are the contents for eFile';
  late DartToolingDaemon client;
  late String dtdSecret;
  late Uri dtdUri;
  setUp(() async {
    tmpDirectory = await Directory.systemTemp.createTemp();

    // Test directory structure:
    //
    // foo/
    //   a.txt
    //   b.txt
    //   pubspec.yaml
    //   C/
    //     d.txt
    //     pubspec.yaml
    // bar/
    //   e.txt
    //   f.txt
    //   pubspec.yaml

    // Setup foo dir
    fooDirectory = Directory(p.join(tmpDirectory.path, 'foo'))..createSync();
    aFile = File(p.join(fooDirectory.path, 'a.txt'))
      ..writeAsStringSync(aFileContents)
      ..createSync();
    bFile = File(p.join(fooDirectory.path, 'b.txt'))..createSync();
    fooPubspecFile = File(p.join(fooDirectory.path, 'pubspec.yaml'))
      ..createSync();
    cDir = Directory(p.join(fooDirectory.path, 'C'))..createSync();
    File(p.join(fooDirectory.path, 'C', 'd.txt')).createSync();
    File(p.join(fooDirectory.path, 'C', 'pubspec.yaml')).createSync();

    fooDirContents.clear();
    fooDirContents.addAll([aFile.uri, bFile.uri, fooPubspecFile.uri, cDir.uri]);

    // Setup bar dir
    barDirectory = Directory(p.join(tmpDirectory.path, 'bar'));
    barDirectory.createSync();

    eFile = File(p.join(barDirectory.path, 'e.txt'))
      ..writeAsStringSync(eFileContents)
      ..createSync();
    fFile = File(p.join(barDirectory.path, 'f.txt'))..createSync();
    barPubspecFile = File(p.join(barDirectory.path, 'pubspec.yaml'))
      ..createSync();

    barDirContents.clear();
    barDirContents.addAll([eFile.uri, fFile.uri, barPubspecFile.uri]);
  });

  tearDown(() {
    tmpDirectory.deleteSync(recursive: true);
    toolingDaemonProcess.kill();
  });

  group('restricted', () {
    setUp(() async {
      toolingDaemonProcess = ToolingDaemonTestProcess(unrestricted: false);
      await toolingDaemonProcess.start();
      dtdUri = toolingDaemonProcess.uri;
      dtdSecret = toolingDaemonProcess.trustedSecret!;

      client = await DartToolingDaemon.connect(dtdUri);
    });

    group('FileSystem', () {
      group('setIDEWorkspaceRoots', () {
        test('wrong secret is unauthorized', () {
          expect(
            () => client.setIDEWorkspaceRoots('abc123', [Uri.directory('/')]),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
          expect(
            () => client.readFileAsString(aFile.uri),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
        });

        test('root must have file scheme', () {
          expect(
            () => client
                .setIDEWorkspaceRoots(dtdSecret, [Uri.parse('/some/path/')]),
            throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
          );
        });

        test('no IDE workspace roots', () {
          final file = File(p.join(fooDirectory.path, 'newfile.txt'));
          expect(
            () => client.listDirectoryContents(fooDirectory.uri),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
          expect(
            () => client.readFileAsString(
              file.uri,
            ),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
          expect(
            () => client.writeFileAsString(
              file.uri,
              'this should not be written',
            ),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
          expect(file.existsSync(), false);
        });

        test('one IDE workspace root', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);

          final fileContents = 'New file contents';
          final listResult = await client.listDirectoryContents(
            fooDirectory.uri,
          );
          expect(listResult.uris, containsAll(fooDirContents));

          await client.writeFileAsString(aFile.uri, fileContents);

          final readResult = await client.readFileAsString(aFile.uri);
          expect(readResult.content, fileContents);
        });

        test('multiple IDE workspace roots', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [
            fooDirectory.uri,
            barDirectory.uri,
          ]);

          // Operate in foo
          final newAFileContents = 'New afile contents';
          final fooListResult = await client.listDirectoryContents(
            fooDirectory.uri,
          );
          expect(fooListResult.uris, containsAll(fooDirContents));

          await client.writeFileAsString(aFile.uri, newAFileContents);

          final readResult = await client.readFileAsString(aFile.uri);
          expect(readResult.content, newAFileContents);

          // Operate in bar
          final newEFileContents = 'New efile contents';
          final barListResult = await client.listDirectoryContents(
            fooDirectory.uri,
          );
          expect(barListResult.uris, containsAll(fooDirContents));

          await client.writeFileAsString(aFile.uri, newEFileContents);

          final eReadResult = await client.readFileAsString(aFile.uri);
          expect(eReadResult.content, newEFileContents);
        });

        test('remove an IDE workspace root', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [
            fooDirectory.uri,
            barDirectory.uri,
          ]);
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);

          final fileContents = 'New file contents';
          final listResult = await client.listDirectoryContents(
            fooDirectory.uri,
          );
          expect(
            listResult.uris,
            containsAll(fooDirContents),
          );

          await client.writeFileAsString(aFile.uri, fileContents);

          final readResult = await client.readFileAsString(aFile.uri);
          expect(readResult.content, fileContents);

          expect(
            () => client.listDirectoryContents(barDirectory.uri),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
          expect(
            () => client.readFileAsString(eFile.uri),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
          expect(
            () => client.writeFileAsString(eFile.uri, fileContents),
            throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
          );
        });
      });

      group('getIDEWorkspaceRoots', () {
        test('empty IDE workspace roots', () async {
          final roots = await client.getIDEWorkspaceRoots();
          expect(roots.ideWorkspaceRoots, isEmpty);
        });

        test('multiple IDE workspace roots', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [
            fooDirectory.uri,
            barDirectory.uri,
          ]);
          final roots = await client.getIDEWorkspaceRoots();
          expect(
            roots.ideWorkspaceRoots,
            containsAll([fooDirectory.uri, barDirectory.uri]),
          );
        });
      });

      group('getProjectRoots', () {
        test('with empty IDE workspace roots', () async {
          final roots = await client.getIDEWorkspaceRoots();
          expect(roots.ideWorkspaceRoots, isEmpty);

          final projectRoots = await client.getProjectRoots();
          expect(projectRoots.uris, isEmpty);
        });

        test('with a single IDE workspace root', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          final projectRoots = await client.getProjectRoots();
          final expected = [fooDirectory.uri, cDir.uri];
          expect(projectRoots.uris, containsAll(expected));
          expect(projectRoots.uris?.length, expected.length);
        });

        test('with a multiple IDE workspace roots', () async {
          await client.setIDEWorkspaceRoots(
            dtdSecret,
            [fooDirectory.uri, barDirectory.uri],
          );
          final projectRoots = await client.getProjectRoots();
          final expected = [fooDirectory.uri, cDir.uri, barDirectory.uri];
          expect(projectRoots.uris, containsAll(expected));
          expect(projectRoots.uris?.length, expected.length);
        });

        test('searches up to a specified depth', () async {
          await client.setIDEWorkspaceRoots(
            dtdSecret,
            [fooDirectory.uri, barDirectory.uri],
          );
          final projectRoots = await client.getProjectRoots(depth: 1);
          final expected = [fooDirectory.uri, barDirectory.uri];
          expect(projectRoots.uris, containsAll(expected));
          expect(projectRoots.uris?.length, expected.length);
        });

        test('does not follow symlinks', () async {
          // Add a symlink under [fooDirectory] that points to the
          // [tmpDirectory]. Since the [tmpDirectory] contains [fooDirectory]
          // and [barDirectory], [client.getProjectRoots] would contain
          // duplicates of each project root if the traversal followed symlinks.
          final symlinkDir = Link(p.join(fooDirectory.path, 'SomeDir'))
            ..createSync(tmpDirectory.path, recursive: true);
          final extraRoot = Directory(p.join(tmpDirectory.path, 'Extra'))
            ..createSync();
          final symlinkFile = Link(p.join(extraRoot.path, 'pubspec.yaml'))
            ..createSync(
              p.join(tmpDirectory.path, 'pubspec.yaml'),
              recursive: true,
            );

          await client.setIDEWorkspaceRoots(
            dtdSecret,
            [fooDirectory.uri, barDirectory.uri, extraRoot.uri],
          );

          final projectRoots = await client.getProjectRoots();
          final expectedUris = [fooDirectory.uri, cDir.uri, barDirectory.uri];
          expect(projectRoots.uris, containsAll(expectedUris));
          expect(projectRoots.uris?.length, expectedUris.length);

          symlinkDir.deleteSync();
          symlinkFile.deleteSync();
          extraRoot.deleteSync();
        });
      });

      group('listDirectoryContents', () {
        test('listing a file should fail', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          expect(
            () => client.listDirectoryContents(aFile.uri),
            throwsAnRpcError(RpcErrorCodes.kDirectoryDoesNotExist),
          );
        });

        test('non-existent directory should fail', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          expect(
            () => client.listDirectoryContents(
              Uri.directory(p.join(fooDirectory.path, 'A')),
            ),
            throwsAnRpcError(RpcErrorCodes.kDirectoryDoesNotExist),
          );
        });

        test('should work for an empty directory', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          final emptyFooDir = Directory(p.join(fooDirectory.path, 'emptyDir'));
          emptyFooDir.createSync();

          final listResult =
              await client.listDirectoryContents(emptyFooDir.uri);
          expect(listResult.uris, isEmpty);
        });

        test('must have a file scheme', () {
          expect(
            () => client.listDirectoryContents(
              Uri.parse('/some/path/'),
            ),
            throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
          );
        });
      });

      group('readFileAsString', () {
        test('fails on a non-existent file', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          expect(
            () => client.readFileAsString(
              File(p.join(fooDirectory.path, 'nonExistentFile.txt')).uri,
            ),
            throwsAnRpcError(RpcErrorCodes.kFileDoesNotExist),
          );
        });

        test('must have a file scheme', () {
          expect(
            () => client.readFileAsString(Uri.parse('/some/path/')),
            throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
          );
        });
      });

      group('writeFileAsString', () {
        final newFileContents = 'Some new file contents';

        test('can overwrite an existing file', () async {
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);

          expect(aFile.readAsStringSync(), aFileContents);

          await client.writeFileAsString(aFile.uri, newFileContents);

          expect(aFile.readAsStringSync(), newFileContents);
        });

        test('creates the file if it does not exist', () async {
          final nonExistentFile = File(
            p.join(fooDirectory.path, 'nonExistentFile.txt'),
          );
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          expect(nonExistentFile.existsSync(), false);
          await client.writeFileAsString(nonExistentFile.uri, newFileContents);
          expect(nonExistentFile.existsSync(), true);
          expect(nonExistentFile.readAsStringSync(), newFileContents);
        });

        test('creates sub directories if they don\'t exist', () async {
          final fileInNonExistentDirectory = File(
            p.join(
              fooDirectory.path,
              'a',
              'b',
              'c',
              'nonExistentFile.txt',
            ),
          );
          await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
          expect(fileInNonExistentDirectory.existsSync(), false);
          await client.writeFileAsString(
            fileInNonExistentDirectory.uri,
            newFileContents,
          );
          expect(fileInNonExistentDirectory.existsSync(), true);
          expect(
            fileInNonExistentDirectory.readAsStringSync(),
            newFileContents,
          );
        });

        test('must have a file scheme', () {
          expect(
            () => client.writeFileAsString(
              Uri.parse('/some/path/'),
              'some contents',
            ),
            throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
          );
        });
      });
    });
  });

  group('unrestricted', () {
    setUp(() async {
      toolingDaemonProcess = ToolingDaemonTestProcess(unrestricted: true);
      await toolingDaemonProcess.start();
      dtdUri = toolingDaemonProcess.uri;

      client = await DartToolingDaemon.connect(dtdUri);
    });

    test('works when no roots set', () async {
      final fileContents = 'New file contents';

      expect((await client.getIDEWorkspaceRoots()).ideWorkspaceRoots, isEmpty);

      final listResult = await client.listDirectoryContents(fooDirectory.uri);
      expect(listResult.uris, containsAll(fooDirContents));

      await client.writeFileAsString(aFile.uri, fileContents);

      final readResult = await client.readFileAsString(aFile.uri);
      expect(readResult.content, fileContents);
    });

    test(
      'works when ide workspace roots set to a different directory',
      () async {
        await client.setIDEWorkspaceRoots(
          Random().nextInt(10000).toString(),
          [barDirectory.uri],
        );
        final fileContents = 'New file contents';
        final listResult = await client.listDirectoryContents(fooDirectory.uri);
        expect(listResult.uris, containsAll(fooDirContents));

        await client.writeFileAsString(aFile.uri, fileContents);

        final readResult = await client.readFileAsString(aFile.uri);
        expect(readResult.content, fileContents);
        expect((await client.getIDEWorkspaceRoots()).ideWorkspaceRoots, [
          barDirectory.uri,
        ]);
      },
    );
  });
}

Matcher throwsAnRpcError(int code) {
  return throwsA(predicate((p0) => (p0 is RpcException) && (p0.code == code)));
}
