//
//  CurrentTripController.swift
//  TravelDiary
//
//  Created by Andreas Heubeck on 08/02/16.
//  Copyright © 2016 PTPA. All rights reserved.
//

import UIKit
import CoreData

class CurrentTripController: UITableViewController{
    
    private struct Constants{
        static let showActivitySeque = "showActivitySegue"
        static let editActivitySegue = "editActivitySegue"
        static let addActivitySegue = "addActivitySegue"
        static let reuseCellIdentifier = "reuseCell"
        static let ActivityTableViewCell = "ActivityTableViewCell"
        static let SearchBarPlaceholder = "Search for trips"
    }
    
    private let dateFormatter = NSDateFormatter()
    // Controller to load data
    private var fetchedResultsController: NSFetchedResultsController!
    private let searchController = UISearchController(searchResultsController: nil)
    // Currently selected trip
    var currentTrip : Trip? {
        didSet {
            navigationItem.title = currentTrip?.title
        }
    }
    private var activitiesAreEditable = false;
    
    private var filteredActivities:[Activity]? = []
    
    private func initializeFetchedResultsController(){
        // Initialize Fetch Request
        let fetchRequest = NSFetchRequest(entityName: Activity.entityName())
        fetchRequest.predicate = NSPredicate(format: "trip == %@", currentTrip!)
        
        // Add Sort Descriptors
        let sortDescriptor = NSSortDescriptor(key: "date", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Initialize Fetched Results Controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        // Do any additional setup after loading the view, typically from a nib.
        let nib = UINib(nibName: Constants.ActivityTableViewCell, bundle: nil)
        tableView.registerNib(nib, forCellReuseIdentifier: Constants.reuseCellIdentifier)
        tableView.separatorColor = UIColor.clearColor()
        dateFormatter.locale = NSLocale.currentLocale()
        dateFormatter.dateStyle = NSDateFormatterStyle.FullStyle
        
        initializeFetchedResultsController()
        instantiateSearchBar()
        
        tableView.allowsSelectionDuringEditing = true
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let fetchError = error as NSError
            print("\(fetchError), \(fetchError.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var numberOfObjects: Int = 0
        if self.isSearchBarActiveAndNotEmpty() {
            numberOfObjects = self.filteredActivities!.count
        }
        else{
            if let sections = fetchedResultsController.sections {
                let currentSection = sections[section]
                numberOfObjects = currentSection.numberOfObjects
            }
        }
        return numberOfObjects
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell: ActivityCell = self.tableView.dequeueReusableCellWithIdentifier(Constants.reuseCellIdentifier) as! ActivityCell
        var actitvity: Activity?
        if self.isSearchBarActiveAndNotEmpty(){
            actitvity = self.filteredActivities![indexPath.row]
        }else {
            actitvity = fetchedResultsController.objectAtIndexPath(indexPath) as? Activity

        }
        //cell.activityDescription.text = actitvity!.descr
        cell.activityDate.text = dateFormatter.stringFromDate((actitvity!.date)!)
        cell.activityTitle.text = actitvity!.title
        cell.activityLocation.text = actitvity?.location?.name
        let photos = actitvity?.photos
        if photos?.count > 0{
            let temp = (photos?.allObjects)! as NSArray
            let firstPhoto = temp[0] as! Photo
            cell.activityImage.image = firstPhoto.thumbnailBlob?.thumbnail
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Perform Segue
        if self.activitiesAreEditable {
            performSegueWithIdentifier(Constants.editActivitySegue, sender: self)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else {
            performSegueWithIdentifier(Constants.showActivitySeque, sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.editActivitySegue {
            let navController = segue.destinationViewController as! UINavigationController
            let activityDetailController = navController.topViewController as!ActivityDetailController
            if activitiesAreEditable {
                activityDetailController.selectedActivity = fetchedResultsController.objectAtIndexPath(tableView.indexPathForSelectedRow!) as? Activity
                activityDetailController.addMode = false
            }else{
                activityDetailController.addMode = true
            }
        }
        if segue.identifier == Constants.showActivitySeque{
            let viewActivityController = segue.destinationViewController as! ViewActivityController
            let activity = fetchedResultsController.objectAtIndexPath(tableView.indexPathForSelectedRow!) as? Activity
            viewActivityController.selectedActivity = activity
        }
    }
    
    /*!
        Override to support editing the table view.
    */
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let actitvity = fetchedResultsController.objectAtIndexPath(indexPath) as! Activity
            currentTrip?.removeActivity(actitvity)
            saveContext()
        }
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        NSLog("setEditing(editing: \(editing), animated: \(animated))")
        activitiesAreEditable = editing
        super.setEditing(editing, animated: animated)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    /*!
        segue which is called when the cancel button on the ActivityDetailContoller is called
    */
    @IBAction func unwindSegueAddActivity(segue:UIStoryboardSegue) {
        if let detailController = segue.sourceViewController as? ActivityDetailController{
            if detailController.addMode{
                let activityToDelete = detailController.selectedActivity
                let photosToDelete = activityToDelete?.photos
                for photo in photosToDelete!{
                    let temp = photo as! Photo
                    self.managedObjectContext.deleteObject(temp)
                }
                self.managedObjectContext.deleteObject(activityToDelete!)
                self.saveContext()
            }
        }
    }
    
    /*!
        segue which is called when the save button on the ActivityDetailContoller is pressed
    */
    @IBAction func unwindSequeSaveActiviy(segue: UIStoryboardSegue){
        if let detailController = segue.sourceViewController as? ActivityDetailController {
            let activityToSave = detailController.selectedActivity
            let photos = activityToSave?.photos
            for photo in photos!{
                let temp = photo as! Photo
                temp.title = activityToSave?.title
            }
            currentTrip?.addActitiesObject(activityToSave!)
            saveContext()
        }
    }
    
    /*!
        Dismiss the keyboard when pressing return
    */
    @IBAction func textFieldDoneEditing(sender: UITextField) {
        sender.resignFirstResponder()}
    
    private func instantiateSearchBar(){
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self
        definesPresentationContext = true
        
        let searchBar = searchController.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = Constants.SearchBarPlaceholder
        tableView.tableHeaderView = searchBar
        let searchBarHeight = searchBar.frame.size.height
        tableView.contentOffset = CGPoint(x: 0, y: searchBarHeight)
    }
    
    private func filterContentForSearchText(searchText: String) {
        let activities:[Activity] = fetchedResultsController.fetchedObjects as! [Activity]
        self.filteredActivities = activities.filter { activity in
            if let title = activity.title {
                return title.lowercaseString.containsString(searchText.lowercaseString)
            }else {
                return false
            }
        }
        tableView.reloadData()
    }
    
    private func isSearchBarActiveAndNotEmpty() -> Bool{
        if searchController.active && searchController.searchBar.text != "" {
            NSLog("search bar is active and not empty")
            return true
        }else{
            return false
        }
    }
}

//MARK: - NSFetchedResultsControllerDelegate
extension CurrentTripController: NSFetchedResultsControllerDelegate{
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
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

// MARK: - UISearchBarDelegate
extension CurrentTripController: UISearchBarDelegate {
    func searchBar(searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        self.filterContentForSearchText(searchBar.text!)
    }
}

// MARK: - UISearchResultsUpdating
extension CurrentTripController : UISearchResultsUpdating {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        self.filterContentForSearchText(searchController.searchBar.text!)
    }
}
