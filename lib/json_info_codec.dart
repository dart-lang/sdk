// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Converters and codecs for converting between JSON and [Info] classes.
part of dart2js_info.info;

List<String> _toSortedSerializIds(Iterable<Info> infos) =>
    infos.map((i) => i.serializedId).toList()..sort(compareNatural);

// TODO(sigmund): add unit tests.
class JsonToAllInfoConverter extends Converter<Map<String, dynamic>, AllInfo> {
  // Using `SplayTreeMap` here because it's faster than the
  // default `LinkedHashMap`.
  final Map<String, Info> registry =
      new SplayTreeMap<String, Info>(compareNatural);

  AllInfo convert(Map<String, dynamic> json) {
    registry.clear();

    var result = new AllInfo();
    var elements = json['elements'];
    // TODO(srawlins): Since only the Map values are being extracted below,
    // replace `as` with `cast` when `cast` becomes available in Dart 2.0:
    //
    //     .addAll(elements['library'].values.cast<Map>().map(parseLibrary));
    result.libraries.addAll(
        (elements['library'] as Map).values.map((l) => parseLibrary(l)));
    result.classes
        .addAll((elements['class'] as Map).values.map((c) => parseClass(c)));
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

    var idMap = new SplayTreeMap<String, Info>(compareNatural);
    for (var f in result.functions) {
      idMap[f.serializedId] = f;
    }
    for (var f in result.fields) {
      idMap[f.serializedId] = f;
    }

    json['holding'].forEach((k, deps) {
      var src = idMap[k];
      assert(src != null);
      for (var dep in deps) {
        var target = idMap[dep['id']];
        assert(target != null);
        (src as CodeInfo).uses.add(new DependencyInfo(target, dep['mask']));
      }
    });

    json['dependencies']?.forEach((String k, List<String> deps) {
      result.dependencies[idMap[k]] = deps.map((d) => idMap[d]).toList();
    });

    result.outputUnits
        .addAll((json['outputUnits'] as List).map((o) => parseOutputUnit(o)));

    result.program = parseProgram(json['program']);
    // todo: version, etc
    return result;
  }

  OutputUnitInfo parseOutputUnit(Map json) {
    OutputUnitInfo result = parseId(json['id']);
    result
      ..name = json['name']
      ..size = json['size'];
    result.imports
        .addAll((json['imports'] as List).map((s) => s as String) ?? const []);
    return result;
  }

  LibraryInfo parseLibrary(Map json) {
    LibraryInfo result = parseId(json['id']);
    result
      ..name = json['name']
      ..uri = Uri.parse(json['canonicalUri'])
      ..outputUnit = parseId(json['outputUnit'])
      ..size = json['size'];
    for (var child in json['children'].map(parseId)) {
      if (child is FunctionInfo) {
        result.topLevelFunctions.add(child);
      } else if (child is FieldInfo) {
        result.topLevelVariables.add(child);
      } else if (child is ClassInfo) {
        result.classes.add(child);
      } else {
        assert(child is TypedefInfo);
        result.typedefs.add(child);
      }
    }
    return result;
  }

  ClassInfo parseClass(Map json) {
    ClassInfo result = parseId(json['id']);
    result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..outputUnit = parseId(json['outputUnit'])
      ..size = json['size']
      ..isAbstract = json['modifiers']['abstract'] == true;
    assert(result is ClassInfo);
    for (var child in json['children'].map(parseId)) {
      if (child is FunctionInfo) {
        result.functions.add(child);
      } else {
        assert(child is FieldInfo);
        result.fields.add(child);
      }
    }
    return result;
  }

  FieldInfo parseField(Map json) {
    FieldInfo result = parseId(json['id']);
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..coverageId = json['coverageId']
      ..outputUnit = parseId(json['outputUnit'])
      ..size = json['size']
      ..type = json['type']
      ..inferredType = json['inferredType']
      ..code = json['code']
      ..isConst = json['const'] ?? false
      ..initializer = parseId(json['initializer'])
      ..closures = (json['children'] as List).map((c) => parseId(c)).toList();
  }

