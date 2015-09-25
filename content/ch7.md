home: index.html
prev: ch6.html
next: ch8.html
---
# 7. Control flow

<div class="summary">
In this chapter, I:

  <ul>
    <li>discuss nested callbacks and control flow in Node</li>
    <li>introduce three essential async control flow patterns:
      <ul>
        <li>Series - for running async tasks one at a time</li>
        <li>Fully parallel - for running async tasks all at the same time</li>
        <li>Limitedly parallel - for running a limited number of async tasks at the same time</li>
      </ul>
    </li>
    <li>walk you through a simple implementation of these control flow patterns</li>
    <li>and convert the simple implementation into a control flow library that takes callback arguments</li>
  </ul>
</div>

When you start coding with Node.js, it’s a bit like learning programming the first time. Since you want everything to be asynchronous, you use a lot of callbacks without really thinking about how you should structure your code. It’s a bit like being overexcited about the if statement, and using it and only it to write complex programs. One of my first programs in primary school was a text-based adventure where you would be presented with a scenario and a choice. I wrote code until I reached the maximum level of nesting supported by the compiler, which probably was 63 nested if statements.

Learning how to code with callbacks is similar in many ways. If that is the only tool you use, you will create a mess.

Enlightenment comes when you realize that this:

```js
async1(function(input, result1) {
  async2(function(result2) {
    async3(function(result3) {
      async4(function(result4) {
        async5(function(output) {
            // do something with output
        });
      });
    });
  });
})
```

ought be written as:

```js
myLibrary.doStuff(input, function(output){
  // do something with output
});
```

In other words, you can and are supposed to think in terms of higher level abstractions. Refactor, and extract functionality into it’s own module. There can be any number of callbacks between the input that matters and the output that matters, just make sure that you split the functionality into meaningful modules rather than dumping it all into one long chain.

Yes, there will still be some nested callbacks. However, more than a couple of levels of nesting would should be a code smell - time to think what you can abstract out into separate, small modules. This has the added benefit of making testing easier, because you end up having smaller, hopefully meaningful code modules that provide a single capability.

Unlike in tradional scripting languages based on blocking I/O, managing the control flow of applications with callbacks can warrant specialized modules which coordinate particular work flows: for example, by dealing with the level concurrency of execution.<p>

<p>Blocking on I/O provides just one way to perform I/O tasks: sequentially (well, at least without threads). With Node's "everything can be done asynchronously" approach, we get more options and can choose when to block, when to limit concurrency and when to just launch a bunch of tasks at the same time.

Let's look at the most common control flow patterns, and see how we can take something as abstract as control flow and turn it into a small, single purpose module to take advantage of callbacks-as-input.

## 7.2 Control flow: Specifying execution order

If you’ve started reading some of the tutorials online, you’ll find a bewildering number of different control-flow libraries for Node. I find it quite confusing that each of these has it’s own API and terminology - talking about promises, steps, vows, futures and so on. Rather than endorse any particular control flow solution, let’s drill down to the basics, look at some fundamental patterns and try to come up with a simple and undramatic set of terms to describe the different options we have for control flow in Node.

As you already know, there are two types of API functions in Node.js:

1.  asynchronous, non-blocking functions - for example:  fs.readFile(filename, [encoding], [callback])
2.  synchronous, blocking functions - for example: fs.readFileSync(filename, [encoding])

Synchronous functions return a result:

```js
var data = fs.readFileSync('/etc/passwd');
```

While asynchronous functions receive the result via a callback (after passing control to the event loop):

```js
fs.readFileSync('/etc/passwd', function(err, data) { … } );
```

Writing synchronous code is not problematic: we can draw on our experience in other languages to structure it appropriately using keywords like if, else, for, while and switch. It’s the way we should structure asynchronous calls which is most problematic, because established practices do not help here. For example, we’d like to read a thousand text files. Take the following naive code:

