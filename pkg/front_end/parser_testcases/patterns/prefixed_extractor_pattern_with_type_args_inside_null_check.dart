import 'dart:async' as async;

test(dynamic x) {
  switch (x) {
    case async.Future<int>()?:
      break;
  }
}
