home: index.html
prev: ch1.html
next: ch3.html
---
# 2. What is Node.js?

<div class="summary">
  In this chapter, I:
  <ul>
    <li>describe the Node.js event loop and the premise behind asynchronous I/O</li>
    <li>go through an example of how context switches are made between V8 and Node</li>
  </ul>
</div>

Node - or Node.js, as it is called to distinguish it from other "nodes" - is an event-driven I/O framework for the V8 JavaScript engine. Node.js allows Javascript to be executed on the server side, and it uses the wicked fast V8 Javascript engine which was developed by Google for the Chrome browser.

The basic philosophy of node.js is:

*   **Non-blocking I/O** - every I/O call must take a callback, whether it is to retrieve information from disk, network or another process.
*   **Built-in support for the most important protocols** (HTTP, DNS, TLS)
*   **Low-level**. Do not remove functionality present at the POSIX layer. For example, support half-closed TCP connections.
*   **Stream everything**; never force the buffering of data.

Node.js is different from client-side Javascript in that it removes certain things, like DOM manipulation, and adds support for evented I/O, processes, streams, HTTP, SSL, DNS, string and buffer processing and C/C++ addons.

Let's skip the boring general buzzword bingo introduction and get to the meat of the matter - how does node run your code?

## The Event Loop - understanding how Node executes Javascript code

The event loop is a mechanism which allows you to specify what happens when a particular event occurs. This might be familiar to you from writing client-side Javascript, where a button might have an onClick event. When the button is clicked, the code associated with the onClick event is run. Node simply extends this idea to I/O operations: when you start an operation like reading a file, you can pass control back to Node and have your code run when the data has been read. For example:

```js
// read the file /etc/passwd, and call console.log on the returned data
fs.readFile('/etc/passwd', function(err, data){
  console.log(data);
});
```

You can think of the event loop as a simple list of tasks (code) bound to events. When an event happens, the code/task associated with that event is executed.

Remember that all of your code in Node is running in a single process. There is no parallel execution of Javascript code that you write - you can only be running a single piece of code at any time. Consider the following code, in which:

1.  We set a function to be called after 1000 milliseconds using setTimeout() and then
2.  start a loop that blocks for 4 seconds.

What will happen?

```js
// set function to be called after 1 second
setTimeout(function() {
   console.log('Timeout ran at ' + new Date().toTimeString());
}, 1000);

// store the start time
var start = new Date();
console.log('Enter loop at: '+start.toTimeString());

// run a loop for 4 seconds
var i = 0;
// increment i while (current time &lt; start time + 4000 ms)
while(new Date().getTime() &lt; start.getTime() + 4000) {
   i++;
}
console.log('Exit loop at: '
            +new Date().toTimeString()
            +'. Ran '+i+' iterations.');

```

Because your code executes in a single process, the output looks like this:

<pre>
Enter loop at: 20:04:50 GMT+0300 (EEST)
Exit loop at: 20:04:54 GMT+0300 (EEST). Ran 3622837 iterations.
Timeout ran at 20:04:54 GMT+0300 (EEST)
</pre>

Notice how the setTimeout function is only triggered after four seconds. This is because Node cannot and will not interrupt the while loop. The event loop is only used to determine what to do next when the execution of your code finishes, which in this case is after four seconds of forced waiting. If you have a CPU-intensive task that takes four seconds to complete, then a Node server would not be able to respond to other requests during those four seconds, since the event loop is only checked for new tasks once your code finishes.

Some people have criticized Node's single process model because it is possible to block the current thread of execution like shown above.

