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
  void rewrite(FunctionDefinition root);
}
