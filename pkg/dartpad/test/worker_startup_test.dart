// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:dartpad/dartpad.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

int get liveWorkers =>
    (web.window['dartpadWorkerTest']['live'] as JSNumber).toDartInt;

int get liveBlobUrls =>
    ((web.window['dartpadWorkerTest']['urls'] as JSObject)['size'] as JSNumber)
        .toDartInt;

int get initializingWorkers =>
    (web.window['dartpadWorkerTest']['initializing'] as JSNumber).toDartInt;

int get closedHandshakePorts =>
    (web.window['dartpadWorkerTest']['closedHandshakePorts'] as JSNumber)
        .toDartInt;

int get queuedSessions =>
    (web.window['dartpadWorkerTest']['queuedSessions'] as JSNumber).toDartInt;

web.Worker get lastWorker =>
    (web.window['dartpadWorkerTest']['workers'] as JSArray<web.Worker>)
        .toDart
        .last;

Matcher get throwsStartupCancellation => throwsA(
  isA<StateError>().having(
    (error) => error.message,
    'message',
    'DartPad worker startup was aborted.',
  ),
);

void evaluate(String script) {
  (web.window['eval'] as JSFunction).callAsFunction(web.window, script.toJS);
}

Future<void> waitForWorkerEvent(String event, bool Function() isReady) async {
  if (isReady()) return;
  final ready = Completer<void>();
  final onReady = ((web.Event _) {
    if (isReady() && !ready.isCompleted) ready.complete();
  }).toJS;
  web.window.addEventListener(event, onReady);
  try {
    await ready.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () => throw TestFailure('Worker fixture did not emit $event.'),
    );
  } finally {
    web.window.removeEventListener(event, onReady);
  }
}

Future<void> waitForInitialization(int count) => waitForWorkerEvent(
  'dartpad-worker-initializing',
  () => initializingWorkers >= count,
);

