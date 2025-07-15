// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:dtd/dtd.dart';
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
      toolingDaemonProcess = ToolingDaemonTestProcess();
      await toolingDaemonProcess.start();
      dtdUri = toolingDaemonProcess.uri;
      dtdSecret = toolingDaemonProcess.trustedSecret!;

      client = await DartToolingDaemon.connect(dtdUri);
    });

    group(FileSystemServiceConstants.serviceName, () {
      group(FileSystemServiceConstants.setIDEWorkspaceRoots, () {
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

      group(FileSystemServiceConstants.getIDEWorkspaceRoots, () {
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
            roots.ideWorkspaceRoots.map((e) => p.normalize(e.path)),
            containsAll(
              [fooDirectory.uri, barDirectory.uri]
                  .map((e) => p.normalize(e.path)),
            ),
          );
        });
      });

      group(FileSystemServiceConstants.getProjectRoots, () {
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

      group(FileSystemServiceConstants.listDirectoryContents, () {
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

      group(FileSystemServiceConstants.readFileAsString, () {
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

        group(
          'windows paths',
          () {
            // Test paths in various formats. We will test all combinations of
            // these both as the set roots and the readFile path to ensure the
            // calling client doesn't need to use the same escaping as the
            // editor.
            final roots = [
              Uri.parse('file:///C:/foo'),
              Uri.parse('file:///C%3A/foo'),
              Uri.parse('file:///c:/foo'),
            ];
            final files = roots
                .map((uri) => uri.replace(path: '${uri.path}/file.txt'))
                .toList();

            for (final root in roots) {
              for (final file in files) {
                test('can read $file in $root', () async {
                  await client.setIDEWorkspaceRoots(dtdSecret, [root]);
                  expect(
                    () => client.readFileAsString(file),
                    // Expect file does not exist (NOT a permission error).
                    throwsAnRpcError(RpcErrorCodes.kFileDoesNotExist),
                  );
                });
              }
            }
          },
          skip: !Platform.isWindows,
        );
      });

      group(FileSystemServiceConstants.writeFileAsString, () {
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

    group('relative paths', () {
      test('normalizes paths when setting pub root', () async {
        final relativePath = p.join(fooDirectory.path, '..', 'bar', 'a.txt');
        final simplifiedPath = p.join(barDirectory.path, 'a.txt');

        await client.call(
          FileSystemServiceConstants.serviceName,
          FileSystemServiceConstants.setIDEWorkspaceRoots,
          params: {
            DtdParameters.secret: dtdSecret,
            DtdParameters.roots: [
              Uri.file(relativePath).toString(),
            ],
          },
        );
        final roots = await client.getIDEWorkspaceRoots();
        expect(
          roots.ideWorkspaceRoots.map((e) => e.toFilePath()),
          [simplifiedPath],
        );
      });

      test('prevents access outside of workspace roots for relative paths',
          () async {
        await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);
        expect(
          () => client.call(
            FileSystemServiceConstants.serviceName,
            FileSystemServiceConstants.readFileAsString,
            params: {
              DtdParameters.uri: p.join('${fooDirectory.uri}', '..', 'a.txt'),
            },
          ),
          throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
        );
        expect(
          () => client.call(
            FileSystemServiceConstants.serviceName,
            FileSystemServiceConstants.writeFileAsString,
            params: {
              DtdParameters.uri: p.join('${fooDirectory.uri}', '..', 'a.txt'),
              DtdParameters.contents: 'abc',
              DtdParameters.encoding: 'utf-8',
            },
          ),
          throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
        );
        expect(
          () => client.call(
            FileSystemServiceConstants.serviceName,
            FileSystemServiceConstants.listDirectoryContents,
            params: {
              DtdParameters.uri: p.join('${fooDirectory.uri}', '..'),
            },
          ),
          throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
        );
      });

      test('allows access to relative paths with ide workspace roots',
          () async {
        await client.setIDEWorkspaceRoots(dtdSecret, [fooDirectory.uri]);

        final writeResult = await client.call(
          FileSystemServiceConstants.serviceName,
          FileSystemServiceConstants.writeFileAsString,
          params: {
            DtdParameters.uri: p.join(
              fooDirectory.uri.toString(),
              'C',
              'D',
              '..',
              '..',
              'C',
              'd.txt',
            ),
            DtdParameters.contents: 'abc',
            DtdParameters.encoding: 'utf-8',
          },
        );

        expect(writeResult.result, {'type': 'Success'});
        final readResult = await client.call(
          FileSystemServiceConstants.serviceName,
          FileSystemServiceConstants.readFileAsString,
          params: {
            DtdParameters.uri: p.join(
              fooDirectory.uri.toString(),
              'C',
              'D',
              '..',
              '..',
              'C',
              'd.txt',
            ),
          },
        );
        expect(readResult.result, {'type': 'FileContent', 'content': 'abc'});

        final listResult = await client.call(
          FileSystemServiceConstants.serviceName,
          FileSystemServiceConstants.listDirectoryContents,
          params: {
            DtdParameters.uri: p.join(
              fooDirectory.uri.toString(),
              'C',
              'D',
              '..',
              '..',
              'C',
            ),
          },
        );

        expect(listResult.result, {
          'type': 'UriList',
          'uris': containsAll([
            '${fooDirectory.uri}C/pubspec.yaml',
            '${fooDirectory.uri}C/d.txt',
          ]),
        });
      });

      final invalidDirectories = [
        {
          'dir': './',
          'error':
              throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
        },
        {
          'dir': '/',
          'error':
              throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
        },
        {
          'dir': '../',
          'error':
              throwsAnRpcError(RpcErrorCodes.kExpectsUriParamWithFileScheme),
        },
        {
          'dir': 'file:///~/',
          'error': throwsAnRpcError(RpcErrorCodes.kPermissionDenied),
        },
      ];
      for (final invalidDirectory in invalidDirectories) {
        test('prevents use of invalid uri: ${invalidDirectory['dir']}', () {
          final dir = invalidDirectory['dir'] as String;
          final error = invalidDirectory['error'] as Matcher;
          expect(
            () => client.call(
              FileSystemServiceConstants.serviceName,
              FileSystemServiceConstants.readFileAsString,
              params: {DtdParameters.uri: '${dir}a.txt'},
            ),
            error,
          );
          expect(
            () => client.call(
              FileSystemServiceConstants.serviceName,
              FileSystemServiceConstants.writeFileAsString,
              params: {
                DtdParameters.uri: '${dir}a.txt',
                DtdParameters.contents: 'abc',
                DtdParameters.encoding: 'utf-8',
              },
            ),
            error,
          );
          expect(
            () => client.call(
              FileSystemServiceConstants.serviceName,
              FileSystemServiceConstants.listDirectoryContents,
              params: {
                DtdParameters.uri: dir,
              },
            ),
            error,
          );
        });
      }
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
        expect(
            (await client.getIDEWorkspaceRoots())
                .ideWorkspaceRoots
                .map((e) => p.normalize(e.path)),
            [
              p.normalize(barDirectory.uri.path),
            ]);
      },
    );
  });
}
