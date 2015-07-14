# %chapter_number%. Node fundamentals: Timers, EventEmitters, Streams and Buffers

<div class="summary">

In this chapter, I cover the fundamentals - the essential building blocks of Node applications and core modules.

</div>

The building blocks of Node applications are:

*   **Streams** Readable and writable streams an alternative way of interacting with (file|network|process) I/O.
*   **Buffers** Buffers provide a binary-friendly, higher-performance alternative to strings by exposing raw memory allocation outside the V8 heap.
*   **Events** Many Node.js core libraries emit events. You can use EventEmitters to implement this pattern in your own applications.
*   **Timers** setTimeout for one-time delayed execution of code, setInterval for periodically repeating execution of code
*   **C/C++ Addons** Provide the capability to use your own or 3rd party C/C++ libraries from Node.js

Note that I will not cover C/C++ addons, as this goes beyond the scope of the book.

## %chapter_number%.1 Timers

The timers library consists of four global functions:

<table>
<tr><td>setTimeout(callback, delay, [arg], [...])</td><td>Schedule the execution of the given callback after delay milliseconds. Returns a timeoutId for possible use with clearTimeout(). Optionally, you can also pass arguments to the callback.</td></tr>
<tr><td>setInterval(callback, delay, [arg], [...])</td><td>Schedule the repeated execution of callback every delay milliseconds. Returns a intervalId for possible use with clearInterval(). Optionally, you can also pass arguments to the callback.</td></tr>
<tr><td>clearTimeout(timeoutId)</td><td>Prevents a timeout from triggering.</td></tr>
<tr><td>clearInterval(intervalId)</td><td>Stops an interval from triggering.</td></tr>
</table>

These functions can be used to schedule callbacks for execution. The setTimeout function is useful for performing housekeeping tasks, such as saving the state of the program to disk after a particular interval. The same functions are available in all major browsers:

<pre class="run prettyprint">
// setting a timeout
setTimeout(function() {
  console.log('Foo');
}, 1000);
// Setting and clearing an interval
var counter = 0;
var interval = setInterval( function() {
  console.log('Bar', counter);
  counter++;
  if (counter >= 3) {
    clearInterval(interval);
  }
}, 1000);
</pre>

