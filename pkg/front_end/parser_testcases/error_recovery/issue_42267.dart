void main() {
  builder..foo[bar];
  FilterSet((builder) => builder..foo[bar]);
  builder..foo[];
  FilterSet((builder) => builder..foo[]);
  builder..foo[ ];
  FilterSet((builder) => builder..foo[ ]);
}