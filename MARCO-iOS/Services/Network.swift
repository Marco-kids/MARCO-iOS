//
//  Network.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 11/15/22.
//

import SwiftUI
import Combine

// private let url = "http://10.14.255.70:10205/api/all-obras"
//private let url = "http://192.168.84.171:8080/api/all-obras" // Datos celular
private let url = "http://192.168.100.25:8080/api/all-obras" // Casita Daniel
// private let url = "http://10.22.235.64:8080/api/all-obras" // Salon
// private let url = "http://192.168.1.236:8080/api/all-obras" // Casa Jose

class Network: NSObject, ObservableObject {
    
    static let sharedInstance = Network() // Comparte la instancia de Network() entre clases views, etc.
    
    @Published var models: [Obra] = []
    var rutas: [URL] = []
    
    var obrasPublisher = PassthroughSubject<[Obra], Error>()
    
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
        for model in self.models {
            downloadModel(model: model.modelo)
        }
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
            }
        })
        downloadTask.resume()
    }
    
}
