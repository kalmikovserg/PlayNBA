//
//  ViewController.swift
//  PlayNBA
//
//  Created by Сергей Калмыков on 7/14/19.
//  Copyright © 2019 Сергей Калмыков. All rights reserved.
//

import ARKit
import CoreMotion
import SpriteKit

class ViewController: UIViewController {
    
    var statusHit = false
    var scorePlaer = 0
    var firstBall = true
    
    var isHoopPlaced = false {
        didSet {
            if isHoopPlaced {
                guard let configuration = sceneView.session.configuration as? ARWorldTrackingConfiguration else { return }
                configuration.planeDetection = []
                sceneView.session.run(configuration)
            }
        }
    }
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var poitLabel: UILabel!
    @IBOutlet var scoreLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.scene.physicsWorld.contactDelegate = self
        sceneView.delegate = self
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .vertical
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    @IBAction func screenTaped(_ sender: UITapGestureRecognizer) {
        if isHoopPlaced {
            addBall()
            firstBall = false
        } else {
            let touchLacation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLacation, types: .existingPlaneUsingExtent)
            if let nearTestResult = hitTestResult.first {
                addHoop(result: nearTestResult)
                isHoopPlaced = true
            }
        }
    }
    
    private func addBall() {
        guard let frame = sceneView.session.currentFrame else { return }
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball, options: [SCNPhysicsShape.Option.collisionMargin: 0.01]))
        
        //        ball.physicsBody?.categoryBitMask = Int(BitMaskCategory.ball)
        //        ball.physicsBody?.collisionBitMask = Int(BitMaskCategory.firstBody)
        //        ball.physicsBody?.contactTestBitMask = Int(BitMaskCategory.firstBody)
        
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/basketballtexture.jpg")
        let tranform = SCNMatrix4(frame.camera.transform)
        let power = Float(10)
        let force = SCNVector3(-tranform.m31 * power, -tranform.m32 * power, -tranform.m33 * power)
        ball.physicsBody?.applyForce(force, asImpulse: true)
        sceneView.scene.rootNode.addChildNode(ball)
        
        if firstBall {
            let scoreLabel = sceneView.scene.rootNode.childNode(withName: "nbaLabel", recursively: false)
            scoreLabel?.removeFromParentNode()
        }
        if tranform.m31 > 3 {
            poitLabel.text = Point.threePoint.rawValue
            sceneView.scene.rootNode.enumerateChildNodes{ node, _ in
                if node.name == "hit" {
                    if firstBall {
                        createHit(for: node)
                        firstBall = false
                    }
                    self.scorePlaer += 3
                    self.poitLabel.text = Point.threePoint.rawValue
                }
            }
        } else {
            poitLabel.text = Point.twoPoint.rawValue
            sceneView.scene.rootNode.enumerateChildNodes{ node, _ in
                if node.name == "hit" {
                    if firstBall {
                        createHit(for: node)
                        firstBall = false
                    }
                    self.scorePlaer += 2
                    self.poitLabel.text = Point.twoPoint.rawValue
                }
            }
            
        }
    }
    
    private func createHit(for node: SCNNode) {
        node.opacity = 0
        node.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: node, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.boundingBox]))
        node.physicsBody?.categoryBitMask = Int(BitMaskCategory.firstBody)
        node.physicsBody?.collisionBitMask = Int(BitMaskCategory.ball)
        node.physicsBody?.contactTestBitMask = Int(BitMaskCategory.ball)
    }
    
    //MARK: - Custom Methods
    private func addHoop(result: ARHitTestResult) {
        let hoop = SCNScene(named: "art.scnassets/hoop.scn")!.rootNode.clone()
        
        hoop.simdTransform = result.worldTransform
        hoop.eulerAngles.x -= .pi / 2
        sceneView.scene.rootNode.addChildNode(hoop)
        
        hoop.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoop, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        //        hoop.physicsBody?.categoryBitMask = Int(BitMaskCategory.board)
        //        hoop.physicsBody?.collisionBitMask = Int(BitMaskCategory.ball)
        //        hoop.physicsBody?.contactTestBitMask = Int(BitMaskCategory.ball)
        
        let score = createNBALabel()
        score.eulerAngles.y += 0.1
        score.scale = SCNVector3(0.01, 0.01, 0.01)
        sceneView.scene.rootNode.addChildNode(score)
        
        sceneView.scene.rootNode.enumerateChildNodes{ node, _ in
            if node.name == "Wall" {
                node.removeFromParentNode()
            }
        }
    }
    
    private func creatWall(pleneAnchor: ARPlaneAnchor) -> SCNNode {
        let extent = pleneAnchor.extent
        let width = CGFloat(extent.x)
        let hight = CGFloat(extent.z)
        let plane = SCNPlane(width: width, height: hight)
        let wall = SCNNode(geometry: plane)
        plane.firstMaterial?.diffuse.contents = UIColor.red
        wall.eulerAngles.x = -.pi / 2
        wall.name = "Wall"
        wall.opacity = 0.125
        
        return wall
    }
    
    private func createNBALabel(nbaLabel: String = "Hello! Play BasketBall") -> SCNNode {
        let nbaGEO = SCNText(string: nbaLabel, extrusionDepth: 0.5)
        nbaGEO.name = "nbaLabel"
        nbaGEO.firstMaterial?.diffuse.contents = UIColor.yellow
        let nbaNode = SCNNode(geometry: nbaGEO)
        
        return nbaNode
    }
}

extension ViewController: ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let wall = creatWall(pleneAnchor: planeAnchor)
        node.addChildNode(wall)
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        statusHit = true
    }
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if statusHit {
            scoreLabel.text = "\(scorePlaer)"
            statusHit = false
        }
    }
}

