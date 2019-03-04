//
//  NotesListViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NotesListViewController: UIViewController, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    
    var notebook: Notebook!
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Note>!
    
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let predicate = NSPredicate(format: "notebook == %@", notebook)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "notes")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch could not be performed because: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()
        navigationItem.title = notebook.name
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        
        ////////////////////////////////////////////////////////////////////////////////////////////////////////
        NSFetchedResultsController<Notebook>.deleteCache(withName: "notes")
        fetchedResultsController = nil  //Must be reset after leaving view.  Notifications
        ////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    
    }
    
    
    @IBAction func addTapped(sender: Any) {
        addNote()
    }
    
    
    func addNote() {
        let noteToAdd = Note(context: dataController.viewContext)
        noteToAdd.attributedText = NSAttributedString(string: "\(notebook.name ?? "No NoteBook Found") .... New Note Create")
        //noteToAdd.text = "\(notebook.name ?? "No NoteBook Found") .... New Note Create"
        noteToAdd.creationDate = Date()
        noteToAdd.notebook = notebook
        try? dataController.viewContext.save()
    }
    
    
    func deleteNote(at indexPath: IndexPath) {
        let noteToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(noteToDelete)
        try? dataController.viewContext.save()
    }
    
    func updateEditButtonState() {
        if let sections = fetchedResultsController.sections {
            navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1 //If first entry is NIL, then it's not an INT and can't be returned
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aNote = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: NoteCell.defaultReuseIdentifier, for: indexPath) as! NoteCell
        //        cell.textPreviewLabel.text = aNote.text
        cell.textPreviewLabel.attributedText = aNote.attributedText
        if let creationDate = aNote.creationDate {
            cell.dateLabel.text = dateFormatter.string(from: creationDate)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteNote(at: indexPath)
        default: () // Unsupported
        }
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? NoteDetailsViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.note = fetchedResultsController.object(at: indexPath)
                vc.dataController = dataController
                vc.onDelete = { [weak self] in
                    if let indexPath = self?.tableView.indexPathForSelectedRow {
                        self?.deleteNote(at: indexPath)
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}

extension NotesListViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates() //start tableViewAnimations vs. tableView.reload()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()  //end tableViewAnimations vs. tableView.reload()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        default:
            break
        }
    }
}
