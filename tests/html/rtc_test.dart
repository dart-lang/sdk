 // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library RealTimeCommunicationTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'dart:html';

main() {
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(RtcPeerConnection.supported, true);
    });
  });

  group('functionality', () {
    // TODO(efortuna): More thorough testing of this API requires the user to
    // explicitly click "allow this site to access my camera and/or microphone."
    // or particularly allow that site to always have those permission on each
    // computer the test is run. Contact WebKit and/or Chrome people to
    // determine how they test with this issue.
    if (RtcPeerConnection.supported) {
      test('peer connection', () {
        var pc = new RtcPeerConnection(
            {'iceServers': [ {'url':'stun:foo.com:19302'}]});
        expect(pc is RtcPeerConnection, isTrue);
      });

      test('ice candidate', () {
        var candidate = new RtcIceCandidate({'sdpMLineIndex' : 1,
                                             'candidate' : 'hello'});
        expect(candidate is RtcIceCandidate, isTrue);
      });

      test('session description', () {
        var description = new RtcSessionDescription({'sdp': 'foo',
                                                     'type': 'offer'});
        expect(description is RtcSessionDescription, isTrue);
      });
    }
  });
}
