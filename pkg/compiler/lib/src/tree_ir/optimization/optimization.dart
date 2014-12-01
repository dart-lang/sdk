library tree_ir.optimization;

import '../tree_ir_nodes.dart';
import '../../elements/elements.dart';
import '../../constants/values.dart' as values;

part 'copy_propagator.dart';
part 'logical_rewriter.dart';
part 'loop_rewriter.dart';
part 'statement_rewriter.dart';

/// An optimization pass over the Tree IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(ExecutableDefinition root) => root.applyPass(this);
  void rewriteFieldDefinition(FieldDefinition root);
  void rewriteFunctionDefinition(FunctionDefinition root);
}


abstract class PassMixin implements Pass {
  void rewrite(ExecutableDefinition root) => root.applyPass(this);
  void rewriteExecutableDefinition(ExecutableDefinition root);
  void rewriteFieldDefinition(FieldDefinition root) {
    if (!root.hasInitializer) return;
    rewriteExecutableDefinition(root);
  }
  void rewriteFunctionDefinition(FunctionDefinition root) {
    if (root.isAbstract) return;
    rewriteExecutableDefinition(root);
  }
}