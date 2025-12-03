// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' hide Element;
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';

class SummaryHandler
    extends
        SharedMessageHandler<DartTextDocumentSummaryParams, DocumentSummary> {
  SummaryHandler(super.server);

  @override
  Method get handlesMessage => CustomMethods.summary;

  @override
  LspJsonHandler<DartTextDocumentSummaryParams> get jsonHandler =>
      DartTextDocumentSummaryParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<DocumentSummary>> handle(
    DartTextDocumentSummaryParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartUri(params.uri)) {
      return success(DocumentSummary());
    }

    var path = pathOfUri(params.uri);
    var resultOr = await path.mapResult(requireResolvedLibrary);
    if (resultOr.isError) {
      return ErrorOr.error(resultOr.errorOrNull!);
    }
    return resultOr.mapResultSync((result) {
      try {
        var summary = SummaryWriter(result).summarize();
        return success(DocumentSummary(summary: summary));
      } catch (e) {
        return error(
          ErrorCodes.InternalError,
          'Failed to create a summary: $e',
        );
      }
    });
  }
}

/// An object used to write a summary for a single file.
///
/// The summary contains the public API for the library, but doesn't include
/// - private members
/// - bodies of functions / methods
/// - initializers of variables / fields
class SummaryWriter {
  final ResolvedLibraryResult result;

  final StringBuffer buffer = StringBuffer();

  SummaryWriter(this.result);

  String summarize() {
    var libraryElement = result.element;

    // Write a summary of the imports.
    var libraryImports = libraryElement.firstFragment.libraryImports;
    for (var libraryImport in libraryImports) {
      summarizeImport(libraryImport);
    }

    // Write a summary of the declarations in the export namespace.
    var definedNames = libraryElement.exportNamespace.definedNames2;
    var needsSeparator = false;
    for (var element in definedNames.values) {
      if (element.isSynthetic) {
        if (element is GetterElement) {
          element = element.variable;
        } else if (element is SetterElement &&
            element.correspondingGetter == null) {
          element = element.variable;
        } else {
          continue;
        }
      }
      if (needsSeparator) {
        buffer.writeln();
      } else {
        needsSeparator = true;
      }
      switch (element) {
        case ClassElement():
          summarizeClass(element);
        case EnumElement():
          summarizeEnum(element);
        case ExtensionElement():
          summarizeExtension(element);
        case ExtensionTypeElement():
          summarizeExtensionType(element);
        case GetterElement():
          summarizeGetter(element);
        case MixinElement():
          summarizeMixin(element);
        case SetterElement():
          summarizeSetter(element);
        case TopLevelFunctionElement():
          summarizeFunction(element);
        case TopLevelVariableElement():
          summarizeVariable(element);
        case TypeAliasElement():
          summarizeTypeAlias(element);
        default:
          throw 'Unhandled element class ${element.runtimeType}.';
      }
    }
    return buffer.toString();
  }

  void summarizeClass(ClassElement element) {
    var name = element.name;
    if (name == null) {
      return;
    }

    if (element.isAbstract) {
      buffer.write('abstract ');
    }
    if (element.isBase) {
      buffer.write('base ');
    }
    if (element.isFinal) {
      buffer.write('final ');
    }
    if (element.isInterface) {
      buffer.write('interface ');
    }
    if (element.isSealed) {
      buffer.write('sealed ');
    }
    buffer.write('class $name');
    summarizeExtends(element.supertype);
    summarizeWith(element.mixins);
    summarizeImplements(element.interfaces);
    buffer.writeln(' {');
    summarizeSequence(element.fields, summarizeField);
    summarizeSequence(element.constructors, summarizeConstructor);
    summarizeSequence(element.getters, summarizeGetter);
    summarizeSequence(element.setters, summarizeSetter);
    summarizeSequence(element.methods, summarizeMethod);
    buffer.writeln('}');
  }

  void summarizeConstructor(ConstructorElement element) {
    buffer.write('  ');
    if (element.isFactory) {
      buffer.write('factory ');
    }
    if (element.isConst) {
      buffer.write('const ');
    }
    buffer.write(element.enclosingElement.name!);
    var name = element.name;
    if (name != null && name != 'new') {
      buffer.write('.$name');
    }
    summarizeTypeParameterList(element.typeParameters);
    summarizeFormalParameterList(element.formalParameters);
    buffer.writeln(';');
  }

  void summarizeEnum(EnumElement element) {
    var name = element.name;
    if (name == null) return;

    buffer.write('enum $name');
    var supertype = element.supertype;
    if (!(supertype?.isDartCoreEnum ?? false)) {
      summarizeExtends(supertype);
    }
    summarizeWith(element.mixins);
    summarizeImplements(element.interfaces);
    buffer.writeln(' {');
    buffer.write('  ');
    summarizeList(element.constants, summarizeEnumConstant);
    buffer.writeln(';');
    summarizeSequence(element.fields, summarizeField);
    summarizeSequence(element.constructors, summarizeConstructor);
    summarizeSequence(element.getters, summarizeGetter);
    summarizeSequence(element.setters, summarizeSetter);
    summarizeSequence(element.methods, summarizeMethod);
    buffer.writeln('}');
  }

