// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:macros/macros.dart';

int? _verbIndex(String step, String verb) {
  var indexStr = _verbSuffix(step, verb);
  if (indexStr != null) {
    return int.parse(indexStr);
  }
  return null;
}

String? _verbSuffix(String step, String verb) {
  var prefix = '$verb ';
  if (step.startsWith(prefix)) {
    return step.substring(prefix.length);
  }
  return null;
}

/*macro*/ class AskFieldsWillThrow implements ClassDefinitionMacro {
  const AskFieldsWillThrow();

  @override
  buildDefinitionForClass(declaration, builder) async {
    // We expect that the analyzer will throw an exception.
    // This simulates a bug in the analyzer, e.g. something not implemented.
    await builder.fieldsOf(declaration);
  }
}

/*macro*/ class MacroWithArguments implements ClassDeclarationsMacro {
  final Object? a1;
  final Object? a2;

  const MacroWithArguments(this.a1, this.a2);

  @override
  buildDeclarationsForClass(declaration, builder) {}
}

/*macro*/ class NothingMacro
    implements ClassTypesMacro, ClassDeclarationsMacro, ClassDefinitionMacro {
  const NothingMacro();

  @override
  buildDeclarationsForClass(clazz, builder) {}

  @override
  buildDefinitionForClass(clazz, builder) {}

  @override
  buildTypesForClass(clazz, builder) {}
}

/*macro*/ class ReportAtDeclaration
    implements
        ClassDeclarationsMacro,
        FunctionDeclarationsMacro,
        MethodDeclarationsMacro,
        MixinDeclarationsMacro,
        TypeAliasDeclarationsMacro {
  final List<String> pathList;

  const ReportAtDeclaration(this.pathList);

  @override
  buildDeclarationsForClass(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForFunction(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForMethod(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForMixin(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForTypeAlias(declaration, builder) async {
    await _report(declaration, builder);
  }

  Future<Declaration> _getTarget(
    Declaration declaration,
    DeclarationBuilder builder,
  ) async {
    var current = await _nextTarget(builder, declaration, pathList.first);
    for (var step in pathList.skip(1)) {
      current = await _nextTarget(builder, current, step);
    }
    return current;
  }

  Future<Declaration> _nextTarget(
    DeclarationBuilder builder,
    Object current,
    String step,
  ) async {
    if (current is FunctionDeclaration) {
      if (_verbIndex(step, 'typeParameter') case var index?) {
        return current.typeParameters.elementAt(index);
      }
    }

    if (current is MethodDeclaration) {
      if (_verbIndex(step, 'typeParameter') case var index?) {
        return current.typeParameters.elementAt(index);
      }
    }

    if (current is ParameterizedTypeDeclaration) {
      if (_verbIndex(step, 'typeParameter') case var index?) {
        return current.typeParameters.elementAt(index);
      }
    }

    throw UnimplementedError('[current: $current][step: $step]');
  }

  Future<void> _report(
    Declaration declaration,
    DeclarationBuilder builder,
  ) async {
    var target = await _getTarget(declaration, builder);
    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: target.asDiagnosticTarget,
        ),
        Severity.warning,
      ),
    );
  }
}

/*macro*/ class ReportAtFirstMethod implements ClassDeclarationsMacro {
  const ReportAtFirstMethod();

  Severity get _severity => Severity.warning;

  @override
  buildDeclarationsForClass(declaration, builder) async {
    var methods = await builder.methodsOf(declaration);
    if (methods case [var method, ...]) {
      builder.report(
        Diagnostic(
          DiagnosticMessage(
            'Reported message',
            target: method.asDiagnosticTarget,
          ),
          _severity,
        ),
      );
    }
  }
}

/*macro*/ class ReportAtTargetAnnotation implements ClassTypesMacro {
  final int annotationIndex;

  const ReportAtTargetAnnotation(this.annotationIndex);

  Severity get _severity => Severity.warning;

  @override
  buildTypesForClass(declaration, builder) {
    _report(declaration, builder);
  }

  void _report(Declaration declaration, Builder builder) {
    var annotation = declaration.metadata.elementAt(annotationIndex);
    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: annotation.asDiagnosticTarget,
        ),
        _severity,
        correctionMessage: 'Correction message',
      ),
    );
  }
}

