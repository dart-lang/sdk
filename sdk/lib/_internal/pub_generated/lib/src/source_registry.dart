library pub.source_registry;
import 'dart:collection';
import 'package.dart';
import 'source.dart';
import 'source/unknown.dart';
class SourceRegistry extends IterableBase<Source> {
  final _sources = new Map<String, Source>();
  Source _default;
  Source get defaultSource => _default;
  Iterator<Source> get iterator {
    var sources = _sources.values.toList();
    sources.sort((a, b) => a.name.compareTo(b.name));
    return sources.iterator;
  }
  bool idsEqual(PackageId id1, PackageId id2) {
    if (id1 != id2) return false;
    if (id1 == null && id2 == null) return true;
    return idDescriptionsEqual(id1, id2);
  }
  bool idDescriptionsEqual(PackageId id1, PackageId id2) {
    if (id1.source != id2.source) return false;
    return this[id1.source].descriptionsEqual(id1.description, id2.description);
  }
  void setDefault(String name) {
    if (!_sources.containsKey(name)) {
      throw new StateError('Default source $name is not in the registry');
    }
    _default = _sources[name];
  }
  void register(Source source) {
    if (_sources.containsKey(source.name)) {
      throw new StateError(
          'Source registry already has a source named ' '${source.name}');
    }
    _sources[source.name] = source;
  }
  Source operator [](String name) {
    if (name == null) {
      if (defaultSource != null) return defaultSource;
      throw new StateError('No default source has been registered');
    }
    if (_sources.containsKey(name)) return _sources[name];
    return new UnknownSource(name);
  }
}
