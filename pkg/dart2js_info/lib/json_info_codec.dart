// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: avoid_dynamic_calls

/// Converters and codecs for converting between JSON and [Info] classes.
library;

import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';

import 'info.dart';
import 'src/util.dart';

// TODO(sigmund): add unit tests.
class JsonToAllInfoConverter extends Converter<Map<String, dynamic>, AllInfo> {
  // Using `MashMap` here because it's faster than the default `LinkedHashMap`.
  final Map<String, Info> registry = HashMap<String, Info>();

  @override
  AllInfo convert(Map<String, dynamic> input) {
    registry.clear();

    var result = AllInfo();
    var elements = input['elements'];
    // TODO(srawlins): Since only the Map values are being extracted below,
    // replace `as` with `cast` when `cast` becomes available in Dart 2.0:
    //
    //     .addAll(elements['library'].values.cast<Map>().map(parseLibrary));
    result.libraries.addAll(
        (elements['library'] as Map).values.map((l) => parseLibrary(l)));
    result.classes
        .addAll((elements['class'] as Map).values.map((c) => parseClass(c)));
    result.classTypes.addAll(
        (elements['classType'] as Map).values.map((c) => parseClassType(c)));
    result.functions.addAll(
        (elements['function'] as Map).values.map((f) => parseFunction(f)));

    // TODO(het): Revert this when the dart2js with the new codec is in stable
    if (elements['closure'] != null) {
      result.closures.addAll(
          (elements['closure'] as Map).values.map((c) => parseClosure(c)));
    }
    result.fields
        .addAll((elements['field'] as Map).values.map((f) => parseField(f)));
    result.typedefs.addAll(
        (elements['typedef'] as Map).values.map((t) => parseTypedef(t)));
    result.constants.addAll(
        (elements['constant'] as Map).values.map((c) => parseConstant(c)));

    input['holding'].forEach((k, deps) {
      final src = registry[k] as CodeInfo;
      for (var dep in deps) {
        final target = registry[dep['id']]!;
        src.uses.add(DependencyInfo(target, dep['mask']));
      }
    });

    input['dependencies']?.forEach((String k, dependencies) {
      List<String> deps = dependencies;
      result.dependencies[registry[k]!] =
          deps.map((d) => registry[d]!).toList();
    });

    result.outputUnits
        .addAll((input['outputUnits'] as List).map((o) => parseOutputUnit(o)));

    result.program = parseProgram(input['program']);

    if (input['deferredFiles'] != null) {
      final deferredFilesMap =
          (input['deferredFiles'] as Map).cast<String, Map<String, dynamic>>();
      for (final library in deferredFilesMap.values) {
        if (library['imports'] != null) {
          // The importMap needs to be typed as <String, List<String>>, but the
          // json parser produces <String, dynamic>.
          final importMap = library['imports'] as Map<String, dynamic>;
          importMap.forEach((prefix, files) {
            importMap[prefix] = (files as List<dynamic>).cast<String>();
          });
          library['imports'] = importMap.cast<String, List<String>>();
        }
      }
      result.deferredFiles = deferredFilesMap;
    }

    // todo: version, etc
    return result;
  }

  OutputUnitInfo parseOutputUnit(Map json) {
    final result = parseId(json['id']) as OutputUnitInfo;
    result
      ..filename = json['filename']
      ..name = json['name']
      ..size = json['size'];
    result.imports.addAll((json['imports'] as List).map((s) => s as String));
    return result;
  }

  LibraryInfo parseLibrary(Map json) {
    final result = parseId(json['id']) as LibraryInfo;
    result
      ..name = json['name']
      ..uri = Uri.parse(json['canonicalUri'])
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?
      ..size = json['size'];
    for (var child in json['children'].map((id) => parseId(id))) {
      if (child is FunctionInfo) {
        result.topLevelFunctions.add(child);
      } else if (child is FieldInfo) {
        result.topLevelVariables.add(child);
      } else if (child is ClassInfo) {
        result.classes.add(child);
      } else if (child is ClassTypeInfo) {
        result.classTypes.add(child);
      } else if (child is TypedefInfo) {
        result.typedefs.add(child);
      } else {
        throw StateError('Invalid LibraryInfo child: $child');
      }
    }
    return result;
  }

