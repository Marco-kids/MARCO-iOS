//
//  ARViewController.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 2/20/23.
//

#if !targetEnvironment(simulator)

import UIKit
import ARKit
import RealityKit
import Combine
import AVFoundation

protocol EditorViewControllerDelegate: AnyObject {
    func loadedData(locations: [ARLocation])
    func loadGame(obra: Obra, models: [Obra])
}

class ARViewController: UIViewController, ARSessionDelegate, ObservableObject {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var sessionInfoLabel: UILabel!
    @IBOutlet var arView: ARView!
    
    var model = Entity()
    var flagLoading: Bool?
    var location: ARLocation?
    let network = Network.sharedInstance
    
    var locationCount: Int = 0
    
    override func viewDidLoad() {
        print("EMPIEZA viewdidload")
        super.viewDidLoad()
        // RealityKit Config
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)
        arView.debugOptions = [ .showFeaturePoints ]
        arView.session.delegate = self
        // Loads sample model (USDZ)
        self.model = try! Entity.load(named: "toy_drummer")
        // Gesture recognizer config
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        arView.addGestureRecognizer(tapGesture)
        // Protocol
        #if !targetEnvironment(simulator)
        network.delegateARVC = self
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("EMPIEZA viewWillAppear")
    }
    
    // MARK: - Persistence: Saving and Loading
    
    private func load(location: ARLocation) {
        print("EMPIEZA load")
        let url = Params.baseURL + location.screenshot
        imageView.imageFromServerURL(url, placeHolder: nil)

        var data = Data()
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            data = try Data(contentsOf: (location.locationPath!))
        } catch {
            print("Error while enumerating files \(documentsURL.path): \(error.localizedDescription)")
        }
        
        let worldMap: ARWorldMap = {
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()

        let configuration = self.defaultConfiguration // this app's standard world tracking settings
        configuration.initialWorldMap = worldMap
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        self.isRelocalizingMap = true
    }
    
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        updateSessionInfoLabel(for: session.currentFrame!, trackingState: camera.trackingState)
    }
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        updateSessionInfoLabel(for: frame, trackingState: frame.camera.trackingState)
    }
    
    // MARK: - AR session managment
    
    var isRelocalizingMap = false
    
    var defaultConfiguration: ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        return configuration
    }
    
    var prevState: Bool?
    
    // This switch can be modified to just detect the space in MARCO KIDS main app
    private func updateSessionInfoLabel(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        imageView.isHidden = true
        if (prevState == true) {
            switch (trackingState) {
            case .normal:
                locationDetectedAlert()
                self.loadGame(obra: network.models[locationCount])
                locationCount += 1
            default:
                prevState = true
            }
        }
        switch (trackingState, frame.worldMappingStatus) {
        case (.normal, .mapped),
             (.normal, .extending):
            message = "Tap 'Save Experience' to save the current map."
            prevState = false
        case (.normal, _) where flagLoading != nil && !isRelocalizingMap:
            message = "Move around to map the environment or tap 'Load Experience' to load a saved experience."
            prevState = false
        case (.normal, _) where flagLoading == nil:
            message = "Move around to map the environment."
            prevState = false
        case (.limited(.relocalizing), _) where isRelocalizingMap:
            message = "Move your device to the location shown in the image."
            imageView.isHidden = false
            prevState = true
        default:
            message = trackingState.localizedFeedback
            prevState = false
        }
        sessionInfoLabel.text = message
    }
    
    // MARK: Alerts
    
    func locationDetectedAlert() {
        let alertController = UIAlertController(title: "Zona detectada correctamente.", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    // MARK: Protocol
    
    func loadedData(locations: [ARLocation]) {
        // MARK: CoreData implementation to load current location
        let obrasCoredata = DataBaseHandler.fetchAllObras()
        locationCount = obrasCoredata.count
        
        if (locationCount < network.models.count) {
            self.load(location: locations[locationCount])
        }
    }
    
    // Method that makes game active
    func loadGame(obra: Obra) {

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        self.initCollisionDetection()
        self.initBullets()
        self.initLight()
        self.initBoxes()
        self.arView.session.run(configuration, options: [.resetTracking])
        // MARK: Se buggea el coaching overlay
        // self.runCoachingOverlay()
        
        print("EMPIEZA loadGame")
        self.removePreviousContent()
        // MARK: To enable random level
        // self.showMarcoModel(currentObra: obra, gameType: Int.random(in: 0..<2))
        self.showMarcoModel(currentObra: obra, gameType: 2)
        
    }
    
    // MARK: Coordinator Code
    var collisionSubscriptions = [Cancellable]()
    
    var currModel = Obra(_id: "0", nombre: "Pirinola", autor: "Jose", descripcion: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.", modelo: "Models/pirinola.usdz", zona: "", completed: false)
    
    // Variable for loading asynchronous models
    var newEntityPirinola: AnyCancellable?
    
    // Variable para saber si ya se capturaron todos los cubitos
    static let completed = ARViewController()
    var currSheet = false
    var progresoActual: Int = 0
    
    // Grupos para detectar colisiones
    let boxGroup = CollisionGroup(rawValue: 1 << 0)
    let sphereGroup = CollisionGroup(rawValue: 1 << 1)
    
    // Masks para detectar colisiones
    var boxMask: CollisionGroup = .init()
    
    // GameType => Difficulty
    // 0 =>
    var gameType = 1
    
    // var arrayObjetos = [false, false, false, false, false, false, false, false, false, false, false, false]
    // MARK: Eliminated boxes: box7, box8 and box9 that are nore used in gameType2
    var arrayObjetos = [false, false, false, false, false, false, true, true, true, false, false, false]


    // Anchor para los modelos
    // let anchor = AnchorEntity(plane: .horizontal, classification: .floor) // Production
    let anchor = AnchorEntity(plane: .horizontal) // For tes`ting puposes
    var pointLightFront = CustomPointLight.init()
    var pointLightBack = CustomPointLight.init()
    // let anchor = AnchorEntity()
    
    let anchorBullet = AnchorEntity(world: [0,0,0])
    
    // For animation on collision between box and bullet
    var animUpdateSubscriptions = [Cancellable]()
    
    // Variables for bullets, used to avoid recreating new bullets therefore optimizing performance
    var bulletMaterial = SimpleMaterial(color: .green, isMetallic: false) // Bullet material
    var currBullet: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody) // Curr bullet thrown
    
    // List of bullets
    var bullet1: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet2: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet3: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet4: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet5: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet6: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet7: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet8: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet9: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet10: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet11: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet12: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet13: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet14: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    var bullet15: (ModelEntity & HasPhysicsBody) = ModelEntity() as (ModelEntity & HasCollision & HasPhysicsBody)
    
    // Bullets helpers (used and explained in Handletap function)
    var tapPoint = CGPoint.init()
    var origin =  SIMD3<Float>.init()
    var direction =  SIMD3<Float>.init()
    var size = SIMD3<Float>.init()
    var bulletShape: ShapeResource = ShapeResource.generateBox(size: [0.1,0.1,0.1])
    var kinematics = PhysicsBodyComponent.init()
    var raycasts = [CollisionCastHit].init()
    var raycastVal = [CollisionCastHit].init().first
    var motion = PhysicsMotionComponent.init()
    
    // Material for making the bullets transparent when needed
    var materialTransparent = UnlitMaterial(color: .blue)
    
    // Variables for the Anchor Model
    var modelPlaceholder: ModelEntity = ModelEntity()
    var textEntity: ModelEntity = ModelEntity()
    var box1: ModelEntity = ModelEntity()
    var box2: ModelEntity = ModelEntity()
    var box3: ModelEntity = ModelEntity()
    var box4: ModelEntity = ModelEntity()
    var box5: ModelEntity = ModelEntity()
    var box6: ModelEntity = ModelEntity()
    
    // MARK: Eliminated boxes not used in gameType = 2
    // var box7: ModelEntity = ModelEntity()
    // var box8: ModelEntity = ModelEntity()
    // var box9: ModelEntity = ModelEntity()
    
    var box10: ModelEntity = ModelEntity()
    var box11: ModelEntity = ModelEntity()
    var box12: ModelEntity = ModelEntity()
    var animationDefinition1: OrbitAnimation? = nil
    var animationResource1: AnimationResource? = nil
    var animationDefinition2: OrbitAnimation? = nil
    var animationResource2: AnimationResource? = nil
    var animationDefinition3: OrbitAnimation? = nil
    var animationResource3: AnimationResource? = nil
    var animationDefinition4: OrbitAnimation? = nil
    var animationResource4: AnimationResource? = nil
    var animationDefinition5: OrbitAnimation? = nil
    var animationResource5: AnimationResource? = nil
    var animationDefinition6: OrbitAnimation? = nil
    var animationResource6: AnimationResource? = nil
    
    // MARK: Eliminated boxes not used in gameType = 2
    // var animationDefinition7: OrbitAnimation? = nil
    // var animationResource7: AnimationResource? = nil
    // var animationDefinition8: OrbitAnimation? = nil
    // var animationResource8: AnimationResource? = nil
    // var animationDefinition9: OrbitAnimation? = nil
    // var animationResource9: AnimationResource? = nil
    
    var animationDefinition10: OrbitAnimation? = nil
    var animationResource10: AnimationResource? = nil
    var animationDefinition11: OrbitAnimation? = nil
    var animationResource11: AnimationResource? = nil
    var animationDefinition12: OrbitAnimation? = nil
    var animationResource12: AnimationResource? = nil
    let box1Material = SimpleMaterial(color: .red, isMetallic: false)
    let box2Material = SimpleMaterial(color: .blue, isMetallic: false)
    let box3Material = SimpleMaterial(color: .purple, isMetallic: false)
    let box4Material = SimpleMaterial(color: .yellow, isMetallic: false)
    let box5Material = SimpleMaterial(color: .orange, isMetallic: false)
    let box6Material = SimpleMaterial(color: .magenta, isMetallic: false)
    
    // MARK: Eliminated boxes not used in gameType = 2
    // let box7Material = SimpleMaterial(color: .cyan, isMetallic: false)
    // let box8Material = SimpleMaterial(color: .green, isMetallic: false)
    // let box9Material = SimpleMaterial(color: .red, isMetallic: false)
    
    let box10Material = SimpleMaterial(color: .blue, isMetallic: false)
    let box11Material = SimpleMaterial(color: .purple, isMetallic: false)
    let box12Material = SimpleMaterial(color: .magenta, isMetallic: false)
    
    let modelPlaceholderMaterial = SimpleMaterial(color: .black, isMetallic: false)
    
    // TODO: Remove Spheres
//    var sphere1: ModelEntity = ModelEntity()
//    var sphere2: ModelEntity = ModelEntity()
//    var sphere3: ModelEntity = ModelEntity()
//    var sphere4: ModelEntity = ModelEntity()
//    var sphere5: ModelEntity = ModelEntity()
//    var sphere6: ModelEntity = ModelEntity()
//    var sphere7: ModelEntity = ModelEntity()
//    var sphere8: ModelEntity = ModelEntity()
//    var sphere9: ModelEntity = ModelEntity()
//    var sphere10: ModelEntity = ModelEntity()
//    var sphere11: ModelEntity = ModelEntity()
//    var sphere12: ModelEntity = ModelEntity()
//    var sphere13: ModelEntity = ModelEntity()
//    var sphere14: ModelEntity = ModelEntity()
//    var sphere15: ModelEntity = ModelEntity()
//    var sphere16: ModelEntity = ModelEntity()
//    var sphere17: ModelEntity = ModelEntity()
//    var sphere18: ModelEntity = ModelEntity()
//    var sphere19: ModelEntity = ModelEntity()
//    var sphere20: ModelEntity = ModelEntity()
//    let completeBoxMaterial = UnlitMaterial(color: .systemPink)
    
    // MARK: CoreData context
    let context = DataBaseHandler.context

    func runCoachingOverlay() {
        guard let view = self.view else { return }

        let coachingOverlay = ARCoachingOverlayView(frame: view.frame)
        
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        view.addSubview(coachingOverlay)

        coachingOverlay.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        coachingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        coachingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        coachingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.activatesAutomatically = true

        coachingOverlay.session = arView.session
    }
    

    // Inits the bullets configurations
    
    // TODO: Changed gestures to only needed
    func initBullets() {
        bulletMaterial.color =  .init(tint: .green.withAlphaComponent(1), texture: nil)
        
        // Bullets that are transparent in case there's an error with the direction or scale
        materialTransparent.color =  .init(tint: .red.withAlphaComponent(0))
        
        // Creates the bullet as a model entity
        bullet1 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        // Gives the bullets the collision shape
        bullet1.generateCollisionShapes(recursive: true)
        bullet1.name = "bullet/1/"
        // Install the necessary configurations for allowing physics and collisions
        // self.arView.installGestures(.translation, for: bullet1)
        
        // Repeats for the other 14 bullets
        bullet2 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet2.generateCollisionShapes(recursive: true)
        bullet2.name = "bullet/2/"
        // self.arView.installGestures(.translation, for: bullet2)
        
        bullet3 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet3.generateCollisionShapes(recursive: true)
        bullet3.name = "bullet/3/"
        // self.arView.installGestures(.translation, for: bullet3)
        
        bullet4 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet4.generateCollisionShapes(recursive: true)
        bullet4.name = "bullet/4/"
        // self.arView.installGestures(.translation, for: bullet4)
        
        bullet5 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet5.generateCollisionShapes(recursive: true)
        bullet5.name = "bullet/5/"
        // self.arView.installGestures(.translation, for: bullet5)
        
        bullet6 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet6.generateCollisionShapes(recursive: true)
        bullet6.name = "bullet/6/"
        // self.arView.installGestures(.translation, for: bullet6)
        
        bullet7 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet7.generateCollisionShapes(recursive: true)
        bullet7.name = "bullet/7/"
        // self.arView.installGestures(.translation, for: bullet7)
        
        bullet8 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet8.generateCollisionShapes(recursive: true)
        bullet8.name = "bullet/8/"
        // self.arView.installGestures(.translation, for: bullet8)
        
        bullet9 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet9.generateCollisionShapes(recursive: true)
        bullet9.name = "bullet/9/"
        // self.arView.installGestures(.translation, for: bullet9)
        
        bullet10 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet10.generateCollisionShapes(recursive: true)
        bullet10.name = "bullet/10/"
        // self.arView.installGestures(.translation, for: bullet10)
        
        bullet11 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet11.generateCollisionShapes(recursive: true)
        bullet11.name = "bullet/11/"
        // self.arView.installGestures(.translation, for: bullet11)
        
        bullet12 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet12.generateCollisionShapes(recursive: true)
        bullet12.name = "bullet/12/"
        // self.arView.installGestures(.translation, for: bullet12)
        
        bullet13 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet13.generateCollisionShapes(recursive: true)
        bullet13.name = "bullet/13/"
        // self.arView.installGestures(.translation, for: bullet13)
        
        bullet14 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet14.generateCollisionShapes(recursive: true)
        bullet14.name = "bullet/14/"
        // self.arView.installGestures(.translation, for: bullet14)
        
        bullet15 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet15.generateCollisionShapes(recursive: true)
        bullet15.name = "bullet/15/"
        // self.arView.installGestures(.translation, for: bullet15)
        
        // Stores the current name of the bullet that is launched
        currBullet.name = bullet1.name
        
        // Add the anchirBullet to the scene for it to be the first anchor
        self.arView.scene.addAnchor(anchorBullet)
        
        // Collision Group
        boxMask = CollisionGroup.all.subtracting(sphereGroup)
    }
    
    func initAnimationsResource() {
        if(gameType == 1) {
            animationDefinition1 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.2,0.6)),
                    spinClockwise: false,
                    orientToPath: false,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat
            )
            animationResource1 = try! AnimationResource.generate(with: self.animationDefinition1!)
            
            
            animationDefinition3 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.2,0.6)),
                    spinClockwise: false,
                    orientToPath: false,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 3
                )
            animationResource3 = try! AnimationResource.generate(with: animationDefinition3!)
            
            
            animationDefinition4 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.2,0.6)),
                    spinClockwise: false,
                    orientToPath: false,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 6
                )
            animationResource4 = try! AnimationResource.generate(with: animationDefinition4!)
            

            animationDefinition2 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.40,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat
                )
            animationResource2 = try! AnimationResource.generate(with: animationDefinition2!)
            
            
            animationDefinition5 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.40,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 3
                )
            animationResource5 = try! AnimationResource.generate(with: animationDefinition5!)
            

            animationDefinition6 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.40,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 6
                )
            animationResource6 = try! AnimationResource.generate(with: animationDefinition6!)
            

            // MARK: Eliminated boxes not used in gameType = 2
            /*
            animationDefinition7 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.60,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat
                )
            animationResource7 = try! AnimationResource.generate(with: animationDefinition7!)
            

            animationDefinition8 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.60,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 3
                )
            animationResource8 = try! AnimationResource.generate(with: animationDefinition8!)
            
            
            animationDefinition9 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.60,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 6
                )
            animationResource9 = try! AnimationResource.generate(with: animationDefinition9!)
            */

            animationDefinition10 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.80,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat
                )
            animationResource10 = try! AnimationResource.generate(with: animationDefinition10!)
            
            
            animationDefinition11 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.80,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 3
                )
            animationResource11 = try! AnimationResource.generate(with: animationDefinition11!)
            
            
            // Animacion box12 giro
            animationDefinition12 = OrbitAnimation(
                duration: 9,
                axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                startTransform: Transform(
                    translation: simd_float3(0,0.80,0.6)),
                    spinClockwise: true,
                    orientToPath: true,
                    rotationCount: 100.0,
                bindTarget: .transform,
                repeatMode: .repeat,
                offset: 6
                )
            animationResource12 = try! AnimationResource.generate(with: animationDefinition12!)
        } else {
            if(gameType == 2) {
                animationDefinition1 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([2,2,1]),
                        translation: simd_float3(0,0.3,0.8)),
                        spinClockwise: false,
                        orientToPath: false,
                        rotationCount: 50.0,
                    bindTarget: .transform,
                    repeatMode: .repeat
                )
                animationResource1 = try! AnimationResource.generate(with: self.animationDefinition1!)
                
                
                animationDefinition3 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([2,2,1]),
                        translation: simd_float3(0,0.3,0.8)),
                        spinClockwise: false,
                        orientToPath: false,
                        rotationCount: 50,
                    bindTarget: .transform,
                    repeatMode: .repeat,
                    offset: 3
                    )
                animationResource3 = try! AnimationResource.generate(with: animationDefinition3!)
                
                
                animationDefinition4 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: 1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([2,2,1]),
                        translation: simd_float3(0,0.3,0.8)),
                        spinClockwise: false,
                        orientToPath: false,
                        rotationCount: 50,
                    bindTarget: .transform,
                    repeatMode: .repeat,
                    offset: 6
                    )
                animationResource4 = try! AnimationResource.generate(with: animationDefinition4!)
                

                animationDefinition2 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([1.6,1.6,1]),
                        translation: simd_float3(0,0.6,0.5)),
                        spinClockwise: true,
                        orientToPath: true,
                        rotationCount: 100.0,
                    bindTarget: .transform,
                    repeatMode: .repeat
                    )
                animationResource2 = try! AnimationResource.generate(with: animationDefinition2!)
                
                
                animationDefinition5 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([1.6,1.6,1]),
                        translation: simd_float3(0,0.6,0.5)),
                        spinClockwise: true,
                        orientToPath: true,
                        rotationCount: 100.0,
                    bindTarget: .transform,
                    repeatMode: .repeat,
                    offset: 3
                    )
                animationResource5 = try! AnimationResource.generate(with: animationDefinition5!)
                

                animationDefinition6 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([1.6,1.6,1]),
                        translation: simd_float3(0,0.6,0.5)),
                        spinClockwise: true,
                        orientToPath: true,
                        rotationCount: 100.0,
                    bindTarget: .transform,
                    repeatMode: .repeat,
                    offset: 6
                    )
                animationResource6 = try! AnimationResource.generate(with: animationDefinition6!)
                

                animationDefinition10 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([2,2,1]),
                        translation: simd_float3(0,0.9,0.7)),
                        spinClockwise: true,
                        orientToPath: true,
                        rotationCount: 100.0,
                    bindTarget: .transform,
                    repeatMode: .repeat
                    )
                animationResource10 = try! AnimationResource.generate(with: animationDefinition10!)
                
                
                animationDefinition11 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([2,2,1]),
                        translation: simd_float3(0,0.9,0.7)),
                        spinClockwise: true,
                        orientToPath: true,
                        rotationCount: 100.0,
                    bindTarget: .transform,
                    repeatMode: .repeat,
                    offset: 3
                    )
                animationResource11 = try! AnimationResource.generate(with: animationDefinition11!)
                
                
                // Animacion box12 giro
                animationDefinition12 = OrbitAnimation(
                    duration: 9,
                    axis: SIMD3<Float>(x: 0, y: -1, z: 0),
                    startTransform: Transform(
                        scale: SIMD3([2,2,1]),
                        translation: simd_float3(0,0.9,0.7)),
                        spinClockwise: true,
                        orientToPath: true,
                        rotationCount: 100.0,
                    bindTarget: .transform,
                    repeatMode: .repeat,
                    offset: 6
                    )
                animationResource12 = try! AnimationResource.generate(with: animationDefinition12!)
                
            } else {
                box1.setPosition(SIMD3([0.5,1.2,0.6]), relativeTo: nil)
                box1.setScale(SIMD3([2,2,0.2]), relativeTo: nil)
                
                box2.setPosition(SIMD3([0,1.4,-0.6]), relativeTo: nil)
                box2.setScale(SIMD3([1.6,1.6,0.2]), relativeTo: nil)
                
                box3.setPosition(SIMD3([-0.5,1.3,0.6]), relativeTo: nil)
                box3.setScale(SIMD3([1.8,1.8,0.2]), relativeTo: nil)
                
                box4.setPosition(SIMD3([0,0.8,0.6]), relativeTo: nil)
                box4.setScale(SIMD3([1.5,1.5,0.2]), relativeTo: nil)
                
                box5.setPosition(SIMD3([-0.8,0.9,0.3]), relativeTo: nil)
                box5.setScale(SIMD3([1.9,1.9,0.2]), relativeTo: nil)
                
                box6.setPosition(SIMD3([0.9,0.7,-0.3]), relativeTo: nil)
                box6.setScale(SIMD3([1.4,1.4,0.2]), relativeTo: nil)
                
                
                // MARK: Eliminated boxes not used in gameType = 2
                // box7.setPosition(SIMD3([1,0.5,0.5]), relativeTo: nil)
                // box7.setScale(SIMD3([2.3,2.3,0.2]), relativeTo: nil)
                
                // box8.setPosition(SIMD3([0.2,0.4,1]), relativeTo: nil)
                // box8.setScale(SIMD3([2.5,2.5,0.2]), relativeTo: nil)
                
                // box9.setPosition(SIMD3([-0.8,0.2,-0.3]), relativeTo: nil)
                // box9.setScale(SIMD3([2.7,2.7,0.2]), relativeTo: nil)
                
                box10.setPosition(SIMD3([-1,0.4,0.6]), relativeTo: nil)
                box10.setScale(SIMD3([1.4,1.4,0.2]), relativeTo: nil)
                
                box11.setPosition(SIMD3([1.0,1.6,0.3]), relativeTo: nil)
                box11.setScale(SIMD3([2.8,2.8,0.2]), relativeTo: nil)
                
                box12.setPosition(SIMD3([-0.9,1.7,-0.3]), relativeTo: nil)
                box12.setScale(SIMD3([2.6,2.6,0.2]), relativeTo: nil)
            }
        }
    }
    
    func initLight() {
        pointLightFront = CustomPointLight()
        pointLightBack = CustomPointLight()
        pointLightFront.setPosition([0,2,1.5], relativeTo: nil)
        pointLightBack.setPosition([0,2,-1.5], relativeTo: nil)
    }
    
    // TODO: Changed gestures to only needed
    func initBoxes() {

        // Box - 1 Collision
        box1 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box1Material])
        box1.generateCollisionShapes(recursive: true)
        box1.collision = CollisionComponent(shapes: [.generateBox(width: 0.15, height: 0.15, depth: 0.02)], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box1.name = "box/1/"
        // self.arView.installGestures(.translation, for: box1)
        
        // Box - 2 Collision
        box2 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box2Material])
        box2.generateCollisionShapes(recursive: true)
        box2.collision = CollisionComponent(shapes: [.generateBox(width: 0.15, height: 0.15, depth: 0.02)], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box2.name = "box/2/"
        // self.arView.installGestures(.translation, for: box2)
        
        // Box - 3 Collision
        box3 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box3Material])
        box3.generateCollisionShapes(recursive: true)
        box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box3.name = "box/3/"
        // self.arView.installGestures(.translation, for: box3)
        
        // Box - 4 Collision
        box4 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box4Material])
        box4.generateCollisionShapes(recursive: true)
        box4.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box4.name = "box/4/"
        // self.arView.installGestures(.translation, for: box4)

        // Box - 5 Collision
        box5 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box5Material])
        box5.generateCollisionShapes(recursive: true)
        box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box5.name = "box/5/"
        // self.arView.installGestures(.translation, for: box5)
        
        // Box - 6 Collision
        box6 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box6Material])
        box6.generateCollisionShapes(recursive: true)
        box6.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box6.name = "box/6/"
        // self.arView.installGestures(.translation, for: box6)
        
        // MARK: Eliminated not used boxes in gameType = 2
        // Box - 7 Collision
        // box7 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box7Material])
        // box7.generateCollisionShapes(recursive: true)
        // box7.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        // box7.name = "box/7/"
        // self.arView.installGestures(.translation, for: box7)
        
        
        // Box - 8 Collision
        // box8 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box8Material])
        // box8.generateCollisionShapes(recursive: true)
        // box8.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        // box8.name = "box/8/"
        // self.arView.installGestures(.translation, for: box8)
        
        
        // Box - 9 Collision
        // box9 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box9Material])
        // box9.generateCollisionShapes(recursive: true)
        // box9.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        // box9.name = "box/9/"
        // self.arView.installGestures(.translation, for: box9)
        
        
        // Box - 10 Collision
        box10 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box10Material])
        box10.generateCollisionShapes(recursive: true)
        box10.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box10.name = "box/10/"
        // self.arView.installGestures(.translation, for: box10)
        
        
        // Box - 11 Collision
        box11 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box11Material])
        box11.generateCollisionShapes(recursive: true)
        box11.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box11.name = "box/11/"
        // self.arView.installGestures(.translation, for: box11)

        
        // Box - 12 Collision
        box12 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box12Material])
        box12.generateCollisionShapes(recursive: true)
        box12.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box12.name = "box/12/"
        // self.arView.installGestures(.translation, for: box12)
        
        
        modelPlaceholder = ModelEntity(mesh: MeshResource.generateBox(width: 0.6, height: 1.1 , depth: 0.4), materials: [self.modelPlaceholderMaterial])
    }
    
    // Remove animation for box on collision with a Bullet
    func animate(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        // Remove the cube after 4 seconds
        let timer1 = CustomTimer { (seconds) in
            if(seconds == 1) {
                if(self.arView.scene.anchors.count == 2) {
                    self.arView.scene.anchors[1].removeChild(entity)
                }
            }
        }
        timer1.start()

        guard loop == true else { return }
        animUpdateSubscriptions.append(self.arView.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity)
        { _ in
            self.animate(entity: entity, angle: angle, axis: axis, duration: duration, loop: loop, currentPosition: currentPosition)
        })
    }
    
    // Remove animation for box on collision with a Bullet
    var transform: Transform = Transform.init()
    func animateModel(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        
        transform = entity.transform
        transform.rotation *= simd_quatf(angle: angle, axis: axis)
        transform.scale.x = 0.05
        transform.scale.y = 0.05
        transform.scale.z = 0.05
        entity.move(to: transform,
                    relativeTo: entity,
                        duration: duration)

        guard loop == true else { return }
        animUpdateSubscriptions.append(self.arView.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity)
        { _ in
            self.animateModel(entity: entity, angle: angle, axis: axis, duration: duration, loop: loop, currentPosition: currentPosition)
        })
    }
    
    // TODO: Remove Spheres
    // Places the boxes after completing a floor
