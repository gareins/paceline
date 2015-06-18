var data = require("sdk/self").data;
// Construct a panel, loading its content from the "text-entry.html"
// file in the "data" directory, and loading the "get-text.js" script
// into it.
var text_entry = require("sdk/panel").Panel({
  contentURL: data.url("text-entry.html"),
  contentScriptFile: data.url("get-text.js")
});

// Create a button
require("sdk/ui/button/action").ActionButton({
  id: "show-panel",
  label: "Show Panel",
  icon: {
    "16": "./icon-16.png",
    "32": "./icon-32.png",
    "64": "./icon-64.png"
  },
  onClick: handleClick
});

// Show the panel when the user clicks the button.
function handleClick(state) {
  text_entry.show();
}

// When the panel is displayed it generated an event called
// "show": we will listen for that event and when it happens,
// send our own "show" event to the panel's script, so the
// script can prepare the panel for display.
text_entry.on("show", function() {
  text_entry.port.emit("show");
});

// Listen for messages called "text-entered" coming from
// the content script. The message payload is the text the user entered.
// In this implementation we'll just log the text to the console.
text_entry.port.on("text-entered", function (text) {
  console.log(text);
  text_entry.hide();
});


// on ready...
// var ss = require("sdk/simple-storage");

var data    = require("sdk/self").data;
var tabs    = require('sdk/tabs');
var pageMod = require("sdk/page-mod");

pageMod.PageMod({
  include: "*",
  exclude: ["*.js", "*.css"], //why is this not working?
  contentScriptFile: [self.data.url("jquery-2.1.4.min.js"), self.data.url("input-get.js")],
  onAttach: function(worker) {
    worker.port.emit("getInput", tabs.activeTab.url);

    worker.port.on("gotInput", function(returned) {
      console.log(returned);
    });
  }
});