  ClassInfo parseClass(Map json) {
    final result = parseId(json['id']) as ClassInfo;
    result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?
      ..size = json['size']
      ..isAbstract = json['modifiers']['abstract'] == true;
    for (var child in json['children'].map((id) => parseId(id))) {
      if (child is FunctionInfo) {
        result.functions.add(child);
      } else if (child is FieldInfo) {
        result.fields.add(child);
      } else {
        throw StateError('Invalid ClassInfo child: $child');
      }
    }
    result.supers.addAll(
        json['supers'].map<ClassInfo>((id) => parseId(id) as ClassInfo));
    return result;
  }

  ClassTypeInfo parseClassType(Map json) {
    final result = parseId(json['id']) as ClassTypeInfo;
    result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?
      ..size = json['size'];
    return result;
  }

  FieldInfo parseField(Map json) {
    final result = parseId(json['id']) as FieldInfo;
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..coverageId = json['coverageId']
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?
      ..size = json['size']
      ..type = json['type']
      ..inferredType = json['inferredType']
      ..code = parseCode(json['code'])
      ..isConst = json['const'] ?? false
      ..initializer = parseId(json['initializer']) as ConstantInfo?
      ..closures = (json['children'] as List)
          .map<ClosureInfo>((c) => parseId(c) as ClosureInfo)
          .toList();
  }

  ConstantInfo parseConstant(Map json) {
    final result = parseId(json['id']) as ConstantInfo;
    return result
      ..name = json['name']
      ..code = parseCode(json['code'])
      ..size = json['size']
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?;
  }

  TypedefInfo parseTypedef(Map json) {
    final result = parseId(json['id']) as TypedefInfo;
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..type = json['type']
      ..size = 0;
  }

  ProgramInfo parseProgram(Map json) {
    // TODO(het): Revert this when the dart2js with the new codec is in stable
    final compilationDuration = json['compilationDuration'];
    final compilationDurationParsed = compilationDuration is String
        ? _parseDuration(compilationDuration)
        : Duration(microseconds: compilationDuration as int);

    final toJsonDuration = json['toJsonDuration'];
    final toJsonDurationParsed = toJsonDuration is String
        ? _parseDuration(toJsonDuration)
        : Duration(microseconds: toJsonDuration as int);

    final dumpInfoDuration = json['dumpInfoDuration'];
    final dumpInfoDurationParsed = dumpInfoDuration is String
        ? _parseDuration(dumpInfoDuration)
        : Duration(microseconds: dumpInfoDuration as int);

    final programInfo = ProgramInfo(
        entrypoint: parseId(json['entrypoint']) as FunctionInfo,
        size: json['size'],
        ramUsage: json['ramUsage'],
        compilationMoment: DateTime.parse(json['compilationMoment']),
        dart2jsVersion: json['dart2jsVersion'],
        noSuchMethodEnabled: json['noSuchMethodEnabled'],
        isRuntimeTypeUsed: json['isRuntimeTypeUsed'],
        isIsolateInUse: json['isIsolateInUse'],
        isFunctionApplyUsed: json['isFunctionApplyUsed'],
        isMirrorsUsed: json['isMirrorsUsed'],
        minified: json['minified'],
        compilationDuration: compilationDurationParsed,
        toJsonDuration: toJsonDurationParsed,
        dumpInfoDuration: dumpInfoDurationParsed);

    return programInfo;
  }

  /// Parse a string formatted as "XX:YY:ZZ.ZZZZZ" into a [Duration].
  Duration _parseDuration(String duration) {
    if (!duration.contains(':')) {
      return Duration(milliseconds: int.parse(duration));
    }
    var parts = duration.split(':');
    var hours = double.parse(parts[0]);
    var minutes = double.parse(parts[1]);
    var seconds = double.parse(parts[2]);
    const secondsInMillis = 1000;
    const minutesInMillis = 60 * secondsInMillis;
    const hoursInMillis = 60 * minutesInMillis;
    var totalMillis = secondsInMillis * seconds +
        minutesInMillis * minutes +
        hoursInMillis * hours;
    return Duration(milliseconds: totalMillis.round());
  }