//    func placeBoxesAfterCompletition() {
//        sphere1 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere2 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere3 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere4 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere5 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere6 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere7 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere8 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere9 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere10 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere11 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere12 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere13 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere14 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere15 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere16 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere17 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere18 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere19 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere20 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.05), materials: [completeBoxMaterial])
//        sphere1.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere2.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere3.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere4.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere5.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere6.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere7.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere8.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere9.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere10.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere11.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere12.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere13.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere14.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere15.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere16.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere17.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere18.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere19.setPosition(SIMD3([Float.random(in: -3..<3), Float.random(in: 0..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//        sphere20.setPosition(SIMD3([Float.random(in: -2..<2), Float.random(in: 0.2..<3), Float.random(in: -3..<3)]), relativeTo: nil)
//    }
    
    // Function to init the collision detection with Subscription
    func initCollisionDetection() {
        // Subscription for collision
        collisionSubscriptions.append(self.arView.scene.subscribe(to: CollisionEvents.Began.self) { event in
            // Entity1 and Entity2 could be either a box or a bullet (even a bullet and a bullet collision)
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
            
            print(self.arrayObjetos)
            // Substrings of the object's name to check whether is a box or bullet, and the corresponding number
            var entityName = entity1.name
            var typeIndex = entityName.firstIndex(of: "/")!
            var lastIndex = entityName.lastIndex(of: "/")!
            var entityType = entityName[...typeIndex] // Type of the object "box" or "bullet"
            var entityId = entityName[typeIndex...lastIndex]
            var entityReal = Int(String(entityId[1])) ?? 0 // Int of the Object -> "box/1/" -> 1
            
            // Check if the number has more than one digit
            if(entityId[2] != "/") {
                entityReal = Int(String("\(entityId[1])\(entityId[2])")) ?? 0 // Int of the Object -> "box/1/" -> 1
            }
            
            // If the entity1 is a box
            if (entityType == "box/") {
                // Makes the model white like an animation
                entity1.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
                // Stops orbit animation
                entity1.stopAllAnimations()
                // Call the animate function to remove the box from the scene
                self.animate(entity: entity1, angle: .pi, axis: [0, 1, 0], duration: 1, loop: false, currentPosition: entity1.position)
                
                self.arrayObjetos[entityReal - 1] = true
            // Repeats the previous code in case the entity2 is the box
            } else {
                // Substrings of the object's name
                entityName = entity2.name
                typeIndex = entityName.firstIndex(of: "/")!
                lastIndex = entityName.lastIndex(of: "/")!
                entityType = entityName[...typeIndex] // Type of the object "box" or "bullet"
                if(entityType == "box/") {
                    entity2.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
                    entityId = entityName[typeIndex...lastIndex]
                    entityReal = Int(String(entityId[1])) ?? 0 // Int of the Object -> "box/1/" -> 1
                    
                    if(entityId[2] != "/") {
                        entityReal = Int(String("\(entityId[1])\(entityId[2])")) ?? 0 // Int of the Object -> "box/1/" -> 1
                    }
                    
                    self.animate(entity: entity2, angle: .pi, axis: [0, 1, 0], duration: 1, loop: false, currentPosition: entity2.position)
                    self.arrayObjetos[entityReal - 1] = true
                }
            }
            
            self.winGame()
        })
    }
    
    // Function to generate the Text entity that goes with the USDZ of the Obra
    func textGen(textString: String) -> ModelEntity {
        let materialVar = SimpleMaterial(color: .white, roughness: 0, isMetallic: false)
        let depthVar: Float = 0.01
        let fontVar = UIFont.systemFont(ofSize: 0.2)
        let containerFrameVar = CGRect(x: -1, y: -0.5, width: 2, height: 1)
        let alignmentVar: CTTextAlignment = .center
        let lineBreakModeVar : CTLineBreakMode = .byWordWrapping
        let textMeshResource : MeshResource = .generateText(textString,
                                               extrusionDepth: depthVar,
                                               font: fontVar,
                                               containerFrame: containerFrameVar,
                                               alignment: alignmentVar,
                                               lineBreakMode: lineBreakModeVar)
        let textEntity = ModelEntity(mesh: textMeshResource, materials: [materialVar])
        return textEntity
    }
    
    
    // Handle tap to shot the bullets
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        guard let view = self.view else { return }
        
        tapPoint = recognizer.location(in: view)
        // Throw ball location - direction
        (origin, direction) = self.arView.ray(through: tapPoint) ?? (SIMD3<Float>([0,0,0]), SIMD3<Float>([0,0,0]))

        // Throw ball location - direction
        raycasts = self.arView.scene.raycast(origin: origin, direction: direction, length: 50, query: .any, mask: .default, relativeTo: nil)
        
        // Collission component
        bulletShape = ShapeResource.generateSphere(radius: 0.02)
        
        // Add physics linear velocity
        kinematics = .init(massProperties: .default,material: nil,mode: .kinematic)
        
        if let raycastVal = raycasts.first {
            if(raycastVal.normal[0] == 0.0 || raycastVal.normal[1] == 0.0 || raycastVal.normal[2] == 0.0) {
                motion = .init(linearVelocity: [0,0,0],angularVelocity: [0, 0, 0])
                currBullet.position = origin
                
                
                // TODO: FIX TO AVOID USING LARGE IF STATEMENT
                if(self.currBullet.name == "bullet/1/") {
                    bullet1.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet1.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/2/") {
                    bullet2.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet2.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/3/") {
                    bullet3.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet3.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/4/") {
                    bullet4.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet4.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/5/") {
                    bullet5.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet5.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/6/") {
                    bullet6.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet6.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/7/") {
                    bullet7.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet7.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/8/") {
                    bullet8.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet8.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/9/") {
                    bullet9.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet9.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/10/") {
                    bullet10.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet10.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/11/") {
                    bullet11.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet11.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/12/") {
                    bullet12.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet12.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/13/") {
                    bullet13.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet13.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/14/") {
                    bullet14.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet14.model?.materials = [materialTransparent]
                } else if (self.currBullet.name == "bullet/15/") {
                    bullet15.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                    bullet15.model?.materials = [materialTransparent]
                }
            } else {
                motion = .init(linearVelocity: [-raycastVal.normal[0]*2, -raycastVal.normal[1]*2,-raycastVal.normal[2]*2],angularVelocity: [0, 0, 0])
                
                // TODO: FIX TO AVOID USING LARGE IF STATEMENT
                if(self.currBullet.name == "bullet/1/") {
                    bullet1.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet1.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/2/") {
                    bullet2.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet2.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/3/") {
                    bullet3.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet3.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/4/") {
                    bullet4.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet4.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/5/") {
                    bullet5.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet5.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/6/") {
                    bullet6.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet6.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/7/") {
                    bullet7.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet7.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/8/") {
                    bullet8.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet8.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/9/") {
                    bullet9.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet9.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/10/") {
                    bullet10.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet10.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/11/") {
                    bullet11.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet11.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/12/") {
                    bullet12.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet12.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/13/") {
                    bullet13.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet13.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/14/") {
                    bullet14.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet14.model?.materials = [bulletMaterial]
                } else if (self.currBullet.name == "bullet/15/") {
                    bullet15.setScale(SIMD3<Float>([1,1,1]), relativeTo: nil)
                    bullet15.model?.materials = [bulletMaterial]
                }
            }
        } else {
            raycasts = []
            motion = .init(linearVelocity: [0,0,0] ,angularVelocity: [0, 0, 0])
            currBullet.position = origin
            
            // TODO: FIX TO AVOID USING LARGE IF STATEMENT
            if(self.currBullet.name == "bullet/1/") {
                bullet1.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet1.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/2/") {
                bullet2.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet2.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/3/") {
                bullet3.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet3.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/4/") {
                bullet4.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet4.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/5/") {
                bullet5.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet5.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/6/") {
                bullet6.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet6.model?.materials = [materialTransparent]
        } else if (self.currBullet.name == "bullet/7/") {
                bullet7.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet7.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/8/") {
                bullet8.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet8.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/9/") {
                bullet9.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet9.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/10/") {
                bullet10.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet10.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/11/") {
                bullet11.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet11.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/12/") {
                bullet12.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet12.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/13/") {
                bullet13.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet13.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/14/") {
                bullet14.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet14.model?.materials = [materialTransparent]
            } else if (self.currBullet.name == "bullet/15/") {
                bullet15.setScale(SIMD3<Float>([20,20,20]), relativeTo: nil)
                bullet15.model?.materials = [materialTransparent]
            }
        }
        
        if(self.currBullet.name == "bullet/1/") {
            bullet1.position = origin
            bullet1.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter:.init(group: boxGroup, mask: boxMask))
                bullet1.components.set(kinematics)
                bullet1.components.set(motion)
                
                self.anchorBullet.addChild(self.bullet1)
                self.currBullet.name = "bullet/2/"
                
        } else if (self.currBullet.name == "bullet/2/") {
            bullet2.position = origin
            bullet2.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet2.components.set(kinematics)
            bullet2.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet2)
            self.currBullet.name = "bullet/3/"
                
        } else if (self.currBullet.name == "bullet/3/") {
            bullet3.position = origin
            bullet3.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet3.components.set(kinematics)
            bullet3.components.set(motion)
                
            self.anchorBullet.addChild(self.bullet3)
            self.currBullet.name = "bullet/4/"
                
        } else if (self.currBullet.name == "bullet/4/") {
            bullet4.position = origin
            bullet4.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet4.components.set(kinematics)
            bullet4.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet4)
            self.currBullet.name = "bullet/5/"
                
        } else if (self.currBullet.name == "bullet/5/") {
            bullet5.position = origin
            bullet5.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet5.components.set(kinematics)
            bullet5.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet5)
            self.currBullet.name = "bullet/6/"
            
        } else if (self.currBullet.name == "bullet/6/") {
            bullet6.position = origin
            bullet6.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet6.components.set(kinematics)
            bullet6.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet6)
            self.currBullet.name = "bullet/7/"
            
        } else if (self.currBullet.name == "bullet/7/") {
            bullet7.position = origin
            bullet7.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet7.components.set(kinematics)
            bullet7.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet7)
            self.currBullet.name = "bullet/8/"
            
        } else if (self.currBullet.name == "bullet/8/") {
            bullet8.position = origin
            bullet8.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet8.components.set(kinematics)
            bullet8.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet8)
            self.currBullet.name = "bullet/9/"
            
        } else if (self.currBullet.name == "bullet/9/") {
            bullet9.position = origin
            bullet9.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet9.components.set(kinematics)
            bullet9.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet9)
            self.currBullet.name = "bullet/10/"
            
        } else if (self.currBullet.name == "bullet/10/") {
            bullet10.position = origin
            bullet10.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet10.components.set(kinematics)
            bullet10.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet10)
            self.currBullet.name = "bullet/11/"
            
        } else if (self.currBullet.name == "bullet/11/") {
            bullet11.position = origin
            bullet11.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet11.components.set(kinematics)
            bullet11.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet11)
            self.currBullet.name = "bullet/12/"
            
        } else if (self.currBullet.name == "bullet/12/") {
            bullet12.position = origin
            bullet12.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet12.components.set(kinematics)
            bullet12.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet12)
            self.currBullet.name = "bullet/13/"
            
        } else if (self.currBullet.name == "bullet/13/") {
            bullet13.position = origin
            bullet13.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet13.components.set(kinematics)
            bullet13.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet13)
            self.currBullet.name = "bullet/14/"
            
        } else if (self.currBullet.name == "bullet/14/") {
            bullet14.position = origin
            bullet14.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet14.components.set(kinematics)
            bullet14.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet14)
            self.currBullet.name = "bullet/15/"
            
        } else if (self.currBullet.name == "bullet/15/") {
            bullet15.position = origin
            bullet15.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
            bullet15.components.set(kinematics)
            bullet15.components.set(motion)
            
            self.anchorBullet.addChild(self.bullet15)
            self.currBullet.name = "bullet/1/"
        }
    }
    
    func winGame() {
        // Se completa el juego actual
        if(!self.arrayObjetos.contains(false) && currModel.completed == false) {
            self.modelPlaceholder.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
            self.animateModel(entity: self.modelPlaceholder, angle: .pi, axis:  [0, 1, 0], duration: 4, loop: false, currentPosition: self.modelPlaceholder.position)
            
            // OPTIONAL: Show pink spheres in scene
            // Places completed boxes
            if(self.arView.scene.anchors.count == 2) {
                // TODO: Remove Spheres
//                self.placeBoxesAfterCompletition()
//                self.arView.scene.anchors[1].addChild(self.sphere1)
//                self.arView.scene.anchors[1].addChild(self.sphere2)
//                self.arView.scene.anchors[1].addChild(self.sphere3)
//                self.arView.scene.anchors[1].addChild(self.sphere4)
//                self.arView.scene.anchors[1].addChild(self.sphere5)
//                self.arView.scene.anchors[1].addChild(self.sphere6)
//                self.arView.scene.anchors[1].addChild(self.sphere7)
//                self.arView.scene.anchors[1].addChild(self.sphere8)
//                self.arView.scene.anchors[1].addChild(self.sphere9)
//                self.arView.scene.anchors[1].addChild(self.sphere10)
//                self.arView.scene.anchors[1].addChild(self.sphere11)
//                self.arView.scene.anchors[1].addChild(self.sphere12)
//                self.arView.scene.anchors[1].addChild(self.sphere13)
//                self.arView.scene.anchors[1].addChild(self.sphere14)
//                self.arView.scene.anchors[1].addChild(self.sphere15)
//                self.arView.scene.anchors[1].addChild(self.sphere16)
//                self.arView.scene.anchors[1].addChild(self.sphere17)
//                self.arView.scene.anchors[1].addChild(self.sphere18)
//                self.arView.scene.anchors[1].addChild(self.sphere19)
//                self.arView.scene.anchors[1].addChild(self.sphere20)
                        
                if(currModel.completed == false) {
                    currModel.completed = true
                    self.progresoActual = self.progresoActual + 1
                    
                    network.currentProgress += 0.1
                    network.currentProgressInt = self.progresoActual
                    
                    if(locationCount < network.models.count) {
                        self.load(location: network.locations[self.locationCount])
                    } else {
                        print("JUEGO COMPLETADO")
                    }
                    
                }
            }
                    
                    
            let modeloFile = URL(string: currModel.modelo)!
            newEntityPirinola = ModelEntity.loadModelAsync(contentsOf: modeloFile)
                .sink { loadCompletion in
                    if case let .failure(error) = loadCompletion {
                        print("Unable to load model \(error)")
                    }
                    self.newEntityPirinola?.cancel()
                } receiveValue: { newEntity in
                    newEntity.setPosition(SIMD3(x: 0, y: 0.6, z: 0), relativeTo: nil)
                    newEntity.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: newEntity)
                    print("se carga con exito")
                    

                    for (index, currObra) in self.network.models.enumerated() {
                        if(currObra._id == self.currModel._id) {
                            self.network.models[index].completed = true
                        }
                    }
                    
                    ARViewController.completed.currModel = self.currModel
                    ARViewController.completed.currSheet = true
                    ARViewController.completed.progresoActual = ARViewController.completed.progresoActual + 1
                    
                    // MARK: - Save current obra in CoreData after completition
                    let newObra = ObraEntity(context: self.context)
                    newObra.id = self.currModel._id
                    newObra.nombre = self.currModel.nombre
                    newObra.autor = self.currModel.autor
                    newObra.descripcion = self.currModel.descripcion
                    newObra.modelo = self.currModel.modelo
                    newObra.zona = self.currModel.zona
                    newObra.completed = true
                    DataBaseHandler.saveContext()
                    
                    // Change black entity for new model Entity
                    if(self.arView.scene.anchors.count == 2) {
                        self.arView.scene.anchors[1].removeChild(self.modelPlaceholder)
                        self.arView.scene.anchors[1].addChild(newEntity)
                    }
                }
            
        }
    }
    
    func removePreviousContent() {
        if(self.arView.scene.anchors.count == 2) {
            self.arView.scene.anchors[1].removeChild(textEntity)
            self.arView.scene.anchors[1].removeChild(box1)
            self.arView.scene.anchors[1].removeChild(box2)
            self.arView.scene.anchors[1].removeChild(box3)
            self.arView.scene.anchors[1].removeChild(box4)
            self.arView.scene.anchors[1].removeChild(box5)
            self.arView.scene.anchors[1].removeChild(box6)
            
            // MARK: Eliminated boxes not used in gameType = 2
            // self.arView.scene.anchors[1].removeChild(box7)
            // self.arView.scene.anchors[1].removeChild(box8)
            // self.arView.scene.anchors[1].removeChild(box9)
            
            self.arView.scene.anchors[1].removeChild(box10)
            self.arView.scene.anchors[1].removeChild(box11)
            self.arView.scene.anchors[1].removeChild(box12)
            self.arView.scene.anchors[1].removeChild(pointLightBack)
            self.arView.scene.anchors[1].removeChild(pointLightFront)
            print("se ejecuta el remove")
            self.arView.scene.anchors[1].removeChild(modelPlaceholder)
            // view.scene.anchors[1].removeChild(newEntity)
            
            for currModels in anchor.children {
                anchor.removeChild(currModels)
            }
        }
        // Remove the actual anchor after removing the childs
        self.arView.scene.removeAnchor(anchor)
    }
    
    func showMarcoModel(currentObra: Obra, gameType: Int) {
        currModel = currentObra
        self.gameType = gameType
        initAnimationsResource()
        arrayObjetos = [false, false, false, false, false, false, true, true, true, false, false, false]
            
        modelPlaceholder.setPosition(SIMD3(x: 0, y: 0.4, z: 0), relativeTo: nil)
        if (currModel.completed == false) {
            modelPlaceholder.stopAllAnimations(recursive: true)
            if(modelPlaceholder.scale.x < 0.8) {
                modelPlaceholder.scale.x = 1
                modelPlaceholder.scale.y = 1
                modelPlaceholder.scale.z = 1
                self.modelPlaceholder.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
            }
            anchor.addChild(modelPlaceholder)
        }
                
        
        
        // Shows the text of the current Obra
        textEntity = textGen(textString: currentObra.nombre)
        if(UIDevice.current.model == "iPhone") {
            textEntity.setPosition(SIMD3(x: 0.0, y: 0.8, z: 0.0), relativeTo: nil)
        } else {
            textEntity.setPosition(SIMD3(x: 0.0, y: -0.2, z: 0.0), relativeTo: nil)
        }
        anchor.addChild(textEntity)
                
        // Adds materials to the boxes
        box1.model?.materials = [box1Material]
        box2.model?.materials = [box2Material]
        box3.model?.materials = [box3Material]
        box4.model?.materials = [box4Material]
        box5.model?.materials = [box5Material]
        box6.model?.materials = [box6Material]
        
        // MARK: Elimininated boxes not used in gameType = 2
        // box7.model?.materials = [box7Material]
        // box8.model?.materials = [box8Material]
        // box9.model?.materials = [box9Material]
        
        box10.model?.materials = [box10Material]
        box11.model?.materials = [box11Material]
        box12.model?.materials = [box12Material]
                

        if(currModel.completed == false) {
            if(self.arrayObjetos[0] == false) {
                anchor.addChild(box1)
            }
            if(self.arrayObjetos[1] == false) {
                anchor.addChild(box2)
            }
            if(self.arrayObjetos[2] == false) {
                anchor.addChild(box3)
            }
            if(self.arrayObjetos[3] == false) {
                anchor.addChild(box4)
            }
            if(self.arrayObjetos[4] == false) {
                anchor.addChild(box5)
            }
            if(self.arrayObjetos[5] == false) {
                anchor.addChild(box6)
            }
            
            // MARK: Eliminated boxes not used in gameType = 2
            // if(self.arrayObjetos[6] == false) {
            //     anchor.addChild(box7)
            // }
            // if(self.arrayObjetos[7] == false) {
            //     anchor.addChild(box8)
            // }
            // if(self.arrayObjetos[8] == false) {
            //    anchor.addChild(box9)
            // }
            if(self.arrayObjetos[9] == false) {
                anchor.addChild(box10)
            }
            if(self.arrayObjetos[10] == false) {
                anchor.addChild(box11)
            }
            if(self.arrayObjetos[11] == false) {
                anchor.addChild(box12)
            }
        }
        
        // Add custom Light
        anchor.addChild(pointLightFront)
        anchor.addChild(pointLightBack)
                
        // Add the anchor to the scene
        anchor.move(to: Transform(translation: simd_float3(0,0,-1)), relativeTo: nil)
        self.arView.scene.addAnchor(anchor)
        
        
        // Play the orbiting animations
        if(gameType == 1) {
            box1.playAnimation(animationResource1!)
            box3.playAnimation(animationResource3!)
            box4.playAnimation(animationResource4!)
            box2.playAnimation(animationResource2!)
            box5.playAnimation(animationResource5!)
            box6.playAnimation(animationResource6!)
            
            // MARK: Eliminated boxes not used in gameType = 2
            // box7.playAnimation(animationResource7!)
            // box8.playAnimation(animationResource8!)
            // box9.playAnimation(animationResource9!)
            
            box10.playAnimation(animationResource10!)
            box11.playAnimation(animationResource11!)
            box12.playAnimation(animationResource12!)
        }
                
        if(gameType == 2 ) {
            box1.playAnimation(animationResource1!)
            box3.playAnimation(animationResource3!)
            box4.playAnimation(animationResource4!)
            box2.playAnimation(animationResource2!)
            box5.playAnimation(animationResource5!)
            box6.playAnimation(animationResource6!)
            box10.playAnimation(animationResource10!)
            box11.playAnimation(animationResource11!)
            box12.playAnimation(animationResource12!)
        }
    }
}


