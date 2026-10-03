// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/file_system/overlay_file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/dart/analysis/file_content_cache.dart';
import 'package:analyzer/src/file_system/timing_resource_provider.dart';
import 'package:analyzer_testing/resource_provider_mixin.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TimingResourceProviderTest);
  });
}

@reflectiveTest
class TimingResourceProviderTest with ResourceProviderMixin {
  late TimingResourceProvider provider;

  void setUp() {
    provider = TimingResourceProvider(resourceProvider);
  }

  void test_accumulateAndSeparateOperations() {
    var file = newFile('/test.dart', 'content');
    var timedFile = provider.getFile(file.path);
    expect(provider.timings, isEmpty);

    expect(timedFile.readAsStringSync(), 'content');
    var firstElapsed = provider.timings['File.readAsStringSync']!.elapsed;
    expect(timedFile.readAsStringSync(), 'content');
    expect(timedFile.exists, isTrue);
    expect(timedFile.lengthSync, 7);
    expect(timedFile.modificationStamp, file.modificationStamp);

    expect(provider.timings['File.readAsStringSync']!.count, 2);
    expect(
      provider.timings['File.readAsStringSync']!.elapsed,
      greaterThanOrEqualTo(firstElapsed),
    );
    expect(provider.timings['File.exists']!.count, 1);
    expect(provider.timings['File.lengthSync']!.count, 1);
    expect(provider.timings['File.modificationStamp']!.count, 1);
  }

  void test_byteReadsAndFailures() {
    var file = newFile('/test.dart', 'é');
    var timedFile = provider.getFile(file.path);
    expect(timedFile.readAsBytesSync(), [0xc3, 0xa9]);
    expect(timedFile.readAsBytesSync(), [0xc3, 0xa9]);
    var missingFile = provider.getFile(convertPath('/missing.dart'));
    expect(missingFile.readAsBytesSync, throwsA(isA<FileSystemException>()));

    var timing = provider.timings['File.readAsBytesSync']!;
    expect(timing.count, 3);
    expect(timing.bytesRead, 4);
    expect(missingFile.readAsStringSync, throwsA(isA<FileSystemException>()));
    expect(provider.timings['File.readAsStringSync']!.count, 1);
  }

  void test_contentCacheDoesNotCountAsIo() {
    var file = newFile('/test.dart', 'content');
    var cache = FileContentCache(provider);
    expect(cache.get(file.path).content, 'content');
    expect(cache.get(file.path).content, 'content');
    expect(provider.timings['File.readAsBytesSync']!.count, 1);
    expect(provider.timings['File.readAsBytesSync']!.bytesRead, 7);

    file.writeAsStringSync('updated');
    expect(cache.get(file.path).content, 'content');
    cache.invalidate(file.path);
    expect(cache.get(file.path).content, 'updated');
    expect(provider.timings['File.readAsBytesSync']!.count, 2);
    expect(provider.timings['File.readAsBytesSync']!.bytesRead, 14);
  }

  void test_copyDoesNotDoubleCount() {
    var file = newFile('/source/test.dart', 'content');
    var destination = provider.getFolder(convertPath('/destination'));
    var copied = provider.getFile(file.path).copyTo(destination);

    expect(resourceProvider.getFile(copied.path).readAsStringSync(), 'content');
    expect(provider.timings.keys, ['File.copyTo']);
    expect(provider.timings['File.copyTo']!.count, 1);
    expect(copied.provider, same(provider));
    copied.readAsStringSync();
    expect(provider.timings['File.readAsStringSync']!.count, 1);

    var folderCopy = provider.getFolder(file.parent.path).copyTo(destination);
    expect(folderCopy.provider, same(provider));
    expect(provider.timings['Folder.copyTo']!.count, 1);
    expect(provider.timings['File.copyTo']!.count, 1);
  }

