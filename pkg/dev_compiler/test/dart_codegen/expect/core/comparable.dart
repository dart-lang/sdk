part of dart.core;
 typedef int Comparator<T>(T a, T b);
 abstract class Comparable<T> {int compareTo(T other);
 static int compare(Comparable a, Comparable b) => a.compareTo(b);
}
