import 'package:macros/macros.dart';

import 'declare_count0_macro.dart';

@DeclareCount0()
macro class DeclareCount1 implements ClassDeclarationsMacro {
  const DeclareCount1();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromString('int get count => ${count + 1};'));
  }
}