  ConstantInfo parseConstant(Map json) {
    ConstantInfo result = parseId(json['id']);
    return result
      ..code = json['code']
      ..size = json['size']
      ..outputUnit = parseId(json['outputUnit']);
  }

  TypedefInfo parseTypedef(Map json) {
    TypedefInfo result = parseId(json['id']);
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..type = json['type']
      ..size = 0;
  }

  ProgramInfo parseProgram(Map json) {
    var programInfo = new ProgramInfo()
      ..entrypoint = parseId(json['entrypoint'])
      ..size = json['size']
      ..compilationMoment = DateTime.parse(json['compilationMoment'])
      ..dart2jsVersion = json['dart2jsVersion']
      ..noSuchMethodEnabled = json['noSuchMethodEnabled']
      ..isRuntimeTypeUsed = json['isRuntimeTypeUsed']
      ..isIsolateInUse = json['isIsolateInUse']
      ..isFunctionApplyUsed = json['isFunctionApplyUsed']
      ..isMirrorsUsed = json['isMirrorsUsed']
      ..minified = json['minified'];

    // TODO(het): Revert this when the dart2js with the new codec is in stable
    var compilationDuration = json['compilationDuration'];
    if (compilationDuration is String) {
      programInfo.compilationDuration = _parseDuration(compilationDuration);
    } else {
      assert(compilationDuration is int);
      programInfo.compilationDuration =
          new Duration(microseconds: compilationDuration);
    }

    var toJsonDuration = json['toJsonDuration'];
    if (toJsonDuration is String) {
      programInfo.toJsonDuration = _parseDuration(toJsonDuration);
    } else {
      assert(toJsonDuration is int);
      programInfo.toJsonDuration = new Duration(microseconds: toJsonDuration);
    }

    var dumpInfoDuration = json['dumpInfoDuration'];
    if (dumpInfoDuration is String) {
      programInfo.dumpInfoDuration = _parseDuration(dumpInfoDuration);
    } else {
      assert(dumpInfoDuration is int);
      programInfo.dumpInfoDuration =
          new Duration(microseconds: dumpInfoDuration);
    }

    return programInfo;
  }

