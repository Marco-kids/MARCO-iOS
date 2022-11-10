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
    var objetoLimitLat = [25.65000, 25.66000]
    var objetoLimitLon =  [-100.26000, -100.25000]
    
    // Simulador cualquier lugar
    // var objetoLimitLat = [20.0000, 28.00000]
    // var objetoLimitLon =  [-101.00000, -100.0000]
    
    // Simulador Xcode
    // var objetoLimitLat = [0.0000, 100.0000]
    // var objetoLimitLon =  [-123.00000, -122.00000]
    
    var arrayObjetos = [false, false, false, false, false, false, false, false, false, false, false, false]
    var arrayRunOnce = [false, false]

    // Entity global que tiene todo
    let anchor = AnchorEntity(plane: .horizontal, classification: .floor)
    // let anchor = AnchorEntity(plane: .horizontal)
    let anchorBullet = AnchorEntity(world: [0,0,0])
    
    // Animacion cuando colisiona la caja y el bullet
    var animUpdateSubscriptions = [Cancellable]()
    func animate(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        guard let view = self.view else { return }
        
        // TODO: Fix animation when collition
        // var transform = entity.transform
        // transform.rotation *= simd_quatf(angle: angle, axis: axis)
        // transform.translation = [0, 1, 0]
        // transform.scale = [0.01, 0.01, 0.01]
        // entity.move(to: transform, relativeTo: entity.parent, duration: duration)
        
        // Remove the cube after 4 seconds
        let timer1 = CustomTimer { (seconds) in
            if(seconds == 1) {
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
            var lastIndex = entityName.lastIndex(of: "/")!
            var entityType = entityName[...typeIndex] // Type of the object "box" or "bullet"
            var entityId = entityName[typeIndex...lastIndex]
            var entityReal = Int(String(entityId[1])) ?? 0 // Int of the Object -> "box/1/" -> 1
            
            if(entityId[2] != "/") {
                entityReal = Int(String("\(entityId[1])\(entityId[2])")) ?? 0 // Int of the Object -> "box/1/" -> 1
            }
            
            // Animacion cuando colisiona con la caja
            if (entityType == "box/") {
                entity1.stopAllAnimations()
                self.animate(entity: entity1, angle: .pi, axis: [0, 1, 0], duration: 1, loop: false, currentPosition: entity1.position)
                self.arrayObjetos[entityReal - 1] = true
                
                print(self.arrayObjetos)
                if (!self.arrayObjetos.contains(false)) {
                    print("se ha completado coordinator")
                    Coordinator.completed.complete = true
                    print(Coordinator.completed.complete)
                }
    
            } else {
                // Substrings of the object's name
                entityName = entity1.name
                typeIndex = entityName.firstIndex(of: "/")!
                lastIndex = entityName.lastIndex(of: "/")!
                entityType = entityName[...typeIndex] // Type of the object "box" or "bullet"
                entityId = entityName[typeIndex...lastIndex]
                entityReal = Int(String(entityId[1])) ?? 0 // Int of the Object -> "box/1/" -> 1
                
                if(entityId[2] != "/") {
                    entityReal = Int(String("\(entityId[1])\(entityId[2])")) ?? 0 // Int of the Object -> "box/1/" -> 1
                }
                
                self.animate(entity: entity2, angle: .pi, axis: [0, 1, 0], duration: 1, loop: false, currentPosition: entity2.position)
                self.arrayObjetos[entityReal - 1] = true
                
                print(self.arrayObjetos)
                if (!self.arrayObjetos.contains(false)) {
                    print("se ha completado coordinator")
                    Coordinator.completed.complete = true
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
        let fontVar = UIFont.systemFont(ofSize: 0.2)
        let containerFrameVar = CGRect(x: -0.5, y: -0.5, width: 1, height: 1)
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
        
        // Throw ball location - direction
        let (origin, direction) = view.ray(through: tapPoint)!

        // Throw ball location - direction
        let raycasts: [CollisionCastHit] = view.scene.raycast(origin: origin, direction: direction, length: 50, query: .any, mask: .default, relativeTo: nil)
        
        // Throw ball model
        let bulletMaterial = SimpleMaterial(color: .green, isMetallic: false)
        let bullet = ModelEntity(mesh: MeshResource.generateSphere(radius: 0.02), materials: [bulletMaterial]) as (Entity & HasCollision & HasPhysicsBody)
        bullet.generateCollisionShapes(recursive: true)
        
        
        // Bullet origin
        bullet.position = origin
        
        // Collission component
        let size = bullet.visualBounds(relativeTo: bullet).extents
        let bulletShape = ShapeResource.generateBox(size: size)
        bullet.collision = CollisionComponent(shapes: [bulletShape], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        
        // Add physics linear velocity
        let kinematics: PhysicsBodyComponent = .init(massProperties: .default,material: nil,mode: .kinematic)
        bullet.components.set(kinematics)
        
        // Raycast
        var flag = false
        if let raycastVal = raycasts.first {
            print("raycast: ", raycastVal.normal[0])
            let motion: PhysicsMotionComponent = .init(linearVelocity: [-raycastVal.normal[0]*2, -raycastVal.normal[1]*2, -raycastVal.normal[2]*2],angularVelocity: [0, 0, 0])
            bullet.components.set(motion)
            flag = true
        }
        
        bullet.name = "bullet/1/"
        anchorBullet.addChild(bullet)
        
        view.installGestures(.all, for: bullet)
        
        // Remove bullet from anchor after 4 seconds
        if(flag) {
            let timer1 = CustomTimer { (seconds) in
                if(seconds == 3) {
                    view.scene.anchors[1].removeChild(bullet)
                }
            }
            timer1.start()
        } else {
            let timer1 = CustomTimer { (seconds) in
                if(seconds == 1) {
                    view.scene.anchors[1].removeChild(bullet)
                }
            }
            timer1.start()
        }
    }
    
    // Cargar los modelos dependiendo de la zona
    @objc func updateMarcoModels(lat: Double, lon: Double) {
        
        guard let view = self.view else { return }
        boxMask = CollisionGroup.all.subtracting(sphereGroup)
        
        // Simulacion del Salon
        if (lat > pirinolaLimitLat[0] && lat < pirinolaLimitLat[1] && lon > pirinolaLimitLon[0] && lon < pirinolaLimitLon[1]) {
            if(view.scene.anchors.isEmpty) {
                
                // Pirinola
                guard let entityPirinolaSalon = try? ModelEntity.load(named: "Models/pirinola_black") else {
                    fatalError("Robot model was not!")
                }
                entityPirinolaSalon.setPosition(SIMD3(x: 0, y: 0.6, z: -0.5), relativeTo: nil)
                entityPirinolaSalon.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: entityPirinolaSalon)
                anchor.addChild(entityPirinolaSalon)

                // Text for Pirinola
                let textEntity = textGen(textString: "Pirinola")
                textEntity.setPosition(SIMD3(x: 0.0, y: 0.9, z: 0.0), relativeTo: nil)
                anchor.addChild(textEntity)
                
                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.name = "box/1/"
                box1.setPosition(SIMD3(x: 0, y: 2, z: -0.5), relativeTo: nil)

                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.name = "box/2/"
                
                
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .purple, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.name = "box/3/"

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
                
                // Caja - 4 Collision
                let boxSalon4 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
                boxSalon4.generateCollisionShapes(recursive: true)
                boxSalon4.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                boxSalon4.name = "box/4/"

                anchor.addChild(boxSalon4)
                view.installGestures(.all, for: boxSalon4)
                
                // Caja - 5 Collision
                let box5 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .orange, isMetallic: false)])
                box5.generateCollisionShapes(recursive: true)
                box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box5.name = "box/5/"

                anchor.addChild(box5)
                view.installGestures(.all, for: box5)
                
                
                // Caja - 6 Collision
                let box6 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
                box6.generateCollisionShapes(recursive: true)
                box6.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box6.name = "box/6/"

                anchor.addChild(box6)
                view.installGestures(.all, for: box6)
                
                // Caja - 7 Collision
                let box7 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .cyan, isMetallic: false)])
                box7.generateCollisionShapes(recursive: true)
                box7.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box7.name = "box/7/"

                anchor.addChild(box7)
                view.installGestures(.all, for: box7)
                
                
                // Caja - 8 Collision
                let box8 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .brown, isMetallic: false)])
                box8.generateCollisionShapes(recursive: true)
                box8.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box8.name = "box/8/"

                anchor.addChild(box8)
                view.installGestures(.all, for: box8)
                
                
                // Caja - 9 Collision
                let box9 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .cyan, isMetallic: false)])
                box9.generateCollisionShapes(recursive: true)
                box9.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box9.name = "box/9/"

                anchor.addChild(box9)
                view.installGestures(.all, for: box9)
                
                
                // Caja - 10 Collision
                let box10 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box10.generateCollisionShapes(recursive: true)
                box10.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box10.name = "box/10/"

                anchor.addChild(box10)
                view.installGestures(.all, for: box10)
                
                // Caja - 11 Collision
                let box11 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                box11.generateCollisionShapes(recursive: true)
                box11.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box11.name = "box/11/"

                anchor.addChild(box11)
                view.installGestures(.all, for: box11)
                
                // Caja - 12 Collision
                let box12 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .orange, isMetallic: false)])
                box12.generateCollisionShapes(recursive: true)
                box12.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box12.name = "box/12/"

                anchor.addChild(box12)
                view.installGestures(.all, for: box12)
    
        
                // TODO: Cambiar de posicion
                anchor.move(to: Transform(translation: simd_float3(0,0,-1)), relativeTo: nil)
                view.scene.addAnchor(anchor)
                view.scene.addAnchor(anchorBullet)
                
                // Animacion box1 giro
                let animationDefinition1 = OrbitAnimation(
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
                let animationResource1 = try! AnimationResource.generate(with: animationDefinition1)
                box1.playAnimation(animationResource1)
                
                // Animacion box3 giro
                let animationDefinition3 = OrbitAnimation(
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
                let animationResource3 = try! AnimationResource.generate(with: animationDefinition3)
                box3.playAnimation(animationResource3)
                
                
                // Animacion box4 giro
                let animationDefinition4 = OrbitAnimation(
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
                let animationResource4 = try! AnimationResource.generate(with: animationDefinition4)
                boxSalon4.playAnimation(animationResource4)
                
                
                // Animacion box2 giro
                let animationDefinition2 = OrbitAnimation(
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
                let animationResource2 = try! AnimationResource.generate(with: animationDefinition2)
                box2.playAnimation(animationResource2)
                
                
                // Animacion box5 giro
                let animationDefinition5 = OrbitAnimation(
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
                let animationResource5 = try! AnimationResource.generate(with: animationDefinition5)
                box5.playAnimation(animationResource5)
                
                
                // Animacion box6 giro
                let animationDefinition6 = OrbitAnimation(
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
                let animationResource6 = try! AnimationResource.generate(with: animationDefinition6)
                box6.playAnimation(animationResource6)
                
                
                // Animacion box7 giro
                let animationDefinition7 = OrbitAnimation(
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
                let animationResource7 = try! AnimationResource.generate(with: animationDefinition7)
                box7.playAnimation(animationResource7)
                
                // Animacion box8 giro
                let animationDefinition8 = OrbitAnimation(
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
                let animationResource8 = try! AnimationResource.generate(with: animationDefinition8)
                box8.playAnimation(animationResource8)
                    
                // Animacion box9 giro
                let animationDefinition9 = OrbitAnimation(
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
                let animationResource9 = try! AnimationResource.generate(with: animationDefinition9)
                box9.playAnimation(animationResource9)
                
                
                // Animacion box10 giro
                let animationDefinition10 = OrbitAnimation(
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
                let animationResource10 = try! AnimationResource.generate(with: animationDefinition10)
                box10.playAnimation(animationResource10)
                
                // Animacion box11 giro
                let animationDefinition11 = OrbitAnimation(
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
                let animationResource11 = try! AnimationResource.generate(with: animationDefinition11)
                box11.playAnimation(animationResource11)
                
                // Animacion box12 giro
                let animationDefinition12 = OrbitAnimation(
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
                let animationResource12 = try! AnimationResource.generate(with: animationDefinition12)
                box12.playAnimation(animationResource12)
                
            }
            
            if(!self.arrayObjetos.contains(false) && self.arrayRunOnce[1] == false) {
                
                // Anadir color a la pirinola
                newEntityPirinola = ModelEntity.loadAsync(named: "Models/pirinola")
                    .sink { loadCompletion in
                        if case let .failure(error) = loadCompletion {
                            print("Unable to load model \(error)")
                        }
                        
                        self.newEntityPirinola?.cancel()
                    } receiveValue: { newEntity in
                        newEntity.setPosition(SIMD3(x: 0, y: 0.6, z: -0.5), relativeTo: nil)
                        newEntity.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: newEntity)
                        
                        // Change black entity for new model Entity
                        view.scene.anchors[0].children[0] = newEntity
                        self.arrayRunOnce[1] = true
                    }
            }
            
            
            
        // Simulacion Casa
        } else if (lat > objetoLimitLat[0] && lat < objetoLimitLat[1] && lon > objetoLimitLon[0] && lon < objetoLimitLon[1]) {
    
            if(view.scene.anchors.isEmpty) {
                
                // Pirinola
                guard let entityPirinolaSalon = try? ModelEntity.load(named: "Models/pirinola_black") else {
                    fatalError("Robot model was not!")
                }
                entityPirinolaSalon.setPosition(SIMD3(x: 0, y: 0.6, z: -0.5), relativeTo: nil)
                entityPirinolaSalon.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: entityPirinolaSalon)
                anchor.addChild(entityPirinolaSalon)

                // Text for Pirinola
                let textEntity = textGen(textString: "Pirinola")
                textEntity.setPosition(SIMD3(x: 0.0, y: 0.9, z: 0.0), relativeTo: nil)
                anchor.addChild(textEntity)
                
                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.name = "box/1/"
                box1.setPosition(SIMD3(x: 0, y: 2, z: -0.5), relativeTo: nil)

                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.name = "box/2/"
                
                
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .purple, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.name = "box/3/"

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
                
                // Caja - 4 Collision
                let boxSalon4 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
                boxSalon4.generateCollisionShapes(recursive: true)
                boxSalon4.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                boxSalon4.name = "box/4/"

                anchor.addChild(boxSalon4)
                view.installGestures(.all, for: boxSalon4)
                
                // Caja - 5 Collision
                let box5 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .orange, isMetallic: false)])
                box5.generateCollisionShapes(recursive: true)
                box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box5.name = "box/5/"

                anchor.addChild(box5)
                view.installGestures(.all, for: box5)
                
                
                // Caja - 6 Collision
                let box6 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .yellow, isMetallic: false)])
                box6.generateCollisionShapes(recursive: true)
                box6.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box6.name = "box/6/"

                anchor.addChild(box6)
                view.installGestures(.all, for: box6)
                
                // Caja - 7 Collision
                let box7 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .cyan, isMetallic: false)])
                box7.generateCollisionShapes(recursive: true)
                box7.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box7.name = "box/7/"

                anchor.addChild(box7)
                view.installGestures(.all, for: box7)
                
                
                // Caja - 8 Collision
                let box8 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .brown, isMetallic: false)])
                box8.generateCollisionShapes(recursive: true)
                box8.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box8.name = "box/8/"

                anchor.addChild(box8)
                view.installGestures(.all, for: box8)
                
                
                // Caja - 9 Collision
                let box9 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .cyan, isMetallic: false)])
                box9.generateCollisionShapes(recursive: true)
                box9.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box9.name = "box/9/"

                anchor.addChild(box9)
                view.installGestures(.all, for: box9)
                
                
                // Caja - 10 Collision
                let box10 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box10.generateCollisionShapes(recursive: true)
                box10.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box10.name = "box/10/"

                anchor.addChild(box10)
                view.installGestures(.all, for: box10)
                
                // Caja - 11 Collision
                let box11 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
                box11.generateCollisionShapes(recursive: true)
                box11.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box11.name = "box/11/"

                anchor.addChild(box11)
                view.installGestures(.all, for: box11)
                
                // Caja - 12 Collision
                let box12 = ModelEntity(mesh: MeshResource.generateBox(width: 0.15, height: 0.15, depth: 0.02), materials: [SimpleMaterial(color: .orange, isMetallic: false)])
                box12.generateCollisionShapes(recursive: true)
                box12.collision = CollisionComponent(shapes: [.generateBox(size: [0.15, 0.15, 0.02])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box12.name = "box/12/"

                anchor.addChild(box12)
                view.installGestures(.all, for: box12)
    
        
                // TODO: Cambiar de posicion
                anchor.move(to: Transform(translation: simd_float3(0,0,-1)), relativeTo: nil)
                view.scene.addAnchor(anchor)
                view.scene.addAnchor(anchorBullet)
                
                // Animacion box1 giro
                let animationDefinition1 = OrbitAnimation(
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
                let animationResource1 = try! AnimationResource.generate(with: animationDefinition1)
                box1.playAnimation(animationResource1)
                
                // Animacion box3 giro
                let animationDefinition3 = OrbitAnimation(
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
                let animationResource3 = try! AnimationResource.generate(with: animationDefinition3)
                box3.playAnimation(animationResource3)
                
                
                // Animacion box4 giro
                let animationDefinition4 = OrbitAnimation(
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
                let animationResource4 = try! AnimationResource.generate(with: animationDefinition4)
                boxSalon4.playAnimation(animationResource4)
                
                
                // Animacion box2 giro
                let animationDefinition2 = OrbitAnimation(
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
                let animationResource2 = try! AnimationResource.generate(with: animationDefinition2)
                box2.playAnimation(animationResource2)
                
                
                // Animacion box5 giro
                let animationDefinition5 = OrbitAnimation(
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
                let animationResource5 = try! AnimationResource.generate(with: animationDefinition5)
                box5.playAnimation(animationResource5)
                
                
                // Animacion box6 giro
                let animationDefinition6 = OrbitAnimation(
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
                let animationResource6 = try! AnimationResource.generate(with: animationDefinition6)
                box6.playAnimation(animationResource6)
                
                
                // Animacion box7 giro
                let animationDefinition7 = OrbitAnimation(
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
                let animationResource7 = try! AnimationResource.generate(with: animationDefinition7)
                box7.playAnimation(animationResource7)
                
                // Animacion box8 giro
                let animationDefinition8 = OrbitAnimation(
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
                let animationResource8 = try! AnimationResource.generate(with: animationDefinition8)
                box8.playAnimation(animationResource8)
                    
                // Animacion box9 giro
                let animationDefinition9 = OrbitAnimation(
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
                let animationResource9 = try! AnimationResource.generate(with: animationDefinition9)
                box9.playAnimation(animationResource9)
                
                
                // Animacion box10 giro
                let animationDefinition10 = OrbitAnimation(
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
                let animationResource10 = try! AnimationResource.generate(with: animationDefinition10)
                box10.playAnimation(animationResource10)
                
                // Animacion box11 giro
                let animationDefinition11 = OrbitAnimation(
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
                let animationResource11 = try! AnimationResource.generate(with: animationDefinition11)
                box11.playAnimation(animationResource11)
                
                // Animacion box12 giro
                let animationDefinition12 = OrbitAnimation(
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
                let animationResource12 = try! AnimationResource.generate(with: animationDefinition12)
                box12.playAnimation(animationResource12)
                
            }
            
            if(!self.arrayObjetos.contains(false) && self.arrayRunOnce[1] == false) {
                
                // Anadir color a la pirinola
                newEntityPirinola = ModelEntity.loadAsync(named: "Models/pirinola")
                    .sink { loadCompletion in
                        if case let .failure(error) = loadCompletion {
                            print("Unable to load model \(error)")
                        }
                        
                        self.newEntityPirinola?.cancel()
                    } receiveValue: { newEntity in
                        newEntity.setPosition(SIMD3(x: 0, y: 0.6, z: -0.5), relativeTo: nil)
                        newEntity.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: newEntity)
                        
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