While you can set a timeout or interval using a string argument (e.g. `setTimeout(‘longRepeatedTask’, 5000)`, this is a bad practice since the string has to be dynamically evaluated (like using the eval() function, which is not recommended). Instead, use a variable or a named function as instead of a string.

Remember that timeouts and intervals are only executed when the execution is passed back to the Node event loop, so timings are not necessarily accurate if you have a long-running blocking task. So a long, CPU-intensive task which takes longer than the timeout/interval time will prevent those tasks from being run at their scheduled times.

## %chapter_number%.2 EventEmitters

event.EventEmitter is a class which is used to provide a consistent interface for emitting (triggering) and binding callbacks to events. It is used internally in many of the Node core libraries and provides a solid foundation to build event-based classes and applications.

#### Using EventEmitters in your own objects

To create a class which extends EventEmitter, you can use utils.inherit():

<pre class="prettyprint">
var EventEmitter = require(‘events’).EventEmitter;
var util = require(‘util’);
// create the class
var MyClass = function () { … }
// augment the prototype using util.inherits
util.inherits(MyClass, EventEmitter);
MyClass.prototype.whatever = function() { … }
</pre>

#### Adding listeners

EventEmitters allow you to add listeners - callbacks - to any arbitrarily named event (except newListener, which is special in EventEmitter). You can attach multiple callbacks to a single event, providing for flexibility. To add a listener, use `EventEmitter.on(event, listener)` or `EventEmitter.addListener(event, listener)` - they both do the same thing:

<pre class="prettyprint">
var obj = new MyClass();
obj.on(‘someevent’, function(arg1) { … });
</pre>

You can use `EventEmitter.once(event, listener)` to add a callback which will only be triggered once, rather than every time the event occurs. This is a good practice, since you should keep the number of listeners to a minimum (in fact, if you have over 10 listerners, EventEmitter will warn you that you need to call emitter.setMaxListeners).

#### Triggering events

To trigger an event from your class, use `EventEmitter.emit(event, [arg1], [arg2], [...])`:

<pre class="prettyprint">MyClass.prototype.whatever = function() {
  this.emit(‘someevent’, ‘Hello’, ‘World’);
};
</pre>

The emit function takes an unlimited number of arguments, and passes those on to the callback(s) associated with the event. You can remove event listeners using `EventEmitter.removeListener(event, listener)` or `EventEmitter.removeAllListeners(event)`, which remove either one listener, or all the listeners associated with a particular event.

#### How EventEmitters work

Now that you have seen the API exposed by EventEmitters, how would something like this be implemented? While there are many things to take care of, the simplest "EventEmitter" would be an object hash containing functions:

<pre class="run prettyprint">
var SimpleEE = function() {
  this.events = {};
};
SimpleEE.prototype.on = function(eventname, callback) {
  this.events[eventname] || (this.events[eventname] = []);
  this.events[eventname].push(callback);
};
SimpleEE.prototype.emit = function(eventname) {
  var args = Array.prototype.slice.call(arguments, 1);
  if (this.events[eventname]) {
    this.events[eventname].forEach(function(callback) {
      callback.apply(this, args);
    });
  }
};
// Example using the event emitter
var emitter = new SimpleEE();
emitter.on('greet', function(name) {
  console.log('Hello, ' + name + '!' );
});
emitter.on('greet', function(name) {
  console.log('World, ' + name + '!' );
});
['foo', 'bar', 'baz'].forEach(function(name) {
  emitter.emit('greet', name);
});
</pre>

It's really pretty simple - though the [Node core EventEmitter class](http://nodejs.org/api/events.html) has many additional features (such as being able to attach multiple callbacks per event, removing listeners, calling listeners only once, performance-related improvements etc.).

EventEmitters extremely useful for abstracting event-based interactions, and if this introduction seems a bit too theoretical - don't worry. You'll see EventEmitters used in many different situations and will hopefully learn to love them. EventEmitters are also used extensively in Node core libraries.

One thing that you should be aware of is that EventEmitters are not “privileged” in any way - despite having “Event” in their name, they are executed just like any other code - emitting events does not trigger the event loop in any special way. Of course, you should use asynchronous functions for I/O in your callbacks, but EventEmitters are simply a standard way of implementing this kind of interface. You can verify this by [reading the source code for EventEmitters on Github](https://github.com/joyent/node/blob/master/lib/events.js).

## %chapter_number%.3 Streams

We’ve discussed the three main alternatives when it comes to controlling execution: Sequential, Full Parallel and Parallel. Streams are an alternative way of accessing data from various sources such as the network (TCP/UDP), files, child processes and user input. In doing I/O, Node offers us multiple options for accessing the data:

<table>
<tr><td></td>                              <td>Synchoronous</td><td>Asynchronous</td></tr>
<tr><td>Fully buffered</td>                <td>readFileSync()</td><td>readFile()</td></tr>
<tr><td>Partially buffered (streaming)</td><td>readSync()</td><td>read(), createReadStream()</td></tr>
</table>

The difference between these is how the data is exposed, and the amount of memory used to store the data.

#### Fully buffered access

<pre>
// Fully buffered access
[100 Mb file]
-> 1. [allocate 100 Mb buffer]
-> 2. [read and return 100 Mb buffer]
</pre>

Fully buffered function calls like readFileSync() and readFile() expose the data as one big blob. That is, reading is performed and then the full set of data is returned either in synchronous or asynchronous fashion.

With these fully buffered methods, we have to wait until all of the data is read, and internally Node will need to allocate enough memory to store all of the data in memory. This can be problematic - imagine an application that reads a 1 GB file from disk. With only fully buffered access we would need to use 1 GB of memory to store the whole content of the file for reading - since both readFile and readFileSync return a string containing all of the data.

#### Partially buffered (streaming) access

<pre>
// Streams (and partially buffered reads)
[100 Mb file]
-> 1. [allocate small buffer]
-> 2. [read and return small buffer]
-> 3. [repeat 1&amp;2 until done]
</pre>

Partially buffered access methods are different. They do not treat data input as a discrete event, but rather as a series of events which occur as the data is being read or written. They allow us to access data as it is being read from disk/network/other I/O.

Partially buffered methods, such as readSync() and read() allow us to specify the size of the buffer, and read data in small chunks. They allow for more control (e.g. reading a file in non-linear order by skipping back and forth in the file).

#### Streams

However, in most cases we only want to read/write through the data once, and in one direction (forward). Streams are an abstraction over partially buffered data access that simplify doing this kind of data processing. Streams return smaller parts of the data (using a Buffer), and trigger a callback when new data is available for processing.

Streams are EventEmitters. If our 1 GB file would, for example, need to be processed in some way once, we could use a stream and process the data as soon as it is read. This is useful, since we do not need to hold all of the data in memory in some buffer: after processing, we no longer need to keep the data in memory for this kind of application.

The Node stream interface consists of two parts: Readable streams and Writable streams. Some streams are both readable and writable.

#### Readable streams

The following Node core objects are Readable streams:

<table>
<tr><td>Files fs.createReadStream(path, [options])</td><td>Returns a new ReadStream object (See Readable Stream).</td></tr>
<tr><td>HTTP (Server) http.ServerRequest</td><td>The request object passed when processing the request/response callback for HTTP servers.</td></tr>
<tr><td>HTTP (Client) http.ClientResponse</td><td>The response object passed when processing the response from an HTTP client request.</td></tr>
<tr><td>TCP net.Socket</td><td>Construct a new socket object.</td></tr>
<tr><td>Child process child.stdout</td><td>The stdout pipe for child processes launched from Node.js</td></tr>
<tr><td>Child process child.stderr</td><td>The stderr pipe for child processes launched from Node.js</td></tr>
<tr><td>Process process.stdin</td><td>A Readable Stream for stdin. The stdin stream is paused by default, so one must call process.stdin.resume() to read from it.</td></tr>
</table>

[Readable streams](http://nodejs.org/api/streams.html#readable_Stream) emit the following events:

<table>
  <tr><td>Event: ‘data’</td><td>Emits either a Buffer (by default) or a string if setEncoding() was used.</p>
  <tr><td>Event: ‘end’</td><td>Emitted when the stream has received an EOF (FIN in TCP terminology). Indicates that no more 'data' events will happen.</td></tr>
  <tr><td>Event: ‘error’</td><td>Emitted if there was an error receiving data.</td></tr>
</table>

To bind a callback to an event, use stream.on(eventname, callback). For example, to read data from a file, you could do the following:

<pre class="prettyprint">
var fs = require('fs');
var file = fs.createReadStream('./test.txt');
file.on('error', function(err) {
  console.log('Error '+err);
  throw err;
});
file.on('data', function(data) {
  console.log('Data '+data);
});
file.on('end', function(){
  console.log('Finished reading all of the data');
});
</pre>

Readable streams have the following functions:

<table>
  <tr><td>pause()</td><td>Pauses the incoming 'data' events.</td></tr>
  <tr><td>resume()</td><td>Resumes the incoming 'data' events after a pause().</td></tr>
  <tr><td>destroy()</td><td>Closes the underlying file descriptor. Stream will not emit any more events.</td></tr>
</table>

#### Writable streams

The following Node core objects are Writable streams:

<table>
  <tr><td>Files fs.createWriteStream(path, [options])</td><td>Returns a new WriteStream object (See Writable Stream).</td></tr>
  <tr><td>HTTP (Server) http.ServerResponse </td><td></td></tr>
  <tr><td>HTTP (Client) http.ClientRequest  </td><td></td></tr>
  <tr><td>TCP net.Socket  </td><td></td></tr>
  <tr><td>Child process child.stdin </td><td></td></tr>
  <tr><td>Process process.stdout</td><td>A Writable Stream to stdout.</td></tr>
  <tr><td>Process process.stderr</td><td>A writable stream to stderr. Writes on this stream are blocking.</td></tr>
</table>

Writable streams emit the following events:

<table>
  <tr><td>Event: ’drain’</td><td>After a write() method returned false, this event is emitted to indicate that it is safe to write again.</td></tr>
  <tr><td>Event: ’error’</td><td>Emitted on error with the exception exception.</td></tr>
</table>

Writable streams have the following functions:

<table>
  <tr><td>write(string, encoding='utf8')</td><td>Writes string with the given encoding to the stream.</td></tr>
  <tr><td>end()</td><td>Terminates the stream with EOF or FIN. This call will allow queued write data to be sent before closing the stream.</td></tr>
  <tr><td>destroy()</td><td>Closes the underlying file descriptor. Stream will not emit any more events. Any queued write data will not be sent.</td></tr>
</table>

Lets read from stdin and write to a file:

<pre class="prettyprint">
var fs = require('fs');

var file = fs.createWriteStream('./out.txt');

process.stdin.on('data', function(data) {
  file.write(data);
});
process.stdin.on('end', function() {
  file.end();
});
process.stdin.resume(); // stdin in paused by default
</pre>

Running the code above will write everything you type in from stdin to the file out.txt, until you hit Ctrl+d (e.g. the end of file indicator in Linux).

You can also pipe readable and writable streams using readableStream.pipe(destination, [options]). This causes the content from the read stream to be sent to the write stream, so the program above could have been written as:

<pre class="prettyprint">
var fs = require('fs');
process.stdin.pipe(fs.createWriteStream('./out.txt'));
process.stdin.resume();
</pre>

## %chapter_number%.4 Buffers - working with binary data

<p>Buffers in Node are a higher-performance alternative to strings. Since Buffers represent raw C memory allocation, they are more appropriate for dealing with binary data than strings. There are two reasons why buffers are useful:

They are allocated outside of V8, meaning that they are not managed by V8. While V8 is generally high performance, sometimes it will move data unnecessarily. Using a Buffer allows you to work around this and work with the memory more directly for higher performance.

They do not have an encoding, meaning that their length is fixed and accurate. Strings support encodings such as UTF-8, which internally stores many foreign characters as a sequence of bytes. Manipulating strings will always take into account the encoding, and will transparently treat sequences of bytes as single characters. This causes problems for binary data, since binary data (like image files) are not encoded as characters but rather as bytes  - but may coincidentally contain byte sequences which would be interpreted as single UTF-8 characters.

Working with buffers is a bit more complicated than working with strings, since they do not support many of the functions that strings do (e.g. indexOf). Instead, buffers act like fixed-size arrays of integers. The Buffer object is global (you don’t have to use require() to access it). You can create a new Buffer and work with it like an array of integers:

<pre class="prettyprint">// Create a Buffer of 10 bytes
var buffer = new Buffer(10);
// Modify a value
buffer[0] = 255;
// Log the buffer
console.log(buffer);
// outputs: &lt;Buffer ff 00 00 00 00 00 4a 7b 08 3f&gt;
</pre>

Note how the buffer has it’s own representation, in which each byte is shown a hexadecimal number. For example, ff in hex equals 255, the value we just wrote in index 0. Since Buffers are raw allocations of memory, their content is whatever happened to be in memory; this is why there are a number of different values in the newly created buffer in the example.

Buffers do not have many predefined functions and certainly lack many of the features of strings. For example, strings are not fixed size, and have convenient functions such as String.replace(). Buffers are fixed size, and only offer the very basics:

<table>
<tr><td>
  new Buffer(size)

new Buffer(str, encoding='utf8')

new Buffer(array)
</td><td>Buffers can be created: 1) with a fixed size, 2) from an existing string and 3) from an array of octets</td></tr>

