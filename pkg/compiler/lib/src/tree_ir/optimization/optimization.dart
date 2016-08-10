library tree_ir.optimization;

import '../tree_ir_nodes.dart';

export 'logical_rewriter.dart' show LogicalRewriter;
export 'loop_rewriter.dart' show LoopRewriter;
export 'pull_into_initializers.dart' show PullIntoInitializers;
export 'statement_rewriter.dart' show StatementRewriter;
export 'variable_merger.dart' show VariableMerger;

/// An optimization pass over the Tree IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(FunctionDefinition root);

  String get passName;
}
