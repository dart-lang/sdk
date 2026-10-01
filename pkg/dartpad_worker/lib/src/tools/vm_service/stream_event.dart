// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dart_runtime_service/dart_runtime_service.dart';
import 'package:vm_service/vm_service.dart';

/// Creates a [StreamEvent] wrapping a `package:vm_service` [Event] for
/// [DartRuntimeService.sendEvent].
StreamEvent createStreamEvent({
  required String streamId,
  required Event event,
}) => _VmStreamEvent(streamId: streamId, event: event);

final class _VmStreamEvent extends StreamEvent {
  final Event event;

  _VmStreamEvent({required super.streamId, required this.event})
    : super(kind: event.kind ?? '');

  @override
  Map<String, Object?> toJson() => {
    StreamEvent.kStreamId: streamId,
    StreamEvent.kEvent: event.toJson(),
  };
}
