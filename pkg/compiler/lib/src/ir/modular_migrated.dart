import 'package:compiler/src/ir/constants.dart';
import 'package:kernel/ast.dart' as ir;

// TODO(48820): Move this back to modular.dart
class ModularCore {
  final ir.Component component;
  final Dart2jsConstantEvaluator constantEvaluator;

  ModularCore(this.component, this.constantEvaluator);
}
