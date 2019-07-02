; RUN: %codegen %s > %t

define i32 @mult(i32, i32) {
  %3 = mul i32 %0, %1
  ret i32 %3
}
