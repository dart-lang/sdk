// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:dartdev/src/progress.dart';
import 'package:test/test.dart';

// Uses noSuchMethod because a standard test Fake/Mock for Stdout does not
// exist in pkg/dartdev, and this mirrors the pattern used in the SDK's own
// io_override_test.dart.
class FakeStdout implements Stdout {
  final StringBuffer buf = StringBuffer();

  @override
  final bool hasTerminal;

  @override
  final bool supportsAnsiEscapes;

  FakeStdout({this.hasTerminal = false, this.supportsAnsiEscapes = false});

  @override
  void write(Object? obj) => buf.write(obj);

  @override
  void writeln([Object? obj = '']) {
    buf.write(obj);
    buf.write('\n');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('progress', () {
    test('non-terminal path terminates line cleanly (#64463)', () async {
      final fakeStdout = FakeStdout(hasTerminal: false);

      await IOOverrides.runZoned(
        () async {
          await progress('Running build hooks', () async {});
        },
        stdout: () => fakeStdout,
      );

      final output = fakeStdout.buf.toString();
      expect(output, equals('Running build hooks...\n'));
      expect(
        output,
        isNot(contains('Running build hooks...Running build hooks')),
      );
    });

    test('non-terminal path sequential calls do not concatenate', () async {
      final fakeStdout = FakeStdout(hasTerminal: false);

      await IOOverrides.runZoned(
        () async {
          await progress('Running build hooks', () async {});
          await progress('Running link hooks', () async {});
        },
        stdout: () => fakeStdout,
      );

      final output = fakeStdout.buf.toString();
      expect(output, equals('Running build hooks...\nRunning link hooks...\n'));
    });

    test('stderr variant terminates line cleanly', () async {
      final fakeStderr = FakeStdout(hasTerminal: false);

      await IOOverrides.runZoned(
        () async {
          await progress(
            'Running build hooks',
            () async {},
            progressUpdatesOnStderr: true,
          );
        },
        stderr: () => fakeStderr,
      );

      final output = fakeStderr.buf.toString();
      expect(output, equals('Running build hooks...\n'));
    });
  });
}
