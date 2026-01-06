// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' show File, IOSink;
import 'dart:typed_data' show BytesBuilder, Uint8List;

import 'package:_fe_analyzer_shared/src/parser/formal_parameter_kind.dart';
import 'package:_fe_analyzer_shared/src/scanner/scanner.dart' show Token;
import 'package:_fe_analyzer_shared/src/scanner/token.dart'
    show SyntheticToken, TokenType;
import 'package:front_end/src/base/lookup_result.dart';
import 'package:front_end/src/base/scope.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_to_binary.dart';
import 'package:kernel/clone.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/src/printer.dart';

import '../base/combinator.dart';
import '../base/configuration.dart';
import '../base/extension_scope.dart';
import '../base/identifiers.dart';
import '../base/modifiers.dart';
import '../builder/declaration_builders.dart';
import '../builder/fixed_type_builder.dart';
import '../builder/formal_parameter_builder.dart';
import '../builder/library_builder.dart';
import '../builder/metadata_builder.dart';
import '../builder/omitted_type_builder.dart';
import '../builder/record_type_builder.dart';
import '../builder/type_builder.dart';
import '../fragment/fragment.dart';
import '../source/fragment_factory.dart';
import '../source/source_type_parameter_builder.dart';
import 'body_builder.dart';
import 'internal_ast.dart';

/// The name for the synthesized field used to store information of
/// unserializable exports in a [Library].
///
/// For instance, if a [Library] tries to export two declarations with the same
/// name, the unserializable exports will map this name to the corresponding
/// error message.
const String unserializableExportName = '_exports#';

/// Sentinel value used in unserializable exports to signal an export of
/// 'dynamic' from 'dart:core'.
const String exportDynamicSentinel = '<dynamic>';

/// Sentinel value used in unserializable exports to signal an export of
/// 'Never' from 'dart:core'.
const String exportNeverSentinel = '<Never>';

// Coverage-ignore(suite): Not run.
void printNodeOn(Node? node, StringSink sink) {
  if (node == null) {
    sink.write("null");
  } else {
    sink.write(node.toText(defaultAstTextStrategy));
  }
}

// Coverage-ignore(suite): Not run.
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

void bindCoreType(
  LibraryBuilder coreLibrary,
  NamedTypeBuilder typeBuilder, {
  bool isNullClass = false,
}) {
  TypeDeclarationBuilder typeDeclarationBuilder =
      coreLibrary.lookupRequiredLocalMember(typeBuilder.typeName.name)
          as TypeDeclarationBuilder;
  typeBuilder.bind(coreLibrary, typeDeclarationBuilder);
  if (isNullClass) {
    (typeDeclarationBuilder as ClassBuilder).isNullClass = true;
  }
}

// Coverage-ignore(suite): Not run.
/// Print the given [component].  Do nothing if it is `null`.  If the
/// [libraryFilter] is provided, then only libraries that satisfy it are
/// printed.
void printComponentText(
  Component? component, {
  bool Function(Library library)? libraryFilter,
  bool showOffsets = false,
}) {
  if (component == null) return;
  StringBuffer sb = new StringBuffer();
  Printer printer = new Printer(sb, showOffsets: showOffsets);
  printer.writeComponentProblems(component);
  for (Library library in component.libraries) {
    if (libraryFilter != null && !libraryFilter(library)) continue;
    printer.writeLibraryFile(library);
  }
  printer.writeConstantTable(component);
  print(sb);
}

// Coverage-ignore(suite): Not run.
/// Write [component] to file only including libraries that match [filter].
Future<Null> writeComponentToFile(
  Component component,
  Uri uri, {
  bool Function(Library library)? filter,
}) async {
  File output = new File.fromUri(uri);
  IOSink sink = output.openWrite();
  try {
    BinaryPrinter printer = new BinaryPrinter(sink, libraryFilter: filter);
    printer.writeComponentFile(component);
  } finally {
    await sink.close();
  }
}

// Coverage-ignore(suite): Not run.
/// Serialize the libraries in [component] that match [filter].
Uint8List serializeComponent(
  Component component, {
  bool Function(Library library)? filter,
  bool includeSources = true,
  bool includeOffsets = true,
}) {
  ByteSink byteSink = new ByteSink();
  BinaryPrinter printer = new BinaryPrinter(
    byteSink,
    libraryFilter: filter,
    includeSources: includeSources,
    includeOffsets: includeOffsets,
  );
  printer.writeComponentFile(component);
  return byteSink.builder.takeBytes();
}

const String kDebugClassName = "#DebugClass";

// Coverage-ignore(suite): Not run.
class _CollectLibraryDependencies extends RecursiveVisitor {
  Set<LibraryDependency> foundLibraryDependencies = {};

  @override
  void visitLoadLibrary(LoadLibrary node) {
    foundLibraryDependencies.add(node.import);
  }

  @override
  void visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    foundLibraryDependencies.add(node.import);
  }
}

