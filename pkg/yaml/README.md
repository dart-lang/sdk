A parser for [YAML](http://www.yaml.org/).

Use `loadYaml` to load a single document, or `loadYamlStream` to load a
stream of documents. For example:

    import 'package:yaml/yaml.dart';
    main() {
      var doc = loadYaml("YAML: YAML Ain't Markup Language");
      print(doc['YAML']);
    }

This library currently doesn't support dumping to YAML. You should use
`stringify` from `dart:json` instead:

    import 'dart:json' as json;
    import 'package:yaml/yaml.dart';
    main() {
      var doc = loadYaml("YAML: YAML Ain't Markup Language");
      print(json.stringify(doc));
    }

The source code for this package is at <http://code.google.com/p/dart>.
Please file issues at <http://dartbug.com>. Other questions or comments can be
directed to the Dart mailing list at <mailto:misc@dartlang.org>.