```js
for(var i = 1; i &lt;= 1000; i++) {
  fs.readFile('./'+i+'.txt', function() {
     // do something with the file
  });
}
do_next_part();
```

This code would start 1000 simultaneous asynchronous file reads, and run the do_next_part() function immediately. This has several problems: first, we’d like to wait until all the file reads are done until going further. Second, launching a thousand file reads simultaneously will quickly exhaust the number of available file handles (a limited resource needed to read files). Third, we do not have a way to accumulate the result for do_next_part().

We need:

*   a way to control the order in which the file reads are done
*   some way to collect the result data for processing
*   some way to restrict the concurrency of the file read operations to conserve limited system resources
*   a way to determine when all the reads necessary for the do_next_part() are completed

Control flow functions enable us to do this in Node.js. A control flow function is a lightweight, generic piece of code which runs in between several asynchronous function calls and which take care of the necessary housekeeping to:

1.  control the order of execution,
2.  collect data,
3.  limit concurrency and
4.  call the next step in the program.

There are three basic patterns for this.

### 7.2.1 Control flow pattern #1: Series - an asynchronous for loop

Sometimes we just want to do one thing at a time. For example, we need to do five database queries, and each of those queries needs data from the previous query, so we have to run one after another.

A series does that:

<pre class="run prettyprint">
// Async task (same in all examples in this chapter)
function async(arg, callback) {
  console.log('do something with \''+arg+'\', return 1 sec later');
  setTimeout(function() { callback(arg * 2); }, 1000);
}
// Final task (same in all the examples)
function final() { console.log('Done', results); }

// A simple async series:
var items = [ 1, 2, 3, 4, 5, 6 ];
var results = [];
function series(item) {
  if(item) {
    async( item, function(result) {
      results.push(result);
      return series(items.shift());
    });
  } else {
    return final();
  }
}
series(items.shift());
</pre>

Basically, we take a set of items and call the series control flow function with the first item. The series launches one async() operation, and passes a callback to it. The callback pushes the result into the results array and then calls series with the next item in the items array. When the items array is empty, we call the final() function.

This results in serial execution of the asynchronous function calls. Control is passed back to the Node event loop after each async I/O operation is completed, then returned back when the operation is completed.

**Characteristics:**

*   Runs a number of operations sequentially
*   Only starts one async operation at a time (no concurrency)
*   Ensures that the async function complete in order

**Variations:**

*   The way in which the result is collected (manual or via a “stashing” callback)
*   How error handling is done (manually in each subfunction, or via a dedicated, additional function)
*   Since execution is sequential, there is no need for a “final” callback

**Tags:** sequential, no-concurrency, no-concurrency-control

### 7.2.2 Control flow pattern #2: Full parallel - an asynchronous, parallel for loop

In other cases, we just want to take a small set of operations, launch them all in parallel and then do something when all of them are complete.

A fully parallel control flow does that:

<pre class="run prettyprint">
function async(arg, callback) {
  console.log('do something with \''+arg+'\', return 1 sec later');
  setTimeout(function() { callback(arg * 2); }, 1000);
}
function final() { console.log('Done', results); }

var items = [ 1, 2, 3, 4, 5, 6 ];
var results = [];

items.forEach(function(item) {
  async(item, function(result){
    results.push(result);
    if(results.length == items.length) {
      final();
    }
  })
});
</pre>

We take every item in the items array and start async operations for each of the items immediately. The async() function is passed a function that stores the result and then checks whether the number of results is equal to the number of items to process. If it is, then we call the final() function.

Since this means that all the I/O operations are started in parallel immediately, we need to be careful not to exhaust the available resources. For example, you probably don't want to start 1000's of I/O operations, since there are operating system limitations for the number of open file handles. You need to consider whether launching parallel tasks is OK on a case-by-case basis.

**Characteristics:**

