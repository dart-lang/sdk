// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import '../common.dart';
import '../constants/values.dart'
    show ConstantValue, DeferredGlobalConstantValue;
import '../elements/entities.dart';
import '../serialization/serialization.dart';
import '../options.dart';

/// A "hunk" of the program that will be loaded whenever one of its [imports]
/// are loaded.
///
/// Elements that are only used in one deferred import, is in an OutputUnit with
/// the deferred import as single element in the [imports] set.
///
/// Whenever a deferred Element is shared between several deferred imports it is
/// in an output unit with those imports in the [imports] Set.
///
/// We never create two OutputUnits sharing the same set of [imports].
class OutputUnit implements Comparable<OutputUnit> {
  static const String tag = 'output-unit';

  /// `true` if this output unit is for the main output file.
  final bool isMainOutput;

  /// A unique name representing this [OutputUnit].
  final String name;

  /// The deferred imports that use the elements in this output unit.
  final Set<ImportEntity> imports;

  OutputUnit(this.isMainOutput, this.name, this.imports);

  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeBool(isMainOutput);
    sink.writeString(name);
    sink.writeImports(imports);
    sink.end(tag);
  }

  static OutputUnit readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    final isMainOutput = source.readBool();
    final name = source.readString();
    final imports = source.readImports().toSet();
    source.end(tag);
    return OutputUnit(isMainOutput, name, imports);
  }

  @override
  int compareTo(OutputUnit other) {
    if (identical(this, other)) return 0;
    if (isMainOutput && !other.isMainOutput) return -1;
    if (!isMainOutput && other.isMainOutput) return 1;
    var size = imports.length;
    var otherSize = other.imports.length;
    if (size != otherSize) return size.compareTo(otherSize);
    var thisImports = imports.toList();
    var otherImports = other.imports.toList();
    for (var i = 0; i < size; i++) {
      var cmp = compareImportEntities(thisImports[i], otherImports[i]);
      if (cmp != 0) return cmp;
    }
    // TODO(sigmund): make compare stable.  If we hit this point, all imported
    // libraries are the same, however [this] and [other] use different deferred
    // imports in the program. We can make this stable if we sort based on the
    // deferred imports themselves (e.g. their declaration location).
    return name.compareTo(other.name);
  }

  @override
  String toString() => "OutputUnit($name, $imports)";
}

int compareImportEntities(ImportEntity a, ImportEntity b) {
  if (a == b) {
    return 0;
  } else {
    return a.uri.path.compareTo(b.uri.path);
  }
}

/// Interface for updating an [OutputUnitData] object with data for late
/// members, that is, members created on demand during code generation.
class LateOutputUnitDataBuilder {
  final OutputUnitData _outputUnitData;

  LateOutputUnitDataBuilder(this._outputUnitData);

  /// Registers [newEntity] to be emitted in the same output unit as
  /// [existingEntity];
  void registerColocatedMembers(
      MemberEntity existingEntity, MemberEntity newEntity) {
    assert(_outputUnitData._memberToUnit[newEntity] == null);
    _outputUnitData._memberToUnit[newEntity] =
        _outputUnitData.outputUnitForMember(existingEntity);
  }
}

/// Results of the deferred loading algorithm.
///
/// Provides information about the output unit associated with entities and
/// constants, as well as other helper methods.
// TODO(sigmund): consider moving here every piece of data used as a result of
// deferred loading (including hunksToLoad, etc).
class OutputUnitData {
  /// Tag used for identifying serialized [OutputUnitData] objects in a
  /// debugging data stream.
  static const String tag = 'output-unit-data';

  final bool isProgramSplit;
  final OutputUnit mainOutputUnit;
  final Map<ClassEntity, OutputUnit> _classToUnit;
  final Map<ClassEntity, OutputUnit> _classTypeToUnit;
  final Map<MemberEntity, OutputUnit> _memberToUnit;
  final Map<Local, OutputUnit> _localFunctionToUnit;
  final Map<ConstantValue, OutputUnit> _constantToUnit;
  final List<OutputUnit> outputUnits;
  final Map<ImportEntity, String> importDeferName;

  /// Because the token-stream is forgotten later in the program, we cache a
  /// description of each deferred import.
  final Map<ImportEntity, ImportDescription> deferredImportDescriptions;

  OutputUnitData(
      this.isProgramSplit,
      this.mainOutputUnit,
      this._classToUnit,
      this._classTypeToUnit,
      this._memberToUnit,
      this._localFunctionToUnit,
      this._constantToUnit,
      this.outputUnits,
      this.importDeferName,
      this.deferredImportDescriptions);

