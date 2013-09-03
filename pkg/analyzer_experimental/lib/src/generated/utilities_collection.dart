// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.
library engine.utilities.collection;
import 'java_core.dart';
/**
 * The class `BooleanArray` defines methods for operating on integers as if they were arrays
 * of booleans. These arrays can be indexed by either integers or by enumeration constants.
 */
class BooleanArray {

  /**
   * Return the value of the element at the given index.
   *
   * @param array the array being accessed
   * @param index the index of the element being accessed
   * @return the value of the element at the given index
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static bool get(int array, Enum index) => get2(array, index.ordinal);

  /**
   * Return the value of the element at the given index.
   *
   * @param array the array being accessed
   * @param index the index of the element being accessed
   * @return the value of the element at the given index
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static bool get2(int array, int index) {
    checkIndex(index);
    return (array & (1 << index)) > 0;
  }

  /**
   * Set the value of the element at the given index to the given value.
   *
   * @param array the array being modified
   * @param index the index of the element being set
   * @param value the value to be assigned to the element
   * @return the updated value of the array
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static int set(int array, Enum index, bool value) => set2(array, index.ordinal, value);

  /**
   * Set the value of the element at the given index to the given value.
   *
   * @param array the array being modified
   * @param index the index of the element being set
   * @param value the value to be assigned to the element
   * @return the updated value of the array
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static int set2(int array, int index, bool value) {
    checkIndex(index);
    if (value) {
      return array | (1 << index);
    } else {
      return array & ~(1 << index);
    }
  }

  /**
   * Throw an exception if the index is not within the bounds allowed for an integer-encoded array
   * of boolean values.
   *
   * @throws IndexOutOfBoundsException if the index is not between zero (0) and 31, inclusive
   */
  static void checkIndex(int index) {
    if (index < 0 || index > 30) {
      throw new RangeError("Index not between 0 and 30: ${index}");
    }
  }
}
/**
 * The class `ListUtilities` defines utility methods useful for working with [List
 ].
 */
class ListUtilities {

  /**
   * Add all of the elements in the given array to the given list.
   *
   * @param list the list to which the elements are to be added
   * @param elements the elements to be added to the list
   */
  static void addAll(List list, List<Object> elements) {
    for (Object element in elements) {
      list.add(element);
    }
  }
}