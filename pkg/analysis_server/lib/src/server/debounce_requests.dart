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
/// If there is a request (for example for completion), and then another request
/// of the same kind, then most probably the user continued typing, and there is
/// no need to compute results for the first request. But we will have to
/// respond, an empty response is enough.
///
/// Debounced requests include:
///
/// * `getAssists`
/// * `getCompletions`
/// * `getFixes`
/// * `getHover`
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
            var filtered = _filterRequests(buffer);
            buffer = [];
            for (var request in filtered) {
              sink.add(request);
            }
          });
        },
      ),
    );
  }

  List<RequestOrResponse> _filterRequests(List<RequestOrResponse> requests) {
    var reversed = <RequestOrResponse>[];
    var abortCompletionRequests = false;
    var abortHoverRequests = false;
    var abortAssistsRequests = false;
    var abortFixesRequests = false;
    for (var requestOrResponse in requests.reversed) {
      if (requestOrResponse is Request) {
        if (requestOrResponse.method == analysisRequestUpdateContent) {
          abortCompletionRequests = true;
        } else if (requestOrResponse.method ==
            completionRequestGetSuggestions2) {
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
        } else if (requestOrResponse.method == analysisRequestGetHover) {
          if (abortHoverRequests) {
            discardedRequests.add(requestOrResponse);
            channel.sendResponse(
              AnalysisGetHoverResult([]).toResponse(
                requestOrResponse.id,
                // We can use a null converter here because we're not sending
                // any path.
                clientUriConverter: null,
              ),
            );
            continue;
          } else {
            abortHoverRequests = true;
          }
        } else if (requestOrResponse.method == editRequestGetAssists) {
          if (abortAssistsRequests) {
            discardedRequests.add(requestOrResponse);
            channel.sendResponse(
              EditGetAssistsResult([]).toResponse(
                requestOrResponse.id,
                // We can use a null converter here because we're not sending
                // any path.
                clientUriConverter: null,
              ),
            );
            continue;
          } else {
            abortAssistsRequests = true;
          }
        } else if (requestOrResponse.method == editRequestGetFixes) {
          if (abortFixesRequests) {
            discardedRequests.add(requestOrResponse);
            channel.sendResponse(
              EditGetFixesResult([]).toResponse(
                requestOrResponse.id,
                // We can use a null converter here because we're not sending
                // any path.
                clientUriConverter: null,
              ),
            );
            continue;
          } else {
            abortFixesRequests = true;
          }
        }
      }
      reversed.add(requestOrResponse);
    }
    return reversed.reversed.toList();
  }
}
