// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library packages_list_files_test;

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../lib/src/entrypoint.dart';
import '../lib/src/io.dart';
import '../lib/src/system_cache.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

String root;
Entrypoint entrypoint;

main() {
  initConfig();

  group('not in a git repo', () {
    setUp(() {
      d.appDir().create();
      scheduleEntrypoint();
    });


    integration('lists files recursively', () {
      d.dir(appPath, [
        d.file('file1.txt', 'contents'),
        d.file('file2.txt', 'contents'),
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents'),
          d.file('subfile2.txt', 'subcontents')
        ])
      ]).create();

      schedule(() {
        expect(entrypoint.root.listFiles(), unorderedEquals([
          path.join(root, 'pubspec.yaml'),
          path.join(root, 'file1.txt'),
          path.join(root, 'file2.txt'),
          path.join(root, 'subdir', 'subfile1.txt'),
          path.join(root, 'subdir', 'subfile2.txt')
        ]));
      });
    });

    commonTests();
  });

  group('with git', () {
    setUp(() {
      ensureGit();
      d.git(appPath, [d.appPubspec()]).create();
      scheduleEntrypoint();
    });

    integration("includes files that are or aren't checked in", () {
      d.dir(appPath, [
        d.file('file1.txt', 'contents'),
        d.file('file2.txt', 'contents'),
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents'),
          d.file('subfile2.txt', 'subcontents')
        ])
      ]).create();

      schedule(() {
        expect(entrypoint.root.listFiles(), unorderedEquals([
          path.join(root, 'pubspec.yaml'),
          path.join(root, 'file1.txt'),
          path.join(root, 'file2.txt'),
          path.join(root, 'subdir', 'subfile1.txt'),
          path.join(root, 'subdir', 'subfile2.txt')
        ]));
      });
    });

    integration("ignores files that are gitignored if desired", () {
      d.dir(appPath, [
        d.file('.gitignore', '*.txt'),
        d.file('file1.txt', 'contents'),
        d.file('file2.text', 'contents'),
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents'),
          d.file('subfile2.text', 'subcontents')
        ])
      ]).create();

      schedule(() {
        expect(entrypoint.root.listFiles(useGitIgnore: true), unorderedEquals([
          path.join(root, 'pubspec.yaml'),
          path.join(root, '.gitignore'),
          path.join(root, 'file2.text'),
          path.join(root, 'subdir', 'subfile2.text')
        ]));
      });

      schedule(() {
        expect(entrypoint.root.listFiles(), unorderedEquals([
          path.join(root, 'pubspec.yaml'),
          path.join(root, 'file1.txt'),
          path.join(root, 'file2.text'),
          path.join(root, 'subdir', 'subfile1.txt'),
          path.join(root, 'subdir', 'subfile2.text')
        ]));
      });
    });

    commonTests();
  });
}

void scheduleEntrypoint() {
  schedule(() {
    root = path.join(sandboxDir, appPath);
    entrypoint = new Entrypoint(root, new SystemCache.withSources(root));
  }, 'initializing entrypoint');

  currentSchedule.onComplete.schedule(() {
    entrypoint = null;
  }, 'nulling entrypoint');
}

void commonTests() {
  integration('ignores broken symlinks', () {
    // Windows requires us to symlink to a directory that actually exists.
    d.dir(appPath, [d.dir('target')]).create();
    scheduleSymlink(path.join(appPath, 'target'), path.join(appPath, 'link'));
    schedule(() => deleteEntry(path.join(sandboxDir, appPath, 'target')));

    schedule(() {
      expect(entrypoint.root.listFiles(),
          equals([path.join(root, 'pubspec.yaml')]));
    });
  });

  integration('ignores pubspec.lock files', () {
    d.dir(appPath, [
      d.file('pubspec.lock'),
      d.dir('subdir', [d.file('pubspec.lock')])
    ]).create();

    schedule(() {
      expect(entrypoint.root.listFiles(),
          equals([path.join(root, 'pubspec.yaml')]));
    });
  });

  integration('ignores packages directories', () {
    d.dir(appPath, [
      d.dir('packages', [d.file('file.txt', 'contents')]),
      d.dir('subdir', [
        d.dir('packages', [d.file('subfile.txt', 'subcontents')]),
      ])
    ]).create();

    schedule(() {
      expect(entrypoint.root.listFiles(),
          equals([path.join(root, 'pubspec.yaml')]));
    });
  });

  integration('allows pubspec.lock directories', () {
    d.dir(appPath, [
      d.dir('pubspec.lock', [
        d.file('file.txt', 'contents'),
      ])
    ]).create();

    schedule(() {
      expect(entrypoint.root.listFiles(), unorderedEquals([
        path.join(root, 'pubspec.yaml'),
        path.join(root, 'pubspec.lock', 'file.txt')
      ]));
    });
  });

  group('and "beneath"', () {
    integration('only lists files beneath the given root', () {
      d.dir(appPath, [
        d.file('file1.txt', 'contents'),
        d.file('file2.txt', 'contents'),
        d.dir('subdir', [
          d.file('subfile1.txt', 'subcontents'),
          d.file('subfile2.txt', 'subcontents'),
          d.dir('subsubdir', [
            d.file('subsubfile1.txt', 'subsubcontents'),
            d.file('subsubfile2.txt', 'subsubcontents'),
          ])
        ])
      ]).create();

      schedule(() {
        expect(entrypoint.root.listFiles(beneath: path.join(root, 'subdir')),
            unorderedEquals([
          path.join(root, 'subdir', 'subfile1.txt'),
          path.join(root, 'subdir', 'subfile2.txt'),
          path.join(root, 'subdir', 'subsubdir', 'subsubfile1.txt'),
          path.join(root, 'subdir', 'subsubdir', 'subsubfile2.txt')
        ]));
      });
    });

    integration("doesn't care if the root is blacklisted", () {
      d.dir(appPath, [
        d.file('file1.txt', 'contents'),
        d.file('file2.txt', 'contents'),
        d.dir('packages', [
          d.file('subfile1.txt', 'subcontents'),
          d.file('subfile2.txt', 'subcontents'),
          d.dir('subsubdir', [
            d.file('subsubfile1.txt', 'subsubcontents'),
            d.file('subsubfile2.txt', 'subsubcontents')
          ])
        ])
      ]).create();

      schedule(() {
        expect(entrypoint.root.listFiles(beneath: path.join(root, 'packages')),
            unorderedEquals([
          path.join(root, 'packages', 'subfile1.txt'),
          path.join(root, 'packages', 'subfile2.txt'),
          path.join(root, 'packages', 'subsubdir', 'subsubfile1.txt'),
          path.join(root, 'packages', 'subsubdir', 'subsubfile2.txt')
        ]));
      });
    });
  });
}
