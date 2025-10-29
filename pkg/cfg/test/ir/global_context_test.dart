// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cfg/ir/global_context.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/type_environment.dart';
import 'package:test/test.dart';
import '../test_helpers.dart';

void main() {
  final component = readVmPlatformKernelFile();
  final coreTypes = CoreTypes(component);
  final classHierarchy = ClassHierarchy(component, coreTypes);
  final typeEnvironment = TypeEnvironment(coreTypes, classHierarchy);

  tearDown(() {
    GlobalContext.setCurrentContext(null);
  });

  group("withContext", () {
    test('simple', () {
      final ctx = GlobalContext(typeEnvironment: typeEnvironment);

      expect(() => GlobalContext.instance, throwsStateError);
      expect(
        GlobalContext.withContext(ctx, () {
          expect(GlobalContext.instance, same(ctx));
          return 42;
        }),
        equals(42),
      );
      expect(() => GlobalContext.instance, throwsStateError);
    });

    test('nested', () {
      final ctx1 = GlobalContext(typeEnvironment: typeEnvironment);
      final ctx2 = GlobalContext(typeEnvironment: typeEnvironment);

      expect(() => GlobalContext.instance, throwsStateError);
      expect(
        GlobalContext.withContext(ctx1, () {
          expect(GlobalContext.instance, same(ctx1));

          expect(
            GlobalContext.withContext(ctx2, () {
              expect(GlobalContext.instance, same(ctx2));
              return 12;
            }),
            equals(12),
          );

          expect(GlobalContext.instance, same(ctx1));
          return 11;
        }),
        equals(11),
      );
      expect(() => GlobalContext.instance, throwsStateError);
    });

    test('exception', () {
      final ctx1 = GlobalContext(typeEnvironment: typeEnvironment);
      final ctx2 = GlobalContext(typeEnvironment: typeEnvironment);

      expect(() => GlobalContext.instance, throwsStateError);
      expect(
        () => GlobalContext.withContext(ctx1, () {
          expect(GlobalContext.instance, same(ctx1));
          throw Exception();
        }),
        throwsException,
      );
      expect(() => GlobalContext.instance, throwsStateError);

      GlobalContext.withContext(ctx1, () {
        expect(GlobalContext.instance, same(ctx1));

        expect(
          () => GlobalContext.withContext(ctx2, () {
            expect(GlobalContext.instance, same(ctx2));
            throw Exception();
          }),
          throwsException,
        );

        expect(GlobalContext.instance, same(ctx1));
      });
      expect(() => GlobalContext.instance, throwsStateError);
    });
  });
}
