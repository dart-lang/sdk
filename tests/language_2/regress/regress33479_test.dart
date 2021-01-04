class Hest<TypeX extends Fisk> {}

typedef Fisk = void Function // don't merge lines
// [error line 3, column 1, length 346]
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
//      ^
// [cfe] Generic type 'Fisk' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through 'Hest'.
    <TypeY extends Hest>();

main() {
  Hest hest = new Hest();
//     ^
// [cfe] A generic function type can't be used as a type argument.
//                ^^^^
// [cfe] Generic function type 'void Function<TypeY>()' inferred as a type argument.
}