class CustomPointLight: Entity, HasPointLight {
    required init() {
        super.init()
        
        self.light = PointLightComponent(color: .white, intensity: 35000, attenuationRadius: 10.0)
    }
}

// Timer
class CustomTimer {
    typealias Update = (Int)->Void
    var timer:Timer?
    var count: Int = 0
    var update: Update?

    init(update:@escaping Update){
        self.update = update
    }
    func start(){
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(timerUpdate), userInfo: nil, repeats: true)
    }
    func stop(){
        if let timer = timer {
            timer.invalidate()
        }
    }


    @objc func timerUpdate() {
        count += 1;
        if let update = update {
            update(count)
        }
        if (count == 4) {
            stop()
        }
    }

}

extension UIImageView {
    
    func imageFromServerURL(_ URLString: String, placeHolder: UIImage?) {
        self.image = nil
        let imageServerUrl = URLString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let url = URL(string: imageServerUrl) {
            URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
                if error != nil {
                    print("ERROR LOADING IMAGES FROM URL: \(String(describing: error))")
                    DispatchQueue.main.async {
                        self.image = placeHolder
                    }
                    return
                }
                DispatchQueue.main.async {
                    if let data = data {
                        if let downloadedImage = UIImage(data: data) {
                            self.image = downloadedImage
                        }
                    }
                }
            }).resume()
        }
    }
    
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

extension Int {
    func times(_ f: () -> ()) {
        if self > 0 {
            for _ in 0..<self {
                f()
            }
        }
    }
    
    func times(_ f: @autoclosure () -> ()) {
        if self > 0 {
            for _ in 0..<self {
                f()
            }
        }
    }
}

#endif
