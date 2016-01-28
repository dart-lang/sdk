// Method to test: function(test)
import 'package:expect/expect.dart';

// This example illustrates a case we wish to do better in terms of inlining and
// code generation.
//
// Today this function is compiled without inlining Wrapper.[], JSArray.[] and
// Wrapper.[]= because:
// JSArray.[] is too big (14 nodes)
// Wrapper.[] is too big if we force inlining of JSArray (15 nodes)
// Wrapper.[]= is even bigger (46 nodes)
//
// See #25478 for ideas on how to make this better.
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
