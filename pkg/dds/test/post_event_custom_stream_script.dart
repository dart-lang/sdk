// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

final eventKind = 'customEventKindTest';
final eventData = {'part1': 1, 'part2': '2'};
final customStreamId = 'a-custom-stream-id';

void main() {
  postEvent('customEventKindTest', eventData, stream: customStreamId);
  postEvent('customEventKindTest', eventData, stream: 'Extension');
}
