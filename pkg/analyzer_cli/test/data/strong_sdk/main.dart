import 'dart:js';

typedef dynamic Func(String x, String y);

Func bar(Func f) {
  return allowInterop(f);
}
