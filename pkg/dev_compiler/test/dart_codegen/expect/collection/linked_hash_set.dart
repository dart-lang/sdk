part of dart.collection;
 abstract class LinkedHashSet<E> implements HashSet<E> {external factory LinkedHashSet({
  bool equals(E e1, E e2), int hashCode(E e), bool isValidKey(potentialKey)}
);
 external factory LinkedHashSet.identity();
 factory LinkedHashSet.from(Iterable<E> elements) {
  LinkedHashSet<E> result = new LinkedHashSet<E>();
   for (final E element in elements) {
    result.add(element);
    }
   return result;
  }
 void forEach(void action(E element));
 Iterator<E> get iterator;
}
