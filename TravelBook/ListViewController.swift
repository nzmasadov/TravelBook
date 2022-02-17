//
//  FirstViewController.swift
//  A.S-TravelBook
//
//  Created by Nazim Asadov on 25.01.22.
//

import UIKit
import CoreData


class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource  {
    
    let singleton = UserSingleton.sharedInstance
    
    @IBOutlet weak var tableView: UITableView!
  //  var selectedId: UUID?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self
        tableView.dataSource = self

        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.add, target: self, action: #selector(addButton))
        
        getData()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("newData"), object: nil)
    }
    
    
    @objc func getData() {
        
        singleton.idArray.removeAll(keepingCapacity: false)
        singleton.titleArray.removeAll(keepingCapacity: false)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let contex = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
        fetchRequest.returnsObjectsAsFaults = false
        do{
            let results = try contex.fetch(fetchRequest)
            if results.count > 0 {
                for result in results as! [NSManagedObject] {
                    if let title = result.value(forKey: "title") as? String{
                        singleton.titleArray.append(title)
                    }
                    if let id = result.value(forKey: "id") as? UUID {
                        singleton.idArray.append(id)
                    }
                    tableView.reloadData()
                }
            }
        }catch{
            print("eRror")
        }
    }
    
    @objc func addButton() {
        singleton.selectedTitle = ""
        performSegue(withIdentifier: "toMainVC", sender: nil)
    }
    
    
    //
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let contex = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            fetchRequest.returnsObjectsAsFaults = false
            
            let idString = singleton.idArray[indexPath.row].uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString)
            
            do{
                let results = try contex.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let id = result.value(forKey: "id") as? UUID{
                            if id == singleton.idArray[indexPath.row] {
                                contex.delete(result)
                                singleton.idArray.remove(at: indexPath.row)
                                singleton.titleArray.remove(at: indexPath.row)
                                self.tableView.reloadData()
                                do{
                                    try contex.save()
                                }catch{
                                    print("erroR")
                                }
                                break
                            }
                        }
                    }
                }
            }catch{
                print("errOr")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = singleton.titleArray[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return singleton.titleArray.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        singleton.selectedId = singleton.idArray[indexPath.row]
        singleton.selectedTitle = singleton.titleArray[indexPath.row]
        performSegue(withIdentifier: "toMainVC", sender: self)
    }
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "toMainVC"{
//            let detailedVC = segue.destination as! MainViewController
//            detailedVC.chosenId = selectedId
//        }
//    }
}