<tr><td>buffer.write(string, offset=0, encoding='utf8')</td><td>Write a string to the buffer at [offset] using the given encoding.</td></tr>
<tr><td>buffer.isBuffer(obj)</td><td>Tests if obj is a Buffer.</td></tr>
<tr><td>buffer.byteLength(string, encoding='utf8')</td><td>Gives the actual byte length of a string. This is not the same as String.prototype.length since that returns the number of characters in a string.</td></tr>
<tr><td>buffer.length</td><td>The size of the buffer in bytes.</td></tr>
<tr><td>buffer.copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)</td><td>Does a memcpy() between buffers.</td></tr>
<tr><td>buffer.slice(start, end=buffer.length)</td><td>Returns a new buffer which references the same memory as the old, but offset and cropped by the start and end indexes.

Modifying the new buffer slice will modify memory in the original buffer!
</td></tr>
<tr><td>buffer.toString(encoding, start=0, end=buffer.length)</td><td>Decodes and returns a string from buffer data encoded with encoding beginning at start and ending at end.</td></tr>
</table>

However, if you need to use the string functions on buffers, you can convert them to strings using buffer.toString() and you can also convert strings to buffers using new Buffer(str). Note that Buffers offer access to the raw bytes in a string, while Strings allow you to operate on charaters (which may consist of one or more bytes). For example:

<pre class="prettyprint">
var buffer = new Buffer('Hyvää päivää!'); // create a buffer containing “Good day!” in Finnish
var str = 'Hyvää päivää!'; // create a string containing “Good day!” in Finnish
// log the contents and lengths to console
console.log(buffer);
console.log('Buffer length:', buffer.length);
console.log(str);
console.log('String length:', str.length);
</pre>

If you run this example, you will get the following output:

<pre>
&lt;Buffer 48 79 76 c3 a4 c3 a4 20 70 c3 a4 69 76 c3 a4 c3 a4 21&gt;
Buffer length: 18
Hyvää päivää!
String length: 13
</pre>

Note how buffer.length is 18, while string.length is 13 for the same content. This is because in the default UTF-8 encoding, the “a with dots” character is represented internally by two characters (“c3 a4” in hexadecimal). The Buffer allows us to access the data in it’s internal representation and returns the actual number of bytes used, while String takes into account the encoding and returns the number of characters used. When working with binary data, we frequently need to access data that has no encoding - and using Strings we could not get the correct length in bytes. More realistic examples could be, for example, reading an image file from a TCP stream, or reading a compressed file, or some other case where binary data will be accessed.