// Coverage-ignore(suite): Not run.
Component createExpressionEvaluationComponent(Procedure procedure) {
  Library realLibrary = procedure.enclosingLibrary;

  Uri uri = new Uri(scheme: 'evaluate', path: 'source');
  Library fakeLibrary = new Library(uri, fileUri: uri)
    ..setLanguageVersion(realLibrary.languageVersion);

  // Add deferred library dependencies. They are needed for serializing
  // references to deferred libraries. We can just claim ownership of the ones
  // we find as they were created when doing the expression compilation.
  _CollectLibraryDependencies collectLibraryDependencies =
      new _CollectLibraryDependencies();
  procedure.accept(collectLibraryDependencies);
  for (LibraryDependency libraryDependency
      in collectLibraryDependencies.foundLibraryDependencies) {
    fakeLibrary.addDependency(libraryDependency);
  }

  TreeNode? realClass = procedure.parent;
  if (realClass is Class) {
    Class fakeClass = new Class(name: kDebugClassName, fileUri: uri)
      ..parent = fakeLibrary;
    Map<TypeParameter, TypeParameter> typeParams =
        <TypeParameter, TypeParameter>{};
    Map<TypeParameter, DartType> typeSubstitution = <TypeParameter, DartType>{};
    for (TypeParameter typeParam in realClass.typeParameters) {
      TypeParameter newNode = new TypeParameter(typeParam.name)
        ..declaration = fakeClass;
      typeParams[typeParam] = newNode;
      typeSubstitution[typeParam] = new TypeParameterType(
        newNode,
        typeParam.computeNullabilityFromBound(),
      );
    }
    CloneVisitorWithMembers cloner = new CloneVisitorWithMembers(
      typeSubstitution: typeSubstitution,
      typeParams: typeParams,
    );

    for (TypeParameter typeParam in realClass.typeParameters) {
      fakeClass.typeParameters.add(
        typeParam.accept<TreeNode>(cloner) as TypeParameter,
      );
    }

    if (realClass.supertype != null) {
      // supertype is null for Object.
      fakeClass.supertype = new Supertype.byReference(
        realClass.supertype!.className,
        realClass.supertype!.typeArguments.map(cloner.visitType).toList(),
      );
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
  component.setMainMethodAndMode(null, false);
  return component;
}

// Coverage-ignore(suite): Not run.
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
  // Coverage-ignore(suite): Not run.
  void close() {}
}

int compareProcedures(Procedure a, Procedure b) {
  int i = "${a.fileUri}".compareTo("${b.fileUri}");
  if (i != 0) return i;
  return a.fileOffset.compareTo(b.fileOffset);
}

List<Combinator>? toCombinators(List<CombinatorBuilder>? combinatorBuilders) {
  if (combinatorBuilders == null) {
    // Note: it's safe to return null here as Kernel's LibraryDependency will
    // convert null to an empty list.
    return null;
  }

  return new List<Combinator>.generate(combinatorBuilders.length, (int i) {
    CombinatorBuilder combinator = combinatorBuilders[i];
    List<String> nameList = combinator.names.toList();
    return combinator.isShow
        ? new Combinator.show(nameList)
        : new Combinator.hide(nameList);
  }, growable: true);
}

final Token dummyToken = new SyntheticToken(TokenType.AT, -1);
final Identifier dummyIdentifier = new SimpleIdentifier(dummyToken);
final CombinatorBuilder dummyCombinator = new CombinatorBuilder(
  false,
  {},
  -1,
  dummyUri,
);
final MetadataBuilder dummyMetadataBuilder = new MetadataBuilder(
  dummyToken,
  dummyUri,
);
final TypeBuilder dummyTypeBuilder = new FixedTypeBuilderImpl(
  dummyDartType,
  dummyUri,
  -1,
);
final FormalParameterBuilder dummyFormalParameterBuilder =
    new FormalParameterBuilder(
      FormalParameterKind.requiredPositional,
      Modifiers.empty,
      const ImplicitTypeBuilder(),
      '',
      -1,
      fileUri: dummyUri,
      hasImmediatelyDeclaredInitializer: false,
    );
final FunctionTypeParameterBuilder dummyFunctionTypeParameterBuilder =
    new FunctionTypeParameterBuilder(
      FormalParameterKind.requiredPositional,
      const ImplicitTypeBuilder(),
      '',
    );
final NominalParameterBuilder dummyNominalVariableBuilder =
    new SourceNominalParameterBuilder(
      new DirectNominalParameterDeclaration(
        name: NominalParameterBuilder.noNameSentinel,
        kind: TypeParameterKind.function,
        isWildcard: false,
        fileOffset: -1,
        fileUri: dummyUri,
      ),
    );
final TypeParameterFragment dummyTypeParameterFragment =
    new TypeParameterFragment(
      metadata: null,
      name: '',
      nameOffset: -1,
      fileUri: dummyUri,
      kind: TypeParameterKind.function,
      isWildcard: false,
      variableName: '',
      extensionScope: dummyExtensionScope,
      typeParameterScope: dummyLookupScope,
    );
final SourceStructuralParameterBuilder dummyStructuralVariableBuilder =
    new SourceStructuralParameterBuilder(
      new RegularStructuralParameterDeclaration(
        metadata: null,
        name: StructuralParameterBuilder.noNameSentinel,
        fileOffset: -1,
        fileUri: dummyUri,
        isWildcard: false,
      ),
    );
final Label dummyLabel = new Label('', -1);
final RecordTypeFieldBuilder dummyRecordTypeFieldBuilder =
    new RecordTypeFieldBuilder(null, dummyTypeBuilder, null, -1);
final FieldInfo dummyFieldInfo = new FieldInfo(
  dummyIdentifier,
  null,
  dummyToken,
  -1,
);
final Configuration dummyConfiguration = new Configuration(-1, '', '', '');
final LookupScope dummyLookupScope = new _DummyLookupScope();
final ExtensionScope dummyExtensionScope = new _DummyExtensionScope();

// Coverage-ignore(suite): Not run.
class _DummyLookupScope implements LookupScope {
  @override
  LookupResult? lookup(String name) => null;
}

// Coverage-ignore(suite): Not run.
class _DummyExtensionScope implements ExtensionScope {
  @override
  void forEachExtension(void Function(ExtensionBuilder) f) {}
}

final Argument dummyArgument = new PositionalArgument(dummyExpression);
