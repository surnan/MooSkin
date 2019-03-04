//
//  NoteDetailsViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData



class NoteDetailsViewController: UIViewController {
    /// A text view that displays a note's text
    @IBOutlet weak var textView: UITextView!
    
    /// The note being displayed and edited
    var note: Note!
    var dataController: DataController!
    
    
    var saveObserverToken: Any?     //observer from the Merging in DataController.configureContext
    
    
    
    /// A closure that is run when the user asks to delete the current note
    var onDelete: (() -> Void)?
    
    /// A date formatter for the view controller's title text
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    var keyboardToolbar: UIToolbar?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let creationDate = note.creationDate {
            navigationItem.title = dateFormatter.string(from: creationDate)
        }
        textView.attributedText = note.attributedText
        
        // keyboard toolbar configuration
        configureToolbarItems()
        configureTextViewInputAccessoryView()
        addSaveNotificationObserver() //from Extension
    }
    
    
    
    deinit {
        removeSaveNotificationObserver()
    }
    
    
    @IBAction func deleteNote(sender: Any) {
        print("Triggered")
        presentDeleteNotebookAlert()
    }
}

// -----------------------------------------------------------------------------
// MARK: - Editing

extension NoteDetailsViewController {
    func presentDeleteNotebookAlert() {
        let alert = UIAlertController(title: "Delete Note", message: "Do you want to delete this note?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: deleteHandler))
        present(alert, animated: true, completion: nil)
    }
    
    func deleteHandler(alertAction: UIAlertAction) {
        onDelete?()
    }
}

// -----------------------------------------------------------------------------
// MARK: - UITextViewDelegate

extension NoteDetailsViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        note.attributedText = textView.attributedText
//        note.text = textView.text
        // try? note.managedObjectContext?.save() //Also works because notes context = view context
        //This could bring drama if we have multiple contexts floating around
        try? dataController.viewContext.save()
    }
}



extension NoteDetailsViewController {
    
    // 1
    func configureToolbarItems() {
        toolbarItems = makeToolbarItems()
        navigationController?.setToolbarHidden(false, animated: false)  //Don't see any functionality
    }
    
    // 2
    func configureTextViewInputAccessoryView() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        toolbar.items = makeToolbarItems()
        textView.inputAccessoryView = toolbar   // Showing custom toolbar above keyboard that we've created
    }
    
    
    
    // called by 1 & 2
    func makeToolbarItems() -> [UIBarButtonItem] {
        let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped(sender:)))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let bold = UIBarButtonItem(image: #imageLiteral(resourceName: "toolbar-bold"), style: .plain, target: self, action: #selector(boldTapped(sender:)))
        let red = UIBarButtonItem(image: #imageLiteral(resourceName: "toolbar-underline"), style: .plain, target: self, action: #selector(redTapped(sender:)))
        let cow = UIBarButtonItem(image: #imageLiteral(resourceName: "toolbar-cow"), style: .plain, target: self, action: #selector(cowTapped(sender:)))
        
        return [trash, space, bold, space, red, space, cow, space]
    }
    
    // called by 2
    @IBAction func deleteTapped(sender: Any) {
        showDeleteAlert()
    }
    
    @IBAction func redTapped(sender: Any) {
        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        let attributes: [NSAttributedStringKey: Any] = [
            .foregroundColor: UIColor.red,
            .underlineStyle: 1,
            .underlineColor: UIColor.red
        ]
        newText.addAttributes(attributes, range: textView.selectedRange)
        
        let selectedTextRange = textView.selectedTextRange
        
        textView.attributedText = newText
        textView.selectedTextRange = selectedTextRange
        note.attributedText = textView.attributedText
        try? dataController.viewContext.save()
    }
    
    @IBAction func boldTapped(sender: Any) {
        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        newText.addAttribute(.font, value: UIFont(name: "OpenSans-Bold", size: 22)!, range: textView.selectedRange)
        
        let selectedTextRange = textView.selectedTextRange
        
        textView.attributedText = newText
        textView.selectedTextRange = selectedTextRange
        note.attributedText = textView.attributedText
        try? dataController.viewContext.save()
    }
    
    @IBAction func cowTapped(sender: Any) {
        
        let backgroundContext: NSManagedObjectContext! = dataController.backgroundContext

        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        let selectedRange = textView.selectedRange
        let selectedText = textView.attributedText.attributedSubstring(from: selectedRange)
        
        
        //Can't use note that's associated with 'viewContext' right before try? dataController.viewContext.save()
        //Instead of fetching Note again on backgroundContext and then using predicate to make sure to get the same exact object
        //Simpler, easier: Every managed object has an identifier that's consistent across contexts
        //  //and it can be accesses through objectID property
        let noteID = note.objectID
        
        backgroundContext.perform {
            let backgroundNote = backgroundContext.object(with: noteID) as! Note
            let cowText = Pathifier.makeMutableAttributedString(for: selectedText, withFont: UIFont(name: "AvenirNext-Heavy", size: 56)!, withPatternImage: #imageLiteral(resourceName: "texture-cow"))
            newText.replaceCharacters(in: selectedRange, with: cowText)
//            sleep(5)
//            backgroundNote.attributedText = textView.attributedText   //associated with 'viewContext'
            backgroundNote.attributedText = newText
            try? backgroundContext.save()
        }
    }
    
    // called by 2
    private func showDeleteAlert() {
        let alert = UIAlertController(title: "Delete Note?", message: "Are you sure you want to delete the current note?", preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.onDelete?()
        }
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true, completion: nil)
    }
}

extension NoteDetailsViewController {
    func addSaveNotificationObserver(){
        removeSaveNotificationObserver()
        saveObserverToken = NotificationCenter.default.addObserver(forName: .NSManagedObjectContextObjectsDidChange, object: dataController.viewContext, queue: nil, using: handleSaveNotification(notification: ))
        
    }
    
    func removeSaveNotificationObserver(){
        if let token = saveObserverToken {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    func handleSaveNotification(notification: Notification){
        DispatchQueue.main.async {
            self.textView.attributedText = self.note.attributedText
        }
    }
}
