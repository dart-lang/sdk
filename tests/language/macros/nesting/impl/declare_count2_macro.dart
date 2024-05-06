import 'package:macros/macros.dart';

import 'declare_count1_macro.dart';

@DeclareCount1()
macro class DeclareCount2 implements ClassDeclarationsMacro {
  const DeclareCount2();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromString('int get count => ${count + 1};'));
  }
}
