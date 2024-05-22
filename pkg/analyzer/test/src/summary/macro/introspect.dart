// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:macros/macros.dart';

/*macro*/ class Introspect
    implements
        ClassDeclarationsMacro,
        ConstructorDeclarationsMacro,
        EnumDeclarationsMacro,
        EnumValueDeclarationsMacro,
        ExtensionDeclarationsMacro,
        ExtensionTypeDeclarationsMacro,
        FieldDeclarationsMacro,
        FunctionDeclarationsMacro,
        LibraryDeclarationsMacro,
        MethodDeclarationsMacro,
        MixinDeclarationsMacro,
        TypeAliasDeclarationsMacro,
        VariableDeclarationsMacro {
  final Set<Object?> withDetailsFor;
  final bool withMetadata;
  final bool withUnnamedConstructor;

  const Introspect({
    this.withDetailsFor = const {},
    this.withMetadata = false,
    this.withUnnamedConstructor = false,
  });

  @override
  Future<void> buildDeclarationsForClass(
    ClassDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _typeDeclarationOf(declaration, builder);

    await _write(builder, declaration, (printer) async {
      await printer.writeClassDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForConstructor(
    ConstructorDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeConstructorDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForEnum(
    EnumDeclaration declaration,
    EnumDeclarationBuilder builder,
  ) async {
    await _typeDeclarationOf(declaration, builder);

    await _write(builder, declaration, (printer) async {
      await printer.writeEnumDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForEnumValue(
    EnumValueDeclaration declaration,
    EnumDeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeEnumValueDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForExtension(
    ExtensionDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _typeDeclarationOf(declaration, builder);

    await _write(builder, declaration, (printer) async {
      await printer.writeExtensionDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForExtensionType(
    ExtensionTypeDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _typeDeclarationOf(declaration, builder);

    await _write(builder, declaration, (printer) async {
      await printer.writeExtensionTypeDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForField(
    FieldDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeField(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForFunction(
    FunctionDeclaration declaration,
    DeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeFunctionDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForLibrary(
    Library library,
    DeclarationBuilder builder,
  ) async {
    var buffer = StringBuffer();
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    var types = await builder.typesOf(library);
    var includedDeclarations = <Declaration>{};

    var printer = _Printer(
      sink: sink,
      withMetadata: withMetadata,
      withUnnamedConstructor: withUnnamedConstructor,
      introspector: builder,
      shouldWriteDetailsFor: (declaration) {
        return includedDeclarations.remove(declaration);
      },
    );

    for (var type in types) {
      includedDeclarations.add(type);
      await printer.writeAnyDeclaration(type);
    }

    var text = buffer.toString();
    _declareIntrospectResult(builder, text);
  }

  @override
  Future<void> buildDeclarationsForMethod(
    MethodDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeMethodDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForMixin(
    MixinDeclaration declaration,
    MemberDeclarationBuilder builder,
  ) async {
    await _typeDeclarationOf(declaration, builder);

    await _write(builder, declaration, (printer) async {
      await printer.writeMixinDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForTypeAlias(
    TypeAliasDeclaration declaration,
    DeclarationBuilder builder,
  ) async {
    await _typeDeclarationOf(declaration, builder);

    await _write(builder, declaration, (printer) async {
      await printer.writeTypeAliasDeclaration(declaration);
    });
  }

  @override
  Future<void> buildDeclarationsForVariable(
    VariableDeclaration declaration,
    DeclarationBuilder builder,
  ) async {
    await _write(builder, declaration, (printer) async {
      await printer.writeVariable(declaration);
    });
  }

  void _declareIntrospectResult(DeclarationBuilder builder, String text) {
    builder.declareInLibrary(
      DeclarationCode.fromString(
        'const _introspect = r"""$text""";',
      ),
    );
  }

  Future<void> _typeDeclarationOf(
    TypeDeclaration declaration,
    DeclarationBuilder builder,
  ) async {
    var identifier = declaration.identifier;
    await builder.typeDeclarationOf(identifier);
    // No check, just don't crash.
  }

  Future<void> _write(
    DeclarationBuilder builder,
    Declaration declaration,
    Future<void> Function(_Printer printer) withPrinter,
  ) async {
    var buffer = StringBuffer();
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    var includedNames = {
      declaration.identifier.name,
      ...withDetailsFor,
    };

    var printer = _Printer(
      sink: sink,
      withMetadata: withMetadata,
      withUnnamedConstructor: withUnnamedConstructor,
      introspector: builder,
      shouldWriteDetailsFor: (declaration) {
        var nameToCheck = declaration.identifier.name;
        return includedNames.remove(nameToCheck);
      },
    );
    await withPrinter(printer);

    var text = buffer.toString();
    _declareIntrospectResult(builder, text);
  }
}

/*macro*/ class IntrospectDeclaration implements FunctionDefinitionMacro {
  final String uriStr;
  final String name;
  final bool withUnnamedConstructor;

  IntrospectDeclaration({
    required this.uriStr,
    required this.name,
    this.withUnnamedConstructor = false,
  });

  @override
  Future<void> buildDefinitionForFunction(
    FunctionDeclaration declaration,
    FunctionDefinitionBuilder builder,
  ) async {
    var buffer = StringBuffer();
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    var includedNames = {name};

    var printer = _Printer(
      sink: sink,
      withMetadata: true,
      withUnnamedConstructor: withUnnamedConstructor,
      introspector: builder,
      shouldWriteDetailsFor: (declaration) {
        var name = declaration.identifier.name;
        return includedNames.remove(name);
      },
    );

    // ignore: deprecated_member_use
    var identifier = await builder.resolveIdentifier(
      Uri.parse(uriStr),
      name,
    );
    var declaration = await builder.declarationOf(identifier);
    await printer.writeAnyDeclaration(declaration);

    var text = buffer.toString();

    builder.augment(
      FunctionBodyCode.fromString('=> r"""$text""";'),
    );
  }
}

/// We use [nameToFind] only because we cannot get [Library] by URI.
/*macro*/ class LibraryTopLevelDeclarations implements FunctionDefinitionMacro {
  final String uriStr;
  final String nameToFind;

  LibraryTopLevelDeclarations({
    required this.uriStr,
    required this.nameToFind,
  });

  @override
  Future<void> buildDefinitionForFunction(
    FunctionDeclaration declaration,
    FunctionDefinitionBuilder builder,
  ) async {
    var buffer = StringBuffer();
    var sink = TreeStringSink(
      sink: buffer,
      indent: '',
    );

    var includedNames = <String>{};

    var printer = _Printer(
      sink: sink,
      withMetadata: true,
      withUnnamedConstructor: false,
      introspector: builder,
      shouldWriteDetailsFor: (declaration) {
        var name = declaration.identifier.name;
        return includedNames.remove(name);
      },
    );

    // ignore: deprecated_member_use
    var identifier = await builder.resolveIdentifier(
      Uri.parse(uriStr),
      nameToFind,
    );
    var declaration = await builder.declarationOf(identifier);
    var library = declaration.library;

    sink.writelnWithIndent('topLevelDeclarationsOf');
    await sink.withIndent(() async {
      var topDeclarations = await builder.topLevelDeclarationsOf(library);
      for (var declaration in topDeclarations) {
        var name = declaration.identifier.name;
        if (name != '_starter') {
          includedNames.add(name);
          await printer.writeAnyDeclaration(declaration);
        }
      }
    });

    var text = buffer.toString();
    builder.augment(
      FunctionBodyCode.fromString('=> r"""$text""";'),
    );
  }
}

/// Wrapper around a [StringSink] for writing tree structures.
class TreeStringSink {
  final StringSink _sink;
  String _indent = '';

  TreeStringSink({
    required StringSink sink,
    required String indent,
  })  : _sink = sink,
        _indent = indent;

  Future<void> withIndent(Future<void> Function() f) async {
    var indent = _indent;
    _indent = '$indent  ';
    await f();
    _indent = indent;
  }

  void write(Object object) {
    _sink.write(object);
  }

  Future<void> writeElements<T extends Object>(
    String name,
    Iterable<T> elements,
    Future<void> Function(T) f,
  ) async {
    if (elements.isNotEmpty) {
      writelnWithIndent(name);
      await withIndent(() async {
        for (var element in elements) {
          await f(element);
        }
      });
    }
  }

  Future<void> writeFlags(Map<String, bool> flags) async {
    if (flags.values.any((flag) => flag)) {
      await writeIndentedLine(() async {
        write('flags:');
        for (var entry in flags.entries) {
          if (entry.value) {
            write(' ${entry.key}');
          }
        }
      });
    }
  }

  void writeIf(bool flag, Object object) {
    if (flag) {
      write(object);
    }
  }

  void writeIndent() {
    _sink.write(_indent);
  }

  Future<void> writeIndentedLine(void Function() f) async {
    writeIndent();
    f();
    writeln();
  }

  void writeln([Object? object = '']) {
    _sink.writeln(object);
  }

  void writelnWithIndent(Object object) {
    _sink.write(_indent);
    _sink.writeln(object);
  }

  void writeWithIndent(Object object) {
    _sink.write(_indent);
    _sink.write(object);
  }
}

class _Printer {
  final TreeStringSink sink;
  final bool withMetadata;
  final bool withUnnamedConstructor;
  final DeclarationPhaseIntrospector introspector;
  final bool Function(Declaration declaration) shouldWriteDetailsFor;

  Identifier? _enclosingDeclarationIdentifier;

  _Printer({
    required this.sink,
    required this.withMetadata,
    required this.withUnnamedConstructor,
    required this.introspector,
    required this.shouldWriteDetailsFor,
  });

  Future<void> writeAnyDeclaration(Declaration declaration) async {
    switch (declaration) {
      case ClassDeclaration():
        await writeClassDeclaration(declaration);
      case EnumDeclaration():
        await writeEnumDeclaration(declaration);
      case ExtensionDeclaration():
        await writeExtensionDeclaration(declaration);
      case ExtensionTypeDeclaration():
        await writeExtensionTypeDeclaration(declaration);
      case FunctionDeclaration():
        await writeFunctionDeclaration(declaration);
      case MixinDeclaration():
        await writeMixinDeclaration(declaration);
      case TypeAliasDeclaration():
        await writeTypeAliasDeclaration(declaration);
      case VariableDeclaration():
        await writeVariable(declaration);
      default:
        throw UnimplementedError('${declaration.runtimeType}');
    }
  }

  Future<void> writeClassDeclaration(ClassDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('class ${e.identifier.name}');

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasBase': e.hasBase,
        'hasExternal': e.hasExternal,
        'hasFinal': e.hasFinal,
        'hasInterface': e.hasInterface,
        'hasMixin': e.hasMixin,
        'hasSealed': e.hasSealed,
      });
      await _writeMetadata(e);
      if (e.superclass case var superclass?) {
        await _writeNamedTypeAnnotation('superclass', superclass);
      }
      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);
      await _writeTypeDeclarationMembers(e);
    });
  }

  Future<void> writeConstructorDeclaration(ConstructorDeclaration e) async {
    _assertEnclosingClass(e);

    sink.writelnWithIndent(
      e.identifier.name.ifNotEmptyOrElse('<unnamed>'),
    );

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasBody': e.hasBody,
        'hasExternal': e.hasExternal,
        'hasStatic': e.hasStatic,
        'isFactory': e.isFactory,
        'isGetter': e.isGetter,
        'isOperator': e.isOperator,
        'isSetter': e.isSetter,
      });
      await _writeMetadata(e);
      await _writeNamedFormalParameters(e.namedParameters);
      await _writePositionalFormalParameters(e.positionalParameters);
      await _writeNamedTypeAnnotation('returnType', e.returnType);
      await _writeTypeParameters(e.typeParameters);
    });
  }

  Future<void> writeEnumDeclaration(EnumDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('enum ${e.identifier.name}');

    await sink.withIndent(() async {
      await _writeMetadata(e);
      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);
      await sink.writeElements(
        'values',
        await introspector.valuesOf(e),
        writeEnumValueDeclaration,
      );
      await _writeTypeDeclarationMembers(e);
    });
  }

  Future<void> writeEnumValueDeclaration(EnumValueDeclaration e) async {
    var enclosing = _enclosingDeclarationIdentifier;
    if (enclosing != null && e.definingEnum != enclosing) {
      throw StateError('Mismatch: definingEnum');
    }

    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await _writeMetadata(e);
      // TODO(scheglov): Write, when added.
      // await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  Future<void> writeExtensionDeclaration(ExtensionDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('extension ${e.identifier.name}');

    await sink.withIndent(() async {
      await _writeMetadata(e);

      await _writeTypeParameters(e.typeParameters);
      await _writeNamedTypeAnnotation('onType', e.onType);
      await _writeTypeDeclarationMembers(e);
    });
  }

  Future<void> writeExtensionTypeDeclaration(ExtensionTypeDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('extension type ${e.identifier.name}');

    await sink.withIndent(() async {
      await _writeMetadata(e);

      await _writeTypeParameters(e.typeParameters);
      await _writeNamedTypeAnnotation(
        'representationType',
        e.representationType,
      );
      await _writeTypeDeclarationMembers(e);
    });
  }

  Future<void> writeField(FieldDeclaration e) async {
    _assertEnclosingClass(e);
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasAbstract': e.hasAbstract,
        'hasConst': e.hasConst,
        'hasExternal': e.hasExternal,
        'hasFinal': e.hasFinal,
        'hasInitializer': e.hasInitializer,
        'hasLate': e.hasLate,
        'hasStatic': e.hasStatic,
      });
      await _writeMetadata(e);
      await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  Future<void> writeFunctionDeclaration(FunctionDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasBody': e.hasBody,
        'hasExternal': e.hasExternal,
        'isGetter': e.isGetter,
        'isOperator': e.isOperator,
        'isSetter': e.isSetter,
      });
      await _writeMetadata(e);
      await _writeNamedFormalParameters(e.namedParameters);
      await _writePositionalFormalParameters(e.positionalParameters);
      await _writeNamedTypeAnnotation('returnType', e.returnType);
      await _writeTypeParameters(e.typeParameters);
    });
  }

  Future<void> writeMethodDeclaration(MethodDeclaration e) async {
    _assertEnclosingClass(e);
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasBody': e.hasBody,
        'hasExternal': e.hasExternal,
        'hasStatic': e.hasStatic,
        'isGetter': e.isGetter,
        'isOperator': e.isOperator,
        'isSetter': e.isSetter,
      });
      await _writeMetadata(e);
      await _writeNamedFormalParameters(e.namedParameters);
      await _writePositionalFormalParameters(e.positionalParameters);
      await _writeNamedTypeAnnotation('returnType', e.returnType);
      await _writeTypeParameters(e.typeParameters);
    });
  }

  Future<void> writeMixinDeclaration(MixinDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('mixin ${e.identifier.name}');

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasBase': e.hasBase,
      });

      await _writeMetadata(e);

      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations(
        'superclassConstraints',
        e.superclassConstraints,
      );
      await _writeTypeAnnotations('interfaces', e.interfaces);
      await _writeTypeDeclarationMembers(e);
    });
  }

  Future<void> writeTypeAliasDeclaration(TypeAliasDeclaration e) async {
    if (!shouldWriteDetailsFor(e)) {
      return;
    }

    sink.writelnWithIndent('typedef ${e.identifier.name}');

    await sink.withIndent(() async {
      await _writeMetadata(e);

      await _writeTypeParameters(e.typeParameters);
      await _writeNamedTypeAnnotation(
        'aliasedType',
        e.aliasedType,
      );
    });
  }

  Future<void> writeVariable(VariableDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await sink.writeFlags({
        'hasConst': e.hasConst,
        'hasExternal': e.hasExternal,
        'hasFinal': e.hasFinal,
        'hasLate': e.hasLate,
        'hasInitializer': e.hasInitializer,
      });
      await _writeMetadata(e);
      await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  void _assertEnclosingClass(MemberDeclaration e) {
    var enclosing = _enclosingDeclarationIdentifier;
    if (enclosing != null && e.definingType != enclosing) {
      throw StateError('Mismatch: definingClass');
    }
  }

  bool _shouldWriteArguments(ConstructorMetadataAnnotation annotation) {
    return !const {
      'Introspect',
    }.contains(annotation.type.identifier.name);
  }

  Future<void> _writeExpressionCode(
    ExpressionCode code, {
    String? name,
  }) async {
    await sink.writeIndentedLine(() async {
      if (name != null) {
        sink.write('$name: ');
      }
      sink.write('${code.parts}');
    });
  }

  Future<void> _writeFormalParameterDeclaration(
      FormalParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);
    await sink.withIndent(() async {
      await sink.writeFlags({
        'isNamed': e.isNamed,
        'isRequired': e.isRequired,
      });
      await _writeMetadata(e);
      await _writeNamedTypeAnnotation('type', e.type);
    });
  }

  /// If [type] is [OmittedTypeAnnotation], write the inferred type.
  Future<void> _writeInferredTypeAnnotation(TypeAnnotation type) async {
    if (type is OmittedTypeAnnotation) {
      if (introspector case DefinitionPhaseIntrospector introspector) {
        var inferred = await introspector.inferType(type);
        await sink.withIndent(() async {
          sink.writelnWithIndent('inferred: ${inferred.asString}');
        });
      }
    }
  }

  Future<void> _writeMetadata(Annotatable e) async {
    if (withMetadata) {
      await sink.writeElements(
        'metadata',
        e.metadata,
        _writeMetadataAnnotation,
      );
    }
  }

  Future<void> _writeMetadataAnnotation(MetadataAnnotation e) async {
    switch (e) {
      case ConstructorMetadataAnnotation():
        sink.writelnWithIndent('ConstructorMetadataAnnotation');
        await sink.withIndent(() async {
          sink.writelnWithIndent('type: ${e.type.identifier.name}');
          var constructorName = e.constructor.name;
          if (constructorName.isNotEmpty) {
            sink.writelnWithIndent('constructorName: $constructorName');
          }
          if (_shouldWriteArguments(e)) {
            await sink.writeElements(
              'positionalArguments',
              e.positionalArguments,
              (argument) async {
                await _writeExpressionCode(argument);
              },
            );
            await sink.writeElements(
              'namedArguments',
              e.namedArguments.entries,
              (entry) async {
                await _writeExpressionCode(name: entry.key, entry.value);
              },
            );
          }
        });
      case IdentifierMetadataAnnotation():
        sink.writelnWithIndent('IdentifierMetadataAnnotation');
        await sink.withIndent(() async {
          sink.writelnWithIndent('identifier: ${e.identifier.name}');
        });
      default:
    }
  }

  Future<void> _writeNamedFormalParameters(
    Iterable<FormalParameterDeclaration> elements,
  ) async {
    await sink.writeElements(
      'namedParameters',
      elements,
      _writeFormalParameterDeclaration,
    );
  }

  Future<void> _writeNamedTypeAnnotation(
    String name,
    TypeAnnotation? type,
  ) async {
    sink.writeWithIndent('$name: ');
    await _writeTypeAnnotation(type);
  }

  Future<void> _writePositionalFormalParameters(
    Iterable<FormalParameterDeclaration> elements,
  ) async {
    await sink.writeElements(
      'positionalParameters',
      elements,
      _writeFormalParameterDeclaration,
    );
  }

  Future<void> _writeTypeAnnotation(TypeAnnotation? type) async {
    if (type != null) {
      sink.writeln(type.asString);
      await _writeInferredTypeAnnotation(type);
      await _writeTypeAnnotationDeclaration(type);
    } else {
      sink.writeln('null');
    }
  }

  Future<void> _writeTypeAnnotationDeclaration(TypeAnnotation type) async {
    await sink.withIndent(() async {
      switch (type) {
        case FunctionTypeAnnotation():
          // No declaration.
          break;
        case NamedTypeAnnotation():
          var identifier = type.identifier;
          if (identifier.name == 'void') {
            return;
          }

          TypeDeclaration declaration;
          try {
            declaration = await introspector.typeDeclarationOf(identifier);
          } on MacroImplementationException {
            sink.writelnWithIndent('noDeclaration');
            return;
          }

          switch (declaration) {
            case ClassDeclaration():
              await writeClassDeclaration(declaration);
            case EnumDeclaration():
              await writeEnumDeclaration(declaration);
            case MixinDeclaration():
              await writeMixinDeclaration(declaration);
            default:
              throw UnimplementedError('${declaration.runtimeType}');
          }
        case OmittedTypeAnnotation():
          // No declaration, yet.
          break;
        default:
          throw UnimplementedError('(${type.runtimeType}) $type');
      }
    });
  }

  Future<void> _writeTypeAnnotations(
    String name,
    Iterable<TypeAnnotation> types,
  ) async {
    await sink.writeElements(name, types, (type) async {
      sink.writeIndent();
      await _writeTypeAnnotation(type);
    });
  }

  Future<void> _writeTypeDeclarationMembers(TypeDeclaration e) async {
    _enclosingDeclarationIdentifier = e.identifier;

    var constructors = await introspector.constructorsOf(e);
    await sink.writeElements(
      'constructors',
      constructors.where((element) {
        return element.identifier.name.isNotEmpty || withUnnamedConstructor;
      }),
      writeConstructorDeclaration,
    );

    await sink.writeElements(
      'fields',
      await introspector.fieldsOf(e),
      writeField,
    );
    await sink.writeElements(
      'methods',
      await introspector.methodsOf(e),
      writeMethodDeclaration,
    );

    _enclosingDeclarationIdentifier = null;
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    sink.writelnWithIndent(e.identifier.name);

    await sink.withIndent(() async {
      await _writeMetadata(e);
      if (e.bound case var bound?) {
        await _writeNamedTypeAnnotation('bound', bound);
      }
    });
  }

  Future<void> _writeTypeParameters(
    Iterable<TypeParameterDeclaration> elements,
  ) async {
    await sink.writeElements('typeParameters', elements, _writeTypeParameter);
  }
}