  void test_navigationKeepsWrapping() {
    var file = newFile('/folder/test.dart', 'content');
    var timedFile = provider.getResource(file.path) as File;
    var folder = provider.getResource(file.parent.path) as Folder;
    expect(timedFile.provider, same(provider));
    expect(timedFile.parent.provider, same(provider));
    expect(folder.parent.provider, same(provider));
    expect(provider.timings['ResourceProvider.getResource']!.count, 2);

    var child = folder.getChild('test.dart') as File;
    expect(child.provider, same(provider));
    expect(child.readAsStringSync(), 'content');
    expect(provider.timings['Folder.getChild']!.count, 1);
    var children = folder.getChildren();
    expect(children, hasLength(1));
    expect(children.single.provider, same(provider));
    expect((children.single as File).readAsStringSync(), 'content');
    expect(provider.timings['Folder.getChildren']!.count, 1);

    expect(folder.getFile('test.dart'), timedFile);
    expect(folder.getFolder('subfolder').provider, same(provider));
    expect(timedFile.resolveSymbolicLinksSync().provider, same(provider));
    expect(provider.timings['File.resolveSymbolicLinksSync']!.count, 1);
    expect(folder.resolveSymbolicLinksSync().provider, same(provider));
    expect(provider.timings['Folder.resolveSymbolicLinksSync']!.count, 1);
  }

  void test_overlayDoesNotCountAsIo() {
    var file = newFile('/test.dart', 'disk');
    var overlay = OverlayResourceProvider(provider);
    overlay.setOverlay(file.path, content: 'editor', modificationStamp: 42);
    var overlayFile = overlay.getFile(file.path);

    expect(overlayFile.readAsStringSync(), 'editor');
    expect(overlayFile.readAsBytesSync(), [101, 100, 105, 116, 111, 114]);
    expect(overlayFile.exists, isTrue);
    expect(overlayFile.modificationStamp, 42);
    expect(provider.timings, isEmpty);

    overlay.removeOverlay(file.path);
    expect(overlayFile.readAsStringSync(), 'disk');
    expect(provider.timings['File.readAsStringSync']!.count, 1);
  }

  void test_pathOperationsDoNotCountAsIo() {
    var file = newFile('/folder/test.dart', 'content');
    var timedFile = provider.getFile(file.path);
    var folder = timedFile.parent;
    expect(provider.pathContext, same(resourceProvider.pathContext));
    expect(timedFile.path, file.path);
    expect(timedFile.shortName, file.shortName);
    expect(timedFile.toUri(), file.toUri());
    expect(timedFile.isOrContains(file.path), isTrue);
    expect(folder.contains(file.path), isTrue);
    expect(folder.isOrContains(file.path), isTrue);
    expect(folder.canonicalizePath('test.dart'), file.path);
    expect(folder.isRoot, isFalse);
    expect(timedFile, provider.getFile(file.path));
    expect(timedFile.hashCode, provider.getFile(file.path).hashCode);
    expect(timedFile, isNot(folder));
    expect(provider.timings, isEmpty);
  }

  void test_physicalProviderPreservesTextDecoding() {
    var directory = io.Directory.systemTemp.createTempSync('timing-provider');
    try {
      var base = PhysicalResourceProvider(stateLocation: directory.path);
      var timedProvider = TimingResourceProvider(base);
      var filePath = base.pathContext.join(directory.path, 'test.dart');
      var file = base.getFile(filePath);
      // A UTF-8 BOM followed by a non-ASCII character.
      file.writeAsBytesSync([0xef, 0xbb, 0xbf, 0xc3, 0xa9]);
      var timedFile = timedProvider.getFile(filePath);
      expect(timedFile.readAsStringSync(), file.readAsStringSync());
      expect(timedFile.readAsBytesSync(), [0xef, 0xbb, 0xbf, 0xc3, 0xa9]);
      expect(timedProvider.timings['File.readAsBytesSync']!.bytesRead, 5);

      file.writeAsBytesSync([0xff]);
      var throwsDecodingError = throwsA(
        isA<FileSystemException>()
            .having((error) => error.path, 'path', filePath)
            .having(
              (error) => error.message,
              'message',
              contains('Failed to decode'),
            ),
      );
      expect(file.readAsStringSync, throwsDecodingError);
      expect(timedFile.readAsStringSync, throwsDecodingError);
      expect(timedProvider.timings['File.readAsStringSync']!.count, 2);
    } finally {
      directory.deleteSync(recursive: true);
    }
  }

