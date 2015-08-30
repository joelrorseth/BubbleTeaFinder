//
//  FilterViewController.swift
//  Bubble Tea Finder
//
//  Created by Pietro Rea on 8/27/14.
//  Copyright (c) 2014 Pietro Rea. All rights reserved.
//

import UIKit
import CoreData

protocol FilterViewControllerDelegate: class {
    func filterViewController(filter: FilterViewController, didSelectPredicate predicate: NSPredicate?, sortDescriptor: NSSortDescriptor?)
}

class FilterViewController: UITableViewController {
    
    // MARK: - @IBOutlets and properties
    //===============================================================================
    //===============================================================================
    
    @IBOutlet weak var firstPriceCategoryLabel: UILabel!
    @IBOutlet weak var secondPriceCategoryLabel: UILabel!
    @IBOutlet weak var thirdPriceCategoryLabel: UILabel!
    @IBOutlet weak var numDealsLabel: UILabel!
    
    //Price section
    @IBOutlet weak var cheapVenueCell: UITableViewCell!
    @IBOutlet weak var moderateVenueCell: UITableViewCell!
    @IBOutlet weak var expensiveVenueCell: UITableViewCell!
    
    //Most popular section
    @IBOutlet weak var offeringDealCell: UITableViewCell!
    @IBOutlet weak var walkingDistanceCell: UITableViewCell!
    @IBOutlet weak var userTipsCell: UITableViewCell!
    
    //Sort section
    @IBOutlet weak var nameAZSortCell: UITableViewCell!
    @IBOutlet weak var nameZASortCell: UITableViewCell!
    @IBOutlet weak var distanceSortCell: UITableViewCell!
    @IBOutlet weak var priceSortCell: UITableViewCell!
    
    var coreDataStack: CoreDataStack!
    weak var delegate: FilterViewControllerDelegate?
    
    var selectedSortDescriptor: NSSortDescriptor?
    var selectedPredicate: NSPredicate?
    
    lazy var cheapVenuePredicate: NSPredicate = {
        var predicate = NSPredicate(format: "priceInfo.priceCategory == %@", "$")
        return predicate
    }()
    
    lazy var moderateVenuePredicate: NSPredicate = {
        var predicate = NSPredicate(format: "priceInfo.priceCategory == %@", "$$")
        return predicate
    }()
    
    lazy var expensiveVenuePredicate: NSPredicate = {
        var predicate = NSPredicate(format: "priceInfo.priceCategory == %@", "$$$")
        return predicate
    }()
    
    lazy var offeringDealPredicate: NSPredicate = {
        var pr = NSPredicate(format: "specialCount > 0")
        return pr
    }()
    
    lazy var walkingDistancePredicate: NSPredicate = {
        var pr = NSPredicate(format: "location.distance < 500")
        return pr
    }()
    
    lazy var hasUserTipsPredicate: NSPredicate = {
        var pr = NSPredicate(format: "stats.tipCount > 0")
        return pr
    }()
    
    lazy var nameSortDescriptor: NSSortDescriptor = {
        var sd = NSSortDescriptor(key: "name", ascending: true, selector: "localizedStandardCompare:")
        return sd
    }()
    
    lazy var distanceSortDescriptor: NSSortDescriptor = {
        var sd = NSSortDescriptor(key: "location.distance", ascending: true)
        return sd
    }()
    
    lazy var priceSortDescriptor: NSSortDescriptor = {
        var sd = NSSortDescriptor(key: "priceInfo.priceCategory", ascending: true)
        return sd
    }()
    