  void summarizeEnumConstant(FieldElement element) {
    var name = element.name;
    if (name == null) return;

    buffer.write(name);
  }

  void summarizeExtends(DartType? type) {
    if (type != null) {
      buffer.write(' extends ');
      summarizeType(type);
    }
  }

  void summarizeExtension(ExtensionElement element) {
    var name = element.name;

    buffer.write('extension ');
    if (name != null) {
      buffer.write(name);
      buffer.write(' ');
    }
    buffer.write('on ');
    summarizeType(element.extendedType);
    buffer.writeln(' {');
    summarizeSequence(element.fields, summarizeField);
    summarizeSequence(element.getters, summarizeGetter);
    summarizeSequence(element.setters, summarizeSetter);
    summarizeSequence(element.methods, summarizeMethod);
    buffer.writeln('}');
  }

  void summarizeExtensionType(ExtensionTypeElement element) {
    var name = element.name;
    if (name == null) return;

    var representation = element.representation;
    buffer.write('extension type ');
    buffer.write(name);
    buffer.write('(');
    buffer.write(representation.type);
    buffer.write(' ');
    buffer.write(representation.name!);
    buffer.write(')');
    summarizeImplements(element.interfaces);
    buffer.writeln(' {');
    summarizeSequence(element.getters, summarizeGetter);
    summarizeSequence(element.setters, summarizeSetter);
    summarizeSequence(element.methods, summarizeMethod);
    buffer.writeln('}');
  }

  void summarizeField(FieldElement element) {
    if (element.isOriginGetterSetter ||
        element.isEnumConstant ||
        element.isOriginEnumValues) {
      return;
    }

    var name = element.name;
    if (name == null) return;

    buffer.write('  ');
    if (element.isStatic) {
      buffer.write('static ');
    }
    if (element.isConst) {
      buffer.write('const ');
    }
    if (element.isFinal) {
      buffer.write('final ');
    }
    if (element.isLate) {
      buffer.write('late ');
    }
    summarizeType(element.type);
    buffer.write(' ');
    buffer.write(name);
    buffer.writeln(';');
  }

  void summarizeFormalParameter(FormalParameterElement element) {
    var name = element.name;
    if (name == null) return;

    if (element.isRequiredNamed) {
      buffer.write('required ');
    }
    if (element.isInitializingFormal) {
      buffer.write('this.');
    } else if (element.isSuperFormal) {
      buffer.write('super.');
    } else {
      if (element.isFinal) {
        buffer.write('final ');
      }
      if (element.isCovariant) {
        buffer.write('covariant ');
      }
      summarizeType(element.type);
      buffer.write(' ');
    }
    buffer.write(name);
  }

  void summarizeFormalParameterList(List<FormalParameterElement> parameters) {
    buffer.write('(');
    var separator = '';
    var closingBracket = '';
    var lastWasPositional = true;
    for (var element in parameters) {
      buffer.write(separator);
      if (lastWasPositional && !element.isRequiredPositional) {
        lastWasPositional = false;
        if (element.isNamed) {
          buffer.write('{');
          closingBracket = '}';
        } else {
          buffer.write('[');
          closingBracket = ']';
        }
      }
      summarizeFormalParameter(element);
      separator = ', ';
    }
    buffer.write(closingBracket);
    buffer.write(')');
  }

  void summarizeFunction(TopLevelFunctionElement element) {
    var name = element.name;
    if (name == null) return;

    summarizeType(element.returnType);
    buffer.write(' ');
    buffer.write(name);
    summarizeTypeParameterList(element.typeParameters);
    summarizeFormalParameterList(element.formalParameters);
    buffer.writeln(';');
  }

  void summarizeGetter(GetterElement element) {
    if (element.isOriginVariable) return;

    var name = element.name;
    if (name == null) return;

    if (element.enclosingElement is! LibraryElement) {
      buffer.write('  ');
    }
    summarizeType(element.returnType);
    buffer.write(' get ');
    buffer.write(name);
    buffer.writeln(';');
  }

  void summarizeImplements(List<DartType> types) {
    if (types.isEmpty) return;

    buffer.write(' implements ');
    summarizeTypes(types);
    buffer.write(' ');
  }