  FunctionInfo parseFunction(Map json) {
    final result = parseId(json['id']) as FunctionInfo;
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..coverageId = json['coverageId']
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?
      ..size = json['size']
      ..functionKind = json['functionKind']
      ..type = json['type']
      ..returnType = json['returnType']
      ..inferredReturnType = json['inferredReturnType']
      ..parameters =
          (json['parameters'] as List).map((p) => parseParameter(p)).toList()
      ..code = parseCode(json['code'])
      ..sideEffects = json['sideEffects']
      ..inlinedCount = json['inlinedCount']
      ..modifiers = parseModifiers(Map<String, bool>.from(json['modifiers']))
      ..closures = (json['children'] as List)
          .map<ClosureInfo>((c) => parseId(c) as ClosureInfo)
          .toList();
  }

  ParameterInfo parseParameter(Map json) =>
      ParameterInfo(json['name'], json['type'], json['declaredType']);

  FunctionModifiers parseModifiers(Map<String, bool> json) {
    return FunctionModifiers(
        isStatic: json['static'] == true,
        isConst: json['const'] == true,
        isFactory: json['factory'] == true,
        isExternal: json['external'] == true);
  }

  ClosureInfo parseClosure(Map json) {
    final result = parseId(json['id']) as ClosureInfo;
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..outputUnit = parseId(json['outputUnit']) as OutputUnitInfo?
      ..size = json['size']
      ..function = parseId(json['function']) as FunctionInfo;
  }

  Info? parseId(String? serializedId) {
    if (serializedId == null) {
      return null;
    }
    return registry.putIfAbsent(serializedId, () {
      if (serializedId.startsWith('function/')) {
        return FunctionInfo.internal();
      } else if (serializedId.startsWith('closure/')) {
        return ClosureInfo.internal();
      } else if (serializedId.startsWith('library/')) {
        return LibraryInfo.internal();
      } else if (serializedId.startsWith('class/')) {
        return ClassInfo.internal();
      } else if (serializedId.startsWith('classType/')) {
        return ClassTypeInfo.internal();
      } else if (serializedId.startsWith('field/')) {
        return FieldInfo.internal();
      } else if (serializedId.startsWith('constant/')) {
        return ConstantInfo.internal();
      } else if (serializedId.startsWith('typedef/')) {
        return TypedefInfo.internal();
      } else if (serializedId.startsWith('outputUnit/')) {
        return OutputUnitInfo.internal();
      }
      throw StateError('Invalid serialized ID found: $serializedId');
    });
  }

  List<CodeSpan> parseCode(dynamic json) {
    // backwards compatibility with format 5.1:
    if (json is String) {
      return [CodeSpan(start: null, end: null, text: json)];
    }

    if (json is List) {
      return json.map((dynamic value) {
        Map<String, dynamic> jsonCode = value;
        return CodeSpan(
            start: jsonCode['start'],
            end: jsonCode['end'],
            text: jsonCode['text']);
      }).toList();
    }

    return [];
  }
}

