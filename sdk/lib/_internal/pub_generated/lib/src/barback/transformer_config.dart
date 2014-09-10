library pub.barback.transformer_config;
import 'package:path/path.dart' as p;
import 'package:source_span/source_span.dart';
import 'package:yaml/yaml.dart';
import 'transformer_id.dart';
class TransformerConfig {
  final TransformerId id;
  final Map configuration;
  final SourceSpan span;
  final Set<String> includes;
  final Set<String> excludes;
  bool get hasExclusions => includes != null || excludes != null;
  bool get canTransformPublicFiles {
    if (includes == null) return true;
    return includes.any(
        (path) => p.url.isWithin('lib', path) || p.url.isWithin('bin', path));
  }
  factory TransformerConfig.parse(String identifier, SourceSpan identifierSpan,
      YamlMap configuration) =>
      new TransformerConfig(
          new TransformerId.parse(identifier, identifierSpan),
          configuration);
  factory TransformerConfig(TransformerId id, YamlMap configurationNode) {
    parseField(key) {
      if (!configurationNode.containsKey(key)) return null;
      var fieldNode = configurationNode.nodes[key];
      var field = fieldNode.value;
      if (field is String) return new Set.from([field]);
      if (field is List) {
        for (var node in field.nodes) {
          if (node.value is String) continue;
          throw new SourceSpanFormatException(
              '"$key" field may contain only strings.',
              node.span);
        }
        return new Set.from(field);
      } else {
        throw new SourceSpanFormatException(
            '"$key" field must be a string or list.',
            fieldNode.span);
      }
    }
    var includes = null;
    var excludes = null;
    var configuration;
    var span;
    if (configurationNode == null) {
      configuration = {};
      span = id.span;
    } else {
      configuration = new Map.from(configurationNode);
      span = configurationNode.span;
      includes = parseField("\$include");
      configuration.remove("\$include");
      excludes = parseField("\$exclude");
      configuration.remove("\$exclude");
      for (var key in configuration.keys) {
        if (key is! String || !key.startsWith(r'$')) continue;
        throw new SourceSpanFormatException(
            'Unknown reserved field.',
            configurationNode.nodes[key].span);
      }
    }
    return new TransformerConfig._(id, configuration, span, includes, excludes);
  }
  TransformerConfig._(this.id, this.configuration, this.span, this.includes,
      this.excludes);
  String toString() => id.toString();
  bool canTransform(String pathWithinPackage) {
    if (excludes != null) {
      if (excludes.contains(pathWithinPackage)) return false;
    }
    return includes == null || includes.contains(pathWithinPackage);
  }
}
