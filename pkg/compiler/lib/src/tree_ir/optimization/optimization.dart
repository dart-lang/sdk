library tree_ir.optimization;

import '../tree_ir_nodes.dart';

export 'statement_rewriter.dart' show StatementRewriter;
export 'variable_merger.dart' show VariableMerger;
export 'loop_rewriter.dart' show LoopRewriter;
export 'logical_rewriter.dart' show LogicalRewriter;
export 'pull_into_initializers.dart' show PullIntoInitializers;

/// An optimization pass over the Tree IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(FunctionDefinition root);

  String get passName;
}
