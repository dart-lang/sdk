// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';

/// Unlinked information about a compilation unit.
class AnalysisDriverUnlinkedUnit {
  /// Set of class member names defined by the unit.
  final Set<String> definedClassMemberNames;

  /// Set of top-level names defined by the unit.
  final Set<String> definedTopLevelNames;

  /// Set of external names referenced by the unit.
  final Set<String> referencedNames;

  /// Set of names which are used in `extends`, `with` or `implements` clauses
  /// in the file. Import prefixes and type arguments are not included.
  final Set<String> subtypedNames;

  /// Unlinked information for the unit.
  final UnlinkedUnit unit;

  AnalysisDriverUnlinkedUnit({
    required this.definedClassMemberNames,
    required this.definedTopLevelNames,
    required this.referencedNames,
    required this.subtypedNames,
    required this.unit,
  });

  factory AnalysisDriverUnlinkedUnit.fromBytes(Uint8List bytes) {
    return AnalysisDriverUnlinkedUnit.read(
      SummaryDataReader(bytes),
    );
  }

  factory AnalysisDriverUnlinkedUnit.read(SummaryDataReader reader) {
    return AnalysisDriverUnlinkedUnit(
      definedClassMemberNames: reader.readStringUtf8Set(),
      definedTopLevelNames: reader.readStringUtf8Set(),
      referencedNames: reader.readStringUtf8Set(),
      subtypedNames: reader.readStringUtf8Set(),
      unit: UnlinkedUnit.read(reader),
    );
  }

  Uint8List toBytes() {
    var byteSink = ByteSink();
    var sink = BufferedSink(byteSink);
    write(sink);
    return sink.flushAndTake();
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8Iterable(definedClassMemberNames);
    sink.writeStringUtf8Iterable(definedTopLevelNames);
    sink.writeStringUtf8Iterable(referencedNames);
    sink.writeStringUtf8Iterable(subtypedNames);
    unit.write(sink);
  }
}

/// Unlinked information about a `macro` class.
class MacroClass {
  final String name;
  final List<String> constructors;

  MacroClass({
    required this.name,
    required this.constructors,
  });

