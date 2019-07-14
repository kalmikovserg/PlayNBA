//
//  ViewController.swift
//  PlayNBA
//
//  Created by Сергей Калмыков on 7/14/19.
//  Copyright © 2019 Сергей Калмыков. All rights reserved.
//

import ARKit

class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        let touchLacation = sender.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(touchLacation, types: .existingPlaneUsingExtent)
        if let nearTestResult = hitTestResult.first {
            addHoop(result: nearTestResult)
        }
    }
    
    //MARK: - Custom Methods
    private func addHoop(result: ARHitTestResult) {
        let hoop = SCNScene(named: "art.scnassets/hoop.scn")!.rootNode.clone()
        hoop.simdTransform = result.worldTransform
        hoop.eulerAngles.x -= .pi / 2
        sceneView.scene.rootNode.addChildNode(hoop)
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
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        let wall = creatWall(pleneAnchor: planeAnchor)
        node.addChildNode(wall)
    }
}