  void summarizeImport(LibraryImport libraryImport) {
    if (libraryImport.isSynthetic) return;
    buffer.write("import '");
    buffer.write(libraryImport.uri.uriString);
    buffer.write("'");
    if (libraryImport.prefix?.name case var prefix?) {
      buffer.write(' as ');
      buffer.write(prefix);
    }
    for (var combinator in libraryImport.combinators) {
      if (combinator is ShowElementCombinator) {
        var prefix = ' show ';
        for (var name in combinator.shownNames) {
          buffer.write(prefix);
          buffer.write(name);
          prefix = ', ';
        }
      } else if (combinator is HideElementCombinator) {
        var prefix = ' hide ';
        for (var name in combinator.hiddenNames) {
          buffer.write(prefix);
          buffer.write(name);
          prefix = ', ';
        }
      }
    }
    buffer.writeln(';');
  }

  void summarizeList<E>(List<E> list, void Function(E) summarizeElement) {
    var separator = '';
    for (var element in list) {
      buffer.write(separator);
      summarizeElement(element);
      separator = ', ';
    }
  }

  void summarizeMethod(MethodElement element) {
    var name = element.name;
    if (name == null) return;

    buffer.write('  ');
    if (element.isStatic) {
      buffer.write('static ');
    }
    summarizeType(element.returnType);
    buffer.write(' ');
    if (element.isOperator) {
      buffer.write('operator ');
    }
    buffer.write(name);
    summarizeTypeParameterList(element.typeParameters);
    summarizeFormalParameterList(element.formalParameters);
    buffer.writeln(';');
  }

  void summarizeMixin(MixinElement element) {
    var name = element.name;
    if (name == null) return;

    if (element.isBase) {
      buffer.write('base ');
    }
    buffer.write('mixin $name');
    summarizeSuperclassConstraints(element.superclassConstraints);
    summarizeExtends(element.supertype);
    summarizeWith(element.mixins);
    summarizeImplements(element.interfaces);
    buffer.writeln(' {');
    summarizeSequence(element.fields, summarizeField);
    summarizeSequence(element.constructors, summarizeConstructor);
    summarizeSequence(element.getters, summarizeGetter);
    summarizeSequence(element.setters, summarizeSetter);
    summarizeSequence(element.methods, summarizeMethod);
    buffer.writeln('}');
  }

  void summarizeSequence<E>(List<E> list, void Function(E) summarizeElement) {
    for (var element in list) {
      summarizeElement(element);
    }
  }

  void summarizeSetter(SetterElement element) {
    if (element.isOriginVariable) return;

    var name = element.name;
    if (name == null) return;

    if (element.enclosingElement is! LibraryElement) {
      buffer.write('  ');
    }
    buffer.write('set ');
    buffer.write(name);
    summarizeFormalParameterList(element.formalParameters);
    buffer.writeln(';');
  }

  void summarizeSuperclassConstraints(List<DartType> types) {
    if (types.isEmpty) return;

    buffer.write(' on ');
    summarizeTypes(types);
  }

  void summarizeType(DartType type) {
    if (type is InterfaceType) {
      var arguments = type.typeArguments;
      if (arguments.isEmpty || !arguments.any((p) => p is! DynamicType)) {
        buffer.write(type.element.name);
        return;
      }
    }
    buffer.write(type.getDisplayString());
  }

  void summarizeTypeAlias(TypeAliasElement element) {
    var name = element.name;
    if (name == null) return;

    buffer.write('typedef ');
    buffer.write(name);
    buffer.write(' = ');
    summarizeType(element.aliasedType);
    buffer.writeln(';');
  }

  void summarizeTypeParameter(TypeParameterElement element) {
    var name = element.name;
    if (name == null) return;

    buffer.write(name);
    var bound = element.bound;
    if (bound != null) {
      buffer.write(' extends ');
      summarizeType(bound);
    }
  }

  void summarizeTypeParameterList(List<TypeParameterElement> parameters) {
    if (parameters.isEmpty || !parameters.any((p) => p is DynamicType)) return;

    buffer.write('<');
    summarizeList(parameters, summarizeTypeParameter);
    buffer.write('>');
  }

  void summarizeTypes(List<DartType> types) {
    summarizeList(types, summarizeType);
  }

  void summarizeVariable(TopLevelVariableElement element) {
    var name = element.name;
    if (name == null) return;

    if (element.isConst) {
      buffer.write('const ');
    }
    if (element.isFinal) {
      buffer.write('final ');
    }
    summarizeType(element.type);
    buffer.write(' ');
    buffer.write(name);
    buffer.writeln(';');
  }

  void summarizeWith(List<DartType> types) {
    if (types.isEmpty) return;

    buffer.write(' with ');
    summarizeTypes(types);
  }
}

extension on DirectiveUri {
  String get uriString => switch (this) {
    DirectiveUriWithLibrary(:var source) => source.uri.toString(),
    DirectiveUriWithRelativeUriString(:var relativeUriString) =>
      relativeUriString,
    DirectiveUri() => throw UnimplementedError(
      'Unhandled instance of type $runtimeType',
    ),
  };
}
