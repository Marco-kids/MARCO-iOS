//
//  Coordinator.swift
//  MARCO-iOS
//
//  Created by Jose Castillo on 4/7/22.
//
import Foundation
import ARKit
import RealityKit
import Combine
import SwiftUI


class Coordinator: NSObject, ARSessionDelegate, ObservableObject {
    
    weak var view: ARView?
    var collisionSubscriptions = [Cancellable]()
    
    // Obras/models from the API
    var models: [Obra] = []
    var rutas: [URL] = []
    // Checks if the obras/models are already loaded (to avoid loading more than once)
    var modelsLoaded = false
    // Array of zonas in the MARCO
    var zonas: Array<(name: String, latMin: Double, latMax: Double, lonMin: Double, lonMax: Double)> = [
        ("Zona E", 25.65000, 25.7000, -100.26000, -100.25000), // Tec biblio 1
        ("Zona B", 25.60008, 25.6600, -100.29169, -100.28800), // Salon Swift
        ("Zona A", 25.65000, 25.66000, -100.26000, -100.25000), // Mi casita
        ("Zona C", 25.65700, 25.658700, -100.26000, -100.25000), // Piso abajo 1
        ("Zona D", 25.6587001, 25.66700, -100.26000, -100.25000), // Piso abajo 2
        ("Zona G", 25.00000, 25.4999, -100.26000, -100.25000), // Tec biblio 2
        
       //  ("Zona G", 25.650051, 25.70000, -100.29169, -100.28800) // Salon Swift 2
    ]
    // index of the current zona in the array, it has to match the models[Obra] based on the index
    var currZona = 0
    
    // Variable for loading asynchronous models
    var newEntityPirinola: AnyCancellable?
    var newEntity: Entity = ModelEntity()
    
    // Variable para saber si ya se capturaron todos los cubitos
    static let completed = Coordinator()
    var complete = false
    
    // Grupos para detectar colisiones
    let boxGroup = CollisionGroup(rawValue: 1 << 0)
    let sphereGroup = CollisionGroup(rawValue: 1 << 1)
    
    // Masks para detectar colisiones
    var boxMask: CollisionGroup = .init()
    var sphereMask: CollisionGroup = .init()
    
    // Array para definir cuando se ha completado una Zona
    // TODO: Replicar para el numero de zonas
    var arrayObjetos = [
        [false, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false],
        [false, false, false, false, false, false, false, false, false, false, false, false],
    ]
    // Array para saber cuando se ha completado cada zona independientemente, cuando se completa este array, se gana el juego
    var arrayNombreObrasCompletadas: [String] = []
    var arrayRunOnce = [false, false, false, false] // Anadir un campo adicional por cada zona
    var progresoActual = 0
    
    // Anchor para los modelos
    let anchor = AnchorEntity(plane: .horizontal, classification: .floor) // Production
    //  let anchor = AnchorEntity(plane: .horizontal) // For testing puposes
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
    var box7: ModelEntity = ModelEntity()
    var box8: ModelEntity = ModelEntity()
    var box9: ModelEntity = ModelEntity()
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
    var animationDefinition7: OrbitAnimation? = nil
    var animationResource7: AnimationResource? = nil
    var animationDefinition8: OrbitAnimation? = nil
    var animationResource8: AnimationResource? = nil
    var animationDefinition9: OrbitAnimation? = nil
    var animationResource9: AnimationResource? = nil
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
    let box7Material = SimpleMaterial(color: .cyan, isMetallic: false)
    let box8Material = SimpleMaterial(color: .green, isMetallic: false)
    let box9Material = SimpleMaterial(color: .red, isMetallic: false)
    let box10Material = SimpleMaterial(color: .blue, isMetallic: false)
    let box11Material = SimpleMaterial(color: .purple, isMetallic: false)
    let box12Material = SimpleMaterial(color: .magenta, isMetallic: false)

