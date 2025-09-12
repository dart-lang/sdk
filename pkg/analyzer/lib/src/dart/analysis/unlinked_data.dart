// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analyzer/src/binary/binary_reader.dart';
import 'package:analyzer/src/binary/binary_writer.dart';

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
    return AnalysisDriverUnlinkedUnit.read(SummaryDataReader(bytes));
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
    var sink = BufferedSink();
    write(sink);
    return sink.takeBytes();
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8Iterable(definedClassMemberNames);
    sink.writeStringUtf8Iterable(definedTopLevelNames);
    sink.writeStringUtf8Iterable(referencedNames);
    sink.writeStringUtf8Iterable(subtypedNames);
    unit.write(sink);
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
      keywordOffset: reader.readUint30(),
      endOffset: reader.readUint30(),
      isShow: reader.readBool(),
      names: reader.readStringUtf8List(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(keywordOffset);
    sink.writeUint30(endOffset);
    sink.writeBool(isShow);
    sink.writeStringUtf8Iterable(names);
  }
}

abstract class UnlinkedConfigurableUriDirective {
  final List<UnlinkedNamespaceDirectiveConfiguration> configurations;
  final String? uri;

  UnlinkedConfigurableUriDirective({
    required this.configurations,
    required this.uri,
  });
}

class UnlinkedDartdocTemplate {
  final String name;
  final String value;

  UnlinkedDartdocTemplate({required this.name, required this.value});

  factory UnlinkedDartdocTemplate.read(SummaryDataReader reader) {
    return UnlinkedDartdocTemplate(
      name: reader.readStringUtf8(),
      value: reader.readStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    sink.writeStringUtf8(value);
  }
}

class UnlinkedLibraryDirective {
  /// `@docImport` directives in the doc comment.
  final List<UnlinkedLibraryImportDirective> docImports;

  final String? name;

  UnlinkedLibraryDirective({required this.docImports, required this.name});

  factory UnlinkedLibraryDirective.read(SummaryDataReader reader) {
    return UnlinkedLibraryDirective(
      docImports: reader.readTypedList(
        () => UnlinkedLibraryImportDirective.read(reader),
      ),
      name: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList(docImports, (docImport) {
      docImport.write(sink);
    });
    sink.writeOptionalStringUtf8(name);
  }
}

/// Unlinked information about an `export` directive.
class UnlinkedLibraryExportDirective extends UnlinkedNamespaceDirective {
  final int exportKeywordOffset;

  UnlinkedLibraryExportDirective({
    required super.combinators,
    required super.configurations,
    required this.exportKeywordOffset,
    required super.uri,
  });

  factory UnlinkedLibraryExportDirective.read(SummaryDataReader reader) {
    return UnlinkedLibraryExportDirective(
      combinators: reader.readTypedList(() => UnlinkedCombinator.read(reader)),
      configurations: reader.readTypedList(
        () => UnlinkedNamespaceDirectiveConfiguration.read(reader),
      ),
      exportKeywordOffset: reader.readUint30(),
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList<UnlinkedCombinator>(combinators, (x) => x.write(sink));
    sink.writeList<UnlinkedNamespaceDirectiveConfiguration>(configurations, (
      x,
    ) {
      x.write(sink);
    });
    sink.writeUint30(exportKeywordOffset);
    sink.writeOptionalStringUtf8(uri);
  }
}

/// Unlinked information about an 'import' directive.
class UnlinkedLibraryImportDirective extends UnlinkedNamespaceDirective {
  final int importKeywordOffset;
  final bool isDocImport;
  final bool isSyntheticDartCore;
  final UnlinkedLibraryImportPrefix? prefix;

  UnlinkedLibraryImportDirective({
    required super.combinators,
    required super.configurations,
    required this.importKeywordOffset,
    required this.isDocImport,
    this.isSyntheticDartCore = false,
    required this.prefix,
    required super.uri,
  });