class _TypeAnnotationStringBuilder {
  final StringSink _sink;

  _TypeAnnotationStringBuilder(this._sink);

  void write(TypeAnnotation type) {
    if (type is FunctionTypeAnnotation) {
      _writeFunctionTypeAnnotation(type);
    } else if (type is NamedTypeAnnotation) {
      _writeNamedTypeAnnotation(type);
    } else if (type is OmittedTypeAnnotation) {
      _sink.write('OmittedType');
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
    if (type.isNullable) {
      _sink.write('?');
    }
  }

  void _writeFormalParameter(FormalParameter node) {
    String closeSeparator;
    if (node.isNamed) {
      _sink.write('{');
      closeSeparator = '}';
      if (node.isRequired) {
        _sink.write('required ');
      }
    } else if (!node.isRequired) {
      _sink.write('[');
      closeSeparator = ']';
    } else {
      closeSeparator = '';
    }

    write(node.type);
    if (node.name != null) {
      _sink.write(' ');
      _sink.write(node.name);
    }

    _sink.write(closeSeparator);
  }

  void _writeFunctionTypeAnnotation(FunctionTypeAnnotation type) {
    write(type.returnType);
    _sink.write(' Function');

    _sink.writeList(
      elements: type.typeParameters,
      write: _writeTypeParameter,
      separator: ', ',
      open: '<',
      close: '>',
    );

    _sink.write('(');
    var hasFormalParameter = false;
    for (var formalParameter in type.positionalParameters) {
      if (hasFormalParameter) {
        _sink.write(', ');
      }
      _writeFormalParameter(formalParameter);
      hasFormalParameter = true;
    }
    for (var formalParameter in type.namedParameters) {
      if (hasFormalParameter) {
        _sink.write(', ');
      }
      _writeFormalParameter(formalParameter);
      hasFormalParameter = true;
    }
    _sink.write(')');
  }

  void _writeNamedTypeAnnotation(NamedTypeAnnotation type) {
    _sink.write(type.identifier.name);
    _sink.writeList(
      elements: type.typeArguments,
      write: write,
      separator: ', ',
      open: '<',
      close: '>',
    );
  }

  void _writeTypeParameter(TypeParameter node) {
    _sink.write(node.name);

    var bound = node.bound;
    if (bound != null) {
      _sink.write(' extends ');
      write(bound);
    }
  }
}

extension on StringSink {
  void writeList<T>({
    required Iterable<T> elements,
    required void Function(T element) write,
    required String separator,
    String? open,
    String? close,
  }) {
    elements = elements.toList();
    if (elements.isEmpty) {
      return;
    }

    if (open != null) {
      this.write(open);
    }
    var isFirst = true;
    for (var element in elements) {
      if (isFirst) {
        isFirst = false;
      } else {
        this.write(separator);
      }
      write(element);
    }
    if (close != null) {
      this.write(close);
    }
  }
}

extension E on TypeAnnotation {
  String get asString {
    var buffer = StringBuffer();
    _TypeAnnotationStringBuilder(buffer).write(this);
    return buffer.toString();
  }
}

extension StringExtension on String {
  String ifNotEmptyOrElse(String orElse) {
    return isNotEmpty ? this : orElse;
  }
}
