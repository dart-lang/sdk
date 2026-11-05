// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/src/utilities/fix_protocol.dart';
import 'package:test/test.dart';

void main() {
  group('fixProtocol', () {
    group('when window location protocol is https:', () {
      const windowProtocol = 'https:';

      test('upgrades http to https for non-localhost hosts', () {
        expect(
          fixProtocol(
            'http://example.com/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'https://example.com/foo/\$dwdsSseHandler',
        );
      });

      test('upgrades ws to wss for non-localhost hosts', () {
        expect(
          fixProtocol(
            'ws://example.com/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'wss://example.com/foo/\$dwdsSseHandler',
        );
      });

      test('does not modify http on localhost', () {
        expect(
          fixProtocol(
            'http://localhost:8080/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'http://localhost:8080/foo/\$dwdsSseHandler',
        );
      });

      test('does not modify ws on localhost', () {
        expect(
          fixProtocol(
            'ws://localhost:8080/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'ws://localhost:8080/foo/\$dwdsSseHandler',
        );
      });

      test('leaves https unchanged for non-localhost hosts', () {
        expect(
          fixProtocol(
            'https://example.com/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'https://example.com/foo/\$dwdsSseHandler',
        );
      });

      test('leaves wss unchanged for non-localhost hosts', () {
        expect(
          fixProtocol(
            'wss://example.com/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'wss://example.com/foo/\$dwdsSseHandler',
        );
      });
    });

    group('when window location protocol is http:', () {
      const windowProtocol = 'http:';

      test('does not modify http for non-localhost hosts', () {
        expect(
          fixProtocol(
            'http://example.com/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'http://example.com/foo/\$dwdsSseHandler',
        );
      });

      test('does not modify ws for non-localhost hosts', () {
        expect(
          fixProtocol(
            'ws://example.com/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'ws://example.com/foo/\$dwdsSseHandler',
        );
      });

      test('does not modify http on localhost', () {
        expect(
          fixProtocol(
            'http://localhost:8080/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'http://localhost:8080/foo/\$dwdsSseHandler',
        );
      });

      test('does not modify ws on localhost', () {
        expect(
          fixProtocol(
            'ws://localhost:8080/foo/\$dwdsSseHandler',
            windowLocationProtocol: windowProtocol,
          ),
          'ws://localhost:8080/foo/\$dwdsSseHandler',
        );
      });
    });

    group('when window location protocol is not https: (e.g. file:)', () {
      test('does not modify urls', () {
        expect(
          fixProtocol(
            'http://example.com/foo',
            windowLocationProtocol: 'file:',
          ),
          'http://example.com/foo',
        );
        expect(
          fixProtocol('ws://example.com/foo', windowLocationProtocol: 'file:'),
          'ws://example.com/foo',
        );
      });
    });
  });
}