However, the alternative - using threads and coordinating their execution - requires somewhat intricate coding to work and is only useful if CPU cycles are the main bottleneck. In my view, Node is about taking a simple idea (single-process event loops), and seeing how far one can go with it.  Even with a single process model, you can move CPU-intensive work to other background processes, for example by setting up a queue which is processed by a pool of workers, or by load balancing over multiple processes. If you are performing CPU-bound work, then the only real solutions are to either figure out a better algorithm (to use less CPU) or to scale to multiple cores and multiple machines (to get more CPU's working on the problem).

The premise of Node is that I/O is the main bottleneck of many (if not most) tasks. A single I/O operation can take millions of CPU cycles, and in traditional, non-event-loop-based frameworks the execution is blocked for that time. In Node, I/O operations such as reading a file are performed asynchronously. This is simply a fancy way of saying that you can pass control back to the event loop when you are performing I/O, like reading a file, and specify the code you want to run when the data is available using a callback function. For example:

```js
setTimeout(function() {
   console.log('setTimeout at '+new Date().toTimeString());
}, 1000);

require('fs').readFile('/etc/passwd', function(err, result) {
  console.log(result);
} );
```

Here, we are reading a file using an asynchronous function, fs.readFile(), which takes as arguments the name of the file and a callback function. When Node executes this code, it starts the I/O operation in the background. Once the execution has passed over fs.readFile(), control is returned back to Node, and the event loop gets to run.

When the I/O operation is complete, the callback function is executed, passing the data from the file as the second argument. If reading the file takes longer than 1 second, then the function we set using setTimeout will be run after 1 second - before the file reading is completed.

In node.js, you aren’t supposed to worry about what happens in the backend: just use callbacks when you are doing I/O; and you are guaranteed that your code is never interrupted and that doing I/O will not block other requests.

Having asynchronous I/O is good, because I/O is more expensive than most code and we should be doing something better than just waiting for I/O. The event loop is simply a way of coordinating what code should run during I/O, which executes whenever your code finishes executing. More formally, an event loop is “an entity that handles and processes external events and converts them into callback invocations”.

By making calls to the asynchronous functions in Node’s core libraries, you specify what code should run once the I/O operation is complete. You can think of  I/O calls as the points at which Node.js can switch from executing one request to another. At an I/O call, your code saves the callback and returns control to the Node runtime environment. The callback will be called later when the data is available.

Of course, on the backend - invisible to you as a Node developer -  may be thread polls and separate processes doing work. However, these are not explicitly exposed to your code, so you can’t worry about them other than by knowing that I/O interactions e.g. with the database, or with other processes will be asynchronous from the perspective of each request since the results from those threads are returned via the event loop to your code. Compared to the non-evented multithreaded approach (which is used by servers like Apache and most common scripting languages), there are a lot fewer threads and thread overhead, since threads aren’t needed for each connection; just when you absolutely positively must have something else running in parallel and even then the management is handled by Node.js.

Other than I/O calls, Node.js expects that all requests return quickly; e.g. CPU-intensive work should be split off to another process with which you can interact with as with events, or by using an abstraction such as WebWorkers (which will be supported in the future). This (obviously) means that you can’t parallelize your code without another process in the background with which you interact with asynchronously. Node provides the tools to do this, but more importantly makes working in an evented, asynchronous manner easy.

### Example: A look at the event loop in a Node.js HTTP server

Let’s look at a very simple Node.js HTTP server (server.js):

```js
var http = require('http');
var content = '&lt;html&gt;&lt;body&gt;&lt;p&gt;Hello World&lt;/p&gt;&lt;script type=”text/javascript”'
    +'>alert(“Hi!”);&lt;/script&gt;&lt;/body&gt;&lt;/html&gt;';
http.createServer(function (request, response) {
   response.end(content);
}).listen(8080, 'localhost');
console.log('Server running at http://localhost:8080/.');
```

You can run this code using the following command:

```
node server.js
```

In the simple server, we first require the http library (a Node core library). Then we instruct that server to listen on port 8080 on your computer (localhost). Finally, we write a console message using console.log().

When the code is run, the Node runtime starts up, loads the V8 Javascript engine which runs the script. The call to http.createServer creates a server, and the listen() call instructs the server to listen on port 8080. The program at the console.log() statement has the following state:

<pre>
[V8 engine running server.js]
[Node.js runtime]
</pre>

After the console message is written, control is returned to the runtime. The state of the program at that time is stored as the execution context “server.js”.

<pre>
[Node.js runtime (waiting for client request to run callback) ]
</pre>

The runtime check will check for pending callbacks, and will find one pending callback - namely, the callback function we gave to http.createServer(). This means that the server program will not exit immediately, but will wait for an event to occur.

When you navigate your browser to http://localhost:8080/, the Node.js runtime receives an event which indicates that a new client has connected to the server. It searches the internal list of callbacks to find the callback function we have set previously to respond to new client requests, and executes it using V8 in the execution context of server.js.

<pre>
[V8 engine running the callback in the server.js context]
[Node.js runtime]
</pre>

When the callback is run, it receives two parameters which represent the client request (the first parameter, request), and the response (the second parameter). The callback calls response.end(), passing the variable content and instructing the response to be closed after sending that data back. Calling response.end() causes some core library code to be run which writes the data back to the client. Finally, when the callback finishes, the control is returned back to the Node.js runtime:

<pre>
[Node.js runtime (waiting for client request to run callback)]
</pre>

As you can see, whenever Node.js is not executing code, the runtime checks for events (more accurately it uses platform-native API’s which allow it to be activated when events occur). Whenever control is passed to the Node.js runtime, another event can be processed. The event could be from an HTTP client connection, or perhaps from a file read. Since there is only one process, there is no parallel execution of Javascript code. Even though you may have several evented I/O operations with different callbacks ongoing, only one of them will have it's Node/Javascript code run at a time (the rest will be activated whenever they are ready and no other JS code is running).

The client (your web browser) will receive the data and interpret it as HTML. The alert() call in the Javascript tag in the returned data will run in your web browser, and the HTML containing “Hello World” will be displayed. It is important to realize that just because both the server and the client are running Javascript, there is no “special” connection - each has it’s own Javascript variables, functions and context. The data returned from the client request callback is just data and there is no automatic sharing or built-in ability to call functions on the server without issuing a server request.

However, because both the server and the client are written in Javascript, you can share code. And even better, since the server is a persistent program, you can build programs that have long-term state - unlike in scripting languages like PHP, where the script is run once and then exits, Node has it’s own internal HTTP server which is capable of saving the state of the program and resuming it quickly when a new request is made.
