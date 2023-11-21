// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/*macro*/ class ReportAtTargetDeclaration
    implements
        ClassTypesMacro,
        ConstructorTypesMacro,
        FieldTypesMacro,
        MethodTypesMacro {
  const ReportAtTargetDeclaration();

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

  void _report(Declaration declaration, Builder builder) {
    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: declaration.asDiagnosticTarget,
        ),
        Severity.warning,
      ),
    );
  }
}

/*macro*/ class ReportWithContextMessages implements ClassDeclarationsMacro {
  const ReportWithContextMessages();

  @override
  buildDeclarationsForClass(declaration, builder) async {
    final methods = await builder.methodsOf(declaration);
    builder.report(
      Diagnostic(
        DiagnosticMessage(
          'Reported message',
          target: declaration.asDiagnosticTarget,
        ),
        Severity.warning,
        contextMessages: methods.map((method) {
          return DiagnosticMessage(
            'See ${method.identifier.name}',
            target: method.asDiagnosticTarget,
          );
        }).toList(),
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
