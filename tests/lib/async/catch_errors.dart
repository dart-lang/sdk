library catch_errors;

import 'dart:async';

Stream catchErrors(void body()) {
  StreamController controller;

  bool onError(e) {
    controller.add(e);
    return true;
  }

  void onDone() {
    controller.close();
  }

  void onListen() {
    runZonedExperimental(body, onError: onError, onDone: onDone);
  }

  controller = new StreamController(onListen: onListen);
  return controller.stream;
}

Future waitForCompletion(void body()) {
  Completer completer = new Completer.sync();
  runZonedExperimental(body, onDone: completer.complete);
  return completer.future;
}
