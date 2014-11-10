// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library yaml;

import 'src/loader.dart';
import 'src/style.dart';
import 'src/yaml_document.dart';
import 'src/yaml_exception.dart';
import 'src/yaml_node.dart';

export 'src/style.dart';
export 'src/utils.dart' show YamlWarningCallback, yamlWarningCallback;
export 'src/yaml_document.dart';
export 'src/yaml_exception.dart';
export 'src/yaml_node.dart' hide setSpan;

/// Loads a single document from a YAML string.
///
/// If the string contains more than one document, this throws a
/// [YamlException]. In future releases, this will become an [ArgumentError].
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// In future versions, maps will instead be [HashMap]s with a custom equality
/// operation.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting. It can be a [String], a [Uri], or `null`.
loadYaml(String yaml, {sourceUrl}) =>
    loadYamlNode(yaml, sourceUrl: sourceUrl).value;

/// Loads a single document from a YAML string as a [YamlNode].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlNode] instead. This allows the caller
/// to be confident that the return value will always be a [YamlNode].
YamlNode loadYamlNode(String yaml, {sourceUrl}) =>
    loadYamlDocument(yaml, sourceUrl: sourceUrl).contents;

/// Loads a single document from a YAML string as a [YamlDocument].
///
/// This is just like [loadYaml], except that where [loadYaml] would return a
/// normal Dart value this returns a [YamlDocument] instead. This allows the
/// caller to access document metadata.
YamlDocument loadYamlDocument(String yaml, {sourceUrl}) {
  var loader = new Loader(yaml, sourceUrl: sourceUrl);
  var document = loader.load();
  if (document == null) {
    return new YamlDocument.internal(
        new YamlScalar.internal(null, loader.span, ScalarStyle.ANY),
        loader.span, null, const []);
  }

  var nextDocument = loader.load();
  if (nextDocument != null) {
    throw new YamlException("Only expected one document.", nextDocument.span);
  }

  return document;
}

/// Loads a stream of documents from a YAML string.
///
/// The return value is mostly normal Dart objects. However, since YAML mappings
/// support some key types that the default Dart map implementation doesn't
/// (NaN, lists, and maps), all maps in the returned document are [YamlMap]s.
/// These have a few small behavioral differences from the default Map
/// implementation; for details, see the [YamlMap] class.
///
/// In future versions, maps will instead be [HashMap]s with a custom equality
/// operation.
///
/// If [sourceUrl] is passed, it's used as the URL from which the YAML
/// originated for error reporting. It can be a [String], a [Uri], or `null`.
YamlList loadYamlStream(String yaml, {sourceUrl}) {
  var loader = new Loader(yaml, sourceUrl: sourceUrl);

  var documents = [];
  var document = loader.load();
  while (document != null) {
    documents.add(document);
    document = loader.load();
  }

  return new YamlList.internal(
      documents.map((document) => document.contents).toList(),
      loader.span,
      CollectionStyle.ANY);
}

/// Loads a stream of documents from a YAML string.
///
/// This is like [loadYamlStream], except that it returns [YamlDocument]s with
/// metadata wrapping the document contents.
List<YamlDocument> loadYamlDocuments(String yaml, {sourceUrl}) {
  var loader = new Loader(yaml, sourceUrl: sourceUrl);

  var documents = [];
  var document = loader.load();
  while (document != null) {
    documents.add(document);
    document = loader.load();
  }

  return documents;
}
