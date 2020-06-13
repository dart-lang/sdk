class Hest<TypeX extends Fisk> {}
//                       ^^^^
// [analyzer] COMPILE_TIME_ERROR.GENERIC_FUNCTION_TYPE_CANNOT_BE_BOUND

typedef Fisk = void Function // don't merge lines
// [error line 5, column 1, length 462]
// [analyzer] COMPILE_TIME_ERROR.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF
//      ^
// [cfe] Generic type 'Fisk' can't be used without type arguments in the bounds of its own type variables. It is referenced indirectly through 'Hest'.
    <TypeY extends Hest>
    //             ^^^^
    // [analyzer] COMPILE_TIME_ERROR.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT
        ();

main() {
  Hest hest = new Hest();
//^^^^
// [analyzer] COMPILE_TIME_ERROR.GENERIC_FUNCTION_TYPE_CANNOT_BE_TYPE_ARGUMENT
//     ^
// [cfe] A generic function type can't be used as a type argument.
//            ^^^^^^^^^^
// [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
//                ^^^^
// [analyzer] COMPILE_TIME_ERROR.COULD_NOT_INFER
// [cfe] Generic function type 'void Function<TypeY>()' inferred as a type argument.
//                ^^^^
// [analyzer] COMPILE_TIME_ERROR.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS
}
