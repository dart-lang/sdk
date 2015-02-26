part of dart._internal;
 class Sort {static const int _INSERTION_SORT_THRESHOLD = 32;
 static void sort(List a, int compare(a, b)) {
  _doSort(a, 0, a.length - 1, compare);
  }
 static void sortRange(List a, int from, int to, int compare(a, b)) {
  if ((from < 0) || (to > a.length) || (to < from)) {
    throw "OutOfRange";
    }
   _doSort(a, from, to - 1, compare);
  }
 static void _doSort(List a, int left, int right, int compare(a, b)) {
  if ((right - left) <= _INSERTION_SORT_THRESHOLD) {
    _insertionSort(a, left, right, compare);
    }
   else {
    _dualPivotQuicksort(a, left, right, compare);
    }
  }
 static void _insertionSort(List a, int left, int right, int compare(a, b)) {
  for (int i = left + 1; i <= right; i++) {
    var el = a[i];
     int j = i;
     while ((j > left) && (compare(a[j - 1], el) > 0)) {
      a[j] = a[j - 1];
       j--;
      }
     a[j] = el;
    }
  }
 static void _dualPivotQuicksort(List a, int left, int right, int compare(a, b)) {
  assert (right - left > _INSERTION_SORT_THRESHOLD); int sixth = (right - left + 1) ~/ 6;
   int index1 = left + sixth;
   int index5 = right - sixth;
   int index3 = (left + right) ~/ 2;
   int index2 = index3 - sixth;
   int index4 = index3 + sixth;
   var el1 = a[index1];
   var el2 = a[index2];
   var el3 = a[index3];
   var el4 = a[index4];
   var el5 = a[index5];
   if (compare(el1, el2) > 0) {
    var t = el1;
     el1 = el2;
     el2 = t;
    }
   if (compare(el4, el5) > 0) {
    var t = el4;
     el4 = el5;
     el5 = t;
    }
   if (compare(el1, el3) > 0) {
    var t = el1;
     el1 = el3;
     el3 = t;
    }
   if (compare(el2, el3) > 0) {
    var t = el2;
     el2 = el3;
     el3 = t;
    }
   if (compare(el1, el4) > 0) {
    var t = el1;
     el1 = el4;
     el4 = t;
    }
   if (compare(el3, el4) > 0) {
    var t = el3;
     el3 = el4;
     el4 = t;
    }
   if (compare(el2, el5) > 0) {
    var t = el2;
     el2 = el5;
     el5 = t;
    }
   if (compare(el2, el3) > 0) {
    var t = el2;
     el2 = el3;
     el3 = t;
    }
   if (compare(el4, el5) > 0) {
    var t = el4;
     el4 = el5;
     el5 = t;
    }
   var pivot1 = el2;
   var pivot2 = el4;
   a[index1] = el1;
   a[index3] = el3;
   a[index5] = el5;
   a[index2] = a[left];
   a[index4] = a[right];
   int less = left + 1;
   int great = right - 1;
   bool pivots_are_equal = (compare(pivot1, pivot2) == 0);
   if (pivots_are_equal) {
    var pivot = pivot1;
     for (int k = less; k <= great; k++) {
      var ak = a[k];
       int comp = compare(ak, pivot);
       if (comp == 0) continue;
       if (comp < 0) {
        if (k != less) {
          a[k] = a[less];
           a[less] = ak;
          }
         less++;
        }
       else {
        while (true) {
          comp = compare(a[great], pivot);
           if (comp > 0) {
            great--;
             continue;
            }
           else if (comp < 0) {
            a[k] = a[less];
             a[less++] = a[great];
             a[great--] = ak;
             break;
            }
           else {
            a[k] = a[great];
             a[great--] = ak;
             break;
            }
          }
        }
      }
    }
   else {
    for (int k = less; k <= great; k++) {
      var ak = a[k];
       int comp_pivot1 = compare(ak, pivot1);
       if (comp_pivot1 < 0) {
        if (k != less) {
          a[k] = a[less];
           a[less] = ak;
          }
         less++;
        }
       else {
        int comp_pivot2 = compare(ak, pivot2);
         if (comp_pivot2 > 0) {
          while (true) {
            int comp = compare(a[great], pivot2);
             if (comp > 0) {
              great--;
               if (great < k) break;
               continue;
              }
             else {
              comp = compare(a[great], pivot1);
               if (comp < 0) {
                a[k] = a[less];
                 a[less++] = a[great];
                 a[great--] = ak;
                }
               else {
                a[k] = a[great];
                 a[great--] = ak;
                }
               break;
              }
            }
          }
        }
      }
    }
   a[left] = a[less - 1];
   a[less - 1] = pivot1;
   a[right] = a[great + 1];
   a[great + 1] = pivot2;
   _doSort(a, left, less - 2, compare);
   _doSort(a, great + 2, right, compare);
   if (pivots_are_equal) {
    return;}
   if (less < index1 && great > index5) {
    while (compare(a[less], pivot1) == 0) {
      less++;
      }
     while (compare(a[great], pivot2) == 0) {
      great--;
      }
     for (int k = less; k <= great; k++) {
      var ak = a[k];
       int comp_pivot1 = compare(ak, pivot1);
       if (comp_pivot1 == 0) {
        if (k != less) {
          a[k] = a[less];
           a[less] = ak;
          }
         less++;
        }
       else {
        int comp_pivot2 = compare(ak, pivot2);
         if (comp_pivot2 == 0) {
          while (true) {
            int comp = compare(a[great], pivot2);
             if (comp == 0) {
              great--;
               if (great < k) break;
               continue;
              }
             else {
              comp = compare(a[great], pivot1);
               if (comp < 0) {
                a[k] = a[less];
                 a[less++] = a[great];
                 a[great--] = ak;
                }
               else {
                a[k] = a[great];
                 a[great--] = ak;
                }
               break;
              }
            }
          }
        }
      }
     _doSort(a, less, great, compare);
    }
   else {
    _doSort(a, less, great, compare);
    }
  }
}
