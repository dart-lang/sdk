// Method to test: function(test)
import 'package:expect/expect.dart';

// This example illustrates a case we wish to do better in terms of inlining and
// code generation.
//
// Naively this function would be compiled without inlining Wrapper.[],
// JSArray.[] and Wrapper.[]= because:
// JSArray.[] is too big (14 nodes)
// Wrapper.[] is too big if we force inlining of JSArray (15 nodes)
// Wrapper.[]= is even bigger (46 nodes)
//
// We now do specialization of [] and []= by adding guards and injecting builtin
// operators. This made it possible to inline []. We still don't see []= inlined
// yet, that might require that we improve the inlining counting heuristics a
// bit.
@NoInline()
test(data, x) {
  data[x + 1] = data[x];
}

main() {
  var wrapper = new Wrapper();
  wrapper[33] = wrapper[1]; // make Wrapper.[]= and [] used more than once.
  print(test(new Wrapper(), int.parse('2')));
}

class Wrapper {
  final List arr = <bool>[true, false, false, true];
  operator[](int i) => this.arr[i];
  operator[]=(int i, v) {
    if (i > arr.length - 1) arr.length = i + 1;
    return arr[i] = v;
  }
}
