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

## Workarounds to Avoid

### Using non-`@staticInterop` `package:js` types

Avoid casting these native objects to non-`@staticInterop` `package:js` types
e.g.

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

### Using extensions on `@Native` types

One alternative that seems viable is to use a static extension on the `@Native`
type in `dart:html` directly, e.g.

```dart
extension FileReaderExtension on FileReader {
  external void readAsBinaryString(Blob blob);
}
```

This may work fine, as long as `FileReader` does not add `readAsBinaryString`.
In the case where this API is added to the class, Dart will [prioritize][] that
instance method over the extension method you wrote. This may lead to issues,
like a type error when the signatures between the two methods are incompatible,
or confusing runtime behavior.

Furthermore, you may come across API conflicts with other users who have also
defined extension methods on these `@Native` types.

To avoid the above, it's recommended you stick with `@staticInterop`.

In the future, when views/extension types are introduced to the language, this
guidance will likely change so that you can directly use views on `@Native`
types.

[#42834]: https://github.com/dart-lang/sdk/issues/42834
[#42200]: https://github.com/dart-lang/sdk/issues/42200
[prioritize]: https://github.com/dart-lang/language/blob/master/accepted/2.7/static-extension-methods/feature-specification.md#member-conflict-resolution
