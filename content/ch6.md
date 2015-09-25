home: index.html
prev: ch5.html
next: ch7.html
---
# 6. Objects and classes by example

<div class="summary">
In this chapter, I:

<ul>
  <li>cover OOP in Javascript by example</li>
  <li>point out a few caveats and recommended solutions</li>
</ul>
</div>

I'm not covering the theory behind this, but I recommend that you start by learning more about the prototype chain, because understanding the prototype chain is essential to working effectively with JS.

The concise explanation is:

<ul>
  <li>Javascript is an object-oriented programming language that supports <i>delegating inheritance</i> based on <i>prototypes</i>.</li>
  <li>Each object has a prototype property, which refers to another (regular) object.</li>
  <li>Properties of an object are looked up from two places:
    <ol>
      <li>the object itself (Obj.foo), and
      </li><li>if the property does not exist, on the prototype of the object (Obj.prototype.foo).</li>
    </ol>
    </li>
  <li>Since this lookup is performed recursively (e.g. Obj.foo, Obj.prototype.foo, Obj.prototype.prototype.foo), each object can be said to have a prototype chain.</li>
  <li>Assigning to an undefined property of an object will create that property on the object. Properties of the object itself take precedence over properties of prototypes.</li>
  <li>New objects are created using a constructor, which is a regular function invoked using <code>new</code></li>
  <li>The <code>new</code> constructor call (e.g. <code>new Foo()</code>):
    <ol>
      <li>creates a new object,</li>
      <li>sets the prototype of that object to Foo.prototype and </li>
      <li>passes that as <code>this</code> to the constructor.</li>
    </ol>
  </li>
  <li>The delegating inheritance implemented in Javascript is different from "classical" inheritance: it is based on run time lookups from the prototype property rather than statically defined class constructs. The prototype chain lookup mechanism is the essence of prototypal inheritance.</li>
</ul>

There are further nuances to the system. Here are my recommendations on what to read:

