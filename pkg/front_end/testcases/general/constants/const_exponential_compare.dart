class Class {
  final Class? next1;
  final Class? next2;
  const Class([Class? next])
      : next1 = next,
        next2 = next;
}

const Class test = const Class(Class(Class(Class(Class(Class(Class(Class(Class(
    Class(Class(Class(Class(Class(
        Class(Class(Class(Class(Class(Class(Class(Class())))))))))))))))))))));
