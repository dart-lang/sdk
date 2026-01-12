// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:native_compiler/back_end/back_end_state.dart';
import 'package:cfg/passes/pass.dart';
import 'package:cfg/ir/instructions.dart';
import 'package:cfg/utils/bit_vector.dart';

/// Compute block order for code generation.
///
/// It is similar to the reverse postorder except:
///  - blocks ending with Throw are considered cold and placed at the end.
///  - blocks which have only cold successors are also considered cold.
///  - blocks belonging to a loop are placed together.
final class ReorderBlocks extends Pass {
  final BackEndState backEndState;

  ReorderBlocks(this.backEndState) : super('ReorderBlocks');

  @override
  void run() {
    final numBlocks = graph.preorder.length;
    final visited = BitVector(numBlocks);
    final cold = BitVector(numBlocks);
    final postorder = <Block>[];
    final coldPostorder = <Block>[];
    final workList = <(Block, bool)>[];

    void pushBlock(Block succ) {
      if (!visited[succ.preorderNumber]) {
        visited.add(succ.preorderNumber);
        workList.add((succ, true));
      }
    }

    pushBlock(graph.entryBlock);
    while (workList.isNotEmpty) {
      final (block, discoverSuccessors) = workList.removeLast();
      final successors = block.successors;
      if (discoverSuccessors) {
        // Re-visit block after successors are visited.
        workList.add((block, false));
        final lastInstruction = block.lastInstruction;
        if (lastInstruction is Branch || lastInstruction is CompareAndBranch) {
          // Push successor with lower loop nesting last so
          // it is processed first.
          final succ0 = successors[0];
          final succ1 = successors[1];
          if (succ0.loopDepth < succ1.loopDepth) {
            pushBlock(succ1);
            pushBlock(succ0);
          } else {
            pushBlock(succ0);
            pushBlock(succ1);
          }
        } else {
          for (final succ in successors) {
            pushBlock(succ);
          }
        }
      } else {
        // All successors have been processed.
        // Figure out if block belongs to a cold section.
        var isCold = false;
        switch (block.lastInstruction) {
          case Throw():
            isCold = true;
            break;
          default:
            if (successors.isNotEmpty) {
              isCold = true;
              for (final succ in successors) {
                if (!cold[succ.preorderNumber]) {
                  isCold = false;
                  break;
                }
              }
            }
        }
        if (isCold) {
          cold.add(block.preorderNumber);
          coldPostorder.add(block);
        } else {
          postorder.add(block);
        }
      }
    }

    backEndState.codeGenBlockOrder = <Block>[
      ...postorder.reversed,
      ...coldPostorder.reversed,
    ];
  }
}
