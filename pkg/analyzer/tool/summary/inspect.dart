// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:analyzer/src/summary/base.dart';
import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';
import 'package:args/args.dart';

main(List<String> args) {
  ArgParser argParser = new ArgParser()..addFlag('raw');
  ArgResults argResults = argParser.parse(args);
  if (argResults.rest.length != 1) {
    print(argParser.usage);
    exitCode = 1;
    return;
  }
  String path = argResults.rest[0];
  List<int> bytes = new File(path).readAsBytesSync();
  PackageBundle bundle = new PackageBundle.fromBuffer(bytes);
  SummaryInspector inspector = new SummaryInspector(argResults['raw']);
  print(inspector.dumpPackageBundle(bundle).join('\n'));
}

const int MAX_LINE_LENGTH = 80;

/**
 * Cache used to speed up [isEnum].
 */
Map<Type, bool> _isEnumCache = <Type, bool>{};

/**
 * Determine if the given [obj] has an enumerated type.
 */
bool isEnum(Object obj) {
  return _isEnumCache.putIfAbsent(
      obj.runtimeType, () => reflect(obj).type.isEnum);
}

/**
 * Decoded reprensentation of a part of a summary that occupies multiple lines
 * of output.
 */
class BrokenEntity implements DecodedEntity {
  final String opener;
  final Map<String, DecodedEntity> parts;
  final String closer;

  BrokenEntity(this.opener, this.parts, this.closer);

  @override
  List<String> getLines() {
    List<String> result = <String>[opener];
    bool first = true;
    for (String key in parts.keys) {
      if (first) {
        first = false;
      } else {
        result[result.length - 1] += ',';
      }
      List<String> subResult = parts[key].getLines();
      subResult[0] = '$key: ${subResult[0]}';
      result.addAll(subResult.map((String s) => '  $s'));
    }
    result.add(closer);
    return result;
  }
}

/**
 * Decoded representation of a part of a summary.
 */
abstract class DecodedEntity {
  /**
   * Create a representation of a part of the summary that consists of a group
   * of entities (represented by [parts]) contained between [opener] and
   * [closer].
   *
   * If [forceKeys] is `true`, the keys in [parts] will always be shown.  If
   * [forceKeys] is `false`, they keys will only be shown if the output is
   * broken into multiple lines.
   */
  factory DecodedEntity.group(String opener, Map<String, DecodedEntity> parts,
      String closer, bool forceKeys) {
    // Attempt to format the entity in a single line; if not bail out and
    // construct a _BrokenEntity.
    DecodedEntity bailout() => new BrokenEntity(opener, parts, closer);
    String short = opener;
    bool first = true;
    for (String key in parts.keys) {
      if (first) {
        first = false;
      } else {
        short += ', ';
      }
      DecodedEntity value = parts[key];
      if (forceKeys) {
        short += '$key: ';
      }
      if (value is UnbrokenEntity) {
        short += value._s;
      } else {
        return bailout();
      }
      if (short.length > MAX_LINE_LENGTH) {
        return bailout();
      }
    }
    return new DecodedEntity.short(short + closer);
  }

  /**
   * Create a representation of a part of the summary that is represented by a
   * single unbroken string.
   */
  factory DecodedEntity.short(String s) = UnbrokenEntity;

  /**
   * Format this entity into a sequence of strings (one per output line).
   */
  List<String> getLines();
}

/**
 * Wrapper around a [LinkedLibrary] and its constituent [UnlinkedUnit]s.
 */
class LibraryWrapper {
  final LinkedLibrary _linked;
  final List<UnlinkedUnit> _unlinked;

  LibraryWrapper(this._linked, this._unlinked);
}

/**
 * Wrapper around a [LinkedReference] and its corresponding [UnlinkedReference].
 */
class ReferenceWrapper {
  final LinkedReference _linked;
  final UnlinkedReference _unlinked;

  ReferenceWrapper(this._linked, this._unlinked);

  String get name {
    if (_linked != null && _linked.name.isNotEmpty) {
      return _linked.name;
    } else if (_unlinked != null && _unlinked.name.isNotEmpty) {
      return _unlinked.name;
    } else {
      return '???';
    }
  }
}

/**
 * Instances of [SummaryInspector] are capable of traversing a summary and
 * converting it to semi-human-readable output.
 */
class SummaryInspector {
  /**
   * The dependencies of the library currently being visited.
   */
  List<LinkedDependency> _dependencies;

  /**
   * The references of the unit currently being visited.
   */
  List<ReferenceWrapper> _references;

  /**
   * Indicates whether summary inspection should operate in "raw" mode.  In this
   * mode, the structure of the summary file is not altered for easier
   * readability; everything is output in exactly the form in which it appears
   * in the file.
   */
  final bool raw;

