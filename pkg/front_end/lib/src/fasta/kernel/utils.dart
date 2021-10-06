// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show BytesBuilder, File, IOSink;

import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show SyntheticToken, TokenType;

import 'package:kernel/ast.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/text/ast_to_text.dart';

import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/type_builder.dart';
import '../builder/type_variable_builder.dart';
import '../combinator.dart';
import '../configuration.dart';
import '../identifiers.dart';
import '../source/source_library_builder.dart';
import 'body_builder.dart';

void printNodeOn(Node? node, StringSink sink, {NameSystem? syntheticNames}) {
  if (node == null) {
    sink.write("null");
  } else {
    syntheticNames ??= new NameSystem();
    new Printer(sink, syntheticNames: syntheticNames).writeNode(node);
  }
}

void printQualifiedNameOn(Member? member, StringSink sink) {
  if (member == null) {
    sink.write("null");
  } else {
    sink.write(member.enclosingLibrary.importUri);
    sink.write("::");
    Class? cls = member.enclosingClass;
    if (cls != null) {
      sink.write(cls.name);
      sink.write("::");
    }
    sink.write(member.name.text);
  }
}

/// Print the given [component].  Do nothing if it is `null`.  If the
/// [libraryFilter] is provided, then only libraries that satisfy it are
/// printed.
void printComponentText(Component? component,
    {bool Function(Library library)? libraryFilter}) {
  if (component == null) return;
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb);
  printer.writeComponentProblems(component);
  for (Library library in component.libraries) {
    if (libraryFilter != null && !libraryFilter(library)) continue;
    printer.writeLibraryFile(library);
  }
  printer.writeConstantTable(component);
  print(sb);
}

/// Write [component] to file only including libraries that match [filter].
Future<Null> writeComponentToFile(Component component, Uri uri,
    {bool Function(Library library)? filter}) async {
  File output = new File.fromUri(uri);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer = new BinaryPrinter(sink, libraryFilter: filter);
    printer.writeComponentFile(component);
  } finally {
    await sink.close();
  }
}

/// Serialize the libraries in [component] that match [filter].
Uint8List serializeComponent(Component component,
    {bool Function(Library library)? filter,
    bool includeSources: true,
    bool includeOffsets: true}) {
  ByteSink byteSink = new ByteSink();
  BinaryPrinter printer = new BinaryPrinter(byteSink,
      libraryFilter: filter,
      includeSources: includeSources,
      includeOffsets: includeOffsets);
  printer.writeComponentFile(component);
  return byteSink.builder.takeBytes();
}

const String kDebugClassName = "#DebugClass";

Component createExpressionEvaluationComponent(Procedure procedure) {
  Library realLibrary = procedure.enclosingLibrary;

  Uri uri = new Uri(scheme: 'evaluate', path: 'source');
  Library fakeLibrary = new Library(uri, fileUri: uri)
    ..setLanguageVersion(realLibrary.languageVersion)
    ..isNonNullableByDefault = realLibrary.isNonNullableByDefault
    ..nonNullableByDefaultCompiledMode =
        realLibrary.nonNullableByDefaultCompiledMode;

  TreeNode? realClass = procedure.parent;
  if (realClass is Class) {
    Class fakeClass = new Class(name: kDebugClassName, fileUri: uri)
      ..parent = fakeLibrary;
    Map<TypeParameter, TypeParameter> typeParams =
        <TypeParameter, TypeParameter>{};
    Map<TypeParameter, DartType> typeSubstitution = <TypeParameter, DartType>{};
    for (TypeParameter typeParam in realClass.typeParameters) {
      TypeParameter newNode = new TypeParameter(typeParam.name)
        ..parent = fakeClass;
      typeParams[typeParam] = newNode;
      typeSubstitution[typeParam] =
          new TypeParameterType.forAlphaRenaming(typeParam, newNode);
    }
    CloneVisitorWithMembers cloner = new CloneVisitorWithMembers(
        typeSubstitution: typeSubstitution, typeParams: typeParams);

    for (TypeParameter typeParam in realClass.typeParameters) {
      fakeClass.typeParameters
          .add(typeParam.accept<TreeNode>(cloner) as TypeParameter);
    }

    if (realClass.supertype != null) {
      // supertype is null for Object.
      fakeClass.supertype = new Supertype.byReference(
          realClass.supertype!.className,
          realClass.supertype!.typeArguments.map(cloner.visitType).toList());
    }

    // Rebind the type parameters in the procedure.
    procedure = cloner.cloneProcedure(procedure, null);
    procedure.parent = fakeClass;
    fakeClass.procedures.add(procedure);
    fakeLibrary.classes.add(fakeClass);
  } else {
    fakeLibrary.procedures.add(procedure);
    procedure.parent = fakeLibrary;
  }

  // TODO(vegorov) find a way to preserve metadata.
  Component component = new Component(libraries: [fakeLibrary]);
  component.setMainMethodAndMode(
      null, false, fakeLibrary.nonNullableByDefaultCompiledMode);
  return component;
}

List<int> serializeProcedure(Procedure procedure) {
  return serializeComponent(createExpressionEvaluationComponent(procedure));
}

/// A [Sink] that directly writes data into a byte builder.
class ByteSink implements Sink<List<int>> {
  final BytesBuilder builder = new BytesBuilder();

  @override
  void add(List<int> data) {
    builder.add(data);
  }

  @override
  void close() {}
}

int compareProcedures(Procedure a, Procedure b) {
  int i = "${a.fileUri}".compareTo("${b.fileUri}");
  if (i != 0) return i;
  return a.fileOffset.compareTo(b.fileOffset);
}

bool isRedirectingGenerativeConstructorImplementation(Constructor constructor) {
  List<Initializer> initializers = constructor.initializers;
  return initializers.length == 1 &&
      initializers.single is RedirectingInitializer;
}

List<Combinator>? toKernelCombinators(
    List<CombinatorBuilder>? fastaCombinators) {
  if (fastaCombinators == null) {
    // Note: it's safe to return null here as Kernel's LibraryDependency will
    // convert null to an empty list.
    return null;
  }

  return new List<Combinator>.generate(fastaCombinators.length, (int i) {
    CombinatorBuilder combinator = fastaCombinators[i];
    List<String> nameList = combinator.names.toList();
    return combinator.isShow
        ? new Combinator.show(nameList)
        : new Combinator.hide(nameList);
  }, growable: true);
}

final Token dummyToken = new SyntheticToken(TokenType.AT, -1);
final Identifier dummyIdentifier = new Identifier(dummyToken);
final CombinatorBuilder dummyCombinator =
    new CombinatorBuilder(false, {}, -1, dummyUri);
final MetadataBuilder dummyMetadataBuilder = new MetadataBuilder(dummyToken);
final TypeBuilder dummyTypeBuilder =
    new FixedTypeBuilder(dummyDartType, dummyUri, -1);
final FormalParameterBuilder dummyFormalParameterBuilder =
    new FormalParameterBuilder(null, 0, null, '', null, -1, fileUri: dummyUri);
final TypeVariableBuilder dummyTypeVariableBuilder =
    new TypeVariableBuilder(TypeVariableBuilder.noNameSentinel, null, -1, null);
final Label dummyLabel = new Label('', -1);
final FieldInfo dummyFieldInfo = new FieldInfo('', -1, null, dummyToken, -1);
final Configuration dummyConfiguration = new Configuration(-1, '', '', '');
