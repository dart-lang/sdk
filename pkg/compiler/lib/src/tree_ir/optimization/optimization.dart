library tree_ir.optimization;

import '../tree_ir_nodes.dart';
import '../../constants/values.dart' as values;
import 'variable_merger.dart';

export 'variable_merger.dart' show VariableMerger;

part 'logical_rewriter.dart';
part 'loop_rewriter.dart';
part 'statement_rewriter.dart';

/// An optimization pass over the Tree IR.
abstract class Pass {
  /// Applies optimizations to root, rewriting it in the process.
  void rewrite(RootNode root);

  String get passName;
}