    // Inits the information from the API to the models variable with the Obras loaded
    func initModelsData(newObras: [Obra]) {
        if(!newObras.isEmpty && modelsLoaded == false) {
            models = newObras
            modelsLoaded = true
        }
        
    }
    
    func initRutasData(newRutas: [URL]) {
        if(rutas.count != models.count) {
            rutas = newRutas
            print("rutas: ")
            print(rutas)
        }
    }
    
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

        coachingOverlay.session = view.session
    }
    


    // Inits the bullets configurations
    func initBullets() {
        guard let view = self.view else { return }
        bulletMaterial.color =  .init(tint: .green.withAlphaComponent(1), texture: nil)
        
        // Bullets that are transparent in case there's an error with the direction or scale
        materialTransparent.color =  .init(tint: .red.withAlphaComponent(0))
        
        // Creates the bullet as a model entity
        bullet1 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        // Gives the bullets the collision shape
        bullet1.generateCollisionShapes(recursive: true)
        bullet1.name = "bullet/1/"
        // Install the necessary configurations for allowing physics and collisions
        view.installGestures(.all, for: bullet1)
        
        // Repeats for the other 14 bullets
        bullet2 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet2.generateCollisionShapes(recursive: true)
        bullet2.name = "bullet/2/"
        view.installGestures(.all, for: bullet2)
        
        bullet3 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet3.generateCollisionShapes(recursive: true)
        bullet3.name = "bullet/3/"
        view.installGestures(.all, for: bullet3)
        
        bullet4 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet4.generateCollisionShapes(recursive: true)
        bullet4.name = "bullet/4/"
        view.installGestures(.all, for: bullet4)
        
        bullet5 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet5.generateCollisionShapes(recursive: true)
        bullet5.name = "bullet/5/"
        view.installGestures(.all, for: bullet5)
        
        bullet6 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet6.generateCollisionShapes(recursive: true)
        bullet6.name = "bullet/6/"
        view.installGestures(.all, for: bullet6)
        
        bullet7 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet7.generateCollisionShapes(recursive: true)
        bullet7.name = "bullet/7/"
        view.installGestures(.all, for: bullet7)
        
        bullet8 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet8.generateCollisionShapes(recursive: true)
        bullet8.name = "bullet/8/"
        view.installGestures(.all, for: bullet8)
        
        bullet9 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet9.generateCollisionShapes(recursive: true)
        bullet9.name = "bullet/9/"
        view.installGestures(.all, for: bullet9)
        
        bullet10 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet10.generateCollisionShapes(recursive: true)
        bullet10.name = "bullet/10/"
        view.installGestures(.all, for: bullet10)
        
        bullet11 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet11.generateCollisionShapes(recursive: true)
        bullet11.name = "bullet/11/"
        view.installGestures(.all, for: bullet11)
        
        bullet12 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet12.generateCollisionShapes(recursive: true)
        bullet12.name = "bullet/12/"
        view.installGestures(.all, for: bullet12)
        
        bullet13 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet13.generateCollisionShapes(recursive: true)
        bullet13.name = "bullet/13/"
        view.installGestures(.all, for: bullet13)
        
        bullet14 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet14.generateCollisionShapes(recursive: true)
        bullet14.name = "bullet/14/"
        view.installGestures(.all, for: bullet14)
        
        bullet15 = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (ModelEntity & HasCollision & HasPhysicsBody)
        bullet15.generateCollisionShapes(recursive: true)
        bullet15.name = "bullet/15/"
        view.installGestures(.all, for: bullet15)
        
        
        
        // Stores the current name of the bullet that is launched
        currBullet.name = bullet1.name
        
        // Add the anchirBullet to the scene for it to be the first anchor
        view.scene.addAnchor(anchorBullet)
        
        // Collision Group
        boxMask = CollisionGroup.all.subtracting(sphereGroup)
    }
    
    func initBoxes() {
        guard let view = self.view else { return }
        
        // Box - 1 Collision
        box1 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box1Material])
        box1.generateCollisionShapes(recursive: true)
        box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box1.name = "box/1/"
        view.installGestures(.all, for: box1)
        
        // Box - 2 Collision
        box2 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box2Material])
        box2.generateCollisionShapes(recursive: true)
        box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box2.name = "box/2/"
        view.installGestures(.all, for: box2)
        
        // Box - 3 Collision
        box3 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box3Material])
        box3.generateCollisionShapes(recursive: true)
        box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box3.name = "box/3/"
        view.installGestures(.all, for: box3)
        
        // Box - 4 Collision
        box4 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box4Material])
        box4.generateCollisionShapes(recursive: true)
        box4.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box4.name = "box/4/"
        view.installGestures(.all, for: box4)

        // Box - 5 Collision
        box5 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box5Material])
        box5.generateCollisionShapes(recursive: true)
        box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box5.name = "box/5/"
        view.installGestures(.all, for: box5)
        
        // Box - 6 Collision
        box6 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box6Material])
        box6.generateCollisionShapes(recursive: true)
        box6.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box6.name = "box/6/"
        view.installGestures(.all, for: box6)
        
        // Box - 7 Collision
        box7 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box7Material])
        box7.generateCollisionShapes(recursive: true)
        box7.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box7.name = "box/7/"
        view.installGestures(.all, for: box7)
        
        
        // Box - 8 Collision
        box8 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box8Material])
        box8.generateCollisionShapes(recursive: true)
        box8.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box8.name = "box/8/"
        view.installGestures(.all, for: box8)
        
        
        // Box - 9 Collision
        box9 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box9Material])
        box9.generateCollisionShapes(recursive: true)
        box9.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box9.name = "box/9/"
        view.installGestures(.all, for: box9)
        
        
        // Box - 10 Collision
        box10 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box10Material])
        box10.generateCollisionShapes(recursive: true)
        box10.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box10.name = "box/10/"
        view.installGestures(.all, for: box10)
        
        
        // Box - 11 Collision
        box11 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box11Material])
        box11.generateCollisionShapes(recursive: true)
        box11.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box11.name = "box/11/"
        view.installGestures(.all, for: box11)

        
        // Box - 12 Collision
        box12 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02, cornerRadius: 1), materials: [box12Material])
        box12.generateCollisionShapes(recursive: true)
        box12.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        box12.name = "box/12/"
        view.installGestures(.all, for: box12)
        
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
        
        let modelPlaceholderMaterial = SimpleMaterial(color: .black, isMetallic: false)
        modelPlaceholder = ModelEntity(mesh: MeshResource.generateBox(width: 0.6, height: 1.1 , depth: 0.4), materials: [modelPlaceholderMaterial])
    }
    
    // Remove animation for box on collision with a Bullet
    func animate(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        guard let view = self.view else { return }
        
        // Remove the cube after 4 seconds
        let timer1 = CustomTimer { (seconds) in
            if(seconds == 1) {
                if(view.scene.anchors.count == 2) {
                    view.scene.anchors[1].removeChild(entity)
                }
            }
        }
        timer1.start()

        guard loop == true else { return }
        animUpdateSubscriptions.append(view.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity)
        { _ in
            self.animate(entity: entity, angle: angle, axis: axis, duration: duration, loop: loop, currentPosition: currentPosition)
        })
    }
    
    // Remove animation for box on collision with a Bullet
    func animateModel(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        guard let view = self.view else { return }
        
        var transform = entity.transform
        transform.rotation *= simd_quatf(angle: angle, axis: axis)
        transform.scale.x = 0.05
        transform.scale.y = 0.05
        transform.scale.z = 0.05
        entity.move(to: transform,
                    relativeTo: entity,
                        duration: duration)

        guard loop == true else { return }
        animUpdateSubscriptions.append(view.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity)
        { _ in
            self.animateModel(entity: entity, angle: angle, axis: axis, duration: duration, loop: loop, currentPosition: currentPosition)
        })
    }

    // Function to init the collision detection with Subscription
    func initCollisionDetection() {
        guard let view = self.view else { return }
    
        // Subscription for collision
        collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Began.self) { event in
            
            // Entity1 and Entity2 could be either a box or a bullet (even a bullet and a bullet collision)
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
            
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
                
                // Checks the index of the box that has been removed to support the progress
                self.arrayObjetos[self.currZona][entityReal - 1] = true
                
                // TODO: Delete on production: just to check array for the progress
                print("Boxes destroyes:")
                print(self.arrayObjetos)
                
                // If the arrayObjects is all setted as true, then marks it up as completed
//                if (!self.arrayObjetos[self.currZona].contains(false)) {
//                    print("se ha completado una Zona")
//                    self.progresoActual = self.progresoActual + 1
//                    print("Progreso: ", self.progresoActual)
//                }

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
                    self.arrayObjetos[self.currZona][entityReal - 1] = true
                    
                    print("Boxes destroyes:")
                    print(self.arrayObjetos)
//                    print(self.arrayObjetos[self.currZona])
//                    if (!self.arrayObjetos[self.currZona].contains(false)) {
//                        print("se ha completado coordinator")
//                        Coordinator.completed.complete = true
//                    }
                }
            }
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
        (origin, direction) = view.ray(through: tapPoint) ?? (SIMD3<Float>([0,0,0]), SIMD3<Float>([0,0,0]))

        // Throw ball location - direction
        raycasts = view.scene.raycast(origin: origin, direction: direction, length: 50, query: .any, mask: .default, relativeTo: nil)
        
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
                motion = .init(linearVelocity: [-raycastVal.normal[0]*2, -raycastVal.normal[1]*2, -raycastVal.normal[2]*2],angularVelocity: [0, 0, 0])
                
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
            bullet1.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
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
    
    // Cargar los modelos dependiendo de la zona
    @objc func updateMarcoModels(lat: Double, lon: Double) {
        
        guard let view = self.view else { return }
            
        // Si ya no se encuentra dentro de la zona actual, busca cual es la zona actual
        if (lat < zonas[currZona].latMin || lat > zonas[currZona].latMax || lon < zonas[currZona].lonMin || lon > zonas[currZona].lonMax) {
            for (index, zona) in zonas.enumerated() {
                if(lat > zona.latMin && lat < zona.latMax && lon > zona.lonMin && lon < zona.lonMax) {
                    currZona = index
                    print("Zona actual: ", currZona)
                }
            }
            
            // Remove the actual entities from the anchor if the anchor is added and have models
            if(view.scene.anchors.count == 2) {
                view.scene.anchors[1].removeChild(textEntity)
                view.scene.anchors[1].removeChild(box1)
                view.scene.anchors[1].removeChild(box2)
                view.scene.anchors[1].removeChild(box3)
                view.scene.anchors[1].removeChild(box4)
                view.scene.anchors[1].removeChild(box5)
                view.scene.anchors[1].removeChild(box6)
                view.scene.anchors[1].removeChild(box7)
                view.scene.anchors[1].removeChild(box8)
                view.scene.anchors[1].removeChild(box9)
                view.scene.anchors[1].removeChild(box10)
                view.scene.anchors[1].removeChild(box11)
                view.scene.anchors[1].removeChild(box12)
                print("se ejecutra el remove")
                view.scene.anchors[1].removeChild(modelPlaceholder)
                // view.scene.anchors[1].removeChild(newEntity)
                
                for currModels in anchor.children {
                    anchor.removeChild(currModels)
                }
                print("se ejecutra el remove CHLDREN: ", anchor.children.count)
                
            }
            // Remove the actual anchor
            view.scene.removeAnchor(anchor)
            
        // Si se encuentra en la zona actual, ejecuta el siguiente codigo
        } else {
            
            // Si aun no se ha montado la escena, se monta con este if
            if(view.scene.anchors.count == 1 && !models.isEmpty) {
                modelPlaceholder.setPosition(SIMD3(x: 0, y: 0.4, z: 0), relativeTo: nil)
                if (self.arrayRunOnce[self.currZona] == false) {
                    modelPlaceholder.stopAllAnimations(recursive: true)
                    print(modelPlaceholder.scale)
                    if(modelPlaceholder.scale.x < 0.8) {
                        modelPlaceholder.scale.x = 1
                        modelPlaceholder.scale.y = 1
                        modelPlaceholder.scale.z = 1
                        self.modelPlaceholder.model?.materials = [SimpleMaterial(color: .black, isMetallic: false)]
                    }
                    
                    anchor.addChild(modelPlaceholder)
                }
                
                // Shows the text of the current Obra
                textEntity = textGen(textString: models[currZona].nombre)
                textEntity.setPosition(SIMD3(x: 0.0, y: -0.2, z: 0.0), relativeTo: nil)
                anchor.addChild(textEntity)
                
                box1.model?.materials = [box1Material]
                box2.model?.materials = [box2Material]
                box3.model?.materials = [box3Material]
                box4.model?.materials = [box4Material]
                box5.model?.materials = [box5Material]
                box6.model?.materials = [box6Material]
                box7.model?.materials = [box7Material]
                box8.model?.materials = [box8Material]
                box9.model?.materials = [box9Material]
                box10.model?.materials = [box10Material]
                box11.model?.materials = [box11Material]
                box12.model?.materials = [box12Material]
                
                if(self.arrayRunOnce[self.currZona] == false) {
                    if(self.arrayObjetos[self.currZona][0] == false) {
                        anchor.addChild(box1)
                    }
                    if(self.arrayObjetos[self.currZona][1] == false) {
                        anchor.addChild(box2)
                    }
                    if(self.arrayObjetos[self.currZona][2] == false) {
                        anchor.addChild(box3)
                    }
                    if(self.arrayObjetos[self.currZona][3] == false) {
                        anchor.addChild(box4)
                    }
                    if(self.arrayObjetos[self.currZona][4] == false) {
                        anchor.addChild(box5)
                    }
                    if(self.arrayObjetos[self.currZona][5] == false) {
                        anchor.addChild(box6)
                    }
                    if(self.arrayObjetos[self.currZona][6] == false) {
                        anchor.addChild(box7)
                    }
                    if(self.arrayObjetos[self.currZona][7] == false) {
                        anchor.addChild(box8)
                    }
                    if(self.arrayObjetos[self.currZona][8] == false) {
                        anchor.addChild(box9)
                    }
                    if(self.arrayObjetos[self.currZona][9] == false) {
                        anchor.addChild(box10)
                    }
                    if(self.arrayObjetos[self.currZona][10] == false) {
                        anchor.addChild(box11)
                    }
                    if(self.arrayObjetos[self.currZona][11] == false) {
                        anchor.addChild(box12)
                    }
                }
                
                // Add the anchor to the scene
                anchor.move(to: Transform(translation: simd_float3(0,0,-1)), relativeTo: nil)
                view.scene.addAnchor(anchor)
                
                
                // Play the orbiting animations
                box1.playAnimation(animationResource1!)
                box3.playAnimation(animationResource3!)
                box4.playAnimation(animationResource4!)
                box2.playAnimation(animationResource2!)
                box5.playAnimation(animationResource5!)
                box6.playAnimation(animationResource6!)
                box7.playAnimation(animationResource7!)
                box8.playAnimation(animationResource8!)
                box9.playAnimation(animationResource9!)
                box10.playAnimation(animationResource10!)
                box11.playAnimation(animationResource11!)
                box12.playAnimation(animationResource12!)
                
                
                if(self.arrayRunOnce[self.currZona] == true) {
                    print("ZONA PREVIAMENTE COMPLETADA: ", self.currZona)
                    var rutaIndex = 0
                    for (index, ruta) in self.rutas.enumerated() {
                        let rutaName = ruta.absoluteString
                        let firstIndex = rutaName.index(rutaName.lastIndex(of: "-")!, offsetBy: 1)
                        let lastIndex = rutaName.index(rutaName.lastIndex(of: ".")!, offsetBy: -1)
                        let completeName = rutaName[firstIndex...lastIndex]
                        
                        if(completeName.uppercased() == models[self.currZona].nombre.uppercased()) {
                            rutaIndex = index
                        }
                    }
                    
                    newEntityPirinola = ModelEntity.loadModelAsync(contentsOf: self.rutas[rutaIndex])
                        .sink { loadCompletion in
                            if case let .failure(error) = loadCompletion {
                                print("Unable to load model \(error)")
                            }
                            self.newEntityPirinola?.cancel()
                        } receiveValue: { newEntity in
                            newEntity.setPosition(SIMD3(x: 0, y: 0.6, z: 0), relativeTo: nil)
                            newEntity.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: newEntity)
                            print("se carga con exito")
                            // Change black entity for new model Entity
                            if(view.scene.anchors.count == 2) {
    //                            view.scene.anchors[1].children[0] = newEntity
                                // view.scene.anchors[1].removeChild(self.modelPlaceholder)
                                view.scene.anchors[1].addChild(newEntity)
                            }
                        }
                }
            }
            
            
            
            
            if(!self.arrayObjetos[self.currZona].contains(false) && self.arrayRunOnce[self.currZona] == false) {
                
                var rutaIndex = 0
                for (index, ruta) in self.rutas.enumerated() {
                    let rutaName = ruta.absoluteString
                    let firstIndex = rutaName.index(rutaName.lastIndex(of: "-")!, offsetBy: 1)
                    let lastIndex = rutaName.index(rutaName.lastIndex(of: ".")!, offsetBy: -1)
                    let completeName = rutaName[firstIndex...lastIndex]
                    
                    if(completeName.uppercased() == models[self.currZona].nombre.uppercased()) {
                        rutaIndex = index
                        
                    }
                }
                
                
                self.modelPlaceholder.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
                self.animateModel(entity: self.modelPlaceholder, angle: .pi, axis:  [0, 1, 0], duration: 4, loop: false, currentPosition: self.modelPlaceholder.position)
 
                newEntityPirinola = ModelEntity.loadModelAsync(contentsOf: self.rutas[rutaIndex])
                    .sink { loadCompletion in
                        if case let .failure(error) = loadCompletion {
                            print("Unable to load model \(error)")
                        }
                        self.newEntityPirinola?.cancel()
                    } receiveValue: { newEntity in
                        newEntity.setPosition(SIMD3(x: 0, y: 0.6, z: 0), relativeTo: nil)
                        newEntity.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: newEntity)
                        print("se carga con exito")
                        // Change black entity for new model Entity
                        if(view.scene.anchors.count == 2) {
//                            view.scene.anchors[1].children[0] = newEntity
                            view.scene.anchors[1].removeChild(self.modelPlaceholder)
                            view.scene.anchors[1].addChild(newEntity)
                            
                            if(self.arrayRunOnce[self.currZona] == false) {
                                
                                self.arrayRunOnce[self.currZona] = true
                                self.arrayNombreObrasCompletadas.append(self.models[self.currZona].nombre)
                            
                                self.progresoActual = self.progresoActual + 1
                                print("Progreso: ", self.progresoActual)
                                print(self.arrayNombreObrasCompletadas)
                                print("ZONA NUEVA COMPLETADA: ", self.currZona)
                                
                                // Checks when the game has been completed
                                if(!self.arrayRunOnce.contains(false)) {
                                    print("se ha completado el juego: ")
                                    Coordinator.completed.complete = true
                                    print(Coordinator.completed.complete)
                                }
                            }
                        }
                    }
            }
        }
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
