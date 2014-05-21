A parser for [YAML](http://www.yaml.org/).

Use `loadYaml` to load a single document, or `loadYamlStream` to load a
stream of documents. For example:

```dart
import 'package:yaml/yaml.dart';

main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(doc['YAML']);
}
```

This library currently doesn't support dumping to YAML. You should use
`JSON.encode` from `dart:convert` instead:

```dart
import 'dart:convert';
import 'package:yaml/yaml.dart';

main() {
  var doc = loadYaml("YAML: YAML Ain't Markup Language");
  print(JSON.encode(doc));
}
```

The source code for this package is at <http://code.google.com/p/dart>.
Please file issues at <http://dartbug.com>. Other questions or comments can be
directed to the Dart mailing list at <mailto:misc@dartlang.org>.