  // Creates J-world data from the K-world data.
  factory OutputUnitData.from(
      OutputUnitData other,
      LibraryEntity convertLibrary(LibraryEntity library),
      Map<ClassEntity, OutputUnit> Function(
              Map<ClassEntity, OutputUnit>, Map<Local, OutputUnit>)
          convertClassMap,
      Map<MemberEntity, OutputUnit> Function(
              Map<MemberEntity, OutputUnit>, Map<Local, OutputUnit>)
          convertMemberMap,
      Map<ConstantValue, OutputUnit> Function(Map<ConstantValue, OutputUnit>)
          convertConstantMap) {
    Map<ClassEntity, OutputUnit> classToUnit =
        convertClassMap(other._classToUnit, other._localFunctionToUnit);
    Map<ClassEntity, OutputUnit> classTypeToUnit =
        convertClassMap(other._classTypeToUnit, other._localFunctionToUnit);
    Map<MemberEntity, OutputUnit> memberToUnit =
        convertMemberMap(other._memberToUnit, other._localFunctionToUnit);
    Map<ConstantValue, OutputUnit> constantToUnit =
        convertConstantMap(other._constantToUnit);
    Map<ImportEntity, ImportDescription> deferredImportDescriptions = {};
    other.deferredImportDescriptions
        .forEach((ImportEntity import, ImportDescription description) {
      deferredImportDescriptions[import] = ImportDescription.internal(
          description.importingUri,
          description.prefix,
          convertLibrary(description.importingLibrary));
    });

    return OutputUnitData(
        other.isProgramSplit,
        other.mainOutputUnit,
        classToUnit,
        classTypeToUnit,
        memberToUnit,
        // Local functions only make sense in the K-world model.
        const {},
        constantToUnit,
        other.outputUnits,
        other.importDeferName,
        deferredImportDescriptions);
  }

  /// Deserializes an [OutputUnitData] object from [source].
  factory OutputUnitData.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    bool isProgramSplit = source.readBool();
    List<OutputUnit> outputUnits =
        source.readList(source.readOutputUnitReference);
    OutputUnit mainOutputUnit = outputUnits[source.readInt()];

