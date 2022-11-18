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
    // Checks if the obras/models are already loaded (to avoid loading more than once)
    var modelsLoaded = false
    // Array of zonas in the MARCO
    var zonas: Array<(name: String, latMin: Double, latMax: Double, lonMin: Double, lonMax: Double)> = [
        ("Zona B", 25.60008, 25.66009, -100.29169, -100.28800), // Salon Swift
        ("Zona C", 25.65700, 25.65880, -100.26000, -100.25000), // Piso abajo 1
        ("Zona D", 25.65881, 25.66600, -100.26000, -100.25000), // Piso abajo 2
        // ("Zona A", 25.65000, 25.66000, -100.26000, -100.25000), // Mi casita
        ("Zona E", 25.69100, 25.70000, -100.26000, -100.25000),
        ("Zona F", 25.70100, 25.71000, -100.26000, -100.25000),
        ("Zona G", 25.71100, 25.72000, -100.26000, -100.25000)
    ]
    // index of the current zona in the array, it has to match the models[Obra] based on the index
    var currZona = 0
    
    // Variable for loading asynchronous models
    var newEntityPirinola: AnyCancellable?
    
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
    // TODO: Replicar para las demas zonas
    var arrayObjetos = [false, false, false, false, false, false, false, false, false, false, false, false]
    
    // Array para saber cuando se ha completado cada zona independientemente, cuando se comp-leta este array, se gana el juego
    var arrayRunOnce = [false, false]
    
    // Anchor para los modelos
    // let anchor = AnchorEntity(plane: .horizontal, classification: .floor) // Production
    let anchor = AnchorEntity(plane: .horizontal) // For testing puposes
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
    
    // Inits the information from the API to the models variable with the Obras loaded
    func initModelsData(newObras: [Obra]) {
        if(!newObras.isEmpty && modelsLoaded == false) {
            models = newObras
            modelsLoaded = true
        }
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
    
    
    // Remove animation for box on collision with a Bullet
    func animate(entity: HasTransform, angle: Float, axis: SIMD3<Float>, duration: TimeInterval, loop: Bool, currentPosition: SIMD3<Float>){
        guard let view = self.view else { return }
        
        // Remove the cube after 4 seconds
        let timer1 = CustomTimer { (seconds) in
            if(seconds == 1) {
                view.scene.anchors[1].removeChild(entity)
            }
        }
        timer1.start()

        guard loop == true else { return }
        animUpdateSubscriptions.append(view.scene.subscribe(to: AnimationEvents.PlaybackCompleted.self, on: entity)
        { _ in
            self.animate(entity: entity, angle: angle, axis: axis, duration: duration, loop: loop, currentPosition: currentPosition)
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
                self.arrayObjetos[entityReal - 1] = true
                
                // TODO: Delete on production: just to check array for the progress
                print(self.arrayObjetos)
                
                // If the arrayObjects is all setted as true, then marks it up as completed
                if (!self.arrayObjetos.contains(false)) {
                    print("se ha completado coordinator")
                    Coordinator.completed.complete = true
                    print(Coordinator.completed.complete)
                }

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
                    
                    print(self.arrayObjetos)
                    if (!self.arrayObjetos.contains(false)) {
                        print("se ha completado coordinator")
                        Coordinator.completed.complete = true
                    }
                }
            }
        })
    }
    
    // Function to generate the Text entity that goes with the USDZ of the Obra
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
            view.scene.removeAnchor(anchor)
            
            
        // Si se encuentra en la zona actual, ejecuta ekl siguiente codigo
        } else {
            // Si aun no se ha montado la escena, se monta con este if
            if(view.scene.anchors.count == 1) {
                // Se carga el modelo Principal en negro sin textura
                // TODO: Anadir modelo correcto con zona.url
                guard let entityPirinolaSalon = try? ModelEntity.load(named: "Models/pirinola_black") else {
                    fatalError("Model was not found!")
                }
                entityPirinolaSalon.setPosition(SIMD3(x: 0, y: 0.6, z: -0.5), relativeTo: nil)
                entityPirinolaSalon.setScale(SIMD3(x: 0.09, y: 0.09, z: 0.09), relativeTo: entityPirinolaSalon)
                anchor.addChild(entityPirinolaSalon)

                // Muestra el texto de ka obra actual
                let textEntity = textGen(textString: models[currZona].nombre)
                textEntity.setPosition(SIMD3(x: 0.0, y: 0.9, z: 0.0), relativeTo: nil)
                anchor.addChild(textEntity)
                
                // Caja - 1 Collision
                // TODO: Check if boxes have to be initiated just once instead for each scene
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
    
        
                // TODO: Add the builded anchor to the scene
                anchor.move(to: Transform(translation: simd_float3(0,0,-1)), relativeTo: nil)
                view.scene.addAnchor(anchor)
                
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
                        view.scene.anchors[1].children[0] = newEntity
                        self.arrayRunOnce[1] = true
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