  factory UnlinkedLibraryImportDirective.read(SummaryDataReader reader) {
    return UnlinkedLibraryImportDirective(
      combinators: reader.readTypedList(() => UnlinkedCombinator.read(reader)),
      configurations: reader.readTypedList(
        () => UnlinkedNamespaceDirectiveConfiguration.read(reader),
      ),
      importKeywordOffset: reader.readUint30() - 1,
      isDocImport: reader.readBool(),
      isSyntheticDartCore: reader.readBool(),
      prefix: reader.readOptionalObject(
        () => UnlinkedLibraryImportPrefix.read(reader),
      ),
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList<UnlinkedCombinator>(combinators, (x) => x.write(sink));
    sink.writeList<UnlinkedNamespaceDirectiveConfiguration>(configurations, (
      x,
    ) {
      x.write(sink);
    });
    sink.writeUint30(1 + importKeywordOffset);
    sink.writeBool(isDocImport);
    sink.writeBool(isSyntheticDartCore);
    sink.writeOptionalObject<UnlinkedLibraryImportPrefix>(
      prefix,
      (x) => x.write(sink),
    );
    sink.writeOptionalStringUtf8(uri);
  }
}

class UnlinkedLibraryImportPrefix {
  final int? deferredOffset;
  final int asOffset;
  final int nameOffset;
  final UnlinkedLibraryImportPrefixName? name;

  UnlinkedLibraryImportPrefix({
    required this.deferredOffset,
    required this.asOffset,
    required this.nameOffset,
    required this.name,
  });

  factory UnlinkedLibraryImportPrefix.read(SummaryDataReader reader) {
    return UnlinkedLibraryImportPrefix(
      deferredOffset: reader.readOptionalUint30(),
      asOffset: reader.readUint30(),
      nameOffset: reader.readUint30(),
      name: reader.readOptionalObject(
        () => UnlinkedLibraryImportPrefixName.read(reader),
      ),
    );
  }

  void write(BufferedSink sink) {
    sink.writeOptionalUint30(deferredOffset);
    sink.writeUint30(asOffset);
    sink.writeUint30(nameOffset);
    sink.writeOptionalObject(name, (name) {
      name.write(sink);
    });
  }
}

class UnlinkedLibraryImportPrefixName {
  final String name;
  final int nameOffset;

  UnlinkedLibraryImportPrefixName({
    required this.name,
    required this.nameOffset,
  });

