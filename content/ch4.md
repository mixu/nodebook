home: index.html
prev: ch3.html
next: ch5.html
---
# 4. V8 and Javascript gotchas

<div class="summary">
  In this chapter, I:
  <ul>
    <li>explain why you need a `self` variable sometimes along with the rules surrounding the `this` keyword</li>
    <li>explain why you might get strange results from `for` loops along with the basics of the variable scope in Javascript</li>
    <li>show a couple of other minor gotchas that I found confusing</li>
  </ul>
</div>

There are basically two things that trip people up in Javascript:

1.  The rules surrounding the "this" keyword and
2.  Variable scope rules

In this chapter, I'll examine these JS gotchas and a couple of V8-related surprises. If you're feeling pretty confident, then feel free to skim or skip this chapter.

### 4.1 Gotcha #1: this keyword

In object-oriented programming languages, the `this` keyword is used to refer to the current instance of the object. For example, in Java, the value of `this` always refers to the current instance:

```java
public class Counter {
  private int count = 0;
  public void increment(int value) {
    this.count += value;
  }
}
```

In Javascript - which is a prototype-based language - the `this` keyword is not fixed to a particular value. Instead, the value of `this` is determined by _how the function is called_ <span class="ref">[[1](http://javascriptweblog.wordpress.com/2010/08/30/understanding-javascripts-this)]</span>:

<table>
<tbody>
<tr>
<td>Execution Context</td>
<td>Syntax of function call</td>
<td>Value of this</td>
</tr>
<tr>
<td>Global</td>
<td>n/a</td>
<td>global object (e.g. `window`)</td>
</tr>
<tr>
<td>Function</td>
<td>Method call:
`myObject.foo();`</td>
<td>`myObject`</td>
</tr>
<tr>
<td>Function</td>
<td>Baseless function call:
`foo();`</td>
<td>global object (e.g. `window`)
(`undefined` in strict mode)</td>
</tr>
<tr>
<td>Function</td>
<td>Using call:
`foo.call(context, myArg);`</td>
<td>`context`</td>
</tr>
<tr>
<td>Function</td>
<td>Using apply:
`foo.apply(context, [myArgs]);`</td>
<td>`context`</td>
</tr>
<tr>
<td>Function</td>
<td>Constructor with new:
`var newFoo = new Foo();`</td>
<td>the new instance
(e.g. `newFoo`)

</td></tr>
<tr>
<td>Evaluation</td>
<td>n/a</td>
<td>value of `this` in parent context</td>
</tr>
</tbody></table>

#### Calling the method of an object

<p>This is the most basic example: we have defined an object, and call object.f1():

<pre class="run prettyprint">
var obj = {
  id: "An object",
  f1: function() {
    console.log(this);
  }
};
obj.f1();
</pre>

As you can see, `this` refers to the current object, as you might expect.

#### Calling a standalone function

Since every function has a "`this`" value, you can access `this` even in functions that are not properties of an object:

<pre class="run prettyprint">
function f1() {
  console.log(this.toString());
  console.log(this == window);
}
f1();
</pre>

In this case, `this` refers to the global object, which is "DomWindow" in the browser and "global" in Node.

#### Manipulating this via Function.apply and Function.call

There are a number of built-in methods that all Functions have (see [the Mozilla Developer Docs for details](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function#Methods_2)). Two of those built-in properties of functions allow us to change the value of "`this`" when calling a function:

1.  [Function.apply](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function/apply)(thisArg[, argsArray]): Calls the function, setting the value of `this` to thisArg and the arguments of the function the values of argsArray.
2.  [Function.call](https://developer.mozilla.org/en/JavaScript/Reference/Global_Objects/Function/call)(thisArg[, arg1[, arg2[, ...]]]): Calls the function, setting the value of `this` to thisArg, and passing the arguments arg1, arg2 ... to the function.

Let's see some examples:

<pre class="run prettyprint">
function f1() {
  console.log(this);
}
var obj1 = { id: "Foo"};
f1.call(obj1);
var obj2 = { id: "Bar"};
f1.apply(obj2);
</pre>

As you can see, both call() and apply() allow us to specify what the value of `this` should be.

The difference between the two is how they pass on addional arguments:

<pre class="run prettyprint">
function f1(a, b) {
  console.log(this, a, b);
}
var obj1 = { id: "Foo"};
f1.call(obj1, 'A', 'B');
var obj2 = { id: "Bar"};
f1.apply(obj2, [ 'A', 'B' ]);
</pre>

Call() takes the actual arguments of call(), while apply() takes just two arguments: thisArg and an array of arguments.

Still with me? OK - now let's talk about the problems.

#### Context changes

As I noted earlier, the value of `this` is not fixed - it is determined by _how the function is called_. In other words, the value of `this` is determined at the time the function is called, rather than being fixed to some particular value.

This causes problems (pun intended) when we want to defer calling a function. For example, the following won't work:

<pre class="run prettyprint">
var obj = {
  id: "xyz",
  printId: function() {
    console.log('The id is '+ this.id + ' '+ this.toString());
  }
};
setTimeout(obj.printId, 100);
</pre>

Why doesn't this work? Well, for the same reason this does not work:

<pre class="run prettyprint">
var obj = {
  id: "xyz",
  printId: function() {
    console.log('The id is '+ this.id + ' '+ this.toString());
  }
};
var callback = obj.printId;
callback();
</pre>

Since the value of `this` is determined at call time - and we are not calling the function using the "object.method" notation, "`this`" refers to the global object -- which is not what we want.

In "setTimeout(obj.printId, 100);", we are passing the value of obj.printId, which is a function. When that function later gets called, it is called as a standalone function - not as a method of an object.

To get around this, we can create a function which maintains a reference to obj, which makes sure that `this` is bound correctly:

<pre class="run prettyprint">
var obj = {
  id: "xyz",
  printId: function() {
    console.log('The id is '+ this.id + ' '+ this.toString());
  }
};
setTimeout(function() { obj.printId() }, 100);
var callback = function() { obj.printId() };
callback();
</pre>

A pattern that you will see used frequently is to store the value of `this` at the beginning of a function to a variable called `self`, and then using `self` in callback in place of `this`:

<pre class="run prettyprint">
var obj = {
  items: ["a", "b", "c"],
  process: function() {
    var self = this; // assign this to self
    this.items.forEach(function(item) {
      // here, use the original value of this!
      self.print(item);
    });
  },
  print: function(item) {
    console.log('*' + item + '*');
  }
};
obj.process();
</pre>

Because `self` is an ordinary variable, it will contain the value of `this` when the first function was called - no matter how or when the callback function passed to forEach() gets called. If we had used "`this`" instead of "self" in the callback function, it would have referred to the wrong object and the call to print() would have failed.

### 4.2 Gotcha #2: variable scope and variable evaluation strategy

C and C-like languages have rather simple variable scope rules. Whenever you see a new block, like { ... }, you know that all the variables defined within that block are local to that block.

Javascript's scope rules differ from those of most other languages. Because of this, assigning to variables can have tricky side effects in Javascript. Look at the following snippets of code, and determine what they print out.

Don't click "run" until you've decided on what the output should be!

#### Example #1: A simple for loop

<pre class="run prettyprint">
for(var i = 0; i &lt; 5; i++) {
  console.log(i);
}
</pre>

#### Example #2: a setTimeout call inside a for loop

<pre class="run prettyprint">
for(var i = 0; i &lt; 5; i++) {
 setTimeout(function() {
  console.log(i);
 }, 100);
}
</pre>

#### Example #3: Delayed calls a function

<pre class="run prettyprint">
var data = [];
for (var i = 0; i &lt; 5; i++) {
 data[i] = function foo() {
   console.log(i);
 };
}
data[0](); data[1](); data[2](); data[3](); data[4]();
</pre>

Example #1 should be pretty simple. It prints out “0, 1, 2, 3, 4”. However, example #2 prints out “5, 5, 5, 5, 5”. Why is this?

Looking at examples #1 to #3, you can see a pattern emerge: delayed calls, whether they are via setTimeout() or a simple array of functions all print the unexpected result “5″.

### Variable scope rules in Javascript

Fundamentally, the only thing that matters is at what time the function code is executed. setTimeout() ensures that the function is only executed at some later stage. Similarly, assigning functions into an array explicitly like in example #3 means that the code within the function is only executed after the loop has been completed.

There are three things you need to remember about variable scope in Javascript:

1.  Variable scope is based on the nesting of functions. In other words, the position of the function in the source always determines what variables can be accessed:

        1.  nested functions can access their parent’s variables:

        <pre class="run prettyprint">
var a = "foo";
function parent() {
  var b = "bar";
  function nested() {
    console.log(a);
    console.log(b);
  }
  nested();
}
parent();
</pre>
    2.  non-nested functions can only access the topmost, global variables:

        <pre class="run prettyprint">
var a = "foo";
function parent() {
  var b = "bar";
}
function nested() {
  console.log(a);
  console.log(b);
}
parent();
nested();
</pre>

2.  Defining functions creates new scopes:

        1.  and the default behavior is to access previous scope:

        <pre class="run prettyprint">
var a = "foo";
function grandparent() {
  var b = "bar";
  function parent() {
    function nested() {
      console.log(a);
      console.log(b);
    }
    nested();
  }
  parent();
}
grandparent();
</pre>

        2.  but inner function scopes can prevent access to a previous scope by defining a variable with the same name:

        <pre class="run prettyprint">
var a = "foo";
function grandparent() {
  var b = "bar";
  function parent() {
    var b = "b redefined!";
    function nested() {
      console.log(a);
      console.log(b);
    }
    nested();
  }
  parent();
}
grandparent();
</pre>
3.  Some functions are executed later, rather than immediately. You can emulate this yourself by storing but not executing functions, see example #3.

What we would expect, based on experience in other languages, is that in the for loop, calling a the function would result in a [call-by-value](http://en.wikipedia.org/wiki/Evaluation_strategy#Call_by_reference) (since we are referencing a primitive – an integer) and that function calls would run using a copy of that value at the time when the part of the code was “passed over” (e.g. when the surrounding code was executed). That’s not what happens, because we are using a closure/nested anonymous function:

A variable referenced in a nested function/closure is not a copy of the value of the variable — it is a live reference to the variable itself and can access it at a much later stage. So while the reference to i is valid in both examples 2 and 3 they refer to the value of i at the time of their execution – which is on the next event loop – which is after the loop has run – which is why they get the value 5.

Functions can create new scopes but they do not have to. The default behavior allows us to refer back to the previous scope (all the way up to the global scope); this is why code executing at a later stage can still access i. Because no variable i exists in the current scope, the i from the parent scope is used; because the parent has already executed, the value of i is 5.

Hence, we can fix the problem by explicitly establishing a new scope every time the loop is executed; then referring back to that new inner scope later.  The only way to do this is to use an (anonymous) function plus explicitly defining a variable in that scope.

We can pass the value of i from the previous scope to the anonymous nested function, but then explicitly establish a new variable j in the new scope to hold that value for future execution of nested functions:

#### Example #4: Closure with new scope establishing a new variable

<pre class="run prettyprint">
for(var i = 0; i &lt; 5; i++) {
  (function() {
    var j = i;
    setTimeout( function() { console.log(j); }, 500*i);
  })();
}
</pre>

Resulting in 0, 1, 2, 3, 4. Let's look at the expression "(function() { ... }) ()":

*   ( ... ) - The first set of round brackets are simply wrappers around an expression.*   ( function() { ... } ) -  Within that expression, we create a new anonymous function.*   ( function() { ... } ) () - Then we take the result of that expression, and call it as a function.

We need to have that wrapping anonymous function, because only functions establish new scope. In fact, we are establishing five new scopes when the loop is run:

*   each iteration establishes it's own closure / anonymous function
*   that closure / anonymous function is immediately executed
*   the value of i is stored in j within the scope of that closure / anonymous function
*   setTimeout() is called, which causes "function() { console.log(j); }" to run at a later point in time
*   When the setTimeout is triggered, the variable j in console.log(j) refers to the j defined in closure / anonymous function

In Javascript, all functions store “a hierarchical chain of all parent variable objects, which are above the current function context; the chain is saved to the function at its creation”. Because the scope chain is stored at creation, it is static and the relative nesting of functions precisely determines variable scope. When scope resolution occurs during code execution, the value for a particular identifier such as i is searched from:

1.  first from the parameters given to the function (a.k.a. the activation object)
2.  and then from the statically stored chain of scopes (stored as the function’s internal property on creation) from top (e.g. parent) to bottom (e.g. global scope).

Javascript will keep the full set of variables of each of the statically stored chains accessible even after their execution has completed, storing them in what is called a variable object. Since code that executes later will receive the value in the variable object at that later time, variables referring to the parent scope of nested code end up having “unexpected” results unless we create a new scope when the parent is run, copy the value from the parent to a variable in that new scope and refer to the variable in the new scope.

For a much more detailed explanation, please read [Dimitry Soshnikov’s detailed account of ECMA-262](http://dmitrysoshnikov.com/ecmascript/javascript-the-core/) which explains these things in full detail; in particular about [Scope chains](http://dmitrysoshnikov.com/ecmascript/chapter-4-scope-chain/) and [Evaluation strategies](http://dmitrysoshnikov.com/ecmascript/chapter-8-evaluation-strategy/).

When you are iterating through the contents of an array, you should use Array.forEach(), as it passes values as function arguments, avoiding this problem. However, in some cases you will still need to use the "create an anonymous function" technique to explicitly establish new scopes.

### 4.3 Other minor gotchas

You should also be aware of the following gotchas:<p>

#### Object properties are not iterated in order (V8)

<p>If you’ve done client-side scripting for Chrome, you might have run into the problems with iterating through the properties of objects. While other current Javascript engines enumerate object properties in insertion order, V8 orders properties with numeric keys in numeric order. For example:

<pre class="run prettyprint">
var a = {"foo":"bar", "2":"2", "1":"1"};
for(var i in a) {
  console.log(i);
};
</pre>

Produces the following output: “1 2 foo” where as in Firefox and other browsers it produces: “foo 2 1”. This means that in V8, you have to use arrays if the order of items is important to you, since the order of properties in an object will not be dependent on the order you write (or insert) them in. This is [technically correct](http://code.google.com/p/v8/issues/detail?id=164), as ECMA-262 does not specify enumeration order for objects. To ensure that items remain in the order you want them to be in, use an array:

<pre class="run prettyprint">
var a = [
  { key: 'foo', val: 'bar'},
  { key: '2', val: '2' },
  { key: '1', val: '1' }
  ];
for(var i in a) {
  console.log(a[i].key)
};
</pre>

Arrays items are always ordered consistently in all compliant implementations, including V8.

#### Comparing NaN with anything (even NaN) is always false

You cannot use the equality operators (==, ===) to determine whether a value is NaN or not. Use the built-in, global isNaN() function:

<pre class="run prettyprint">
console.log(NaN == NaN);
console.log(NaN === NaN);
console.log(isNaN(NaN));
</pre>

The main use case for isNaN() is checking whether a conversion from string to int/float succeeded:

<pre class="run prettyprint">
console.log("Input is 123 - ", !isNaN(parseInt("123", 10)));
console.log("Input is abc - ", !isNaN(parseInt("abc", 10)));
</pre>

#### Floating point precision

Be aware that numbers in Javascript are floating point values, and as such, are not accurate in some cases, such as:

<pre class="run prettyprint">
console.log(0.1 + 0.2);
console.log(0.1 + 0.2 == 0.3);
</pre>

Dealing with numbers with full precision requires specialized solutions.