*   Runs a number of operations in parallel
*   Starts all async operations in parallel (full concurrency)
*   No guarantee of order, only that all the operations have been completed

**Variations:**

*   The way in which the result is collected (manual or via a “stashing” callback)
*   How error handling is done (via the first argument of the final function, manually in each subfunction, or via a dedicated, additional function)
*   Whether a final callback can be specified

Tags: parallel, full-concurrency, no-concurrency-control

### 7.2.3 Control flow pattern #3: Limited parallel - an asynchronous, parallel, concurrency limited for loop

In this case, we want to perform some operations in parallel, but keep the number of running I/O operations under a set limit:

<pre class="run prettyprint">
function async(arg, callback) {
  console.log('do something with \''+arg+'\', return 1 sec later');
  setTimeout(function() { callback(arg * 2); }, 1000);
}
function final() { console.log('Done', results); }

var items = [ 1, 2, 3, 4, 5, 6 ];
var results = [];
var running = 0;
var limit = 2;

function launcher() {
  while(running &lt; limit &amp;&amp; items.length &gt; 0) {
    var item = items.shift();
    async(item, function(result) {
      results.push(result);
      running--;
      if(items.length &gt; 0) {
        launcher();
      } else if(running == 0) {
        final();
      }
    });
    running++;
  }
}

launcher();
</pre>

We start new async() operations until we reach the limit (2). Each async() operation gets a callback which stores the result, decrements the number of running operations, and then check whether there are items left to process. If yes, then laucher() is run again. If there are no items to process and the current operation was the last running operation, then final() is called.

Of course, the criteria for whether or not we should launch another task could be based on some other logic. For example, we might keep a pool of database connections, and check whether "spare" connections are available - or check server load - or make the decision based on some more complicated criteria.

**Characteristics:**

*   Runs a number of operations in parallel
*   Starts a limited number of operations in parallel (partial concurrency, full concurrency control)
*   No guarantee of order, only that all the operations have been completed

## 7.3 Building a control flow library on top of these patterns

For the sake of simplicity, I used a fixed array and named functions in the control flow patterns above.

The problem with the examples above is that the control flow is intertwined with the data structures of our specific use case: taking items from an array and populating another array with the results from a single function.

We can write the same control flows as functions that take arguments in the form:

```js
series([
  function(next) { async(1, next); },
  function(next) { async(2, next); },
  function(next) { async(3, next); },
  function(next) { async(4, next); },
  function(next) { async(5, next); },
  function(next) { async(6, next); }
], final);
```

E.g. an array of callback functions and a final() function.

The callback functions get a next() function as their first parameter which they should call when they have completed their async operations. This allows us to use any async function as part of the control flow.

The final function is called with a single parameter: an array of arrays with the results from each async call. Each element in the array corresponds the values passed back from the async function to next(). Unlike the examples in previous section, these functions store all the results from the callback, not just the first argument - so you can call next(1, 2, 3, 4) and all the arguments are stored in the results array.

### Series