  factory MacroClass.read(
    SummaryDataReader reader,
  ) {
    return MacroClass(
      name: reader.readStringUtf8(),
      constructors: reader.readStringUtf8List(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    sink.writeStringUtf8Iterable(constructors);
  }
}

class UnlinkedCombinator {
  final int keywordOffset;
  final int endOffset;
  final bool isShow;
  final List<String> names;

  UnlinkedCombinator({
    required this.keywordOffset,
    required this.endOffset,
    required this.isShow,
    required this.names,
  });

  factory UnlinkedCombinator.read(SummaryDataReader reader) {
    return UnlinkedCombinator(
      keywordOffset: reader.readUInt30(),
      endOffset: reader.readUInt30(),
      isShow: reader.readBool(),
      names: reader.readStringUtf8List(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUInt30(keywordOffset);
    sink.writeUInt30(endOffset);
    sink.writeBool(isShow);
    sink.writeStringUtf8Iterable(names);
  }
}

/// Unlinked information about an `export` directive.
class UnlinkedExportDirective extends UnlinkedNamespaceDirective {
  final int exportKeywordOffset;

  UnlinkedExportDirective({
    required super.combinators,
    required super.configurations,
    required this.exportKeywordOffset,
    required super.uri,
  });

  factory UnlinkedExportDirective.read(SummaryDataReader reader) {
    return UnlinkedExportDirective(
      combinators: reader.readTypedList(
        () => UnlinkedCombinator.read(reader),
      ),
      configurations: reader.readTypedList(
        () => UnlinkedNamespaceDirectiveConfiguration.read(reader),
      ),
      exportKeywordOffset: reader.readUInt30(),
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList<UnlinkedCombinator>(
      combinators,
      (x) => x.write(sink),
    );
    sink.writeList<UnlinkedNamespaceDirectiveConfiguration>(
      configurations,
      (x) {
        x.write(sink);
      },
    );
    sink.writeUInt30(exportKeywordOffset);
    sink.writeOptionalStringUtf8(uri);
  }
}

class UnlinkedImportAugmentationDirective {
  final String? uri;

  UnlinkedImportAugmentationDirective({
    required this.uri,
  });

  factory UnlinkedImportAugmentationDirective.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedImportAugmentationDirective(
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalStringUtf8(uri);
  }
}

/// Unlinked information about an 'import' directive.
class UnlinkedImportDirective extends UnlinkedNamespaceDirective {
  final int importKeywordOffset;
  final bool isSyntheticDartCore;
  final UnlinkedImportDirectivePrefix? prefix;

  UnlinkedImportDirective({
    required super.combinators,
    required super.configurations,
    required this.importKeywordOffset,
    this.isSyntheticDartCore = false,
    required this.prefix,
    required super.uri,
  });

  factory UnlinkedImportDirective.read(SummaryDataReader reader) {
    return UnlinkedImportDirective(
      combinators: reader.readTypedList(
        () => UnlinkedCombinator.read(reader),
      ),
      configurations: reader.readTypedList(
        () => UnlinkedNamespaceDirectiveConfiguration.read(reader),
      ),
      importKeywordOffset: reader.readUInt30() - 1,
      isSyntheticDartCore: reader.readBool(),
      prefix: reader.readOptionalObject(
        UnlinkedImportDirectivePrefix.read,
      ),
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList<UnlinkedCombinator>(
      combinators,
      (x) => x.write(sink),
    );
    sink.writeList<UnlinkedNamespaceDirectiveConfiguration>(
      configurations,
      (x) {
        x.write(sink);
      },
    );
    sink.writeUInt30(1 + importKeywordOffset);
    sink.writeBool(isSyntheticDartCore);
    sink.writeOptionalObject<UnlinkedImportDirectivePrefix>(
      prefix,
      (x) => x.write(sink),
    );
    sink.writeOptionalStringUtf8(uri);
  }
}

class UnlinkedImportDirectivePrefix {
  final int? deferredOffset;
  final int asOffset;
  final String name;
  final int nameOffset;

  UnlinkedImportDirectivePrefix({
    required this.deferredOffset,
    required this.asOffset,
    required this.name,
    required this.nameOffset,
  });

  factory UnlinkedImportDirectivePrefix.read(SummaryDataReader reader) {
    return UnlinkedImportDirectivePrefix(
      deferredOffset: reader.readOptionalUInt30(),
      asOffset: reader.readUInt30(),
      name: reader.readStringUtf8(),
      nameOffset: reader.readUInt30(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalUInt30(deferredOffset);
    sink.writeUInt30(asOffset);
    sink.writeStringUtf8(name);
    sink.writeUInt30(nameOffset);
  }
}

class UnlinkedLibraryAugmentationDirective {
  final String? uri;
  final UnlinkedSourceRange uriRange;

  UnlinkedLibraryAugmentationDirective({
    required this.uri,
    required this.uriRange,
  });

  factory UnlinkedLibraryAugmentationDirective.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedLibraryAugmentationDirective(
      uri: reader.readOptionalStringUtf8(),
      uriRange: UnlinkedSourceRange.read(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalStringUtf8(uri);
    uriRange.write(sink);
  }
}

class UnlinkedLibraryDirective {
  final String name;

  UnlinkedLibraryDirective({
    required this.name,
  });

  factory UnlinkedLibraryDirective.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedLibraryDirective(
      name: reader.readStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
  }
}

abstract class UnlinkedNamespaceDirective {
  final List<UnlinkedCombinator> combinators;
  final List<UnlinkedNamespaceDirectiveConfiguration> configurations;
  final String? uri;

  UnlinkedNamespaceDirective({
    required this.combinators,
    required this.configurations,
    required this.uri,
  });
}

/// Unlinked information about a namespace directive configuration.
class UnlinkedNamespaceDirectiveConfiguration {
  /// The name of the declared variable used in the condition.
  final String name;

  /// The URI to be used if the condition is true.
  final String? uri;

  /// The value to which the value of the declared variable will be compared,
  /// or the empty string if the condition does not include an equality test.
  final String value;

  UnlinkedNamespaceDirectiveConfiguration({
    required this.name,
    required this.uri,
    required this.value,
  });

  factory UnlinkedNamespaceDirectiveConfiguration.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedNamespaceDirectiveConfiguration(
      name: reader.readStringUtf8(),
      uri: reader.readOptionalStringUtf8(),
      value: reader.readStringUtf8(),
    );
  }

  String get valueOrTrue {
    if (value.isEmpty) {
      return 'true';
    } else {
      return value;
    }
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    sink.writeOptionalStringUtf8(uri);
    sink.writeStringUtf8(value);
  }
}

class UnlinkedPartDirective {
  final String? uri;

  UnlinkedPartDirective({
    required this.uri,
  });

  factory UnlinkedPartDirective.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedPartDirective(
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalStringUtf8(uri);
  }
}

class UnlinkedPartOfNameDirective {
  final String name;
  final UnlinkedSourceRange nameRange;

  UnlinkedPartOfNameDirective({
    required this.name,
    required this.nameRange,
  });

  factory UnlinkedPartOfNameDirective.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedPartOfNameDirective(
      name: reader.readStringUtf8(),
      nameRange: UnlinkedSourceRange.read(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    nameRange.write(sink);
  }
}

class UnlinkedPartOfUriDirective {
  final String? uri;
  final UnlinkedSourceRange uriRange;

  UnlinkedPartOfUriDirective({
    required this.uri,
    required this.uriRange,
  });

  factory UnlinkedPartOfUriDirective.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedPartOfUriDirective(
      uri: reader.readOptionalStringUtf8(),
      uriRange: UnlinkedSourceRange.read(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalStringUtf8(uri);
    uriRange.write(sink);
  }
}

class UnlinkedSourceRange {
  final int offset;
  final int length;

  UnlinkedSourceRange({
    required this.offset,
    required this.length,
  }) {
    RangeError.checkNotNegative(offset);
    RangeError.checkNotNegative(length);
  }

  factory UnlinkedSourceRange.read(
    SummaryDataReader reader,
  ) {
    return UnlinkedSourceRange(
      offset: reader.readUInt30(),
      length: reader.readUInt30(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUInt30(offset);
    sink.writeUInt30(length);
  }
}

/// Unlinked information about a compilation unit.
class UnlinkedUnit {
  /// The MD5 hash signature of the API portion of this unit. It depends on all
  /// tokens that might affect APIs of declarations in the unit.
  /// TODO(scheglov) Do we need it?
  final Uint8List apiSignature;

  /// `import augmentation` directives.
  final List<UnlinkedImportAugmentationDirective> augmentations;

  /// `export` directives.
  final List<UnlinkedExportDirective> exports;

  /// `import` directives.
  final List<UnlinkedImportDirective> imports;

  /// Encoded informative data.
  final Uint8List informativeBytes;

  /// The `library augment 'uri';` directive.
  final UnlinkedLibraryAugmentationDirective? libraryAugmentationDirective;

  /// The `library name;` directive.
  final UnlinkedLibraryDirective? libraryDirective;

  /// Offsets of the first character of each line in the source code.
  final Uint32List lineStarts;

  /// The list of `macro` classes.
  final List<MacroClass> macroClasses;

  /// `part` directives.
  final List<UnlinkedPartDirective> parts;

  /// The `part of my.name';` directive.
  final UnlinkedPartOfNameDirective? partOfNameDirective;

  /// The `part of 'uri';` directive.
  final UnlinkedPartOfUriDirective? partOfUriDirective;

  /// Top-level declarations of the unit.
  final Set<String> topLevelDeclarations;

  UnlinkedUnit({
    required this.apiSignature,
    required this.augmentations,
    required this.exports,
    required this.imports,
    required this.informativeBytes,
    required this.libraryAugmentationDirective,
    required this.libraryDirective,
    required this.lineStarts,
    required this.macroClasses,
    required this.parts,
    required this.partOfNameDirective,
    required this.partOfUriDirective,
    required this.topLevelDeclarations,
  });

  factory UnlinkedUnit.read(SummaryDataReader reader) {
    return UnlinkedUnit(
      apiSignature: reader.readUint8List(),
      augmentations: reader.readTypedList(
        () => UnlinkedImportAugmentationDirective.read(reader),
      ),
      exports: reader.readTypedList(
        () => UnlinkedExportDirective.read(reader),
      ),
      imports: reader.readTypedList(
        () => UnlinkedImportDirective.read(reader),
      ),
      informativeBytes: reader.readUint8List(),
      libraryAugmentationDirective: reader.readOptionalObject(
        UnlinkedLibraryAugmentationDirective.read,
      ),
      libraryDirective: reader.readOptionalObject(
        UnlinkedLibraryDirective.read,
      ),
      lineStarts: reader.readUInt30List(),
      macroClasses: reader.readTypedList(
        () => MacroClass.read(reader),
      ),
      parts: reader.readTypedList(
        () => UnlinkedPartDirective.read(reader),
      ),
      partOfNameDirective: reader.readOptionalObject(
        UnlinkedPartOfNameDirective.read,
      ),
      partOfUriDirective: reader.readOptionalObject(
        UnlinkedPartOfUriDirective.read,
      ),
      topLevelDeclarations: reader.readStringUtf8Set(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint8List(apiSignature);
    sink.writeList<UnlinkedImportAugmentationDirective>(augmentations, (x) {
      x.write(sink);
    });
    sink.writeList<UnlinkedExportDirective>(exports, (x) {
      x.write(sink);
    });
    sink.writeList<UnlinkedImportDirective>(imports, (x) {
      x.write(sink);
    });
    sink.writeUint8List(informativeBytes);
    sink.writeOptionalObject<UnlinkedLibraryAugmentationDirective>(
      libraryAugmentationDirective,
      (x) => x.write(sink),
    );
    sink.writeOptionalObject<UnlinkedLibraryDirective>(
      libraryDirective,
      (x) => x.write(sink),
    );
    sink.writeUint30List(lineStarts);
    sink.writeList<MacroClass>(macroClasses, (x) {
      x.write(sink);
    });
    sink.writeList<UnlinkedPartDirective>(parts, (x) {
      x.write(sink);
    });
    sink.writeOptionalObject<UnlinkedPartOfNameDirective>(
      partOfNameDirective,
      (x) => x.write(sink),
    );
    sink.writeOptionalObject<UnlinkedPartOfUriDirective>(
      partOfUriDirective,
      (x) => x.write(sink),
    );
    sink.writeStringUtf8Iterable(topLevelDeclarations);
  }
}