*   [ECMA-262-3 in detail. Chapter 7.1. OOP: The general theory](http://dmitrysoshnikov.com/ecmascript/chapter-7-1-oop-general-theory/) from Dmitry Soshnikov
*   [ECMA-262-3 in detail. Chapter 7.2. OOP: ECMAScript implementation](http://dmitrysoshnikov.com/ecmascript/chapter-7.2-oop-ecmascript-implementation/) from Dmitry Soshnikov
*   [Details of the Object Model](https://developer.mozilla.org/en/JavaScript/Guide/Details_of_the_Object_Model) from Mozilla

Let's look at some applied patterns next:

### Class pattern

```js
// Constructor
function Foo(bar) {
  // always initialize all instance properties
  this.bar = bar;
  this.baz = 'baz'; // default value
}
// class methods
Foo.prototype.fooBar = function() {

};
// export the class
module.exports = Foo;
```

Instantiating a class is simple:

```js
// constructor call
var object = new Foo('Hello');
```

Note that I recommend using `function Foo() { ... }` for constructors instead of `var Foo = function() { ... }`.

The main benefit is that you get better stack traces from Node when you use a named function. Generating a stack trace from an object with an unnamed constructor function:

```js
var Foo = function() { };
Foo.prototype.bar = function() { console.trace(); };

var f = new Foo();
f.bar();
```

... produces something like this:

```
Trace:
    at [object Object].bar (/home/m/mnt/book/code/06_oop/constructors.js:3:11)
    at Object.<anonymous> (/home/m/mnt/book/code/06_oop/constructors.js:7:3)
    at Module._compile (module.js:432:26)
    at Object..js (module.js:450:10)
    at Module.load (module.js:351:31)
    at Function._load (module.js:310:12)
    at Array.0 (module.js:470:10)
    at EventEmitter._tickCallback (node.js:192:40)
```

... while using a named function</li>

```js
function Baz() { };
Baz.prototype.bar = function() { console.trace(); };

var b = new Baz();
b.bar();
```

... produces a stack trace with the name of the class:

```
Trace:
    at Baz.bar (/home/m/mnt/book/code/06_oop/constructors.js:11:11)
    at Object.<anonymous> (/home/m/mnt/book/code/06_oop/constructors.js:15:3)
    at Module._compile (module.js:432:26)
    at Object..js (module.js:450:10)
    at Module.load (module.js:351:31)
    at Function._load (module.js:310:12)
    at Array.0 (module.js:470:10)
    at EventEmitter._tickCallback (node.js:192:40)
```

To add private shared (among all instances of the class) variables, add them to the top level of the module:

```js
// Private variable
var total = 0;

// Constructor
function Foo() {
  // access private shared variable
  total++;
};
// Expose a getter (could also expose a setter to make it a public variable)
Foo.prototype.getTotalObjects = function(){
  return total;
};
```

### Avoid assigning variables to prototypes

If you want to define a default value for a property of an instance, define it in the constructor function.

Prototypes should not have properties that are not functions, because prototype properties that are not primitives (such as arrays and objects) will not behave as one would expect, since they will use the instance that is looked up from the prototype. Example for Dimitry Sosnikov's site:

<pre class="prettyprint run">
var Foo = function (name) { this.name = name; };
Foo.prototype.data = [1, 2, 3]; // setting a non-primitive property
Foo.prototype.showData = function () { console.log(this.name, this.data); };

var foo1 = new Foo("foo1");
var foo2 = new Foo("foo2");

// both instances use the same default value of data
foo1.showData(); // "foo1", [1, 2, 3]
foo2.showData(); // "foo2", [1, 2, 3]

// however, if we change the data from one instance
foo1.data.push(4);

// it mirrors on the second instance
foo1.showData(); // "foo1", [1, 2, 3, 4]
foo2.showData(); // "foo2", [1, 2, 3, 4]
</pre>

Hence prototypes should only define methods, not data.

If you set the variable in the constructor, then you will get the behavior you expect:

<pre class="prettyprint run">
function Foo(name) {
  this.name = name;
  this.data = [1, 2, 3]; // setting a non-primitive property
};
Foo.prototype.showData = function () { console.log(this.name, this.data); };
var foo1 = new Foo("foo1");
var foo2 = new Foo("foo2");
foo1.data.push(4);
foo1.showData(); // "foo1", [1, 2, 3, 4]
foo2.showData(); // "foo2", [1, 2, 3]
</pre>

### Don't construct by returning objects - use prototype and new

For example, construction pattern which returns an object is terrible ([even though](http://bolinfest.com/javascript/inheritance.php) it was introduced in "JavaScript: The Good Parts"):

```js
function Phone(phoneNumber) {
  var that = {};
  // You are constructing a custom object on every call!
  that.getPhoneNumber = function() {
    return phoneNumber;
  };
  return that;
};
// or
function Phone() {
  // You are constructing a custom object on every call!
  return {
    getPhoneNumber: function() { ... }
  };
};
```

Here, every time we run Phone(), a new object is created with a new property.
The V8 runtime cannot optimize this case, since there is no indication that instances of Phone are a class; they look like custom objects to the engine since prototypes are not used. This leads to slower performance.

It's also broken in another way: you cannot change the prototype properties of all instances of Phone, since they do not have a common ancestor/prototype object. Prototypes exists for a reason, so use the class pattern described earlier.

### Avoid implementing classical inheritance

I think classical inheritance is in most cases an antipattern in Javascript. Why?

There are two reasons to have inheritance:

1.  to support polymorphism in languages that do not have dynamic typing, like C++. The class acts as an interface specification for a type. This provides the benefit of being able to replace one class with another (such as a function that operates on a Shape that can accept subclasses like Circle). However, Javascript doesn't require you to do this: the only thing that matters is that a method or property can be looked up when called/accessed.
2.  to reuse code. Here the theory is that you can reuse code by having a hierarchy of items that go from an abstract implementation to a more specific one, and you can thus define multiple subclasses in terms of a parent class. This is sometimes useful, but not that often.

The disadvantages of inheritance are:

1.  Nonstandard, hidden implementations of classical inheritance. Javascript doesn't have a builtin way to define class inheritance, so people invent their own ones. These implementations are similar to each other, but differ in subtle ways.
2.  Deep inheritance trees. Subclasses are aware of the implementation details of their superclasses, which means that you need to understand both. What you see in the code is not what you get: instead, parts of an implementation are defined in the subclass and the rest are defined piecemeal in the inheritance tree. The implementation is thus sprinkled over multiple files, and you have to mentally recombine those to understand the actual behavior.

I favor [composition over inheritance](http://en.wikipedia.org/wiki/Composite_reuse_principle):

*   Composition - Functionality of an object is made up of an aggregate of different classes by containing instances of other objects.
*   Inheritance - Functionality of an object is made up of it's own functionality plus functionality from its parent classes.

### If you must have inheritance, use plain old JS

If you must implement inheritance, at least avoid using yet another nonstandard implementation / magic function. Here is how you can implement a reasonable facsimile of inheritance in pure ES3 (as long as you follow the rule of never defining properties on prototypes):

<pre class="prettyprint run">
function Animal(name) {
  this.name = name;
};
Animal.prototype.move = function(meters) {
  console.log(this.name+" moved "+meters+"m.");
};

function Snake() {
  Animal.apply(this, Array.prototype.slice.call(arguments));
};
Snake.prototype = new Animal();
Snake.prototype.move = function() {
  console.log("Slithering...");
  Animal.prototype.move.call(this, 5);
};

var sam = new Snake("Sammy the Python");
sam.move();
</pre>

This is not the same thing as classical inheritance - but it is standard, understandable Javascript and has the functionality that people mostly seek: chainable constructors and the ability to call methods of the superclass.

Or use [util.inherits()](http://nodejs.org/api/util.html#util.inherits) (from the Node.js core). Here is the full implementation:

```js
var inherits = function (ctor, superCtor) {
    ctor.super_ = superCtor;
    ctor.prototype = Object.create(superCtor.prototype, {
        constructor: {
            value: ctor,
            enumerable: false
        }
    });
};
```

And a usage example:

```js
var util = require('util');
function Foo() { }
util.inherits(Foo, EventEmitter);
```

The only real benefit to util.inherits is that you don't need to use the actual ancestor name in the Child constructor.

Note that if you define variables as properties of a prototype, you will experience unexpected behavior (e.g. since variables defined on the prototype of the superclass will be accessible in subclasses but will also be shared among all instances of the subclass).

As I pointed out with the class pattern, always define all instance variables in the constructor. This forces the properties to exist on the object itself and avoids lookups on the prototype chain for these variables.

Otherwise, you might accidentally define/access a variable property defined in a prototype. Since the prototype is shared among all instances, this will lead to the unexpected behavior if the variable is not a primitive (e.g. is an Object or an Array). See the earlier example under "Avoid setting variables as properties of prototypes".

### Use mixins

A mixin is a function that adds new functions to the prototype of an object. I prefer to expose an explicit mixin() function to indicate that the class is designed to be mixed into another one:

```js
function Foo() { }
Foo.prototype.bar = function() { };
Foo.prototype.baz = function() { };

// mixin - augment the target object with the Foo functions
Foo.mixin = function(destObject){
  ['bar', 'baz'].forEach(function(property) {
    destObject.prototype[property] = Foo.prototype[property];
  });
};

module.exports = Foo;
```

Extending the Bar prototype with Foo:

```js
var Foo = require('./foo.js');
function Bar() {}
Bar.prototype.qwerty = function() {};

// mixin Foo
Foo.mixin(Bar);
```

### Avoid currying

Currying is a shorthand notation for creating an anonymous function with a new scope that calls another function. In other words, anything you can do using currying can be done using a simple anonymous function and a few variables local to that function.

```js
Function.prototype.curry = function() {
  var fn = this;
  var args = Array.prototype.slice.call(arguments);
  return function() {
    return fn.apply(this, args.concat(Array.prototype.slice.call(arguments, 0)));
  };
}
```

Currying is intriguing, but I haven't seen a practical use case for it outside of subverting how the `this` argument works in Javascript.

Don't use currying to change the context of a call/the`this` argument. Use the "self" variable accessed through an anonymous function, since it achieves the same thing but is more obvious.

Instead of using currying:

```js
function foo(a, b, c) { console.log(a, b, c); }

var bar = foo.curry('Hello');
bar('World', '!');
```

I think that writing:

```js
function foo(a, b, c) { console.log(a, b, c); }

function bar(b, c) { foo('Hello', b, c); }
bar('World', '!');
```

is more clear.