    // MARK: - Fetching Methods
    //===============================================================================
    //===============================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        populateCheapVenueCountLabel()
        populateModerateVenueCountLabel()
        populateExpensiveVenueCountLabel()
        populateDealsCountLabel()
    }
    
    //===============================================================================
    //===============================================================================
    func populateCheapVenueCountLabel() {
        let fetchRequest = NSFetchRequest(entityName: "Venue")
        fetchRequest.resultType = .CountResultType
        fetchRequest.predicate = cheapVenuePredicate
        
        var error: NSError?
        
        let result = coreDataStack.context.executeFetchRequest(fetchRequest, error: &error) as! [NSNumber]?
        if let countArray = result {
            let count = countArray[0].integerValue
            firstPriceCategoryLabel.text = "\(count) bubble tea places"
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    //===============================================================================
    //===============================================================================
    func populateModerateVenueCountLabel() {
        let fetchRequest = NSFetchRequest(entityName: "Venue")
        fetchRequest.resultType = .CountResultType
        fetchRequest.predicate = moderateVenuePredicate
        
        var error: NSError?
        let result = coreDataStack.context.executeFetchRequest(fetchRequest, error: &error) as! [NSNumber]?
        if let countArray = result {
            let count = countArray[0].integerValue
            secondPriceCategoryLabel.text = "\(count) bubble tea places"
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    //===============================================================================
    //===============================================================================
    func populateExpensiveVenueCountLabel() {
        let fetchRequest = NSFetchRequest(entityName: "Venue")
        fetchRequest.predicate = expensiveVenuePredicate
        
        var error: NSError?
        let count = coreDataStack.context.countForFetchRequest(fetchRequest, error: &error)
        
        if count == NSNotFound {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        
        thirdPriceCategoryLabel.text = "\(count) bubble tea places"
    }
    
    //===============================================================================
    //===============================================================================
    func populateDealsCountLabel() {
        let fetchRequest = NSFetchRequest(entityName: "Venue")
        fetchRequest.resultType = .DictionaryResultType
        
        // Create NSExpressionDescription to request sum, give it name so you can read results from dictionary
        let sumExpressDesc = NSExpressionDescription()
        sumExpressDesc.name = "sumDeals"
        
        // Give expression description an NSExpression to specify that you want sum function
        // Use another NSExpression to specify specialCount as the property you want to sum over
        sumExpressDesc.expression = NSExpression(forFunction: "sum:", arguments: [NSExpression(forKeyPath: "specialCount")])
        sumExpressDesc.expressionResultType = .Integer32AttributeType
        
        // Tell fetch request that you want to fetch the sum by doing this...
        fetchRequest.propertiesToFetch = [sumExpressDesc]
        
        var error: NSError?
        let result = coreDataStack.context.executeFetchRequest(fetchRequest, error: &error) as! [NSDictionary]?
        
        if let resultArray = result {
            let resultDict = resultArray[0]
            let numDeals: AnyObject? = resultDict["sumDeals"]
            numDealsLabel.text = "\(numDeals!) total deals"
        } else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    
    // MARK: - UITableViewDelegate
    //===============================================================================
    // Determine which cell/filter was selected and set selectedPredicate
    //===============================================================================
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        
        switch cell {
            
            // Price Section
        case cheapVenueCell:
            selectedPredicate = cheapVenuePredicate
        case moderateVenueCell:
            selectedPredicate = moderateVenuePredicate
        case expensiveVenueCell:
            selectedPredicate = expensiveVenuePredicate
            
        // Most Popular Section
        case offeringDealCell:
            selectedPredicate = offeringDealPredicate
        case walkingDistanceCell:
            selectedPredicate = walkingDistancePredicate
        case userTipsCell:
            selectedPredicate = hasUserTipsPredicate
            
        // Sort By Section
        case nameAZSortCell:
            selectedSortDescriptor = nameSortDescriptor
        case nameZASortCell:
            selectedSortDescriptor = nameSortDescriptor.reversedSortDescriptor as? NSSortDescriptor
        case distanceSortCell:
            selectedSortDescriptor = distanceSortDescriptor
        case priceSortCell:
            selectedSortDescriptor = priceSortDescriptor
            
        default:
            println("DEFAULT CASE")
        }
        
        cell.accessoryType = .Checkmark
    }
    
    // MARK: - @IBAction
    //===============================================================================
    // Send our protocol method to the delegate to be carried out with these variables...
    //===============================================================================
    @IBAction func saveButtonTapped(sender: UIBarButtonItem) {
        delegate!.filterViewController(self, didSelectPredicate: selectedPredicate, sortDescriptor: selectedSoftDescriptor)
        dismissViewControllerAnimated(true, completion:nil)
    }
    
}
