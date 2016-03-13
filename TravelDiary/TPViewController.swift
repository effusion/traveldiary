//
//  TripPhotosController.swift
//  TravelDiary
//
//  Created by Philippe Wanner on 09/03/16.
//  Copyright © 2016 PTPA. All rights reserved.
//

import UIKit
import CoreData

class TPViewController: UIViewController {
    
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
        tableViewCell.collectionView.delegate = tableViewCell
        tableViewCell.collectionView.reloadData()
    }
}