/*macro*/ class ReportAtTargetDeclaration
    implements
        ClassTypesMacro,
        ConstructorTypesMacro,
        FieldTypesMacro,
        MethodTypesMacro,
        MixinTypesMacro {
  const ReportAtTargetDeclaration();

  Severity get _severity => Severity.warning;

  @override
  buildTypesForClass(declaration, builder) {
    _report(declaration, builder);
  }

  @override
  buildTypesForConstructor(declaration, builder) {
    _report(declaration, builder);
  }

  @override
  buildTypesForField(declaration, builder) {
    _report(declaration, builder);
  }

  @override
  buildTypesForMethod(declaration, builder) {
    _report(declaration, builder);
  }

  @override
  buildTypesForMixin(declaration, builder) {
    _report(declaration, builder);
  }

  void _report(Declaration declaration, Builder builder) {
    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: declaration.asDiagnosticTarget,
        ),
        _severity,
        correctionMessage: 'Correction message',
      ),
    );
  }
}

/*macro*/ class ReportAtTypeAnnotation
    implements
        ClassDeclarationsMacro,
        ConstructorDeclarationsMacro,
        FunctionDeclarationsMacro,
        FieldDeclarationsMacro,
        MethodDeclarationsMacro,
        TypeAliasDeclarationsMacro,
        VariableDeclarationsMacro {
  final List<String> pathList;

  const ReportAtTypeAnnotation(this.pathList);

  @override
  buildDeclarationsForClass(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForConstructor(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForField(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForFunction(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForMethod(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  Future<void> buildDeclarationsForTypeAlias(declaration, builder) async {
    await _report(declaration, builder);
  }

  @override
  buildDeclarationsForVariable(declaration, builder) async {
    await _report(declaration, builder);
  }

  Future<TypeAnnotation> _getTarget(
    Declaration declaration,
    DeclarationBuilder builder,
  ) async {
    var current = await _nextTarget(builder, declaration, pathList.first);
    for (var step in pathList.skip(1)) {
      current = await _nextTarget(builder, current, step);
    }
    return current;
  }

  Future<TypeAnnotation> _nextTarget(
    DeclarationBuilder builder,
    Object current,
    String step,
  ) async {
    if (current is ClassDeclaration) {
      if (step == 'superclass') {
        return current.superclass!;
      }
    }

    if (current is ConstructorDeclaration) {
      if (_verbIndex(step, 'namedFormalParameterType') case var index?) {
        return current.namedParameters.elementAt(index).type;
      }
      if (_verbIndex(step, 'positionalFormalParameterType') case var index?) {
        return current.positionalParameters.elementAt(index).type;
      }
    }

    if (current is MemberDeclaration) {
      if (_verbSuffix(step, 'field') case var fieldName?) {
        var definingType = await builder.typeDeclarationOf(
          current.definingType,
        );
        var fields = await builder.fieldsOf(definingType);
        var field = fields.singleWhere((field) {
          return field.identifier.name == fieldName;
        });
        return field.type;
      }
    }

    if (current is FunctionDeclaration) {
      if (step == 'returnType') {
        return current.returnType;
      }
      if (_verbIndex(step, 'namedFormalParameterType') case var index?) {
        return current.namedParameters.elementAt(index).type;
      }
      if (_verbIndex(step, 'positionalFormalParameterType') case var index?) {
        return current.positionalParameters.elementAt(index).type;
      }
    }

    if (current is FunctionTypeAnnotation) {
      if (step == 'returnType') {
        return current.returnType;
      }
      if (_verbIndex(step, 'namedFormalParameterType') case var index?) {
        return current.namedParameters.elementAt(index).type;
      }
      if (_verbIndex(step, 'positionalFormalParameterType') case var index?) {
        return current.positionalParameters.elementAt(index).type;
      }
    }

    if (current is NamedTypeAnnotation) {
      if (_verbIndex(step, 'namedTypeArgument') case var index?) {
        return current.typeArguments.elementAt(index);
      }
    }

    if (current is RecordTypeAnnotation) {
      if (_verbIndex(step, 'namedField') case var index?) {
        return current.namedFields.elementAt(index).type;
      }
      if (_verbIndex(step, 'positionalField') case var index?) {
        return current.positionalFields.elementAt(index).type;
      }
    }

    if (current is TypeAliasDeclaration) {
      if (step == 'aliasedType') {
        return current.aliasedType;
      }
    }

    if (current is VariableDeclaration) {
      if (step == 'variableType') {
        return current.type;
      }
    }

    throw UnimplementedError('[current: $current][step: $step]');
  }

  Future<void> _report(
    Declaration declaration,
    DeclarationBuilder builder,
  ) async {
    var target = await _getTarget(declaration, builder);
    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: target.asDiagnosticTarget,
        ),
        Severity.warning,
      ),
    );
  }
}

/*macro*/ class ReportErrorAtTargetDeclaration
    extends ReportAtTargetDeclaration {
  const ReportErrorAtTargetDeclaration();

  @override
  Severity get _severity => Severity.error;
}

/*macro*/ class ReportInfoAtTargetDeclaration
    extends ReportAtTargetDeclaration {
  const ReportInfoAtTargetDeclaration();

  @override
  Severity get _severity => Severity.info;
}

/*macro*/ class ReportWithContextMessages implements ClassDeclarationsMacro {
  final bool forSuperClass;
  final bool withDeclarationTarget;

  const ReportWithContextMessages({
    this.forSuperClass = false,
    this.withDeclarationTarget = true,
  });

  @override
  buildDeclarationsForClass(declaration, builder) async {
    List<MethodDeclaration> methods;
    if (forSuperClass) {
      var superIdentifier = declaration.superclass!.identifier;
      var superType = await builder.typeDeclarationOf(superIdentifier);
      superType as ClassDeclaration;
      methods = await builder.methodsOf(superType);
    } else {
      methods = await builder.methodsOf(declaration);
    }

    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: withDeclarationTarget ? declaration.asDiagnosticTarget : null,
        ),
        Severity.warning,
        contextMessages: methods.map((method) {
          return DiagnosticMessage(
            'See ${method.identifier.name}',
            target: method.asDiagnosticTarget,
          );
        }).toList(),
        correctionMessage: 'Correction message',
      ),
    );
  }
}

