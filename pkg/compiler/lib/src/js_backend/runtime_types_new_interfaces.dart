import '../js_emitter/code_emitter_task_interfaces.dart';
import '../js_model/type_recipe.dart';
import '../js/js.dart' as jsAst;

abstract class RecipeEncoder {
  jsAst.Literal encodeGroundRecipe(ModularEmitter emitter, TypeRecipe recipe);
}
