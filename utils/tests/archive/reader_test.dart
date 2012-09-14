// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('reader_test');

#import('dart:io');
#import('../../../pkg/unittest/unittest.dart');
#import('../../archive/archive.dart');

final String dataPath = "utils/tests/archive/data";

main() {
  test('reading a .tar.gz file', () {
    var asyncDone = expectAsync0(() {});

    var reader = new ArchiveReader();
    reader.format.tar = true;
    reader.filter.gzip = true;

    var future = reader.openFilename("$dataPath/test-archive.tar.gz")
      .transform((input) {
      var log = <String>[];
      input.onEntry = (entry) => guardAsync(() {
        log.add("Entry: ${entry.pathname}");
        var stream = new StringInputStream(entry.openInputStream());
        stream.onData = () => log.add("Contents: ${stream.read().trim()}");
        stream.onClosed = () => log.add("Closed: ${entry.pathname}");
      });
      input.onError = registerException;

      input.onClosed = () => guardAsync(() {
        expect(log, orderedEquals([
          "Entry: filename1",
          "Contents: contents 1",
          "Closed: filename1",

          "Entry: filename2",
          "Contents: contents 2",
          "Closed: filename2",

          "Entry: filename3",
          "Contents: contents 3",
          "Closed: filename3",
        ]));
      }, asyncDone);
    });

    expect(future, completes);
  });

  test('reading a .tar.gz file with readAll', () {
    var reader = new ArchiveReader();
    reader.format.tar = true;
    reader.filter.gzip = true;

    var future = reader.openFilename("$dataPath/test-archive.tar.gz")
      .chain((input) => input.readAll())
      .transform((entries) {
      entries = entries.map((entry) => [entry.pathname, entry.contents.trim()]);
      expect(entries[0], orderedEquals(["filename1", "contents 1"]));
      expect(entries[1], orderedEquals(["filename2", "contents 2"]));
      expect(entries[2], orderedEquals(["filename3", "contents 3"]));
    });

    expect(future, completes);
  });

  test('reading an in-memory .tar.gz', () {
    var asyncDone = expectAsync0(() {});

    var reader = new ArchiveReader();
    reader.format.tar = true;
    reader.filter.gzip = true;

    var future = new File("$dataPath/test-archive.tar.gz").readAsBytes()
      .chain((bytes) => reader.openData(bytes))
      .transform((input) {
      var log = <String>[];
      input.onEntry = (entry) => guardAsync(() {
        log.add("Entry: ${entry.pathname}");
        var stream = new StringInputStream(entry.openInputStream());
        stream.onData = () => log.add("Contents: ${stream.read().trim()}");
        stream.onClosed = () => log.add("Closed: ${entry.pathname}");
      });
      input.onError = registerException;

      input.onClosed = () => guardAsync(() {
        expect(log, orderedEquals([
          "Entry: filename1",
          "Contents: contents 1",
          "Closed: filename1",

          "Entry: filename2",
          "Contents: contents 2",
          "Closed: filename2",

          "Entry: filename3",
          "Contents: contents 3",
          "Closed: filename3",
        ]));
      }, asyncDone);
    });

    expect(future, completes);
  });

  test("closing entries before they're read", () {
    var asyncDone = expectAsync0(() {});

    var reader = new ArchiveReader();
    reader.format.tar = true;
    reader.filter.gzip = true;

    var future = reader.openFilename("$dataPath/test-archive.tar.gz")
      .transform((input) {
      var log = <String>[];
      input.onEntry = (entry) => guardAsync(() {
        log.add("Entry: ${entry.pathname}");
        var underlyingStream = entry.openInputStream();
        var stream = new StringInputStream(underlyingStream);
        stream.onData = () => log.add("Contents: ${stream.read().trim()}");
        stream.onClosed = () => log.add("Closed: ${entry.pathname}");
        underlyingStream.close();
      });
      input.onError = registerException;

      input.onClosed = () => guardAsync(() {
        expect(log, orderedEquals([
          "Entry: filename1",
          "Closed: filename1",

          "Entry: filename2",
          "Closed: filename2",

          "Entry: filename3",
          "Closed: filename3",
        ]));
      }, asyncDone);
    });

    expect(future, completes);
  });

  test("closing an archive stream before it's finished", () {
    var asyncDone = expectAsync0(() {});

    var reader = new ArchiveReader();
    reader.format.tar = true;
    reader.filter.gzip = true;

    var future = reader.openFilename("$dataPath/test-archive.tar.gz")
      .transform((input) {
      var count = 0;

      var log = <String>[];
      input.onEntry = (entry) => guardAsync(() {
        count += 1;

        log.add("Entry: ${entry.pathname}");
        var underlyingStream = entry.openInputStream();
        var stream = new StringInputStream(underlyingStream);
        stream.onData = () => log.add("Contents: ${stream.read().trim()}");
        stream.onClosed = () => log.add("Closed: ${entry.pathname}");

        if (count == 2) {
          input.close();
          expect(input.closed);
        }
      });
      input.onError = registerException;

      input.onClosed = () {
        expect(log, orderedEquals([
          "Entry: filename1",
          "Contents: contents 1",
          "Closed: filename1",

          "Entry: filename2",
          "Closed: filename2",
        ]));
        asyncDone();
      };
    });

    expect(future, completes);
  });

  test("opening a non-existent archive", () {
    var reader = new ArchiveReader();
    reader.format.tar = true;
    reader.filter.gzip = true;

    expect(reader.openFilename("$dataPath/non-existent.tar.gz"),
      throwsA((e) => e is ArchiveException));
  });
}

