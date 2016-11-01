//
//  ViewController.swift
//  HealthApp
//
//  Created by Wong Sam on 26/10/2016.
//  Copyright © 2016年 Wong Sam. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController{
    
    var myHealthStore = HKHealthStore()
    @IBOutlet var ageLabel : UILabel!
    @IBOutlet var bloodLabel : UILabel!
    @IBOutlet var sexLabel : UILabel!
    @IBOutlet var heightLabel : UILabel!
    @IBOutlet var weightLabel : UILabel!
    @IBOutlet var BMILabel : UILabel!
    @IBOutlet var stepCountLabel : UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        requestAuthorization()
    }
    
    private func requestAuthorization(){
        let typeOfRead = Set(arrayLiteral:
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.bodyMass)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.height)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.bloodType)!
        )
        myHealthStore.requestAuthorization(toShare: nil, read: typeOfRead, completion: { (success, error) in
            if let e = error {
                print("Error: \(e.localizedDescription)")
                return
            }
            if success {
                print("Success!")
                self.readData()
            } else {
                print("Error!")
            }
        })
    }
    
    //Data Reading
    private func readData() {
        do {
            // get sex
            let myBiologicalSex = try myHealthStore.biologicalSex()
            var myBiologicalSexText:String = ""
            switch myBiologicalSex.biologicalSex {
            case HKBiologicalSex.female:
                myBiologicalSexText = "Female"
            case HKBiologicalSex.male:
                myBiologicalSexText = "Male"
            case HKBiologicalSex.notSet:
                myBiologicalSexText = "NotSet"
            default:
                myBiologicalSexText = "error"
                print("error")
            }
            // assign sex to label
            sexLabel.text = "Sex : \(myBiologicalSexText)"
            // get blood type
            let myBloodType = try myHealthStore.bloodType()
            var myBloodTypeText = ""
            switch myBloodType.bloodType {
            case HKBloodType.aPositive:
                myBloodTypeText = "A+"
            case HKBloodType.aNegative:
                myBloodTypeText = "A-"
            case HKBloodType.bPositive:
                myBloodTypeText = "B+"
            case HKBloodType.bNegative:
                myBloodTypeText = "B-"
            case HKBloodType.abPositive:
                myBloodTypeText = "AB+"
            case HKBloodType.abNegative:
                myBloodTypeText = "AB-"
            case HKBloodType.oPositive:
                myBloodTypeText = "O+"
            case HKBloodType.oNegative:
                myBloodTypeText = "O-"
            default:
                myBloodTypeText = "error"
                print("error")
            }
            // assign blood type to label
            bloodLabel.text = "BloodType : \(myBloodTypeText)"
            // get date of birth
            let dateOfBirth = try myHealthStore.dateOfBirthComponents()
            let now = NSDate()
            let calendar = NSCalendar.current
            let compoents = calendar.dateComponents([.year], from: now as Date)
            // calculate age and assign to label
            ageLabel.text = "Age : \(compoents.year! - dateOfBirth.year!)"
            // get step count
            let typeOfStep = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            let scCalendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
            let startDate = scCalendar.startOfDay(for: now as Date)
            let yesterday = scCalendar.date(byAdding: Calendar.Component.day, value: -1, to: startDate)
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: NSDate() as Date, options: .strictStartDate)
            let interval: NSDateComponents = NSDateComponents()
            interval.day = 1
            //  Perform the Query
            let query = HKStatisticsCollectionQuery(quantityType: typeOfStep!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: startDate as Date, intervalComponents:interval as DateComponents)
            
            query.initialResultsHandler = { query, results, error in
                //  Something went Wrong
                if error != nil {                    
                    return
                }
                if let myResults = results{
                    myResults.enumerateStatistics(from: yesterday! as Date, to: NSDate() as Date) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            let steps: Int = Int(quantity.doubleValue(for: HKUnit.count()))
                            self.stepCountLabel.text = "Steps : \(steps)"
                        }
                    }
                }
            }
            
            myHealthStore.execute(query)
          
            
        } catch let error as NSError {
            // reading error
            sexLabel.text = "Sex : Error"
            bloodLabel.text = "BloodType : Error"
            ageLabel.text = "Age: Error"
            stepCountLabel.text = "StepCount: Error"
            print("A read error occured")
            print("\(error.localizedDescription)")
        }
    }
    @IBAction func exerciseButton() {
        if let exerciseViewController = storyboard?.instantiateViewController(withIdentifier: "ExerciseViewController") as? ExerciseViewController {
            present(exerciseViewController, animated: false, completion:nil)
        }
    }
}