  SummaryInspector(this.raw);

  /**
   * Decode the object [obj], which was reached by examining [key] inside
   * another object.
   */
  DecodedEntity decode(Object obj, String key) {
    if (!raw && obj is PackageBundle) {
      return decodePackageBundle(obj);
    }
    if (obj is LibraryWrapper) {
      return decodeLibrary(obj);
    }
    if (obj is UnitWrapper) {
      return decodeUnit(obj);
    }
    if (obj is ReferenceWrapper) {
      return decodeReference(obj);
    }
    if (obj is DecodedEntity) {
      return obj;
    }
    if (obj is SummaryClass) {
      Map<String, Object> map = obj.toMap();
      return decodeMap(map);
    } else if (obj is List) {
      Map<String, DecodedEntity> parts = <String, DecodedEntity>{};
      for (int i = 0; i < obj.length; i++) {
        parts[i.toString()] = decode(obj[i], key);
      }
      return new DecodedEntity.group('[', parts, ']', false);
    } else if (obj is String) {
      return new DecodedEntity.short(JSON.encode(obj));
    } else if (isEnum(obj)) {
      return new DecodedEntity.short(obj.toString().split('.')[1]);
    } else if (obj is int &&
        key == 'dependency' &&
        _dependencies != null &&
        obj < _dependencies.length) {
      return new DecodedEntity.short('$obj (${_dependencies[obj].uri})');
    } else if (obj is int &&
        key == 'reference' &&
        _references != null &&
        obj < _references.length) {
      return new DecodedEntity.short('$obj (${_references[obj].name})');
    } else {
      return new DecodedEntity.short(obj.toString());
    }
  }

  /**
   * Decode the given [LibraryWrapper].
   */
  DecodedEntity decodeLibrary(LibraryWrapper obj) {
    try {
      LinkedLibrary linked = obj._linked;
      List<UnlinkedUnit> unlinked = obj._unlinked;
      _dependencies = linked.dependencies;
      Map<String, Object> result = linked.toMap();
      result.remove('units');
      result['defining compilation unit'] =
          new UnitWrapper(linked.units[0], unlinked[0]);
      for (int i = 1; i < linked.units.length; i++) {
        String partUri = unlinked[0].publicNamespace.parts[i - 1];
        result['part ${JSON.encode(partUri)}'] =
            new UnitWrapper(linked.units[i], unlinked[i]);
      }
      return decodeMap(result);
    } finally {
      _dependencies = null;
    }
  }

  /**
   * Decode the given [map].
   */
  DecodedEntity decodeMap(Map<String, Object> map) {
    Map<String, DecodedEntity> parts = <String, DecodedEntity>{};
    map = reorderMap(map);
    map.forEach((String key, Object value) {
      if (value is String && value.isEmpty) {
        return;
      }
      if (isEnum(value) && (value as dynamic).index == 0) {
        return;
      }
      if (value is int && value == 0) {
        return;
      }
      if (value is bool && value == false) {
        return;
      }
      if (value == null) {
        return;
      }
      if (value is List) {
        if (value.isEmpty) {
          return;
        }
        DecodedEntity entity = decode(value, key);
        if (entity is BrokenEntity) {
          for (int i = 0; i < value.length; i++) {
            parts['$key[$i]'] = decode(value[i], key);
          }
          return;
        } else {
          parts[key] = entity;
        }
      }
      parts[key] = decode(value, key);
    });
    return new DecodedEntity.group('{', parts, '}', true);
  }