void main() {
  late DartPadSdk sdk;
  final pending = Uri.parse('https://test.invalid/pending');

  setUpAll(() {
    evaluate('''
      (() => {
        const state = window.dartpadWorkerTest = {
          live: 0, workers: [], urls: new Set(), initializing: 0,
          closedHandshakePorts: 0, beforeSession: null, failConstruction: false,
          captureSession: false, queuedSession: null, queuedSessions: 0,
          sessionWorker: null
        };
        const NativeWorker = window.Worker;
        const createUrl = URL.createObjectURL;
        const revokeUrl = URL.revokeObjectURL;
        window.Worker = class extends NativeWorker {
          constructor(...args) {
            if (state.failConstruction) {
              throw new Error('Fixture Worker construction failed');
            }
            super(...args);
            this.retired = false;
            state.live++;
            state.workers.push(this);
            this.addEventListener('message', event => {
              if (event.data?.action === 'initializing') {
                state.initializing++;
                window.dispatchEvent(new Event('dartpad-worker-initializing'));
              }
              if (event.data?.action === 'session') {
                if (state.captureSession) {
                  const port = event.ports[0];
                  const close = port.close;
                  port.close = () => {
                    state.closedHandshakePorts++;
                    close.call(port);
                  };
                  event.stopImmediatePropagation();
                  state.queuedSession = event;
                  state.sessionWorker = this;
                  state.queuedSessions++;
                  window.dispatchEvent(new Event('dartpad-worker-session'));
                  return;
                }
                state.beforeSession?.();
              }
            });
          }
          terminate() {
            if (!this.retired) { this.retired = true; state.live--; }
            super.terminate();
          }
        };
        URL.createObjectURL = blob => {
          const url = createUrl.call(URL, blob);
          state.urls.add(url);
          return url;
        };
        URL.revokeObjectURL = url => {
          state.urls.delete(url);
          revokeUrl.call(URL, url);
        };
        state.restore = () => {
          window.Worker = NativeWorker;
          URL.createObjectURL = createUrl;
          URL.revokeObjectURL = revokeUrl;
        };
      })();
    ''');
  });

  setUp(() {
    sdk = DartPadSdk(
      assetBaseUrl: Uri.base.resolve('fixtures/worker_startup/'),
    );
    evaluate('''
      dartpadWorkerTest.initializing = 0;
      dartpadWorkerTest.closedHandshakePorts = 0;
      dartpadWorkerTest.beforeSession = null;
      dartpadWorkerTest.failConstruction = false;
      dartpadWorkerTest.captureSession = false;
      dartpadWorkerTest.queuedSessions = 0;
    ''');
  });

  tearDown(() {
    // Retire blocked fixture workers even when an assertion fails.
    evaluate('''
      dartpadWorkerTest.queuedSession?.ports.forEach(port => port.close());
      dartpadWorkerTest.queuedSession = null;
      dartpadWorkerTest.sessionWorker = null;
      dartpadWorkerTest.workers.forEach(worker => worker.terminate());
      dartpadWorkerTest.workers = [];
      [...dartpadWorkerTest.urls].forEach(url => URL.revokeObjectURL(url));
    ''');
  });

  tearDownAll(() => evaluate('dartpadWorkerTest.restore();'));

  test(
    'an already completed trigger aborts startup and releases resources',
    () async {
      final abort = Completer<void>()..complete();
      await expectLater(
        sdk.dedicatedWorker(abortTrigger: abort.future),
        throwsStartupCancellation,
      );
      expect(liveWorkers, 0);
      expect(liveBlobUrls, 0);
    },
  );

  test('an error completion also requests cancellation', () async {
    final abort = Completer<void>();
    final started = sdk.dedicatedWorker(
      abortTrigger: abort.future,
      pubHostedUrl: pending,
    );
    started.ignore();
    await waitForInitialization(1);

    abort.completeError(const FormatException('Caller failed during startup'));

    await expectLater(started, throwsStartupCancellation);
    expect(liveWorkers, 0);
    expect(liveBlobUrls, 0);
  });

  test(
    'abort terminates a pending worker without its session handshake',
    () async {
      final abort = Completer<void>();
      final started = sdk.dedicatedWorker(
        abortTrigger: abort.future,
        pubHostedUrl: pending,
      );
      started.ignore();
      await waitForInitialization(1);
      expect(liveWorkers, 1);
      expect(liveBlobUrls, 1);

      abort.complete();

      // Completing the trigger schedules cancellation without a handshake.
      await expectLater(started, throwsStartupCancellation);
      expect(liveWorkers, 0);
      expect(liveBlobUrls, 0);
    },
  );

  test('aborting one start leaves another pending start alive', () async {
    final firstAbort = Completer<void>();
    final secondAbort = Completer<void>();
    final first = sdk.dedicatedWorker(
      abortTrigger: firstAbort.future,
      pubHostedUrl: pending,
    );
    final second = sdk.dedicatedWorker(
      abortTrigger: secondAbort.future,
      pubHostedUrl: pending,
    );
    first.ignore();
    second.ignore();
    await waitForInitialization(2);

    firstAbort.complete();
    await expectLater(first, throwsStartupCancellation);
    expect(liveWorkers, 1);
    expect(liveBlobUrls, 1);

    secondAbort.complete();
    await expectLater(second, throwsStartupCancellation);
    expect(liveWorkers, 0);
    expect(liveBlobUrls, 0);
  });

  test(
    'worker initialization errors release the worker and Blob URL',
    () async {
      await expectLater(
        sdk.dedicatedWorker(
          pubHostedUrl: Uri.parse('https://test.invalid/error'),
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Fixture initialization failed'),
          ),
        ),
      );
      expect(liveWorkers, 0);
      expect(liveBlobUrls, 0);
    },
  );

  test(
    'native worker load failure settles startup and releases resources',
    () async {
      final missing = DartPadSdk(
        assetBaseUrl: Uri.base.resolve('fixtures/missing_worker/'),
      );
      await expectLater(
        missing.dedicatedWorker(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed loading DartPad worker.',
          ),
        ),
      );
      expect(liveWorkers, 0);
      expect(liveBlobUrls, 0);
    },
  );

  test('worker construction failure releases the Blob URL', () async {
    evaluate('dartpadWorkerTest.failConstruction = true;');
    await expectLater(
      sdk.dedicatedWorker(),
      throwsA(
        predicate<Object>(
          (error) =>
              error.toString().contains('Fixture Worker construction failed'),
        ),
      ),
    );
    expect(liveWorkers, 0);
    expect(liveBlobUrls, 0);
  });

  for (final beforeSession in [true, false]) {
    test(
      'abort at the handshake closes its port, beforeSession=$beforeSession',
      () async {
        // Capture the real transferred port, then dispatch the handshake from
        // Dart. Native callbacks can otherwise drain microtasks between listeners.
        evaluate('dartpadWorkerTest.captureSession = true;');
        final abort = Completer<void>.sync();
        if (beforeSession) {
          web.window['dartpadWorkerTest']['beforeSession'] =
              (() => abort.complete()).toJS;
        }
        final started = sdk.dedicatedWorker(abortTrigger: abort.future);
        started.ignore();
        await waitForWorkerEvent(
          'dartpad-worker-session',
          () => queuedSessions == 1,
        );
        if (!beforeSession) {
          final worker = lastWorker;
          final onSession = ((web.MessageEvent event) {
            final data = event.data as JSObject?;
            if ((data?['action'] as JSString?)?.toDart == 'session')
              abort.complete();
          }).toJS;
          // Register after dedicatedWorker() installed its message handler.
          worker.addEventListener('message', onSession);
          addTearDown(() => worker.removeEventListener('message', onSession));
        }

        evaluate('''
        const state = dartpadWorkerTest;
        const event = state.queuedSession;
        state.queuedSession = null;
        state.captureSession = false;
        state.sessionWorker.dispatchEvent(new MessageEvent('message', {
          data: event.data, ports: event.ports
        }));
      ''');

        await expectLater(started, throwsStartupCancellation);

        expect(abort.isCompleted, isTrue);
        expect(closedHandshakePorts, 1);
        expect(liveWorkers, 0);
        expect(liveBlobUrls, 0);
      },
    );
  }

  for (final completeWithError in [false, true]) {
    test('after the handshake the client owns closing, '
        'trigger completes with error=$completeWithError', () async {
      final abort = Completer<void>();
      final client = await sdk.dedicatedWorker(abortTrigger: abort.future);
      addTearDown(client.close);

      if (completeWithError) {
        abort.completeError(StateError('Caller failed after startup'));
      } else {
        abort.complete();
      }
      await pumpEventQueue();
      expect(liveWorkers, 1);
      expect(liveBlobUrls, 1);

      await client.close();
      expect(liveWorkers, 0);
      expect(liveBlobUrls, 0);
    });
  }
}
