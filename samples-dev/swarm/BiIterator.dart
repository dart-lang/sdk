part of swarmlib;

/**
 * An iterator that allows the user to move forward and backward though
 * a set of items. (Bi-directional)
 */
class BiIterator<E> {
  /**
   * Provides forward and backward iterator functionality to keep track
   * which item is currently selected.
   */
  ObservableValue<int> currentIndex;

  /**
   * The collection of items we will be iterating through.
   */
  List<E> list;

  BiIterator(this.list, [List<ChangeListener> oldListeners = null])
      : currentIndex = new ObservableValue<int>(0) {
    if (oldListeners != null) {
      currentIndex.listeners = oldListeners;
    }
  }

  /**
   * Returns the next section from the sections, given the current
   * position. Returns the last source if there is no next section.
   */
  E next() {
    if (currentIndex.value < list.length - 1) {
      currentIndex.value += 1;
    }
    return list[currentIndex.value];
  }

  /**
   * Returns the current Section (page in the UI) that the user is
   * looking at.
   */
  E get current {
    return list[currentIndex.value];
  }

  /**
   * Returns the previous section from the sections, given the current
   * position. Returns the front section if we are already at the front of
   * the list.
   */
  E previous() {
    if (currentIndex.value > 0) {
      currentIndex.value -= 1;
    }
    return list[currentIndex.value];
  }

  /**
   * Move the iterator pointer over so that it points to a given list item.
   */
  void jumpToValue(E val) {
    for (int i = 0; i < list.length; i++) {
      if (identical(list[i], val)) {
        currentIndex.value = i;
        break;
      }
    }
  }
}
