class A {}

class B extends A {}

final bool kTrue = int.parse('1') == 1;

final dynamic smiValue = kTrue == 1 ? 1 : 'a';
final A barValue = kTrue ? B() : A();

main() {
  // Inlined AssertAssignable has to perform Smi check on LoadClassId.
  smiValue as String;

  // Inlined AssertAssignable can omit Smi check on LoadClassId.
  barValue as B;

  foo<int>(1);
  foo<String>('a');
}

@pragma('vm:never-inline')
T foo<T>(dynamic arg) => arg as T;
