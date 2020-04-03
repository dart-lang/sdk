import 'others.dart';
import 'package:expect/expect.dart';

const Map<Key, String> m = {someKey: "PASSED"};

main() {
  Expect.equals(m[someKey], "PASSED");
}
