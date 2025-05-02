class Hest<TypeX extends Fisk> {}
//                       ^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

typedef Fisk =
    //  ^^^^
    // [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
    // [cfe] Generic type 'Fisk' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through 'Hest'.
    void Function // don't merge lines
    <TypeY extends Hest>();
//                 ^^^^
// [analyzer] COMPILE_TIME_ERROR.NOT_INSTANTIATED_BOUND

main() {
  Hest hest = new Hest();
}
