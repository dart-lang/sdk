# `package:record_use`


> [!CAUTION]
> This is an experimental package, and it's API can break at any time. Use at
> your own discretion.

This package provides the data classes for the usage recording feature in the
Dart SDK.

Dart objects with the `@RecordUse` annotation are being recorded at compile 
time, providing the user with information. The information depends on the object
being recorded.

- If placed on a static method, the annotation means that arguments passed to
the method will be recorded, as far as they can be inferred at compile time.
- If placed on a class with a constant constructor, the annotation means that
any constant instance of the class will be recorded. This is particularly useful
when using the class as an annotation.

## Example

```dart
import 'package:meta/meta.dart' show RecordUse;

void main() {
  print(SomeClass.stringMetadata(42));
  print(SomeClass.doubleMetadata(42));
  print(SomeClass.intMetadata(42));
  print(SomeClass.boolMetadata(42));
}

class SomeClass {
  @RecordMetadata('leroyjenkins')
  @RecordUse()
  static stringMetadata(int i) {
    return i + 1;
  }

  @RecordMetadata(3.14)
  @RecordUse()
  static doubleMetadata(int i) {
    return i + 1;
  }

  @RecordMetadata(42)
  @RecordUse()
  static intMetadata(int i) {
    return i + 1;
  }

  @RecordMetadata(true)
  @RecordUse()
  static boolMetadata(int i) {
    return i + 1;
  }
}

@RecordUse()
class RecordMetadata {
  final Object metadata;

  const RecordMetadata(this.metadata);
}

```
This code will generate a data file that contains both the `metadata` values of
the `RecordMetadata` instances, as well as the arguments for the different
methods annotated with `@RecordUse()`.

This information can then be accessed in a link hook as follows:
```dart
import 'dart:convert';

import 'package:native_assets_cli/native_assets_cli.dart';
import 'package:record_use/record_use_internal.dart';

final methodId = Identifier(
  uri: 'myfile.dart',
  name: 'myMethod',
);

final classId = Identifier(
  uri: 'myfile.dart',
  name: 'myClass',
);

void main(List<String> arguments){
  link(arguments, (config, output) async {
    final usesUri = config.recordedUses;
    final usesJson = await File,fromUri(usesUri).readAsString();
    final uses = UsageRecord.fromJson(jsonDecode(usesJson));

    final args = uses.argumentsTo(methodId));
    //[args] is an iterable of arguments, in this case containing "42"

    final fields = uses.instancesOf(classId);
    //[fields] is an iterable of the fields of the class, in this case
    //containing
    // {"arguments": "leroyjenkins"}
    // {"arguments": 3.14}
    // {"arguments": 42}
    // {"arguments": true}

    ... // Do something with the information, such as tree-shaking native assets
  });
}
```

## Contributing
Contributions are welcome! Please open an issue or submit a pull request.