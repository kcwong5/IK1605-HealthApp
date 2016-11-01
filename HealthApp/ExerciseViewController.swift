//
//  ExerciseViewController.swift
//  HealthApp
//
//  Created by Wong Sam on 27/10/2016.
//  Copyright © 2016年 Wong Sam. All rights reserved.
//

import UIKit
import HealthKit
import Charts

class ExerciseViewController: UIViewController,ChartViewDelegate {
    var myHealthStore = HKHealthStore()
    @IBOutlet var stepCountLabel : UILabel!
    @IBOutlet weak var stepBarChartView: BarChartView!
    var steps: [Int] = [0,0,0,0,0,0,0]
    var days: [Int] = [1,2,3,4,5,6,7]
    let goal : Int = Int(7000)
    override func viewDidLoad() {
        super.viewDidLoad()
        stepBarChartView.delegate = self
        stepBarChartView.chartDescription?.text = ""
        stepBarChartView.leftAxis.axisMinimum = Double(0)
        stepBarChartView.rightAxis.axisMinimum = Double(0)
        stepBarChartView.leftAxis.axisMaximum = Double(20000)
        stepBarChartView.rightAxis.axisMaximum = Double(20000)
        stepBarChartView.scaleXEnabled = false
        stepBarChartView.xAxis.avoidFirstLastClippingEnabled = true
        //stepBarChartView.noDataText = "Loading data for the chart."
        setChart(values: steps)
        readWeeklyStep()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func readMonthlyStep(){
        steps = []
        days = []
        let calendar = NSCalendar.current
        let compoents = calendar.dateComponents([.day], from: NSDate() as Date)
        if compoents.day!>30{
            for day in 0...30{
                self.steps.insert(0, at: day)
                self.days.insert(day+1, at: day)
            }
        }
        else{
            for day in 0..<compoents.day!{
                self.steps.insert(0, at: day)
                self.days.insert(day+1, at: day)
            }
            for day in compoents.day!...29{
                self.steps.insert(0, at: day)
                self.days.insert(day+1, at: day)
            }
        }
        for day in 0..<compoents.day!{
            let typeOfStep = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            let scCalendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
            let now = NSDate()
            let startDate = scCalendar.date(byAdding: Calendar.Component.day, value: day-compoents.day!+1, to: now as Date)
            let today = scCalendar.startOfDay(for: startDate! as Date)
            let yesterday = scCalendar.date(byAdding: Calendar.Component.day, value: -1, to: today)
            let predicate = HKQuery.predicateForSamples(withStart: today, end: NSDate() as Date , options: .strictStartDate)
            let interval: NSDateComponents = NSDateComponents()
            interval.day = 1
            //  Perform the Query
            let query = HKStatisticsCollectionQuery(quantityType: typeOfStep!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: today as Date, intervalComponents:interval as DateComponents)
            
            query.initialResultsHandler = { query, results, error in
                //  Something went Wrong
                if error != nil {
                    return
                }
                if let myResults = results{
                    myResults.enumerateStatistics(from: yesterday! as Date, to: today as Date) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            let step = (Int(quantity.doubleValue(for: HKUnit.count())))
                            self.steps[day] = step
                            self.setChart(values: self.steps)
                            self.stepCountLabel.text = "\(self.steps[compoents.day!-1])"
                        }
                    }
                }
            }
            myHealthStore.execute(query)
        }
    }
    private func readWeeklyStep(){
        steps = []
        days = []
        let calendar = NSCalendar.current
        let weekDay = calendar.component(.weekday, from: NSDate() as Date)
        for day in 0..<weekDay{
            let currentday = calendar.date(byAdding: Calendar.Component.day, value: day-weekDay+1, to: NSDate() as Date)
            let compoent = calendar.dateComponents([.day], from: currentday!)
            self.days.insert(compoent.day!, at: day)
            self.steps.insert(0, at: day)
        }
        
        for day in 0..<weekDay{
            let typeOfStep = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
            let scCalendar = Calendar.init(identifier: Calendar.Identifier.gregorian)
            let now = NSDate()
            let startDate = scCalendar.date(byAdding: Calendar.Component.day, value: day-weekDay+1, to: now as Date)
            let today = scCalendar.startOfDay(for: startDate! as Date)
            let yesterday = scCalendar.date(byAdding: Calendar.Component.day, value: -1, to: today)
            let predicate = HKQuery.predicateForSamples(withStart: today, end: NSDate() as Date , options: .strictStartDate)
            let interval: NSDateComponents = NSDateComponents()
            interval.day = 1
            //  Perform the Query
            let query = HKStatisticsCollectionQuery(quantityType: typeOfStep!, quantitySamplePredicate: predicate, options: [.cumulativeSum], anchorDate: today as Date, intervalComponents:interval as DateComponents)
            
            query.initialResultsHandler = { query, results, error in
                //  Something went Wrong
                if error != nil {
                    return
                }
                if let myResults = results{
                    myResults.enumerateStatistics(from: yesterday! as Date, to: today as Date) {
                        statistics, stop in
                        if let quantity = statistics.sumQuantity() {
                            let step = (Int(quantity.doubleValue(for: HKUnit.count())))
                            self.steps[day] = step
                            self.setChart(values: self.steps)
                            self.stepCountLabel.text = "\(self.steps[weekDay-1])"
                        }
                    }
                }
            }
            myHealthStore.execute(query)
        }
    }
    func setChart(values: [Int]){
        var dataEntries: [BarChartDataEntry] = []
        let ll = ChartLimitLine(limit: Double(self.goal), label: "")
        stepBarChartView.rightAxis.addLimitLine(ll)
        stepBarChartView.leftAxis.addLimitLine(ll)
        for i in 0..<values.count {
            let dataEntry = BarChartDataEntry(x: Double(i), y: Double(values[i]))
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = BarChartDataSet(values: dataEntries, label: "")
        let chartData = BarChartData(dataSet: chartDataSet)
        stepBarChartView.data = chartData
        stepBarChartView.xAxis.labelPosition = .bottom

    }
    
    @IBAction func weeklyButton() {
        readWeeklyStep()
    }
    
    @IBAction func monthlyButton() {
        readMonthlyStep()
    }
    
    @IBAction func profileButton() {
        if let ViewController = storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            present(ViewController, animated: false, completion:nil)
        }
    }
}
