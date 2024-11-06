//
//  ViewController.swift
//  Lab3_WeatherApp_Faraz
//
//  Created by Faraz Ahmed on 2024-11-05.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    var locationData : weatherResponse?
    @IBOutlet weak var Image: UIImageView!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var Temperature: UILabel!
    @IBOutlet weak var locationTextfield: UITextField!
    @IBOutlet weak var toggleBtn: UISwitch!
    @IBOutlet weak var toggleLabel: UILabel!
    var value = true
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        locationTextfield.delegate = self
        locationManager.delegate = self
    }

    func textFieldShouldReturn(_ sender: UITextField) -> Bool {
        locationTextfield.endEditing(true)
        return true
       
    }
    @IBAction func switchChange(_ sender: UISwitch) {
        if sender.isOn {
            value = true
            Temperature.text = String(locationData?.current.temp_c ?? 0)+"C"
                toggleLabel.text = "Celsius"
            } else {
                value = false
                Temperature.text = String(locationData?.current.temp_f ?? 0)+"F"
                toggleLabel.text = "Fahrenheit"
            }
    }
    @IBAction func searchLocationTapped(_ sender: UIButton) {
        weatherShow(search: locationTextfield.text)
    }
    
    @IBAction func currentLocationTapped(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func weatherShow(search : String?){
        guard let search = search else{
            return
        }
        guard let url = getURL(query: search) else {
            print("Could not get URL")
            return
        }
        let session = URLSession.shared
        let dataTask = session.dataTask(with: url) { data, response, error in
            print("Network call complete")
            guard error == nil else {
                print("received error")
                return
            }
            guard let data = data else {
                print("NO DATA FOUND")
                return
            }
            if let responseW = self.parseJson(data: data){
                self.locationData = responseW
                print(responseW.location.name)
                print(responseW.current.temp_c)
                print(responseW.current.temp_f)
                print(responseW.current.condition.code)
                DispatchQueue.main.async {
                    self.location.text = responseW.location.name
                    if self.value == true {
                        self.Temperature.text = "\(responseW.current.temp_c)C"
                    }else{
                        self.Temperature.text = "\(responseW.current.temp_f)F"
                    }
                    switch responseW.current.condition.code {
                    case 1000:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "sun.max")
                    case 1003...1009:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "sun.min")
                    case 1010...1050:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.white, .systemYellow])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "snowflake.circle.fill")
                    case 1050...1079:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "cloud.drizzle")
                    case 1180...1209:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "cloud.bolt")
                    case 1210...1260:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "snowflake")
                    case 1270...1285:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "cloud.sleet.fill")
                    default:
                        let config = UIImage.SymbolConfiguration(paletteColors: [.systemYellow, .white])
                        self.Image.preferredSymbolConfiguration = config
                        self.Image.image = UIImage(systemName: "cloud")
                    }
                }
            }
            
            
        }
    
        dataTask.resume()
    }
    
    private func getURL(query : String) -> URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "6c07f59540ff415eaf4205741241803"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        print(url)
        return URL(string: url)
    }
    
    private func parseJson(data: Data) -> weatherResponse?{
        let decoder = JSONDecoder()
        var weather: weatherResponse?
        do  {
            weather = try decoder.decode(weatherResponse.self, from: data)
        }catch{
            print("Error Decoding")
        }
        return weather
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            print("Lat: \(latitude), Long: \(longitude)")
            currentLocationName(latitude: latitude, longitude: longitude)
        }
        
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    private func currentLocationName(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
            let location = CLLocation(latitude: latitude, longitude: longitude)
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                guard let placemark = placemarks?.first, error == nil else {
                    print("Reverse geocoding failed with error: \(error!)")
                    return
                }
                if let city = placemark.locality {
                    self.weatherShow(search: city)
                } else {
                    self.location.text = "Unknown"
                }
            }
        }
}

struct weatherResponse: Decodable {
    let location: Location
    let current: Weather
}
struct Location: Decodable{
    let name: String
}
struct Weather: Decodable{
    let temp_c: Float
    let temp_f: Float
    let condition: WeatherCondition
}
struct WeatherCondition: Decodable {
    let text: String
    let code: Int
}

