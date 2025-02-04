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
    @IBOutlet var script: UITextView!
    
    // store these two because they are being transmitted by Safari
    var pageTitle = ""
    var pageURL = ""

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
                    self?.pageTitle = javaScriptValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptValues["URL"] as? String ?? ""
                    
                    // self уже захвачен слабо в предыдущем уровне, и повторно писать [weak self] нет смысла
                    DispatchQueue.main.async {
                        // change the UI on the main thread
                        self?.title = self?.pageTitle
                        
                        // download saved javaScript
                        // .host — это свойство URL, которое возвращает доменное имя сайта.
                        if let host = URL(string: self?.pageURL ?? "")?.host {
                            let defaults = UserDefaults.standard
                            self?.script.text = defaults.string(forKey: host) ?? ""
                        }
                    }
                }
            }
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        // ask to be told when the keyboard state changes by using a new class
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Examples", style: .plain, target: self, action: #selector(exampleScripts))
        
    }
    
    // just the reverse of what we are doing inside viewDidLoad().
    @IBAction func done() {
        guard let host = URL(string: pageURL)?.host else { return }
        
        let defaults = UserDefaults.standard
        defaults.set(script.text, forKey: host)
        
        // on our extension context will cause the extension to be closed, returning back to the parent app
        // it will pass back to the parent app any items that we specify, which in the current code is the same items that were sent in
        // object that will host our items
        let item = NSExtensionItem()
        // dict containing the key "customJavaScript" and the value of our script
        let argument: NSDictionary = ["customJavaScript": script.text]
        // Put that dictionary into another dictionary with the key
        let webDictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument]
        // Wrap the big dict inside an NSItemProvider object with the type identifier kUTTypePropertyList.
        let customJavaScript = NSItemProvider(item: webDictionary, typeIdentifier: kUTTypePropertyList as String)
        // Place that NSItemProvider into our NSExtensionItem as its attachments
        item.attachments = [customJavaScript]
        
        // returning our NSExtensionItem.
        extensionContext?.completeRequest(returningItems: [item])
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        // the dictionary will contain a key telling us the frame of the keyboard after it has finished animating
        // Obj-C arrays and dictionaries couldn't contain structures like CGRect, special class called NSValue that as a wrapper around structures so they could be put into dictionaries and arrays
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        // we need to convert the rectangle to our view's co-ordinates because rotation isn't factored into the frame
        // (if the user is in landscape we'll have the width and height flipped)
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        // indent the edges of our text view so that it appears to occupy less space even though its constraints are still edge to edge in the view.
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        } else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        // make the text view scroll so that the text entry cursor is visible
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange)
    }
    
    @objc func exampleScripts() {
        let ac = UIAlertController(title: "Script examples", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "alert(document.title);", style: .default) { [weak self] _ in
            self?.script.text = "alert(document.title);"
            self?.done()
        })

        present(ac, animated: true)
    }
    
    
}

// user has written their code in our extension, tapped Done, and it gets executed in Safari using eval(). If you want to give it a try, enter the code alert(document.title); into the extension

// Apple's default action extension is configured for images, not for web page content.

// This code takes a number of shortcuts that Apple's own code doesn't, which is why it's significantly shorter. Once you've gotten to grips with this basic extension, I do recommend you go back and look at Apple's template code to see how it loops through all the items and providers to find the first image it can.
