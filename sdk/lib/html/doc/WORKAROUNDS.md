Dart web platform libraries e.g. `dart:html` is partially hand-written and
partially generated, with the code generation using the Chrome IDL as the source
of truth for many browser interfaces. This introduces a dependency on the
version of the IDL and doesn’t always match up with other browser interfaces.

Currently, we do not intend on updating our scripts to use a newer version of
the IDL, so APIs and classes in these libraries may be inaccurate.

In order to work around this, we ask users to leverage JS interop. Longer term,
we intend to revamp our web library offerings to be more robust and reliable.

The following are workarounds to common issues you might see with using the web
platform libraries.

## Common Issues

### Missing/broken APIs

As mentioned above, there exists stale interfaces. While some of these may be
fixed in the source code, many might not.

In order to work around this, you can use the annotation `@staticInterop` from
`package:js`.

Let’s look at an example. `FileReader` is a `dart:html` interface that is
missing the API `readAsBinaryString` ([#42834][]). We can work around this by
doing something like the following:

```dart
@JS()
library workarounds;

import 'dart:html';

import 'package:async_helper/async_minitest.dart';
import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
@staticInterop
class JSFileReader {}

extension JSFileReaderExtension on JSFileReader {
  external void readAsBinaryString(Blob blob);
}

void main() async {
  var reader = new FileReader();
  reader.onLoad.listen(expectAsync((event) {
    String result = reader.result as String;
    Expect.equals(result, '00000000');
  }));
  var jsReader = reader as JSFileReader;
  jsReader.readAsBinaryString(new Blob(['00000000']));
}
```

Alternatively, you can directly use the `js_util` library, using the methods
`getProperty`, `setProperty`, `callMethod`, and `callConstructor`.

```dart
import 'dart:html';
import 'dart:js_util' as js_util;

import 'package:async_helper/async_minitest.dart';
import 'package:expect/expect.dart';

void main() async {
  var reader = new FileReader();
  reader.onLoad.listen(expectAsync((event) {
    String result = reader.result as String;
    Expect.equals(result, '00000000');
  }));
  js_util.callMethod(reader, 'readAsBinaryString', [new Blob(['00000000'])]);
  // We can manipulate properties as well.
  js_util.setProperty(reader, 'foo', 'bar'); // reader.foo is now ‘bar’
  Expect.equals(js_util.getProperty(reader, 'foo'), 'bar');
}
```

In the case where the API is missing a constructor, we can define a constructor
within a `@staticInterop` class. Note that constructors, `external` or
otherwise, are disallowed in extensions currently. For example:

```dart
@JS()
library workarounds;

import 'dart:js_util' as js_util;

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS('KeyboardEvent')
@staticInterop
class JSKeyboardEvent {
  external JSKeyboardEvent(String typeArg, Object keyboardEventInit);
}

extension JSKeyboardEventExtension on JSKeyboardEvent {
  external String get key;
}

void main() {
  var event = JSKeyboardEvent('KeyboardEvent',
      js_util.jsify({'key': 'A'}));
  Expect.equals(event.key, 'A');
}
```

or with `js_util`'s `callConstructor`:

```dart
import 'dart:html';
import 'dart:js_util' as js_util;

import 'package:expect/expect.dart';

void main() {
  List<dynamic> eventArgs = <dynamic>[
    'KeyboardEvent',
    <String, dynamic>{'key': 'A'}
  ];
  KeyboardEvent event = js_util.callConstructor(
      js_util.getProperty(window, 'KeyboardEvent'), js_util.jsify(eventArgs));
  Expect.equals(event.key, 'A');
}
```

### Private/unimplemented native types

There are several native interfaces that are suppressed e.g.
`USBDevice` ([#42200][]) due to historical reasons. These native interfaces are
marked with `@Native`, are private, and have no attributes associated with them.
Therefore, unlike other `@Native` objects, we can’t access any of the APIs or
attributes associated with this interface. We can again either use the
`@staticInterop` annotation or use the `js_util` library to circumvent this
issue. For example, we can abstract a `_SubtleCrypto` object:

```dart
@JS()
library workarounds;

import 'dart:html';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:js/js.dart';

@JS()
external Crypto get crypto;

@JS()
@staticInterop
class JSSubtleCrypto {}

extension JSSubtleCryptoExtension on JSSubtleCrypto {
  external dynamic digest(String algorithm, Uint8List data);
  Future<ByteBuffer> digestFuture(String algorithm, Uint8List data) =>
      js_util.promiseToFuture(digest(algorithm, data));
}

void main() async {
  var subtle = crypto.subtle! as JSSubtleCrypto;
  var digest = await subtle.digestFuture('SHA-256', Uint8List(16));
}
```

or with `js_util`:

```dart
@JS()
library workarounds;

import 'dart:html';
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:js/js.dart';

@JS()
external Crypto get crypto;

void main() async {
  var subtle = crypto.subtle!;
  var array = Uint8List(16);
  var promise = js_util.promiseToFuture<ByteBuffer>(js_util
      .callMethod(subtle, 'digest', ['SHA-256', array])); // SubtleCrypto.digest
  var digest = await promise;
}
```

What you shouldn’t do is attempt to cast these native objects using the
non-`@staticInterop` `package:js` types e.g.

```dart
@JS()
library workarounds;

import 'dart:html';

import 'package:js/js.dart';

@JS()
external Crypto get crypto;

@JS()
class SubtleCrypto {}

void main() {
  SubtleCrypto subtle = crypto.subtle! as SubtleCrypto;
}
```

With the above, you’ll see a static error:

`Error: Non-static JS interop class 'SubtleCrypto' conflicts with natively supported class '_SubtleCrypto' in 'dart:html'.`

This is because the types in the `@Native` annotation are reserved and the above
leads to namespace conflicts between the `@Native` type and the user JS interop
type in the compiler. `@staticInterop` classes, however, don't have this issue.

[#42834]: https://github.com/dart-lang/sdk/issues/42834
[#42200]: https://github.com/dart-lang/sdk/issues/42200
