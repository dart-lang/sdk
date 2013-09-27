library catch_errors;

import 'dart:async';

Stream catchErrors(void body()) {
  StreamController controller;

  bool onError(e) {
    controller.add(e);
    return true;
  }

  void onListen() {
    runZoned(body, onError: onError);
  }

  controller = new StreamController(onListen: onListen);
  return controller.stream;
}
