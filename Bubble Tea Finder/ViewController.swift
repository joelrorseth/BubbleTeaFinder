//
//  ViewController.swift
//  Bubble Tea Finder
//
//  Created by Pietro Rea on 8/24/14.
//  Copyright (c) 2014 Pietro Rea. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, FilterViewControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var coreDataStack: CoreDataStack!
    var fetchRequest: NSFetchRequest!
    var asyncFetchRequest: NSAsynchronousFetchRequest!
    var venues: [Venue]! = []
    
    //===============================================================================
    //===============================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // BATCH UPDATES ============================================================
        let batchUpdate = NSBatchUpdateRequest(entityName: "Venue")
        batchUpdate.propertiesToUpdate = ["favorite" : NSNumber(bool: true)] // Update all records of favorite to true
        batchUpdate.affectedStores = coreDataStack.psc.persistentStores
        batchUpdate.resultType = .UpdatedObjectsCountResultType
        
        var batchError: NSError?
        let batchResult = coreDataStack.context.executeRequest(batchUpdate, error: &batchError) as! NSBatchUpdateResult?
        
        if let result = batchResult {
            println("Records updated: \(result.result)")
        } else {
            println("Could not update \(batchError), \(batchError!.userInfo)")
        }
        
        
        // Cant declare like this;  request becomes immutable
        //fetchRequest = coreDataStack.model.fetchRequestTemplateForName("FetchRequest")
        fetchRequest = NSFetchRequest(entityName: "Venue")
        
        
        // ASYNCHRONOUS FETCHING ====================================================
        // Create the completion handler, use finalResult property for access
        asyncFetchRequest = NSAsynchronousFetchRequest(fetchRequest: fetchRequest) {
            [unowned self] (result: NSAsynchronousFetchResult!) -> Void in
            self.venues = result.finalResult as! [Venue]
            self.tableView.reloadData()
        }
        
        // Call executeRequest instead on coreDataStack's context
        var error: NSError?
        let results = coreDataStack.context.executeRequest(asyncFetchRequest, error: &error)
        
        if let persistentStoreResults = results {
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    //===============================================================================
    //===============================================================================
    func tableView(tableView: UITableView?, numberOfRowsInSection section: Int) -> Int {
        return venues.count
    }
    
    //===============================================================================
    //===============================================================================
    func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        var cell = tableView.dequeueReusableCellWithIdentifier("VenueCell") as! UITableViewCell
        
        let venue = venues[indexPath.row]
        cell.textLabel!.text = venue.name
        cell.detailTextLabel!.text = venue.priceInfo.priceCategory
        
        return cell
    }
    
    //===============================================================================
    //===============================================================================
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "toFilterViewController" {
            
            let navController = segue.destinationViewController as! UINavigationController
            let filterVC = navController.topViewController as! FilterViewController
            
            filterVC.coreDataStack = coreDataStack
            filterVC.delegate = self
        }
    }
    
    //===============================================================================
    //===============================================================================
    @IBAction func unwindToVenuListViewController(segue: UIStoryboardSegue) {
        
    }
    
    //===============================================================================
    //===============================================================================
    func fetchAndReload() {
        var error: NSError?
        let results = coreDataStack.context.executeFetchRequest(fetchRequest, error: &error) as! [Venue]?
        
        if let fetchedResults = results {
            venues = fetchedResults
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        
        tableView.reloadData()
    }
    
    //===============================================================================
    // This delegate method fires everytime user selects new sort combination
    //===============================================================================
    func filterViewController(filter: FilterViewController, didSelectPredicate predicate: NSPredicate?, sortDescriptor: NSSortDescriptor?) {
        fetchRequest.predicate = nil
        fetchRequest.sortDescriptors = nil
        
        if let fetchPredicate = predicate {
            fetchRequest.predicate = fetchPredicate
            
        }
        
        if let sr = sortDescriptor {
            fetchRequest.sortDescriptors = [sr]
        }
        
        fetchAndReload()
    }
}

