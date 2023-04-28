typedef A = int?;

void f(x) {
  switch (x) {
    case A(foo: 0):
//       ^
// [analyzer] COMPILE_TIME_ERROR.UNCHECKED_USE_OF_NULLABLE_VALUE
// [cfe] unspecified
      break;
  }
}
