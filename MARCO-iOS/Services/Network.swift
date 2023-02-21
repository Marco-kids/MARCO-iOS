//
//  Network.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/15/22.
//

import SwiftUI
import Combine
import Alamofire

// private let url = "http://10.14.255.70:10205/api/all-obras"
//private let url = "http://192.168.84.171:8080/api/all-obras" // Datos celular
// private let url = "http://192.168.100.29:8080/api/all-obras" // Casita
// private let url = "http://10.22.186.24:8080/api/all-obras" // Salon Swift
private let url = "http://192.168.1.236:8080/api/all-obras" // Casa Jose
let headers: HTTPHeaders = []

class Network: NSObject, ObservableObject {
    
    static let sharedInstance = Network() // Comparte la instancia de Network() entre clases views, etc.
    
    @Published var models: [Obra] = []
    var rutas: [URL] = []
    
    var obrasPublisher = PassthroughSubject<[Obra], Error>()
    #if !targetEnvironment(simulator)
    weak var delegateARVC: ARViewController?
    #endif
    
    // ARWorldMap
    var downloadedData: [Data] = []
    @Published var locations: [ARLocation] = []
    
    func getModels() {
        print("Started USDZ request")
        guard let url = URL(string: url) else { fatalError("Missing URL") }

        let urlRequest = URLRequest(url: url)

        let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                print("Request error: ", error)
                return
            }

            guard let response = response as? HTTPURLResponse else { return }

            print("URL error")
            if response.statusCode == 200 {
                guard let data = data else { return }
                DispatchQueue.main.async {
                    do {
                        let decodedModels = try JSONDecoder().decode([Obra].self, from: data)
                        self.models = decodedModels
                        self.obrasPublisher.send(self.models)
                        self.loadModels() // Downloads USDZ models
                    } catch let error {
                        print("Error decoding: ", error)
                    }
                }
            }
        }
        dataTask.resume()
    }
    
    func loadModels() {
        downloadModel(model: self.models[0].modelo)
//        for model in self.models {
//            downloadModel(model: model.modelo)
//        }
    }
    
    func downloadModel(model: String) {
        print(model)
        let url = URL(string: model)
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destinationUrl = documentsUrl.appendingPathComponent(url!.lastPathComponent)
        let session = URLSession(configuration: URLSessionConfiguration.default, delegate: nil, delegateQueue: nil)
        var request = URLRequest(url: url!) // MARK: Checar el unwrapper (!)
        request.httpMethod = "GET"
        let downloadTask = session.downloadTask(with: request, completionHandler: { (location:URL?, response:URLResponse?, error:Error?) -> Void in
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: destinationUrl.path) {
                try! fileManager.removeItem(atPath: destinationUrl.path)
            }
            try? fileManager.moveItem(atPath: location?.path ?? "", toPath: destinationUrl.path) // MARK: Check errors to catch in ?? and ""
            DispatchQueue.main.async {
                for (index, obra) in self.models.enumerated() {
                    if obra.modelo == model {
                        self.models[index].modelo = destinationUrl.absoluteString
                        self.rutas.append(destinationUrl)
                    }
                }
                print(self.rutas)
                self.obrasPublisher.send(self.models)
                #if !targetEnvironment(simulator)
                guard let delegateEditor = self.delegateARVC else { return }
                delegateEditor.loadGame(obra: self.models[0])
                #endif
            }
        })
        downloadTask.resume()
    }
    
    #if !targetEnvironment(simulator)
    
    func getLocations() {
        let url = Params.locationsURL
        AF.request(url).responseJSON { [self] response in
            switch response.result {
            case .success(let value):
                do {
                    let arLocation = try JSONDecoder().decode([ARLocation].self, from: response.data!)
                    self.locations = arLocation
                    for item in arLocation {
                        self.getARWordlMap(location: item)
                    }
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            case .failure(let error):
                print("Error: \(error)")
            }
        }
    }
    
    func getARWordlMap(location: ARLocation) {
        let fileName = location.ARWorldMap.components(separatedBy: "/").last
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let filePathToSearch = documentsURL.relativePath + "/" + fileName!
        let filePathToSearchURL = URL(string: "file://" + filePathToSearch)
        if fileManager.fileExists(atPath: filePathToSearch) {
            for i in self.locations.indices {
                if self.locations[i].nombre == location.nombre {
                    self.locations[i].locationPath = filePathToSearchURL
                    guard let delegateEditor = delegateARVC else { return }
                    delegateEditor.loadedData(locations: self.locations)
                }
            }
        } else {
            downloadARWorldMap(location: location)
        }
    }
    
    func downloadARWorldMap(location: ARLocation) {
        let destination = DownloadRequest.suggestedDownloadDestination(for: .documentDirectory)
        AF.download(Params.baseURL + location.ARWorldMap, to: destination).responseData { response in
            if let error = response.error {
                print("Error downloading file: \(error)")
            } else if let data = response.value {
                self.downloadedData.append(data)
                for i in self.locations.indices {
                    if self.locations[i].nombre == location.nombre {
                        print(response.fileURL as Any)
                        self.locations[i].locationPath = response.fileURL
                        guard let delegateEditor = self.delegateARVC else { return }
                        delegateEditor.loadedData(locations: self.locations)
                    }
                }
            }
        }
    }
#endif
}
