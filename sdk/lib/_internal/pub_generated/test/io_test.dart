library io_test;
import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:unittest/unittest.dart';
import '../lib/src/io.dart';
import 'test_pub.dart';
main() {
  initConfig();
  group('listDir', () {
    test('ignores hidden files by default', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        writeTextFile(path.join(temp, 'file2.txt'), '');
        writeTextFile(path.join(temp, '.file3.txt'), '');
        createDir(path.join(temp, '.subdir'));
        writeTextFile(path.join(temp, '.subdir', 'file3.txt'), '');
        expect(
            listDir(temp, recursive: true),
            unorderedEquals([path.join(temp, 'file1.txt'), path.join(temp, 'file2.txt')]));
      }), completes);
    });
    test('includes hidden files when told to', () {
      expect(withTempDir((temp) {
        writeTextFile(path.join(temp, 'file1.txt'), '');
        writeTextFile(path.join(temp, 'file2.txt'), '');
        writeTextFile(path.join(temp, '.file3.txt'), '');
        createDir(path.join(temp, '.subdir'));
        writeTextFile(path.join(temp, '.subdir', 'file3.txt'), '');
        expect(
            listDir(temp, recursive: true, includeHidden: true),
            unorderedEquals(
                [
                    path.join(temp, 'file1.txt'),
                    path.join(temp, 'file2.txt'),
                    path.join(temp, '.file3.txt'),
                    path.join(temp, '.subdir'),
                    path.join(temp, '.subdir', 'file3.txt')]));
      }), completes);
    });
    test("doesn't ignore hidden files above the directory being listed", () {
      expect(withTempDir((temp) {
        var dir = path.join(temp, '.foo', 'bar');
        ensureDir(dir);
        writeTextFile(path.join(dir, 'file1.txt'), '');
        writeTextFile(path.join(dir, 'file2.txt'), '');
        writeTextFile(path.join(dir, 'file3.txt'), '');
        expect(
            listDir(dir, recursive: true),
            unorderedEquals(
                [
                    path.join(dir, 'file1.txt'),
                    path.join(dir, 'file2.txt'),
                    path.join(dir, 'file3.txt')]));
      }), completes);
    });
  });
  group('canonicalize', () {
    test('resolves a non-link', () {
      expect(withCanonicalTempDir((temp) {
        var filePath = path.join(temp, 'file');
        writeTextFile(filePath, '');
        expect(canonicalize(filePath), equals(filePath));
      }), completes);
    });
    test('resolves a non-existent file', () {
      expect(withCanonicalTempDir((temp) {
        expect(
            canonicalize(path.join(temp, 'nothing')),
            equals(path.join(temp, 'nothing')));
      }), completes);
    });
    test('resolves a symlink', () {
      expect(withCanonicalTempDir((temp) {
        createDir(path.join(temp, 'linked-dir'));
        createSymlink(path.join(temp, 'linked-dir'), path.join(temp, 'dir'));
        expect(
            canonicalize(path.join(temp, 'dir')),
            equals(path.join(temp, 'linked-dir')));
      }), completes);
    });
    test('resolves a relative symlink', () {
      expect(withCanonicalTempDir((temp) {
        createDir(path.join(temp, 'linked-dir'));
        createSymlink(
            path.join(temp, 'linked-dir'),
            path.join(temp, 'dir'),
            relative: true);
        expect(
            canonicalize(path.join(temp, 'dir')),
            equals(path.join(temp, 'linked-dir')));
      }), completes);
    });
    test('resolves a single-level horizontally recursive symlink', () {
      expect(withCanonicalTempDir((temp) {
        var linkPath = path.join(temp, 'foo');
        createSymlink(linkPath, linkPath);
        expect(canonicalize(linkPath), equals(linkPath));
      }), completes);
    });
    test('resolves a multi-level horizontally recursive symlink', () {
      expect(withCanonicalTempDir((temp) {
        var fooPath = path.join(temp, 'foo');
        var barPath = path.join(temp, 'bar');
        var bazPath = path.join(temp, 'baz');
        createSymlink(barPath, fooPath);
        createSymlink(bazPath, barPath);
        createSymlink(fooPath, bazPath);
        expect(canonicalize(fooPath), equals(fooPath));
        expect(canonicalize(barPath), equals(barPath));
        expect(canonicalize(bazPath), equals(bazPath));
        createSymlink(fooPath, path.join(temp, 'outer'));
        expect(canonicalize(path.join(temp, 'outer')), equals(fooPath));
      }), completes);
    });
    test('resolves a broken symlink', () {
      expect(withCanonicalTempDir((temp) {
        createSymlink(path.join(temp, 'nonexistent'), path.join(temp, 'foo'));
        expect(
            canonicalize(path.join(temp, 'foo')),
            equals(path.join(temp, 'nonexistent')));
      }), completes);
    });
    test('resolves multiple nested symlinks', () {
      expect(withCanonicalTempDir((temp) {
        var dir1 = path.join(temp, 'dir1');
        var dir2 = path.join(temp, 'dir2');
        var subdir1 = path.join(dir1, 'subdir1');
        var subdir2 = path.join(dir2, 'subdir2');
        createDir(dir2);
        createDir(subdir2);
        createSymlink(dir2, dir1);
        createSymlink(subdir2, subdir1);
        expect(
            canonicalize(path.join(subdir1, 'file')),
            equals(path.join(subdir2, 'file')));
      }), completes);
    });
    test('resolves a nested vertical symlink', () {
      expect(withCanonicalTempDir((temp) {
        var dir1 = path.join(temp, 'dir1');
        var dir2 = path.join(temp, 'dir2');
        var subdir = path.join(dir1, 'subdir');
        createDir(dir1);
        createDir(dir2);
        createSymlink(dir2, subdir);
        expect(
            canonicalize(path.join(subdir, 'file')),
            equals(path.join(dir2, 'file')));
      }), completes);
    });
    test('resolves a vertically recursive symlink', () {
      expect(withCanonicalTempDir((temp) {
        var dir = path.join(temp, 'dir');
        var subdir = path.join(dir, 'subdir');
        createDir(dir);
        createSymlink(dir, subdir);
        expect(
            canonicalize(
                path.join(temp, 'dir', 'subdir', 'subdir', 'subdir', 'subdir', 'file')),
            equals(path.join(dir, 'file')));
      }), completes);
    });
    test(
        'resolves a symlink that links to a path that needs more resolving',
        () {
      expect(withCanonicalTempDir((temp) {
        var dir = path.join(temp, 'dir');
        var linkdir = path.join(temp, 'linkdir');
        var linkfile = path.join(dir, 'link');
        createDir(dir);
        createSymlink(dir, linkdir);
        createSymlink(path.join(linkdir, 'file'), linkfile);
        expect(canonicalize(linkfile), equals(path.join(dir, 'file')));
      }), completes);
    });
    test('resolves a pair of pathologically-recursive symlinks', () {
      expect(withCanonicalTempDir((temp) {
        var foo = path.join(temp, 'foo');
        var subfoo = path.join(foo, 'subfoo');
        var bar = path.join(temp, 'bar');
        var subbar = path.join(bar, 'subbar');
        createSymlink(subbar, foo);
        createSymlink(subfoo, bar);
        expect(
            canonicalize(subfoo),
            equals(path.join(subfoo, 'subbar', 'subfoo')));
      }), completes);
    });
  });
  testExistencePredicate(
      "entryExists",
      entryExists,
      forFile: true,
      forFileSymlink: true,
      forMultiLevelFileSymlink: true,
      forDirectory: true,
      forDirectorySymlink: true,
      forMultiLevelDirectorySymlink: true,
      forBrokenSymlink: true,
      forMultiLevelBrokenSymlink: true);
  testExistencePredicate(
      "linkExists",
      linkExists,
      forFile: false,
      forFileSymlink: true,
      forMultiLevelFileSymlink: true,
      forDirectory: false,
      forDirectorySymlink: true,
      forMultiLevelDirectorySymlink: true,
      forBrokenSymlink: true,
      forMultiLevelBrokenSymlink: true);
  testExistencePredicate(
      "fileExists",
      fileExists,
      forFile: true,
      forFileSymlink: true,
      forMultiLevelFileSymlink: true,
      forDirectory: false,
      forDirectorySymlink: false,
      forMultiLevelDirectorySymlink: false,
      forBrokenSymlink: false,
      forMultiLevelBrokenSymlink: false);
  testExistencePredicate(
      "dirExists",
      dirExists,
      forFile: false,
      forFileSymlink: false,
      forMultiLevelFileSymlink: false,
      forDirectory: true,
      forDirectorySymlink: true,
      forMultiLevelDirectorySymlink: true,
      forBrokenSymlink: false,
      forMultiLevelBrokenSymlink: false);
}
void testExistencePredicate(String name, bool predicate(String path),
    {bool forFile, bool forFileSymlink, bool forMultiLevelFileSymlink,
    bool forDirectory, bool forDirectorySymlink, bool forMultiLevelDirectorySymlink,
    bool forBrokenSymlink, bool forMultiLevelBrokenSymlink}) {
  group(name, () {
    test('returns $forFile for a file', () {
      expect(withTempDir((temp) {
        var file = path.join(temp, "test.txt");
        writeTextFile(file, "contents");
        expect(predicate(file), equals(forFile));
      }), completes);
    });
    test('returns $forDirectory for a directory', () {
      expect(withTempDir((temp) {
        var file = path.join(temp, "dir");
        createDir(file);
        expect(predicate(file), equals(forDirectory));
      }), completes);
    });
    test('returns $forDirectorySymlink for a symlink to a directory', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlinkPath = path.join(temp, "linkdir");
        createDir(targetPath);
        createSymlink(targetPath, symlinkPath);
        expect(predicate(symlinkPath), equals(forDirectorySymlink));
      }), completes);
    });
    test(
        'returns $forMultiLevelDirectorySymlink for a multi-level symlink to '
            'a directory',
        () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlink1Path = path.join(temp, "link1dir");
        var symlink2Path = path.join(temp, "link2dir");
        createDir(targetPath);
        createSymlink(targetPath, symlink1Path);
        createSymlink(symlink1Path, symlink2Path);
        expect(predicate(symlink2Path), equals(forMultiLevelDirectorySymlink));
      }), completes);
    });
    test('returns $forBrokenSymlink for a broken symlink', () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlinkPath = path.join(temp, "linkdir");
        createDir(targetPath);
        createSymlink(targetPath, symlinkPath);
        deleteEntry(targetPath);
        expect(predicate(symlinkPath), equals(forBrokenSymlink));
      }), completes);
    });
    test(
        'returns $forMultiLevelBrokenSymlink for a multi-level broken symlink',
        () {
      expect(withTempDir((temp) {
        var targetPath = path.join(temp, "dir");
        var symlink1Path = path.join(temp, "link1dir");
        var symlink2Path = path.join(temp, "link2dir");
        createDir(targetPath);
        createSymlink(targetPath, symlink1Path);
        createSymlink(symlink1Path, symlink2Path);
        deleteEntry(targetPath);
        expect(predicate(symlink2Path), equals(forMultiLevelBrokenSymlink));
      }), completes);
    });
    if (Platform.operatingSystem != 'windows') {
      test('returns $forFileSymlink for a symlink to a file', () {
        expect(withTempDir((temp) {
          var targetPath = path.join(temp, "test.txt");
          var symlinkPath = path.join(temp, "link.txt");
          writeTextFile(targetPath, "contents");
          createSymlink(targetPath, symlinkPath);
          expect(predicate(symlinkPath), equals(forFileSymlink));
        }), completes);
      });
      test(
          'returns $forMultiLevelFileSymlink for a multi-level symlink to a ' 'file',
          () {
        expect(withTempDir((temp) {
          var targetPath = path.join(temp, "test.txt");
          var symlink1Path = path.join(temp, "link1.txt");
          var symlink2Path = path.join(temp, "link2.txt");
          writeTextFile(targetPath, "contents");
          createSymlink(targetPath, symlink1Path);
          createSymlink(symlink1Path, symlink2Path);
          expect(predicate(symlink2Path), equals(forMultiLevelFileSymlink));
        }), completes);
      });
    }
  });
}
Future withCanonicalTempDir(Future fn(String path)) =>
    withTempDir((temp) => fn(canonicalize(temp)));
