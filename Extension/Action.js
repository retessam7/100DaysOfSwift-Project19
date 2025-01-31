//
//  Action.js
//  Project19
//
//  Created by Aleksei Ivanov on 31/1/25.
//

var Action = function() {};

Action.prototype = {
    
    // functions: run() called before your extension is run.
run: function(parameters) {
        // "tell iOS the JavaScript has finished preprocessing, and give this data dictionary to the extension."
    parameters.completionFunction({"URL": document.URL, "title": document.title });
},

// functions: finalize(). is called after.
finalize: function(parameters) {
    var customJavaScript = parameters["customJavaScript"];
    // function, which executes any code it finds.
    eval(customJavaScript);
}
    
};

var ExtensionPreprocessingJS = new Action
