//
//  ActionViewController.swift
//  Extension
//
//  Created by Aleksei Ivanov on 31/1/25.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // extensionContext lets us control how it interacts with the parent app. inputItems array of data the parent app is sending to our extension to use.
        // We care about this first item in this pr, it might not exist, so we conditionally typecast using if let and as?.
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem {
            // input item contains an array of attachments, which are given to us wrapped up as an NSItemProvider
            if let itemProvider = inputItem.attachments?.first {
                // ask the item provider to actually provide us with its item, it uses a closure so this code executes asynchronously. The method will carry on executing while the item provider is busy loading and sending us its data.
                // accept two parameters: the dictionary that was given to us by the item provider, and any error that occurred.
                itemProvider.loadItem(forTypeIdentifier: kUTTypePropertyList as String) { [weak self] (dict, error) in
                    guard let itemDictionary = dict as? NSDictionary else { return }
                    //  data sent from JavaScript, and stored in a special key called NSExten...ultsKey
                    // typecast javaScriptValues as an NSDictionary again so we can pull out values using keys
                    guard let javaScriptValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    print(javaScriptValues)
                }
            }
        }
    }

    @IBAction func done() {
        // Return any edited content to the host app.
        // This template doesn't do anything, so we just echo the passed in items.
        self.extensionContext!.completeRequest(returningItems: self.extensionContext!.inputItems, completionHandler: nil)
    }

}

// Apple's default action extension is configured for images, not for web page content.

// This code takes a number of shortcuts that Apple's own code doesn't, which is why it's significantly shorter. Once you've gotten to grips with this basic extension, I do recommend you go back and look at Apple's template code to see how it loops through all the items and providers to find the first image it can.