    Map<ClassEntity, OutputUnit> classToUnit = source.readClassMap(() {
      return outputUnits[source.readInt()];
    });
    Map<ClassEntity, OutputUnit> classTypeToUnit = source.readClassMap(() {
      return outputUnits[source.readInt()];
    });
    Map<MemberEntity, OutputUnit> memberToUnit =
        source.readMemberMap((MemberEntity member) {
      return outputUnits[source.readInt()];
    });
    Map<ConstantValue, OutputUnit> constantToUnit = source.readConstantMap(() {
      return outputUnits[source.readInt()];
    });
    Map<ImportEntity, String> importDeferName =
        source.readImportMap(source.readString);
    Map<ImportEntity, ImportDescription> deferredImportDescriptions =
        source.readImportMap(() {
      String importingUri = source.readString();
      String prefix = source.readString();
      LibraryEntity importingLibrary = source.readLibrary();
      return ImportDescription.internal(importingUri, prefix, importingLibrary);
    });
    source.end(tag);
    return OutputUnitData(
        isProgramSplit,
        mainOutputUnit,
        classToUnit,
        classTypeToUnit,
        memberToUnit,
        // Local functions only make sense in the K-world model.
        const {},
        constantToUnit,
        outputUnits,
        importDeferName,
        deferredImportDescriptions);
  }

  /// Serializes this [OutputUnitData] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeBool(isProgramSplit);
    Map<OutputUnit, int> outputUnitIndices = {};
    sink.writeList(outputUnits, (OutputUnit outputUnit) {
      outputUnitIndices[outputUnit] = outputUnitIndices.length;
      sink.writeOutputUnitReference(outputUnit);
    });
    sink.writeInt(outputUnitIndices[mainOutputUnit]!);
    sink.writeClassMap(_classToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]!);
    });
    sink.writeClassMap(_classTypeToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]!);
    });
    sink.writeMemberMap(_memberToUnit,
        (MemberEntity member, OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]!);
    });
    sink.writeConstantMap(_constantToUnit, (OutputUnit outputUnit) {
      sink.writeInt(outputUnitIndices[outputUnit]!);
    });
    sink.writeImportMap(importDeferName, sink.writeString);
    sink.writeImportMap(deferredImportDescriptions,
        (ImportDescription importDescription) {
      sink.writeString(importDescription.importingUri);
      sink.writeString(importDescription.prefix);
      sink.writeLibrary(importDescription.importingLibrary);
    });
    sink.end(tag);
  }

  /// Returns the [OutputUnit] where [cls] belongs.
  // TODO(johnniwinther): Remove the need for [allowNull]. Dump-info currently
  // needs it.
  OutputUnit outputUnitForClass(ClassEntity cls, {bool allowNull = false}) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit? unit = _classToUnit[cls];
    assert(allowNull || unit != null, 'No output unit for class $cls');
    return unit ?? mainOutputUnit;
  }

  OutputUnit? outputUnitForClassForTesting(ClassEntity cls) =>
      _classToUnit[cls];

  /// Returns the [OutputUnit] where [cls]'s type belongs.
  // TODO(joshualitt): see above TODO regarding allowNull.
  OutputUnit outputUnitForClassType(ClassEntity cls, {bool allowNull = false}) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit? unit = _classTypeToUnit[cls];
    assert(allowNull || unit != null, 'No output unit for type $cls');
    return unit ?? mainOutputUnit;
  }

  OutputUnit? outputUnitForClassTypeForTesting(ClassEntity cls) =>
      _classTypeToUnit[cls];

  /// Returns the [OutputUnit] where [member] belongs.
  OutputUnit outputUnitForMember(MemberEntity member) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit? unit = _memberToUnit[member];
    assert(unit != null, 'No output unit for member $member');
    return unit ?? mainOutputUnit;
  }

  OutputUnit? outputUnitForMemberForTesting(MemberEntity member) =>
      _memberToUnit[member];

  /// Direct access to the output-unit to constants map used for testing.
  Iterable<ConstantValue> get constantsForTesting => _constantToUnit.keys;

  /// Returns the [OutputUnit] where [constant] belongs.
  OutputUnit outputUnitForConstant(ConstantValue constant) {
    if (!isProgramSplit) return mainOutputUnit;
    OutputUnit? unit = _constantToUnit[constant];
    // TODO(sigmund): enforce unit is not null: it is sometimes null on some
    // corner cases on internal apps.
    return unit ?? mainOutputUnit;
  }

  OutputUnit? outputUnitForConstantForTesting(ConstantValue constant) =>
      _constantToUnit[constant];

  /// Indicates whether [element] is deferred.
  bool isDeferredClass(ClassEntity element) {
    return outputUnitForClass(element) != mainOutputUnit;
  }

  /// Returns `true` if element [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPaths(MemberEntity from, MemberEntity to) {
    OutputUnit outputUnitFrom = outputUnitForMember(from);
    OutputUnit outputUnitTo = outputUnitForMember(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo.imports.containsAll(outputUnitFrom.imports);
  }

  /// Returns `true` if constant [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPathsToConstant(
      MemberEntity from, ConstantValue to) {
    OutputUnit outputUnitFrom = outputUnitForMember(from);
    OutputUnit outputUnitTo = outputUnitForConstant(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo.imports.containsAll(outputUnitFrom.imports);
  }

  /// Returns `true` if class [to] is reachable from element [from] without
  /// crossing a deferred import.
  ///
  /// For example, if we have two deferred libraries `A` and `B` that both
  /// import a library `C`, then even though elements from `A` and `C` end up in
  /// different output units, there is a non-deferred path between `A` and `C`.
  bool hasOnlyNonDeferredImportPathsToClass(MemberEntity from, ClassEntity to) {
    OutputUnit outputUnitFrom = outputUnitForMember(from);
    OutputUnit outputUnitTo = outputUnitForClass(to);
    if (outputUnitTo == mainOutputUnit) return true;
    if (outputUnitFrom == mainOutputUnit) return false;
    return outputUnitTo.imports.containsAll(outputUnitFrom.imports);
  }

  /// Registers that a constant is used in the same deferred output unit as
  /// [field].
  void registerConstantDeferredUse(DeferredGlobalConstantValue constant) {
    if (!isProgramSplit) return;
    OutputUnit unit = constant.unit;
    assert(
        _constantToUnit[constant] == null || _constantToUnit[constant] == unit);
    _constantToUnit[constant] = unit;
  }

  /// Returns the unique name for the given deferred [import].
  String getImportDeferName(Spannable node, ImportEntity import) {
    String? name = importDeferName[import];
    if (name == null) {
      throw SpannableAssertionFailure(node, "No deferred name for $import.");
    }
    return name;
  }

  /// Returns the names associated with each deferred import in [unit].
  Iterable<String> getImportNames(OutputUnit unit) {
    return unit.imports.map((i) => importDeferName[i]!);
  }
}

class ImportDescription {
  /// Relative uri to the importing library.
  final String importingUri;

  /// The prefix this import is imported as.
  final String prefix;

  final LibraryEntity importingLibrary;

  ImportDescription.internal(
      this.importingUri, this.prefix, this.importingLibrary);

  ImportDescription(
      ImportEntity import, LibraryEntity importingLibrary, Uri mainLibraryUri)
      : this.internal(
            fe.relativizeUri(
                mainLibraryUri, importingLibrary.canonicalUri, false),
            import.name!,
            importingLibrary);
}

/// Returns the filename for the output-unit named [name].
///
/// The filename is of the form "<main output file>_<name>.part.js".
/// If [addExtension] is false, the ".part.js" suffix is left out.
String deferredPartFileName(CompilerOptions options, String name,
    {bool addExtension = true}) {
  assert(name != "");
  String outPath = options.outputUri != null ? options.outputUri!.path : "out";
  String outName = outPath.substring(outPath.lastIndexOf('/') + 1);
  String extension = addExtension ? ".part.js" : "";
  return "${outName}_$name$extension";
}
