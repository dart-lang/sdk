This package exposes a `StringScanner` type that makes it easy to parse a string
using a series of `Pattern`s. For example:

```dart
import 'dart:math';

import 'package:string_scanner/string_scanner.dart';

num parseNumber(String source) {
  // Scan a number ("1", "1.5", "-3").
  var scanner = new StringScanner(source);

  // [Scanner.scan] tries to consume a [Pattern] and returns whether or not it
  // succeeded. It will move the scan pointer past the end of the pattern.
  var negative = scanner.scan("-");

  // [Scanner.expect] consumes a [Pattern] and throws a [FormatError] if it
  // fails. Like [Scanner.scan], it will move the scan pointer forward.
  scanner.expect(new RegExp(r"\d+"));

  // [Scanner.lastMatch] holds the [MatchData] for the most recent call to
  // [Scanner.scan], [Scanner.expect], or [Scanner.matches].
  var number = int.parse(scanner.lastMatch[0]);

  if (scanner.scan(".")) {
    scanner.expect(new RegExp(r"\d+"));
    var decimal = scanner.lastMatch[0];
    number += int.parse(decimal) / math.pow(10, decimal.length);
  }

  // [Scanner.expectDone] will throw a [FormatError] if there's any input that
  // hasn't yet been consumed.
  scanner.expectDone();

  return (negative ? -1 : 1) * number;
}
```
