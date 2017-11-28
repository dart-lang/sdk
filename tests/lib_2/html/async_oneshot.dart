import 'dart:async';
import 'package:unittest/unittest.dart';

main(message, replyTo) {
  var command = message.first;
  expect(command, 'START');
  new Timer(const Duration(milliseconds: 10), () {
    replyTo.send('DONE');
  });
}
