import 'dart:async';
import 'package:expect/minitest.dart';

main(message, replyTo) {
  var command = message.first;
  expect(command, 'START');
  new Timer(const Duration(milliseconds: 10), () {
    replyTo.send('DONE');
  });
}
