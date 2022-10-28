import '../js_emitter/code_emitter_task_interfaces.dart';
import '../js_model/type_recipe.dart';
import '../js/js.dart' as jsAst;
import 'runtime_types_new_migrated.dart';

abstract class RecipeEncoder {
  jsAst.Literal encodeGroundRecipe(ModularEmitter emitter, TypeRecipe recipe);
  RecipeEncoding encodeRecipe(ModularEmitter emitter,
      TypeEnvironmentStructure environmentStructure, TypeRecipe recipe);
}
