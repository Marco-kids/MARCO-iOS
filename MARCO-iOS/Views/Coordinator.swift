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
    
    // Loading asynchronous models
    var newEntityPirinola: AnyCancellable?
    
    // Variable para saber si ya se capturaron todos los cubitos
    static let completed = Coordinator()
    var complete = false
    
    let boxGroup = CollisionGroup(rawValue: 1 << 0)
    let sphereGroup = CollisionGroup(rawValue: 1 << 1)
    
    var boxMask: CollisionGroup = .init()
    var sphereMask: CollisionGroup = .init()
    
    // Salon Aplicacion
    var pirinolaLimitLat = [25.60008, 25.66009]
    var pirinolaLimitLon = [-100.29069, -100.290400]
    
    // Simulador casa objeto
    // var objetoLimitLat = [25.65000, 25.66000]
    // var objetoLimitLon =  [-100.26000, -100.25000]
    
    // Simulador cualquier lugar
    var objetoLimitLat = [20.0000, 28.00000]
    var objetoLimitLon =  [-101.00000, -100.0000]
    
    // Simulador Xcode
    // var objetoLimitLat = [0.0000, 100.0000]
    // var objetoLimitLon =  [-123.00000, -122.00000]
    
    var arrayObjetos = [false, false, false, false, false]
    var arrayRunOnce = [false, false]

    // Entity global que tiene todo
    let anchor = AnchorEntity(world: [0,0,0])
    
    // Animacion cuando colisiona la caja y el bullet
    var animUpdateSubscriptions = [Cancellable]()
    func animate(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        guard let view = self.view else { return }
        
        var transform = entity.transform
        transform.rotation *= simd_quatf(angle: angle, axis: axis)
        transform.translation = [0, 1, 0]
        transform.scale = [0.1, 0.1, 0.1]
        entity.move(to: transform, relativeTo: entity.parent, duration: duration)
        
        
        // Remove the cube after 4 seconds
        let timer1 = CustomTimer { (seconds) in
            if(seconds == 4) {
                view.scene.anchors[0].removeChild(entity)
            }
        }
        timer1.start()
        
        guard loop == true else { return }
        animUpdateSubscriptions.append(view.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity)
                                       { _ in
            self.animate(entity: entity, angle: angle, axis: axis, duration: duration, loop: loop, currentPosition: currentPosition)
        })
    }

    func initCollisionDetection() {
        guard let view = self.view else { return }
    
        // Cuando empieza la colision
        collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Began.self) { event in
            
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
                    
            entity1.model?.materials = [SimpleMaterial(color: .yellow, isMetallic: false)]
            entity2.model?.materials = [SimpleMaterial(color: .white, isMetallic: false)]
            
            // Substrings of the object's name
            var entityName = entity1.name
            var typeIndex = entityName.firstIndex(of: "/")!
            var entityType = entityName[...typeIndex] // Type of the object "box" or "bullet"
            var entityId = entityName[typeIndex...]
            var entityNumber = entityId[1]
            var entityReal = Int(String(entityNumber)) ?? 0 // Int of the Object -> "box/1/" -> 1
            
            // Animacion cuando colisiona con la caja
            if (entityType == "box/") {
                self.animate(entity: entity1, angle: .pi, axis: [0, 1, 0], duration: 4, loop: false, currentPosition: entity1.position)
                self.arrayObjetos[entityReal - 1] = true
                
                print(self.arrayObjetos)
                if (!self.arrayObjetos.contains(false)) {
                    print("se ha completado coordinator")
                    Coordinator.completed.complete = true
                    print(Coordinator.completed.complete)
                }
            } else {
                // Substrings of the object's name
                entityName = entity2.name
                typeIndex = entityName.firstIndex(of: "/")!
                entityType = entityName[...typeIndex] // Type of the object "box" or "bullet"
                entityId = entityName[typeIndex...]
                entityNumber = entityId[1]
                entityReal = Int(String(entityNumber)) ?? 0 // Int of the Object -> "box/1/" -> 1
                
                self.animate(entity: entity2, angle: .pi, axis: [0, 1, 0], duration: 4, loop: false, currentPosition: entity2.position)
                self.arrayObjetos[entityReal - 1] = true
                
                print(self.arrayObjetos)
                if (!self.arrayObjetos.contains(false)) {
                    print("se ha completado coordinator")
                    Coordinator.completed.complete = true
                    print(Coordinator.completed.complete)
                }
            }
        })
        
        // Cuando termina la colision
        // collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Ended.self) { event in
            
            // guard let entity1 = event.entityA as? ModelEntity,
            //       let entity2 = event.entityB as? ModelEntity else { return }
            
            // entity1.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            // entity2.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            
            // print("colision detectada")
        // })
        
        print("inicia")
    }
    
    // Generate Text
    func textGen(textString: String) -> ModelEntity {
        let materialVar = SimpleMaterial(color: .white, roughness: 0, isMetallic: false)
        
        let depthVar: Float = 0.01
        let fontVar = UIFont.systemFont(ofSize: 0.1)
        let containerFrameVar = CGRect(x: -0.3, y: -0.3, width: 0.5, height: 0.5)
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
    
    // Disparar bolitas
    @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
        
        guard let view = self.view else { return }
        let tapPoint = recognizer.location(in: view)
        
        // Throw ball model
        let bulletMaterial = SimpleMaterial(color: .yellow, isMetallic: false)
        let bullet = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (Entity & HasCollision & HasPhysicsBody)
        bullet.generateCollisionShapes(recursive: true)
        
        // Throw ball location - direction
        let (origin, direction) = view.ray(through: tapPoint)!
        
        let raycasts: [CollisionCastHit] = view.scene.raycast(origin: origin, direction: direction, length: 50, query: .any, mask: .default, relativeTo: nil)
        
        bullet.position = origin
        
        let size = bullet.visualBounds(relativeTo: bullet).extents
        let bulletShape = ShapeResource.generateBox(size: size)
        bullet.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        
        let kinematics: PhysicsBodyComponent = .init(massProperties: .default,material: nil,mode: .kinematic)
        bullet.components.set(kinematics)
        
        if let raycastVal = raycasts.first {
            let motion: PhysicsMotionComponent = .init(linearVelocity: [-raycastVal.normal[0]*1, -raycastVal.normal[1]*1, -raycastVal.normal[2]*1],angularVelocity: [0, 0, 0])
            bullet.components.set(motion)
        }

        bullet.name = "bullet/1/"
        anchor.addChild(bullet)
        
        view.installGestures(.all, for: bullet)
        
        // Remove bullet from anchor after 4 seconds
        let timer1 = CustomTimer { (seconds) in
            if(seconds == 4) {
                view.scene.anchors[0].removeChild(bullet)
            }
        }
        timer1.start()
    }
    
    // Cargar los modelos dependiendo de la zona
    @objc func updateMarcoModels(lat: Double, lon: Double) {
        
        guard let view = self.view else { return }
        boxMask = CollisionGroup.all.subtracting(sphereGroup)
        
        // Simulacion del Salon
        if (lat > pirinolaLimitLat[0] && lat < pirinolaLimitLat[1] && lon > pirinolaLimitLon[0] && lon < pirinolaLimitLon[1]) {
            if(view.scene.anchors.isEmpty) {
                print("adentro")
                // Pirinola
                guard let entityPirinolaSalon = try? ModelEntity.load(named: "Models/pirinola_black") else {
                    fatalError("Robot model was not!")
                }
                entityPirinolaSalon.setScale(SIMD3(x: 0.05, y: 0.05, z: 0.05), relativeTo: entityPirinolaSalon)
                entityPirinolaSalon.name = "entityPirinola/1/"
                anchor.addChild(entityPirinolaSalon)

                // Text for Pirinola
                let textEntity = textGen(textString: "Pirinola")
                anchor.addChild(textEntity)
                
                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.1, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.setPosition(SIMD3(x: 100, y: 150, z: 250), relativeTo: entityPirinolaSalon)
                box1.name = "box/1/"
            
                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.1, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.setPosition(SIMD3(x: -200, y: -200, z: -150), relativeTo: entityPirinolaSalon)
                box2.name = "box/2/"
                
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.1, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.setPosition(SIMD3(x: 130, y: 130, z: -130), relativeTo: entityPirinolaSalon)
                box3.name = "box/3/"

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
                
                // Caja - 4 Collision
                let boxSalon4 = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.1, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                boxSalon4.generateCollisionShapes(recursive: true)
                boxSalon4.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                boxSalon4.setPosition(SIMD3(x: 500, y: 500, z: 500), relativeTo: entityPirinolaSalon)
                boxSalon4.name = "box/4/"

                anchor.addChild(boxSalon4)
                view.installGestures(.all, for: boxSalon4)
                
                view.scene.addAnchor(anchor)
                
                // Caja - 5 Collision
                let box5 = ModelEntity(mesh: MeshResource.generateBox(width: 0.1, height: 0.1, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box5.generateCollisionShapes(recursive: true)
                box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box5.setPosition(SIMD3(x: -500, y: -500, z: -500), relativeTo: entityPirinolaSalon)
                box5.name = "box/5/"

                anchor.addChild(box5)
                view.installGestures(.all, for: box5)
            }
            
            // Todo hacer una animacion propia para la pirinola
            if(!self.arrayObjetos.contains(false) && self.arrayRunOnce[0] == false) {
                // Anadir color a la pirinola
                newEntityPirinola = ModelEntity.loadAsync(named: "Models/pirinola")
                    .sink { loadCompletion in
                        if case let .failure(error) = loadCompletion {
                            print("Unable to load model \(error)")
                        }
                        
                        self.newEntityPirinola?.cancel()
                    } receiveValue: { newEntity in
                        newEntity.setScale(SIMD3(x: 1, y: 1, z: 1), relativeTo: view.scene.anchors[0].children[0])
                        newEntity.setPosition(SIMD3(x: 0, y: 0, z: 0), relativeTo: view.scene.anchors[0].children[0])
                        
                        // Change black entity for new model Entity
                        view.scene.anchors[0].children[0] = newEntity
                        self.arrayRunOnce[0] = true
                    }
            }
            
        // Simulacion Swift
        } else if (lat > objetoLimitLat[0] && lat < objetoLimitLat[1] && lon > objetoLimitLon[0] && lon < objetoLimitLon[1]) {
    
            if(view.scene.anchors.isEmpty) {
                print("adentro")
                // Pirinola
                guard let entityPirinolaSalon = try? ModelEntity.load(named: "Models/pirinola_black") else {
                    fatalError("Robot model was not!")
                }
                entityPirinolaSalon.setScale(SIMD3(x: 0.05, y: 0.05, z: 0.05), relativeTo: entityPirinolaSalon)
                anchor.addChild(entityPirinolaSalon)
                
                // Text for Pirinola
                let textEntity = textGen(textString: "Pirinola")
                anchor.addChild(textEntity)
                
                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.setPosition(SIMD3(x: 100, y: 150, z: 250), relativeTo: entityPirinolaSalon)
                box1.name = "box/1/"

                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.setPosition(SIMD3(x: -200, y: -200, z: -150), relativeTo: entityPirinolaSalon)
                box2.name = "box/2/"
                
                
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.setPosition(SIMD3(x: 130, y: 130, z: -130), relativeTo: entityPirinolaSalon)
                box3.name = "box/3/"

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
                
                // Caja - 4 Collision
                let boxSalon4 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                boxSalon4.generateCollisionShapes(recursive: true)
                boxSalon4.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                boxSalon4.setPosition(SIMD3(x: 500, y: 500, z: 500), relativeTo: entityPirinolaSalon)
                boxSalon4.name = "box/4/"

                anchor.addChild(boxSalon4)
                view.installGestures(.all, for: boxSalon4)
                
                view.scene.addAnchor(anchor)
                
                // Caja - 5 Collision
                let box5 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box5.generateCollisionShapes(recursive: true)
                box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box5.setPosition(SIMD3(x: -500, y: -500, z: -500), relativeTo: entityPirinolaSalon)
                box5.name = "box/5/"

                anchor.addChild(box5)
                view.installGestures(.all, for: box5)
                
                // Todo hacer una animacion propia para la pirinola
            }
            
            if(!self.arrayObjetos.contains(false) && self.arrayRunOnce[1] == false) {
                // Anadir color a la pirinola
                print("Entra aqui")
                newEntityPirinola = ModelEntity.loadAsync(named: "Models/pirinola")
                    .sink { loadCompletion in
                        if case let .failure(error) = loadCompletion {
                            print("Unable to load model \(error)")
                        }
                        
                        self.newEntityPirinola?.cancel()
                    } receiveValue: { newEntity in
                        newEntity.setScale(SIMD3(x: 1, y: 1, z: 1), relativeTo: view.scene.anchors[0].children[0])
                        newEntity.setPosition(SIMD3(x: 0, y: 0, z: 0), relativeTo: view.scene.anchors[0].children[0])
                        
                        // Change black entity for new model Entity
                        view.scene.anchors[0].children[0] = newEntity
                        self.arrayRunOnce[1] = true
                    }
            }
            
        } else { // Improve delete of models
            // step 1: function to delete
            // step 2: check if there's something different than the actual position
            // step 3: delete whatever is previous loaded
            
            // Descomentar
            // if(view.scene.anchors.isEmpty == false) {
            //    print("afuera")
            //'   view.scene.removeAnchor(anchor)
            // }
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
    /**
     * This method must be in the public or scope
     */
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
