riak_cql
========

A language for describing Riak CRDT modifications. 


### Update
```
map {
  counter gold inc 10,
	counter stone dec 1,

	set weapons {
		mace,
		sword,
		knowledge,
		"warm beer"
	},

	map foo {
		map bar {
			counter baz inc 1
		}
	}
}
```

### Query
```
.gold                // get the current value of gold
.weapons             // returns the whole set
.weapons.mace?       // does mace exist in the set?
.foo.bar.*           // returns baz and z
.gold, .foo.bar.baz  // return multiple values from one query (comma sep)
.foo.bar.baz         // returns value of baz
.foo.$keys           // use a $ prefix so users can store a "keys" or "values" key
.foo.$values
.foo.$count          // keys + values bolth have the same count, no?
.foo.$type           // return the CRDT type
.foo.bar?            // does foo contain the key bar?
.* return everything
```