class AllInfoToJsonConverter extends Converter<AllInfo, Map>
    implements InfoVisitor<Map> {
  /// Whether to generate json compatible with format 5.1
  final bool isBackwardCompatible;

  final Map<Info, Id> ids = HashMap<Info, Id>();
  final Set<String> usedIds = <String>{};

  AllInfoToJsonConverter({this.isBackwardCompatible = false});

  Id idFor(Info info) {
    var serializedId = ids[info];
    if (serializedId != null) return serializedId;

    assert(
        info is LibraryInfo ||
            info is ConstantInfo ||
            info is OutputUnitInfo ||
            info is ClassInfo ||
            info.parent != null,
        "$info");

    String name;
    if (info is ConstantInfo) {
      // No name and no parent, so `longName` isn't helpful
      assert(info.name.isEmpty);
      assert(info.parent == null);
      // Instead, use the content of the code.
      name = info.code.first.text ?? '';
    } else {
      name = longName(info, useLibraryUri: true, forId: true);
    }

    Id id = Id(info.kind, name);
    // longName isn't guaranteed to create unique serializedIds for some info
    // constructs (such as closures), so we disambiguate here.
    int count = 0;
    while (!usedIds.add(id.serializedId)) {
      id = Id(info.kind, '$name%${count++}');
    }

    return ids[info] = id;
  }

  @override
  Map convert(AllInfo input) => input.accept(this);

  Map _visitList(List<Info> infos) {
    // Using SplayTree to maintain a consistent order of keys
    var map = SplayTreeMap<String, Map>(compareNatural);
    for (var info in infos) {
      map[idFor(info).id] = info.accept(this);
    }
    return map;
  }

  Map _visitAllInfoElements(AllInfo info) {
    var jsonLibraries = _visitList(info.libraries);
    var jsonClasses = _visitList(info.classes);
    var jsonClassTypes = _visitList(info.classTypes);
    var jsonFunctions = _visitList(info.functions);
    var jsonTypedefs = _visitList(info.typedefs);
    var jsonFields = _visitList(info.fields);
    var jsonConstants = _visitList(info.constants);
    var jsonClosures = _visitList(info.closures);
    return {
      'library': jsonLibraries,
      'class': jsonClasses,
      'classType': jsonClassTypes,
      'function': jsonFunctions,
      'typedef': jsonTypedefs,
      'field': jsonFields,
      'constant': jsonConstants,
      'closure': jsonClosures,
    };
  }

  Map visitDependencyInfo(DependencyInfo info) => {
        'id': idFor(info.target).serializedId,
        if (info.mask != null) 'mask': info.mask,
      };

  Map _visitAllInfoHolding(AllInfo allInfo) {
    var map = SplayTreeMap<String, List>(compareNatural);
    void helper(CodeInfo info) {
      if (info.uses.isEmpty) return;
      map[idFor(info).serializedId] =
          info.uses.map(visitDependencyInfo).toList()
            ..sort((a, b) {
              final value = a['id'].compareTo(b['id']);
              if (value != 0) return value;
              final aMask = a['mask'] as String?;
              final bMask = b['mask'] as String?;
              if (aMask == null) {
                return bMask == null ? 0 : 1;
              }
              if (bMask == null) {
                return -1;
              }
              return aMask.compareTo(bMask);
            });
    }

    allInfo.functions.forEach(helper);
    allInfo.fields.forEach(helper);
    return map;
  }

  Map _visitAllInfoDependencies(AllInfo allInfo) {
    var map = SplayTreeMap<String, List>(compareNatural);
    allInfo.dependencies.forEach((k, v) {
      map[idFor(k).serializedId] = _toSortedSerializedIds(v, idFor);
    });
    return map;
  }

  @override
  Map visitAll(AllInfo info) {
    var elements = _visitAllInfoElements(info);
    var jsonHolding = _visitAllInfoHolding(info);
    var jsonDependencies = _visitAllInfoDependencies(info);
    return {
      'dump_version': isBackwardCompatible ? 5 : info.version,
      'dump_minor_version': isBackwardCompatible ? 1 : info.minorVersion,
      'program': info.program!.accept(this),
      'elements': elements,
      'holding': jsonHolding,
      'dependencies': jsonDependencies,
      'outputUnits': info.outputUnits.map((u) => u.accept(this)).toList(),
      'deferredFiles': info.deferredFiles,
    };
  }

  @override
  Map visitProgram(ProgramInfo info) {
    return {
      'entrypoint': idFor(info.entrypoint).serializedId,
      'size': info.size,
      'ramUsage': info.ramUsage,
      'dart2jsVersion': info.dart2jsVersion,
      'compilationMoment': '${info.compilationMoment}',
      'compilationDuration': info.compilationDuration.inMicroseconds,
      'toJsonDuration': info.toJsonDuration.inMicroseconds,
      'dumpInfoDuration': info.dumpInfoDuration.inMicroseconds,
      'noSuchMethodEnabled': info.noSuchMethodEnabled,
      'isRuntimeTypeUsed': info.isRuntimeTypeUsed,
      'isIsolateInUse': info.isIsolateInUse,
      'isFunctionApplyUsed': info.isFunctionApplyUsed,
      'isMirrorsUsed': info.isMirrorsUsed,
      'minified': info.minified,
    };
  }

  Map _visitBasicInfo(BasicInfo info) {
    var res = {
      'id': idFor(info).serializedId,
      'kind': kindToString(info.kind),
      'name': info.name,
      'size': info.size,
    };
    // TODO(sigmund): Omit this also when outputUnit.id == 0 (most code is in
    // the main output unit by default).
    if (info.outputUnit != null) {
      res['outputUnit'] = idFor(info.outputUnit!).serializedId;
    }
    if (info.coverageId != null) res['coverageId'] = info.coverageId;
    if (info.parent != null) res['parent'] = idFor(info.parent!).serializedId;
    return res;
  }

  @override
  Map visitLibrary(LibraryInfo info) {
    return _visitBasicInfo(info)
      ..addAll(<String, Object>{
        'children': _toSortedSerializedIds([
          ...info.topLevelFunctions,
          ...info.topLevelVariables,
          ...info.classes,
          ...info.classTypes,
          ...info.typedefs
        ], idFor),
        'canonicalUri': '${info.uri}',
      });
  }

  @override
  Map visitClass(ClassInfo info) {
    return _visitBasicInfo(info)
      ..addAll(<String, Object>{
        // TODO(sigmund): change format, include only when abstract is true.
        'modifiers': {'abstract': info.isAbstract},
        'children':
            _toSortedSerializedIds([...info.fields, ...info.functions], idFor),
        'supers': _toSortedSerializedIds(info.supers, idFor)
      });
  }

  @override
  Map visitClassType(ClassTypeInfo info) {
    return _visitBasicInfo(info);
  }

  @override
  Map visitField(FieldInfo info) {
    var result = _visitBasicInfo(info)
      ..addAll(<String, Object>{
        'children': _toSortedSerializedIds(info.closures, idFor),
        'inferredType': info.inferredType,
        'code': _serializeCode(info.code),
        'type': info.type,
      });
    if (info.isConst) {
      result['const'] = true;
      if (info.initializer != null) {
        result['initializer'] = idFor(info.initializer!).serializedId;
      }
    }
    return result;
  }

  @override
  Map visitConstant(ConstantInfo info) => _visitBasicInfo(info)
    ..addAll(<String, Object>{'code': _serializeCode(info.code)});

  // TODO(sigmund): exclude false values (requires bumping the format version):
  //     var res = <String, bool>{};
  //     if (isStatic) res['static'] = true;
  //     if (isConst) res['const'] = true;
  //     if (isFactory) res['factory'] = true;
  //     if (isExternal) res['external'] = true;
  //     return res;
  Map _visitFunctionModifiers(FunctionModifiers mods) => {
        'static': mods.isStatic,
        'const': mods.isConst,
        'factory': mods.isFactory,
        'external': mods.isExternal,
      };

  Map _visitParameterInfo(ParameterInfo info) =>
      {'name': info.name, 'type': info.type, 'declaredType': info.declaredType};

  @override
  Map visitFunction(FunctionInfo info) {
    return _visitBasicInfo(info)
      ..addAll(<String, Object?>{
        'children': _toSortedSerializedIds(info.closures, idFor),
        'modifiers': _visitFunctionModifiers(info.modifiers),
        'returnType': info.returnType,
        'inferredReturnType': info.inferredReturnType,
        'parameters':
            info.parameters.map((p) => _visitParameterInfo(p)).toList(),
        'sideEffects': info.sideEffects,
        'inlinedCount': info.inlinedCount,
        'code': _serializeCode(info.code),
        'type': info.type,
        'functionKind': info.functionKind,
        // Note: version 3.2 of dump-info serializes `uses` in a section called
        // `holding` at the top-level.
      });
  }

  @override
  Map visitClosure(ClosureInfo info) {
    return _visitBasicInfo(info)
      ..addAll(<String, Object>{'function': idFor(info.function).serializedId});
  }

  @override
  Map visitTypedef(TypedefInfo info) =>
      _visitBasicInfo(info)..['type'] = info.type;

  @override
  Map visitOutput(OutputUnitInfo info) => _visitBasicInfo(info)
    ..['filename'] = info.filename
    ..['imports'] = info.imports;

  Object _serializeCode(List<CodeSpan> code) {
    if (isBackwardCompatible) {
      return code.map((c) => c.text).join('\n');
    }
    return code
        .map<Object>((c) => {
              'start': c.start,
              'end': c.end,
              'text': c.text,
            })
        .toList();
  }

  List<String> _toSortedSerializedIds(
          Iterable<Info> infos, Id Function(Info) getId) =>
      infos.map((i) => getId(i).serializedId).toList()..sort(compareNatural);
}

class AllInfoJsonCodec extends Codec<AllInfo, Map> {
  @override
  final Converter<AllInfo, Map> encoder;
  @override
  final Converter<Map, AllInfo> decoder = JsonToAllInfoConverter();

  AllInfoJsonCodec({bool isBackwardCompatible = false})
      : encoder =
            AllInfoToJsonConverter(isBackwardCompatible: isBackwardCompatible);
}

class Id {
  final InfoKind kind;
  final String id;

  Id(this.kind, this.id);

  String get serializedId => '${kindToString(kind)}/$id';
}
