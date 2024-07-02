// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/channel/channel.dart';

/// Return the stream of requests that is filtered to exclude requests for
/// which the client does not need actual responses.
///
/// If there is one completion request, and then another completion request,
/// then most probably the user continued typing, and there is no need to
/// compute results for the first request. But we will have to respond, an
/// empty response is enough.
///
/// Discarded requests are reported into [discardedRequests].
Stream<RequestOrResponse> debounceRequests(
  ServerCommunicationChannel channel,
  StreamController<RequestOrResponse> discardedRequests,
) {
  return _DebounceRequests(channel, discardedRequests).requests;
}

class _DebounceRequests {
  final ServerCommunicationChannel channel;
  final StreamController<RequestOrResponse> discardedRequests;
  late final Stream<RequestOrResponse> requests;

  _DebounceRequests(this.channel, this.discardedRequests) {
    var buffer = <RequestOrResponse>[];
    Timer? timer;

    requests = channel.requests.transform(
      StreamTransformer.fromHandlers(
        handleData: (requestOrResponse, sink) {
          buffer.add(requestOrResponse);
          // Accumulate requests for a short period of time.
          // When we were busy processing a request, the client could put
          // multiple requests into the event queue. So, when we look, we will
          // quickly get all of them. So, even 1 ms should be enough.
          timer ??= Timer(const Duration(milliseconds: 1), () {
            timer = null;
            var filtered = _filterCompletion(buffer);
            buffer = [];
            for (var request in filtered) {
              sink.add(request);
            }
          });
        },
      ),
    );
  }

  List<RequestOrResponse> _filterCompletion(List<RequestOrResponse> requests) {
    var reversed = <RequestOrResponse>[];
    var abortCompletionRequests = false;
    for (var requestOrResponse in requests.reversed) {
      if (requestOrResponse is Request) {
        if (requestOrResponse.method == ANALYSIS_REQUEST_UPDATE_CONTENT) {
          abortCompletionRequests = true;
        }
        if (requestOrResponse.method == COMPLETION_REQUEST_GET_SUGGESTIONS2) {
          if (abortCompletionRequests) {
            discardedRequests.add(requestOrResponse);
            var params = CompletionGetSuggestions2Params.fromRequest(
              requestOrResponse,
              // We can use a null converter here because we're not using the
              // path for anything.
              clientUriConverter: null,
            );
            var offset = params.offset;
            channel.sendResponse(
              CompletionGetSuggestions2Result(offset, 0, [], true).toResponse(
                requestOrResponse.id,
                // We can use a null converter here because we're not sending
                // any path.
                clientUriConverter: null,
              ),
            );
            continue;
          } else {
            abortCompletionRequests = true;
          }
        }
      }
      reversed.add(requestOrResponse);
    }
    return reversed.reversed.toList();
  }
}