/*macro*/ class ReportWithoutTargetError implements ClassTypesMacro {
  const ReportWithoutTargetError();

  @override
  buildTypesForClass(clazz, builder) {
    builder.report(
      Diagnostic(
        DiagnosticMessage('Reported message'),
        Severity.error,
      ),
    );
  }
}

/*macro*/ class ReportWithoutTargetInfo implements ClassTypesMacro {
  const ReportWithoutTargetInfo();

  @override
  buildTypesForClass(clazz, builder) {
    builder.report(
      Diagnostic(
        DiagnosticMessage('Reported message'),
        Severity.info,
      ),
    );
  }
}

/*macro*/ class ReportWithoutTargetWarning implements ClassTypesMacro {
  const ReportWithoutTargetWarning();

  @override
  buildTypesForClass(clazz, builder) {
    builder.report(
      Diagnostic(
        DiagnosticMessage('Reported message'),
        Severity.warning,
      ),
    );
  }
}

/*macro*/ class TargetClassOrMixinMacro
    implements ClassTypesMacro, MixinTypesMacro {
  const TargetClassOrMixinMacro();

  @override
  buildTypesForClass(declaration, builder) {}

  @override
  buildTypesForMixin(declaration, builder) {}
}

/*macro*/ class ThrowExceptionDeclarationsPhase
    implements
        ClassDeclarationsMacro,
        ConstructorDeclarationsMacro,
        FieldDeclarationsMacro,
        MethodDeclarationsMacro {
  const ThrowExceptionDeclarationsPhase();

  @override
  buildDeclarationsForClass(clazz, builder) {
    _doThrow();
  }

  @override
  buildDeclarationsForConstructor(constructor, builder) {
    _doThrow();
  }

  @override
  buildDeclarationsForField(declaration, builder) {
    _doThrow();
  }

  @override
  buildDeclarationsForMethod(method, builder) {
    _doThrow();
  }

  void _doThrow() {
    throw 'My declarations phase';
  }
}

/*macro*/ class ThrowExceptionDefinitionsPhase implements ClassDefinitionMacro {
  const ThrowExceptionDefinitionsPhase();

  @override
  buildDefinitionForClass(clazz, builder) {
    _doThrow();
  }

  void _doThrow() {
    throw 'My definitions phase';
  }
}

/*macro*/ class ThrowExceptionTypesPhase implements ClassTypesMacro {
  const ThrowExceptionTypesPhase();

  @override
  buildTypesForClass(clazz, builder) {
    _doThrow();
  }

  void _doThrow() {
    throw 'My types phase';
  }
}
