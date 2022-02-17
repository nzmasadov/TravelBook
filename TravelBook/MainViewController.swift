//
//  ViewController.swift
//  A.S-TravelBook
//
//  Created by Nazim Asadov on 25.01.22.
//

import UIKit
import MapKit
import CoreLocation
import CoreData



class MainViewController: UIViewController {
    
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var saveButtonOutlet: UIButton!
    
    let locationManager = CLLocationManager()
    
 //   var chosenLongitude = Double()
  //  var chosenLatitude = Double()
    
  //  var chosenId: UUID?
    
    var singleton = UserSingleton.sharedInstance
    

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest  // accuracy quality of location
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        
        saveButtonOutlet.layer.cornerRadius = 15
        
        // hide keyboard
        nameText.delegate = self
        commentText.delegate = self
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        
        showPin()
        
      
    }
    
//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        view.endEditing(true)
//    }
    
    
    func showPin() {
        if UserSingleton.sharedInstance.selectedTitle != "" {
            saveButtonOutlet.isHidden = true
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let contex = appDelegate.persistentContainer.viewContext
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            
            let idString = singleton.selectedId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", idString!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do{
                let results = try contex.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let title = result.value(forKey: "title") as? String{
                            singleton.annotationTitle = title
                            if let subtitle = result.value(forKey: "subtitle") as? String{
                                singleton.annotationSubtitle = subtitle
                                if let longitude = result.value(forKey: "longitude") as? Double{
                                    singleton.annotationLongitude = longitude
                                    if let latitude = result.value(forKey: "latitude") as? Double{
                                        singleton.annotationLatitude = latitude
                                        
                                        let annotation = MKPointAnnotation()
                                        annotation.title = singleton.selectedTitle
                                        annotation.subtitle = singleton.annotationSubtitle
                                        let coordinate = CLLocationCoordinate2D(latitude: singleton.annotationLatitude, longitude: singleton.annotationLongitude)
                                        annotation.coordinate = coordinate
                                        mapView.addAnnotation(annotation)
                                        nameText.text = singleton.annotationTitle
                                        commentText.text = singleton.annotationSubtitle
                                        
                                        locationManager.stopUpdatingLocation() // edirik ki işarətlədiyimiz yerdə map sabit qalsın, bizlə bərabər hərəkət etməsin
                                        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                        let region = MKCoordinateRegion(center: coordinate, span: span)
                                        self.mapView.setRegion(region, animated: true)
                                    }
                                }
                            }
                        }
                    }
                }
            }catch{
                print("erRor")
            }
            
        }else{
            
        }
    }
    
    // 3. to reach contex and save user information to Core Data
    @IBAction func saveButtonPressed(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let contex = appDelegate.persistentContainer.viewContext
        
        let newPlaces = NSEntityDescription.insertNewObject(forEntityName: "Places", into: contex)
        
        // empty control
        if nameText.text == "" || commentText.text == "" {
            let alert = UIAlertController(title: "Error", message: "Please type someting", preferredStyle: UIAlertController.Style.alert)
            let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil)
            alert.addAction(okButton)
            present(alert, animated: true) {
                return
            }
        }else {
        newPlaces.setValue(nameText.text, forKey: "title")
        newPlaces.setValue(commentText.text, forKey: "subtitle")
        newPlaces.setValue(UUID(), forKey: "id")
            newPlaces.setValue(singleton.chosenLatitude, forKey: "latitude")
            newPlaces.setValue(singleton.chosenLongitude, forKey: "longitude")
        }
        
        do{
            try contex.save()
            print("success")
        }catch{
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("newData"), object: nil)
        self.navigationController?.popViewController(animated: true)
        
    }
}

//MARK: - MKMapViewDelegate, CLLocationManagerDelegate
extension MainViewController: MKMapViewDelegate, CLLocationManagerDelegate {
    
    //  updated location of user. 1.
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if singleton.selectedTitle == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)  // zooming
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true) // to reach the region we had to reach
        }else{
            //
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var markerView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKMarkerAnnotationView
        if markerView == nil {
            markerView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            markerView?.canShowCallout = true
            markerView?.tintColor = .systemGreen
      //      markerView?.glyphImage = .actions
            
            let button = UIButton(type: UIButton.ButtonType.detailDisclosure)
            markerView?.rightCalloutAccessoryView = button
            
        }else{
            markerView?.annotation = annotation 
        }
        
        return markerView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if singleton.selectedTitle != "" {
            let geoLocation = CLLocation(latitude: singleton.annotationLatitude, longitude: singleton.annotationLongitude)
        
        CLGeocoder().reverseGeocodeLocation(geoLocation) { placemarks, error in
            if let placemarkz = placemarks{ // optional olduğu üçün kontrol
                if placemarkz.count > 0 {  // əlavə kontrol
                    let newPlacemark = MKPlacemark(placemark: placemarkz[0])
                    let item = MKMapItem(placemark: newPlacemark)
                    item.name = self.singleton.annotationTitle
                    
                    let launchOptions = [MKLaunchOptionsDirectionsModeKey:MKLaunchOptionsDirectionsModeDriving]
                    item.openInMaps(launchOptions: launchOptions)
                }
            }
        }
        }
    }
    
    // 2.
    @objc func chooseLocation(gestureRecognizer:UILongPressGestureRecognizer){
        
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: self.mapView)
            let touchedCoordinate =  mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            singleton.chosenLatitude = touchedCoordinate.latitude
            singleton.chosenLongitude = touchedCoordinate.longitude
            
            let annotation = MKPointAnnotation()   // pinning
            
            annotation.coordinate = touchedCoordinate.self
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }
}

//MARK: - UITextFieldDelegate
extension MainViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
       // textField.resignFirstResponder()
        self.view.endEditing(true)
        return false
    }
}
