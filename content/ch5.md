home: index.html
prev: ch4.html
next: ch6.html
---
# 5. Arrays, Objects, Functions and JSON

<div class="summary">
In this chapter, I go through a number of useful ECMA5 functions for situations such as:
  <ul>
    <li>Searching the content of an Array</li>
    <li>Checking whether the contents of an Array satisfy a criteria</li>
    <li>Iterating through the properties (keys) of an object</li>
    <li>Accepting variable number of arguments in functions</li>
  </ul>
</div>

This chapter focuses on Arrays, Objects and Functions. There are a number of useful ECMAScript 5 features which are supported by V8, such as Array.forEach(), Array.indexOf(), Object.keys() and String.trim().

If you haven't heard of those functions, it's because they are part of ECMAScript 5, which is [not supported by Internet Explorer versions](http://kangax.github.com/es5-compat-table/) prior to IE9.

Typically when writing Javascript for execution on the client side you have to force yourself to the lowest common denominator. The ECMAScript 5 additions make writing server side code nicer. Even IE is finally adding support for ECMA 5 - in IE9.

### Arrays vs. Objects

You have the choice between using arrays or objects for storing your data in Javascript. Arrays can also be used as stacks:

<pre class="run prettyprint">
var arr = [ 'a', 'b', 'c'];
arr.push('d'); // insert as last item
console.log(arr); // ['a', 'b', 'c', 'd']
console.log(arr.pop()); // remove last item
console.log(arr); // ['a', 'b', 'c']
</pre>

Unshift() and shift() work on the front of the array:

<pre class="run prettyprint">
var arr = [ 'a', 'b', 'c'];
arr.unshift('1'); // insert as first item
console.log(arr); // ['1','a', 'b', 'c']
console.log(arr.shift()); // remove first item
console.log(arr); // ['a', 'b', 'c']
</pre>

Arrays are ordered - the order in which you add items (e.g. push/pop or shift/unshift) matters. Hence, you should use arrays for storing items which are ordered.

 Objects are good for storing named values, but V8 does not allow you to specify an order for the properties (so adding properties in a particular order to an object does not guarantee that the properties will be iterated in that order). Objects can also be useful for values which need to be looked up quickly, since you can simply check for whether a property is defined without needing to iterate through the properties:

 <pre class="run prettyprint">
 var obj = { has_thing: true, id: 123 };
 if(obj.has_thing) {
  console.log('true', obj.id);
 }
 </pre>

### Working with Arrays

Arrays are very versatile for storing data, and can be searched, tested, and have functions applied to them in V8 using the following ECMAScript 5 functions:

#### Searching the content of an Array

<table>
<tr><td>Array.isArray(array)</td><td>Returns true if a variable is an array, false if it is not.</td></tr>

<tr><td>indexOf(searchElement[, fromIndex])</td><td>Returns the first (least) index of an element within the array equal to the specified value, or -1 if none is found. The search can optionally begin at fromIndex.</td></tr>

<tr><td>lastIndexOf(searchElement[, fromIndex])</td><td>Returns the last (greatest) index of an element within the array equal to the specified value, or -1 if none is found.The array is searched backwards, starting at fromIndex.</td></tr>
</table>

The `indexOf()` and `lastIndexOf()` functions are very useful for searching an array for a particular value, if necessary. For example, to check whether a particular value is present in an array:

<pre class="run prettyprint">
function process(argv) {
  if(argv.indexOf('help')) {
    console.log('This is the help text.');
  }
}
process(['foo', 'bar', 'help']);
</pre>

However, be aware that indexOf() uses the strict comparison operator (===), so the following will not work:

<pre class="run prettyprint">
var arr = ["1", "2", "3"];
// Search the array of keys
console.log(arr.indexOf(2)); // returns -1
</pre>

This is because we defined an array of Strings, not Integers. The strict equality operator used by indexOf takes into account the type, like this:

<pre class="run prettyprint">
console.log(2 == "2"); // true
console.log(2 === "2"); // false
var arr = ["1", "2", "3"];
// Search the array of keys
console.log(arr.indexOf(2)); // returns -1
console.log(arr.indexOf("2")); // returns 1
</pre>

Notably, you might run into this problem when you use indexOf() on the return value of Object.keys().

<pre class="run prettyprint">
var lookup = { 12: { foo: 'b'}, 13: { foo: 'a' }, 14: { foo: 'c' }};
console.log(Object.keys(lookup).indexOf(12) > -1); // false
console.log(Object.keys(lookup).indexOf(''+12) > -1); // true
</pre>

#### Applying function to every item in an Array

<table>
<tr><td>filter(callback[, thisObject])</td><td>Creates a new array with all of the elements of this array for which the provided filtering function returns true. If a thisObject parameter is provided to filter, it will be used as the this for each invocation of the callback. IE9</td></tr>
<tr><td>forEach(callback[, thisObject])</td><td>Calls a function for each element in the array.</td></tr>
<tr><td>map(callback[, thisObject])</td><td>Creates a new array with the results of calling a provided function on every element in this array.</td></tr>
</table>

`filter()`, `map()` and `forEach()` all call a callback with every value of the array. This can be useful for performing various operations on the array. Again, the callback is invoked with three arguments: the value of the element, the index of the element, and the Array object being traversed. For example, you might apply a callback to all items in the array:

<pre class="run prettyprint">
var names = ['a', 'b', 'c'];
names.forEach(function(value) {
  console.log(value);
});
// prints a b c
</pre>

or you might filter based on a criterion:

<pre class="run prettyprint">
var items = [ { id: 1 }, { id: 2}, { id: 3}, { id: 4 }];
// only include items with even id's
items = items.filter(function(item){
  return (item.id % 2 == 0);
});
console.log(items);
// prints [ {id: 2 }, { id: 4} ]
</pre>

If you want to accumulate a particular value - like the sum of elements in an array - you can use the reduce() functions:

<table>
<tr><td>reduce(callback[, initialValue])</td><td>Apply a function simultaneously against two values of the array (from left-to-right) as to reduce it to a single value.  IE9</td></tr>
<tr><td>reduceRight(callback[, initialValue])</td><td>Apply a function simultaneously against two values of the array (from right-to-left) as to reduce it to a single value. IE9</td></tr>
</table>

`reduce()` and `reduceRight()` apply a function against an accumulator and each value of the array. The callback receives four arguments: the initial value (or value from the previous callback call), the value of the current element, the current index, and the array over which iteration is occurring (e.g. arr.reduce(function(previousValue, currentValue, index, array){ ... }).

#### Checking whether the contents of an Array satisfy a criteria

<table>
<tr><td>every(callback[, thisObject])</td><td>Returns true if every element in this array satisfies the provided testing function.</td></tr>
<tr><td>some(callback[, thisObject])</td><td>Returns true if at least one element in this array satisfies the provided testing function.</td></tr>
</table>

`some()` and `every()` allow for a condition to be specified which is then tested against all the values in the array. The callback is invoked with three arguments: the value of the element, the index of the element, and the Array object being traversed. For example, to check whether a particular string contains at least one of the tokens in an array, use `some()`:

<pre class="run prettyprint">
var types = ['text/html', 'text/css', 'text/javascript'];
var string = 'text/javascript; encoding=utf-8';
if (types.some(function(value) {
    return string.indexOf(value) &gt; -1;
  })) {
  console.log('The string contains one of the content types.');
}
</pre>

### ECMA 3 Array functions

I'd just like to remind you that these exist:

<table>
<tr><td>sort([compareFunction])</td><td>Sorts the elements of an array.</td></tr>
<tr><td>concat(value1, value2, ..., valueN)</td><td>Returns a new array comprised of this array joined with other array(s) and/or value(s).</td></tr>
<tr><td>join(separator)</td><td>Joins all elements of an array into a string.</td></tr>
<tr><td>slice(begin[, end]</td><td>Extracts a section of an array and returns a new array.</td></tr>
<tr><td>splice(index [,howMany][,element1[, ...[, elementN]]]</td><td>Adds and/or removes elements from an array.</td></tr>
<tr><td>reverse</td><td>Reverses the order of the elements of an array -- the first becomes the last, and the last becomes the first.</td></tr>
</table>

These functions are part of ECMAScript 3, so they are available on all modern browsers.

<pre class="run prettyprint">
var a = [ 'a', 'b', 'c' ];
var b = [ 1, 2, 3 ];
console.log( a.concat(['d', 'e', 'f'], b) );
console.log( a.join('! ') );
console.log( a.slice(1, 3) );
console.log( a.reverse() );
console.log( ' --- ');
var c = a.splice(0, 2);
console.log( a, c );
var d = b.splice(1, 1, 'foo', 'bar');
console.log( b, d );
</pre>

### Working with Objects

Objects are useful when you need to have named properties (like a hash), and you don't care about the order of the properties. The most common basic operations include iterating the properties and values of an Object, and working with arrays of Objects.

<table>
<tr>
<td>`Object.keys(obj)`</td>
<td>Returns a list of the ownProperties of an object that are enumerable.</td>
</tr><tr>
<td>`hasOwnProperty(prop)`</td>
<td>Returns a boolean indicating whether the object has the specified property. This method can be used to determine whether an object has the specified property as a direct property of that object; unlike the in operator, this method does not check down the object's prototype chain.
</td>
</tr>
<tr><td>`prop in objectName`</td><td>The in operator returns true if the specified property is in the specified object. It is useful for checking for properties which have been set to undefined, as it will return true for those as well.</td>
</tr>
</table>

You can use this to count the number of properties in an object which you are using as a hash table:

<pre class="run prettyprint">
// returns array of keys
var keys = Object.keys({ a: 'foo', b: 'bar'});
// keys.length is 2
console.log(keys, keys.length);
</pre>

#### Iterating through the properties (keys) of an object

An easy way to iterate through the keys is to use Object.keys() and then apply Array.forEach() on the array:

<pre class="run prettyprint">
var group = { 'Alice': { a: 'b', b: 'c' }, 'Bob': { a: 'd' }};
var people = Object.keys(group);
people.forEach(function(person) {
  var items = Object.keys(group[person]);
  items.forEach(function(item) {
    var value = group[person][item];
    console.log(person+': '+item+' = '+value);
  });
});
</pre>

#### Iterating objects in alphabetical order

Remember that object properties are not necessarily retrieved in order, so if you want the keys to be in alphabetical order, use sort():

<pre class="run prettyprint">
var obj = { x: '1', a: '2', b: '3'};
var items = Object.keys(obj);
items.sort(); // sort the array of keys
items.forEach(function(item) {
  console.log(item + '=' + obj[item]);
});
</pre>

#### Sorting arrays of objects by property

The default sort function compares the items in the array as strings, but you can pass a custom function to sort() if you want to sort an array of objects by a property of the objects:

<pre class="run prettyprint">
var arr = [
  { item: 'Xylophone' },
  { item: 'Carrot' },
  { item: 'Apple'}
  ];
arr = arr.sort(function (a, b) {
  return a.item.localeCompare(b.item);
});
console.log( arr );
</pre>

The code above uses the comparator parameter of sort() to specify a custom sort, and then uses String.localCompare to return the correct sort order information.

#### Checking whether a property is present, even if it is false

There are multiple ways of checking whether a property is defined:

<pre class="run prettyprint">
var obj = { a: "value", b: false };
// nonexistent properties
console.log( !!obj.nonexistent );
console.log( 'nonexistent' in obj );
console.log( obj.hasOwnProperty('nonexistent') );

// existing properties
console.log( !!obj.a );
console.log( 'a' in obj );
console.log( obj.hasOwnProperty('a') );
</pre>

The expression !!obj.propertyname takes the value of the property (or undefined) and converts it to a Boolean by negating it twice (!true == false, !!true == true).

The in keyword searches for the property in the object, and will return true even if the value of the property is zero, false or an empty string.

<pre class="run prettyprint">
var obj = { a: "value", b: false };
// different results when the value evaluates to false
console.log( !!obj.b );
console.log( 'b' in obj );
console.log( obj.hasOwnProperty('b') );
</pre>

The hasOwnProperty() method does not check down the object's prototype chain, which may be desirable in some cases:

<pre class="run prettyprint">
var obj = { a: "value", b: false };
// different results when the property is from an object higher up in the prototype chain
console.log( !!obj.toString );
console.log( 'toString' in obj );
console.log( obj.hasOwnProperty('toString') );
</pre>

(Note: All objects have a toString method, derived from Object).

#### Filtering an array of objects

<pre class="run prettyprint">
function match(item, filter) {
  var keys = Object.keys(filter);
  // true if any true
  return keys.some(function (key) {
    return item[key] == filter[key];
  });
}
var objects = [ { a: 'a', b: 'b', c: 'c'},
  { b: '2', c: '1'},
  { d: '3', e: '4'},
  { e: 'f', c: 'c'} ];

objects.forEach(function(obj) {
  console.log('Result: ', match(obj, { c: 'c', d: '3'}));
});
</pre>

Substituting some() with every() above would change the definition of match() so that all key-value pairs in the filter object must match.

### Working with Functions

Defining new functions:

<pre class="run prettyprint">
function doSomething() { return 'doSomething'; }
var doSomethingElse = function() { return 'doSomethingElse'; };
console.log( doSomething() );
console.log( doSomethingElse() );
</pre>

Order of function definition within a scope does not matter, but when defining a function as a variable the order does matter.

<pre class="run prettyprint">
console.log( doSomething() );
console.log( doSomethingElse() );
// define the functions after calling them!
var doSomethingElse = function() { return 'doSomethingElse'; };
function doSomething() { return 'doSomething'; }
</pre>

Functions are objects, so they can have properties attached to them.

<pre class="run prettyprint">
function doSomething() { return doSomething.value + 50; }
var doSomethingElse = function() { return doSomethingElse.value + 100; };
doSomething.value = 100;
doSomethingElse.value = 100;
console.log( doSomething() );
console.log( doSomethingElse() );
</pre>

#### Call and apply

The value of the this keyword is determined by how the function was called. For the details, see the section on this scope and call() and apply() in the previous chapter.

<table>
<tr><td>Function.call</td><td>Calls a function with a given this value and arguments provided individually.</td></tr>
<tr><td>Function.apply</td><td>Applies the method of another object in the context of a different object (the calling object); arguments can be passed as an Array object.</td></tr>
</table>

As you can see, both call() and apply() allow us to specify what the value of this should be.

The difference between the two is how they pass on addional arguments:

<pre class="run prettyprint">
function f1(a, b) {
  console.log(this, a, b);
}
var obj1 = { id: "Foo"};
f1.call(obj1, 'A', 'B'); // The value of this is changed to obj1
var obj2 = { id: "Bar"};
f1.apply(obj2, [ 'A', 'B' ]); // The value of this is changed to obj2
</pre>

The syntax of call() is identical to that of apply(). The difference is that call() uses the actual arguments passed to it (after the first argument), while apply() takes just two arguments: thisArg and an array of arguments.

#### Variable number of arguments

Functions have a arguments property:

<table>
<tr><td>Property: arguments</td><td>The arguments property contains all the parameters passed to the function</td></tr>
</table>

which contains all the arguments passed to the function:

<pre class="run prettyprint">
var doSomethingElse = function(a, b) {
  console.log(a, b);
  console.log(arguments);
};
doSomethingElse(1, 2, 3, 'foo');
</pre>

Using apply() and arguments:

<pre class="run prettyprint">
function smallest(){
  return Math.min.apply( Math, arguments);
}
console.log( smallest(999, 899, 99999) );
</pre>

The arguments variable available in functions is not an Array, through it acts mostly like an array. For example, it does not have the push() and pop() methods but it does have a length property:

<pre class="run prettyprint">
function test() {
  console.log(arguments.length);
  console.log(arguments.concat(['a', 'b', 'c'])); // causes an error
}
test(1, 2, 3);
</pre>

To create an array from the arguments property, you can use Array.prototype combined with Function.call:

<pre class="run prettyprint">
function test() {
  // Create a new array from the contents of arguments
  var args = Array.prototype.slice.call(arguments); // returns an array
  console.log(args.length);
  console.log(args.concat(['a', 'b', 'c'])); // works
}
test(1, 2, 3);
</pre>

### Working with JSON data

The JSON functions are particularly useful for working with data structures in Javascript. They can be used to transform objects and arrays to strings.

<table>
<tr><td>JSON.parse(text[, reviver]);</td><td>Parse a string as JSON, optionally transform the produced value and its properties, and return the value.</td></tr>
<tr><td>JSON.stringify(value[, replacer [, space]]);</td><td>Return a JSON string corresponding to the specified value, optionally including only certain properties or replacing property values in a user-defined manner.</td></tr>
</table>

JSON.parse() can be used to convert JSON data to a Javascript Object or Array:

<pre class="run prettyprint">
// returns an Object with two properties
var obj = JSON.parse('{"hello": "world", "data": [ 1, 2, 3 ] }');
console.log(obj.data);
</pre>

JSON.stringify() does the opposite:

<pre class="run prettyprint">
var obj = { hello: 'world', data: [ 1, 2, 3 ] };
console.log(JSON.stringify(obj));
</pre>

The optional space parameter in JSON.stringify is particularly useful in producing readable output from complex object.

The reviver and replacer parameters are rarely used. They expect a function which takes the key and value of each value as an argument. That function is applied to the JSON input before returning it.
