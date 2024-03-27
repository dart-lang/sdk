import 'package:macros/macros.dart';

macro class DeclareCount0 implements ClassDeclarationsMacro {
  const DeclareCount0();

  @override
  Future<void> buildDeclarationsForClass(
      ClassDeclaration clazz, MemberDeclarationBuilder builder) async {
    builder.declareInType(DeclarationCode.fromString('int get count => 0;'));
  }
}