  /**
   * Decode the given [PackageBundle].
   */
  DecodedEntity decodePackageBundle(PackageBundle bundle) {
    Map<String, UnlinkedUnit> units = <String, UnlinkedUnit>{};
    Set<String> seenUnits = new Set<String>();
    for (int i = 0; i < bundle.unlinkedUnits.length; i++) {
      units[bundle.unlinkedUnitUris[i]] = bundle.unlinkedUnits[i];
    }
    Map<String, Object> restOfMap = bundle.toMap();
    Map<String, Object> result = <String, Object>{};
    result['version'] = new DecodedEntity.short(
        '${bundle.majorVersion}.${bundle.minorVersion}');
    restOfMap.remove('majorVersion');
    restOfMap.remove('minorVersion');
    result['linkedLibraryUris'] = restOfMap['linkedLibraryUris'];
    result['unlinkedUnitUris'] = restOfMap['unlinkedUnitUris'];
    for (int i = 0; i < bundle.linkedLibraries.length; i++) {
      String libraryUriString = bundle.linkedLibraryUris[i];
      Uri libraryUri = Uri.parse(libraryUriString);
      UnlinkedUnit unlinkedDefiningUnit = units[libraryUriString];
      seenUnits.add(libraryUriString);
      List<UnlinkedUnit> libraryUnits = <UnlinkedUnit>[unlinkedDefiningUnit];
      LinkedLibrary linkedLibrary = bundle.linkedLibraries[i];
      for (int j = 1; j < linkedLibrary.units.length; j++) {
        String partUriString = resolveRelativeUri(libraryUri,
                Uri.parse(unlinkedDefiningUnit.publicNamespace.parts[j - 1]))
            .toString();
        libraryUnits.add(units[partUriString]);
        seenUnits.add(partUriString);
      }
      result['library ${JSON.encode(libraryUriString)}'] =
          new LibraryWrapper(linkedLibrary, libraryUnits);
    }
    for (String uriString in units.keys) {
      if (seenUnits.contains(uriString)) {
        continue;
      }
      result['orphan unit ${JSON.encode(uriString)}'] =
          new UnitWrapper(null, units[uriString]);
    }
    restOfMap.remove('linkedLibraries');
    restOfMap.remove('linkedLibraryUris');
    restOfMap.remove('unlinkedUnits');
    restOfMap.remove('unlinkedUnitUris');
    result.addAll(restOfMap);
    return decodeMap(result);
  }

  /**
   * Decode the given [ReferenceWrapper].
   */
  DecodedEntity decodeReference(ReferenceWrapper obj) {
    Map<String, Object> result = obj._unlinked != null
        ? obj._unlinked.toMap()
        : <String, Object>{'linkedOnly': true};
    if (obj._linked != null) {
      mergeMaps(result, obj._linked.toMap());
    }
    return decodeMap(result);
  }

  /**
   * Decode the given [UnitWrapper].
   */
  DecodedEntity decodeUnit(UnitWrapper obj) {
    try {
      LinkedUnit linked = obj._linked;
      UnlinkedUnit unlinked = obj._unlinked ?? new UnlinkedUnitBuilder();
      Map<String, Object> unlinkedMap = unlinked.toMap();
      Map<String, Object> linkedMap =
          linked != null ? linked.toMap() : <String, Object>{};
      Map<String, Object> result = <String, Object>{};
      List<ReferenceWrapper> references = <ReferenceWrapper>[];
      int numReferences = linked != null
          ? linked.references.length
          : unlinked.references.length;
      for (int i = 0; i < numReferences; i++) {
        references.add(new ReferenceWrapper(
            linked != null ? linked.references[i] : null,
            i < unlinked.references.length ? unlinked.references[i] : null));
      }
      result['references'] = references;
      _references = references;
      unlinkedMap.remove('references');
      linkedMap.remove('references');
      linkedMap.forEach((String key, Object value) {
        result['linked $key'] = value;
      });
      unlinkedMap.forEach((String key, Object value) {
        result[key] = value;
      });
      return decodeMap(result);
    } finally {
      _references = null;
    }
  }

  /**
   * Decode the given [PackageBundle] and dump it to a list of strings.
   */
  List<String> dumpPackageBundle(PackageBundle bundle) {
    DecodedEntity decoded = decode(bundle, 'PackageBundle');
    return decoded.getLines();
  }

  /**
   * Merge the contents of [other] into [result], discarding empty entries.
   */
  void mergeMaps(Map<String, Object> result, Map<String, Object> other) {
    other.forEach((String key, Object value) {
      if (value is String && value.isEmpty) {
        return;
      }
      if (result.containsKey(key)) {
        Object oldValue = result[key];
        if (oldValue is String && oldValue.isEmpty) {
          result[key] = value;
        } else {
          throw new Exception(
              'Duplicate values for $key: $oldValue and $value');
        }
      } else {
        result[key] = value;
      }
    });
  }

  /**
   * Reorder [map] for more intuitive display.
   */
  Map<String, Object> reorderMap(Map<String, Object> map) {
    Map<String, Object> result = <String, Object>{};
    if (map.containsKey('name')) {
      result['name'] = map['name'];
    }
    result.addAll(map);
    return result;
  }
}

/**
 * Decoded reprensentation of a part of a summary that occupies a single line of
 * output.
 */
class UnbrokenEntity implements DecodedEntity {
  final String _s;

  UnbrokenEntity(this._s);

  @override
  List<String> getLines() => <String>[_s];
}

/**
 * Wrapper around a [LinkedUnit] and its corresponding [UnlinkedUnit].
 */
class UnitWrapper {
  final LinkedUnit _linked;
  final UnlinkedUnit _unlinked;

  UnitWrapper(this._linked, this._unlinked);
}