  /// Parse a string formatted as "XX:YY:ZZ.ZZZZZ" into a [Duration].
  Duration _parseDuration(String duration) {
    if (!duration.contains(':')) {
      return new Duration(milliseconds: int.parse(duration));
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
    return new Duration(milliseconds: totalMillis.round());
  }

  FunctionInfo parseFunction(Map json) {
    FunctionInfo result = parseId(json['id']);
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..coverageId = json['coverageId']
      ..outputUnit = parseId(json['outputUnit'])
      ..size = json['size']
      ..type = json['type']
      ..returnType = json['returnType']
      ..inferredReturnType = json['inferredReturnType']
      ..parameters =
          (json['parameters'] as List).map((p) => parseParameter(p)).toList()
      ..code = json['code']
      ..sideEffects = json['sideEffects']
      ..modifiers =
          parseModifiers(new Map<String, bool>.from(json['modifiers']))
      ..closures = (json['children'] as List).map((p) => parseId(p)).toList()
      ..measurements = parseMeasurements(json['measurements']);
  }

  ParameterInfo parseParameter(Map json) =>
      new ParameterInfo(json['name'], json['type'], json['declaredType']);

  Measurements parseMeasurements(Map json) {
    if (json == null) return null;
    var uri = json['sourceFile'];
    var res = new Measurements(uri == null ? null : Uri.parse(uri));
    for (var key in json.keys) {
      var value = json[key];
      if (value == null) continue;
      if (key == 'entries') {
        value.forEach((metricName, entries) {
          var metric = new Metric.fromName(metricName);
          for (var i = 0; i < entries.length; i += 2) {
            res.record(metric, entries[i], entries[i + 1]);
          }
        });
      } else {
        res.counters[new Metric.fromName(key)] = value;
      }
    }
    return res;
  }

  FunctionModifiers parseModifiers(Map<String, bool> json) {
    return new FunctionModifiers(
        isStatic: json['static'] == true,
        isConst: json['const'] == true,
        isFactory: json['factory'] == true,
        isExternal: json['external'] == true);
  }

  ClosureInfo parseClosure(Map json) {
    ClosureInfo result = parseId(json['id']);
    return result
      ..name = json['name']
      ..parent = parseId(json['parent'])
      ..outputUnit = parseId(json['outputUnit'])
      ..size = json['size']
      ..function = parseId(json['function']);
  }

  Info parseId(String serializedId) {
    if (serializedId == null) {
      return null;
    }
    return registry.putIfAbsent(serializedId, () {
      if (serializedId.startsWith('function/')) {
        return new FunctionInfo._(serializedId);
      } else if (serializedId.startsWith('closure/')) {
        return new ClosureInfo._(serializedId);
      } else if (serializedId.startsWith('library/')) {
        return new LibraryInfo._(serializedId);
      } else if (serializedId.startsWith('class/')) {
        return new ClassInfo._(serializedId);
      } else if (serializedId.startsWith('field/')) {
        return new FieldInfo._(serializedId);
      } else if (serializedId.startsWith('constant/')) {
        return new ConstantInfo._(serializedId);
      } else if (serializedId.startsWith('typedef/')) {
        return new TypedefInfo._(serializedId);
      } else if (serializedId.startsWith('outputUnit/')) {
        return new OutputUnitInfo._(serializedId);
      }
      assert(false);
    });
  }
}

class AllInfoToJsonConverter extends Converter<AllInfo, Map>
    implements InfoVisitor<Map> {
  Map convert(AllInfo info) => info.accept(this);

  Map _visitList(List<Info> infos) {
    // Using SplayTree to maintain a consistent order of keys
    var map = new SplayTreeMap<String, Map>(compareNatural);
    for (var info in infos) {
      map['${info.id}'] = info.accept(this);
    }
    return map;
  }

  Map _visitAllInfoElements(AllInfo info) {
    var jsonLibraries = _visitList(info.libraries);
    var jsonClasses = _visitList(info.classes);
    var jsonFunctions = _visitList(info.functions);
    var jsonTypedefs = _visitList(info.typedefs);
    var jsonFields = _visitList(info.fields);
    var jsonConstants = _visitList(info.constants);
    var jsonClosures = _visitList(info.closures);
    return {
      'library': jsonLibraries,
      'class': jsonClasses,
      'function': jsonFunctions,
      'typedef': jsonTypedefs,
      'field': jsonFields,
      'constant': jsonConstants,
      'closure': jsonClosures,
    };
  }

  Map _visitDependencyInfo(DependencyInfo info) =>
      {'id': info.target.serializedId, 'mask': info.mask};

  Map _visitAllInfoHolding(AllInfo allInfo) {
    var map = new SplayTreeMap<String, List>(compareNatural);
    void helper(CodeInfo info) {
      if (info.uses.isEmpty) return;
      map[info.serializedId] = info.uses.map(_visitDependencyInfo).toList();
    }

    allInfo.functions.forEach(helper);
    allInfo.fields.forEach(helper);
    return map;
  }

  Map _visitAllInfoDependencies(AllInfo allInfo) {
    var map = new SplayTreeMap<String, List>(compareNatural);
    allInfo.dependencies.forEach((k, v) {
      map[k.serializedId] = _toSortedSerializIds(v);
    });
    return map;
  }

  Map visitAll(AllInfo info) {
    var elements = _visitAllInfoElements(info);
    var jsonHolding = _visitAllInfoHolding(info);
    var jsonDependencies = _visitAllInfoDependencies(info);
    return {
      'elements': elements,
      'holding': jsonHolding,
      'dependencies': jsonDependencies,
      'outputUnits': info.outputUnits.map((u) => u.accept(this)).toList(),
      'dump_version': info.version,
      'deferredFiles': info.deferredFiles,
      'dump_minor_version': info.minorVersion,
      'program': info.program.accept(this)
    };
  }

  Map visitProgram(ProgramInfo info) {
    return {
      'entrypoint': info.entrypoint.serializedId,
      'size': info.size,
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
      'id': info.serializedId,
      'kind': kindToString(info.kind),
      'name': info.name,
      'size': info.size,
    };
    // TODO(sigmund): Omit this also when outputUnit.id == 0 (most code is in
    // the main output unit by default).
    if (info.outputUnit != null) {
      res['outputUnit'] = info.outputUnit.serializedId;
    }
    if (info.coverageId != null) res['coverageId'] = info.coverageId;
    if (info.parent != null) res['parent'] = info.parent.serializedId;
    return res;
  }

  Map visitLibrary(LibraryInfo info) {
    return _visitBasicInfo(info)
      ..addAll({
        'children': _toSortedSerializIds([
          info.topLevelFunctions,
          info.topLevelVariables,
          info.classes,
          info.typedefs
        ].expand((i) => i)),
        'canonicalUri': '${info.uri}',
      });
  }

  Map visitClass(ClassInfo info) {
    return _visitBasicInfo(info)
      ..addAll({
        // TODO(sigmund): change format, include only when abstract is true.
        'modifiers': {'abstract': info.isAbstract},
        'children':
            _toSortedSerializIds([info.fields, info.functions].expand((i) => i))
      });
  }

  Map visitField(FieldInfo info) {
    var result = _visitBasicInfo(info)
      ..addAll({
        'children': _toSortedSerializIds(info.closures),
        'inferredType': info.inferredType,
        'code': info.code,
        'type': info.type,
      });
    if (info.isConst) {
      result['const'] = true;
      if (info.initializer != null) {
        result['initializer'] = info.initializer.serializedId;
      }
    }
    return result;
  }

  Map visitConstant(ConstantInfo info) =>
      _visitBasicInfo(info)..addAll({'code': info.code});

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

  String _visitMetric(Metric metric) => metric.name;

  Map _visitMeasurements(Measurements measurements) {
    if (measurements == null) return null;
    var jsonEntries = <String, List<int>>{};
    measurements.entries.forEach((metric, values) {
      jsonEntries[_visitMetric(metric)] =
          values.expand((e) => [e.begin, e.end]).toList();
    });
    var json = <String, dynamic>{'entries': jsonEntries};
    // TODO(sigmund): encode uri as an offset of the URIs available in the parts
    // of the library info.
    if (measurements.uri != null) json['sourceFile'] = '${measurements.uri}';
    if (measurements.counters[Metric.functions] != null) {
      json[_visitMetric(Metric.functions)] =
          measurements.counters[Metric.functions];
    }
    if (measurements.counters[Metric.reachableFunctions] != null) {
      json[_visitMetric(Metric.reachableFunctions)] =
          measurements.counters[Metric.reachableFunctions];
    }
    return json;
  }

  Map visitFunction(FunctionInfo info) {
    return _visitBasicInfo(info)
      ..addAll({
        'children': _toSortedSerializIds(info.closures),
        'modifiers': _visitFunctionModifiers(info.modifiers),
        'returnType': info.returnType,
        'inferredReturnType': info.inferredReturnType,
        'parameters':
            info.parameters.map((p) => _visitParameterInfo(p)).toList(),
        'sideEffects': info.sideEffects,
        'inlinedCount': info.inlinedCount,
        'code': info.code,
        'type': info.type,
        'measurements': _visitMeasurements(info.measurements),
        // Note: version 3.2 of dump-info serializes `uses` in a section called
        // `holding` at the top-level.
      });
  }

  Map visitClosure(ClosureInfo info) {
    return _visitBasicInfo(info)
      ..addAll({'function': info.function.serializedId});
  }

  visitTypedef(TypedefInfo info) => _visitBasicInfo(info)..['type'] = info.type;

  visitOutput(OutputUnitInfo info) =>
      _visitBasicInfo(info)..['imports'] = info.imports;
}

class AllInfoJsonCodec extends Codec<AllInfo, Map> {
  final Converter<AllInfo, Map> encoder = new AllInfoToJsonConverter();
  final Converter<Map, AllInfo> decoder = new JsonToAllInfoConverter();
}