  void test_recordsElapsedTimeOnFailure() {
    var slowProvider = TimingResourceProvider(_SlowResourceProvider());
    expect(
      () => slowProvider.getResource(convertPath('/test.dart')),
      throwsA(isA<FileSystemException>()),
    );
    var timing = slowProvider.timings['ResourceProvider.getResource']!;
    expect(timing.count, 1);
    expect(timing.elapsed, greaterThanOrEqualTo(Duration(milliseconds: 2)));
  }

  void test_stateLocation() {
    var state = provider.getStateLocation('plugin');
    expect(state, isNotNull);
    expect(state!.provider, same(provider));
    expect(provider.timings['ResourceProvider.getStateLocation']!.count, 1);
    expect(state.exists, isTrue);
    expect(provider.timings['Folder.exists']!.count, 1);
  }

  void test_stateLocationUnavailable() {
    var timedProvider = TimingResourceProvider(_NoStateResourceProvider());
    expect(timedProvider.getStateLocation('plugin'), isNull);
    expect(
      timedProvider.timings['ResourceProvider.getStateLocation']!.count,
      1,
    );
  }

  Future<void> test_watchPreservesEvents() async {
    var file = newFile('/test.dart', 'content');
    var watcher = provider.getFile(file.path).watch();
    var events = <String>[];
    var subscription = watcher.changes.listen(
      (event) => events.add(event.path),
    );
    try {
      await watcher.ready;
      file.writeAsStringSync('changed');
      await pumpEventQueue();
      expect(events, [file.path]);
      expect(provider.timings['File.watch']!.count, 1);
    } finally {
      await subscription.cancel();
    }
  }

  void test_writesRenameDeleteAndLinks() {
    var file = newFile('/folder/test.dart', 'content');
    var timedFile = provider.getFile(file.path);
    timedFile.writeAsStringSync('updated');
    timedFile.writeAsBytesSync([65, 66]);
    expect(file.readAsStringSync(), 'AB');
    expect(provider.timings['File.writeAsStringSync']!.count, 1);
    expect(provider.timings['File.writeAsBytesSync']!.count, 1);

    var renamed = timedFile.renameSync(convertPath('/folder/renamed.dart'));
    expect(renamed.provider, same(provider));
    expect(renamed.readAsStringSync(), 'AB');
    expect(provider.timings['File.renameSync']!.count, 1);
    renamed.delete();
    expect(provider.timings['File.delete']!.count, 1);

    var folder = provider.getFolder(convertPath('/newFolder'));
    folder.create();
    expect(folder.exists, isTrue);
    folder.delete();
    expect(provider.timings['Folder.create']!.count, 1);
    expect(provider.timings['Folder.exists']!.count, 1);
    expect(provider.timings['Folder.delete']!.count, 1);

    var link = provider.getLink(convertPath('/link'));
    link.create(file.parent.path);
    expect(link.exists, isTrue);
    expect(provider.timings['Link.create']!.count, 1);
    expect(provider.timings['Link.exists']!.count, 1);
  }
}

class _NoStateResourceProvider implements ResourceProvider {
  @override
  Folder? getStateLocation(String pluginId) => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SlowResourceProvider extends MemoryResourceProvider {
  @override
  Resource getResource(String path) {
    io.sleep(Duration(milliseconds: 2));
    throw FileSystemException(path, 'Failed after waiting');
  }
}
