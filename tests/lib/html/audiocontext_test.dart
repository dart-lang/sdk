// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:html';
import 'dart:typed_data';
import 'dart:web_audio';

import 'package:async_helper/async_helper.dart';
import 'package:expect/minitest.dart';

main() {
  var isAudioContext =
      predicate((x) => x is AudioContext, 'is an AudioContext');

  group('supported', () {
    test('supported', () {
      expect(AudioContext.supported, true);
    });
  });

  group('functional', () {
    var context;
    if (AudioContext.supported) {
      context = new AudioContext();
    }

    test('constructorTest', () {
      if (AudioContext.supported) {
        expect(context, isNotNull);
        expect(context, isAudioContext);
      }
    });

    test('audioRenames', () {
      if (AudioContext.supported) {
        GainNode gainNode = context.createGain();
        gainNode.connectNode(context.destination);
        expect(gainNode is GainNode, isTrue);

        expect(context.createAnalyser() is AnalyserNode, isTrue);
        expect(context.createChannelMerger() is AudioNode, isTrue);
        expect(context.createChannelSplitter() is AudioNode, isTrue);
        expect(context.createOscillator() is OscillatorNode, isTrue);
        expect(context.createPanner() is PannerNode, isTrue);
        expect(
            context.createScriptProcessor(4096) is ScriptProcessorNode, isTrue);
      }
    });

    // TODO(9322): This test times out.
    /*
    test('onAudioProcess', () {
      if(AudioContext.supported) {
        var completer = new Completer<bool>();
        var context = new AudioContext();
        var scriptProcessor = context.createScriptProcessor(1024, 1, 2);
        scriptProcessor.connectNode(context.destination);
        bool alreadyCalled = false;
        scriptProcessor.onAudioProcess.listen((event) {
          if (!alreadyCalled) {
            completer.complete(true);
          }
          alreadyCalled = true;
        });
        return completer.future;
      }
    });
    */

    test('oscillatorTypes', () {
      if (AudioContext.supported) {
        OscillatorNode oscillator = context.createOscillator();
        oscillator.connectNode(context.destination);

        oscillator.type = 'sawtooth';
        expect(oscillator.type, equals('sawtooth'));

        oscillator.type = 'sine';
        expect(oscillator.type, equals('sine'));

        oscillator.type = 'square';
        expect(oscillator.type, equals('square'));

        oscillator.type = 'triangle';
        expect(oscillator.type, equals('triangle'));

        //expect(() => oscillator.type = 7, throws); Firefox does not throw, it
        //simply ignores this value.
        expect(oscillator.type, equals('triangle'));

        // Firefox does not throw when it receives invalid values; it simply
        // ignores them.
        //expect(() => oscillator.type = ['heap object not a string'], throws);
        expect(oscillator.type, equals('triangle'));
      }
    });

    asyncTest(() async {
      if (AudioContext.supported) {
        final audioSourceUrl = "/root_dart/tests/lib/html/small.mp3";

        Future<void> requestAudioDecode(
            {bool triggerDecodeError: false,
            DecodeSuccessCallback? successCallback,
            DecodeErrorCallback? errorCallback}) async {
          HttpRequest audioRequest = HttpRequest();
          audioRequest.open("GET", audioSourceUrl, async: true);
          audioRequest.responseType = "arraybuffer";
          var completer = new Completer<void>();
          audioRequest.onLoad.listen((_) {
            ByteBuffer audioData = audioRequest.response;
            if (triggerDecodeError) audioData = Uint8List.fromList([]).buffer;
            context
                .decodeAudioData(audioData, successCallback, errorCallback)
                .then((_) {
              completer.complete();
            }).catchError((e) {
              completer.completeError(e);
            });
          });
          audioRequest.send();
          return completer.future;
        }

        // Decode successfully without callback.
        await requestAudioDecode();

        // Decode successfully with callback. Use counter to make sure it's only
        // called once.
        var successCallbackCalled = 0;
        await requestAudioDecode(
            successCallback: (_) {
              successCallbackCalled += 1;
            },
            errorCallback: (_) {});
        expect(successCallbackCalled, 1);

        // Fail decode without callback.
        try {
          await requestAudioDecode(triggerDecodeError: true);
          fail('Expected decode failure.');
        } catch (_) {}

        // Fail decode with callback.
        var errorCallbackCalled = 0;
        try {
          await requestAudioDecode(
              triggerDecodeError: true,
              successCallback: (_) {},
              errorCallback: (_) {
                errorCallbackCalled += 1;
              });
          fail('Expected decode failure.');
        } catch (e) {
          // Safari may return a null error. Assuming Safari is version >= 14.1,
          // the Future should complete with a string error if the error
          // callback never gets called.
          if (errorCallbackCalled == 0) {
            expect(e is String, true);
          } else {
            expect(errorCallbackCalled, 1);
          }
        }
      }
    });
  });
}
