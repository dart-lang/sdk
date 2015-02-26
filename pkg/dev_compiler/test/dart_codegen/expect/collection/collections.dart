part of dart.collection;
 class UnmodifiableListView<E> extends UnmodifiableListBase<E> {final Iterable<E> _source;
 UnmodifiableListView(Iterable<E> source) : _source = source;
 int get length => _source.length;
 E operator [](int index) => _source.elementAt(index);
}
