import 'dart:developer';

final eventKind = 'customEventKindTest';
final eventData = {'part1': 1, 'part2': '2'};
final customStreamId = 'a-custom-stream-id';

void main() {
  postEvent('customEventKindTest', eventData, stream: customStreamId);
}