This conversion is pretty straightforward. We pass an anonymous function which pushes to results and calls next() again: this is so that we can push the results passed from the callback via [arguments](https://developer.mozilla.org/en/JavaScript/Reference/Functions_and_function_scope/arguments) immediately, rather than passing them directly to next() and handling them in next().

<pre class="run prettyprint">
function series(callbacks, last) {
  var results = [];
  function next() {
    var callback = callbacks.shift();
    if(callback) {
      callback(function() {
        results.push(Array.prototype.slice.call(arguments));
        next();
      });
    } else {
      last(results);
    }
  }
  next();
}
// Example task
function async(arg, callback) {
  var delay = Math.floor(Math.random() * 5 + 1) * 100; // random ms
  console.log('async with \''+arg+'\', return in '+delay+' ms');
  setTimeout(function() { callback(arg * 2); }, delay);
}
function final(results) { console.log('Done', results); }

series([
  function(next) { async(1, next); },
  function(next) { async(2, next); },
  function(next) { async(3, next); },
  function(next) { async(4, next); },
  function(next) { async(5, next); },
  function(next) { async(6, next); }
], final);
</pre>

### Full parallel

Unlike in a series, we cannot assume that the results are returned in any particular order.

Because of this we use callbacks.forEach, which returns the index of the callback - and store the result to the same index in the results array.

Since the last callback could complete and return it's result first, we cannot use results.length, since the length of an array always returns the largest index in the array + 1. So we use an explicit result_counter to track how many results we've gotten back.

<pre class="run prettyprint">
function fullParallel(callbacks, last) {
  var results = [];
  var result_count = 0;
  callbacks.forEach(function(callback, index) {
    callback( function() {
      results[index] = Array.prototype.slice.call(arguments);
      result_count++;
      if(result_count == callbacks.length) {
        last(results);
      }
    });
  });
}
// Example task
function async(arg, callback) {
  var delay = Math.floor(Math.random() * 5 + 1) * 100; // random ms
  console.log('async with \''+arg+'\', return in '+delay+' ms');
  setTimeout(function() { callback(arg * 2); }, delay);
}
function final(results) { console.log('Done', results); }

fullParallel([
  function(next) { async(1, next); },
  function(next) { async(2, next); },
  function(next) { async(3, next); },
  function(next) { async(4, next); },
  function(next) { async(5, next); },
  function(next) { async(6, next); }
], final);
</pre>

### Limited parallel

This is a bit more complicated, because we need to launch async tasks once other tasks finish, and need to store the result from those tasks back into the correct position in the results array. Details further below.

<pre class="run prettyprint">
function limited(limit, callbacks, last) {
  var results = [];
  var running = 1;
  var task = 0;
  function next(){
    running--;
    if(task == callbacks.length &amp;&amp; running == 0) {
      last(results);
    }
    while(running &lt; limit &amp;&amp; callbacks[task]) {
      var callback = callbacks[task];
      (function(index) {
        callback(function() {
          results[index] = Array.prototype.slice.call(arguments);
          next();
        });
      })(task);
      task++;
      running++;
    }
  }
  next();
}
// Example task
function async(arg, callback) {
  var delay = Math.floor(Math.random() * 5 + 1) * 1000; // random ms
  console.log('async with \''+arg+'\', return in '+delay+' ms');
  setTimeout(function() {
    var result = arg * 2;
    console.log('Return with \''+arg+'\', result '+result);
    callback(result);
  }, delay);
}
function final(results) { console.log('Done', results); }

limited(3, [
  function(next) { async(1, next); },
  function(next) { async(2, next); },
  function(next) { async(3, next); },
  function(next) { async(4, next); },
  function(next) { async(5, next); },
  function(next) { async(6, next); }
], final);
</pre>

We need to keep two counter values here: one for the next task, and another for the callback function.

In the fully parallel control flow we took advantage of [].forEach(), which returns the index of the currently running task in it's own scope.

Since we cannot rely on forEach() as tasks are launched in small groups, we need to use an anonymous function to get a new scope to hold the original index. This index is used to store the return value from the callback.

To illustrate the problem, I added a longer delay to the return from async() and an additional line of logging which shows when the result from async is returned. At that moment, we need to store the return value to the right index.

The anonymous function: (function(index) { ... } (task)) is needed because if we didn't create a new scope using an anonymous function, we would store the result in the wrong place in the results array (since the value of task might have changed between calling the callback and returning back from the callback). See [the chapter on Javascript gotchas](ch4.html) for more information on scope rules in JS.

## 7.4 The fourth control flow pattern

There is a fourth control flow pattern, which I won't discuss here: eventual completion. In this case, we are not interested in strictly controlling the order of operations, only that they occur at some point and are correctly responded to.

In Node, this can be implemented using EventEmitters. These are discussed in the chapter on Node fundamentals.