  factory UnlinkedLibraryImportPrefixName.read(SummaryDataReader reader) {
    return UnlinkedLibraryImportPrefixName(
      name: reader.readStringUtf8(),
      nameOffset: reader.readUint30(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeStringUtf8(name);
    sink.writeUint30(nameOffset);
  }
}

abstract class UnlinkedNamespaceDirective
    extends UnlinkedConfigurableUriDirective {
  final List<UnlinkedCombinator> combinators;

  UnlinkedNamespaceDirective({
    required this.combinators,
    required super.configurations,
    required super.uri,
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

class UnlinkedPartDirective extends UnlinkedConfigurableUriDirective {
  final int partKeywordOffset;

  UnlinkedPartDirective({
    required super.configurations,
    required this.partKeywordOffset,
    required super.uri,
  });

  factory UnlinkedPartDirective.read(SummaryDataReader reader) {
    return UnlinkedPartDirective(
      configurations: reader.readTypedList(
        () => UnlinkedNamespaceDirectiveConfiguration.read(reader),
      ),
      partKeywordOffset: reader.readUint30(),
      uri: reader.readOptionalStringUtf8(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList<UnlinkedNamespaceDirectiveConfiguration>(configurations, (
      x,
    ) {
      x.write(sink);
    });
    sink.writeUint30(partKeywordOffset);
    sink.writeOptionalStringUtf8(uri);
  }
}

class UnlinkedPartOfNameDirective {
  /// `@docImport` directives in the doc comment.
  final List<UnlinkedLibraryImportDirective> docImports;

  final String name;
  final UnlinkedSourceRange nameRange;

  UnlinkedPartOfNameDirective({
    required this.docImports,
    required this.name,
    required this.nameRange,
  });

  factory UnlinkedPartOfNameDirective.read(SummaryDataReader reader) {
    return UnlinkedPartOfNameDirective(
      docImports: reader.readTypedList(
        () => UnlinkedLibraryImportDirective.read(reader),
      ),
      name: reader.readStringUtf8(),
      nameRange: UnlinkedSourceRange.read(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList(docImports, (docImport) {
      docImport.write(sink);
    });
    sink.writeStringUtf8(name);
    nameRange.write(sink);
  }
}

class UnlinkedPartOfUriDirective {
  /// `@docImport` directives in the doc comment.
  final List<UnlinkedLibraryImportDirective> docImports;

  final String? uri;
  final UnlinkedSourceRange uriRange;

  UnlinkedPartOfUriDirective({
    required this.docImports,
    required this.uri,
    required this.uriRange,
  });

  factory UnlinkedPartOfUriDirective.read(SummaryDataReader reader) {
    return UnlinkedPartOfUriDirective(
      docImports: reader.readTypedList(
        () => UnlinkedLibraryImportDirective.read(reader),
      ),
      uri: reader.readOptionalStringUtf8(),
      uriRange: UnlinkedSourceRange.read(reader),
    );
  }

  void write(BufferedSink sink) {
    sink.writeList(docImports, (docImport) {
      docImport.write(sink);
    });
    sink.writeOptionalStringUtf8(uri);
    uriRange.write(sink);
  }
}

class UnlinkedSourceRange {
  final int offset;
  final int length;

  UnlinkedSourceRange({required this.offset, required this.length}) {
    RangeError.checkNotNegative(offset);
    RangeError.checkNotNegative(length);
  }

  factory UnlinkedSourceRange.read(SummaryDataReader reader) {
    return UnlinkedSourceRange(
      offset: reader.readUint30(),
      length: reader.readUint30(),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint30(offset);
    sink.writeUint30(length);
  }
}

/// Unlinked information about a compilation unit.
class UnlinkedUnit {
  /// The MD5 hash signature of the API portion of this unit. It depends on all
  /// tokens that might affect APIs of declarations in the unit.
  // TODO(scheglov): Do we need it?
  final Uint8List apiSignature;

  /// `export` directives.
  final List<UnlinkedLibraryExportDirective> exports;

  /// Whether this file has explicit `dart:core` import.
  final bool hasDartCoreImport;

  /// `import` directives.
  final List<UnlinkedLibraryImportDirective> imports;

  /// Encoded informative data.
  final Uint8List informativeBytes;

  /// Whether this file is `dart:core` library.
  final bool isDartCore;

  /// The `library name;` directive.
  final UnlinkedLibraryDirective? libraryDirective;

  /// Offsets of the first character of each line in the source code.
  final Uint32List lineStarts;

  /// `part` directives.
  final List<UnlinkedPartDirective> parts;

  /// The `part of my.name';` directive.
  final UnlinkedPartOfNameDirective? partOfNameDirective;

  /// The `part of 'uri';` directive.
  final UnlinkedPartOfUriDirective? partOfUriDirective;

  /// Top-level declarations of the unit.
  final Set<String> topLevelDeclarations;

  /// The Dartdoc templates of the unit.
  final List<UnlinkedDartdocTemplate> dartdocTemplates;

  UnlinkedUnit({
    required this.apiSignature,
    required this.exports,
    required this.hasDartCoreImport,
    required this.imports,
    required this.informativeBytes,
    required this.isDartCore,
    required this.libraryDirective,
    required this.lineStarts,
    required this.parts,
    required this.partOfNameDirective,
    required this.partOfUriDirective,
    required this.topLevelDeclarations,
    required this.dartdocTemplates,
  });

  factory UnlinkedUnit.read(SummaryDataReader reader) {
    return UnlinkedUnit(
      apiSignature: reader.readUint8List(),
      exports: reader.readTypedList(
        () => UnlinkedLibraryExportDirective.read(reader),
      ),
      hasDartCoreImport: reader.readBool(),
      imports: reader.readTypedList(
        () => UnlinkedLibraryImportDirective.read(reader),
      ),
      informativeBytes: reader.readUint8List(),
      isDartCore: reader.readBool(),
      libraryDirective: reader.readOptionalObject(
        () => UnlinkedLibraryDirective.read(reader),
      ),
      lineStarts: reader.readUint30List(),
      parts: reader.readTypedList(() => UnlinkedPartDirective.read(reader)),
      partOfNameDirective: reader.readOptionalObject(
        () => UnlinkedPartOfNameDirective.read(reader),
      ),
      partOfUriDirective: reader.readOptionalObject(
        () => UnlinkedPartOfUriDirective.read(reader),
      ),
      topLevelDeclarations: reader.readStringUtf8Set(),
      dartdocTemplates: reader.readTypedList(
        () => UnlinkedDartdocTemplate.read(reader),
      ),
    );
  }

  void write(BufferedSink sink) {
    sink.writeUint8List(apiSignature);
    sink.writeList<UnlinkedLibraryExportDirective>(exports, (x) {
      x.write(sink);
    });
    sink.writeBool(hasDartCoreImport);
    sink.writeList<UnlinkedLibraryImportDirective>(imports, (x) {
      x.write(sink);
    });
    sink.writeUint8List(informativeBytes);
    sink.writeBool(isDartCore);
    sink.writeOptionalObject<UnlinkedLibraryDirective>(
      libraryDirective,
      (x) => x.write(sink),
    );
    sink.writeUint30List(lineStarts);
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
    sink.writeList(dartdocTemplates, (x) {
      x.write(sink);
    });
  }
}
