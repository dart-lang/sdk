// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/fake.dart';
import 'package:test/test.dart';

import 'package:_fe_analyzer_shared/src/macros/executor_shared/response_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

void main() {
  group('MacroInstanceIdentifierImpl', () {
    test('shouldExecute', () {
      for (var kind in DeclarationKind.values) {
        for (var phase in Phase.values) {
          var instance = instancesByKindAndPhase[kind]![phase]!;
          for (var otherKind in DeclarationKind.values) {
            for (var otherPhase in Phase.values) {
              var expected = false;
              if (otherPhase == phase) {
                if (kind == otherKind) {
                  expected = true;
                } else if (kind == DeclarationKind.function &&
                    otherKind == DeclarationKind.method) {
                  expected = true;
                } else if (kind == DeclarationKind.variable &&
                    otherKind == DeclarationKind.field) {
                  expected = true;
                }
              }
              expect(instance.shouldExecute(otherKind, otherPhase), expected,
                  reason: 'Expected a $kind macro in $phase to '
                      '${expected ? '' : 'not '}be applied to a $otherKind '
                      'in $otherPhase');
            }
          }
        }
      }
    });

    test('supportsDeclarationKind', () {
      for (var kind in DeclarationKind.values) {
        for (var phase in Phase.values) {
          var instance = instancesByKindAndPhase[kind]![phase]!;
          for (var otherKind in DeclarationKind.values) {
            var expected = false;
            if (kind == otherKind) {
              expected = true;
            } else if (kind == DeclarationKind.function &&
                otherKind == DeclarationKind.method) {
              expected = true;
            } else if (kind == DeclarationKind.variable &&
                otherKind == DeclarationKind.field) {
              expected = true;
            }
            expect(instance.supportsDeclarationKind(otherKind), expected,
                reason: 'Expected a $kind macro to ${expected ? '' : 'not '}'
                    'support a $otherKind');
          }
        }
      }
    });
  });
}

final Map<DeclarationKind, Map<Phase, MacroInstanceIdentifierImpl>>
    instancesByKindAndPhase = {
  DeclarationKind.clazz: {
    Phase.types: MacroInstanceIdentifierImpl(FakeClassTypesMacro()),
    Phase.declarations:
        MacroInstanceIdentifierImpl(FakeClassDeclarationsMacro()),
    Phase.definitions: MacroInstanceIdentifierImpl(FakeClassDefinitionMacro()),
  },
  DeclarationKind.constructor: {
    Phase.types: MacroInstanceIdentifierImpl(FakeConstructorTypesMacro()),
    Phase.declarations:
        MacroInstanceIdentifierImpl(FakeConstructorDeclarationsMacro()),
    Phase.definitions:
        MacroInstanceIdentifierImpl(FakeConstructorDefinitionMacro()),
  },
  DeclarationKind.field: {
    Phase.types: MacroInstanceIdentifierImpl(FakeFieldTypesMacro()),
    Phase.declarations:
        MacroInstanceIdentifierImpl(FakeFieldDeclarationsMacro()),
    Phase.definitions: MacroInstanceIdentifierImpl(FakeFieldDefinitionMacro()),
  },
  DeclarationKind.function: {
    Phase.types: MacroInstanceIdentifierImpl(FakeFunctionTypesMacro()),
    Phase.declarations:
        MacroInstanceIdentifierImpl(FakeFunctionDeclarationsMacro()),
    Phase.definitions:
        MacroInstanceIdentifierImpl(FakeFunctionDefinitionMacro()),
  },
  DeclarationKind.method: {
    Phase.types: MacroInstanceIdentifierImpl(FakeMethodTypesMacro()),
    Phase.declarations:
        MacroInstanceIdentifierImpl(FakeMethodDeclarationsMacro()),
    Phase.definitions: MacroInstanceIdentifierImpl(FakeMethodDefinitionMacro()),
  },
  DeclarationKind.variable: {
    Phase.types: MacroInstanceIdentifierImpl(FakeVariableTypesMacro()),
    Phase.declarations:
        MacroInstanceIdentifierImpl(FakeVariableDeclarationsMacro()),
    Phase.definitions:
        MacroInstanceIdentifierImpl(FakeVariableDefinitionMacro()),
  },
};

class FakeClassTypesMacro extends Fake implements ClassTypesMacro {}

class FakeClassDeclarationsMacro extends Fake
    implements ClassDeclarationsMacro {}

class FakeClassDefinitionMacro extends Fake implements ClassDefinitionMacro {}

class FakeConstructorTypesMacro extends Fake implements ConstructorTypesMacro {}

class FakeConstructorDeclarationsMacro extends Fake
    implements ConstructorDeclarationsMacro {}

class FakeConstructorDefinitionMacro extends Fake
    implements ConstructorDefinitionMacro {}

class FakeFieldTypesMacro extends Fake implements FieldTypesMacro {}

class FakeFieldDeclarationsMacro extends Fake
    implements FieldDeclarationsMacro {}

class FakeFieldDefinitionMacro extends Fake implements FieldDefinitionMacro {}

class FakeFunctionTypesMacro extends Fake implements FunctionTypesMacro {}

class FakeFunctionDeclarationsMacro extends Fake
    implements FunctionDeclarationsMacro {}

class FakeFunctionDefinitionMacro extends Fake
    implements FunctionDefinitionMacro {}

class FakeMethodTypesMacro extends Fake implements MethodTypesMacro {}

class FakeMethodDeclarationsMacro extends Fake
    implements MethodDeclarationsMacro {}

class FakeMethodDefinitionMacro extends Fake implements MethodDefinitionMacro {}

class FakeVariableTypesMacro extends Fake implements VariableTypesMacro {}

class FakeVariableDeclarationsMacro extends Fake
    implements VariableDeclarationsMacro {}

class FakeVariableDefinitionMacro extends Fake
    implements VariableDefinitionMacro {}
