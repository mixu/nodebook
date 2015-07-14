var BookGen = require('./bookgen/generate.js');

BookGen.generate({

  header: __dirname + '/layouts/header.hdbs',
  footer: __dirname + '/layouts/footer.html',
//  footer: __dirname + '/layouts/footer_draft.html',

  header_single: __dirname + '/layouts/header_single.hdbs',
  footer_single: __dirname + '/layouts/footer_single.html',

  input: __dirname + '/content/',
  output: __dirname + '/output/',

  defaults: {
    title: 'Mixu\'s Node book'
  },

  order: [
    'index', 'ch1', 'ch2', 'ch3', 'ch4', 'ch5', 'ch6', 'ch7', 'ch8', 'ch9', 'ch10', 'ch11', 'ch13', 'thankyou'
  ],

  titles: {
    ch1: '1. Introduction',
    ch2: '2. What is Node.js?',
    ch3: '3. Simple messaging application',
    ch4: '4. V8 and Javascript gotchas',
    ch5: '5. Arrays, Objects, Functions and JSON',
    ch6: '6. Objects and classes by example',
    ch7: '7. Control flow in Node.js',
    ch8: '8. Node: Modules and npm',
    ch9: '9. Fundamentals: Timers, EventEmitters, Streams and Buffers',
    ch10: '10. Node: HTTP, HTTPS',
    ch11: '11. File system',
    ch13: '13. Comet and Socket.io',
    thankyou: 'Thank you'
  }
});
