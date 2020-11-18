// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import 'package:dev_compiler/src/kernel/expression_compiler.dart';
import 'package:front_end/src/api_prototype/standard_file_system.dart';
import 'package:front_end/src/api_unstable/ddc.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart';
import 'package:kernel/ast.dart';
import 'package:kernel/binary/ast_from_binary.dart';
import 'package:kernel/src/printer.dart';
import 'package:test/test.dart';

/// Verbose mode for debugging
bool get verbose => false;

Uri get sdkRoot => computePlatformBinariesLocation();
Uri get sdkSummaryPath => sdkRoot.resolve('ddc_sdk.dill');
Uri get librariesPath => sdkRoot.resolve('lib/libraries.json');

void main(List<String> args) {
  test('Offsets are present on scoping nodes in SDK', () async {
    var entity = StandardFileSystem.instance.entityForUri(sdkSummaryPath);
    var bytes = await entity.readAsBytes();

    var component = Component();
    BinaryBuilderWithMetadata(bytes, disableLazyReading: true)
        .readComponent(component, checkCanonicalNames: true, createView: true);

    for (var lib in component.libraries) {
      ScopeOffsetValidator.validate(lib);
    }
  });
}

class ScopeOffsetValidator extends Visitor<void> {
  int classCount = 0;
  int memberCount = 0;
  int blockCount = 0;

  ScopeOffsetValidator._();

  static void validate(Library library) {
    var validator = ScopeOffsetValidator._();
    validator.visitLibrary(library);
    expect(validator.classCount + validator.memberCount, greaterThan(0),
        reason: 'Validation was not empty');
    expect(validator.blockCount, equals(0),
        reason: 'SDK dill only contains outlines');
  }

  @override
  void defaultTreeNode(Node node) {
    node.visitChildren(this);
  }

  @override
  void visitClass(Class cls) {
    classCount++;
    expect(
        cls,
        const TypeMatcher<Class>()
            .having((c) => c.fileOffset, '${cls.name} : fileOffset',
                isNot(equals(-1)))
            .having((c) => c.fileEndOffset, '${cls.name} : fileEndOffset',
                isNot(equals(-1))));

    super.visitClass(cls);
  }

  @override
  void defaultMember(Member member) {
    // exclude code that does not correspond to a dart source
    // location we can set a breakpoint on.
    var noBreakPointPossible = (member is Constructor)
        ? member.isSynthetic
        : (member is Procedure)
            ? member.isNoSuchMethodForwarder ||
                member.isAbstract ||
                member.isForwardingStub
            : (member is Field)
                ? member.name.name.contains(redirectingName)
                : false;

    if (!noBreakPointPossible) {
      memberCount++;
      expect(
          member,
          const TypeMatcher<Member>()
              .having(
                  (c) => c.fileOffset,
                  '${member.enclosingClass}.${member.name} : fileOffset',
                  isNot(equals(-1)))
              .having(
                  (c) => c.fileEndOffset,
                  '${member.enclosingClass}.${member.name} : fileEndOffset',
                  isNot(equals(-1))));

      super.defaultMember(member);
    }
  }

  @override
  void visitFunctionNode(FunctionNode fun) {
    expect(
        fun,
        const TypeMatcher<FunctionNode>()
            .having(
                (c) => c.fileOffset,
                '${fun.parent.toText(astTextStrategyForTesting)} : fileOffset',
                isNot(equals(-1)))
            .having(
                (c) => c.fileEndOffset,
                '${fun.parent.toText(astTextStrategyForTesting)} : fileEndOffset',
                isNot(equals(-1))));

    super.visitFunctionNode(fun);
  }

  @override
  void visitBlock(Block block) {
    blockCount++;
    expect(
        block,
        const TypeMatcher<FunctionNode>().having(
            (c) => c.fileOffset,
            '${block.toText(astTextStrategyForTesting)} : fileOffset',
            isNot(equals(-1))));

    var fileEndOffset = FileEndOffsetCalculator.calculateEndOffset(block);
    expect(fileEndOffset, isNot(equals(-1)),
        reason: '${block.toText(astTextStrategyForTesting)} : fileOffset');

    super.visitBlock(block);
  }
}
