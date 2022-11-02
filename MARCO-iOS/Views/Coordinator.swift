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

class Coordinator: NSObject, ARSessionDelegate {
    
    weak var view: ARView?
    var collisionSubscriptions = [Cancellable]()
    
    let boxGroup = CollisionGroup(rawValue: 1 << 0)
    let sphereGroup = CollisionGroup(rawValue: 1 << 1)
    
    var boxMask: CollisionGroup = .init()
    var sphereMask: CollisionGroup = .init()
    
    // Salon Aplicacion
    var pirinolaLimitLat = [25.60008, 25.66009]
    var pirinolaLimitLon = [-100.29069, -100.290600]
    
    // Simulador segundo objeto
    var objetoLimitLat = [37.33467638, 37.33501504]
    var objetoLimitLon =  [-122.03432425, -122.03254905]

    // Entity global que tiene todo
    let anchor = AnchorEntity(world: [0,0,0])
    
    func initCollisionDetection() {
        guard let view = self.view else { return }
    
        collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Began.self) { event in
            
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
                    
            entity1.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
            entity2.model?.materials = [SimpleMaterial(color: .green, isMetallic: false)]
            
            print("colision detectada")
            
        })
        
        collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Ended.self) { event in
            
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
            
            entity1.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            entity2.model?.materials = [SimpleMaterial(color: .red, isMetallic: false)]
            
            print("colision detectada")
        })
        
        print("inicia")
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
            print(raycastVal.normal[0])
            
            let motion: PhysicsMotionComponent = .init(linearVelocity: [-raycastVal.normal[0]*1, -raycastVal.normal[1]*1, -raycastVal.normal[2]*1],angularVelocity: [0, 0, 0])
            bullet.components.set(motion)
            
            print("proyectil disparado")
        }

        anchor.addChild(bullet)
        
        view.installGestures(.all, for: bullet)
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
                guard let entityPirinolaSalon = try? ModelEntity.load(named: "Models/pirinola") else {
                    fatalError("Robot model was not!")
                }
                entityPirinolaSalon.setScale(SIMD3(x: 0.05, y: 0.05, z: 0.05), relativeTo: entityPirinolaSalon)
                anchor.addChild(entityPirinolaSalon)

                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.setPosition(SIMD3(x: 100, y: 150, z: 250), relativeTo: entityPirinolaSalon)
                
                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.setPosition(SIMD3(x: -200, y: -200, z: -150), relativeTo: entityPirinolaSalon)
    
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.setPosition(SIMD3(x: 130, y: 130, z: -130), relativeTo: entityPirinolaSalon)

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
                
                // Caja - 3 Collision
                let boxSalon4 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                boxSalon4.generateCollisionShapes(recursive: true)
                boxSalon4.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                boxSalon4.setPosition(SIMD3(x: 500, y: 500, z: 500), relativeTo: entityPirinolaSalon)

                anchor.addChild(boxSalon4)
                view.installGestures(.all, for: boxSalon4)
                
                view.scene.addAnchor(anchor)
                
                // Caja - 5 Collision
                let box5 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box5.generateCollisionShapes(recursive: true)
                box5.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box5.setPosition(SIMD3(x: -500, y: -500, z: -500), relativeTo: entityPirinolaSalon)

                anchor.addChild(box5)
                view.installGestures(.all, for: box5)
            }
            
        // Simulacion Swift
        } else if (lat > objetoLimitLat[0] && lat < objetoLimitLat[1] && lon > objetoLimitLon[0] && lon < objetoLimitLon[1]) {
    
            if(view.scene.anchors.isEmpty) {
                print("adentro")
                // Pirinola
                guard let entityPirinola = try? ModelEntity.load(named: "Models/pirinola") else {
                    fatalError("Robot model was not!")
                }
                entityPirinola.setScale(SIMD3(x: 0.05, y: 0.05, z: 0.05), relativeTo: entityPirinola)
                anchor.addChild(entityPirinola)
                
                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.setPosition(SIMD3(x: 100, y: 150, z: 250), relativeTo: entityPirinola)
                
                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.setPosition(SIMD3(x: -200, y: -200, z: -150), relativeTo: entityPirinola)
    
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(size: 0.1), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.1, 0.1, 0.1])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.setPosition(SIMD3(x: 130, y: 130, z: -130), relativeTo: entityPirinola)

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
                
                view.scene.addAnchor(anchor)
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
