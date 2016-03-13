//
//  TripPhotosController.swift
//  TravelDiary
//
//  Created by Philippe Wanner on 09/03/16.
//  Copyright © 2016 PTPA. All rights reserved.
//

import UIKit
import CoreData

class TPViewController: UIViewController, UITableViewDelegate, UICollectionViewDelegate{
    
    var model: [[Photo]] = [[]]
    var storedOffsets = [Int: CGFloat]()
    
    var whichCollecitonView = 0
    
    @IBOutlet weak var tableView: UITableView!
    
    var photosModelHelper = PhotosModelHelper()
    
    // Core Data managed context
    var managedContext : NSManagedObjectContext?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("wiewDidLoad")
        // setup Core Data context
        photosModelHelper.coreDataSetup()
        // load photos in memory
        model = photosModelHelper.getPhotosPerTrip()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //Number of row in the collection view cell.
        return 1
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return model[section][0].trip!.title
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        //Number of row in the table view cell.
        NSLog("number of trips: %d", model.count)
        return model.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("tripCell", forIndexPath: indexPath)
        
        return cell
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        
        guard let tableViewCell = cell as? TPTableViewCell else { return }

        tableViewCell.data = model[indexPath.section]
        tableViewCell.collectionView.dataSource = tableViewCell
        tableViewCell.collectionView.delegate = self
        tableViewCell.collectionView.reloadData()
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        //When someone clicks on the cell
        NSLog("click on image in collection trip view, indexPath=%d", indexPath.item)
//        self.performSegueWithIdentifier("showImageFromTripView", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "showImageFromTripView" {
            NSLog("showImageFromTripView, indexPath=%d", (sender?.indexPath.item)!)
            
            if sender?.collectionView == nil {
                NSLog("sender collection view nilllll")
            }
            
            //Get the number of items selected in the collection view
            let indexPaths = sender!.collectionView!.indexPathsForSelectedItems()!
            //Get the first items of those
            let indexPath = indexPaths[0] as NSIndexPath
            
            //Cast the destination view controller to ImageViewController
            let controller = segue.destinationViewController as! ImageViewController

            //Set the image in the ImageViewController to the selected item in the collection view
            controller.image = (sender as! TPTableViewCell).data[indexPath.row].image!
            
            //Set the title of this image depending of the selected item in the collection view
//            controller.title = sender.collectionViewDataSource.data[indexPath.row].title
        }
    }
}