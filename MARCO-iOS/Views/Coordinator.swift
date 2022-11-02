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
    
    
    // var pirinolaLimitLat = [25.65008, 25.65009]
    // var pirinolaLimitLon = [-100.29066, -100.29063]
    
    var pirinolaLimitLat = [37.33467638, 37.33501504]
    var pirinolaLimitLon = [-122.03432425, -122.03254905]
    
    // Primer Objeto
    // var pirinolaLimitLat = [37.33467638, 37.33501504]
    // var pirinolaLimitLon = [-122.03432425, -122.03254905]
    
    
    
    // Simulador segundo objeto
    var objetoLimitLat = [25.60008, 25.66009]
    var objetoLimitLon = [-100.29069, -100.290600]
    // objetoLimitLat = [37.332000, 37.333000]
    // objetoLimitLon = [-123.00000, -121.00000]
    
    // Entity global que tiene todo
    let anchor = AnchorEntity()
    
    func initFunction() {
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
    
    // Copiar codigo
    func buildEnvironment() {
        boxMask = CollisionGroup.all.subtracting(sphereGroup)
        sphereMask = CollisionGroup.all.subtracting(boxGroup)
        
        guard let view = self.view else { return }
        
        print("inicia")
        
        let box1 = ModelEntity(mesh: MeshResource.generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        box1.generateCollisionShapes(recursive: false)
        box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        
        let box2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: false)])
        box2.generateCollisionShapes(recursive: false)
        box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
        
        anchor.addChild(box1)
        anchor.addChild(box2)
        
        view.scene.addAnchor(anchor)
        
        view.installGestures(.all, for: box1)
        view.installGestures(.all, for: box2)
        
        
        collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Began.self) { event in
            
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
                    
            entity1.model?.materials = [SimpleMaterial(color: .green, isMetallic: true)]
            entity2.model?.materials = [SimpleMaterial(color: .green, isMetallic: true)]
            
            print("colision detectada")
            
        })
        
        collisionSubscriptions.append(view.scene.subscribe(to: CollisionEvents.Ended.self) { event in
            
            guard let entity1 = event.entityA as? ModelEntity,
                  let entity2 = event.entityB as? ModelEntity else { return }
            
            entity1.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
            entity2.model?.materials = [SimpleMaterial(color: .red, isMetallic: true)]
            
            print("colision detectada")
        })
        
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
        
        // bullet.physicsBody = PhysicsBodyComponent(
        //    massProperties: .init(shape: bulletShape, mass: 0.00001),
        //    material: nil,
        //    mode: .dynamic
        //)

        // bullet.physicsMotion?.linearVelocity = [2000, 0, 0]
        // bullet.addForce([2000, 0, 0], relativeTo: nil)

        let kinematics: PhysicsBodyComponent = .init(massProperties: .default,material: nil,mode: .kinematic)
        bullet.components.set(kinematics)
        
        if let raycastVal = raycasts.first {
            print(raycastVal.normal[0])
            
            let motion: PhysicsMotionComponent = .init(linearVelocity: [-raycastVal.normal[0]*1, -raycastVal.normal[1]*1, -raycastVal.normal[2]*1],angularVelocity: [0, 0, 0])
            bullet.components.set(motion)
        }
        
        print("bala disparada")
        anchor.addChild(bullet)
        view.installGestures(.all, for: bullet)
        
        // print("hey")
        // print(raycasts)
        // bullet.addForce([2,2,2], at: [1,1,1], relativeTo: bullet)
        // Add Force to throw the ball
        // if let raycastVal = raycasts.first {
        // bullet.addForce([2,2,2], at: raycastVal.position, relativeTo: nil)
        //    print("bullet tap")
        //}
        

    }
    
    // Cargar los modelos dependiendo de la zona
    @objc func updateMarcoModels(lat: Double, lon: Double) {
        
        guard let view = self.view else { return }
        
        boxMask = CollisionGroup.all.subtracting(sphereGroup)
        
        
        // Primer Objeto
        if (lat > pirinolaLimitLat[0] && lat < pirinolaLimitLat[1] && lon > pirinolaLimitLon[0] && lon < pirinolaLimitLon[1]) {
            
            

            if(view.scene.anchors.isEmpty) {
                // Pirinola
                guard let entityPirinola = try? ModelEntity.load(named: "Models/pirinola") else {
                    fatalError("Shoe model was not!")
                }
                anchor.addChild(entityPirinola)
                

                // Aliens - 1
                guard let entityArchery1 = try? ModelEntity.load(named: "Models/robot") else {
                    fatalError("Robot 1 model was not!")
                }
                entityArchery1.setPosition(SIMD3(x: 10, y: 15, z: 25), relativeTo: entityPirinola)
                entityArchery1.setScale(SIMD3(x: 0.5, y: 0.5, z: 0.5), relativeTo: entityPirinola)
                anchor.addChild(entityArchery1)
                
                // Aliens - 2
                guard let entityArchery2 = try? ModelEntity.load(named: "Models/robot") else {
                    fatalError("Robot 2 model was not!")
                }
                entityArchery2.setPosition(SIMD3(x: -20, y: -20, z: -15), relativeTo: entityPirinola)
                entityArchery2.setScale(SIMD3(x: 0.5, y: 0.5, z: 0.5), relativeTo: entityPirinola)
                anchor.addChild(entityArchery2)
                
                // Aliens - 3
                guard let entityArchery3 = try? ModelEntity.load(named: "Models/robot") else {
                    fatalError("Robot 3 model was not!")
                }
                entityArchery3.setPosition(SIMD3(x: 13, y: 13, z: -13), relativeTo: entityPirinola)
                entityArchery3.setScale(SIMD3(x: 0.5, y: 0.5, z: 0.5), relativeTo: entityPirinola)
                anchor.addChild(entityArchery3)
                
            }
            
            // Segundo Objeto que funciona
        } else if (lat > objetoLimitLat[0] && lat < objetoLimitLat[1] && lon > objetoLimitLon[0] && lon < objetoLimitLon[1]) {
            
            if(view.scene.anchors.isEmpty) {
                print("adentro")
                // Pirinola
                guard let entityPirinola = try? ModelEntity.load(named: "Models/pirinola") else {
                    fatalError("Robot model was not!")
                }
                entityPirinola.setScale(SIMD3(x: 0.05, y: 0.05, z: 0.05), relativeTo: entityPirinola)
                anchor.addChild(entityPirinola)
                
                //
                //
                // Caja - 1 Collision
                let box1 = ModelEntity(mesh: MeshResource.generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box1.generateCollisionShapes(recursive: true)
                box1.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box1.setPosition(SIMD3(x: 100, y: 150, z: 250), relativeTo: entityPirinola)
                
                anchor.addChild(box1)
                view.installGestures(.all, for: box1)
                
                // Caja - 2 Collision
                let box2 = ModelEntity(mesh: MeshResource.generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box2.generateCollisionShapes(recursive: true)
                box2.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box2.setPosition(SIMD3(x: -200, y: -200, z: -150), relativeTo: entityPirinola)
    
                anchor.addChild(box2)
                view.installGestures(.all, for: box2)
                
                // Caja - 3 Collision
                let box3 = ModelEntity(mesh: MeshResource.generateBox(size: 0.2), materials: [SimpleMaterial(color: .red, isMetallic: false)])
                box3.generateCollisionShapes(recursive: true)
                box3.collision = CollisionComponent(shapes: [.generateBox(size: [0.2, 0.2, 0.2])], mode: .trigger, filter: .init(group: boxGroup, mask: boxMask))
                box3.setPosition(SIMD3(x: 130, y: 130, z: -130), relativeTo: entityPirinola)

                anchor.addChild(box3)
                view.installGestures(.all, for: box3)
            }
            
            view.scene.addAnchor(anchor)
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
