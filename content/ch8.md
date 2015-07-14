# %chapter_number%. An overview of Node: Modules and npm

<div class="summary">In this chapter, I:

*   discuss modules and process-related globals in Node
</div>

Node.js has a good amount of functionality built in. Let's look at the [Table of Contents for the API documentation](http://nodejs.org/api/) and try to group it into manageable chunks (_italic_ = not covered here):

<table>
  <tr>
    <td>
**Fundamentals**

*   [Globals](http://nodejs.org/api/globals.html)
*   [STDIO](http://nodejs.org/api/stdio.html)
*   [Timers](http://nodejs.org/api/timers.html)
*   [Modules](http://nodejs.org/api/modules.html)
*   [Events](http://nodejs.org/api/events.html)
*   [Buffers](http://nodejs.org/api/buffers.html)
*   [Streams](http://nodejs.org/api/streams.html)
*   _[C/C++ Addons](http://nodejs.org/api/addons.html)_

    </td>
    <td>
**Network I/O**

*   [HTTP](http://nodejs.org/api/http.html)
*   [HTTPS](http://nodejs.org/api/https.html)
*   [URL](http://nodejs.org/api/url.html)
*   [Query Strings](http://nodejs.org/api/querystring.html)
*   _[Net](http://nodejs.org/api/net.html)_
*   _[UDP/Datagram](http://nodejs.org/api/dgram.html)_
*   _[DNS](http://nodejs.org/api/dns.html)_

    </td>
    <td>
**File system I/O**

*   [File System](http://nodejs.org/api/fs.html)
*   [Path](http://nodejs.org/api/path.html)

**Process I/O and V8 VM**

*   [Process](http://nodejs.org/api/process.html)
*   [VM](http://nodejs.org/api/vm.html)
*   [Child Processes](http://nodejs.org/api/child_processes.html)
*   _[Cluster](http://nodejs.org/api/cluster.html)_

    </td>
  </tr>
  <tr>
    <td>
**Terminal/console**

*   [REPL](http://nodejs.org/api/repl.html)
*   _[Readline](http://nodejs.org/api/readline.html)_
*   _[TTY](http://nodejs.org/api/tty.html)_
    </td>
    <td>
**Testing &amp; debugging**

*   [Assertion Testing](http://nodejs.org/api/assert.html)
*   [Debugger](http://nodejs.org/api/debugger.html)
*   [Utilities](http://nodejs.org/api/util.html)

    </td>
    <td>
**Misc**

*   _[Crypto](http://nodejs.org/api/crypto.html)_
*   _[TLS/SSL](http://nodejs.org/api/tls.html)_
*   _[String Decoder](http://nodejs.org/api/string_decoder.html)_
*   _[ZLIB](http://nodejs.org/api/zlib.html)_
*   _[OS](http://nodejs.org/api/os.html)_

    </td>
  </tr>
</table>

I’ll go through the parts of the Node API that you’ll use the most when writing web applications. The rest of the API is best looked up from [nodejs.org/api/](http://nodejs.org/api/).

<table>
  <tr>
  <td>
    **Fundamentals**

The current chapter and [Chapter 9](ch9.html).

  </td>
  <td>
    **Network I/O**

HTTP and HTTPS are covered in [Chapter 10](ch10.html).

  </td>

  <td>
    **File system I/O**

The file system module is covered in [Chapter 11](ch11.html).

  </td>
  </tr>

  <tr>
  <td>
    **Process I/O and V8 VM**

Covered in Chapter TODO.

  </td>
  <td>
    **Terminal/console**

REPL is discussed in Chapter TODO.

  </td>
  <td>
    **Testing and debugging**

Coverage TODO.

  </td>

</table>

## %chapter_number%.1 Node.js modules

Let's talk about the module system in Node.

Modules make it possible to include other Javascript files into your applications. In fact, a vast majority of Node’s core functionality is implemented using modules written in Javascript - which means you can read the source code for the core libraries [on Github](https://github.com/joyent/node).

Modules are crucial to building applications in Node, as they allow you to include external libraries, such as database access libraries - and they help in organizing your code into separate parts with limited responsibilities. You should try to identify reusable parts in your own code and turn them into separate modules to reduce the amount of code per file and to make it easier to read and maintain your code.

Using modules is simple: you use the `require()` function, which takes one argument: the name of a core library or a file system path to the module you want to load. You’ve seen this before in the simple messaging application example, where I used `require()` to use several core modules.

To make a module yourself, you need to specify what objects you want to export. The exports object is available in the top level scope in Node for this purpose:

<pre class="prettyprint">
exports.funcname = function() {
  return ‘Hello World’;
};
</pre>

Any properties assigned to the exports object will be accessible from the return value of the require() function:

<pre class="prettyprint">
var hello = require(‘./hello.js’);
console.log(hello.funcname()); // Print “Hello World”
</pre>

You can also use module.exports instead of exports:

<pre class="prettyprint">
function funcname() { return ‘Hello World’; }
module.exports = { funcname: funcname };
</pre>

This alternative syntax makes it possible to assign a single object to exports (such as a class). We’ve previously discussed how you can build classes using prototypal inheritance. By making your classes separate modules, you can easily include them in your application:

<pre class="prettyprint">// in class.js:
var Class = function() { … }
Class.prototype.funcname = function() {...}
module.exports = Class;
</pre>

Then you can include your file using require() and make a new instance of your class:

<pre class="prettyprint">
// in another file:
var Class = require(‘./class.js’);
var object = new Class(); // create new instance
</pre>

### Sharing variables between modules

Note that there is no global context in Node. Each script has it's own context, so including multiple modules does not pollute the current scope. `var foo = 'bar';` in the top level scope of another module will not define `foo` in other modules.

What this means is that the only way to share variables and values between node modules is to include the same module in multiple files. Since modules are cached, you can use a shared module to store common data, such as configuration options:

<pre class="prettyprint">
// in config.js
var config = {
  foo: 'bar'
};
module.exports = config;
</pre>

In a different module:

<pre class="prettyprint">
// in server.js
var config = require('./config.js');
console.log(config.foo);
</pre>

However, Node module has a number of variables which are available by default. These are documented in the API docs: [globals](http://nodejs.org/api/globals.html) and [process](http://nodejs.org/api/process.html).

Some of the more interesting ones are:

<table>
  <tr><td>__filename</td><td>The filename of the code being executed.</td></tr>
  <tr><td>__dirname</td><td>The name of the directory that the currently executing script resides in.</td></tr>
  <tr><td>process</td><td>A object which is associated with the currently running process. In addition to variables, it has methods such as [process.exit](http://nodejs.org/api/process.html#process.exit), [process.cwd](http://nodejs.org/api/process.html#process.cwd) and [process.uptime](http://nodejs.org/api/process.html#process.uptime).</td></tr>
  <tr><td>process.argv.</td><td>An array containing the command line arguments. The first element will be 'node', the second element will be the name of the JavaScript file. The next elements will be any additional command line arguments.</td></tr>
  <tr><td>process.stdin, process.stout, process.stderr.</td><td>Streams which correspond to the standard input, standard output and standard error output for the current process.</td></tr>
  <tr><td>process.env</td><td>An object containing the user environment of the current process.</td></tr>
  <tr><td>[require.main](http://nodejs.org/api/modules.html#accessing_the_main_module)</td><td>When a file is run directly from Node, `require.main` is set to its `module`.</td></tr>
</table>

The code below will print the values for the current script:

<pre class="prettyprint">
console.log('__filename', __filename);
console.log('__dirname', __dirname);
console.log('process.argv', process.argv);
console.log('process.env', process.env);
if(module === require.main) {
  console.log('This is the main module being run.');
}
</pre>

require.main can be used to detect whether the module being currently run is the main module. This is useful when you want to do something else when a module is run standalone. For example, I make my test files runnable via `node filename.js` by including something like this:

<pre class="prettyprint">
// if this module is the script being run, then run the tests:
if (module === require.main) {
  var nodeunit_runner = require('nodeunit-runner');
  nodeunit_runner.run(__filename);
}
</pre>

process.stdin, process.stdout and process.stderr are briefly discussed in the next chapter, where we discuss readable and writable streams.

### Organizing modules

There are [three ways](http://nodejs.org/api/modules.html#loading_from_node_modules_Folders) in which you can require() files:

*   using a relative path: foo = require('./lib/bar.js');
*   using an absolute path: foo = require('/home/foo/lib/bar.js')
*   using a search: foo = require('bar')

The first two are easy to understand. In the third case, Node starts at the current directory, and adds ./node_modules/, and attempts to load the module from that location. If the module is not found, then it moves to the parent directory and performs the same check, until the root of the filesystem is reached.</p

<p>For example, if require('bar') would called in /home/foo/, the following locations would be searched until a match a found:

*   /home/foo/node_modules/bar.js
*   /home/node_modules/bar.js and
*   /node_modules/bar.js

Loading modules in this way is easier than specifying a relative path, since you can move the files without worrying about the paths changing.

### Directories as modules

You can organize your modules into directories, as long as you provide a point of entry for Node.

The easiest way to do this is to create the directory ./node_modules/mymodulename/, and put an index.js file in that directory. The index.js file will be loaded by default.

Alternatively, you can put a package.json file in the mymodulename folder, specifying the name and main file of the module:

<pre class="prettyprint">
{
  "name": "mymodulename",
  "main": "./lib/foo.js"
}
</pre>

This would cause the file ./node_modules/mymodulename/lib/foo.js to be returned from `require('mymodulename')`.

Generally, you want to keep a single ./node_modules folder in the base directory of your app. You can install new modules by adding files or directories to ./node_modules. The best way to manage these modules is to use npm, which is covered briefly in the next section.

## %chapter_number%.2 npm

[npm](http://npmjs.org/) is the package manager used to distribute Node modules. I won't cover it in detail here, because [the Internet does that already](http://npmjs.org/doc/).

npm is awesome, and you should use it. Below are a couple of use cases.

### %chapter_number%.2.1 Installing packages

The most common use case for npm is to use it for installing modules from other people:

<pre>
npm search packagename
</pre>

<pre>
npm view packagename
</pre>

<pre>
npm install packagename
</pre>

<pre>
npm outdated
</pre>

<pre>
npm update packagename
</pre>

Packages are installed under ./node_modules/ in the current directory.

### %chapter_number%.2.2 Specifying and installing dependencies for your own app

npm makes installing your application on a new machine easy, because you can specify what modules you want to have in your application by adding a package.json file in the root of your application.

Here is a minimal package.json:

<pre class="prettyprint">
{ "name": "modulename",
  "description": "Foo for bar",
  "version": "0.0.1",
  "repository": {
    "type": "git",
    "url":  "git://github.com/mixu/modulename.git" },
  "dependencies": {
    "underscore": "1.1.x",
    "foo": "git+ssh://git@github.com:mixu/foo.git#0.4.1",
    "bar": "git+ssh://git@github.com:mixu/bar.git#master"
  },
  "private": true
}
</pre>

This makes getting the right versions of the dependencies of your application a lot easier.  To install the dependencies specified for your application, run:

<pre>
npm install
</pre>

### %chapter_number%.2.3 Loading dependencies from a remote git repository

One of my favorite features is the ability to use git+ssh URLs to fetch remote git repositories. By specifying a URL like git+ssh://github.com:mixu/nwm.git#master, you can install a dependency directly from a remote git repository. The part after the hash refers to a tag or branch on the repository.

To list the installed dependencies, use:

<pre>
npm ls
</pre>

### %chapter_number%.2.4 Specifying custom start, stop and test scripts

You can also use the "scripts" member of package.json to specify actions to be taken during various stages:

<pre class="prettyprint">
{ "scripts" :
  { "preinstall" : "./configure",
    "install" : "make &amp;&amp; make install",
    "test" : "make test",
    "start": "scripts/start.js",
    "stop": "scripts/stop.js"
  }
}
</pre>

In the example above, we specify what should happen before install and during install. We also define what happens when npm test, npm start and npm stop are called.
