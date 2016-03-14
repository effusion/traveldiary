//
//  TripSearchController.swift
//  TravelDiary
//
//  Created by Tobias Rindlisbacher on 28/02/16.
//  Copyright © 2016 PTPA. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapSearchController: UITableViewController {

    var delegate: MapSearchDelegate?

    var fetchedResultsController: NSFetchedResultsController!
    var fetchRequest: NSFetchRequest!

    private struct Constants {
        static let CacheName = "mapSearchCache"
        static let ReuseIdentifierCell = "reuseIdentifierCell"
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeFetchedResultsController()
    }
    
    override func didReceiveMemoryWarning() {
        NSFetchedResultsController.deleteCacheWithName(Constants.CacheName)
    }
    
    func initializeFetchedResultsController() {
        
        fetchRequest = NSFetchRequest(entityName: Location.entityName())
        fetchRequest.relationshipKeyPathsForPrefetching = ["inActivity", "inActivity.location"]

        let tripSort = NSSortDescriptor(key: "inActivity.trip.title", ascending: true)
        let nameSort = NSSortDescriptor(key: "name", ascending: true)
        fetchRequest.sortDescriptors = [tripSort, nameSort]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: "inActivity.trip.title", cacheName: nil)
        
        self.fetchedResultsController.delegate = self
    }

    // MARK: TableView
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.ReuseIdentifierCell)!
        configureCell(cell, indexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
        cell.textLabel?.text = location.name
        cell.detailTextLabel?.text = location.address
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections!.count
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        return 0
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.name
        }
        return nil
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let location = fetchedResultsController.objectAtIndexPath(indexPath) as! Location
        delegate?.tripFound(location.inActivity!.trip!)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: - UISearchResultsUpdating
extension MapSearchController: UISearchResultsUpdating {

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text?.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet()) else {
            return
        }
        
        fetchRequest.predicate = NSPredicate(format:"longitude != nil AND latitude != nil AND name CONTAINS[c] %@", searchText)
        print(searchText)
        
        do {
            try fetchedResultsController.performFetch()
        } catch let error as NSError {
            print("Failed to load map data \(error.localizedDescription)")
        }
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension MapSearchController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
        case .Insert:
            self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
        case .Move:
            break
        case .Update:
            break
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject object: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Update:
            self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        case .Move:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
        case .Delete:
            self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
}
