class Hest<TypeX extends Fisk> {}
//                       ^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

typedef Fisk = void Function // don't merge lines
<<<<<<< HEAD
// [error line 5, column 1, length 346]
=======
// [error line 7, column 9, length 4]
>>>>>>> bugfix: update test fix
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
//      ^
// [cfe] Generic type 'Fisk' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through 'Hest'.
    <TypeY extends Hest>();
//                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

main() {
  Hest hest = new Hest();
}
