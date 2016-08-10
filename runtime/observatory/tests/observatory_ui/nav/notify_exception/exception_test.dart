// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:async';
import 'package:unittest/unittest.dart';
import 'package:observatory/src/elements/nav/notify_exception.dart';

main() {
  NavNotifyExceptionElement.tag.ensureRegistration();

  final st = new StackTrace.fromString('stacktrace string');
  group('normal exception', () {
    final ex = new Exception('exception message');
    group('instantiation', () {
      test('no stacktrace', () {
        final e = new NavNotifyExceptionElement(ex);
        expect(e, isNotNull, reason: 'element correctly created');
        expect(e.exception, equals(ex));
        expect(e.stacktrace, isNull);
      });
      test('with stacktrace', () {
        final e = new NavNotifyExceptionElement(ex, stacktrace: st);
        expect(e, isNotNull, reason: 'element correctly created');
        expect(e.exception, equals(ex));
        expect(e.stacktrace, equals(st));
      });
    });
    group('elements', () {
      test('created after attachment (no stacktrace)', () async {
        final e = new NavNotifyExceptionElement(ex);
        document.body.append(e);
        await e.onRendered.first;
        expect(e.children.length, isNonZero, reason: 'has elements');
        expect(e.innerHtml.contains(ex.toString()), isTrue);
        expect(e.innerHtml.contains(st.toString()), isFalse);
        e.remove();
        await e.onRendered.first;
        expect(e.children.length, isZero, reason: 'is empty');
      });
      test('created after attachment (with stacktrace)', () async {
        final e = new NavNotifyExceptionElement(ex, stacktrace: st);
        document.body.append(e);
        await e.onRendered.first;
        expect(e.children.length, isNonZero, reason: 'has elements');
        expect(e.innerHtml.contains(ex.toString()), isTrue);
        expect(e.innerHtml.contains(st.toString()), isTrue);
        e.remove();
        await e.onRendered.first;
        expect(e.children.length, isZero, reason: 'is empty');
      });
    });
    group('events are fired', () {
      NavNotifyExceptionElement e;
      StreamSubscription sub;
      setUp(() async {
        e = new NavNotifyExceptionElement(ex, stacktrace: st);
        document.body.append(e);
        await e.onRendered.first;
      });
      tearDown(() {
        sub.cancel();
        e.remove();
      });
      test('navigation after connect', () async {
        sub = window.onPopState.listen(expectAsync((_) {}, count: 1,
          reason: 'event is fired'));
        e.querySelector('a').click();
      });
      test('onDelete events (DOM)', () async {
        sub = e.onDelete.listen(expectAsync((ExceptionDeleteEvent event) {
          expect(event, isNotNull, reason: 'event is passed');
          expect(event.exception, equals(ex), reason: 'exception is the same');
          expect(event.stacktrace, equals(st),
                                            reason: 'stacktrace is the same');
        }, count: 1, reason: 'event is fired'));
        e.querySelector('button').click();
      });
      test('onDelete events (code)', () async {
        sub = e.onDelete.listen(expectAsync((ExceptionDeleteEvent event) {
          expect(event, isNotNull, reason: 'event is passed');
          expect(event.exception, equals(ex), reason: 'exception is the same');
          expect(event.stacktrace, equals(st),
                                            reason: 'stacktrace is the same');
        }, count: 1, reason: 'event is fired'));
        e.delete();
      });
    });
  });
}
